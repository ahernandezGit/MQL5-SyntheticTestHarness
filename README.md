# MQL5 Synthetic Test Harness

A lightweight, deterministic synthetic testing and mocking engine for MetaTrader 5 (MQL5) using Dependency Injection (DI), Mocking, and Event-Driven Architecture.

> **Part 1 of the Institutional Architecture for MQL5 Series.**

---

> [!NOTE]
> **Version & Branch Notice:**
> - **Tag `v1.0.0-article` / Branch `article-version`**: Contains the exact code and state published in the original MQL5 community article. Use this release/tag if you are following the article step-by-step.
> - **`main`**: The active development branch containing the latest updates, ongoing enhancements, bug fixes, and architectural improvements beyond the published article.

---

## Overview

Backtesting and live forward-testing alone cannot reliably test edge cases such as spread spikes, latency bursts, order rejections, and broker disconnections under controlled conditions.

**MQL5-SyntheticTestHarness** introduces software engineering best practices to MQL5:
- **Dependency Injection (DI)**: Decouples trading logic from the native terminal runtime.
- **Mock Environment**: Deterministic tick generation and controllable market state injection.
- **On-Chart Telemetry**: Real-time HUD and visualizer powered by `CCanvas` for test progress, metrics, and assertion verdicts.
- **Fail-Fast & Zero Cost**: Run comprehensive unit and scenario tests inside MetaTrader 5 in milliseconds.

---

## Architecture & Components

```
MQL5/
├── Include/
│   └── SyntheticTestHarness/
│       ├── IMarketEnvironment.mqh   # Market data & terminal state abstraction interface
│       ├── ITickProvider.mqh        # Interface for streaming and replaying ticks
│       ├── CLiveEnvironment.mqh     # Production implementation wrapping native MQL5 calls
│       ├── CSyntheticEngine.mqh     # Dual-mode synthetic mock (tick simulation + behavior injection)
│       ├── BehaviorDelegates.mqh    # Function pointer delegates for dynamic behavior injection
│       ├── BehaviorLibrary.mqh      # Pre-built chaos engineering behaviors (requotes, disconnects)
│       ├── CArrayProvider.mqh       # In-memory tick provider for deterministic test vectors
│       ├── MockTick.mqh             # Synthetic tick builder & data structures
│       ├── CCanvasVisualizer.mqh    # On-chart HUD / graphical assertion dashboard
│       ├── CAssert.mqh              # Centralized, reusable assertion framework & test reporter
│       └── ErrorCodes.mqh           # Harness-specific status and error definitions
└── Scripts/
    └── SyntheticTestHarness/
        ├── TestSpreadSpike.mq5      # Executable scenario demonstrating spread spike tests
        └── TestBehaviorInjection.mq5 # TDD runner demonstrating behavior injection and hot-swapping
```

---

## Installation & Setup

### Option 1: Automatic Setup via Symlinks (Recommended)

We provide a PowerShell script to symlink this repository directly into your MetaTrader 5 Data Folder. Changes in this repository will instantly reflect in MetaEditor/MT5 without manual copying.

1. Open PowerShell (run as Administrator if Windows Developer Mode is disabled).
2. Execute:
   ```powershell
   .\Install-Symlinks.ps1 -Mt5DataFolder "C:\Users\<User>\AppData\Roaming\MetaQuotes\Terminal\<INSTANCE_ID>"
   ```
   *(Find your path in MT5 via **File -> Open Data Folder**)*.

### Option 2: Manual Copy

Copy the `MQL5/` directory directly into your MetaTrader 5 Data Folder:
- `MQL5/Include/SyntheticTestHarness/` &rarr; `<DataFolder>/MQL5/Include/SyntheticTestHarness/`
- `MQL5/Scripts/SyntheticTestHarness/` &rarr; `<DataFolder>/MQL5/Scripts/SyntheticTestHarness/`

---

## Running the Tests

1. Open **MetaEditor** (`F4` in MT5).
2. In the Navigator, browse to `Scripts/SyntheticTestHarness/` and open either:
   - `TestSpreadSpike.mq5` (Deterministic tick replay test suite)
   - `TestBehaviorInjection.mq5` (Dynamic behavior injection and Chaos Engineering test suite)
3. Press **Compile** (`F7`).
4. In **MetaTrader 5**, drag the compiled script onto any active chart.
5. Observe the test assertions, retcodes, and summary dashboard.

---

## Changelog (Since Article Publication)

All notable changes and enhancements introduced after the baseline publication (`article-version`) will be documented here.

### [Unreleased]

#### Added
- **Reusable Assertion Framework (`CAssert.mqh`)**: Centralized self-validating assertions (`AssertTrue`, `AssertFalse`, `AssertEqual`, `AssertIntEqual`, `AssertUintEqual`, etc.) and automated test suite reporting (`CAssert::Summary`).
- **Behavior Injection (`BehaviorDelegates.mqh`)**: Typedef function pointer delegates enabling dynamic, runtime behavior mocking without mock frameworks.
- **Chaos Behavior Library (`BehaviorLibrary.mqh`)**: Stateful and fault-injection mock implementations including `Behavior_RequoteTwice` and `Behavior_FatalDisconnect`.
- **TDD Behavior Test Suite (`TestBehaviorInjection.mq5`)**: Test runner validating AAA pattern, stateful retries, hot-swapping, and behavior resetting.
- **DOM Abstraction**: Added `MarketBookGet` to `IMarketEnvironment`, `CSyntheticEngine`, and `CLiveEnvironment`.
- **Architecture Record (`ADR-003`)**: Documented the rationale for behavior injection via function pointers in MQL5.

#### Changed
- **Test Scripts**: Refactored `TestSpreadSpike.mq5` and `TestBehaviorInjection.mq5` to eliminate code duplication by adopting `CAssert.mqh`.
- **`IMarketEnvironment`**: Renamed `TryExecuteOrder` to `OrderSend` for 1:1 parity with the native MT5 terminal API.
- **`CSyntheticEngine`**: Upgraded into a dual-mode engine supporting both tick-driven simulation and priority behavior injection.
- **`CLiveEnvironment`**: Explicitly scoped all native MT5 API calls with the global scope resolution operator (`::`).
- **`TestSpreadSpike.mq5`**: Updated invocation call sites to `OrderSend`.

<!--
Format template for future entries:
### [Version / Date]
#### Added
- Feature description
#### Changed
- Modification description
#### Fixed
- Bug fix description
-->

---

## License

This project is open-source under the [MIT License](LICENSE).