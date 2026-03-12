// Simple C program that calls assembly function
// This demonstrates C+assembly integration in RISC-V


// ChaCha20 assembly function
extern void chacha20_block();

// Buffer generado en ASM
extern unsigned char serialized_block[64];

// Simple implementation of basic functions since we're in bare-metal environment
void print_char(char c) {
    // In a real bare-metal environment, this would write to UART
    // For now, this is just a placeholder
    volatile char *uart = (volatile char*)0x10000000;
    *uart = c;
}

void print_number(int num) {
    if (num == 0) {
        print_char('0');
        return;
    }
    
    if (num < 0) {
        print_char('-');
        num = -num;
    }
    
    char buffer[10];
    int i = 0;
    
    while (num > 0) {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }
    
    // Print digits in reverse order
    while (i > 0) {
        print_char(buffer[--i]);
    }
}

void print_string(const char* str) {
    while (*str) {
        print_char(*str++);
    }
}

void print_hex_byte(unsigned char b) {
    char hex[] = "0123456789abcdef";
    print_char(hex[(b >> 4) & 0xF]);
    print_char(hex[b & 0xF]);
}


// Entry point for C program
void main() {

    // -----------------------------
    // Test ChaCha20 block
    // -----------------------------

    print_string("Generating ChaCha20 block...\n");

    chacha20_block();

    print_string("Serialized Block:\n");

    for (int i = 0; i < 64; i++) {

        if (i % 16 == 0) {
            print_string("\n");
        }

        print_hex_byte(serialized_block[i]);
        print_char(' ');
    }

    print_string("\n\nChaCha20 block test completed.\n");


    print_string("Tests completed.\n");
    
    
    // Infinite loop to keep program running
    while (1) {
        __asm__ volatile ("nop");
    }
}