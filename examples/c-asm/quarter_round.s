
.globl quarter_round

quarter_round:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    # The quarter round function operates on the state elements at the addresses in s1, s2, s3, s4
    #1
    add t3, t3, t4     # a = a + b
    xor t6, t6, t3     # d = d XOR a
    mv a0 , t6         # arg for rotate left (d)
    li a1, 16          # n for rotate left (16)
    call rotate_left   # d = rotate_left(d, 16)
    mv t6 , a0         # update d with result of rotate left

    #2
    add t5, t5, t6     # c = c + d
    xor t4, t4, t5     # b = b xor c
    mv a0 , t4         # arg for rotate left (b)
    li a1, 12          # n for rotate left (12)
    call rotate_left   # b = rotate_left(b, 12)
    mv t4 , a0         # update b with result of rotate left

    #3
    add t3 , t3, t4    # a = a + b
    xor t6, t6, t3     # d = d XOR a   
    mv a0, t6          # arg for rotate left (d)
    li a1, 8           # n for rotate left (8)
    call rotate_left   # d = rotate_left(d, 8)
    mv t6, a0          # update d with result of rotate left

    #4
    add t5, t5, t6     # c = c + d
    xor t4, t4, t5     # b = b XOR c
    mv a0, t4          # arg for rotate left (b)
    li a1, 7           # n for rotate left (7)
    call rotate_left   # b = rotate_left(b, 7)
    mv t4, a0          # update b with result of rotate left

    sw t3, 0(s1)       # save state[x] = a
    sw t4, 0(s2)       # save state[y] = b
    sw t5, 0(s3)       # save state[z] = c
    sw t6, 0(s4)       # save state[w] = d

    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

rotate_left:
    sll t0, a0, a1     # t0 = x << n
    li t1, 32          # t1 = 32
    sub t1, t1, a1     # t1 = 32 - n
    srl t2, a0, t1     # t2 = x >> (32-n)
    or a0, t0, t2      # a0 = result
    ret
    