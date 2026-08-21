//+------------------------------------------------------------------+
//|                                                      CAssert.mqh |
//|                          Synthetic Test Harness for MetaTrader 5 |
//|              Institutional Architecture in MQL5 - Part 1 Series  |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CASSERT_MQH
#define SYNTHETIC_TEST_HARNESS_CASSERT_MQH

//+------------------------------------------------------------------+
//| CAssert: Centralized self-validating assertions and reporting    |
//| for MQL5 unit and scenario testing (FIRST principle).            |
//+------------------------------------------------------------------+
class CAssert
  {
private:
   static int        m_passed;
   static int        m_failed;
   static string     m_report;

public:
   //--- Reset state before running test suites
   static void       Reset(void)
     {
      m_passed = 0;
      m_failed = 0;
      m_report = "";
     }

   //--- Logging helper: prints to Experts log and updates chart comments
   static void       Log(const string msg)
     {
      if(msg != "")
         Print(msg);
      m_report += msg + "\n";
      Comment(m_report);
     }

   //--- Metrics getters
   static int        PassedCount(void)  { return(m_passed); }
   static int        FailedCount(void)  { return(m_failed); }
   static int        TotalCount(void)   { return(m_passed + m_failed); }
   static bool       AllPassed(void)    { return(m_failed == 0 && m_passed > 0); }
   static string     GetReport(void)    { return(m_report); }

   //--- Assert True: foundational assertion
   static void       True(const string test_name, const bool condition)
     {
      if(condition)
        {
         m_passed++;
         PrintFormat("  [PASS] %s", test_name);
        }
      else
        {
         m_failed++;
         PrintFormat("  [FAIL] %s", test_name);
        }
     }

   //--- Assert False: inverted condition assertion
   static void       False(const string test_name, const bool condition)
     {
      True(test_name, !condition);
     }

   //--- Assert Equal (Double with tolerance)
   static void       Equal(const string test_name,
                           const double expected,
                           const double actual,
                           const double epsilon = 0.00001)
     {
      bool match = (MathAbs(expected - actual) < epsilon);
      if(!match)
         Log(StringFormat("    Expected=%.5f  Actual=%.5f", expected, actual));
      True(test_name, match);
     }

   static void       DoubleEqual(const string test_name,
                                 const double expected,
                                 const double actual,
                                 const double epsilon = 0.00001)
     {
      Equal(test_name, expected, actual, epsilon);
     }

   //--- Assert Integer Equal
   static void       IntEqual(const string test_name,
                              const int expected,
                              const int actual)
     {
      bool match = (expected == actual);
      if(!match)
         Log(StringFormat("    Expected=%d  Actual=%d", expected, actual));
      True(test_name, match);
     }

   //--- Assert Long Integer Equal
   static void       LongEqual(const string test_name,
                               const long expected,
                               const long actual)
     {
      bool match = (expected == actual);
      if(!match)
         Log(StringFormat("    Expected=%I64d  Actual=%I64d", expected, actual));
      True(test_name, match);
     }

   //--- Assert Unsigned Integer Equal
   static void       UintEqual(const string test_name,
                               const uint expected,
                               const uint actual)
     {
      bool match = (expected == actual);
      if(!match)
         Log(StringFormat("    Expected=%u  Actual=%u", expected, actual));
      True(test_name, match);
     }

   //--- Assert Unsigned Long Equal
   static void       UlongEqual(const string test_name,
                                const ulong expected,
                                const ulong actual)
     {
      bool match = (expected == actual);
      if(!match)
         Log(StringFormat("    Expected=%I64u  Actual=%I64u", expected, actual));
      True(test_name, match);
     }

   //--- Assert String Equal
   static void       StringEqual(const string test_name,
                                 const string expected,
                                 const string actual)
     {
      bool match = (expected == actual);
      if(!match)
         Log(StringFormat("    Expected=\"%s\"  Actual=\"%s\"", expected, actual));
      True(test_name, match);
     }

   //--- Display summary & MessageBox dialog
   static void       Summary(const string suite_title = "Test Results",
                             const bool show_message_box = true)
     {
      Log("");
      Log("==========================================================");
      string summary = StringFormat("  RESULTS: %d passed, %d failed, %d total",
                                    m_passed, m_failed, TotalCount());
      Log(summary);

      string status;
      uint icon;
      if(m_failed == 0 && m_passed > 0)
        {
         status = "  STATUS: ALL TESTS PASSED (100% SUCCESS)";
         icon = MB_ICONINFORMATION;
        }
      else if(m_failed == 0 && m_passed == 0)
        {
         status = "  STATUS: NO TESTS EXECUTED";
         icon = MB_ICONWARNING;
        }
      else
        {
         status = "  STATUS: SOME TESTS FAILED";
         icon = MB_ICONERROR;
        }

      Log(status);
      Log("==========================================================");

      if(show_message_box)
         MessageBox(summary + "\n\n" + status, suite_title, icon | MB_OK);

      Comment("");
     }
  };

//+------------------------------------------------------------------+
//| Static member variable initialization                            |
//+------------------------------------------------------------------+
int    CAssert::m_passed = 0;
int    CAssert::m_failed = 0;
string CAssert::m_report = "";

//+------------------------------------------------------------------+
//| Global helper functions for functional assertion syntax           |
//+------------------------------------------------------------------+
void Log(const string msg)
  {
   CAssert::Log(msg);
  }

void AssertTrue(const string test_name, const bool condition)
  {
   CAssert::True(test_name, condition);
  }

void AssertFalse(const string test_name, const bool condition)
  {
   CAssert::False(test_name, condition);
  }

void AssertEqual(const string test_name, const double expected, const double actual, const double epsilon = 0.00001)
  {
   CAssert::Equal(test_name, expected, actual, epsilon);
  }

void AssertDoubleEqual(const string test_name, const double expected, const double actual, const double epsilon = 0.00001)
  {
   CAssert::DoubleEqual(test_name, expected, actual, epsilon);
  }

void AssertIntEqual(const string test_name, const int expected, const int actual)
  {
   CAssert::IntEqual(test_name, expected, actual);
  }

void AssertLongEqual(const string test_name, const long expected, const long actual)
  {
   CAssert::LongEqual(test_name, expected, actual);
  }

void AssertUintEqual(const string test_name, const uint expected, const uint actual)
  {
   CAssert::UintEqual(test_name, expected, actual);
  }

void AssertUlongEqual(const string test_name, const ulong expected, const ulong actual)
  {
   CAssert::UlongEqual(test_name, expected, actual);
  }

void AssertStringEqual(const string test_name, const string expected, const string actual)
  {
   CAssert::StringEqual(test_name, expected, actual);
  }

#endif
