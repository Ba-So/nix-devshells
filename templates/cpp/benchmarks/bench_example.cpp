#include <benchmark/benchmark.h>
#include "example.hpp"
#include <string>

static void BM_ProcessData(benchmark::State& state) {
    std::string input = "Hello World! This is a benchmark test.";

    for (auto _ : state) {
        auto result = example::processData(input);
        benchmark::DoNotOptimize(result);
    }
}
BENCHMARK(BM_ProcessData);

static void BM_Calculate(benchmark::State& state) {
    int a = 42;
    int b = 17;

    for (auto _ : state) {
        auto result = example::calculate(a, b);
        benchmark::DoNotOptimize(result);
    }
}
BENCHMARK(BM_Calculate);

static void BM_ExampleAddItem(benchmark::State& state) {
    for (auto _ : state) {
        state.PauseTiming();
        example::Example ex;
        state.ResumeTiming();

        for (int i = 0; i < state.range(0); ++i) {
            ex.addItem("item" + std::to_string(i));
        }
    }
}
BENCHMARK(BM_ExampleAddItem)->Range(8, 8<<10);

BENCHMARK_MAIN();
