
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


# ------------------------------------------------------------
# Executes the ChaCha20 inner block loop.
#
# This function calls inner_block 10 times to complete the
# 20 rounds of the ChaCha20 algorithm (10 column + diagonal
# round pairs).
#
# Inputs:
#   s5 : number of inner_block iterations (normally 10)
#
# Uses:
#   s0 : pointer to working_state (used by inner_block)
#
# Stack:
#   Saves return address and loop counter
# ------------------------------------------------------------
.globl loop_inner_block
loop_inner_block:
    addi sp, sp, -16
    sw ra, 12(sp)        # save return address
    sw s5, 8(sp)         # save loop counter

loop_start:
    la s0, working_state # load address of working_state
    call inner_block     # execute one inner block
    addi s5, s5, -1      # decrement round counter
    bnez s5, loop_start  # repeat while s5 != 0

    lw s5, 8(sp)         # restore loop counter
    lw ra, 12(sp)        # restore return address
    addi sp, sp, 16
    ret



# ------------------------------------------------------------
# Copies the original ChaCha20 state into working_state.
#
# This function creates a working copy of the 16-word state
# before executing the ChaCha20 rounds. The original state
# must remain unchanged so it can be added back after the
# 20 rounds are completed.
#
# Inputs:
#   state : original ChaCha20 state array (16 x 32-bit words)
#
# Outputs:
#   working_state : copy of state used during computation
#
# Temporaries:
#   t0 : pointer to state
#   t1 : pointer to working_state
#   t2 : loop counter (16 words)
#   t3 : temporary register to hold loaded word
# ------------------------------------------------------------
.globl copy_state_to_working
copy_state_to_working:
    la t0, state           # pointer to state[16]
    la t1, working_state   # pointer to working_state[16]
    li t2, 16              # number of words to copy

copy_loop:
    lw t3, 0(t0)           # load state[i]
    sw t3, 0(t1)           # store into working_state[i]
    addi t0, t0, 4         # move to next state word
    addi t1, t1, 4         # move to next working_state word
    addi t2, t2, -1        # decrement counter
    bnez t2, copy_loop     # repeat until all 16 words copied
    ret



# ------------------------------------------------------------
# Adds the working_state to the original ChaCha20 state.
#
# According to the ChaCha20 specification:
#   state[i] = state[i] + working_state[i] (mod 2^32)
#
# This produces the final block after the 20 rounds of the
# ChaCha20 algorithm.
#
# Inputs:
#   state : original ChaCha20 state array (16 x 32-bit words)
#   working_state : transformed state after 20 rounds
#
# Outputs:
#   state : updated with the final block result
#
# Temporaries:
#   t0 : loop counter
#   t1 : state[i]
#   t2 : working_state[i]
#   t3 : constant value 16 (number of words)
#   t4 : pointer to state
#   t5 : pointer to working_state
# ------------------------------------------------------------
.globl add_working_to_state
add_working_to_state:
    la t4, state          # pointer to state[16]
    la t5, working_state  # pointer to working_state[16]
    li t0, 0              # loop index = 0
    li t3, 16             # number of words in state

loop_add:
    lw t1, 0(t4)          # load state[i]
    lw t2, 0(t5)          # load working_state[i]

    add t1, t1, t2        # state[i] += working_state[i]
    sw t1, 0(t4)          # store result back to state[i]

    addi t4, t4, 4        # move to next state word
    addi t5, t5, 4        # move to next working_state word

    addi t0, t0, 1        # i++
    blt t0, t3, loop_add  # repeat until i < 16

    ret


# ------------------------------------------------------------
# Serializes the ChaCha20 state into a contiguous 64-byte block.
#
# After completing the ChaCha20 rounds and adding the original
# state to the working_state, the resulting state[16] words
# must be written sequentially into an output buffer.
#
# Inputs:
#   state : ChaCha20 state array (16 x 32-bit words)
#
# Outputs:
#   serialized_block : 64-byte output block
#
# Temporaries:
#   t0 : pointer to state
#   t1 : pointer to serialized_block
#   t2 : loop counter (16 words)
#   t3 : temporary register to hold state word
# ------------------------------------------------------------
.globl serialize_state
serialize_state:
    la t0, state              # pointer to state[16]
    la t1, serialized_block   # pointer to output buffer
    li t2, 16                 # number of words to copy

serialize_loop:
    lw t3, 0(t0)              # load state[i]
    sw t3, 0(t1)              # store into serialized_block[i]
    addi t0, t0, 4            # advance state pointer
    addi t1, t1, 4            # advance output pointer
    addi t2, t2, -1           # decrement counter
    bnez t2, serialize_loop   # repeat until 16 words copied
    ret
