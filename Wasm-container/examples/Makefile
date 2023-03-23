# This means we can't "make clean" outside an environment that
# includes wasmer 
WASM_INCLUDE := ${shell wasmer config --includedir}
WASM_LIBS := ${shell wasmer config --libs}
WASM_LIBDIR := ${shell wasmer config --libdir}
WASM_CFLAGS := ${shell wasmer config --cflags}

all: run_hello run_abstract_runner

clean:
	rm -f wasmer-hello *.wasm *.o *.a *.so *~ abstract_runner comparison

wasmer-hello: wasmer-hello.c
	gcc wasmer-hello.c -I ${WASM_INCLUDE} ${WASM_LIBS} -o wasmer-hello

run_hello: wasmer-hello
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${WASM_LIBDIR} ./wasmer-hello

sum.rs.wasm: sum.rs
	rustc +stable --target wasm32-unknown-unknown -O --crate-type=cdylib \
		sum.rs -o sum.rs.wasm

# this doesn't work (yet)
# WASMBITS=64
WASMBITS=32
sum.c.wasm: sum.c
	clang --target=wasm${WASMBITS}-unknown-unknown \
	        -nostdlib \
	        -Wl,--no-entry \
	        -Wl,--export-all \
	        sum.c \
	        -o sum.c.wasm

fib.c.wasm: fib.c
	clang --target=wasm${WASMBITS}-unknown-unknown \
	        -nostdlib \
	        -Wl,--no-entry \
	        -Wl,--export-all \
	        fib.c \
	        -o fib.c.wasm

fib.rs.wasm: fib.rs
	rustc +stable --target wasm32-unknown-unknown -O --crate-type=cdylib \
		fib.rs -o fib.rs.wasm

fibtest: fibtest.c fib.c
	gcc -std=c99 fibtest.c fib.c -o fibtest

udx_wasm.o: udx_wasm.c udx_wasm.h
	gcc $(CFLAGS) -c -fpic -Werror udx_wasm.c -I ${WASM_INCLUDE} 

libudx_wasm.a: udx_wasm.o
	ar cr libudx_wasm.a udx_wasm.o

libudx_wasm.so: udx_wasm.o
	gcc -shared -o libudx_wasm.so udx_wasm.o

ull_runner.o: ull_runner.c udx_wasm.h
	gcc -g -c ull_runner.c -I $(WASM_INCLUDE)

ull_runner: ull_runner.o libudx_wasm.so
	gcc -g ull_runner.o -L. -ludx_wasm $(WASM_LIBS)  -o ull_runner

run_ull_runner: ull_runner fib.c.wasm fib.rs.wasm 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.c.wasm fib 3 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.rs.wasm fib 3 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.c.wasm fib 50
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.rs.wasm fib 50
	@echo Binet formula gives 12586269025
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.c.wasm fib 75
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./ull_runner fib.rs.wasm fib 75
	@echo Binet formula "(approximate)" gives 2111485077978055

timing_test.o: timing_test.c udx_wasm.h
	gcc -g -c timing_test.c -I $(WASM_INCLUDE)

timing_test: timing_test.o libudx_wasm.so
	gcc -g timing_test.o -L. -ludx_wasm $(WASM_LIBS)  -o timing_test

run_timing_test: timing_test fib.c.wasm fib.rs.wasm 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.c.wasm fib 3 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.rs.wasm fib 3 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.c.wasm fib 50 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.rs.wasm fib 50 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.c.wasm fib 75 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.rs.wasm fib 75 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.c.wasm fib 4998 1000000
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./timing_test fib.rs.wasm fib 4998 1000000

abstract_runner.o: abstract_runner.c udx_wasm.h
	gcc -g -c abstract_runner.c -I $(WASM_INCLUDE)

abstract_runner: abstract_runner.o libudx_wasm.so
	gcc -g abstract_runner.o -L. -ludx_wasm $(WASM_LIBS)  -o abstract_runner

run_abstract_runner: abstract_runner sum.c.wasm sum.rs.wasm 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./abstract_runner sum.c.wasm
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./abstract_runner sum.rs.wasm

comparison.o: comparison.cpp udx_wasm.h
	g++ -g -c comparison.cpp -I $(WASM_INCLUDE)

comparison: comparison.o udx_wasm.o libudx_wasm.so
	g++ -g comparison.o udx_wasm.o ${WASM_LIBS} -o comparison

run_comparison: comparison sum.c.wasm sum.rs.wasm 
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./comparison

profile_comparison:
	gcc $(CFLAGS) -c -pg -fpic -Werror udx_wasm.c -I ${WASM_INCLUDE} 
	g++ -g -pg comparison.cpp udx_wasm.o ${WASM_LIBS} -o comparison_pg
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.:$(WASM_LIBDIR) ./comparison_pg
	gprof comparison_pg gmon.out > comparison.profile
