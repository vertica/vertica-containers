// Code borrows extensively from an example in
// https://docs.rs/wasmer-c-api/latest/wasmer/wasm_c_api/instance/index.html

#include <errno.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>

#include "wasmer.h"
#include "udx_wasm.h"

#define EBUF_SIZE 256
static char ebuf[EBUF_SIZE+1];

// Having this static simplifies the C interface, but complicates things
// if you want to have more than one Wasm function in your program
static struct wasm_state {
    wasm_byte_vec_t wasm;
    wasm_engine_t* engine;
    wasm_store_t* store;
    wasm_module_t* module;
    wasm_extern_vec_t imports;
    wasm_trap_t* trap;
    wasm_instance_t* instance;
    wasm_extern_vec_t exports;
    wasm_func_t* func;
} STATIC_WASM_STATE;

#define MAX_NAME_SIZE 256

#define min(a,b)             \
({                           \
    __typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    _a < _b ? _a : _b;       \
})

// this is one way to turn a wasm_name_t into a C string
// I don't export it because of the use of a static buffer and
// silence about occurances of the wasm_name being too long for the static
static char* vwasm_name_to_static_string(const wasm_name_t *name) {
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
        for(int export_index = 0; export_index < exporttypes->size; ++export_index) {
            const wasm_externtype_t *etp = wasm_exporttype_type(exporttypes->data[export_index]);
            if(wasm_externtype_kind(etp) == WASM_EXTERN_FUNC) {
                // does the wasm_name_t match the function name?
                const wasm_name_t *namebytes = wasm_exporttype_name(exporttypes->data[export_index]);
                // No need to check for string equality if the lengths are different
                if(namebytes->size == strlen(name)) {
                    bool found_it = true;
                    // All characters match?
                    for(size_t ch_idx = 0; ch_idx < namebytes->size && found_it; ++ch_idx) {
                        if(namebytes->data[ch_idx] != name[ch_idx]) {
                            found_it = false;
                        }
                    }
                    if(found_it)
                        return wasm_extern_as_func(exports->data[export_index]);
                }
            }
        }
    }
    return NULL;
}

static void zero_wasm_state(struct wasm_state *ws) {
    bzero(ws, sizeof(struct wasm_state));
}

static void initialize_wasm_state(struct wasm_state *ws) {
    if(ws->wasm.data) free(ws->wasm.data);
    ws->wasm.data = NULL;
    if(ws->engine)
        wasm_engine_delete(ws->engine);
    ws->engine = NULL;
    if(ws->store)
        wasm_store_delete(ws->store);
    ws->store = NULL;
    if(ws->module)
        wasm_module_delete(ws->module);
    ws->module = NULL;
    if(ws->imports.data != NULL) {
        wasm_extern_vec_delete(&ws->imports);
        ws->imports.data = NULL;
        ws->imports.size = 0;
    }
    ws->trap = NULL;
    if(ws->instance)
        wasm_instance_delete(ws->instance);
    ws->instance = NULL;
    if(ws->exports.data) {
        wasm_extern_vec_delete(&ws->exports);
        ws->exports.data = NULL;
        ws->exports.size = 0;
    }
    ws->func = NULL;
}

const char* udx_query_wasm_config() {
    // I've learned about config --- does that help?

    wasm_config_t* config = wasm_config_new();

    // Use the Cranelift compiler, if available.
    /* if (wasmer_is_compiler_available(CRANELIFT)) { */
    /*     wasm_config_set_compiler(config, CRANELIFT); */
    /*     return "CRANELIFT"; */
    /* } */
    /* // Or maybe LLVM? */
    /* if (wasmer_is_compiler_available(LLVM)) { */
    /*     wasm_config_set_compiler(config, LLVM); */
    /*     return "LLVM"; */
    /* } */
    // Or maybe Singlepass?
    if (wasmer_is_compiler_available(SINGLEPASS)) {
        wasm_config_set_compiler(config, SINGLEPASS);
        return "SINGLEPASS";
    }
    return "Unknown";
}


void* udx_get_wasm_state() {
    zero_wasm_state(&STATIC_WASM_STATE);
    initialize_wasm_state(&STATIC_WASM_STATE);
    return &STATIC_WASM_STATE;
}

void udx_cleanup(void* v_ws) {
    struct wasm_state* ws = (struct wasm_state*) v_ws;
    initialize_wasm_state(ws);
}

bool udx_setup(const char* filename,
               void *v_ws,
               const char* func_name,
               char** error_str) {
    struct wasm_state* ws = (struct wasm_state*) v_ws;
    zero_wasm_state(ws);

    struct stat st;
    if(stat(filename, &st) < 0) {
        snprintf(ebuf,
                 EBUF_SIZE,
                 "Can't stat %s; %s",
                filename,
                strerror(errno));
        *error_str = ebuf;
        return false;
    }
    size_t code_len = st.st_size;
    char * code_buffer;

    if((code_buffer = (wasm_byte_t*) malloc(code_len)) == NULL) {
        snprintf(ebuf,
                 EBUF_SIZE,
                 "Can't malloc %ld bytes to hold %s; %s\n",
                code_len,
                filename,
                strerror(errno));
        *error_str = ebuf;
        return false;
    }
    FILE* file = fopen(filename, "r");
    if(fread(code_buffer, 1, code_len, file) != code_len) {
        free(code_buffer);
        snprintf(ebuf,
                 EBUF_SIZE,
                 "Can't read code from %s; %s",
                filename,
                strerror(errno));
        *error_str = ebuf;
        return false;
    }
    fclose(file);
    ws->wasm.size = code_len;
    ws->wasm.data = code_buffer;
    ws->engine = wasm_engine_new();
    ws->store = wasm_store_new(ws->engine);
    ws->module = wasm_module_new(ws->store, &ws->wasm);
    if(! ws->module) {
        initialize_wasm_state(ws);
        snprintf(ebuf,
                 EBUF_SIZE,
                 "Can't read code from %s; %s",
                filename,
                strerror(errno));
        *error_str = ebuf;
        return false;
    }
    ws->imports.data = NULL;
    ws->imports.size = 0;
    ws->trap = NULL;
    ws->instance = wasm_instance_new(ws->store,
                                     ws->module,
                                     &ws->imports,
                                     &ws->trap);
    if(! ws->instance) {
        initialize_wasm_state(ws);
        snprintf(ebuf, EBUF_SIZE, "Can't create wasm instance");
        *error_str = ebuf;
        return false;
    }

    wasm_instance_exports(ws->instance, &ws->exports);
    if(ws->exports.size <= 0) {
        initialize_wasm_state(ws);
        snprintf(ebuf, EBUF_SIZE, "Can't find any wasm exports");
        *error_str = ebuf;
        return false;
    }
    // This is annoying --- other languages have accessors to find the
    // function we want, but all I can do is run wasm2wat on the wasm
    // and see which export is reported as (export "sum" (func $sum))
    wasm_exporttype_vec_t exporttypes;
    wasm_module_exports(ws->module, &exporttypes);
    if(exporttypes.size == 0) {
        snprintf(ebuf, EBUF_SIZE, "Can't find wasm exporttypes");
        *error_str = ebuf;
        return false;
    }
    ws->func = vwasm_find_exported_function(func_name, &exporttypes, &ws->exports);
    if(! ws->func) {
        initialize_wasm_state(ws);
        snprintf(ebuf, EBUF_SIZE, "Can't find exported function '%s'", func_name);
        *error_str = ebuf;
        return false;
    }
    return true;
}

// This is a specialized function for wasm functions that take two ints and return an int
bool udx_call_func_2i_1i(int a, int b, int *result, void* v_ws, char** error) {
    struct wasm_state* ws = (struct wasm_state*) v_ws;
    wasm_val_t args_val[2] = { WASM_I32_VAL(a), WASM_I32_VAL(b) };
    wasm_val_t results_val[1] = { WASM_INIT_VAL };
    wasm_val_vec_t args = WASM_ARRAY_VEC(args_val);
    wasm_val_vec_t results = WASM_ARRAY_VEC(results_val);

    if (wasm_func_call(ws->func, &args, &results)) {
        *error = "> Error calling the `sum` function!";
        return false;
    }

    *error = NULL;
    *result = results_val[0].of.i32;
    return true;
}
