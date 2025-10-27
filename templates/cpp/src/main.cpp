#include <fmt/core.h>
#include <spdlog/spdlog.h>
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    // Initialize logger
    spdlog::set_level(spdlog::level::info);
    spdlog::info("Starting application");

    // Example using fmt for formatting
    std::string name = "C++ Developer";
    fmt::print("Hello, {}!\n", name);
    fmt::print("Welcome to the C++ project template.\n\n");

    // Process command line arguments
    if (argc > 1) {
        fmt::print("Command line arguments:\n");
        for (int i = 1; i < argc; ++i) {
            fmt::print("  [{}]: {}\n", i, argv[i]);
        }
    } else {
        fmt::print("No command line arguments provided.\n");
    }

    // Log completion
    spdlog::info("Application completed successfully");

    return 0;
}
