//+------------------------------------------------------------------+
//|                                       MockEquityPeakStore.mqh    |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 2 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_MOCK_EQUITY_PEAK_STORE_MQH
#define SYNTHETIC_TEST_HARNESS_MOCK_EQUITY_PEAK_STORE_MQH

//+------------------------------------------------------------------+
//| In-Memory Equity Peak Store for Hermetic Testing                 |
//|                                                                  |
//| Provides three function-pointer-compatible stubs that satisfy    |
//| CRiskManager::SetEquityPeakStorage(). All state is kept in      |
//| function-local statics — zero dependency on the MT5 terminal's   |
//| GlobalVariable* subsystem.                                       |
//|                                                                  |
//| Usage:                                                           |
//|   MockEquityPeakStore::Reset();            // between test runs  |
//|   rm.SetEquityPeakStorage(MockEPCheck,     //                    |
//|                           MockEPGet,       //                    |
//|                           MockEPSet);      //                    |
//|                                                                  |
//| Design:                                                          |
//|   - Supports up to MAX_MOCK_GV_ENTRIES concurrent peak entries   |
//|     (keyed by the "RM_Peak_<magic>_<symbol>" name string).       |
//|   - Reset() clears all entries for test isolation between runs.  |
//|   - No GlobalVariable*, no terminal state, fully hermetic.       |
//+------------------------------------------------------------------+

#define MAX_MOCK_GV_ENTRIES 16

//+------------------------------------------------------------------+
//| Static storage class — manages the in-memory key-value store     |
//+------------------------------------------------------------------+
class MockEquityPeakStore
  {
private:
   static string     s_keys[];
   static double     s_values[];
   static int        s_count;

   static int        FindKey(const string name)
     {
      for(int i = 0; i < s_count; i++)
        {
         if(s_keys[i] == name)
            return(i);
        }
      return(-1);
     }

public:
   //--- Reset all stored peaks (call between test runs for isolation)
   static void       Reset(void)
     {
      s_count = 0;
      ArrayResize(s_keys, 0);
      ArrayResize(s_values, 0);
     }

   //--- Check if a named peak entry exists
   static bool       Check(const string name)
     {
      return(FindKey(name) >= 0);
     }

   //--- Get the stored peak value (returns 0.0 if not found)
   static double     Get(const string name)
     {
      int idx = FindKey(name);
      if(idx >= 0)
         return(s_values[idx]);
      return(0.0);
     }

   //--- Set (upsert) a named peak value
   static bool       Set(const string name, const double value)
     {
      int idx = FindKey(name);
      if(idx >= 0)
        {
         s_values[idx] = value;
         return(true);
        }
      if(s_count >= MAX_MOCK_GV_ENTRIES)
        {
         PrintFormat("[MockEquityPeakStore] ERROR: Store full (%d entries). Increase MAX_MOCK_GV_ENTRIES.", MAX_MOCK_GV_ENTRIES);
         return(false);
        }
      ArrayResize(s_keys, s_count + 1);
      ArrayResize(s_values, s_count + 1);
      s_keys[s_count]   = name;
      s_values[s_count]  = value;
      s_count++;
      return(true);
     }

   //--- Diagnostic: number of stored entries
   static int        Count(void) { return(s_count); }
  };

//--- Static member initialization
string MockEquityPeakStore::s_keys[];
double MockEquityPeakStore::s_values[];
int    MockEquityPeakStore::s_count = 0;

//+------------------------------------------------------------------+
//| Free functions matching CRiskManager delegate signatures         |
//|                                                                  |
//| These are the actual function pointers you pass to               |
//| CRiskManager::SetEquityPeakStorage().                            |
//+------------------------------------------------------------------+
bool MockEPCheck(const string name)
  {
   return(MockEquityPeakStore::Check(name));
  }

double MockEPGet(const string name)
  {
   return(MockEquityPeakStore::Get(name));
  }

bool MockEPSet(const string name, const double value)
  {
   return(MockEquityPeakStore::Set(name, value));
  }

#endif
//+------------------------------------------------------------------+
