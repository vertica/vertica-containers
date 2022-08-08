/*
 * simple scalar function for benchmarks, int input, int output
 *
 * Create Date: 17 Feb 2022
 */
#include "Vertica.h"
#include <sstream>

using namespace Vertica;
class nonWasmUDx_sum : public ScalarFunction
{
    public:
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
                if (argReader.isNull(0) || argReader.isNull(1)) {
                    resWriter.setNull();
                } else {
                    int result = 0;
                    const int a = static_cast<int>(argReader.getIntRef(0));
                    const int b = static_cast<int>(argReader.getIntRef(1));
                    result = a + b;
                    resWriter.setInt(static_cast<vint>(result));
                }
                resWriter.next();
            } while (argReader.next());
        } catch(std::exception& e) {
            // Standard exception. Quit.
            vt_report_error(0, "Exception while processing block: [%s]", e.what());
        }
    }
};

class nonWasmUDx_sumFactory : public ScalarFunctionFactory
{
    // return an instance of Add2Ints to perform the actual addition.
    virtual ScalarFunction *createScalarFunction(ServerInterface &interface)
    { return vt_createFuncObject<nonWasmUDx_sum>(interface.allocator); }

    // This function returns the description of the input and outputs of the
    // Add2Ints class's processBlock function.  It stores this information in
    // two ColumnTypes objects, one for the input parameters, and one for
    // the return value.
    virtual void getPrototype(ServerInterface &interface,
                              ColumnTypes &argTypes,
                              ColumnTypes &returnType)
    {
        argTypes.addInt();
        argTypes.addInt();
        // Note that ScalarFunctions *always* return a single value.
        returnType.addInt();
    }
};

RegisterFactory(nonWasmUDx_sumFactory);
