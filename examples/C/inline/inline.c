// inline.c
// David_Harris@hmc.edu 12 January 2022
// Illustrates inline assembly language

#include <stdio.h>

int main(void) {
    long cycles;
    asm volatile("csrr %0, 0xB00" : "=r"(cycles)); // read mcycle register
    printf ("mcycle = %ld\n", cycles);

    int a = 3;
    int b = 4;
    int c;

    // write inline assembly for c = a + 2*b
    asm volatile("slli %1, %1, 1" : "=r"(c) : "r"(b));
    asm volatile("add %1, %2, %1" : "=r"(c) : "r"(a), "r"(c));

    printf("c= %d", c); 
}
