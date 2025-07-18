#!/bin/bash

EMAN_DIR=$(dirname "$(readlink -f "$0")")

help() {
    cat <<EOF

Usage: ./eman.sh <command>
    ./eman.sh help                         : show this help message
    ./eman.sh check-verilator              : print the version of the first found Verilator
    ./eman.sh verilator-example            : compile and run the Verilator example
    ./eman.sh change-verilator <VERSION>   : change default Verilator to different version. If not installed, install it.

    ./eman.sh c-compiler-version           : print the version of default C compiler and GNU Make
    ./eman.sh c-compiler-example           : compile and run the C example

    ./eman.sh systemc-example              : compile and run the SystemC example
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

    EXAMPLE_DIR="$(dirname "$0")/examples/c"
    cd "$EXAMPLE_DIR"

    make
    make clean
    
    cd -
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
    echo "=== Building Verilator example ==="

    EXAMPLE_DIR="$(dirname "$0")/examples/verilator"
    cd "$EXAMPLE_DIR"

    make clean
    make all

    cd -
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

systemc_example() {
    echo "=== Building SystemC example ==="

    EXAMPLE_DIR="$(dirname "$0")/examples/systemc"
    cd "$EXAMPLE_DIR"

    make clean
    make all
    cd -
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
    systemc-example)
        systemc_example
        ;;
    *)
        echo "Unknown command: $1"
        help
        ;;
esac
