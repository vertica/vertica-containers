// g++ -std=c++11 comparison.cpp -o comparison

#include <chrono>
#include <iostream>
#include <random>

extern "C" {
#include "udx_wasm.h"
};

#define ARRAY_SIZE 1'000'000

int subroutine_sum(const int a, const int b) {
    return a + b;
}

void populate(int data[], int size) {
    unsigned seed = std::chrono::high_resolution_clock::now().time_since_epoch().count();
    std::default_random_engine generator(seed);
    std::uniform_int_distribution<int> distribution(0, 255); // fits in a byte
    for (int i = 0; i < size; ++i) {
        data[i] = distribution(generator);
    }
}

void check_results(const int a_result[],
                   const int b_result[],
                   const int size,
                   const char* a_label,
                   const char* b_label) {
    for(int i = 0; i < size; ++i) {
        if(a_result[i] != a_result[i]) {
            std::cerr << "Surprise! "
                      << a_label
                      << " and "
                      << b_label
                      << " results differ at "
                      << i
                      << "th location!"
                      << std::endl << std::flush;
            return;
        }
    }
}

// declared as BSS they can be bigger than on the stack
int direct_result[ARRAY_SIZE];
int subroutine_result[ARRAY_SIZE];
int c_result[ARRAY_SIZE];
int rust_result[ARRAY_SIZE];
int a_data[ARRAY_SIZE];
int b_data[ARRAY_SIZE];

int main(const int argc, const char* argv[]) {
    char* errormsg;

    populate(a_data, sizeof(a_data)/sizeof(a_data[0]));
    populate(b_data, sizeof(b_data)/sizeof(b_data[0]));

    // direct time
    auto start = std::chrono::high_resolution_clock::now();
    for(int i = 0; i < ARRAY_SIZE; ++i) {
        direct_result[i] = a_data[i] + b_data[i];
    }
    auto stop = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
    std::cout << "Direct time: " << duration.count() << std::endl << std::flush;

    // subroutine time
    start = std::chrono::high_resolution_clock::now();
    for(int i = 0; i < ARRAY_SIZE; ++i) {
        subroutine_result[i] = subroutine_sum(a_data[i], b_data[i]);
    }
    stop = std::chrono::high_resolution_clock::now();
    duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
    std::cout << "Subroutine time: " << duration.count() << std::endl << std::flush;
    // This stuff actually works, right?
    check_results(direct_result,
                  subroutine_result,
                  sizeof(b_data)/sizeof(b_data[0]),
                  "direct",
                  "subroutine");

    // set up C wasm engine
    void* ws = udx_get_wasm_state();
    if(! udx_setup("sum.c.wasm", ws, "sum", &errormsg))
        std::cerr << "Can't load sum.c.wasm; " << errormsg << std::endl << std::flush;
    else {
        // c_wasm time
        start = std::chrono::high_resolution_clock::now();
        for(int i = 0; i < ARRAY_SIZE; ++i) {
            if(! udx_call_func_2i_1i(a_data[i], b_data[i], &c_result[i], ws, &errormsg)) {
                std::cerr << "Can't execute rustwasm_sum function on "
                          << i
                          << "th entry; "
                          << errormsg
                          << std::endl << std::flush;
                break;
            }
        }
        stop = std::chrono::high_resolution_clock::now();
        duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
        std::cout << "CWasm time: " << duration.count() << std::endl << std::flush;
        // This stuff actually did something, right?
        check_results(direct_result,
                      c_result,
                      sizeof(b_data)/sizeof(b_data[0]),
                      "direct",
                      "cwasm");
    }
    udx_cleanup(ws);
    // set up rust wasm engine
    ws = udx_get_wasm_state();
    if(! udx_setup("sum.rs.wasm", ws, "sum", &errormsg))
        std::cerr << "Can't load sum.rs.wasm; " << errormsg << std::endl << std::flush;
    else {
        // rust_wasm time
        start = std::chrono::high_resolution_clock::now();
        for(int i = 0; i < ARRAY_SIZE; ++i) {
            if(! udx_call_func_2i_1i(a_data[i], b_data[i], &rust_result[i], ws, &errormsg)) {
                std::cerr << "Can't execute rustwasm_sum function on "
                          << i
                          << "th entry; "
                          << errormsg
                          << std::endl << std::flush;
                break;
            }
        }
        stop = std::chrono::high_resolution_clock::now();
        duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
        std::cout << "Rustasm time: " << duration.count() << std::endl << std::flush;
        // This stuff actually did something, right?
        check_results(direct_result,
                      rust_result,
                      sizeof(b_data)/sizeof(b_data[0]),
                      "direct",
                      "rustwasm");
    }
}
