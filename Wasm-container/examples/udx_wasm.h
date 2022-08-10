#ifndef udx_wasm_h
#define udx_wasm_h
#include <stdbool.h>

void* udx_get_wasm_state();

bool udx_setup(const char* filename,
               void* ws,
               const char* func_name,
               char **place_to_put_errormsg_ptr);
void udx_cleanup(void* ws);

// 2 int args, returns 1 int
bool udx_call_func_2i_1i(const int a,
                         const int b,
                         int *place_to_put_result,
                         void* ws,
                         char** place_to_put_errormsg_ptr);
#endif // udx_wasm_h
