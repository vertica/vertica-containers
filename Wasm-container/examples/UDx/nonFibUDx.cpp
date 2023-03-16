/*
 * simple scalar function for benchmarks, int input, int output
 *
 * Create Date: 17 Feb 2022
 */
#include "Vertica.h"
#include <sstream>

static unsigned long long fib(unsigned long long a) {
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


using namespace Vertica;
class nonFibUDx_fib : public ScalarFunction
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
                if (argReader.isNull(0)) {
                    resWriter.setNull();
                } else {
                    unsigned long long result = 0;
                    const unsigned long long a = static_cast<unsigned long long>(argReader.getIntRef(0));
                    result = fib(a);
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

class nonFibUDx_fibFactory : public ScalarFunctionFactory
{
    // return an instance of Add2Ints to perform the actual addition.
    virtual ScalarFunction *createScalarFunction(ServerInterface &interface)
    { return vt_createFuncObject<nonFibUDx_fib>(interface.allocator); }

    // This function returns the description of the input and outputs of the
    // Add2Ints class's processBlock function.  It stores this information in
    // two ColumnTypes objects, one for the input parameters, and one for
    // the return value.
    virtual void getPrototype(ServerInterface &interface,
                              ColumnTypes &argTypes,
                              ColumnTypes &returnType)
    {
        argTypes.addInt();
        // Note that ScalarFunctions *always* return a single value.
        returnType.addInt();
    }
};

RegisterFactory(nonFibUDx_fibFactory);
