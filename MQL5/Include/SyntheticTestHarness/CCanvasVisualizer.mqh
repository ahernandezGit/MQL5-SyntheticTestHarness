//+------------------------------------------------------------------+
//|                                           CCanvasVisualizer.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 1 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CCANVAS_VISUALIZER_MQH
#define SYNTHETIC_TEST_HARNESS_CCANVAS_VISUALIZER_MQH

#include <Canvas\Canvas.mqh>
#include "MockTick.mqh"
#include "ErrorCodes.mqh"

//+------------------------------------------------------------------+
//| OHLC: represents a consolidated candle structure for rendering.   |
//+------------------------------------------------------------------+
struct OHLC
  {
   double            open;
   double            high;
   double            low;
   double            close;
   bool              is_bullish;
   bool              has_error;
  };

//+------------------------------------------------------------------+
//| LayoutMetrics: holds pixel dimensions and bounds for rendering.   |
//+------------------------------------------------------------------+
struct LayoutMetrics
  {
   int               canvas_w;      // Total canvas width (pixels)
   int               canvas_h;      // Total canvas height (pixels)
   int               draw_x;        // Left edge of the drawing area
   int               draw_y;        // Top edge of the drawing area
   int               draw_w;        // Drawing area width
   int               draw_h;        // Drawing area height
   int               bar_width;     // Width of each candle body (pixels)
   int               gap_width;     // Gap between candles (pixels)
   double            price_min;     // Lowest price in the scenario
   double            price_max;     // Highest price in the scenario
   double            price_range;   // price_max - price_min (with padding)
  };

//+------------------------------------------------------------------+
//| CCanvasVisualizer: visual overlay for synthetic scenarios.       |
//+------------------------------------------------------------------+
class CCanvasVisualizer
  {
private:
   CCanvas           m_canvas;
   bool              m_is_created;
   bool              m_original_show;

   //+---------------------------------------------------------------+
   //| CreateOverlay: initializes the canvas overlay over the chart. |
   //+---------------------------------------------------------------+
   bool CreateOverlay(void)
     {
      int width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

      if(!m_canvas.CreateBitmapLabel(0, 0, "STH_Overlay", 0, 0, width, height, COLOR_FORMAT_XRGB_NOALPHA))
        {
         Print("CCanvasVisualizer: Failed to create Canvas.");
         m_is_created = false;
         return(false);
        }

      m_is_created = true;
      m_canvas.Erase(ColorToARGB(clrWhite, 255));

      // Save original show state and temporarily hide the user's candles/grids
      m_original_show = (bool)ChartGetInteger(0, CHART_SHOW);
      ChartSetInteger(0, CHART_SHOW, false);

      return(true);
     }

   //+---------------------------------------------------------------+
   //| BuildOHLC: converts raw MockTicks to consolidated OHLC bars.  |
   //+---------------------------------------------------------------+
   void BuildOHLC(const MockTick &ticks[], OHLC &bars[])
     {
      int count = ArraySize(ticks);
      ArrayResize(bars, count);
      if(count == 0)
         return;

      for(int i = 0; i < count; i++)
        {
         // Open is the bid of the previous tick. For index 0, use own bid.
         bars[i].open = (i == 0) ? ticks[0].bid : ticks[i - 1].bid;
         bars[i].close = ticks[i].bid;

         // High and low encompass the full bid/ask spread and open/close boundaries.
         double high_val = MathMax(ticks[i].bid, ticks[i].ask);
         double low_val  = MathMin(ticks[i].bid, ticks[i].ask);

         bars[i].high = MathMax(high_val, MathMax(bars[i].open, bars[i].close));
         bars[i].low  = MathMin(low_val, MathMin(bars[i].open, bars[i].close));

         bars[i].is_bullish = (bars[i].close >= bars[i].open);
         bars[i].has_error  = IsExecutionError(ticks[i].injected_error);
        }
     }

   //+---------------------------------------------------------------+
   //| ComputeLayout: calculates positioning metrics for elements.   |
   //+---------------------------------------------------------------+
   void ComputeLayout(const OHLC &bars[], LayoutMetrics &m)
     {
      int count = ArraySize(bars);
      m.canvas_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      m.canvas_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

      // Define centered drawing area (70% width, 70% height)
      m.draw_w = (int)(m.canvas_w * 0.70);
      m.draw_x = (int)(m.canvas_w * 0.15);

      m.draw_h = (int)(m.canvas_h * 0.70);
      m.draw_y = (int)(m.canvas_h * 0.15);

      // Find price range min/max
      m.price_min = DBL_MAX;
      m.price_max = -DBL_MAX;

      for(int i = 0; i < count; i++)
        {
         if(bars[i].low < m.price_min)
            m.price_min = bars[i].low;
         if(bars[i].high > m.price_max)
            m.price_max = bars[i].high;
        }

      // Add 10% vertical buffer to prevent crowding near boundaries
      double diff = m.price_max - m.price_min;
      if(diff <= 0.0)
         diff = 0.0001;

      m.price_min -= diff * 0.10;
      m.price_max += diff * 0.10;
      m.price_range = m.price_max - m.price_min;

      // Candle body width and gap sizing
      if(count > 0)
        {
         m.bar_width = m.draw_w / (2 * count - 1);
         if(m.bar_width < 1)
            m.bar_width = 1;
         m.gap_width = m.bar_width;
        }
      else
        {
         m.bar_width = 10;
         m.gap_width = 10;
        }
     }

   //+---------------------------------------------------------------+
   //| PriceToY: scales double prices to chart pixel coordinates.    |
   //+---------------------------------------------------------------+
   int PriceToY(const double price, const LayoutMetrics &m)
     {
      if(m.price_range <= 0.0)
         return(m.draw_y + m.draw_h / 2);
      return(m.draw_y + m.draw_h - (int)(((price - m.price_min) / m.price_range) * m.draw_h));
     }

   //+---------------------------------------------------------------+
   //| DrawCandles: renders the wicks and bodies of the mock candles.|
   //+---------------------------------------------------------------+
   void DrawCandles(const OHLC &bars[], const LayoutMetrics &m)
     {
      int count = ArraySize(bars);
      uint bull_color  = ColorToARGB(clrForestGreen, 255);
      uint bear_color  = ColorToARGB(clrFireBrick, 255);
      uint error_color = ColorToARGB(clrOrange, 255);

      for(int i = 0; i < count; i++)
        {
         int bar_x_center = m.draw_x + i * (m.bar_width + m.gap_width) + m.bar_width / 2;
         int bar_x1 = bar_x_center - m.bar_width / 2;
         int bar_x2 = bar_x1 + m.bar_width - 1;

         int y_open  = PriceToY(bars[i].open, m);
         int y_close = PriceToY(bars[i].close, m);
         int y_high  = PriceToY(bars[i].high, m);
         int y_low   = PriceToY(bars[i].low, m);

         // Color assignment - Option A: highlight whole candle in orange if error injected
         uint candle_color = bars[i].is_bullish ? bull_color : bear_color;
         if(bars[i].has_error)
            candle_color = error_color;

         // Draw shadow line (wick)
         m_canvas.LineVertical(bar_x_center, y_high, y_low, candle_color);

         // Draw candle body
         int body_y1 = MathMin(y_open, y_close);
         int body_y2 = MathMax(y_open, y_close);

         if(body_y1 == body_y2)
            body_y2 = body_y1 + 1; // Guarantee visibility

         m_canvas.FillRectangle(bar_x1, body_y1, bar_x2, body_y2, candle_color);
        }
     }

   //+---------------------------------------------------------------+
   //| DrawPriceAxis: draws gridlines and right-side price values.   |
   //+---------------------------------------------------------------+
   void DrawPriceAxis(const LayoutMetrics &m)
     {
      int axis_x = m.draw_x + m.draw_w;
      uint axis_color = ColorToARGB(clrLightGray, 255);
      uint text_color = ColorToARGB(clrDimGray, 255);
      uint grid_color = ColorToARGB(clrGray, 40); // Soft transparent horizontal grid

      // Vertical axis line
      m_canvas.LineVertical(axis_x, m.draw_y, m.draw_y + m.draw_h, axis_color);

      m_canvas.FontSet("Arial", 11, FW_NORMAL);

      // Render 5 price grid ticks (0%, 25%, 50%, 75%, 100%)
      for(int i = 0; i <= 4; i++)
        {
         double ratio = i / 4.0;
         double price = m.price_min + ratio * m.price_range;
         int y = PriceToY(price, m);

         // Grid line
         m_canvas.LineHorizontal(m.draw_x, axis_x, y, grid_color);

         // Label text
         string label = DoubleToString(price, 5);
         m_canvas.TextOut(axis_x + 8, y - 6, label, text_color);
        }
     }

   //+---------------------------------------------------------------+
   //| DrawTitle: writes main title and scenario summary text.      |
   //+---------------------------------------------------------------+
   void DrawTitle(const MockTick &ticks[], const LayoutMetrics &m)
     {
      int count = ArraySize(ticks);
      if(count == 0)
         return;

      uint title_color = ColorToARGB(clrBlack, 255);
      uint sub_color   = ColorToARGB(clrDimGray, 255);

      // Main title
      m_canvas.FontSet("Arial", 20, FW_BOLD);
      string title = "Synthetic Test Harness - Scenario Preview";
      int title_x = (m.canvas_w - m_canvas.TextWidth(title)) / 2;
      m_canvas.TextOut(title_x, m.draw_y / 3, title, title_color);

      // Subtitle
      m_canvas.FontSet("Arial", 12, FW_NORMAL);
      datetime start_time = ticks[0].time;
      datetime end_time = ticks[count - 1].time;
      string subtitle = StringFormat("%d bars | %s -> %s", count, TimeToString(start_time), TimeToString(end_time));
      int sub_x = (m.canvas_w - m_canvas.TextWidth(subtitle)) / 2;
      m_canvas.TextOut(sub_x, m.draw_y / 3 + 28, subtitle, sub_color);
     }

   //+---------------------------------------------------------------+
   //| DrawCountdown: updates bottom-left countdown label.           |
   //+---------------------------------------------------------------+
   void DrawCountdown(const int seconds_remaining, const LayoutMetrics &m)
     {
      // Erase previous text space
      m_canvas.FillRectangle(0, m.canvas_h - 60, 450, m.canvas_h, ColorToARGB(clrWhite, 255));

      m_canvas.FontSet("Arial", 14, FW_BOLD);
      string text = StringFormat("Restoring chart in: %ds", seconds_remaining);
      m_canvas.TextOut(20, m.canvas_h - 40, text, ColorToARGB(clrDimGray, 255));

      m_canvas.Update();
     }

   //+---------------------------------------------------------------+
   //| DestroyOverlay: removes the canvas and triggers chart redraw. |
   //+---------------------------------------------------------------+
   void DestroyOverlay(void)
     {
      if(m_is_created)
        {
         m_canvas.Destroy();
         m_is_created = false;

         // Restore original chart show state
         ChartSetInteger(0, CHART_SHOW, m_original_show);

         ChartRedraw(0);
        }
     }

public:
   //+---------------------------------------------------------------+
   //| Constructor.                                                  |
   //+---------------------------------------------------------------+
                     CCanvasVisualizer(void)
     {
      m_is_created = false;
     }

   //+---------------------------------------------------------------+
   //| Destructor: ensures overlay is cleaned up on stack release.  |
   //+---------------------------------------------------------------+
                    ~CCanvasVisualizer(void)
     {
      DestroyOverlay();
     }

   //+---------------------------------------------------------------+
   //| ShowScenario: runs the visualizer pipeline and countdown.     |
   //+---------------------------------------------------------------+
   void ShowScenario(const MockTick &ticks[], int countdown_seconds = 5)
     {
      if(ArraySize(ticks) == 0)
         return;

      if(!CreateOverlay())
         return;

      OHLC bars[];
      LayoutMetrics m;

      BuildOHLC(ticks, bars);
      ComputeLayout(bars, m);
      DrawPriceAxis(m);
      DrawCandles(bars, m);
      DrawTitle(ticks, m);

      // Countdown loop
      for(int i = countdown_seconds; i > 0; i--)
        {
         DrawCountdown(i, m);
         Sleep(1000);
        }

      DestroyOverlay();
     }
  };

//+------------------------------------------------------------------+
#endif
