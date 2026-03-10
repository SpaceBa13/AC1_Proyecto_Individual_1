.section .data
state:
.word 0,1,2,3
.word 4,5,6,7
.word 8,9,10,11
.word 12,13,14,15

.section .text
.globl _start
_start:

    la s0, state # Load address of state into s0 for use in quarter_round function


    # Starting matri

    li t0, 0x879531e0
    sw t0, 0(s0)

    li t0, 0xc5ecf37d
    sw t0, 4(s0)

    li t0, 0x516461b1
    sw t0, 8(s0)

    li t0, 0xc9a62f8a
    sw t0, 12(s0)

    li t0, 0x44c20ef3
    sw t0, 16(s0)

    li t0, 0x3390af7f
    sw t0, 20(s0)

    li t0, 0xd9fc690b
    sw t0, 24(s0)

    li t0, 0x2a5f714c
    sw t0, 28(s0)

    li t0, 0x53372767
    sw t0, 32(s0)

    li t0, 0xb00a5631
    sw t0, 36(s0)

    li t0, 0x974c541a
    sw t0, 40(s0)

    li t0, 0x359e9963
    sw t0, 44(s0)

    li t0, 0x5c971061
    sw t0, 48(s0)

    li t0, 0x3d631689
    sw t0, 52(s0)

    li t0, 0x2098d9d6
    sw t0, 56(s0)

    li t0, 0x91dbd320
    sw t0, 60(s0)

    # set the index for quarter round
    li a0, 2 # x = 2
    li a1, 7 # y = 7
    li a2, 8 # z = 8
    li a3, 13 # w = 13
    
    # call to compute the addresses of the state elements for the quarter round
    call compute_adresses

    # call to load the state values into t3, t4, t5, t6 for the quarter round
    call assign_addresses

    # call quarter round
    call quarter_round


    call end

rotate_left:
    sll t0, a0, a1     # t0 = x << n
    li t1, 32          # t1 = 32
    sub t1, t1, a1     # t1 = 32 - n
    srl t2, a0, t1     # t2 = x >> (32-n)
    or a0, t0, t2      # a0 = result
    ret
    
quarter_round:
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

    ret

compute_addresses:
    # Compute the addresses of the state elements for the quarter round

    slli t0, a0, 2      # t0 = x * 4
    add  s1, s0, t0     # s1 = &state[x]

    slli t0, a1, 2
    add  s2, s0, t0     # s2 = &state[y]

    slli t0, a2, 2
    add  s3, s0, t0     # s3 = &state[z]

    slli t0, a3, 2
    add  s4, s0, t0     # s4 = &state[w]

    ret

assign_addresses:
    # Load the state values into t3, t4, t5, t6 for the quarter round
    lw t3, 0(s1)   # a = state[x]
    lw t4, 0(s2)   # b = state[y]
    lw t5, 0(s3)   # c = state[z]
    lw t6, 0(s4)   # d = state[w]
    ret

end:
    j end
    # The program ends here, but we loop infinitely to keep the QEMU session alive.

