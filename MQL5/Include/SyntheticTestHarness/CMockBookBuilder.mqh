//+------------------------------------------------------------------+
//|                                        CMockBookBuilder.mqh       |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 3 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_CMOCK_BOOK_BUILDER_MQH
#define SYNTHETIC_TEST_HARNESS_CMOCK_BOOK_BUILDER_MQH

//+------------------------------------------------------------------+
//| CMockBookBuilder: Deterministic Level 2 DOM Constructor.         |
//|                                                                  |
//| Single Responsibility: Build valid, reproducible MqlBookInfo[]   |
//| snapshots for TDD without broker subscriptions or historical L2  |
//| data. Designed to plug into CSyntheticEngine via                 |
//| TMarketBookGetBehavior delegate injection.                       |
//+------------------------------------------------------------------+
class CMockBookBuilder
  {
private:
   MqlBookInfo         m_book[];
   int                 m_count;
   int                 m_max_levels;

   double              m_tick_size;
   double              m_digits_factor;

   void                PushLevel(const ENUM_BOOK_TYPE side,
                                  const double price,
                                  const long volume_real,
                                  const long volume = 0);
   void                SortAndDeduplicate(void);
   void                EnsureCapacity(void);

public:
   //+---------------------------------------------------------------+
   //| Constructor & Destructor                                      |
   //+---------------------------------------------------------------+
   CMockBookBuilder(void);
   ~CMockBookBuilder(void);

   void   Clear(void);
   void   SetTickSize(const double ts, const int digits = 5);

   // Raw level injection
   void   AddBid(const double price, const double volume_lots);
   void   AddAsk(const double price, const double volume_lots);

   // Named canonical scenarios (Etapa 1 do plano)
   void   BuildBalancedBook(const double mid_price,
                             const int levels_per_side = 10,
                             const double base_volume_lots = 1.0,
                             const double step_ticks = 1,
                             const double volume_decay = 0.9);

   void   BuildThinBook(const double mid_price,
                         const int levels_per_side = 3,
                         const double base_volume_lots = 0.1,
                         const double step_ticks = 5,
                         const double volume_decay = 0.8);

   void   BuildHollowBook(const double mid_price,
                           const int levels_per_side = 10,
                           const double surface_volume_lots = 0.5,
                           const double step_ticks = 1,
                           const double hollow_factor = 0.1);

   void   BuildWallOnBid(const double mid_price,
                          const int levels_per_side = 10,
                          const double base_volume_lots = 1.0,
                          const int wall_level_index = 2,
                          const double wall_volume_lots = 25.0,
                          const double step_ticks = 1);

   void   BuildWallOnAsk(const double mid_price,
                          const int levels_per_side = 10,
                          const double base_volume_lots = 1.0,
                          const int wall_level_index = 2,
                          const double wall_volume_lots = 25.0,
                          const double step_ticks = 1);

   void   BuildAsymmetricBook(const double mid_price,
                               const int levels_per_side = 10,
                               const double bid_base_volume = 2.0,
                               const double ask_base_volume = 0.5,
                               const double step_ticks = 1,
                               const double volume_decay = 0.9);

   void   BuildLiquidityVacuum(const double mid_price,
                                const int levels_per_side = 10,
                                const double surface_volume = 0.2,
                                const double vacuum_start_ticks = 3,
                                const int vacuum_width_levels = 5,
                                const double deep_volume = 5.0,
                                const double step_ticks = 1);

   // Exporters
   bool   ToArray(MqlBookInfo &out_book[]);
   int    LevelsTotal(void) const { return(m_count); }

   // Diagnostics / Test Helpers
   double GetBestBid(void) const;
   double GetBestAsk(void) const;
   double SumVolumeSide(const ENUM_BOOK_TYPE side) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMockBookBuilder::CMockBookBuilder(void) :
   m_count(0),
   m_max_levels(1024),
   m_tick_size(0.00001),
   m_digits_factor(100000.0)
  {
   ArrayResize(m_book, m_max_levels);
  }

CMockBookBuilder::~CMockBookBuilder(void)
  {
   ArrayFree(m_book);
  }

void CMockBookBuilder::Clear(void)
  {
   ArrayFree(m_book);
   m_max_levels = 1024;
   ArrayResize(m_book, m_max_levels);
   m_count = 0;
  }

void CMockBookBuilder::SetTickSize(const double ts, const int digits)
  {
   m_tick_size = (ts > 0) ? ts : m_tick_size;
   double df = 1.0;
   for(int i = 0; i < digits; i++) df *= 10.0;
   m_digits_factor = df;
  }

void CMockBookBuilder::EnsureCapacity(void)
  {
   if(m_count < m_max_levels - 1) return;
   m_max_levels *= 2;
   ArrayResize(m_book, m_max_levels);
  }

void CMockBookBuilder::PushLevel(const ENUM_BOOK_TYPE side,
                                  const double price,
                                  const long volume_real,
                                  const long volume)
  {
   EnsureCapacity();
   ZeroMemory(m_book[m_count]);
   m_book[m_count].type        = side;
   m_book[m_count].price       = NormalizeDouble(price, (int)MathLog10(m_digits_factor));
   m_book[m_count].volume_real = (double)volume_real;
   m_book[m_count].volume      = (volume > 0) ? volume : volume_real;
   m_count++;
  }

void CMockBookBuilder::AddBid(const double price, const double volume_lots)
  {
   long vol = (long)MathMax(1, MathRound(volume_lots * m_digits_factor));
   PushLevel(BOOK_TYPE_BUY, price, vol);
  }

void CMockBookBuilder::AddAsk(const double price, const double volume_lots)
  {
   long vol = (long)MathMax(1, MathRound(volume_lots * m_digits_factor));
   PushLevel(BOOK_TYPE_SELL, price, vol);
  }

void CMockBookBuilder::SortAndDeduplicate(void)
  {
   if(m_count <= 1) return;

   int n = m_count;
   for(int i = 0; i < n - 1; i++)
     {
      for(int j = i + 1; j < n; j++)
        {
         bool need_swap = false;
         if(m_book[i].type != m_book[j].type)
           need_swap = (m_book[i].type > m_book[j].type);
         else if(m_book[i].type == BOOK_TYPE_BUY)
           need_swap = (m_book[i].price < m_book[j].price);
         else
           need_swap = (m_book[i].price > m_book[j].price);

         if(need_swap)
           {
            MqlBookInfo tmp = m_book[i];
            m_book[i] = m_book[j];
            m_book[j] = tmp;
           }
        }
     }

   int write = 0;
   for(int read = 0; read < n; read++)
     {
      if(write > 0 &&
         m_book[write - 1].type  == m_book[read].type &&
         MathAbs(m_book[write - 1].price - m_book[read].price) < m_tick_size * 0.5)
        {
         m_book[write - 1].volume_real += m_book[read].volume_real;
         m_book[write - 1].volume      += m_book[read].volume;
        }
      else
        {
         if(read != write) m_book[write] = m_book[read];
         write++;
        }
     }
   m_count = write;
  }

void CMockBookBuilder::BuildBalancedBook(const double mid_price,
                                           const int levels_per_side,
                                           const double base_volume_lots,
                                           const double step_ticks,
                                           const double volume_decay)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   double bid_vol = base_volume_lots;
   double ask_vol = base_volume_lots;

   for(int i = 0; i < levels_per_side; i++)
     {
      AddBid(bid_price, bid_vol);
      AddAsk(ask_price, ask_vol);
      bid_price -= step;
      ask_price += step;
      bid_vol *= volume_decay;
      ask_vol *= volume_decay;
     }

   SortAndDeduplicate();
  }

void CMockBookBuilder::BuildThinBook(const double mid_price,
                                      const int levels_per_side,
                                      const double base_volume_lots,
                                      const double step_ticks,
                                      const double volume_decay)
  {
   BuildBalancedBook(mid_price, levels_per_side, base_volume_lots, step_ticks, volume_decay);
  }

void CMockBookBuilder::BuildHollowBook(const double mid_price,
                                        const int levels_per_side,
                                        const double surface_volume_lots,
                                        const double step_ticks,
                                        const double hollow_factor)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   double v;
   for(int i = 0; i < levels_per_side; i++)
     {
      if(i == 0)
         v = surface_volume_lots;
      else
         v = surface_volume_lots * hollow_factor;

      AddBid(bid_price, v);
      AddAsk(ask_price, v);
      bid_price -= step;
      ask_price += step;
     }

   SortAndDeduplicate();
  }

void CMockBookBuilder::BuildWallOnBid(const double mid_price,
                                       const int levels_per_side,
                                       const double base_volume_lots,
                                       const int wall_level_index,
                                       const double wall_volume_lots,
                                       const double step_ticks)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   double bid_vol = base_volume_lots;
   double ask_vol = base_volume_lots;

   for(int i = 0; i < levels_per_side; i++)
     {
      double bv = (i == wall_level_index) ? wall_volume_lots : bid_vol;
      AddBid(bid_price, bv);
      AddAsk(ask_price, ask_vol);
      bid_price -= step;
      ask_price += step;
      bid_vol *= 0.9;
      ask_vol *= 0.9;
     }

   SortAndDeduplicate();
  }

void CMockBookBuilder::BuildWallOnAsk(const double mid_price,
                                       const int levels_per_side,
                                       const double base_volume_lots,
                                       const int wall_level_index,
                                       const double wall_volume_lots,
                                       const double step_ticks)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   double bid_vol = base_volume_lots;
   double ask_vol = base_volume_lots;

   for(int i = 0; i < levels_per_side; i++)
     {
      double av = (i == wall_level_index) ? wall_volume_lots : ask_vol;
      AddBid(bid_price, bid_vol);
      AddAsk(ask_price, av);
      bid_price -= step;
      ask_price += step;
      bid_vol *= 0.9;
      ask_vol *= 0.9;
     }

   SortAndDeduplicate();
  }

void CMockBookBuilder::BuildAsymmetricBook(const double mid_price,
                                             const int levels_per_side,
                                             const double bid_base_volume,
                                             const double ask_base_volume,
                                             const double step_ticks,
                                             const double volume_decay)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   double bid_vol = bid_base_volume;
   double ask_vol = ask_base_volume;

   for(int i = 0; i < levels_per_side; i++)
     {
      AddBid(bid_price, bid_vol);
      AddAsk(ask_price, ask_vol);
      bid_price -= step;
      ask_price += step;
      bid_vol *= volume_decay;
      ask_vol *= volume_decay;
     }

   SortAndDeduplicate();
  }

void CMockBookBuilder::BuildLiquidityVacuum(const double mid_price,
                                              const int levels_per_side,
                                              const double surface_volume,
                                              const double vacuum_start_ticks,
                                              const int vacuum_width_levels,
                                              const double deep_volume,
                                              const double step_ticks)
  {
   Clear();
   double step = m_tick_size * step_ticks;
   double half_spread = step;

   double bid_price = mid_price - half_spread;
   double ask_price = mid_price + half_spread;

   int vac_start = (int)MathMax(1, MathFloor(vacuum_start_ticks / MathMax(1, step_ticks)));

   for(int i = 0; i < levels_per_side; i++)
     {
      bool in_vacuum = (i >= vac_start && i < vac_start + vacuum_width_levels);
      double v;
      if(i == 0)
         v = surface_volume;
      else if(in_vacuum)
         v = surface_volume * 0.05;
      else
         v = deep_volume;

      AddBid(bid_price, v);
      AddAsk(ask_price, v);
      bid_price -= step;
      ask_price += step;
     }

   SortAndDeduplicate();
  }

bool CMockBookBuilder::ToArray(MqlBookInfo &out_book[])
  {
   SortAndDeduplicate();
   ArrayFree(out_book);
   if(m_count <= 0) return(false);

   ArrayResize(out_book, m_count);
   for(int i = 0; i < m_count; i++)
      out_book[i] = m_book[i];

   return(true);
  }

double CMockBookBuilder::GetBestBid(void) const
  {
   double best = 0.0;
   for(int i = 0; i < m_count; i++)
     {
      if(m_book[i].type == BOOK_TYPE_BUY)
        {
         if(best == 0.0 || m_book[i].price > best)
            best = m_book[i].price;
        }
     }
   return(best);
  }

double CMockBookBuilder::GetBestAsk(void) const
  {
   double best = 0.0;
   for(int i = 0; i < m_count; i++)
     {
      if(m_book[i].type == BOOK_TYPE_SELL)
        {
         if(best == 0.0 || m_book[i].price < best)
            best = m_book[i].price;
        }
     }
   return(best);
  }

double CMockBookBuilder::SumVolumeSide(const ENUM_BOOK_TYPE side) const
  {
   double sum = 0.0;
   for(int i = 0; i < m_count; i++)
     {
      if(m_book[i].type == side)
         sum += (double)m_book[i].volume_real / m_digits_factor;
     }
   return(sum);
  }

#endif
//+------------------------------------------------------------------+
