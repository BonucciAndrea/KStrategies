# K-Alpha-Engine: Vectorized High-Frequency Backtester

This repository contains a suite of systematic trading strategies and a grid-search execution engine built entirely in **Kona (K3/APL dialect)** as well as **ngn/k (K6/APL dialect)**. 

The architecture is designed to bypass the I/O and loop-based bottlenecks of standard Python/pandas stacks. By utilizing pure array-oriented programming, prefix-sums, and zero-reallocation memory management, this engine evaluates tens of millions of discrete matrix operations in ~3.5 seconds locally, and is structurally designed to achieve sub-20ms execution times when deployed to an enterprise kdb+ distributed compute grid.

## Core Architectural Principles

1. **$O(N)$ Time Complexity:** All rolling calculations (averages, variances) utilize prefix-sums (scan operators) to achieve constant-time window evaluation. The engine never recalculates overlapping data.
2. **Zero-Loop Execution:** Total reliance on K-idiomatic vectorization. `while` and `for` loops are strictly avoided in favor of sliding array logic.
3. **Pre-computation (Memoization):** Grid-search sweeps pull from pre-calculated mathematical matrices in RAM rather than calculating indicators on-the-fly.
4. **Cache Preservation:** Array shifting (to prevent look-ahead bias) is handled via negative drops (`-1_`) rather than memory-heavy array reversals, protecting the CPU cache from reallocation thrashing.
5. **Separation of Concerns:** Disk I/O (CSV parsing) is strictly isolated from the mathematical execution engine.

---

## The Strategy Ensemble

The repository is divided into uncorrelated quantitative strategies, demonstrating proficiency in Trend Following, Statistical Arbitrage, and Momentum Oscillation.

### Strategy 1: Moving Average Crossover (Trend Following)
A foundational momentum strategy optimized for ultra-low latency execution. It evaluates a fast moving average against a slow moving average to detect trend emergence, factoring in basis-point transaction costs on signal flips.
* **Mathematical Highlight:** Reduces the standard $O(N \times W)$ moving average calculation to strict $O(N)$ time. By calculating the running sum of the entire price array first, the engine isolates the exact sum of any window $W$ by subtracting the trailing sum from the leading sum.

### Strategy 2: Z-Score Mean Reversion (Statistical Arbitrage)
A mean-reversion engine that assumes price elasticity. It generates signals based on standard deviation extremes (Z-Scores).
* **Mathematical Highlight:** Computes rolling variance without loops. It leverages the mathematical identity $Var(X) = E[X^2] - (E[X])^2$, applying the prefix-sum architecture to both the price array and the squared-price array simultaneously. 

### Strategy 3: RSI via Boolean Masking (Momentum Oscillator)
An implementation of the Relative Strength Index to identify overbought and oversold market conditions.
* **Mathematical Highlight:** Bypasses conditional `if/else` statements entirely. It separates positive and negative daily returns by multiplying the returns array against a boolean condition mask, enabling lightning-fast calculation of the Average Gain and Average Loss.

### Strategy 4: Donchian Channel Breakout (Volatility)
A breakout strategy that generates signals when an asset surpasses its $N$-day highest high or lowest low.
* **Mathematical Highlight:** Demonstrates advanced K-language reduction operators to maintain a sliding-window maximum without iteration.

---

## The Grid-Search Execution Engine

To find optimal parameter pairs, the repository utilizes a custom grid-search engine. Instead of passing parameters into a strategy function and calculating math dynamically, the engine executes a three-layer pipeline:

1. **Ingestion Layer:** Loads and parses the data into a pure float array exactly once.
2. **The Matrix (Memoization):** Pre-calculates every possible indicator array (e.g., all moving averages from window size 1 to 200) into RAM.
3. **The Sweep:** Maps combinations across the execution function. The function simply compares two pre-existing arrays from memory, applies transaction costs via boolean flip detection, and outputs the final exponentiated PnL. 

## Usage
To run the simulations, ensure you have the Kona and ngn/k interpreters installed and configured.
Execute the respective strategy files via the command line, passing in your target high-frequency CSV dataset.

## Performance & Execution Benchmarks

The K-ALPHA-ENGINE was stress-tested using a single-threaded CPU environment against a 1,249-day historical dataset (Apple Inc.). The grid searches evaluated multi-dimensional parameter surfaces without utilizing conditional `for` loops or pipeline-stalling memory reallocations. 

## 📊 Performance Benchmarks: ngn/k vs. Kona
The following benchmarks evaluate the performance of identical vectorized logic across 1,249 historical price points (`HistDataAPPLE2.csv`). These metrics illustrate the raw computational velocity of the K-family and the extreme efficiency of the **ngn/k** engine.

| Strategy Section | Total Operations | ngn/k Time (ms) | Kona Time (ms) | **ngn/k Ops/Sec** | **Kona Ops/Sec** | Delta |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MA Crossover** | ~2,135,790 | 317 | 967 | **6,737,507** | 2,208,676 | 3.05x |
| **Z-Score (1D)** | ~2,473,020 | 292 | 881 | **8,469,246** | 2,807,060 | 3.02x |
| **Z-Score (2D)** | ~19,784,160 | 2,371 | 7,580 | **8,344,226** | 2,610,047 | 3.20x |
| **RSI (1D)** | ~1,712,370 | 114 | 437 | **15,020,789** | 3,918,466 | 3.83x |
| **RSI (2D)** | **61,700,000** | 4,049 | 26,772 | **15,238,330** | 2,304,646 | **6.61x** |
*Note: Total matrix operations are approximations based on the mathematical footprint of the $O(N)$ prefix-sum and boolean masking pathways multiplied by the grid combinations and dataset length.*
