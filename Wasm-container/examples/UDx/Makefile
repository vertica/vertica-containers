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
LIBWASMER=${WASMHOME}/.wasmer/lib/libwasmer.a
SUM_C_WASM="/data/dmankins/WebAssembly/vertica-containers/Wasm-container/examples/UDx/build/sum.c.wasm"
SUM_RS_WASM="/data/dmankins/WebAssembly/vertica-containers/Wasm-container/examples/UDx/build/sum.rs.wasm"

## Set to the location of the SDK installation
SDK_HOME?=/opt/vertica/sdk
SDK_JAR?=/opt/vertica/

CXX=g++
CXXFLAGS:=$(CXXFLAGS) -I .. -I $(SDK_HOME)/include \
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
	cWasmUDxlib rustWasmUDxlib nonWasmUDxlib

all: \
	cWasmUDxlib rustWasmUDxlib nonWasmUDxlib

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

$(BUILD_DIR)/rustWasmUDx.so: \
		$(WASMUDX_O) \
		$(SDK_HOME)/include/Vertica.cpp \
		$(SDK_HOME)/include/BuildInfo.h \
		sum.rs.wasm \
		$(BUILD_DIR)/.exists
	$(CXX) -shared $(CXXFLAGS) -DWASMFILE=\"${SUM_RS_WASM}\" -o $@ $(rustWASMUDX) ${UDX_WASM} \
		$(SDK_HOME)/include/Vertica.cpp \
		-Wl,--whole-archive ${LIBWASMER} -Wl,--no-whole-archive

$(BUILD_DIR)/.exists:
	test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR)/.exists

sum.c.wasm:
	cd ..; $(MAKE) sum.c.wasm
	cp ../sum.c.wasm $(BUILD_DIR)

sum.rs.wasm:
	cd ..; $(MAKE) sum.rs.wasm
	cp ../sum.rs.wasm $(BUILD_DIR)

clean:
	rm -f $(BUILD_DIR)/*.so *~ *.o $(BUILD_DIR)/*.wasm


