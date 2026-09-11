//+------------------------------------------------------------------+
//|                                            CLiveEnvironment.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 2 Series   |
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
//+------------------------------------------------------------------+
class CLiveEnvironment : public IMarketEnvironment
  {
private:
   string            m_symbol;

public:
   //+---------------------------------------------------------------+
   //| Constructor & Destructor                                      |
   //+---------------------------------------------------------------+
   CLiveEnvironment(const string symbol = "")
     {
      m_symbol = (symbol == "") ? _Symbol : symbol;
     }

   ~CLiveEnvironment(void)
     {
     }

   //+---------------------------------------------------------------+
   //| Price queries                                                 |
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
   //| Time abstraction                                              |
   //+---------------------------------------------------------------+
   datetime GetTimeCurrent(void)
     {
      return(::TimeCurrent());
     }

   //+---------------------------------------------------------------+
   //| Order execution                                               |
   //+---------------------------------------------------------------+
   bool OrderSend(MqlTradeRequest &request, MqlTradeResult &result)
     {
      return(::OrderSend(request, result));
     }

   //+---------------------------------------------------------------+
   //| Depth of Market (DOM)                                         |
   //+---------------------------------------------------------------+
   bool MarketBookGet(const string symbol, MqlBookInfo &book[])
     {
      return(::MarketBookGet(symbol, book));
     }

   //+---------------------------------------------------------------+
   //| Generic Symbol Info Bridge                                    |
   //+---------------------------------------------------------------+
   double SymbolInfoDouble(const string symbol, const ENUM_SYMBOL_INFO_DOUBLE property)
     {
      return(::SymbolInfoDouble(symbol, property));
     }

   long SymbolInfoInteger(const string symbol, const ENUM_SYMBOL_INFO_INTEGER property)
     {
      return(::SymbolInfoInteger(symbol, property));
     }

   //+---------------------------------------------------------------+
   //| Generic Account Info Bridge                                   |
   //+---------------------------------------------------------------+
   double AccountInfoDouble(const ENUM_ACCOUNT_INFO_DOUBLE property)
     {
      return(::AccountInfoDouble(property));
     }

   long AccountInfoInteger(const ENUM_ACCOUNT_INFO_INTEGER property)
     {
      return(::AccountInfoInteger(property));
     }

   //+---------------------------------------------------------------+
   //| Margin Calculation Bridge                                     |
   //+---------------------------------------------------------------+
   bool OrderCalcMargin(const ENUM_ORDER_TYPE action,
                        const string symbol,
                        const double volume,
                        const double price,
                        double &margin)
     {
      return(::OrderCalcMargin(action, symbol, volume, price, margin));
     }

   //+---------------------------------------------------------------+
   //| Position Tracking Bridge                                      |
   //+---------------------------------------------------------------+
   int PositionsTotal(void)
     {
      return(::PositionsTotal());
     }

   string PositionGetSymbol(const int index)
     {
      return(::PositionGetSymbol(index));
     }

   long PositionGetInteger(const ENUM_POSITION_PROPERTY_INTEGER property)
     {
      return(::PositionGetInteger(property));
     }

   double PositionGetDouble(const ENUM_POSITION_PROPERTY_DOUBLE property)
     {
      return(::PositionGetDouble(property));
     }

   //+---------------------------------------------------------------+
   //| Pending Order Tracking Bridge                                 |
   //+---------------------------------------------------------------+
   int OrdersTotal(void)
     {
      return(::OrdersTotal());
     }

   ulong OrderGetTicket(const int index)
     {
      return(::OrderGetTicket(index));
     }

   long OrderGetInteger(const ulong ticket, const ENUM_ORDER_PROPERTY_INTEGER property)
     {
      int total = ::OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         ulong t = ::OrderGetTicket(i);
         if(t == ticket)
            return(::OrderGetInteger(property));
        }
      return(0);
     }

   string OrderGetString(const ulong ticket, const ENUM_ORDER_PROPERTY_STRING property)
     {
      int total = ::OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         ulong t = ::OrderGetTicket(i);
         if(t == ticket)
            return(::OrderGetString(property));
        }
      return("");
     }

   //+---------------------------------------------------------------+
   //| Deal History Bridge                                           |
   //+---------------------------------------------------------------+
   bool HistorySelect(const datetime from_date, const datetime to_date)
     {
      return(::HistorySelect(from_date, to_date));
     }

   int HistoryDealsTotal(void)
     {
      return(::HistoryDealsTotal());
     }

   ulong HistoryDealGetTicket(const int index)
     {
      return(::HistoryDealGetTicket(index));
     }

   long HistoryDealGetInteger(const ulong ticket, const ENUM_DEAL_PROPERTY_INTEGER property)
     {
      return(::HistoryDealGetInteger(ticket, property));
     }

   double HistoryDealGetDouble(const ulong ticket, const ENUM_DEAL_PROPERTY_DOUBLE property)
     {
      return(::HistoryDealGetDouble(ticket, property));
     }

   string HistoryDealGetString(const ulong ticket, const ENUM_DEAL_PROPERTY_STRING property)
     {
      return(::HistoryDealGetString(ticket, property));
     }
  };

#endif
//+------------------------------------------------------------------+
