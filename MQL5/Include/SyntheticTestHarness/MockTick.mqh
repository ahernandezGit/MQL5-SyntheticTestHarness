//+------------------------------------------------------------------+
//|                                                     MockTick.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_MOCKTICK_MQH
#define SYNTHETIC_TEST_HARNESS_MOCKTICK_MQH

//+------------------------------------------------------------------+
//| MockTick: the atomic unit of synthetic market data.               |
//|                                                                   |
//| Each field is independently controllable so test scenarios can    |
//| vary one dimension at a time (spread spike, price gap, error      |
//| injection) without coupling to the others.                        |
//|                                                                   |
//| Design note: spread_points is separate from the bid/ask delta     |
//| to allow scenarios where spread is the variable under test,       |
//| independently of the price levels.                                |
//+------------------------------------------------------------------+
struct MockTick
  {
   datetime          time;            // Simulated server timestamp
   double            bid;             // Simulated bid price
   double            ask;             // Simulated ask price
   double            spread_points;   // Spread in points (broker convention)
   int               injected_error;  // MQL5 trade server error code (0 = none)
  };

//+------------------------------------------------------------------+
#endif
