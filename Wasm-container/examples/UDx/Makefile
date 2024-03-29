############################
# Vertica Analytic Database
#
# Makefile to build example user defined functions
#
############################

ifeq ($(WASMHOME), undefined)
	$(error "WASMHOME not defined")
endif

UDX_WASM=../udx_wasm.o
PWD := $(shell pwd)
LIBWASMER=${WASMHOME}/.wasmer/lib/libwasmer.a
SUM_C_WASM="${PWD}/build/sum.c.wasm"
SUM_RS_WASM="${PWD}/build/sum.rs.wasm"
FIB_C_WASM="${PWD}/build/fib.c.wasm"
FIB_RS_WASM="${PWD}/build/fib.rs.wasm"

## Set to the location of the SDK installation
SDK_HOME?=/opt/vertica/sdk
SDK_JAR?=/opt/vertica/

CXX=g++
CXXFLAGS:=$(CXXFLAGS) -O3 -I .. -I $(SDK_HOME)/include \
	-I HelperLibraries -g -Wall -Wno-unused-value \
	-shared -fPIC --std=c++11 \
	-D_GLIBCXX_USE_CXX11_ABI=0 

ifdef OPTIMIZE
## UDLs should be compiled with compiler optimizations in release builds
CXXFLAGS:=$(CXXFLAGS) -O3
endif

## Set to the desired destination directory for .so output files
BUILD_DIR?=$(abspath build)

## Set to the path to 
BOOST_INCLUDE ?= /usr/include
CURL_INCLUDE ?= /usr/include
ZLIB_INCLUDE ?= /usr/include
BZIP_INCLUDE ?= /usr/include

ifdef RUN_VALGRIND
VALGRIND=valgrind --leak-check=full
endif

.PHONEY: \
	cWasmUDxlib rustWasmUDxlib nonWasmUDxlib \
	cFibUDxlib rustFibUDxlib nonFibUDxlib

all: \
	cWasmUDxlib rustWasmUDxlib nonWasmUDxlib \
	cFibUDxlib rustFibUDxlib nonFibUDxlib

cWasmUDxlib: $(BUILD_DIR)/cWasmUDx.so

cWASMUDX = cWasmUDx.cpp

cWASMUDX_O = $(subst .cpp,.o,$(cWASMUDX))

$(BUILD_DIR)/cWasmUDx.so: \
		$(WASMUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		sum.c.wasm \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -DWASMFILE=\"${SUM_C_WASM}\" -o $@ ${UDX_WASM} $(cWASMUDX) \
		$(SDK_HOME)/include/Vertica.cpp \
		-Wl,--whole-archive ${LIBWASMER} -Wl,--no-whole-archive

nonWasmUDxlib: $(BUILD_DIR)/nonWasmUDx.so

nonWASMUDX = nonWasmUDx.cpp

nonWASMUDX_O = $(subst .cpp,.o,$(nonWASMUDX))

$(BUILD_DIR)/nonWasmUDx.so: \
		$(nonWASMUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -o $@ $(nonWASMUDX) \
		$(SDK_HOME)/include/Vertica.cpp 

rustWasmUDxlib: $(BUILD_DIR)/rustWasmUDx.so

rustWASMUDX = rustWasmUDx.cpp

rustWASMUDX_O = $(subst .cpp,.o,$(rustWASMUDX))

$(BUILD_DIR)/rustWasmUDx.so: $(WASMUDX_O) $(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h sum.rs.wasm $(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -DWASMFILE=\"${SUM_RS_WASM}\" -o $@ \
		$(rustWASMUDX) ${UDX_WASM} \
		$(SDK_HOME)/include/Vertica.cpp \
		-Wl,--whole-archive ${LIBWASMER} -Wl,--no-whole-archive

cFibUDxlib: $(BUILD_DIR)/cFibUDx.so

cFIBUDX = cFibUDx.cpp

cFIBUDX_O = $(subst .cpp,.o,$(cFIBUDX))

$(BUILD_DIR)/cFibUDx.so: \
		$(WASMUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		fib.c.wasm \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -DWASMFILE=\"${FIB_C_WASM}\" -o $@ ${UDX_WASM} $(cFIBUDX) \
		$(SDK_HOME)/include/Vertica.cpp \
		-Wl,--whole-archive ${LIBWASMER} -Wl,--no-whole-archive


nonFibUDxlib: $(BUILD_DIR)/nonFibUDx.so

nonFIBUDX = nonFibUDx.cpp

nonFIBUDX_O = $(subst .cpp,.o,$(nonFIBUDX))

$(BUILD_DIR)/nonFibUDx.so: \
		$(nonFIBUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -o $@ $(nonFIBUDX) \
		$(SDK_HOME)/include/Vertica.cpp 

rustFibUDxlib: $(BUILD_DIR)/rustFibUDx.so

rustFIBUDX = rustFibUDx.cpp

rustFIBUDX_O = $(subst .cpp,.o,$(rustFIBUDX))

$(BUILD_DIR)/rustFibUDx.so: \
		$(WASMUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		fib.rs.wasm \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -DWASMFILE=\"${FIB_RS_WASM}\" -o $@ $(rustFIBUDX) ${UDX_WASM} \
		$(SDK_HOME)/include/Vertica.cpp \
		-Wl,--whole-archive ${LIBWASMER} -Wl,--no-whole-archive

$(BUILD_DIR)/.exists:
	test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR)/.exists

fib.c.wasm:
	cd ..; $(MAKE) fib.c.wasm
	cp ../fib.c.wasm $(BUILD_DIR)

fib.rs.wasm:
	cd ..; $(MAKE) fib.rs.wasm
	cp ../fib.rs.wasm $(BUILD_DIR)

sum.c.wasm:
	cd ..; $(MAKE) sum.c.wasm
	cp ../sum.c.wasm $(BUILD_DIR)

sum.rs.wasm:
	cd ..; $(MAKE) sum.rs.wasm
	cp ../sum.rs.wasm $(BUILD_DIR)

clean:
	rm -f $(BUILD_DIR)/*.so *~ *.o $(BUILD_DIR)/*.wasm


