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

    if(argc != 4) {
        fprintf(stderr, "%s: Usage: %s wasm-file function-name arg\n",
                progname,
                progname);
        return 1;
    }
    const char* filename = argv[1];
    const char* function = argv[2];
    const unsigned long long arg = (unsigned long long) atoll(argv[3]);
    printf("Loading wasm code...\n");

    if(! udx_setup(filename, ws, function, &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }

    unsigned long long result;
    unsigned long long a = arg;
    if(! udx_call_func_ull_ull(a, &result, ws, &errormsg)) {
        fprintf(stderr, "%s: %s\n", progname, errormsg);
        return 1;
    }
    printf("%s: result of %s(%llu): %llu\n",
           progname, function, a, result);
    udx_cleanup(ws);
    return 0;
}
