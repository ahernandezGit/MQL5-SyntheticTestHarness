//+------------------------------------------------------------------+
//|                                          IMarketEnvironment.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 2 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_IMARKET_ENVIRONMENT_MQH
#define SYNTHETIC_TEST_HARNESS_IMARKET_ENVIRONMENT_MQH

//+------------------------------------------------------------------+
//| IMarketEnvironment: Outbound port abstracting the MT5 terminal.   |
//|                                                                   |
//| Decouples both trading strategy and risk management engines from  |
//| native global MT5 calls. Allows complete dependency injection.    |
//|                                                                   |
//| Concrete implementations:                                         |
//|   - CSyntheticEngine   (test: reads from injected ticks/delegates)|
//|   - CLiveEnvironment   (prod: delegates to native MT5 API `::`)   |
//+------------------------------------------------------------------+
interface IMarketEnvironment
  {
   //--- Price queries
   double            GetBid(void);
   double            GetAsk(void);
   double            GetSpread(void);

   //--- Time abstraction
   datetime          GetTimeCurrent(void);

   //--- Order execution: mirrors native OrderSend() contract
   bool              OrderSend(MqlTradeRequest &request,
                               MqlTradeResult  &result);

   //--- Depth of Market (DOM) abstraction: mirrors native MarketBookGet()
   bool              MarketBookGet(const string symbol,
                                   MqlBookInfo &book[]);

   //--- Generic Symbol Info Bridge
   double            SymbolInfoDouble(const string symbol, const ENUM_SYMBOL_INFO_DOUBLE property);
   long              SymbolInfoInteger(const string symbol, const ENUM_SYMBOL_INFO_INTEGER property);

   //--- Generic Account Info Bridge
   double            AccountInfoDouble(const ENUM_ACCOUNT_INFO_DOUBLE property);
   long              AccountInfoInteger(const ENUM_ACCOUNT_INFO_INTEGER property);

   //--- Margin Calculation Bridge
   bool              OrderCalcMargin(const ENUM_ORDER_TYPE action,
                                     const string symbol,
                                     const double volume,
                                     const double price,
                                     double &margin);

   //--- Position Tracking Bridge
   int               PositionsTotal(void);
   string            PositionGetSymbol(const int index);
   long              PositionGetInteger(const ENUM_POSITION_PROPERTY_INTEGER property);
   double            PositionGetDouble(const ENUM_POSITION_PROPERTY_DOUBLE property);

   //--- Pending Order Tracking Bridge
   int               OrdersTotal(void);
   ulong             OrderGetTicket(const int index);
   long              OrderGetInteger(const ulong ticket, const ENUM_ORDER_PROPERTY_INTEGER property);
   string            OrderGetString(const ulong ticket, const ENUM_ORDER_PROPERTY_STRING property);

   //--- Deal History Bridge (for PnL accounting)
   bool              HistorySelect(const datetime from_date, const datetime to_date);
   int               HistoryDealsTotal(void);
   ulong             HistoryDealGetTicket(const int index);
   long              HistoryDealGetInteger(const ulong ticket, const ENUM_DEAL_PROPERTY_INTEGER property);
   double            HistoryDealGetDouble(const ulong ticket, const ENUM_DEAL_PROPERTY_DOUBLE property);
   string            HistoryDealGetString(const ulong ticket, const ENUM_DEAL_PROPERTY_STRING property);
  };

#endif
//+------------------------------------------------------------------+
