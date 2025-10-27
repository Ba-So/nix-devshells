cmake_minimum_required(VERSION 3.20)
project(MyProject
    VERSION 1.0.0
    DESCRIPTION "A C++ project template"
    LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for language servers
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set default build type if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type" FORCE)
endif()

# Compiler warnings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        -Wall
        -Wextra
        -Wpedantic
        -Wshadow
        -Wnon-virtual-dtor
        -Wcast-align
        -Wunused
        -Woverloaded-virtual
        -Wconversion
        -Wsign-conversion
        -Wmisleading-indentation
        -Wduplicated-cond
        -Wduplicated-branches
        -Wlogical-op
        -Wnull-dereference
        -Wuseless-cast
        -Wdouble-promotion
        -Wformat=2
    )
endif()

# Debug/Release specific flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-O0 -g3 -fno-omit-frame-pointer)
    add_compile_definitions(DEBUG)
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O3 -march=native)
    add_compile_definitions(NDEBUG)
endif()

# Sanitizers for debug builds
if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    option(ENABLE_ASAN "Enable Address Sanitizer" OFF)
    option(ENABLE_UBSAN "Enable Undefined Behavior Sanitizer" OFF)
    option(ENABLE_TSAN "Enable Thread Sanitizer" OFF)

    if(ENABLE_ASAN)
        add_compile_options(-fsanitize=address -fno-optimize-sibling-calls)
        add_link_options(-fsanitize=address)
    endif()

    if(ENABLE_UBSAN)
        add_compile_options(-fsanitize=undefined)
        add_link_options(-fsanitize=undefined)
    endif()

    if(ENABLE_TSAN)
        add_compile_options(-fsanitize=thread)
        add_link_options(-fsanitize=thread)
    endif()
endif()

# Find packages
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)
find_package(Catch2 3)
find_package(benchmark)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Source files
file(GLOB_RECURSE SOURCES "src/*.cpp")
file(GLOB_RECURSE HEADERS "include/*.hpp")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Link libraries
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        fmt::fmt
        spdlog::spdlog
)

# Testing
if(Catch2_FOUND)
    enable_testing()

    file(GLOB_RECURSE TEST_SOURCES "tests/*.cpp")
    add_executable(tests ${TEST_SOURCES})
    target_link_libraries(tests
        PRIVATE
            Catch2::Catch2WithMain
            fmt::fmt
            spdlog::spdlog
    )

    include(CTest)
    include(Catch)
    catch_discover_tests(tests)
endif()

# Benchmarks
if(benchmark_FOUND)
    file(GLOB_RECURSE BENCH_SOURCES "benchmarks/*.cpp")
    if(BENCH_SOURCES)
        add_executable(benchmarks ${BENCH_SOURCES})
        target_link_libraries(benchmarks
            PRIVATE
                benchmark::benchmark
                fmt::fmt
                spdlog::spdlog
        )
    endif()
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin)
install(DIRECTORY include/
    DESTINATION include)

# CPack configuration for packaging
set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
