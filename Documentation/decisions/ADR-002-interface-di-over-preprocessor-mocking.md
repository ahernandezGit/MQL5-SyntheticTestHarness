# ADR-002: Interface-Based Dependency Injection Over Preprocessor Mocking

## Status: Accepted

## Context

In C++ ecosystems, mocking frameworks like Google Mock (gmock) use template metaprogramming, macros, and preprocessor directives to generate mock classes at compile time. This approach is unavailable in MQL5 because:

1. MQL5 has no template metaprogramming. While the language supports basic template<typename T> syntax for generic functions and classes, it lacks template specialization, SFINAE (Substitution Failure Is Not An Error), variadic templates, constexpr evaluation, and type traits — all essential for compile-time mock generation.

2. MQL5 has no reflection or runtime type introspection. There is no typeid, no RTTI, and no way to enumerate or inspect the methods of a class at runtime, making automatic mock class generation impossible.

3. MQL5's preprocessor is too limited for mock generation. Although it supports #define (including function-like macros with arguments), #if, #else, #elif, #ifdef, #ifndef, #undef, #include, and #pragma, it lacks token pasting (##), stringification (#), and variadic macros (__VA_ARGS__) — all of which are required to programmatically generate mock class definitions and method stubs.

We need a mechanism to test Expert Advisor logic **without a live MetaTrader 5 terminal**, meaning all dependencies on native global functions (`SymbolInfoDouble()`, `TimeCurrent()`, `OrderSend()`) must be replaceable.

## Decision

Use **pure virtual interfaces** (MQL5 `interface` keyword) with **constructor injection**:

```mql5
interface IMarketEnvironment
{
   double   GetBid(void);
   double   GetAsk(void);
   bool     TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result);
};

// Test implementation
class CSyntheticEngine : public IMarketEnvironment { ... };

// Future production implementation
class CLiveEnvironment : public IMarketEnvironment { ... };
```

The Expert Advisor receives an `IMarketEnvironment*` in its constructor (or initialization method), never calling native functions directly. Swapping between test and production is a single line change at the composition root.

## Consequences

### Positive
- **Complete isolation**: EA logic can be tested with zero terminal dependencies.
- **Open/Closed Principle**: new tick sources (`CFileProvider`, `CRandomProvider`) extend `ITickProvider` without modifying the engine.
- **Explicit dependencies**: every dependency is visible in the constructor signature — no hidden globals.
- **Familiar pattern**: developers who know Strategy Pattern, Ports & Adapters, or Hexagonal Architecture will recognize this immediately.

### Negative
- **Vtable overhead**: virtual method dispatch adds ~2-5 nanoseconds per call compared to direct function calls. For test scenarios (microsecond-scale), this is negligible. For high-frequency live trading, profiling is recommended.
- **Boilerplate**: each native function abstracted requires a method on the interface + implementations in both test and live adapters. This is the "tax" of testability.
- **Single inheritance limitation**: MQL5 allows single class inheritance + multiple interface implementation. Complex hierarchies may hit this wall, but the current design stays flat.
