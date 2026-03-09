// Simple C program that calls assembly function
// This demonstrates C+assembly integration in RISC-V

// Assembly function declaration
extern int sum_to_n(int n);

// Assembly function declaration
extern int rotate_left(int x, int n);


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

// Entry point for C program
void main() {
    // Test the assembly function with different values
    int test_values[] = {5, 10, 15, 0, -1};
    int num_tests = 5;
    
    print_string("Testing sum_to_n assembly function:\n");
    
    for (int i = 0; i < num_tests; i++) {
        int n = test_values[i];
        int result = sum_to_n(n);
        
        print_string("sum_to_n(");
        print_number(n);
        print_string(") = ");
        print_number(result);
        print_string("\n");
    }

    // Ahora probamos rotate_left
    int rot_tests[][2] = {
        {0x12345678, 4},
        {0xdeadbeef, 8},
        {0x01020304, 16},
    };
    int num_rot = 3;

    print_string("Testing rotate_left assembly function:\n");

    for (int i = 0; i < num_rot; i++) {
        int x = rot_tests[i][0];
        int n = rot_tests[i][1];
        int r = rotate_left(x, n);
        
        print_string("rotate_left(0x");
        print_number(x);
        print_string(", ");
        print_number(n);
        print_string(") = 0x");
        print_number(r);
        print_string("\n");
    }

    print_string("Tests completed.\n");
    
    
    // Infinite loop to keep program running
    while (1) {
        __asm__ volatile ("nop");
    }
}