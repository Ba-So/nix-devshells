# C++ Project Template

## Quick Start

```bash
# Activate environment
direnv allow  # or: nix develop

# Configure and build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Run
./build/MyProject

# Test
cd build && ctest --output-on-failure
```

## Included

- Toolchain: GCC, Clang, CMake, Ninja
- Testing: Catch2
- Analysis: clang-tidy, cppcheck, clangd
- Utilities: ccache, gdb, lldb, valgrind

See `CMakeLists.txt` and `flake.nix` for details.
