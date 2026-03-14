// Simple C program that calls assembly function
// This demonstrates C+assembly integration in RISC-V

typedef unsigned int uint32_t;

uint32_t key[8] = {
    0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c,
    0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c
};

uint32_t nonce[3] = {
    0x09000000,
    0x4a000000,
    0x00000000
};

uint32_t counter = 1;

unsigned char message[] = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";

unsigned int message_len = sizeof(message) - 1;

// ChaCha20 assembly function
extern void chacha20_block(uint32_t *key, uint32_t *counter, uint32_t *nonce);

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

    chacha20_block(key,&counter, nonce);

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