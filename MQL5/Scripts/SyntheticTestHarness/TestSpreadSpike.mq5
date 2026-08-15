//+------------------------------------------------------------------+
//|                                           TestSpreadSpike.mq5     |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#property copyright   "Institutional Architecture in MQL5 Series"
#property version     "1.00"
#property description "Synthetic test: spread spike with TRADE_RETCODE_PRICE_OFF injection"
#property description "Validates the Chaos Engineering Engine against a 5-tick"
#property description "scenario covering normal market, spread spike, and recovery."
#property script_show_inputs

#include <SyntheticTestHarness\CSyntheticEngine.mqh>
#include <SyntheticTestHarness\CArrayProvider.mqh>
#include <SyntheticTestHarness\CCanvasVisualizer.mqh>

//+------------------------------------------------------------------+
//| Assertion counters - global state scoped to this script.          |
//+------------------------------------------------------------------+
int g_tests_passed = 0;
int g_tests_failed = 0;
string g_report_text = "";
const double EPSILON_PRICE = 0.00001;  // 1 point on a 5-digit broker

//+------------------------------------------------------------------+
//| Log: helper to print and update the chart comment                |
//+------------------------------------------------------------------+
void Log(const string msg)
  {
   if(msg != "")
      Print(msg);
   g_report_text += msg + "\n";
   Comment(g_report_text);
  }

//+------------------------------------------------------------------+
//| AssertTrue: self-validating assertion (FIRST principle).          |
//| Prints [PASS] or [FAIL] with the test name and increments the     |
//| appropriate counter. No manual inspection required.               |
//+------------------------------------------------------------------+
void AssertTrue(const string test_name, const bool condition)
  {
   if(condition)
     {
      g_tests_passed++;
      PrintFormat("  [PASS] %s", test_name);
     }
   else
     {
      g_tests_failed++;
      PrintFormat("  [FAIL] %s", test_name);
     }
  }

//+------------------------------------------------------------------+
//| AssertFalse: inverted assertion for negative test cases.          |
//+------------------------------------------------------------------+
void AssertFalse(const string test_name, const bool condition)
  {
   AssertTrue(test_name, !condition);
  }

//+------------------------------------------------------------------+
//| AssertEqual: floating-point equality with epsilon tolerance.      |
//| Uses EPSILON_PRICE to avoid IEEE 754 rounding false negatives.    |
//+------------------------------------------------------------------+
void AssertEqual(const string test_name,
                 const double expected,
                 const double actual)
  {
   bool match = MathAbs(expected - actual) < EPSILON_PRICE;
   if(!match)
      Log(StringFormat("    Expected=%.5f  Actual=%.5f", expected, actual));
   AssertTrue(test_name, match);
  }

//+------------------------------------------------------------------+
//| AssertIntEqual: integer equality assertion.                       |
//+------------------------------------------------------------------+
void AssertIntEqual(const string test_name,
                    const int expected,
                    const int actual)
  {
   bool match = (expected == actual);
   if(!match)
      Log(StringFormat("    Expected=%d  Actual=%d", expected, actual));
   AssertTrue(test_name, match);
  }

//+------------------------------------------------------------------+
//| AssertUintEqual: unsigned integer equality (for retcode checks).  |
//+------------------------------------------------------------------+
void AssertUintEqual(const string test_name,
                     const uint expected,
                     const uint actual)
  {
   bool match = (expected == actual);
   if(!match)
      Log(StringFormat("    Expected=%u  Actual=%u", expected, actual));
   AssertTrue(test_name, match);
  }

//+------------------------------------------------------------------+
//| BuildTestBuyRequest: helper to create a minimal BUY order.        |
//| Avoids repeating the same MqlTradeRequest setup in every test     |
//| (DRY principle).                                                  |
//+------------------------------------------------------------------+
void BuildTestBuyRequest(MqlTradeRequest &request, const double volume)
  {
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type   = ORDER_TYPE_BUY;
   request.volume = volume;
   request.symbol = "SYNTHETIC";
  }

//+------------------------------------------------------------------+
//| BuildSpreadSpikeScenario: creates the 5-tick test dataset.                |
//|                                                                           |
//| Timeline:                                                                 |
//|   Tick 0 - Normal market (spread=20pt, no error)                          |
//|   Tick 1 - Normal market (spread=20pt, no error)                          |
//|   Tick 2 - SPREAD SPIKE (spread=1500pt, TRADE_RETCODE_PRICE_OFF injected) |
//|   Tick 3 - Recovery phase (spread=100pt, no error)                        |
//|   Tick 4 - Full recovery (spread=20pt, no error)                          |
//+------------------------------------------------------------------+
void BuildSpreadSpikeScenario(MockTick &ticks[])
  {
   ArrayResize(ticks, 5);

   //--- Tick 0: Normal market conditions
   ticks[0].time           = D'2026.01.15 10:00:00';
   ticks[0].bid            = 1.10000;
   ticks[0].ask            = 1.10020;
   ticks[0].spread_points  = 20.0;
   ticks[0].injected_error = SYNTH_ERR_NONE;

   //--- Tick 1: Normal market continues
   ticks[1].time           = D'2026.01.15 10:00:01';
   ticks[1].bid            = 1.10005;
   ticks[1].ask            = 1.10025;
   ticks[1].spread_points  = 20.0;
   ticks[1].injected_error = SYNTH_ERR_NONE;

   //--- Tick 2: SPREAD SPIKE + server rejection
   ticks[2].time           = D'2026.01.15 10:00:02';
   ticks[2].bid            = 1.09800;
   ticks[2].ask            = 1.11300;
   ticks[2].spread_points  = 1500.0;
   ticks[2].injected_error = SYNTH_ERR_PRICE_OFF;

   //--- Tick 3: Recovery begins (spread narrowing)
   ticks[3].time           = D'2026.01.15 10:00:03';
   ticks[3].bid            = 1.09950;
   ticks[3].ask            = 1.10050;
   ticks[3].spread_points  = 100.0;
   ticks[3].injected_error = SYNTH_ERR_NONE;

   //--- Tick 4: Full recovery to normal conditions
   ticks[4].time           = D'2026.01.15 10:00:04';
   ticks[4].bid            = 1.10010;
   ticks[4].ask            = 1.10030;
   ticks[4].spread_points  = 20.0;
   ticks[4].injected_error = SYNTH_ERR_NONE;
  }

//+------------------------------------------------------------------+
//| TEST 1: Engine processes every tick from the provider.            |
//| Verifies: CSyntheticEngine + ITickProvider integration.           |
//+------------------------------------------------------------------+
void TestEngineProcessesAllTicks()
  {
   Log("--- Test: Engine Processes All Ticks ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   int processed = 0;
   while(engine.ProcessNextTick())
      processed++;

   AssertIntEqual("Processed tick count matches scenario size", 5, processed);
   AssertIntEqual("Engine internal counter agrees",
                  5, engine.GetTicksProcessed());
  }

//+------------------------------------------------------------------+
//| TEST 2: Spread spike values are correctly surfaced at tick 2.    |
//| Verifies: CSyntheticEngine delegates to current MockTick.        |
//+------------------------------------------------------------------+
void TestSpreadSpikeDetected()
  {
   Log("--- Test: Spread Spike Detected ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   //--- Advance to the spike tick (index 2)
   engine.ProcessNextTick();  // tick 0
   engine.ProcessNextTick();  // tick 1
   engine.ProcessNextTick();  // tick 2 - spike

   AssertEqual("Spread at spike is 1500 points", 1500.0,   engine.GetSpread());
   AssertEqual("Bid reflects flash crash",        1.09800,  engine.GetBid());
   AssertEqual("Ask reflects flash widening",     1.11300,  engine.GetAsk());
  }

//+------------------------------------------------------------------+
//| TEST 3: TryExecuteOrder fails with injected error code.          |
//| Verifies: error injection path in CSyntheticEngine.              |
//+------------------------------------------------------------------+
void TestOrderFailsOnInjectedError()
  {
   Log("--- Test: Order Fails On Injected Error ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   //--- Advance to the spike tick (index 2) which carries TRADE_RETCODE_PRICE_OFF
   engine.ProcessNextTick();  // tick 0
   engine.ProcessNextTick();  // tick 1
   engine.ProcessNextTick();  // tick 2

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.01);

   bool success = engine.TryExecuteOrder(request, result);

   AssertFalse("Order execution fails on spike tick", success);
   AssertUintEqual("Retcode is TRADE_RETCODE_PRICE_OFF",
                   SYNTH_ERR_PRICE_OFF, result.retcode);
  }

//+------------------------------------------------------------------+
//| TEST 4: TryExecuteOrder succeeds on normal ticks.                |
//| Verifies: happy path through CSyntheticEngine.                   |
//+------------------------------------------------------------------+
void TestOrderSucceedsOnNormalTick()
  {
   Log("--- Test: Order Succeeds On Normal Tick ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   //--- Advance to tick 0 (normal conditions)
   engine.ProcessNextTick();

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.01);

   bool success = engine.TryExecuteOrder(request, result);

   AssertTrue("Order execution succeeds on normal tick", success);
   AssertUintEqual("Retcode is TRADE_RETCODE_DONE",
                   TRADE_RETCODE_DONE, result.retcode);
   AssertEqual("Fill volume matches requested volume",
               0.01, result.volume);
   AssertEqual("Fill price is the ask (BUY order)",
               1.10020, result.price);
  }

//+------------------------------------------------------------------+
//| TEST 5: Market recovers after the spike - orders work again.      |
//| Verifies: engine correctly transitions through spike -> recovery. |
//+------------------------------------------------------------------+
void TestMarketRecoveryAfterSpike()
  {
   Log("--- Test: Market Recovery After Spike ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   //--- Advance through all 5 ticks to the final recovery tick
   for(int i = 0; i < 5; i++)
      engine.ProcessNextTick();

   AssertEqual("Spread returns to normal after recovery",
               20.0, engine.GetSpread());

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.01);

   bool success = engine.TryExecuteOrder(request, result);

   AssertTrue("Order succeeds after full recovery", success);
   AssertUintEqual("Retcode is TRADE_RETCODE_DONE after recovery",
                   TRADE_RETCODE_DONE, result.retcode);
  }

//+------------------------------------------------------------------+
//| TEST 6: TryExecuteOrder fails before any tick is loaded.         |
//| Verifies: guard clause for uninitialized engine state.           |
//+------------------------------------------------------------------+
void TestOrderFailsBeforeFirstTick()
  {
   Log("--- Test: Order Fails Before First Tick ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider   provider(ticks);
   CSyntheticEngine engine(&provider);

   //--- Attempt execution WITHOUT calling ProcessNextTick()
   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.01);

   bool success = engine.TryExecuteOrder(request, result);

   AssertFalse("Order fails when no tick is loaded", success);
   AssertTrue("Retcode is not TRADE_RETCODE_DONE before first tick",
              result.retcode != TRADE_RETCODE_DONE);
  }

//+------------------------------------------------------------------+
//| TEST 7: CArrayProvider Reset() allows scenario re-execution.     |
//| Verifies: provider rewind for repeated test runs.                |
//+------------------------------------------------------------------+
void TestProviderResetReplaysTicks()
  {
   Log("--- Test: Provider Reset Replays Ticks ---");

   MockTick ticks[];
   BuildSpreadSpikeScenario(ticks);

   CArrayProvider provider(ticks);

   //--- First pass: consume all ticks
   MockTick temp;
   int first_pass_count = 0;
   while(provider.HasNext())
     {
      provider.GetNextTick(temp);
      first_pass_count++;
     }

   AssertFalse("Provider is exhausted after first pass",
               provider.HasNext());

   //--- Reset and replay
   provider.Reset();

   int second_pass_count = 0;
   while(provider.HasNext())
     {
      provider.GetNextTick(temp);
      second_pass_count++;
     }

   AssertIntEqual("Second pass yields same tick count",
                  first_pass_count, second_pass_count);
  }

//+------------------------------------------------------------------+
//| OnStart: test runner entry point.                                 |
//| Executes all independent test functions and prints a summary.     |
//+------------------------------------------------------------------+
void OnStart()
  {
   Log("==========================================================");
   Log("  SYNTHETIC TEST HARNESS - Spread Spike Scenario");
   Log("  Institutional Architecture in MQL5 - Part 1");
   Log("==========================================================");
   Log("");

   //--- Run each test independently (FIRST: Independent)
   TestEngineProcessesAllTicks();
   Log("");
   TestSpreadSpikeDetected();
   Log("");
   TestOrderFailsOnInjectedError();
   Log("");
   TestOrderSucceedsOnNormalTick();
   Log("");
   TestMarketRecoveryAfterSpike();
   Log("");
   TestOrderFailsBeforeFirstTick();
   Log("");
   TestProviderResetReplaysTicks();

   //--- Summary (FIRST: Self-validating)
   Log("");
   Log("==========================================================");
   
   string summary = StringFormat("  RESULTS: %d passed, %d failed, %d total",
                                 g_tests_passed, g_tests_failed,
                                 g_tests_passed + g_tests_failed);
   Log(summary);

   string status;
   uint icon;
   if(g_tests_failed == 0)
     {
      status = "  STATUS: ALL TESTS PASSED";
      icon = MB_ICONINFORMATION;
     }
   else
     {
      status = "  STATUS: SOME TESTS FAILED";
      icon = MB_ICONERROR;
     }
   Log(status);
   Log("==========================================================");

   // Show MessageBox
   MessageBox(summary + "\n\n" + status, "Test Results", icon | MB_OK);
   
   //--- Visual overlay: render the scenario candles on the chart
   MockTick visual_ticks[];
   BuildSpreadSpikeScenario(visual_ticks);
   CCanvasVisualizer visualizer;
   visualizer.ShowScenario(visual_ticks, 5);

   // Clear comment after closing MessageBox
   Comment("");
  }
//+------------------------------------------------------------------+
