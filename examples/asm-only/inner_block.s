
.globl inner_block
inner_block:
    addi sp, sp, -16   # reservar stack
    sw ra, 12(sp)      # salvar ra
    sw s1, 8(sp)       # opcional: salvar registros
    sw s2, 4(sp)
    sw s3, 0(sp)
    # This block makes the quarter round in specific order for the inner block of the ChaCha20 algorithm, which operates on columns of the state matrix
    # Quarter round on (0, 4, 8, 12)
    # set the index for quarter round
    li a0, 0        # x = 0
    li a1, 4        # y = 4
    li a2, 8        # z = 8
    li a3, 12       # w = 12

    # call to compute the addresses of the state elements for the quarter round
    call compute_addresses

    # call to load the state values into t3, t4, t5, t6 for the quarter round
    call assign_addresses

    # call quarter round
    call quarter_round

    ######### This structure is the same for rest of the quarter rounds, so this section aint gonna be commented again #####

    # Quarter round on (1, 5, 9, 13)
    li a0, 1        # x = 1
    li a1, 5        # y = 5
    li a2, 9        # z = 9
    li a3, 13       # w = 13
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (2, 6, 10, 14)
    li a0, 2        # x = 2
    li a1, 6        # y = 6
    li a2, 10       # z = 10
    li a3, 14       # w = 14
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (3, 7, 11, 15)
    li a0, 3        # x = 3
    li a1, 7        # y = 7
    li a2, 11       # z = 11
    li a3, 15       # w = 15
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (0, 5, 10, 15)
    li a0, 0        # x = 0
    li a1, 5        # y = 5
    li a2, 10       # z = 10
    li a3, 15       # w = 15
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (1, 6, 11, 12)
    li a0, 1        # x = 1
    li a1, 6        # y = 6
    li a2, 11       # z = 11
    li a3, 12       # w = 12
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (2, 7, 8, 13)
    li a0, 2        # x = 2
    li a1, 7        # y = 7
    li a2, 8        # z = 8
    li a3, 13       # w = 13
    call compute_addresses
    call assign_addresses
    call quarter_round
    # Quarter round on (3, 4, 9, 14)
    li a0, 3        # x = 3
    li a1, 4        # y = 4
    li a2, 9        # z = 9
    li a3, 14       # w = 14
    call compute_addresses
    call assign_addresses
    call quarter_round

    # restaurar registros
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
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
    lw t3, 0(s1)    # a = state[x]
    lw t4, 0(s2)    # b = state[y]
    lw t5, 0(s3)    # c = state[z]
    lw t6, 0(s4)    # d = state[w]
    ret
