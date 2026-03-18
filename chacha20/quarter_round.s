
# ------------------------------------------------------------
# Implements the ChaCha20 quarter round operation.
#
# The quarter round updates four state words (a, b, c, d)
# using additions, XOR operations, and bit rotations.
#
# Inputs:
#   a0 : address of state[x]
#   a1 : address of state[y]
#   a2 : address of state[z]
#   a3 : address of state[w]
#
# Uses:
#   t3 : a
#   t4 : b
#   t5 : c
#   t6 : d
#
# Stack:
#   Saves callee-saved registers and return address
# ------------------------------------------------------------
.globl quarter_round
quarter_round:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    # ---------------------------
    # Load values from a0..a3 to t3..t6
    # ---------------------------
    mv t3, a0      # t3 = a
    mv t4, a1      # t4 = b
    mv t5, a2      # t5 = c
    mv t6, a3      # t6 = d

    # --------------------------------------------------------
    # Quarter round operations
    # --------------------------------------------------------

    # 1
    add t3, t3, t4     # a = a + b
    xor t6, t6, t3     # d = d ^ a
    mv a0, t6          # argument x = d
    li a1, 16          # rotation amount
    call rotate_left   # d = rotl(d,16)
    mv t6, a0          # update d

    # 2
    add t5, t5, t6     # c = c + d
    xor t4, t4, t5     # b = b ^ c
    mv a0, t4          # argument x = b
    li a1, 12          # rotation amount
    call rotate_left   # b = rotl(b,12)
    mv t4, a0          # update b

    # 3
    add t3, t3, t4     # a = a + b
    xor t6, t6, t3     # d = d ^ a
    mv a0, t6          # argument x = d
    li a1, 8           # rotation amount
    call rotate_left   # d = rotl(d,8)
    mv t6, a0          # update d

    # 4
    add t5, t5, t6     # c = c + d
    xor t4, t4, t5     # b = b ^ c
    mv a0, t4          # argument x = b
    li a1, 7           # rotation amount
    call rotate_left   # b = rotl(b,7)
    mv t4, a0          # update b

    # Store updated state values
    sw t3, 0(s1)       # state[x] = a
    sw t4, 0(s2)       # state[y] = b
    sw t5, 0(s3)       # state[z] = c
    sw t6, 0(s4)       # state[w] = d

    # Restore registers
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw ra, 16(sp)

    addi sp, sp, 20
    ret


# ------------------------------------------------------------
# Performs a left rotation on a 32-bit value.
#
# This operation is used in the ChaCha20 quarter round:
#   result = (x << n) | (x >> (32 - n))
#
# Inputs (parameters - RISC-V ABI):
#   a0 : 32-bit value to rotate (x)
#   a1 : number of bits to rotate (n)
#
# Outputs:
#   a0 : rotated result
#
# Temporaries:
#   t0 : stores (x << n)
#   t1 : stores (32 - n)
#   t2 : stores (x >> (32 - n))
# ------------------------------------------------------------
rotate_left:
    # Compute left shift
    sll t0, a0, a1     # t0 = x << n
    # Compute (32 - n)
    li t1, 32
    sub t1, t1, a1
    # Compute right shift
    srl t2, a0, t1     # t2 = x >> (32 - n)
    # Combine both parts to obtain rotation
    or a0, t0, t2      # result = (x << n) | (x >> (32 - n))
    ret




.globl quarter_round_c
quarter_round_c:
    # Guardar registros callee-saved
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Guardar punteros originales
    mv s0, a0   # s0 = ptr a
    mv s1, a1   # s1 = ptr b
    mv s2, a2   # s2 = ptr c
    mv s3, a3   # s3 = ptr d

    # Cargar valores de memoria a temporales
    lw t3, 0(s0)  # a
    lw t4, 0(s1)  # b
    lw t5, 0(s2)  # c
    lw t6, 0(s3)  # d

    # ---------------------------
    # Quarter round operations
    # ---------------------------
    add t3, t3, t4
    xor t6, t6, t3
    mv a0, t6
    li a1, 16
    call rotate_left
    mv t6, a0

    add t5, t5, t6
    xor t4, t4, t5
    mv a0, t4
    li a1, 12
    call rotate_left
    mv t4, a0

    add t3, t3, t4
    xor t6, t6, t3
    mv a0, t6
    li a1, 8
    call rotate_left
    mv t6, a0

    add t5, t5, t6
    xor t4, t4, t5
    mv a0, t4
    li a1, 7
    call rotate_left
    mv t4, a0

    # Guardar resultados de vuelta a memoria usando punteros originales
    sw t3, 0(s0)
    sw t4, 0(s1)
    sw t5, 0(s2)
    sw t6, 0(s3)

    # Restaurar registros
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret