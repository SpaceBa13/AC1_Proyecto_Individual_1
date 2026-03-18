# ------------------------------------------------------------
# Implements the inner block of the ChaCha20 algorithm.
#
# The inner block performs 8 quarter rounds on the 4x4 state
# matrix in the following order:
#   - 4 column rounds
#   - 4 diagonal rounds
#
# In the full ChaCha20 algorithm, this function is executed
# 10 times to complete the 20 rounds of the cipher.
#
# Inputs:
#   s0 : pointer to the working_state array (16 x 32-bit words)
#
# Uses:
#   s1-s4 : store addresses of state elements for quarter rounds
#
# Temporaries:
#   t3-t6 : hold state values used in quarter_round
#   a0-a3 : indices (x, y, z, w) passed as parameters to helper functions
#
# Stack:
#   Saves callee-saved registers and return address
# ------------------------------------------------------------
.globl inner_block
inner_block:
    # Allocate stack space and save registers
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    # --------------------------------------------------------
    # Column rounds
    # --------------------------------------------------------

    # Quarter round on (0, 4, 8, 12)
    li a0, 0
    li a1, 4
    li a2, 8
    li a3, 12
    call compute_addresses
    call quarter_round

    # Quarter round on (1, 5, 9, 13)
    li a0, 1
    li a1, 5
    li a2, 9
    li a3, 13
    call compute_addresses
    call quarter_round

    # Quarter round on (2, 6, 10, 14)
    li a0, 2
    li a1, 6
    li a2, 10
    li a3, 14
    call compute_addresses
    call quarter_round

    # Quarter round on (3, 7, 11, 15)
    li a0, 3
    li a1, 7
    li a2, 11
    li a3, 15
    call compute_addresses
    call quarter_round

    # --------------------------------------------------------
    # Diagonal rounds
    # --------------------------------------------------------

    # Quarter round on (0, 5, 10, 15)
    li a0, 0
    li a1, 5
    li a2, 10
    li a3, 15
    call compute_addresses
    call quarter_round

    # Quarter round on (1, 6, 11, 12)
    li a0, 1
    li a1, 6
    li a2, 11
    li a3, 12
    call compute_addresses
    call quarter_round

    # Quarter round on (2, 7, 8, 13)
    li a0, 2
    li a1, 7
    li a2, 8
    li a3, 13
    call compute_addresses
    call quarter_round

    # Quarter round on (3, 4, 9, 14)
    li a0, 3
    li a1, 4
    li a2, 9
    li a3, 14
    call compute_addresses
    call quarter_round

    # Restore registers and return
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)

    addi sp, sp, 24
    ret


# ------------------------------------------------------------
# Computes the memory addresses of the state elements used in
# a ChaCha20 quarter round.
#
# Parameters:
#   a0 : position x in the state array
#   a1 : position y in the state array
#   a2 : position z in the state array
#   a3 : position w in the state array
#
# Uses:
#   s0 : pointer to the working_state array
#
# Outputs:
#   s1 : address of state[x]
#   s2 : address of state[y]
#   s3 : address of state[z]
#   s4 : address of state[w]
#
# Temporaries:
#   t0 : used to compute byte offsets (index * 4)
# ------------------------------------------------------------
compute_addresses:
    # Compute address of state[x]
    slli t0, a0, 2
    add  s1, s0, t0
    # Compute address of state[y]
    slli t0, a1, 2
    add  s2, s0, t0
    # Compute address of state[z]
    slli t0, a2, 2
    add  s3, s0, t0
    # Compute address of state[w]
    slli t0, a3, 2
    add  s4, s0, t0

# ------------------------------------------------------------
# Loads the state values from memory for the ChaCha20
# quarter round computation.
#
# Inputs:
#   s1 : address of state[x]
#   s2 : address of state[y]
#   s3 : address of state[z]
#   s4 : address of state[w]
#
# Outputs:
#   t3 : a = state[x]
#   t4 : b = state[y]
#   t5 : c = state[z]
#   t6 : d = state[w]
# ------------------------------------------------------------
assign_addresses:
    # Load state values
    lw t3, 0(s1)    # a = state[x]
    lw t4, 0(s2)    # b = state[y]
    lw t5, 0(s3)    # c = state[z]
    lw t6, 0(s4)    # d = state[w]

    # Prepare the parameters for quarter_round
    mv a0, t3       # a0 = a
    mv a1, t4       # a1 = b
    mv a2, t5       # a2 = c
    mv a3, t6       # a3 = d

    ret