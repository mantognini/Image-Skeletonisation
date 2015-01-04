CXX                 = clang++-3.5
CXXCFLAGS           = -std=c++11 -stdlib=libc++ -Wall -Ofast \
                      -nostdinc++ -I/usr/local/lib/llvm-3.5/include/c++/v1
CXXLDFLAGS          = -L lib/libc++/ -stdlib=libc++ \
                      -lsfml-system-s -lsfml-graphics-s -lboost_program_options-s -ljpeg-s \
                      -L/usr/local/lib/llvm-3.5/usr/lib

GXX                 = g++-4.9
GXXCFLAGS           = -std=c++11 -Wall -Ofast
GXXLDFLAGS          = -L lib/stdlibc++/ \
                      -lsfml-system-s -lsfml-graphics-s -lboost_program_options-s -ljpeg-s

NVCC                = nvcc
NVCCCFLAGS          = -Xcompiler -stdlib=libstdc++ -O3
NVCCLDFLAGS         = -L lib/stdlibc++/ -Xcompiler -stdlib=libstdc++ \
                      -lsfml-system-s -lsfml-graphics-s -lboost_program_options-s -ljpeg-s

SERIALCFLAGS        =
SERIALLDFLAGS       =

CUDACFLAGS          = -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CUDA
CUDALDFLAGS         =

TBBCFLAGS           = -x c++ -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB \
                      -I /Developer/NVIDIA/CUDA-6.5/include
TBBLDFLAGS          = -ltbb

OMPCFLAGS           = -x c++ -fopenmp -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP \
                      -I /Developer/NVIDIA/CUDA-6.5/include
OMPLDFLAGS          = -lgomp

BUILD_DIR           = build/
BIN_DIR             = bin/

COMMON_DIR          = src/common/
SERIAL_DIR          = src/serial/
PAR_DIR             = src/parallel/

SOURCES_COMMON      = main.cpp
SOURCES_SERIAL      = Image.cpp Skeleton.cpp
SOURCES_PAR         = Image.cu Skeleton.cu
EXECUTABLE_SERIAL   = skeleton_serial
EXECUTABLE_CUDA     = skeleton_cuda
EXECUTABLE_TBB      = skeleton_tbb
EXECUTABLE_OMP      = skeleton_omp

SOURCES_COMMON     := $(addprefix $(COMMON_DIR)/, $(SOURCES_COMMON))
SOURCES_SERIAL     := $(addprefix $(SERIAL_DIR)/, $(SOURCES_SERIAL)) $(SOURCES_COMMON)
SOURCES_PAR        := $(addprefix $(PAR_DIR)/, $(SOURCES_PAR)) $(SOURCES_COMMON)
OBJECTS_SERIAL     := $(addsuffix .serial.o, $(notdir $(SOURCES_SERIAL)))
OBJECTS_PAR        := $(addsuffix .cuda.o, $(notdir $(SOURCES_PAR)))
OBJECTS_TBB        := $(addsuffix .tbb.o, $(notdir $(SOURCES_PAR)))
OBJECTS_OMP        := $(addsuffix .omp.o, $(notdir $(SOURCES_PAR)))
OBJECTS_SERIAL     := $(addprefix $(BUILD_DIR)/, $(OBJECTS_SERIAL))
OBJECTS_PAR        := $(addprefix $(BUILD_DIR)/, $(OBJECTS_PAR))
OBJECTS_TBB        := $(addprefix $(BUILD_DIR)/, $(OBJECTS_TBB))
OBJECTS_OMP        := $(addprefix $(BUILD_DIR)/, $(OBJECTS_OMP))

EXECUTABLES         = $(EXECUTABLE_SERIAL) $(EXECUTABLE_CUDA) $(EXECUTABLE_TBB) $(EXECUTABLE_OMP)


## This hack fixes foreach commands below
define \n


endef

all: $(EXECUTABLES)

serial: $(EXECUTABLE_SERIAL)

cuda: $(EXECUTABLE_CUDA)

tbb: $(EXECUTABLE_TBB)

omp: $(EXECUTABLE_OMP)

$(EXECUTABLE_SERIAL): $(OBJECTS_SERIAL)
	$(CXX) $(CXXLDFLAGS) $(SERIALLDFLAGS) $(OBJECTS_SERIAL) -o $(BIN_DIR)/$@

$(EXECUTABLE_CUDA): $(OBJECTS_PAR)
	$(NVCC) $(NVCCLDFLAGS) $(CUDALDFLAGS) $(OBJECTS_PAR) -o $(BIN_DIR)/$@

$(EXECUTABLE_TBB): $(OBJECTS_TBB)
	$(CXX) $(CXXLDFLAGS) $(TBBLDFLAGS) $(OBJECTS_TBB) -o $(BIN_DIR)/$@

$(EXECUTABLE_OMP): $(OBJECTS_OMP)
	$(GXX) $(GXXLDFLAGS) $(OMPLDFLAGS) $(OBJECTS_OMP) -o $(BIN_DIR)/$@

$(OBJECTS_SERIAL): $(SOURCES_SERIAL) | dirs
	$(foreach file, $?, \
		$(CXX) $(CXXCFLAGS) $(SERIALCFLAGS) -I $(COMMON_DIR) -I $(SERIAL_DIR) \
		-c $(file) \
		-o $(BUILD_DIR)/$(notdir $(addsuffix .serial.o, $(file))) \
		${\n} \
	)

$(OBJECTS_PAR): $(SOURCES_PAR) | dirs
	$(foreach file, $?, \
		$(NVCC) $(NVCCCFLAGS) $(CUDACFLAGS) -I $(COMMON_DIR) -I $(PAR_DIR) \
		-c $(file) \
		-o $(BUILD_DIR)/$(notdir $(addsuffix .cuda.o, $(file))) \
		${\n} \
	)

$(OBJECTS_TBB): $(SOURCES_PAR) | dirs
	$(foreach file, $?, \
		$(CXX) $(CXXCFLAGS) $(TBBCFLAGS) -I $(COMMON_DIR) -I $(SERIAL_DIR) \
		-c $(file) \
		-o $(BUILD_DIR)/$(notdir $(addsuffix .tbb.o, $(file))) \
		${\n} \
	)

$(OBJECTS_OMP): $(SOURCES_PAR) | dirs
	$(foreach file, $?, \
		$(GXX) $(GXXCFLAGS) $(OMPCFLAGS) -I $(COMMON_DIR) -I $(SERIAL_DIR) \
		-c $(file) \
		-o $(BUILD_DIR)/$(notdir $(addsuffix .omp.o, $(file))) \
		${\n} \
	)

dirs:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)

clean:
	rm -f $(addprefix $(BIN_DIR)/, $(EXECUTABLES)) $(BUILD_DIR)/*.o

run: $(EXECUTABLES)
	./scripts/run.sh


