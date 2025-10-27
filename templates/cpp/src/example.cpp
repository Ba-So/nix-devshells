#include "example.hpp"
#include <algorithm>
#include <spdlog/spdlog.h>

namespace example {

void Example::addItem(const std::string& item) {
    items_.push_back(item);
    spdlog::debug("Added item: {}", item);
}

void Example::clearItems() {
    items_.clear();
    spdlog::debug("Cleared all items");
}

std::vector<std::string> Example::getItems() const {
    return items_;
}

std::size_t Example::itemCount() const noexcept {
    return items_.size();
}

std::string processData(const std::string& input) {
    std::string result = input;
    std::transform(result.begin(), result.end(), result.begin(), ::toupper);
    return result;
}

int calculate(int a, int b) noexcept {
    return a + b;
}

} // namespace example
