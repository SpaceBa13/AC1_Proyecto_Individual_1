# ------------------------------------------------------------
# Brayan Alpizar Elizondo
# Instituto Tecnológico de Costa Rica (TEC)
# Ingeniería en Computadores - 2026
#
# RISC-V Assembly implementation of the ChaCha20 encryption
# algorithm.
#
# This file contains the global data structures used by the
# ChaCha20 block function and encryption routine.
# ------------------------------------------------------------


# --------------------------------- IMPORT SECTION --------------------------------- #
.extern print_block


# --------------------------------- DATA SECTION --------------------------------- #
.section .data

# ChaCha20 constant words ("expand 32-byte k")
# These constants form the first 4 words of the ChaCha20 state
.globl original_constants
original_constants:
    .word 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574


# Main ChaCha20 state (16 x 32-bit words = 512 bits)
# Layout:
#   constants (4 words)
#   key       (8 words)
#   counter   (1 word)
#   nonce     (3 words)
.globl state
state:
    .space 64


# Working state used during the 20 ChaCha20 rounds
# This is a temporary copy of the original state
.globl working_state
working_state:
    .space 64


# Serialized state after the rounds
# This produces the 64-byte keystream block
.globl serialized_block
serialized_block:
    .space 64


# Output buffer that stores the encrypted block
# Result of: plaintext XOR keystream
.globl cyphered_block
cyphered_block:
    .space 64


# --------------------------------- TEXT SECTION --------------------------------- #
.section .text


# ------------------------------------------------------------
# Implements the ChaCha20 encryption algorithm.
#
# For each 64-byte block:
#   1. Generate a keystream block using chacha20_block
#   2. XOR the keystream with the plaintext
#   3. Output the encrypted block
#
# Inputs (RISC-V ABI):
#   a0 : pointer to 256-bit key (8 x uint32_t)
#   a1 : pointer to 32-bit counter
#   a2 : pointer to 96-bit nonce (3 x uint32_t)
#   a3 : pointer to plaintext buffer
#   a4 : length of plaintext in bytes
# ------------------------------------------------------------
.globl chacha20_encrypt
chacha20_encrypt:
    # Save callee-saved registers and return address
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
    # Store input parameters in callee-saved registers
    mv s0, a0        # s0 = key pointer
    mv s1, a1        # s1 = counter pointer
    mv s2, a2        # s2 = nonce pointer
    mv s3, a3        # s3 = plaintext pointer
    mv s4, a4        # s4 = plaintext length
    # Compute number of 64-byte blocks needed
    addi t0, s4, 63  # length + 63
    srli t0, t0, 6   # divide by 64
    mv s5, t0        # s5 = total number of blocks
    lw s6, 0(s1)     # load initial counter value
    li s7, 0         # block index = 0


# ------------------------------------------------------------
# Main encryption loop (process each 64-byte block)
# ------------------------------------------------------------
loop_chacha_encrypt:
    # Update counter for this block
    add t1, s6, s7   # counter = initial_counter + block_index
    sw t1, 0(s1)     # store updated counter
    # Generate keystream block
    mv a0, s0
    mv a1, s1
    mv a2, s2
    call chacha20_block

    # --------------------------------------------------------
    # Determine how many bytes to encrypt in this block
    # (last block may be smaller than 64 bytes)
    # --------------------------------------------------------
    slli t4, s7, 6                  # t4 = block_index * 64
    sub t4, s4, t4                  # remaining bytes in message
    li t5, 64                       # full block size
    blt t4, t5, block_less_than_64  # if remaining < 64 → partial block

    # --------------------------------------------------------
    # Full 64-byte block
    # --------------------------------------------------------
    mv a0, t5                       # encrypt 64 bytes
    li s8, 64                       # save size for printing
    call encrypt_message
    j continue_after_encrypt

block_less_than_64:
    # --------------------------------------------------------
    # Final partial block
    # --------------------------------------------------------
    mv t3, t4                       # useful bytes remaining
    mv s8, t3                       # save size for printing
    mv a0, t3                       # pass byte count
    call encrypt_message

continue_after_encrypt:
    # --------------------------------------------------------
    # Print encrypted block using C helper function
    # --------------------------------------------------------
    la a0, cyphered_block
    mv a1, s8
    call print_block
    # Move to next block
    addi s7, s7, 1
    bne s7, s5, loop_chacha_encrypt
    # --------------------------------------------------------
    # Restore registers and return
    # --------------------------------------------------------
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

# ------------------------------------------------------------
# Encrypts a block of the message by XORing plaintext bytes
# with the generated ChaCha20 keystream block.
#
# The keystream block (64 bytes) is produced by chacha20_block
# and stored in serialized_block.
#
# Inputs (RISC-V ABI):
#   a0 : number of useful bytes to encrypt (<= 64 for last block)
#
# Registers used as inputs:
#   s3 : pointer to plaintext buffer
#   s7 : block index (used to compute block offset)
#
# Outputs:
#   cyphered_block : encrypted block written to output buffer
#
# Temporaries:
#   t0 : pointer to keystream block
#   t1 : pointer to plaintext block
#   t2 : pointer to output block
#   t3 : remaining byte counter
#   t6 : block offset (block_index * 64)
# ------------------------------------------------------------
encrypt_message:
    # Save callee-saved registers
    addi sp, sp, -8
    sw s3, 4(sp)
    sw s7, 0(sp)
    la t0, serialized_block     # pointer to keystream block
    mv t1, s3                   # base pointer to plaintext
    slli t6, s7, 6              # block_offset = block_index * 64
    add t1, t1, t6              # plaintext pointer += offset
    la t2, cyphered_block       # pointer to output buffer
    mv t3, a0                   # number of bytes to encrypt

# ------------------------------------------------------------
# XORs each plaintext byte with the corresponding keystream
# byte to produce the ciphertext (or plaintext during decrypt).
#
# ChaCha20 is a stream cipher, so encryption and decryption
# use the same XOR operation.
#
# Registers:
#   t0 : pointer to keystream bytes
#   t1 : pointer to plaintext bytes
#   t2 : pointer to output buffer
#   t3 : remaining byte counter
#   t4 : keystream byte
#   t5 : plaintext byte
# ------------------------------------------------------------
xor_loop:
    lbu t4, 0(t0)        # load keystream byte
    lbu t5, 0(t1)        # load plaintext byte
    xor t4, t4, t5       # ciphertext = plaintext ^ keystream
    sb t4, 0(t2)         # store result in output buffer
    addi t0, t0, 1       # advance keystream pointer
    addi t1, t1, 1       # advance plaintext pointer
    addi t2, t2, 1       # advance output pointer
    addi t3, t3, -1      # decrement remaining byte count
    bnez t3, xor_loop    # repeat while bytes remain
    # Restore saved registers
    lw s3, 4(sp)
    lw s7, 0(sp)
    addi sp, sp, 8
    ret
