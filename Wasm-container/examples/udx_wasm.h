#ifndef udx_wasm_h
#define udx_wasm_h
#include <stdbool.h>
#include "wasmer.h"

void* udx_get_wasm_state();

bool udx_setup(const char* filename,
               void* ws,
               const char* func_name,
               char **place_to_put_errormsg_ptr);
void udx_cleanup(void* ws);

bool udx_call_func(const int a,
                   const int b,
                   int *place_to_put_result,
                   void* ws,
                   char** place_to_put_errormsg_ptr);

wasm_func_t *vwasm_find_exported_function(const char* name,
                                          wasm_exporttype_vec_t *exporttypes,
                                          wasm_extern_vec_t *exports);

#endif // udx_wasm_h
