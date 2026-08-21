# ADR-003: Behavior Injection via Function Pointers for Dynamic Mocking

## Status: Accepted

## Context

In high-reliability institutional algorithmic trading engines, execution modules must be validated against unexpected terminal and broker behaviors (Chaos Engineering):
- Successive requotes during low liquidity
- Order rejections and price slippages
- Gateway/network disconnects (`TRADE_RETCODE_CONNECTION`)
- Custom Depth of Market (DOM) snapshots

In languages like C++ or C#, mocking frameworks (e.g., GoogleMock, Moq) use dynamic proxies, closures/lambdas, or template metaprogramming to configure mock responses on the fly. 

MQL5 has strict language constraints:
1. No native lambda functions or true closure captures.
2. No reflection or runtime type introspection.
3. No compile-time mock generation libraries.

Previous iterations of the test harness relied solely on static tick arrays (`MockTick.injected_error`), which required constructing rigid multi-tick datasets to test dynamic scenarios like retry loops.

## Decision

Use **C-style function pointers (`typedef`)** to implement **Behavior Injection** directly into `CSyntheticEngine`:

1. Define delegate signatures in `BehaviorDelegates.mqh` mirroring the `IMarketEnvironment` interface methods.
2. Provide setter methods in `CSyntheticEngine` (e.g., `MockOrderSend()`, `MockMarketBookGet()`) to inject delegate function pointers at runtime.
3. Use a **Dual-Mode Priority Resolution**:
   - **Behavior Injection Hook (Highest Priority)**: If a function pointer is non-NULL, execute it immediately.
   - **Tick-Driven Simulation (Fallback)**: If no delegate is assigned, fall back to sequential `MockTick` replay.
   - **Default Safe State**: If no ticks are loaded and no behavior is set, return safe defaults.
4. For stateful behaviors across successive calls (such as counting requote retries), use **local static variables** inside standalone behavior functions (`BehaviorLibrary.mqh`).

## Consequences

### Positive
- **Dynamic Chaos Engineering**: Behaviors can be hot-swapped mid-flight in unit tests without recreating tick arrays or restarting the test environment.
- **Zero Overhead in Production**: `CLiveEnvironment` continues to delegate directly to global MT5 functions via the scope resolution operator (`::`), unaffected by function pointer indirection.
- **Clean Architecture & Decoupling**: Separation of behavior definitions (`BehaviorDelegates.mqh`), behavior implementations (`BehaviorLibrary.mqh`), and the mock engine (`CSyntheticEngine.mqh`).
- **Idiomatic MQL5**: Full compatibility with strict MQL5 compiler without requiring external tooling.

### Negative
- **Manual State Reset**: Stateful behavior functions relying on internal `static` variables require careful sequencing or automatic reset after completion cycles.
- **Function Signature Constraints**: Injected functions must strictly adhere to the `typedef` delegate signature.
