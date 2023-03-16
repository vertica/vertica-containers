// Code borrows extensively from an example in
// https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/instance/index.html

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include "udx_wasm.h"

const char* progname;

unsigned long long fib(unsigned long long a) {
    unsigned long long i;
    unsigned long long prev = 1;
    unsigned long long cur = 1;;
    for(i = 2; i < a; i++) {
        unsigned long long tmp = cur;
        cur = cur + prev;
        prev = tmp;
    }
    return cur;
}



int main(int argc, const char* argv[]) {
    char* errormsg;
    progname = argv[0];
    void* ws = udx_get_wasm_state();

    if(argc != 5) {
        fprintf(stderr,
                "%s: Usage: %s wasm-file function-name arg loop-count\n",
                progname,
                progname);
        return 1;
    }
    const char* filename = argv[1];
    const char* function = argv[2];
    const unsigned long long arg = (unsigned long long) atoll(argv[3]);
    const int loop_count = atoi(argv[4]);
    unsigned long long result;
    unsigned long long wasm_result;

    printf("Loading wasm code...\n");

    if(! udx_setup(filename, ws, function, &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }

    clock_t start, end;
    printf("%ld ticks per second\n", CLOCKS_PER_SEC);
    start = clock();
    unsigned long long a;
    for(int i = 0; i < loop_count; ++i) {
        if(arg > 2*loop_count) {
            a = arg + (2 * i) - loop_count;
        }
        else {
            a = arg;
        }
        if(! udx_call_func_ull_ull(a, &result, ws, &errormsg)) {
            fprintf(stderr, "%s: %s\n", progname, errormsg);
            return 1;
        }
    }
    end = clock();
    printf("%d passes of %s(%s) took %ld ticks\n",
           loop_count,
           filename,
           function,
           end - start);
    double wasm_time = end - start;

    // recalculate the arg value because I want to compare results with C
    a = arg;
    if(! udx_call_func_ull_ull(a, &result, ws, &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }
    wasm_result = result;

    start = clock();
    for(int i = 0; i < loop_count; ++i) {
        unsigned long long a = arg;
        result = fib(a);
    }
    end = clock();
    printf("%d passes of fib() took %ld ticks\n",
           loop_count,
           end - start);

    double c_time = end - start;
    // just to be sure the optimizer doesn't optimize out the loop
    printf("ratio of wasm/c: %f\n", wasm_time/c_time);
    printf("fib(%llu) is      %llu\n", arg, result);
    printf("wasm fib(%llu) is %llu\n", arg, wasm_result);

    udx_cleanup(ws);
    return 0;
}
