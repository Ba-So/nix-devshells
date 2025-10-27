# C++ Project Template

A modern C++ project template with Nix flakes for reproducible development environments.

## Features

- 🚀 Modern C++20 standard
- 📦 CMake build system with preset configurations
- 🔧 Complete toolchain (GCC/Clang, CMake, Ninja, etc.)
- 🧪 Testing with Catch2
- ⚡ Benchmarking with Google Benchmark
- 📊 Static analysis (clang-tidy, cppcheck, include-what-you-use)
- 🎨 Code formatting (clang-format)
- 🔍 Language server support (clangd)
- 💾 Compilation caching (ccache)
- 🔌 MCP integration for AI-assisted development

## Quick Start

### Prerequisites

- Nix with flakes enabled
- direnv (optional but recommended)

### Setup

1. Enable the development environment:

   ```bash
   direnv allow  # If using direnv
   # OR
   nix develop   # Manual activation
   ```

2. Configure and build:

   ```bash
   # Create build directory and configure
   cmake -B build -G Ninja \
     -DCMAKE_BUILD_TYPE=Debug \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

   # Build the project
   cmake --build build

   # Run the executable
   ./build/MyProject
   ```

## Project Structure

```
.
├── CMakeLists.txt          # Main CMake configuration
├── include/                # Public headers
│   └── example.hpp
├── src/                    # Source files
│   ├── main.cpp
│   └── example.cpp
├── tests/                  # Unit tests
│   └── test_example.cpp
├── benchmarks/            # Performance benchmarks
│   └── bench_example.cpp
├── flake.nix              # Nix flake configuration
└── .pre-commit-config.yaml # Pre-commit hooks
```

## Development Commands

### Building

```bash
# Debug build
cmake -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug

# Release build
cmake -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-release

# Clean rebuild
rm -rf build && cmake -B build -G Ninja && cmake --build build
```

### Testing

```bash
# Run all tests
cd build && ctest --output-on-failure

# Run tests with detailed output
cd build && ctest -V

# Run specific test
cd build && ./tests --reporter compact
```

### Benchmarking

```bash
# Build with Release mode for accurate benchmarks
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Run benchmarks
./build/benchmarks
```

### Code Quality

```bash
# Format code
clang-format -i src/*.cpp include/*.hpp

# Run static analysis
clang-tidy src/*.cpp -- -I include/

# Check with cppcheck
cppcheck --enable=all --suppress=missingIncludeSystem src/ include/

# Analyze includes
include-what-you-use src/main.cpp -I include/
```

### Debugging

```bash
# Build with debug symbols
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Debug with GDB
gdb ./build/MyProject

# Debug with LLDB
lldb ./build/MyProject

# Memory analysis with Valgrind
valgrind --leak-check=full ./build/MyProject

# Heap profiling
heaptrack ./build/MyProject
```

## Build Options

### CMake Options

- `CMAKE_BUILD_TYPE`: Debug, Release, RelWithDebInfo, MinSizeRel
- `CMAKE_CXX_COMPILER`: Specify compiler (gcc, clang)
- `CMAKE_EXPORT_COMPILE_COMMANDS`: Generate compile_commands.json for IDEs

### Sanitizers (Debug builds only)

```bash
# Address Sanitizer
cmake -B build -DENABLE_ASAN=ON

# Undefined Behavior Sanitizer
cmake -B build -DENABLE_UBSAN=ON

# Thread Sanitizer
cmake -B build -DENABLE_TSAN=ON
```

## Performance Optimization

### Compiler Optimizations

The template includes several optimization options:

```bash
# Use fast linker (mold)
cmake -B build -DCMAKE_CXX_FLAGS="-fuse-ld=mold"

# Enable Link Time Optimization
cmake -B build -DCMAKE_CXX_FLAGS="-flto"

# Profile-guided optimization (PGO)
# Step 1: Generate profile
cmake -B build -DCMAKE_CXX_FLAGS="-fprofile-generate"
cmake --build build
./build/MyProject  # Run typical workload

# Step 2: Use profile
cmake -B build -DCMAKE_CXX_FLAGS="-fprofile-use"
cmake --build build
```

### Build Caching

ccache is automatically enabled in the development environment:

```bash
# View cache statistics
ccache -s

# Clear cache
ccache -C
```

## IDE Integration

### VS Code

The project generates `compile_commands.json` for clangd:

1. Install the clangd extension
2. Build the project once to generate compile_commands.json
3. clangd will automatically use it for code intelligence

### CLion

1. Open the project folder
2. CLion will automatically detect CMakeLists.txt
3. Configure the CMake profile as needed

## Pre-commit Hooks

Install pre-commit hooks:

```bash
pre-commit install
```

The hooks will automatically:

- Format code with clang-format
- Run clang-tidy for static analysis
- Check with cppcheck
- Format CMake files
- Run tests before push

## MCP Integration

This template includes MCP (Model Context Protocol) servers for AI-assisted development:

- **Shrimp**: Task management and planning
- **Serena**: Code intelligence and navigation
- **Codanna**: Semantic code search

These are automatically available when using Claude Code or other MCP-compatible tools.

## Troubleshooting

### Common Issues

1. **CMake can't find packages**: Ensure you're in the Nix development shell
2. **Linker errors**: Check that all dependencies are linked in CMakeLists.txt
3. **Slow compilation**: Enable ccache and use Ninja instead of Make
4. **clangd not working**: Ensure compile_commands.json exists in the build directory

## License

This is a template - add your own license for your project.

## Contributing

This is a template repository. Fork it and make it your own!
