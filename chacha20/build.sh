#!/bin/bash

# Build script for C+assembly chacha_program
echo "Building C+assembly chacha_program..."

# Compile C source to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    chacha_program.c \
    -o chacha_program.o

if [ $? -ne 0 ]; then
    echo "C compilation failed"
    exit 1
fi

# Compile startup assembly to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    startup.s \
    -o startup.o

if [ $? -ne 0 ]; then
    echo "Startup assembly compilation failed"
    exit 1
fi

# Compile math assembly source to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    chacha20_encrypt.s \
    -o chacha20_encrypt.o

if [ $? -ne 0 ]; then
    echo "Math assembly compilation failed"
    exit 1
fi

# Compile inner_block assembly source to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    inner_block.s \
    -o inner_block.o

if [ $? -ne 0 ]; then
    echo "inner_block assembly compilation failed"
    exit 1
fi

# Compile inner_block assembly source to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    quarter_round.s \
    -o quarter_round.o

if [ $? -ne 0 ]; then
    echo "quarter_round assembly compilation failed"
    exit 1
fi

# Compile inner_block assembly source to object file
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    -c \
    chacha20_block.s \
    -o chacha20_block.o

if [ $? -ne 0 ]; then
    echo "chacha20_block assembly compilation failed"
    exit 1
fi

# Link object files together
riscv64-unknown-elf-gcc \
    -march=rv32im \
    -mabi=ilp32 \
    -nostdlib \
    -ffreestanding \
    -g3 \
    -gdwarf-4 \
    startup.o \
    chacha_program.o \
    chacha20_encrypt.o \
    inner_block.o \
    quarter_round.o \
    chacha20_block.o \
    -T linker.ld \
    -o chacha_program.elf

if [ $? -eq 0 ]; then
    echo "Build successful: chacha_program.elf created"
    echo "Object files: chacha_program.o, chacha20_encrypt.o"
else
    echo "Linking failed"
    exit 1
fi