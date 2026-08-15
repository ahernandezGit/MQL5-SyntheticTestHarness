//+------------------------------------------------------------------+
//|                                                   ErrorCodes.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_ERROR_CODES_MQH
#define SYNTHETIC_TEST_HARNESS_ERROR_CODES_MQH

//+------------------------------------------------------------------+
//| Named error constants for synthetic test scenarios.               |
//|                                                                   |
//| ADR-001: MQL5 has no exceptions (try/catch/throw). We use named   |
//| constants instead of raw integers so error-handling paths are     |
//| self-documenting and grep-searchable.                             |
//+------------------------------------------------------------------+
#define SYNTH_ERR_NONE           0      // No error - execution succeeded
#define SYNTH_ERR_REQUOTE        10004  // TRADE_RETCODE_REQUOTE
#define SYNTH_ERR_REJECT         10006  // TRADE_RETCODE_REJECT
#define SYNTH_ERR_TIMEOUT        10012  // TRADE_RETCODE_TIMEOUT
#define SYNTH_ERR_PRICE_OFF      10021  // TRADE_RETCODE_PRICE_OFF

//+------------------------------------------------------------------+
//| IsExecutionError: guard function replacing raw int comparisons.   |
//| Callers use this instead of checking error codes against zero     |
//| directly, centralizing the "what counts as failure" logic.        |
//+------------------------------------------------------------------+
bool IsExecutionError(const int error_code)
  {
   return(error_code != SYNTH_ERR_NONE);
  }

//+------------------------------------------------------------------+
#endif
