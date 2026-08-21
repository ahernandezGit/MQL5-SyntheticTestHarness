//+------------------------------------------------------------------+
//|                                           CSyntheticEngine.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 2 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CSYNTHETIC_ENGINE_MQH
#define SYNTHETIC_TEST_HARNESS_CSYNTHETIC_ENGINE_MQH

#include "IMarketEnvironment.mqh"
#include "ITickProvider.mqh"
#include "MockTick.mqh"
#include "ErrorCodes.mqh"
#include "BehaviorDelegates.mqh"
#include "MockPositionStore.mqh"

//+------------------------------------------------------------------+
//| CSyntheticEngine: Dual-Mode Deterministic Testing Adapter.       |
//|                                                                  |
//| Execution Priority:                                              |
//|   Injected Function Pointer -> Current MockTick -> Safe Default  |
//|                                                                  |
//| Delegates position, order, and deal history tracking to the      |
//| dedicated CMockPositionStore data container.                     |
//+------------------------------------------------------------------+
class CSyntheticEngine : public IMarketEnvironment
  {
private:
   ITickProvider              *m_provider;
   MockTick                    m_current_tick;
   bool                        m_tick_loaded;
   int                         m_ticks_processed;

   //--- Dynamic Behavior Delegates (Function Pointers)
   TOrderSendBehavior          m_orderSendBehavior;
   TGetBidBehavior             m_getBidBehavior;
   TGetAskBehavior             m_getAskBehavior;
   TGetSpreadBehavior          m_getSpreadBehavior;
   TGetTimeCurrentBehavior     m_getTimeCurrentBehavior;
   TMarketBookGetBehavior      m_marketBookGetBehavior;

   //--- Dedicated In-Memory Mock Position & Deal Store
   CMockPositionStore          m_position_store;

   //--- Configurable Mock Account State
   double                      m_mock_balance;
   double                      m_mock_equity;
   double                      m_mock_margin_free;
   long                        m_mock_leverage;

   //--- Configurable Mock Symbol Properties
   double                      m_mock_point;
   double                      m_mock_tick_value;
   double                      m_mock_tick_size;
   double                      m_mock_vol_min;
   double                      m_mock_vol_max;
   double                      m_mock_vol_step;
   long                        m_mock_calc_mode;
   long                        m_mock_digits;

public:
   //+---------------------------------------------------------------+
   //| Constructor & Destructor                                      |
   //+---------------------------------------------------------------+
   CSyntheticEngine(ITickProvider *provider = NULL)
     {
      m_provider                = provider;
      m_tick_loaded             = false;
      m_ticks_processed         = 0;
      ZeroMemory(m_current_tick);

      // Default Account Mocking
      m_mock_balance            = 100000.0;
      m_mock_equity             = 100000.0;
      m_mock_margin_free        = 100000.0;
      m_mock_leverage           = 100;

      // Default Symbol Mocking (Standard EURUSD-like profile)
      m_mock_point              = 0.00001;
      m_mock_tick_value         = 1.0;
      m_mock_tick_size          = 0.00001;
      m_mock_vol_min            = 0.01;
      m_mock_vol_max            = 100.0;
      m_mock_vol_step           = 0.01;
      m_mock_calc_mode          = (long)SYMBOL_CALC_MODE_FOREX;
      m_mock_digits             = 5;

      ResetAllBehaviors();
     }

   ~CSyntheticEngine(void)
     {
      m_provider = NULL;
     }

   //+---------------------------------------------------------------+
   //| Behavior Injection Hooks                                      |
   //+---------------------------------------------------------------+
   void MockOrderSend(TOrderSendBehavior behavior)             { m_orderSendBehavior = behavior; }
   void MockGetBid(TGetBidBehavior behavior)                   { m_getBidBehavior = behavior; }
   void MockGetAsk(TGetAskBehavior behavior)                   { m_getAskBehavior = behavior; }
   void MockGetSpread(TGetSpreadBehavior behavior)             { m_getSpreadBehavior = behavior; }
   void MockGetTimeCurrent(TGetTimeCurrentBehavior behavior)   { m_getTimeCurrentBehavior = behavior; }
   void MockMarketBookGet(TMarketBookGetBehavior behavior)     { m_marketBookGetBehavior = behavior; }

   void ResetOrderSend(void)        { m_orderSendBehavior      = NULL; }
   void ResetGetBid(void)           { m_getBidBehavior         = NULL; }
   void ResetGetAsk(void)           { m_getAskBehavior         = NULL; }
   void ResetGetSpread(void)        { m_getSpreadBehavior      = NULL; }
   void ResetGetTimeCurrent(void)   { m_getTimeCurrentBehavior = NULL; }
   void ResetMarketBookGet(void)    { m_marketBookGetBehavior  = NULL; }

   void ResetAllBehaviors(void)
     {
      m_orderSendBehavior      = NULL;
      m_getBidBehavior         = NULL;
      m_getAskBehavior         = NULL;
      m_getSpreadBehavior      = NULL;
      m_getTimeCurrentBehavior = NULL;
      m_marketBookGetBehavior  = NULL;
     }

   //+---------------------------------------------------------------+
   //| Position Store Direct Accessor (for Test Setup)               |
   //+---------------------------------------------------------------+
   CMockPositionStore* GetPositionStore(void)
     {
      return(&m_position_store);
     }

   //+---------------------------------------------------------------+
   //| Setters for Mock Account and Symbol Environment Properties    |
   //+---------------------------------------------------------------+
   void SetMockBalance(const double b)              { m_mock_balance = b; }
   void SetMockEquity(const double e)               { m_mock_equity = e; }
   void SetMockMarginFree(const double m)           { m_mock_margin_free = m; }
   void SetMockLeverage(const long l)               { m_mock_leverage = l; }
   void SetMockPoint(const double p)                { m_mock_point = p; }
   void SetMockTickValue(const double tv)           { m_mock_tick_value = tv; }
   void SetMockTickSize(const double ts)            { m_mock_tick_size = ts; }
   void SetMockVolumeLimits(const double min_vol, const double max_vol, const double step_vol)
     {
      m_mock_vol_min  = min_vol;
      m_mock_vol_max  = max_vol;
      m_mock_vol_step = step_vol;
     }
   void SetMockCalcMode(const long mode)            { m_mock_calc_mode = mode; }
   void SetMockDigits(const long d)                 { m_mock_digits = d; }

   //+---------------------------------------------------------------+
   //| Tick Provider Control                                         |
   //+---------------------------------------------------------------+
   void SetTickProvider(ITickProvider *provider)
     {
      m_provider        = provider;
      m_tick_loaded     = false;
      m_ticks_processed = 0;
      ZeroMemory(m_current_tick);
     }

   bool ProcessNextTick(void)
     {
      if(m_provider == NULL) return(false);
      if(!m_provider.HasNext()) return(false);

      m_tick_loaded = m_provider.GetNextTick(m_current_tick);
      if(m_tick_loaded) m_ticks_processed++;
      return(m_tick_loaded);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Price & Time Queries                      |
   //+---------------------------------------------------------------+
   double GetBid(void)
     {
      if(m_getBidBehavior != NULL) return(m_getBidBehavior());
      if(m_tick_loaded) return(m_current_tick.bid);
      return(1.10000);
     }

   double GetAsk(void)
     {
      if(m_getAskBehavior != NULL) return(m_getAskBehavior());
      if(m_tick_loaded) return(m_current_tick.ask);
      return(1.10020);
     }

   double GetSpread(void)
     {
      if(m_getSpreadBehavior != NULL) return(m_getSpreadBehavior());
      if(m_tick_loaded) return(m_current_tick.spread_points);
      return(20.0);
     }

   datetime GetTimeCurrent(void)
     {
      if(m_getTimeCurrentBehavior != NULL) return(m_getTimeCurrentBehavior());
      if(m_tick_loaded) return(m_current_tick.time);
      return(D'2026.01.15 10:00:00');
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Order Execution                           |
   //+---------------------------------------------------------------+
   bool OrderSend(MqlTradeRequest &request, MqlTradeResult &result)
     {
      if(m_orderSendBehavior != NULL)
         return(m_orderSendBehavior(request, result));

      ZeroMemory(result);

      if(!m_tick_loaded)
        {
         result.retcode = SYNTH_ERR_PRICE_OFF;
         return(false);
        }

      if(IsExecutionError(m_current_tick.injected_error))
        {
         result.retcode = (uint)m_current_tick.injected_error;
         return(false);
        }

      result.retcode = TRADE_RETCODE_DONE;
      result.volume  = request.volume;
      result.bid     = m_current_tick.bid;
      result.ask     = m_current_tick.ask;
      result.price   = (request.type == ORDER_TYPE_BUY) ? m_current_tick.ask : m_current_tick.bid;
      result.deal    = 12345678;
      result.order   = 87654321;
      return(true);
     }

   bool MarketBookGet(const string symbol, MqlBookInfo &book[])
     {
      if(m_marketBookGetBehavior != NULL)
         return(m_marketBookGetBehavior(symbol, book));

      ArrayFree(book);
      return(false);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Generic Symbol Info Bridge                |
   //+---------------------------------------------------------------+
   double SymbolInfoDouble(const string symbol, const ENUM_SYMBOL_INFO_DOUBLE property)
     {
      switch(property)
        {
         case SYMBOL_BID:              return(GetBid());
         case SYMBOL_ASK:              return(GetAsk());
         case SYMBOL_POINT:            return(m_mock_point);
         case SYMBOL_TRADE_TICK_VALUE: return(m_mock_tick_value);
         case SYMBOL_TRADE_TICK_SIZE:  return(m_mock_tick_size);
         case SYMBOL_VOLUME_MIN:       return(m_mock_vol_min);
         case SYMBOL_VOLUME_MAX:       return(m_mock_vol_max);
         case SYMBOL_VOLUME_STEP:      return(m_mock_vol_step);
         default:                      return(0.0);
        }
     }

   long SymbolInfoInteger(const string symbol, const ENUM_SYMBOL_INFO_INTEGER property)
     {
      switch(property)
        {
         case SYMBOL_SPREAD:           return((long)GetSpread());
         case SYMBOL_TRADE_CALC_MODE:  return(m_mock_calc_mode);
         case SYMBOL_DIGITS:           return(m_mock_digits);
         default:                      return(0);
        }
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Generic Account Info Bridge               |
   //+---------------------------------------------------------------+
   double AccountInfoDouble(const ENUM_ACCOUNT_INFO_DOUBLE property)
     {
      switch(property)
        {
         case ACCOUNT_BALANCE:     return(m_mock_balance);
         case ACCOUNT_EQUITY:      return(m_mock_equity);
         case ACCOUNT_MARGIN_FREE: return(m_mock_margin_free);
         default:                  return(0.0);
        }
     }

   long AccountInfoInteger(const ENUM_ACCOUNT_INFO_INTEGER property)
     {
      switch(property)
        {
         case ACCOUNT_LEVERAGE:    return(m_mock_leverage);
         default:                  return(0);
        }
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Margin Calculation                        |
   //+---------------------------------------------------------------+
   bool OrderCalcMargin(const ENUM_ORDER_TYPE action,
                        const string symbol,
                        const double volume,
                        const double price,
                        double &margin)
     {
      // Deterministic synthetic margin estimation based on leverage
      if(m_mock_leverage <= 0) return(false);
      margin = (volume * 100000.0 * price) / (double)m_mock_leverage;
      return(true);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Delegations to CMockPositionStore         |
   //+---------------------------------------------------------------+
   int PositionsTotal(void)
     {
      return(m_position_store.PositionsTotal());
     }

   string PositionGetSymbol(const int index)
     {
      return(m_position_store.PositionGetSymbol(index));
     }

   long PositionGetInteger(const ENUM_POSITION_PROPERTY_INTEGER property)
     {
      return(m_position_store.PositionGetInteger(property));
     }

   double PositionGetDouble(const ENUM_POSITION_PROPERTY_DOUBLE property)
     {
      return(m_position_store.PositionGetDouble(property));
     }

   int OrdersTotal(void)
     {
      return(m_position_store.OrdersTotal());
     }

   ulong OrderGetTicket(const int index)
     {
      return(m_position_store.OrderGetTicket(index));
     }

   long OrderGetInteger(const ulong ticket, const ENUM_ORDER_PROPERTY_INTEGER property)
     {
      return(m_position_store.OrderGetInteger(ticket, property));
     }

   string OrderGetString(const ulong ticket, const ENUM_ORDER_PROPERTY_STRING property)
     {
      return(m_position_store.OrderGetString(ticket, property));
     }

   bool HistorySelect(const datetime from_date, const datetime to_date)
     {
      return(m_position_store.HistorySelect(from_date, to_date));
     }

   int HistoryDealsTotal(void)
     {
      return(m_position_store.HistoryDealsTotal());
     }

   ulong HistoryDealGetTicket(const int index)
     {
      return(m_position_store.HistoryDealGetTicket(index));
     }

   long HistoryDealGetInteger(const ulong ticket, const ENUM_DEAL_PROPERTY_INTEGER property)
     {
      return(m_position_store.HistoryDealGetInteger(ticket, property));
     }

   double HistoryDealGetDouble(const ulong ticket, const ENUM_DEAL_PROPERTY_DOUBLE property)
     {
      return(m_position_store.HistoryDealGetDouble(ticket, property));
     }

   string HistoryDealGetString(const ulong ticket, const ENUM_DEAL_PROPERTY_STRING property)
     {
      return(m_position_store.HistoryDealGetString(ticket, property));
     }

   //+---------------------------------------------------------------+
   //| Diagnostics                                                   |
   //+---------------------------------------------------------------+
   int GetTicksProcessed(void) const { return(m_ticks_processed); }
   bool IsTickLoaded(void) const     { return(m_tick_loaded); }
  };

#endif
//+------------------------------------------------------------------+
