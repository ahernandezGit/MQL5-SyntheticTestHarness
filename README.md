# MQL5-SyntheticTestHarness

A lightweight synthetic testing engine for MQL5 using dependency injection, mocking, and event-driven architecture. Proof of concept. Part 1 of the Institutional Architecture series.

## Installation

We provide a PowerShell script to easily link this project to your MetaTrader 5 Data Folder so you can edit files here and have them instantly reflected in MT5.

Open PowerShell (as Administrator if Developer Mode is not enabled) and run:

```powershell
.\Install-Symlinks.ps1 -Mt5DataFolder "C:\Path\To\Your\MT5\Data\Folder"
```
*(You can find your Data Folder by opening MT5 and clicking `File -> Open Data Folder`)*

## Running the Tests (Example script)

After linking, open **MetaEditor**, navigate to `Scripts -> SyntheticTestHarness` and compile `TestSpreadSpike.mq5`.

Then, in **MetaTrader 5**, drag the `TestSpreadSpike` script onto any chart to see the test runner execute the synthetic scenarios in real-time.