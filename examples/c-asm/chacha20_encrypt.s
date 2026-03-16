# Brayan Alpizar ELizondo
# TEC Ing. Computadores
# RISC-V Assembly implementation of ChaCha20 encryption algorithm


# ---------------------------------IMPORT SECTION--------------------------------- #
.extern print_block

# ---------------------------------DATA SECTION--------------------------------- #
.section .data

# This is the original constant part of the ChaCha20 state, which is the same for every block
.globl original_constants
original_constants:
    .word 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574

# This is the 512-bit state of the ChaCha20 algorithm
.globl state
state: 
    .space 64

# This is the 512-bit working state used for the rounds
.globl working_state
working_state:
    .space 64

# This buffer will hold the serialized state after the rounds, which is the keystream block
.globl serialized_block
serialized_block:
    .space 64

# This buffer will hold the encrypted output after XORing with plaintext
.globl cyphered_block
cyphered_block:
    .space 64

# ---------------------------------TEXT SECTION--------------------------------- #
.section .text

# This function implements the ChaCha20 encryption algorithm
# Inputs:
#   a0: pointer to 256-bit key (8 x uint32_t)
#   a1: pointer to 32-bit counter
#   a2: pointer to 96-bit nonce (3 x uint32_t)
#   a3: pointer to plaintext buffer
#   a4: length of plaintext in bytes
.globl chacha20_encrypt
chacha20_encrypt:
    # Save registers to stack to preserve caller state
    addi sp, sp, -40
    sw ra, 36(sp)
    sw s0, 32(sp)
    sw s1, 28(sp)
    sw s2, 24(sp)
    sw s3, 20(sp)
    sw s4, 16(sp)
    sw s5, 12(sp)
    sw s6, 8(sp)
    sw s7, 4(sp)
    sw s8, 0(sp)

    # Save input parameters in callee-saved registers
    mv s0, a0        # key pointer
    mv s1, a1        # counter pointer
    mv s2, a2        # nonce pointer
    mv s3, a3        # plaintext pointer
    mv s4, a4        # plaintext length

    # Calculate number of 64-byte blocks to encrypt
    addi t0, s4, 63   # length + 63
    srli t0, t0, 6    # divide by 64 using shift
    mv s5, t0         # s5 = number of blocks

    lw s6, 0(s1)      # load initial counter value
    li s7, 0          # initialize block index

# Main encryption loop: process each 64-byte block
loop_chacha_encrypt:
    add t1, s6, s7      # counter = initial_counter + block_index
    sw t1, 0(s1)        # update counter in memory

    # Prepare arguments and call ChaCha20 block function
    mv a0, s0
    mv a1, s1
    mv a2, s2
    call chacha20_block
    # Encrypt the block using the keystream

    # Prepare useful bytes to encrypt the last block if it's less than 64 bytes
    slli t4, s7, 6                  # t4 = block_index * 64 → byte offset of the current block
    sub t4, s4, t4                  # t4 = remaining bytes from this block to the end of the message
    li t5, 64                       # t5 = size of a full block (64 bytes)
    blt t4, t5, block_less_than_64  # If remaining bytes < 64, jump to partial block handling

    # Normal case: full 64-byte block
    mv a0, t5                       # a0 = number of bytes to encrypt for this block
    li s8, 64                       # s8 = number of bytes to be used for printing later
    call encrypt_message            # Call the XOR function to encrypt the block
    j continue_after_encrypt        # Skip the partial block section

    block_less_than_64:
    # Final block: partial block with fewer than 64 bytes
    mv t3, t4                       # t3 = number of useful bytes to process in this block
    mv s8, t3                       # Save the useful byte count in s8 for printing
    mv a0, t3                       # Pass the number of bytes to encrypt to encrypt_message
    call encrypt_message            # Call the XOR function with the adjusted number of bytes

    continue_after_encrypt:
    # Continue normal flow after encrypting the block (full or partial)

    # Print the encrypted block using C function
    la a0, cyphered_block
    mv a1, s8
    call print_block
    # Increment block index
    addi s7, s7, 1
    bne s7, s5, loop_chacha_encrypt
    # Restore registers before returning
    lw s8, 0(sp)
    lw s7, 4(sp)
    lw s6, 8(sp)
    lw s5, 12(sp)
    lw s4, 16(sp)
    lw s3, 20(sp)
    lw s2, 24(sp)
    lw s1, 28(sp)
    lw s0, 32(sp)
    lw ra, 36(sp)
    addi sp, sp, 40
    ret

# This function performs the XOR of a 64-byte plaintext block with the keystream block
# inputs:
#  a0: useful bytes to encrypt (adjusted for last block if < 64)
# Registers used as inputs:
#   s3: pointer to the plaintext buffer
#   s7: current block index (used to calculate offset into plaintext)
encrypt_message:
    # Save callee-saved registers that will be used
    addi sp, sp, -8
    sw s3, 4(sp)
    sw s7, 0(sp)
    la t0, serialized_block     # pointer to the keystream block
    mv t1, s3                   # base pointer to plaintext
    slli t6, s7, 6              # calculate block_offset = block_index * 64
    add t1, t1, t6              # adjust plaintext pointer for current block
    la t2, cyphered_block       # pointer to output buffer
    mv t3, a0                   # number of bytes to encrypt in this block

# Loop: XOR each byte of plaintext with the corresponding keystream byte
# Registers:
#   t0: keystream pointer
#   t1: plaintext pointer
#   t2: output pointer
#   t3: remaining bytes counter
xor_loop:
    lbu t4, 0(t0)        # load byte from keystream
    lbu t5, 0(t1)        # load byte from plaintext
    xor t4, t4, t5       # XOR plaintext byte with keystream byte
    sb t4, 0(t2)         # store result in output buffer

    addi t0, t0, 1       # move to next keystream byte
    addi t1, t1, 1       # move to next plaintext byte
    addi t2, t2, 1       # move to next output byte

    addi t3, t3, -1      # decrement byte counter
    bnez t3, xor_loop    # continue loop if more bytes remain

    # Restore saved registers
    lw s3, 4(sp)
    lw s7, 0(sp)
    addi sp, sp, 8
    ret
    