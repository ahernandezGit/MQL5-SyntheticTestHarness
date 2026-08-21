//+------------------------------------------------------------------+
//|                                          BehaviorLibrary.mqh      |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_BEHAVIOR_LIBRARY_MQH
#define SYNTHETIC_TEST_HARNESS_BEHAVIOR_LIBRARY_MQH

#include "BehaviorDelegates.mqh"
#include "ErrorCodes.mqh"

//+------------------------------------------------------------------+
//| Stateful Mock Behaviors for Chaos Engineering                    |
//|                                                                  |
//| This module supplies pre-packaged behaviors for injecting faults |
//| and edge cases into the trading environment.                     |
//|                                                                  |
//| Stateful simulations:                                            |
//| Since MQL5 functions lack closures, stateful behaviors use local |
//| static variables to preserve lifecycle context across repeated   |
//| calls (e.g., counting retry attempts before achieving a fill).   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Behavior_RequoteTwice:                                           |
//| Simulates a broker that requotes 2 consecutive execution         |
//| attempts, and fills the order on the 3rd attempt.                |
//|                                                                  |
//| Lifecycle:                                                       |
//|   Call 1: Returns false, retcode = TRADE_RETCODE_REQUOTE (10004) |
//|   Call 2: Returns false, retcode = TRADE_RETCODE_REQUOTE (10004) |
//|   Call 3: Returns true,  retcode = TRADE_RETCODE_DONE    (10009) |
//|           Counter automatically resets to 0.                     |
//+------------------------------------------------------------------+
bool Behavior_RequoteTwice(MqlTradeRequest &request, MqlTradeResult &result)
  {
   static int call_count = 0;
   call_count++;

   ZeroMemory(result);

   if(call_count < 3)
     {
      result.retcode = SYNTH_ERR_REQUOTE; // TRADE_RETCODE_REQUOTE
      result.comment = StringFormat("Chaos Injection: Requote attempt #%d", call_count);
      return(false);
     }

   // 3rd attempt succeeds
   result.retcode = TRADE_RETCODE_DONE;
   result.volume  = request.volume;
   result.price   = (request.type == ORDER_TYPE_BUY) ? request.price : request.price;
   result.deal    = 12345678;
   result.order   = 87654321;
   result.comment = "Chaos Injection: Order filled on 3rd attempt";

   // Reset counter for subsequent cycles
   call_count = 0;
   return(true);
  }

//+------------------------------------------------------------------+
//| Behavior_FatalDisconnect:                                        |
//| Simulates an unrecoverable broker gateway / network disconnect.  |
//|                                                                  |
//| Returns false with TRADE_RETCODE_CONNECTION (10031).             |
//+------------------------------------------------------------------+
bool Behavior_FatalDisconnect(MqlTradeRequest &request, MqlTradeResult &result)
  {
   ZeroMemory(result);
   result.retcode = TRADE_RETCODE_CONNECTION; // 10031: No connection with the trade server
   result.comment = "Chaos Injection: Fatal broker disconnect simulated";
   return(false);
  }

#endif
//+------------------------------------------------------------------+
