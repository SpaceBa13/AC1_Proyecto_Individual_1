# Brayan Alpizar ELizondo
# TEC Ing. Computadores
# RISC-V Assembly implementation of ChaCha20 encryption algorithm


# ---------------------------------IMPORT SECTION--------------------------------- #
.extern print_block

# ---------------------------------DATA SECTION--------------------------------- #
.section .data

# This is the original constant part of the ChaCha20 state, which is the same for every block
original_constants:
    .word 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574

# This is the 512-bit state of the ChaCha20 algorithm
state: 
    .space 64

# This is the 512-bit working state used for the rounds
working_state:
    .space 64

# This buffer will hold the serialized state after the rounds, which is the keystream block
serialized_block:
    .space 64

# This buffer will hold the encrypted output after XORing with plaintext
cyphered_block:
    .space 64

# ---------------------------------TEXT SECTION--------------------------------- #
.section .text


# This function copies the original ChaCha20 state into the working_state
# Used before performing the 20 rounds (or inner block rounds)
# state: original state[16] words (input)
# working_state: temporary working copy (output)
# Registers used: t0-t3 for pointers and loop counter
.globl copy_state_to_working
copy_state_to_working:
    la t0, state           # pointer to state[16]
    la t1, working_state   # pointer to working_state[16]
    li t2, 16              # loop counter = 16 words

copy_loop:
    lw t3, 0(t0)           # load state[i]
    sw t3, 0(t1)           # store into working_state[i]
    addi t0, t0, 4         # move to next word in state
    addi t1, t1, 4         # move to next word in working_state
    addi t2, t2, -1        # decrement loop counter
    bnez t2, copy_loop      # loop until all 16 words copied
    ret


# This function adds the working_state to the original state
# ChaCha20: state[i] = state[i] + working_state[i]  (mod 2^32)
# Output is stored back into state
# Uses t0-t5 as temporaries
.globl add_working_to_state
add_working_to_state:
    la t4, state          # pointer to original state[16]
    la t5, working_state  # pointer to working_state[16]
    li t0, 0              # loop counter = 0

loop_add:
    lw t1, 0(t4)          # load state[i]
    lw t2, 0(t5)          # load working_state[i]
    add t1, t1, t2        # state[i] += working_state[i]
    sw t1, 0(t4)          # store back to state[i]

    addi t4, t4, 4        # move to next word in state
    addi t5, t5, 4        # move to next word in working_state
    addi t0, t0, 1        # increment loop counter
    li t3, 16             # number of words in state
    blt t0, t3, loop_add  # loop until 16 words processed

    ret

# This function sets up and executes a single ChaCha20 block
# Inputs (via RISC-V ABI):
#   a0: pointer to key[8] (32-bit words)
#   a1: pointer to counter (single 32-bit word)
#   a2: pointer to nonce[3] (32-bit words)
# Outputs:
#   serialized_block[64] contains the generated keystream

.globl chacha20_block
chacha20_block:
    # --- Prologue: save callee-saved registers and return address ---
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s5, 0(sp)

    # --- Move input parameters into callee-saved registers ---
    mv s0, a0        # s0 = key pointer
    mv s1, a1        # s1 = counter pointer
    mv s2, a2        # s2 = nonce pointer

    # --- Load constants into ChaCha20 state (words 0-3) ---
    la t1, original_constants      # pointer to 4 constants
    la t2, state                   # pointer to state[16]

    lw t0, 0(t1)
    sw t0, 0(t2)   # state[0] = 0x61707865
    lw t0, 4(t1)
    sw t0, 4(t2)   # state[1] = 0x3320646e
    lw t0, 8(t1)
    sw t0, 8(t2)   # state[2] = 0x79622d32
    lw t0, 12(t1)
    sw t0, 12(t2)  # state[3] = 0x6b206574

    # --- Load 256-bit key into state (words 4-11) ---
    lw t0, 0(s0)
    sw t0, 16(t2)  # state[4]
    lw t0, 4(s0)
    sw t0, 20(t2)  # state[5]
    lw t0, 8(s0)
    sw t0, 24(t2)  # state[6]
    lw t0, 12(s0)
    sw t0, 28(t2)  # state[7]
    lw t0, 16(s0)
    sw t0, 32(t2)  # state[8]
    lw t0, 20(s0)
    sw t0, 36(t2)  # state[9]
    lw t0, 24(s0)
    sw t0, 40(t2)  # state[10]
    lw t0, 28(s0)
    sw t0, 44(t2)  # state[11]

    # --- Load counter into state[12] ---
    lw t0, 0(s1)
    sw t0, 48(t2)

    # --- Load nonce into state[13-15] ---
    lw t0, 0(s2)
    sw t0, 52(t2)
    lw t0, 4(s2)
    sw t0, 56(t2)
    lw t0, 8(s2)
    sw t0, 60(t2)

    # --- ChaCha20 block function ---
    call copy_state_to_working   # copy state -> working_state
    li s5, 10                    # 10 rounds (20 quarter-rounds)
    call loop_inner_block        # perform 20 quarter-rounds
    call add_working_to_state    # add working_state -> state
    call serialize_state         # convert state[16] -> serialized_block[64]

    # --- Epilogue: restore callee-saved registers ---
    lw s5, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret


# This function serializes the ChaCha20 state into a contiguous memory block
# Used after adding the working_state back into state
# state: array of 16 32-bit words (input)
# serialized_block: output array of 64 bytes (16 words * 4 bytes)
# Registers used: t0-t3 for pointers and loop counter
.globl serialize_state
serialize_state:
    la t0, state              # pointer to state[16] (source)
    la t1, serialized_block   # pointer to output buffer (destination)
    li t2, 16                 # loop counter = 16 words

serialize_loop:
    lw t3, 0(t0)              # load state[i]
    sw t3, 0(t1)              # store into serialized_block[i]
    addi t0, t0, 4            # move to next word in state
    addi t1, t1, 4            # move to next word in output buffer
    addi t2, t2, -1           # decrement loop counter
    bnez t2, serialize_loop   # repeat until all 16 words copied
    ret


# This function implements the ChaCha20 inner block loop
# It applies the inner_block function 10 times on working_state
# Registers used:
#   s0: pointer to working_state (used by inner_block)
#   s5: loop counter (number of rounds left)
# Stack: protects ra and s5
.globl loop_inner_block
loop_inner_block:
    addi sp, sp, -16
    sw ra, 12(sp)   # save return address
    sw s5, 8(sp)    # save loop counter

loop_start:
    la s0, working_state  # set pointer to working_state
    call inner_block       # perform one ChaCha20 quarter-round set
    addi s5, s5, -1       # decrement loop counter
    bnez s5, loop_start    # repeat until s5 == 0

    lw s5, 8(sp)    # restore loop counter
    lw ra, 12(sp)   # restore return address
    addi sp, sp, 16
    ret



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
    