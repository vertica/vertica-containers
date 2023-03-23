/*
 * simple scalar function for benchmarks, two ints input, int output
 */
#include "Vertica.h"
#include <sstream>
extern "C" {
#include "udx_wasm.h"
}

using namespace Vertica;
class cFibUDx_fib : public ScalarFunction
{
    void* ws;
    const char* wasm_file;
    public:
    virtual void setup(ServerInterface &srvInterface, const SizedColumnTypes &argtypes) {
        char* error_str;
        // WASMFILE is passed as -DWASMFILE=\"absolute-path-of-fib.c.wsm\"
        // when compiling
        wasm_file = WASMFILE;
        ws = udx_get_wasm_state();
        // Identify the function to load from the module
        if(! udx_setup(wasm_file, ws, "fib", &error_str)) {
            vt_report_error(0,
                            "Cannot initialize wasm from %s; %s",
                            wasm_file,
                            error_str);
        }
    }

    virtual void destroy(ServerInterface &srvInterface, const SizedColumnTypes &argtypes) {
        udx_cleanup(ws);
    }
   /*
     * This method processes a block of rows in a single invocation.
     *
     * The inputs are retrieved via argReader
     * The outputs are returned via resWriter
     */
    virtual void processBlock(ServerInterface &srvInterface,
                              BlockReader &argReader,
                              BlockWriter &resWriter)
    {
        try {
            // While we have inputs to process
            do {
                if (argReader.isNull(0)) {
                    resWriter.setNull();
                } else {
                    char *error_str;
                    unsigned long long result = 0;
                    const unsigned long long a = static_cast<unsigned long long>(argReader.getIntRef(0));
                    // Function takes 2 ints, returns 1 int
                    if(! udx_call_func_ull_ull(a, &result, ws, &error_str)) {
                        vt_report_error(0,
                                        "wasm_function_call to %s failed: %s",
                                        wasm_file,
                                        error_str);
                    }
                    resWriter.setInt(static_cast<vint>(result & 0xffffffff));
                }
                resWriter.next();
            } while (argReader.next());
        } catch(std::exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing block: [%s]", e.what());
        }
    }
};

class cFibUDx_fibFactory : public ScalarFunctionFactory
{
    // return an instance of Add2Ints to perform the actual addition.
    virtual ScalarFunction *createScalarFunction(ServerInterface &interface)
    { return vt_createFuncObject<cFibUDx_fib>(interface.allocator); }

    // This function returns the description of the input and outputs of the
    // Add2Ints class's processBlock function.  It stores this information in
    // two ColumnTypes objects, one for the input parameters, and one for
    // the return value.
    virtual void getPrototype(ServerInterface &interface,
                              ColumnTypes &argTypes,
                              ColumnTypes &returnType)
    {
        // Function takes 2 int arguments, returns 1 int result
        argTypes.addInt();
        // Note that ScalarFunctions *always* return a single value.
        returnType.addInt();
    }
};

RegisterFactory(cFibUDx_fibFactory);
