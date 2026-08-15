//+------------------------------------------------------------------+
//|                                               CArrayProvider.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CARRAY_PROVIDER_MQH
#define SYNTHETIC_TEST_HARNESS_CARRAY_PROVIDER_MQH

#include "ITickProvider.mqh"

//+------------------------------------------------------------------+
//| CArrayProvider: reads synthetic ticks from an in-memory array.    |
//|                                                                   |
//| Usage: define your scenario as a MockTick[], pass it to the       |
//| constructor, and the provider iterates through it sequentially.   |
//| Call Reset() to re-run the same scenario without re-creating      |
//| the provider.                                                     |
//|                                                                   |
//| Ownership: copies the source array internally (owns its data).    |
//+------------------------------------------------------------------+
class CArrayProvider : public ITickProvider
  {
private:
   MockTick          m_ticks[];
   int               m_current_index;
   int               m_tick_count;

public:
   //+---------------------------------------------------------------+
   //| Constructor: copies the source array so the provider owns its  |
   //| data. The caller's array can be safely discarded after this.   |
   //+---------------------------------------------------------------+
    CArrayProvider(MockTick &source_ticks[])
     {
      m_tick_count    = ArraySize(source_ticks);
      m_current_index = 0;

      ArrayResize(m_ticks, m_tick_count);
      for(int i = 0; i < m_tick_count; i++)
         m_ticks[i] = source_ticks[i];
     }

   //+---------------------------------------------------------------+
   //| HasNext: returns true if unprocessed ticks remain.             |
   //+---------------------------------------------------------------+
   bool HasNext(void)
     {
      return(m_current_index < m_tick_count);
     }

   //+---------------------------------------------------------------+
   //| GetNextTick: fills out_tick and advances the cursor by one.    |
   //| Returns false when all ticks have been consumed.               |
   //+---------------------------------------------------------------+
   bool GetNextTick(MockTick &out_tick)
     {
      if(!HasNext())
         return(false);

      out_tick = m_ticks[m_current_index];
      m_current_index++;
      return(true);
     }

   //+---------------------------------------------------------------+
   //| Reset: rewinds to the first tick for re-running scenarios.     |
   //+---------------------------------------------------------------+
   void Reset(void)
     {
      m_current_index = 0;
     }

   //+---------------------------------------------------------------+
   //| GetTickCount: returns the total number of ticks in the array.  |
   //+---------------------------------------------------------------+
   int GetTickCount(void)
     {
      return(m_tick_count);
     }
  };

//+------------------------------------------------------------------+
#endif
