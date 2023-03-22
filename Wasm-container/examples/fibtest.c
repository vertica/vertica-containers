#include <stdio.h>

extern unsigned long long fib(unsigned long long);

int main(int argc, char** argv) {
    //  1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987
    for(int i = 2; i < 20; ++i) {
        printf("fib[%d] = %llu\n", i, fib(i));
    }
    // binet returns 2971215073 for fib[47] --- fits in 32 bits
    printf("fib[47] = %llu\n", fib(47));
    // binet's formula gives 12586269025
    printf("fib[50] = %llu\n", fib(50));
    // 2111485077978055, but warns of inaccuracy
    printf("fib[75] = %llu\n", fib(75));
    // meaningless
    printf("fib[4998] = %llu\n", fib(4998));
    return 0;
}
