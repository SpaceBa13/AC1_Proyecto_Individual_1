.section .data


original_constants:
    .word 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574

state:
    # constants
    .word 0, 0, 0, 0
    # key
    .space 32
    # counter
    .space 4
    # nonce
    .space 12

working_state:
    .word 0,0,0,0
    .word 0,0,0,0
    .word 0,0,0,0
    .word 0,0,0,0

.globl serialized_block
serialized_block:
    .space 64

.section .text
copy_state_to_working:
    la t0, state           # t0 apunta al inicio de state
    la t1, working_state   # t1 apunta al inicio de working_state
    li t2, 16              # contador de palabras

copy_loop:
    lw t3, 0(t0)           # cargar palabra de state
    sw t3, 0(t1)           # almacenar palabra en working_state
    addi t0, t0, 4         # avanzar al siguiente elemento de state
    addi t1, t1, 4         # avanzar al siguiente elemento de working_state
    addi t2, t2, -1        # decrementar contador
    bnez t2, copy_loop      # repetir hasta copiar las 16 palabras
    ret

add_working_to_state:
    la t4, state
    la t5, working_state
    li t0, 0
loop_add:
    lw t1, 0(t4)
    lw t2, 0(t5)
    add t1, t1, t2
    sw t1, 0(t4)
    addi t4, t4, 4
    addi t5, t5, 4
    addi t0, t0, 1
    li t3, 16
    blt t0, t3, loop_add
    ret

loop_inner_block:
    addi sp, sp, -16
    sw ra, 12(sp)   # proteger ra
    sw s5, 8(sp)    # opcional: proteger s5

loop_start:
    la s0, working_state
    call inner_block
    addi s5, s5, -1
    bnez s5, loop_start

    lw s5, 8(sp)    # restaurar s5
    lw ra, 12(sp)   # restaurar ra
    addi sp, sp, 16
    ret


.globl chacha20_block
chacha20_block:
    # inputs: a0 key, a1 counter, a2 nonce
    addi sp, sp, -16
    sw ra, 12(sp)   # proteger ra
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0        # s0 = key pointer
    mv s1, a1        # s1 = counter pointer
    mv s2, a2        # s2 = nonce pointer

    # Load constants on state (0-15)
    la t1, original_constants      # t1 = &constants[0]
    la t2, state                   # t2 = &state[0]

    lw t0, 0(t1)                   # Load constant0
    sw t0, 0(t2)                   # state[0] = 0x61707865
    lw t0, 4(t1)                   # Load constant1
    sw t0, 4(t2)                   # state[1] = 0x3320646e
    lw t0, 8(t1)                   # Load constant2
    sw t0, 8(t2)                   # state[2] = 0x79622d32
    lw t0, 12(t1)                  # Load constant3
    sw t0, 12(t2)                  # state[3] = 0x6b206574

    # Load KEY en state (16-47)
    lw t0, 0(s0)       # Load key[0]
    sw t0, 16(t2)      # Store at state[4]
    lw t0, 4(s0)       # Load key[1]
    sw t0, 20(t2)      # Store at state[5]
    lw t0, 8(s0)       # Load key[2]
    sw t0, 24(t2)      # Store at state[6]
    lw t0, 12(s0)      # Load key[3]
    sw t0, 28(t2)      # Store at state[7]
    lw t0, 16(s0)      # Load key[4]
    sw t0, 32(t2)      # Store at state[8]
    lw t0, 20(s0)      # Load key[5]
    sw t0, 36(t2)      # Store at state[9]
    lw t0, 24(s0)      # Load key[6]
    sw t0, 40(t2)      # Store at state[10]
    lw t0, 28(s0)      # Load key[7]
    sw t0, 44(t2)      # Store at state[11] 

    # Cargar COUNTER en state (48-51)
    # counter está en s1
    lw t0, 0(s1)       # Load counter value
    sw t0, 48(t2)      # Store at state[12]

    # Cargar NONCE en state (52-63)
    # nonce está en s2
    lw t0, 0(s2)       # Load nonce[0]
    sw t0, 52(t2)      # Store at state[13]
    lw t0, 4(s2)       # Load nonce[1]
    sw t0, 56(t2)      # Store at state[14]
    lw t0, 8(s2)       # Load nonce[2]
    sw t0, 60(t2)      # Store at state[15]

    # This block implements the ChaCha20 principal block function
    call copy_state_to_working
    li s5, 10
    call loop_inner_block
    call add_working_to_state
    call serialize_state

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


.globl serialize_state
serialize_state:
# This function serializes the state into a contiguous block of memory
    la t0, state              # origen
    la t1, serialized_block   # destino
    li t2, 16                 # 16 words

serialize_loop:
# This loop serializes the state into a contiguous block of memory
    lw t3, 0(t0)              # cargar word
    sw t3, 0(t1)              # guardar word
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, -1
    bnez t2, serialize_loop
    ret

