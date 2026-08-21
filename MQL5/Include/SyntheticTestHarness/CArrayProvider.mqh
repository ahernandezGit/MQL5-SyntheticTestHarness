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
//+------------------------------------------------------------------+
class CArrayProvider : public ITickProvider
  {
private:
   MockTick          m_ticks[];
   int               m_current_index;
   int               m_tick_count;

public:
   CArrayProvider(MockTick &source_ticks[])
     {
      m_tick_count    = ArraySize(source_ticks);
      m_current_index = 0;

      ArrayResize(m_ticks, m_tick_count);
      for(int i = 0; i < m_tick_count; i++)
         m_ticks[i] = source_ticks[i];
     }

   bool HasNext(void)
     {
      return(m_current_index < m_tick_count);
     }

   bool GetNextTick(MockTick &out_tick)
     {
      if(!HasNext())
         return(false);

      out_tick = m_ticks[m_current_index];
      m_current_index++;
      return(true);
     }

   void Reset(void)
     {
      m_current_index = 0;
     }

   int GetTickCount(void)
     {
      return(m_tick_count);
     }
  };

//+------------------------------------------------------------------+
#endif
