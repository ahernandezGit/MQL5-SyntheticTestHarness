//+------------------------------------------------------------------+
//|                                                ITickProvider.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_ITICK_PROVIDER_MQH
#define SYNTHETIC_TEST_HARNESS_ITICK_PROVIDER_MQH

#include "MockTick.mqh"

//+------------------------------------------------------------------+
//| ITickProvider: inbound port for tick data sources.                |
//|                                                                   |
//| This is the Strategy Pattern interface. The engine depends on     |
//| this abstraction, never on a concrete data source. New sources    |
//| (CSV file, network stream, random generator) extend the system    |
//| by implementing this interface - no existing code changes.        |
//|                                                                   |
//| Concrete implementations:                                         |
//|   - CArrayProvider   (in-memory array, for rapid prototyping)     |
//|   - [Future] CFileProvider   (CSV/binary file)                    |
//|   - [Future] CRandomProvider (Monte Carlo scenarios)              |
//+------------------------------------------------------------------+
interface ITickProvider
  {
   //--- Returns true if the provider has remaining ticks to deliver
   bool              HasNext(void);

   //--- Advances the cursor and fills out_tick with the next data point.
   //--- Returns false if no tick was available (exhausted).
   bool              GetNextTick(MockTick &out_tick);
  };


//+------------------------------------------------------------------+
#endif
