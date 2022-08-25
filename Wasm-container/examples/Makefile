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

udx_wasm.o: udx_wasm.c udx_wasm.h
	gcc $(CFLAGS) -c -fpic -Werror udx_wasm.c -I ${WASM_INCLUDE} 

libudx_wasm.a: udx_wasm.o
	ar cr libudx_wasm.a udx_wasm.o

libudx_wasm.so: udx_wasm.o
	gcc -shared -o libudx_wasm.so udx_wasm.o

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