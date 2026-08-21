//+------------------------------------------------------------------+
//|                                            CLiveEnvironment.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CLIVE_ENVIRONMENT_MQH
#define SYNTHETIC_TEST_HARNESS_CLIVE_ENVIRONMENT_MQH

#include "IMarketEnvironment.mqh"

//+------------------------------------------------------------------+
//| CLiveEnvironment: Production Adapter for the Live MT5 Terminal.   |
//|                                                                   |
//| Bridges IMarketEnvironment to native MT5 API functions.           |
//| Uses the global scope resolution operator (`::`) to eliminate any |
//| ambiguous calls or recursive collisions with interface methods.   |
//|                                                                   |
//| Dependency Injection:                                             |
//|   - In Tests:      Trading engine receives CSyntheticEngine*      |
//|   - In Production: Trading engine receives CLiveEnvironment*      |
//|   - Business logic remains 100% agnostic to execution context.   |
//+------------------------------------------------------------------+
class CLiveEnvironment : public IMarketEnvironment
  {
private:
   string            m_symbol;

public:
   //+---------------------------------------------------------------+
   //| Constructor: sets the active symbol for price polling.        |
   //+---------------------------------------------------------------+
   CLiveEnvironment(const string symbol)
     {
      m_symbol = symbol;
     }

   //+---------------------------------------------------------------+
   //| Price queries: delegated to native MT5 global functions.      |
   //+---------------------------------------------------------------+
   double GetBid(void)
     {
      return(::SymbolInfoDouble(m_symbol, SYMBOL_BID));
     }

   double GetAsk(void)
     {
      return(::SymbolInfoDouble(m_symbol, SYMBOL_ASK));
     }

   double GetSpread(void)
     {
      return((double)::SymbolInfoInteger(m_symbol, SYMBOL_SPREAD));
     }

   //+---------------------------------------------------------------+
   //| Time abstraction: delegated to native TimeCurrent().          |
   //+---------------------------------------------------------------+
   datetime GetTimeCurrent(void)
     {
      return(::TimeCurrent());
     }

   //+---------------------------------------------------------------+
   //| OrderSend: delegates to native ::OrderSend().                 |
   //| Global scope operator `::` prevents recursion into method.    |
   //+---------------------------------------------------------------+
   bool OrderSend(MqlTradeRequest &request, MqlTradeResult &result)
     {
      return(::OrderSend(request, result));
     }

   //+---------------------------------------------------------------+
   //| MarketBookGet: delegates to native ::MarketBookGet().         |
   //+---------------------------------------------------------------+
   bool MarketBookGet(const string symbol, MqlBookInfo &book[])
     {
      return(::MarketBookGet(symbol, book));
     }
  };

#endif
//+------------------------------------------------------------------+
