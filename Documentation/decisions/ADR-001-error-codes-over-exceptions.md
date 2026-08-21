# ADR-001: Error Codes Over Exceptions

## Context

Clean Code (Robert C. Martin) mandates: *"Use exceptions, never return codes."* This principle assumes a language with `try`/`catch`/`throw` semantics (Java, C++, Python). MQL5 has **none of these constructs**. The language provides no mechanism to throw, propagate, or catch exceptions.

The native MQL5 API itself is built entirely on error codes:
- `OrderSend()` returns `bool` and fills `MqlTradeResult.retcode`
- `GetLastError()` returns the last runtime error code
- Every trade operation follows the pattern: `bool success` + `int error_code`

## Decision

Use the **bool return + output parameter** pattern for all fallible operations in the framework:

```mql5
bool TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result);
```

This mirrors the native `OrderSend()` contract exactly. Additionally:

1. **Named constants** (`SYNTH_ERR_PRICE_OFF`, `SYNTH_ERR_REQUOTE`, etc.) replace raw integer literals to make error-handling paths self-documenting.
2. **A guard function** (`IsExecutionError()`) centralizes the "what counts as failure?" logic, preventing scattered `!= 0` comparisons.

## Consequences

### Positive
- **Zero friction for MQL5 developers**: the pattern matches what they already use daily with `OrderSend()`.
- **Named constants** are grep-searchable and self-documenting, capturing the *spirit* of Clean Code's error handling guidelines.
- **Guard function** prevents the bug class where a developer compares against the wrong integer value.

### Negative
- **Callers must always check the return value**. Unlike exceptions, nothing forces the caller to handle the error. This is mitigated by the test suite (which validates both success and failure paths).

### Risk
- If a future version of MQL5 adds exception support, this pattern should be reevaluated. The interface `IMarketEnvironment` would need a new version.
