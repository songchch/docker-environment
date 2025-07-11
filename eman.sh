#!/bin/bash

EMAN_DIR=$(dirname "$(readlink -f "$0")")

help() {
    cat <<EOF

Usage: ./eman.sh <command>
    ./eman.sh help                         : show this help message
    ./eman.sh check-verilator              : print the version of the first found Verilator
    ./eman.sh verilator-example            : compile and run the Verilator example(s)
    ./eman.sh change-verilator <VERSION>   : change default Verilator to different version. If not installed, install it.

    ./eman.sh c-compiler-version           : print the version of default C compiler and GNU Make
    ./eman.sh c-compiler-example           : compile and run the C/C++ example(s)

EOF
}

c_compiler_version() {
    echo "C compiler version:"
    gcc --version 2>/dev/null || echo "gcc not found"
    echo
    echo "Make version:"
    make --version 2>/dev/null | head -n 1 || echo "make not found"
}

c_compiler_example() {
    echo "=== Building C example ==="
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    cat > main.c <<'EOC'
#include <stdio.h>

int main() {
    int arr[2][3][4] = {
        {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12}
        },
        {
            {13, 14, 15, 16},
            {17, 18, 19, 20},
            {21, 22, 23, 24}
        }
    };

    int *ptr = (int*)arr;

    printf("-----  print out  ----- \n");
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 4; k++) {
                int idx = i*12 + j*4 + k;
                printf("addr: %p , value: %d\n", &arr[idx], *(ptr + idx));
            }
        }
    }
    return 0;
}
EOC

    cat > Makefile <<'EOF'
BIN := main.exe

CC := gcc

CFLAGS := -Wall -Wextra -O2
INCLUDE_DIR := .

SRC := main.c
OBJ := $(SRC:.c=.o)

.PHONY: all run clean

all: $(BIN) run

$(BIN): $(OBJ)
	$(CC) $^ -o $@

%.o: %.c
	$(CC) -c $(CFLAGS) $< -I$(INCLUDE_DIR) -o $@

run: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BIN) $(OBJ)
EOF

    make all
    cd -
    rm -rf "$TMPDIR"
}

check_verilator() {
    if command -v verilator &>/dev/null; then
        verilator --version
    else
        echo "Verilator not found."
    fi
}

verilator_example() {
    if ! command -v verilator &>/dev/null; then
        echo "Verilator not found."
        exit 1
    fi

    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"

    # Verilog source
    cat > Counter.v <<'EOV'
module Counter(
    input clk,
    input rst,
    input [8:0] max,
    output reg [8:0] out
);
    reg [8:0] cnt;

    always @(posedge clk, posedge rst) begin
        if (rst) cnt <= max;
        else if (cnt == 0) cnt <= max;
        else cnt <= cnt - 1;
    end

    always @(*) out = cnt;

endmodule
EOV

    # Testbench
    cat > testbench.cc <<'EOT'
#include <iostream>
#include "VCounter.h"
#include "verilated_vcd_c.h"

int main() {
    Verilated::traceEverOn(true);
    VerilatedVcdC* fp = new VerilatedVcdC();

    auto dut = new VCounter;
    dut->trace(fp, 0);
    fp->open("wave.vcd");

    int clk = 0;
    const int maxclk = 10;

    dut->rst = 1;
    dut->max = 9;
    dut->clk = 1; dut->eval(); fp->dump(clk++);

    dut->rst = 0;
    while (clk < maxclk << 1) {
        // falling edge
        dut->clk = 0; dut->eval(); fp->dump(clk++);

        // rising edge
        dut->clk = 1; dut->eval(); fp->dump(clk++);
        std::cout << "count: " << dut->out << std::endl;
    }

    fp->close();
    dut->final();
    delete dut;
    return 0;
}
EOT

    # Makefile
    cat > Makefile <<'EOF'
TB_SRC = testbench.cc
BIN = obj_dir/VCounter

VFLAGS = -Wall --cc --exe --build --trace
VC = verilator

.PHONY: all clean format run

all: $(BIN)

run: $(BIN)
	./$<

obj_dir/V%: %.v $(TB_SRC)
	$(VC) $(VFLAGS) $^

format:
	clang-format -i tb/*.cpp

clean:
	$(RM) -rv obj_dir *.vcd
EOF

    make all
    make run

    cd -
    rm -rf "$TMPDIR"
}

change_verilator() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: ./eman.sh change-verilator <VERSION>"
        return 1
    fi
    # 假設有多版本管理工具，這裡僅為範例
    if command -v update-alternatives &>/dev/null; then
        sudo update-alternatives --set verilator /usr/bin/verilator-$version
        echo "Switched to verilator version $version"
    else
        echo "切換功能需要多版本管理工具或自行實作"
    fi
}

case "$1" in
    help|-h|--help|"")
        help
        ;;
    c-compiler-version)
        c_compiler_version
        ;;
    c-compiler-example)
        c_compiler_example
        ;;
    check-verilator)
        check_verilator
        ;;
    verilator-example)
        verilator_example
        ;;
    change-verilator)
        change_verilator "$2"
        ;;
    *)
        echo "Unknown command: $1"
        help
        ;;
esac
