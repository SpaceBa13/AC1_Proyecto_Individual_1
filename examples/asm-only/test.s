.section .data
state:
.word 0,1,2,3
.word 4,5,6,7
.word 8,9,10,11
.word 12,13,14,15

.section .text
.globl _start
_start:


    call quarter_round
    call end

rotate_left:
    sll t0, a0, a1      # t0 = x << n
    li t1, 32           # t1 = 32
    sub t1, t1, a1      # t1 = 32 - n
    srl t2, a0, t1      # t2 = x >> (32-n)
    or a0, t0, t2       # a0 = result
    ret
    
quarter_round:
    la s0, state     # Load address of state into s0
    lw t3, 4(s0)     # state[1] -> a
    lw t4, 20(s0)    # state[5] -> b
    lw t5, 36(s0)    # state[9] -> c
    lw t6, 52(s0)    # state[13] -> d

    #1
    add t3, t3, t4      # a = a + b
    xor t6, t6, t3      # d = d XOR a
    mv a0 , t6          # arg for rotate left (d)
    li a1, 16           # n for rotate left (16)
    call rotate_left    # d = rotate_left(d, 16)
    mv t6 , a0          # update d with result of rotate left

    #2
    add t5, t5, t6      # c = c + d
    xor t4, t4, t5      # b = b xor c
    mv a0 , t4          # arg for rotate left (b)
    li a1, 12           # n for rotate left (12)
    call rotate_left    # b = rotate_left(b, 12)
    mv t4 , a0          # update b with result of rotate left

    #3
    add t3 , t3, t4     # a = a + b
    xor t6, t6, t3     # d = d XOR a   
    mv a0, t6          # arg for rotate left (d)
    li a1, 8           # n for rotate left (8)
    call rotate_left    # d = rotate_left(d, 8)
    mv t6, a0          # update d with result of rotate left

    #4
    add t5, t5, t6     # c = c + d
    xor t4, t4, t5     # b = b XOR c
    mv a0, t4          # arg for rotate left (b)
    li a1, 7           # n for rotate left (7)
    call rotate_left   # b = rotate_left(b, 7)
    mv t4, a0          # update b with result of rotate left

    sw t3, 4(s0)        # save state[1] = a
    sw t4, 20(s0)       # save state[5] = b
    sw t5, 36(s0)       # save state[9] = c
    sw t6, 52(s0)       # save state[13] = d

    ret

end:
    j end
    # The program ends here, but we loop infinitely to keep the QEMU session alive.

