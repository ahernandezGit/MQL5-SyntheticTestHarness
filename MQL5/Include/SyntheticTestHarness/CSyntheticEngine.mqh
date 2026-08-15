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

//+------------------------------------------------------------------+
//| CSyntheticEngine: the simulation motor.                           |
//|                                                                   |
//| Implements IMarketEnvironment by delegating price/time queries    |
//| to the current MockTick loaded from an injected ITickProvider.    |
//| The engine has ZERO calls to native MT5 global functions -        |
//| this is ASR-1 (testability without a live terminal).              |
//|                                                                   |
//| Ownership: non-owning reference to ITickProvider. The caller      |
//| (test script) creates the provider, injects it, and destroys it.  |
//|                                                                   |
//| Lifecycle:                                                        |
//|   1. Construct with a provider pointer                            |
//|   2. Loop: ProcessNextTick() -> query Get*() / TryExecuteOrder()  |
//|   3. ProcessNextTick() returns false when data is exhausted       |
//+------------------------------------------------------------------+
class CSyntheticEngine : public IMarketEnvironment
  {
private:
   ITickProvider    *m_provider;
   MockTick          m_current_tick;
   bool              m_tick_loaded;
   int               m_ticks_processed;

public:
   //+---------------------------------------------------------------+
   //| Constructor: receives the tick provider via Dependency         |
   //| Injection. Does NOT take ownership of the pointer.             |
   //+---------------------------------------------------------------+
    CSyntheticEngine(ITickProvider *provider)
     {
      m_provider        = provider;
      m_tick_loaded     = false;
      m_ticks_processed = 0;
      ZeroMemory(m_current_tick);
     }

   //+---------------------------------------------------------------+
   //| Destructor: nullifies the non-owning pointer. Does NOT delete. |
   //+---------------------------------------------------------------+
    ~CSyntheticEngine(void)
     {
      m_provider = NULL;
     }

   //+---------------------------------------------------------------+
   //| ProcessNextTick: advances the simulation by one tick.          |
   //| Returns false when all ticks are exhausted or the provider     |
   //| is NULL.                                                       |
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

   //--- IMarketEnvironment: price queries delegate to current tick --

   double GetBid(void)
     {
      return(m_current_tick.bid);
     }

   double GetAsk(void)
     {
      return(m_current_tick.ask);
     }

   double GetSpread(void)
     {
      return(m_current_tick.spread_points);
     }

   //--- IMarketEnvironment: time abstraction -------------------------

   datetime GetTimeCurrent(void)
     {
      return(m_current_tick.time);
     }

   //+---------------------------------------------------------------+
   //| TryExecuteOrder: simulates order execution with error          |
   //| injection from the current tick.                               |
   //|                                                                |
   //| Uses the same MqlTradeRequest/MqlTradeResult structures as     |
   //| the native OrderSend(). This ensures test code and production  |
   //| code use identical call patterns — no signature mismatch.      |
   //|                                                                |
   //| Behavior:                                                      |
   //|   - tick not loaded       -> fails with TRADE_RETCODE_PRICE_OFF|
   //|   - injected_error != 0   -> fails with that error code        |
   //|   - injected_error == 0   -> succeeds with TRADE_RETCODE_DONE  |
   //+---------------------------------------------------------------+
   bool TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result)
     {
      ZeroMemory(result);

      //--- Guard: no tick has been loaded yet
      if(!m_tick_loaded)
        {
         result.retcode = SYNTH_ERR_PRICE_OFF;
         return(false);
        }

      //--- Check for injected chaos
      if(IsExecutionError(m_current_tick.injected_error))
        {
         result.retcode = (uint)m_current_tick.injected_error;
         return(false);
        }

      //--- Simulate a successful fill with realistic field values
      result.retcode = TRADE_RETCODE_DONE;
      result.volume  = request.volume;
      result.bid     = m_current_tick.bid;
      result.ask     = m_current_tick.ask;

      //--- Fill execution price based on order direction
      if(request.type == ORDER_TYPE_BUY)
         result.price = m_current_tick.ask;
      else
         result.price = m_current_tick.bid;

      return(true);
     }

   //--- Diagnostic accessors (not part of IMarketEnvironment) -------

   int GetTicksProcessed(void)
     {
      return(m_ticks_processed);
     }

   bool IsTickLoaded(void)
     {
      return(m_tick_loaded);
     }
  };


//+------------------------------------------------------------------+
#endif
