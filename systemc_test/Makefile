# SystemC 2.3.4 安裝目錄
SYSTEMC_DIR = /opt/systemc

# 編譯器設定
BUILDFLAGS  = -g3
CXX         = g++ -std=c++17

# Include 與 Link 路徑
INCFLAGS    = -I. -I${SYSTEMC_DIR}/include -DSC_INCLUDE_FX # 包含 fixed-point
LDFLAGS     = -L${SYSTEMC_DIR}/lib-linux64 -Wl,-rpath,${SYSTEMC_DIR}/lib-linux64 -lsystemc -lm

PROJECT     = out
SRC_CPPHEAD = 
SRC_CPP     =  
HEADERS     = 
MAIN        = helloworld.cpp 
OBJECTS     = $(SRC_CPPHEAD:=.o) $(SRC_CPP:cpp=o)

# 執行時動態庫路徑
export LD_LIBRARY_PATH := $(SYSTEMC_DIR)/lib-linux64:$(LD_LIBRARY_PATH)

EXE = $(PROJECT)

all: $(EXE)

$(EXE): $(MAIN) $(OBJECTS) $(HEADERS)
	@echo "$@ building..."
	$(CXX) $(INCFLAGS) $(MAIN) $(OBJECTS) $(LDFLAGS) -o $@
	@echo ""
	@echo "$@ build done successfully..."
	@echo ""
	./out

%.o:%.cpp %.h
	@echo "Compiling $< ..."
	$(CXX) -c $< $(INCFLAGS)

clean:
	rm -f $(EXE)
	rm -f *.o
    