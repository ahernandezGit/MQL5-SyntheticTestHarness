//+------------------------------------------------------------------+
//|                                          IMarketEnvironment.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_IMARKET_ENVIRONMENT_MQH
#define SYNTHETIC_TEST_HARNESS_IMARKET_ENVIRONMENT_MQH

//+------------------------------------------------------------------+
//| IMarketEnvironment: outbound port abstracting the MT5 terminal.   |
//|                                                                   |
//| Domain logic (Expert Advisors) programs against this interface,   |
//| never against native global functions like SymbolInfoDouble(),    |
//| TimeCurrent(), or OrderSend(). This is the core of the            |
//| Dependency Injection strategy.                                    |
//|                                                                   |
//| Concrete implementations:                                         |
//|   - CSyntheticEngine   (test: reads from injected ticks)          |
//|   - CLiveEnvironment   (prod: delegates to native MT5 API)        |
//|                                                                   |
//| ADR-001: OrderSend() uses the native MqlTradeRequest and          |
//| MqlTradeResult structures so test and production code share the   |
//| exact same call pattern. No signature mismatch between adapters.  |
//+------------------------------------------------------------------+
interface IMarketEnvironment
  {
   //--- Price queries
   double            GetBid(void);
   double            GetAsk(void);
   double            GetSpread(void);

   //--- Time abstraction
   datetime          GetTimeCurrent(void);

   //--- Order execution: mirrors the native OrderSend() contract.
   //--- Returns true on success (result.retcode == TRADE_RETCODE_DONE).
   //--- Returns false on failure (result.retcode contains the server error).
   bool              OrderSend(MqlTradeRequest &request,
                               MqlTradeResult  &result);

   //--- DOM (Depth of Market) abstraction: mirrors native MarketBookGet().
   //--- Returns true on success and populates the book array with DOM entries.
   bool              MarketBookGet(const string symbol,
                                   MqlBookInfo &book[]);
  };


//+------------------------------------------------------------------+
#endif
