//+------------------------------------------------------------------+
//|                                     TestBehaviorInjection.mq5     |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#property copyright   "Institutional Architecture in MQL5 Series"
#property version     "1.00"
#property description "Synthetic test: Dynamic Behavior Injection for Chaos Engineering"
#property description "Validates function pointer delegates, stateful requotes, and on-the-fly fault switching."
#property script_show_inputs
#property strict

#include <SyntheticTestHarness\CSyntheticEngine.mqh>
#include <SyntheticTestHarness\BehaviorLibrary.mqh>
#include <SyntheticTestHarness\ErrorCodes.mqh>
#include <SyntheticTestHarness\CAssert.mqh>

//+------------------------------------------------------------------+
//| Helper: Build minimal BUY trade request                           |
//+------------------------------------------------------------------+
void BuildTestBuyRequest(MqlTradeRequest &request, const double volume = 0.10)
  {
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type   = ORDER_TYPE_BUY;
   request.volume = volume;
   request.price  = 1.10000;
   request.symbol = "EURUSD";
  }

//+------------------------------------------------------------------+
//| Custom Behavior Mock Functions for Price & DOM Testing           |
//+------------------------------------------------------------------+
double CustomSpreadSpikeBehavior(void)
  {
   return(250.0); // Custom 250 point spread injection
  }

bool CustomMarketBookBehavior(const string symbol, MqlBookInfo &book[])
  {
   ArrayResize(book, 2);
   book[0].type   = BOOK_TYPE_BUY;
   book[0].price  = 1.10000;
   book[0].volume = 100;

   book[1].type   = BOOK_TYPE_SELL;
   book[1].price  = 1.10025;
   book[1].volume = 150;
   return(true);
  }

//+------------------------------------------------------------------+
//| TEST 1: Default Behavior Without Injection or Ticks              |
//| Pattern: Arrange -> Act -> Assert                                |
//+------------------------------------------------------------------+
void TestDefaultEnvironmentState(void)
  {
   Log("--- Test 1: Default Environment State ---");

   // [Arrange]
   CSyntheticEngine engine; // Standalone engine without tick provider

   // [Act & Assert]
   AssertDoubleEqual("Default Bid price is 1.10000", 1.10000, engine.GetBid());
   AssertDoubleEqual("Default Ask price is 1.10020", 1.10020, engine.GetAsk());
   AssertDoubleEqual("Default Spread is 20 points",  20.0,    engine.GetSpread());

   MqlBookInfo book[];
   AssertFalse("Default MarketBookGet returns false", engine.MarketBookGet("EURUSD", book));
  }

//+------------------------------------------------------------------+
//| TEST 2: Stateful Requote Behavior Cycle (Behavior_RequoteTwice)  |
//| Pattern: Arrange -> Act -> Assert                                |
//| Verifies: Call 1 & 2 return REQUOTE, Call 3 returns DONE.        |
//+------------------------------------------------------------------+
void TestStatefulRequoteBehavior(void)
  {
   Log("--- Test 2: Stateful Requote Twice Behavior ---");

   // [Arrange]
   CSyntheticEngine engine;
   engine.MockOrderSend(Behavior_RequoteTwice); // Inject stateful behavior

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 1.0);

   // [Act 1: First Attempt]
   bool success1 = engine.OrderSend(request, result);

   // [Assert 1]
   AssertFalse("Attempt 1 fails due to requote", success1);
   AssertUintEqual("Attempt 1 retcode is TRADE_RETCODE_REQUOTE",
                   SYNTH_ERR_REQUOTE, result.retcode);

   // [Act 2: Second Attempt]
   bool success2 = engine.OrderSend(request, result);

   // [Assert 2]
   AssertFalse("Attempt 2 fails due to requote", success2);
   AssertUintEqual("Attempt 2 retcode is TRADE_RETCODE_REQUOTE",
                   SYNTH_ERR_REQUOTE, result.retcode);

   // [Act 3: Third Attempt]
   bool success3 = engine.OrderSend(request, result);

   // [Assert 3]
   AssertTrue("Attempt 3 succeeds after retry", success3);
   AssertUintEqual("Attempt 3 retcode is TRADE_RETCODE_DONE",
                   TRADE_RETCODE_DONE, result.retcode);
   AssertDoubleEqual("Filled volume matches request", 1.0, result.volume);
  }

//+------------------------------------------------------------------+
//| TEST 3: On-the-fly Hot Swapping of Injected Behaviors            |
//| Pattern: Arrange -> Act -> Assert                                |
//| Verifies: Switching from Requote to Fatal Disconnect mid-flight. |
//+------------------------------------------------------------------+
void TestHotSwappingBehavior(void)
  {
   Log("--- Test 3: Hot-Swapping Behavior to Fatal Disconnect ---");

   // [Arrange]
   CSyntheticEngine engine;
   engine.MockOrderSend(Behavior_RequoteTwice);

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.5);

   // Consume one requote
   engine.OrderSend(request, result);
   AssertUintEqual("Initial behavior is REQUOTE", SYNTH_ERR_REQUOTE, result.retcode);

   // [Act: Hot-Swap Behavior Dynamically]
   engine.MockOrderSend(Behavior_FatalDisconnect);

   bool success = engine.OrderSend(request, result);

   // [Assert]
   AssertFalse("Fatal disconnect causes immediate failure", success);
   AssertUintEqual("Retcode reflects TRADE_RETCODE_CONNECTION",
                   TRADE_RETCODE_CONNECTION, result.retcode);
  }

//+------------------------------------------------------------------+
//| TEST 4: Behavior Resetting (Reversion to Default Engine State)   |
//| Pattern: Arrange -> Act -> Assert                                |
//+------------------------------------------------------------------+
void TestBehaviorReset(void)
  {
   Log("--- Test 4: Resetting Injected Behaviors ---");

   // [Arrange]
   CSyntheticEngine engine;
   engine.MockOrderSend(Behavior_FatalDisconnect);

   MqlTradeRequest request;
   MqlTradeResult  result;
   BuildTestBuyRequest(request, 0.1);

   // Verify injected error is active
   engine.OrderSend(request, result);
   AssertUintEqual("Injected disconnect is active", TRADE_RETCODE_CONNECTION, result.retcode);

   // [Act: Reset Behavior]
   engine.ResetOrderSend();

   // [Assert: Engine reverts to default tickless guard]
   bool success = engine.OrderSend(request, result);
   AssertFalse("Default without loaded tick returns SYNTH_ERR_PRICE_OFF", success);
   AssertUintEqual("Retcode is SYNTH_ERR_PRICE_OFF", SYNTH_ERR_PRICE_OFF, result.retcode);
  }

//+------------------------------------------------------------------+
//| TEST 5: Custom Price & DOM Behavior Injection                    |
//| Pattern: Arrange -> Act -> Assert                                |
//+------------------------------------------------------------------+
void TestCustomPriceAndDOMInjection(void)
  {
   Log("--- Test 5: Custom Price & DOM Behavior Injection ---");

   // [Arrange]
   CSyntheticEngine engine;
   engine.MockGetSpread(CustomSpreadSpikeBehavior);
   engine.MockMarketBookGet(CustomMarketBookBehavior);

   // [Act & Assert: Price Behavior]
   AssertDoubleEqual("Custom injected spread is 250 points", 250.0, engine.GetSpread());

   // [Act & Assert: DOM Behavior]
   MqlBookInfo book[];
   bool has_book = engine.MarketBookGet("EURUSD", book);
   AssertTrue("Custom MarketBookGet succeeds", has_book);
   AssertIntEqual("Custom book has 2 entries", 2, ArraySize(book));
   AssertDoubleEqual("Book best bid is 1.10000", 1.10000, book[0].price);
   AssertDoubleEqual("Book best ask is 1.10025", 1.10025, book[1].price);

   // [Reset]
   engine.ResetAllBehaviors();
   AssertDoubleEqual("Reset restores default spread of 20 points", 20.0, engine.GetSpread());
  }

//+------------------------------------------------------------------+
//| Script Program Start Function                                    |
//+------------------------------------------------------------------+
void OnStart(void)
  {
   CAssert::Reset();

   Log("==========================================================");
   Log("  SYNTHETIC TEST HARNESS - Behavior Injection Runner      ");
   Log("  Institutional Architecture in MQL5 - Part 1 Upgrade     ");
   Log("==========================================================");
   Log("");

   // Execute test suite
   TestDefaultEnvironmentState();
   Log("");
   TestStatefulRequoteBehavior();
   Log("");
   TestHotSwappingBehavior();
   Log("");
   TestBehaviorReset();
   Log("");
   TestCustomPriceAndDOMInjection();
   Log("");

   //--- Test Summary Output
   CAssert::Summary("Behavior Injection Test Suite", true);
  }
//+------------------------------------------------------------------+
