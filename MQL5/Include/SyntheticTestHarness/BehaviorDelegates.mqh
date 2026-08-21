//+------------------------------------------------------------------+
//|                                        BehaviorDelegates.mqh      |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_BEHAVIOR_DELEGATES_MQH
#define SYNTHETIC_TEST_HARNESS_BEHAVIOR_DELEGATES_MQH

//+------------------------------------------------------------------+
//| Behavior Injection Delegates (Function Pointers)                 |
//|                                                                  |
//| In institutional algorithmic trading systems, Chaos Engineering  |
//| requires simulating erratic broker behaviors on-the-fly (e.g.,   |
//| requotes, network latency drops, catastrophic disconnects).      |
//|                                                                  |
//| Because MQL5 does not provide native closure/lambda support or   |
//| dynamic mocking frameworks (like GoogleMock), we achieve dynamic |
//| behavior injection via C-style function pointers (`typedef`).    |
//+------------------------------------------------------------------+

//--- Delegate for OrderSend execution behavior
typedef bool (*TOrderSendBehavior)(MqlTradeRequest &request, MqlTradeResult &result);

//--- Delegates for market price and spread queries
typedef double (*TGetBidBehavior)(void);
typedef double (*TGetAskBehavior)(void);
typedef double (*TGetSpreadBehavior)(void);

//--- Delegate for simulated server time
typedef datetime (*TGetTimeCurrentBehavior)(void);

//--- Delegate for Depth of Market (DOM) / Order Book retrieval
typedef bool (*TMarketBookGetBehavior)(const string symbol, MqlBookInfo &book[]);

//--- Delegate for Slippage Prediction / Thermodynamic LOB Energy Model (Part 3 Hook)
typedef double (*TSlippagePredictor)(const string symbol, const double volume, const MqlBookInfo &book[]);

#endif
//+------------------------------------------------------------------+
