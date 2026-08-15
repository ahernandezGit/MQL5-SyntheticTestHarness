//+------------------------------------------------------------------+
//|                                            CLiveEnvironment.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CLIVE_ENVIRONMENT_MQH
#define SYNTHETIC_TEST_HARNESS_CLIVE_ENVIRONMENT_MQH

#include "IMarketEnvironment.mqh"

//+------------------------------------------------------------------+
//| CLiveEnvironment: production adapter for the real MT5 terminal.   |
//|                                                                   |
//| Every method delegates directly to native MT5 global functions.   |
//| This is the "other side" of the Dependency Injection coin:        |
//|   - In tests:  your EA receives a CSyntheticEngine*               |
//|   - In prod:   your EA receives a CLiveEnvironment*               |
//|   - Your EA code stays the same in both cases.                    |
//|                                                                   |
//| Usage:                                                            |
//|   CLiveEnvironment *env = new CLiveEnvironment("EURUSD");         |
//|   my_ea.Initialize(env);                                          |
//+------------------------------------------------------------------+
class CLiveEnvironment : public IMarketEnvironment
  {
private:
   string            m_symbol;

public:
   //+---------------------------------------------------------------+
   //| Constructor: receives the symbol to query from the terminal.   |
   //+---------------------------------------------------------------+
    CLiveEnvironment(const string symbol)
     {
      m_symbol = symbol;
     }

   //+---------------------------------------------------------------+
   //| GetBid: delegates to SymbolInfoDouble(SYMBOL_BID).            |
   //+---------------------------------------------------------------+
   double GetBid(void)
     {
      return(SymbolInfoDouble(m_symbol, SYMBOL_BID));
     }

   //+---------------------------------------------------------------+
   //| GetAsk: delegates to SymbolInfoDouble(SYMBOL_ASK).            |
   //+---------------------------------------------------------------+
   double GetAsk(void)
     {
      return(SymbolInfoDouble(m_symbol, SYMBOL_ASK));
     }

   //+---------------------------------------------------------------+
   //| GetSpread: delegates to SymbolInfoInteger(SYMBOL_SPREAD).     |
   //| Returns spread in points as a double for interface compat.    |
   //+---------------------------------------------------------------+
   double GetSpread(void)
     {
      return((double)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD));
     }

   //+---------------------------------------------------------------+
   //| GetTimeCurrent: delegates to the native TimeCurrent().        |
   //+---------------------------------------------------------------+
   datetime GetTimeCurrent(void)
     {
      return(TimeCurrent());
     }

   //+---------------------------------------------------------------+
   //| TryExecuteOrder: delegates directly to the native OrderSend().|
   //| The request and result structures are passed through unchanged |
   //| — this adapter adds zero logic, just bridges the interface     |
   //| to the real terminal.                                          |
   //+---------------------------------------------------------------+
   bool TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result)
     {
      return(OrderSend(request, result));
     }
  };

//+------------------------------------------------------------------+
#endif
