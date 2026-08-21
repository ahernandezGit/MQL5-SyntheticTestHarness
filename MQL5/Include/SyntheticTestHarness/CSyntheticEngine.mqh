//+------------------------------------------------------------------+
//|                                            CSyntheticEngine.mqh   |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CSYNTHETIC_ENGINE_MQH
#define SYNTHETIC_TEST_HARNESS_CSYNTHETIC_ENGINE_MQH

#include "IMarketEnvironment.mqh"
#include "ITickProvider.mqh"
#include "ErrorCodes.mqh"
#include "BehaviorDelegates.mqh"

//+------------------------------------------------------------------+
//| CSyntheticEngine: Dynamic Synthetic Mock & Simulation Motor.      |
//|                                                                   |
//| Implements IMarketEnvironment using a Dual-Mode testing paradigm: |
//|                                                                   |
//| 1. Behavior Injection Mode (Dynamic Programmable Mock):           |
//|    Allows on-the-fly injection of C-style function pointers       |
//|    (`typedef` delegates) to override specific method behaviors    |
//|    (e.g., simulating requotes, disconnections, or custom DOMs).   |
//|    This decouples the engine for Chaos Engineering without        |
//|    needing complex mock frameworks or rebuilding tick datasets.   |
//|                                                                   |
//| 2. Tick-Driven Simulation Mode (Deterministic Replay):            |
//|    If no behavior function pointer is set for a method, the       |
//|    engine falls back to reading prices and error injection from   |
//|    the current MockTick supplied by an injected ITickProvider.    |
//|                                                                   |
//| Priority Order:                                                   |
//|   Injected Function Pointer -> Current MockTick -> Safe Default   |
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

public:
   //+---------------------------------------------------------------+
   //| Constructor: optionally receives a tick provider via DI.      |
   //| Does NOT take ownership of the pointer.                       |
   //+---------------------------------------------------------------+
   CSyntheticEngine(ITickProvider *provider = NULL)
     {
      m_provider                = provider;
      m_tick_loaded             = false;
      m_ticks_processed         = 0;
      ZeroMemory(m_current_tick);

      ResetAllBehaviors();
     }

   //+---------------------------------------------------------------+
   //| Destructor: nullifies references. Does NOT delete provider.   |
   //+---------------------------------------------------------------+
   ~CSyntheticEngine(void)
     {
      m_provider = NULL;
     }

   //+---------------------------------------------------------------+
   //| Behavior Injection Setters                                     |
   //| Allows injecting programmable delegates at runtime.            |
   //+---------------------------------------------------------------+
   void MockOrderSend(TOrderSendBehavior behavior)
     {
      m_orderSendBehavior = behavior;
     }

   void MockGetBid(TGetBidBehavior behavior)
     {
      m_getBidBehavior = behavior;
     }

   void MockGetAsk(TGetAskBehavior behavior)
     {
      m_getAskBehavior = behavior;
     }

   void MockGetSpread(TGetSpreadBehavior behavior)
     {
      m_getSpreadBehavior = behavior;
     }

   void MockGetTimeCurrent(TGetTimeCurrentBehavior behavior)
     {
      m_getTimeCurrentBehavior = behavior;
     }

   void MockMarketBookGet(TMarketBookGetBehavior behavior)
     {
      m_marketBookGetBehavior = behavior;
     }

   //+---------------------------------------------------------------+
   //| Reset Functions: clears injected behavior delegates.          |
   //+---------------------------------------------------------------+
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
   //| SetTickProvider: updates or attaches a tick data provider.     |
   //+---------------------------------------------------------------+
   void SetTickProvider(ITickProvider *provider)
     {
      m_provider        = provider;
      m_tick_loaded     = false;
      m_ticks_processed = 0;
      ZeroMemory(m_current_tick);
     }

   //+---------------------------------------------------------------+
   //| ProcessNextTick: advances the simulation by one tick.          |
   //| Returns false when all ticks are exhausted or provider is NULL|
   //+---------------------------------------------------------------+
   bool ProcessNextTick(void)
     {
      if(m_provider == NULL)
         return(false);

      if(!m_provider.HasNext())
         return(false);

      m_tick_loaded = m_provider.GetNextTick(m_current_tick);

      if(m_tick_loaded)
         m_ticks_processed++;

      return(m_tick_loaded);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Price Queries                             |
   //+---------------------------------------------------------------+
   double GetBid(void)
     {
      if(m_getBidBehavior != NULL)
         return(m_getBidBehavior());

      if(m_tick_loaded)
         return(m_current_tick.bid);

      return(1.10000);
     }

   double GetAsk(void)
     {
      if(m_getAskBehavior != NULL)
         return(m_getAskBehavior());

      if(m_tick_loaded)
         return(m_current_tick.ask);

      return(1.10020);
     }

   double GetSpread(void)
     {
      if(m_getSpreadBehavior != NULL)
         return(m_getSpreadBehavior());

      if(m_tick_loaded)
         return(m_current_tick.spread_points);

      return(20.0);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Time Abstraction                          |
   //+---------------------------------------------------------------+
   datetime GetTimeCurrent(void)
     {
      if(m_getTimeCurrentBehavior != NULL)
         return(m_getTimeCurrentBehavior());

      if(m_tick_loaded)
         return(m_current_tick.time);

      return(D'2026.01.15 10:00:00');
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Order Execution                           |
   //|                                                               |
   //| Execution Priority:                                           |
   //| 1. Injected Behavior Delegate (TOrderSendBehavior)            |
   //| 2. Tick-Driven Simulation & Fault Injection                   |
   //+---------------------------------------------------------------+
   bool OrderSend(MqlTradeRequest &request, MqlTradeResult &result)
     {
      //--- 1. Behavior Injection Hook (Highest Priority)
      if(m_orderSendBehavior != NULL)
         return(m_orderSendBehavior(request, result));

      //--- 2. Tick-Driven Execution Mode
      ZeroMemory(result);

      //--- Guard: no tick loaded
      if(!m_tick_loaded)
        {
         result.retcode = SYNTH_ERR_PRICE_OFF;
         return(false);
        }

      //--- Injected fault in tick
      if(IsExecutionError(m_current_tick.injected_error))
        {
         result.retcode = (uint)m_current_tick.injected_error;
         return(false);
        }

      //--- Simulate successful fill
      result.retcode = TRADE_RETCODE_DONE;
      result.volume  = request.volume;
      result.bid     = m_current_tick.bid;
      result.ask     = m_current_tick.ask;

      if(request.type == ORDER_TYPE_BUY)
         result.price = m_current_tick.ask;
      else
         result.price = m_current_tick.bid;

      return(true);
     }

   //+---------------------------------------------------------------+
   //| IMarketEnvironment: Depth of Market (DOM)                     |
   //+---------------------------------------------------------------+
   bool MarketBookGet(const string symbol, MqlBookInfo &book[])
     {
      if(m_marketBookGetBehavior != NULL)
         return(m_marketBookGetBehavior(symbol, book));

      // Default synthetic behavior: no DOM available
      ArrayFree(book);
      return(false);
     }

   //+---------------------------------------------------------------+
   //| Diagnostic accessors                                          |
   //+---------------------------------------------------------------+
   int GetTicksProcessed(void)
     {
      return(m_ticks_processed);
     }

   bool IsTickLoaded(void)
     {
      return(m_tick_loaded);
     }
  };

#endif
//+------------------------------------------------------------------+
