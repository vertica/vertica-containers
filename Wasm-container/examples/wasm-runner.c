// Code borrows extensively from an example in
// https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/instance/index.html

#include <errno.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

#include "wasmer.h"

#define min(a,b)             \
({                           \
    __typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    _a < _b ? _a : _b;       \
})

#define MAX_NAME_SIZE 256

const char* progname;

// The code (wasmer.h) is the documentation....
char* vwasm_name_to_static_string(const wasm_name_t *name) {
    static char buffer[MAX_NAME_SIZE];
    for(int i = 0; i < name->size && i < sizeof(buffer)-2; ++i) {
        buffer[i] = name->data[i];
    }
    buffer[min(sizeof(buffer)-1, name->size)] = '\0';
    return buffer;
}

// This is annoying --- other languages have accessors to find the
// function we want.  This is a little dicey, since it is derived
// from dimensional analysis of the function prototypes, not from
// any specification.
wasm_func_t *vwasm_find_exported_function(const char* name,
                                          wasm_exporttype_vec_t *exporttypes,
                                          wasm_extern_vec_t *exports) {
    if(exporttypes->size != 0) {
        for(int i = 0; i < exporttypes->size; ++i) {
            const wasm_externtype_t *etp = wasm_exporttype_type(exporttypes->data[i]);
            if(wasm_externtype_kind(etp) == WASM_EXTERN_FUNC) {
                const char* export_name
                    = vwasm_name_to_static_string(wasm_exporttype_name(exporttypes->data[i]));
                if(strcmp(name, export_name) == 0) {
                    return wasm_extern_as_func(exports->data[i]);
                }
            }
        }
    }
    return NULL;
}

int main(int argc, const char* argv[]) {
    progname = argv[0];

    if(argc != 2) {
        fprintf(stderr, "%s: Usage: %s wasm-file\n", progname, progname);
        return 1;
    }
    const char* filename = argv[1];
    struct stat st;
    if(stat(filename, &st) < 0) {
        fprintf(stderr, "%s: Can't stat %s; %s\n",
                progname,
                filename,
                strerror(errno));
        return 1;
    }
    size_t code_len = st.st_size;
    char * code_buffer;

    if((code_buffer = (wasm_byte_t*) malloc(code_len)) == NULL) {
        fprintf(stderr, "%s: Can't malloc %ld bytes to hold %s; %s\n",
                progname,
                code_len,
                filename,
                strerror(errno));
        return 1;
    }
    printf("Loading wasm code...\n");
    FILE* file = fopen(filename, "r");
    assert(fread(code_buffer, 1, code_len, file) == code_len);
    fclose(file);
    wasm_byte_vec_t wasm = { code_len, code_buffer };

    wasm_engine_t* engine = wasm_engine_new();
    wasm_store_t* store = wasm_store_new(engine);
    wasm_module_t* module = wasm_module_new(store, &wasm);
    assert(module);

    wasm_extern_vec_t imports = WASM_EMPTY_VEC;
    wasm_trap_t* trap = NULL;

    wasm_instance_t* instance = wasm_instance_new(store, module, &imports, &trap);
    assert(instance);

    wasm_extern_vec_t exports;
    wasm_instance_exports(instance, &exports);
    assert(exports.size > 0);

    printf("Using wasm_instance_exports:\n");
    for(int i = 0; i < exports.size; ++i) {
        char *type = "unrecognized";
        switch(wasm_extern_kind(exports.data[i])) {
        case WASM_EXTERN_FUNC:
            type = "func";
            break;
        case WASM_EXTERN_GLOBAL:
            type = "global";
            break;
        case WASM_EXTERN_TABLE:
            type = "table";
            break;
        case WASM_EXTERN_MEMORY:
            type = "memory";
            break;
        }
        printf("export.data[%d] is type %s\n", i, type);
    }
    printf("using wasm_module_exports:\n");
    wasm_exporttype_vec_t exporttypes;
    wasm_module_exports(module, &exporttypes);
    if(exporttypes.size == 0) {
        printf("wasm_module_exports didn't give me anything\n");
    }
    else
    {
        for(int i = 0; i < exporttypes.size; ++i) {
            char *type = "unrecognized";
            const wasm_externtype_t *etp = wasm_exporttype_type(exporttypes.data[i]);

            switch(wasm_externtype_kind(etp)) {
            case WASM_EXTERN_FUNC:
                type = "func";
                break;
            case WASM_EXTERN_GLOBAL:
                type = "global";
                break;
            case WASM_EXTERN_TABLE:
                type = "table";
                break;
            case WASM_EXTERN_MEMORY:
                type = "memory";
                break;
            }
            printf("export.data[%d] is type %s\n", i, type);
            printf("export.data[%d] has name %s\n",
                   i,
                   vwasm_name_to_static_string(wasm_exporttype_name(exporttypes.data[i])));
        }
    }

    printf("Retrieving the `sum` function...\n");
    wasm_func_t* sum_func = vwasm_find_exported_function("sum", &exporttypes, &exports);
    assert(sum_func);

    printf("Calling `sum` function...\n");
    wasm_val_t args_val[2] = { WASM_I32_VAL(3), WASM_I32_VAL(4) };
    wasm_val_t results_val[1] = { WASM_INIT_VAL };
    wasm_val_vec_t args = WASM_ARRAY_VEC(args_val);
    wasm_val_vec_t results = WASM_ARRAY_VEC(results_val);

    if (wasm_func_call(sum_func, &args, &results)) {
        printf("> Error calling the `sum` function!\n");
        return 1;
    }

    printf("Results of `sum`: %d\n", results_val[0].of.i32);

    wasm_module_delete(module);
    wasm_extern_vec_delete(&exports);
    wasm_instance_delete(instance);
    free(wasm.data); // wasm_byte_vec_delete(&wasm);
    wasm_store_delete(store);
    wasm_engine_delete(engine);
}
