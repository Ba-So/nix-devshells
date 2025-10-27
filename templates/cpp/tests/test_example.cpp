#include <catch2/catch_test_macros.hpp>
#include "example.hpp"

using namespace example;

TEST_CASE("Example class operations", "[example]") {
    Example ex;

    SECTION("Initial state") {
        REQUIRE(ex.itemCount() == 0);
        REQUIRE(ex.getItems().empty());
    }

    SECTION("Adding items") {
        ex.addItem("first");
        ex.addItem("second");

        REQUIRE(ex.itemCount() == 2);

        auto items = ex.getItems();
        REQUIRE(items.size() == 2);
        REQUIRE(items[0] == "first");
        REQUIRE(items[1] == "second");
    }

    SECTION("Clearing items") {
        ex.addItem("test");
        ex.clearItems();

        REQUIRE(ex.itemCount() == 0);
        REQUIRE(ex.getItems().empty());
    }
}

TEST_CASE("Free functions", "[example]") {
    SECTION("processData converts to uppercase") {
        REQUIRE(processData("hello") == "HELLO");
        REQUIRE(processData("Test123") == "TEST123");
        REQUIRE(processData("") == "");
    }

    SECTION("calculate adds two numbers") {
        REQUIRE(calculate(2, 3) == 5);
        REQUIRE(calculate(-1, 1) == 0);
        REQUIRE(calculate(0, 0) == 0);
    }
}
