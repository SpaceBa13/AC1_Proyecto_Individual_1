.section .text
.globl _start
_start:
    li t0, 10
    li t1, 1
    li t2, 0
    # b = 0x7998bfda
    li a0, 0x7998bfda
    # n = 7
    li a1, 7
    call rotate_left
    call end

loop_sum:
    add t2, t2, t1
    addi t1, t1, 1
    ble t1, t0, loop_sum
    ret


rotate_left:
    sll t0, a0, a1      # t0 = x << n
    li t1, 32           # t1 = 32
    sub t1, t1, a1      # t1 = 32 - n
    srl t2, a0, t1      # t2 = x >> (32-n)
    or a0, t0, t2       # a0 = resultado
    ret
    

quarter_round:
    #a
    li t3, 0x11111111
    #b
    li t4, 0x01020304
    #c
    li t5, 0x77777777
    #d
    li t6, 0x01234567

    add t3, t3, t4      # a = a + b
    xor t6, t6, t3      # d = d XOR a
    mv a0 , t6          # arg for rotate left
    li a1, 16           # n for rotate left
    call rotate_left    # d = rotate_left(d, 16)
    mv t6 , a0          # update d with result of rotate left


end:
    j end
    # The program ends here, but we loop infinitely to keep the QEMU session alive.

