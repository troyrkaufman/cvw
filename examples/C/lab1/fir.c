#include <stdio.h>  // supports printf
#include "util.h"   // supports verify

extern void fir(int [], int [], int [], int, int);

// # of cycles needed to complete algorithm (includes optimization)
// -NA: mcycle = 6444   (if print statement -> 433249)
// -O:  mcycle = 763    (if print statement -> 158949)
// -O2: mcycle = 766    (if print statement -> 123149)


// Add two Q1.31 fixed point numbers
int add_q31(int a, int b) {
    // your code here
    return a + b;
}


// Multiplly two Q1.31 fixed point numbers
int mul_q31(int a, int b) {
    // your code here; consider computing a 64-bit Q2.62 res and 32-bit Q1.31 result
    int result;
    int64_t res = ((int64_t)a * (int64_t)b);
    result = (int32_t)(res >> 31);
    //printf("mul_q31: a = %x, b = %x, res = %lx, result = %x\n", a, b, res, result);
    return result;
}
/*
// low pass filter x with coefficients c, result in y
// n is the length of x, m is the length of c
// y[i] = c[0]*x[i] + c[1]*x[i+1] + ... + c[m-1]*x[i+m-1]
// inputs in Q1.31 format
void fir(int x[], int c[], int y[], int n, int m) {
    // your code here, use add_q31 and mul_q31
    for (int i = 0; i <= (n - m + 1); i++){
        int round_val = 0;
        int temp = 0;
        for (int j = 0; j <= (m - 1); j++){
            temp = mul_q31(c[j], x[i - j + (m - 1)]);
            round_val = add_q31(temp, round_val);
        }
        y[i] = round_val;
    }
}
*/
int main(void) {
    int32_t sin_table[20] = { // in Q1.31 format
        0x00000000, // sin(0*2pi/10)
        0x4B3C8C12, // sin(1*2pi/10)
        0x79BC384D, // sin(2*2pi/10)
        0x79BC384D, // sin(3*2pi/10)
        0x4B3C8C12, // sin(4*2pi/10)
        0x00000000, // sin(5*2pi/10)
        0xB4C373EE, // sin(6*2pi/10)
        0x8643C7B3, // sin(7*2pi/10)
        0x8643C7B3, // sin(8*2pi/10)
        0xB4C373EE, // sin(9*2pi/10)
        0x00000000, // sin(10*2pi/10)
        0x4B3C8C12, // sin(11*2pi/10)
        0x79BC384D, // sin(12*2pi/10)
        0x79BC384D, // sin(13*2pi/10)
        0x4B3C8C12, // sin(14*2pi/10)
        0x00000000, // sin(15*2pi/10)
        0xB4C373EE, // sin(16*2pi/10)
        0x8643C7B3, // sin(17*2pi/10)
        0x8643C7B3, // sin(18*2pi/10)
        0xB4C373EE  // sin(19*2pi/10)
    };  
    //printf("Attempting to see if something works");


    int lowpass[4] = {0x20000001, 0x20000002, 0x20000003, 0x20000004}; // 1/4 in Q1.31 format
    int y[17];
    int expected[17] = { // in Q1.31 format
        0x4fad3f2f,
        0x627c6236,
        0x4fad3f32,
        0x1e6f0e17,
        0xe190f1eb,
        0xb052c0ce,
        0x9d839dc6,
        0xb052c0cb,
        0xe190f1e6,
        0x1e6f0e12,
        0x4fad3f2f,
        0x627c6236,
        0x4fad3f32,
        0x1e6f0e17,
        0xe190f1eb,
        0xb052c0ce,
        0x9d839dc6
    };
    setStats(1);        // record initial mcycle and minstret
    //printf("Attempting to see if something works #1\n");
    fir(sin_table, lowpass, y, 20, 4);
    //printf("Attempting to see if something works #2");
    setStats(0);        // record elapsed mcycle and minstret
    for (int i=0; i<17; i++) {
        printf("y[%d] = %x\n", i, y[i]);
    }
    return verify(16, y, expected);
// check the 1 element of s matches expected. 0 means success
}
