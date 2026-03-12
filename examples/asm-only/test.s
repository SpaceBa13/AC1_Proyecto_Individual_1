
.section .data

state:
    # constants
    .word 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
    # key
    .word 0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c
    .word 0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c
    # counter + nonce
    .word 0x00000001, 0x09000000, 0x4a000000, 0x00000000

working_state:
    .word 0,0,0,0
    .word 0,0,0,0
    .word 0,0,0,0
    .word 0,0,0,0

serialized_block:
    .space 64


.section .text
.globl _start
_start:
    la s0, state # Load address of state into s0 for use in quarter_round function
    la s1, working_state
    li sp, 0x80010000  # stack seguro en memoria libre
    call chacha20_block
    call end


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
    mv t4, s0     # guardar base de state
    mv t5, s1     # guardar base de working_state
    li t0, 0      # índice
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
    call inner_block
    addi s5, s5, -1
    bnez s5, loop_start

    lw s5, 8(sp)    # restaurar s5
    lw ra, 12(sp)   # restaurar ra
    addi sp, sp, 16
    ret


chacha20_block:
    addi sp, sp, -16
    sw ra, 12(sp)   # proteger ra
    # This block implements the ChaCha20 principal block function
    call copy_state_to_working
    li s5, 10
    call loop_inner_block
    call add_working_to_state
    call serialize_state
    lw ra, 12(sp)   # restaurar ra
    addi sp, sp, 16
    ret


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
    lw ra, 12(sp)   # restaurar ra
    ret


end:
    j end
    # The program ends here, but we loop infinitely to keep the QEMU session alive.
