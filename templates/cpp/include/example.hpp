#pragma once

#include <string>
#include <vector>

namespace example {

class Example {
public:
    Example() = default;
    ~Example() = default;

    // Delete copy operations for demonstration
    Example(const Example&) = delete;
    Example& operator=(const Example&) = delete;

    // Allow move operations
    Example(Example&&) = default;
    Example& operator=(Example&&) = default;

    // Sample methods
    void addItem(const std::string& item);
    void clearItems();
    [[nodiscard]] std::vector<std::string> getItems() const;
    [[nodiscard]] std::size_t itemCount() const noexcept;

private:
    std::vector<std::string> items_;
};

// Free functions
[[nodiscard]] std::string processData(const std::string& input);
[[nodiscard]] int calculate(int a, int b) noexcept;

} // namespace example
