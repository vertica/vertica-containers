// Code borrows extensively from an example in
// https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/instance/index.html

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "udx_wasm.h"

const char* progname;

int main(int argc, const char* argv[]) {
    char* errormsg;
    progname = argv[0];
    void* ws = udx_get_wasm_state();

    if(argc != 2) {
        fprintf(stderr, "%s: Usage: %s wasm-file\n", progname, progname);
        return 1;
    }
    const char* filename = argv[1];
    printf("Loading wasm code...\n");

    if(! udx_setup(filename, ws, "sum", &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }

    int result;
    int a = 10;
    int b = 34;
    if(! udx_call_func(a, b, &result, ws, &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }
    printf("%s: result of adding **** %d + %d is %d *****\n", progname, a, b, result);
    if(result != a + b) {
        fprintf(stderr, "%s: ****ERROR**** return value does not equal %d\n",
                progname,
                a+b);
        return 1;
    }
    else {
        printf("%s: Happy, happy, joy, joy\n", progname);
    }
    udx_cleanup(ws);
    return 0;
}
