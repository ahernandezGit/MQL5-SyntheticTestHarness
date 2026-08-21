//+------------------------------------------------------------------+
//|                                           MockPositionStore.mqh  |
//|                          Synthetic Test Harness for MetaTrader 5  |
//|              Institutional Architecture in MQL5 - Part 2 Series   |
//+------------------------------------------------------------------+
#ifndef SYNTHETIC_TEST_HARNESS_MOCK_POSITION_STORE_MQH
#define SYNTHETIC_TEST_HARNESS_MOCK_POSITION_STORE_MQH

//+------------------------------------------------------------------+
//| Mock data structure for an open position                         |
//+------------------------------------------------------------------+
struct SMockPosition
  {
   ulong             ticket;
   string            symbol;
   long              magic;
   ENUM_POSITION_TYPE type;
   double            volume;
   double            price_open;
   double            price_current;
   double            sl;
   double            tp;
   double            profit;
   double            swap;
   datetime          time_open;
   string            comment;
  };

//+------------------------------------------------------------------+
//| Mock data structure for a closed deal (history)                  |
//+------------------------------------------------------------------+
struct SMockDeal
  {
   ulong             ticket;
   ulong             order;
   string            symbol;
   long              magic;
   ENUM_DEAL_TYPE    type;
   ENUM_DEAL_ENTRY   entry;
   double            volume;
   double            price;
   double            profit;
   double            commission;
   double            swap;
   datetime          time;
   string            comment;
  };

//+------------------------------------------------------------------+
//| Mock data structure for a pending order                          |
//+------------------------------------------------------------------+
struct SMockPendingOrder
  {
   ulong             ticket;
   string            symbol;
   long              magic;
   ENUM_ORDER_TYPE   type;
   ENUM_ORDER_STATE  state;
   double            volume_initial;
   double            volume_current;
   double            price_open;
   double            sl;
   double            tp;
   datetime          time_setup;
   string            comment;
  };

//+------------------------------------------------------------------+
//| CMockPositionStore: In-memory store for synthetic account state  |
//|                                                                  |
//| Single Responsibility: Decoupled container managing synthetic    |
//| positions, orders, and historical deals for unit testing without |
//| coupling to terminal state or CSyntheticEngine tick simulation.  |
//+------------------------------------------------------------------+
class CMockPositionStore
  {
private:
   SMockPosition     m_positions[];
   SMockDeal         m_deals[];
   SMockPendingOrder m_orders[];

   int               m_selected_position_idx;
   ulong             m_selected_deal_ticket;
   ulong             m_selected_order_ticket;
   bool              m_history_selected;
   datetime          m_history_from;
   datetime          m_history_to;

public:
   //+---------------------------------------------------------------+
   //| Constructor & Destructor                                      |
   //+---------------------------------------------------------------+
   CMockPositionStore(void)
     {
      m_selected_position_idx = -1;
      m_selected_deal_ticket  = 0;
      m_selected_order_ticket = 0;
      m_history_selected      = false;
      m_history_from          = 0;
      m_history_to            = 0;
      Clear();
     }

   ~CMockPositionStore(void)
     {
      Clear();
     }

   //+---------------------------------------------------------------+
   //| Clear all mock storage data                                   |
   //+---------------------------------------------------------------+
   void Clear(void)
     {
      ArrayFree(m_positions);
      ArrayFree(m_deals);
      ArrayFree(m_orders);
      m_selected_position_idx = -1;
      m_selected_deal_ticket  = 0;
      m_selected_order_ticket = 0;
      m_history_selected      = false;
     }

   //+---------------------------------------------------------------+
   //| Position Setup Helpers (Used by Unit Tests)                   |
   //+---------------------------------------------------------------+
   void AddPosition(const SMockPosition &pos)
     {
      int size = ArraySize(m_positions);
      ArrayResize(m_positions, size + 1);
      m_positions[size] = pos;
     }

   bool RemovePosition(const ulong ticket)
     {
      int size = ArraySize(m_positions);
      for(int i = 0; i < size; i++)
        {
         if(m_positions[i].ticket == ticket)
           {
            for(int j = i; j < size - 1; j++)
               m_positions[j] = m_positions[j + 1];
            ArrayResize(m_positions, size - 1);
            if(m_selected_position_idx >= ArraySize(m_positions))
               m_selected_position_idx = -1;
            return(true);
           }
        }
      return(false);
     }

   //+---------------------------------------------------------------+
   //| Position Queries (Mirrors MT5 API)                            |
   //+---------------------------------------------------------------+
   int PositionsTotal(void) const
     {
      return(ArraySize(m_positions));
     }

   string PositionGetSymbol(const int index)
     {
      if(index < 0 || index >= ArraySize(m_positions))
        {
         m_selected_position_idx = -1;
         return("");
        }
      m_selected_position_idx = index;
      return(m_positions[index].symbol);
     }

   long PositionGetInteger(const ENUM_POSITION_PROPERTY_INTEGER property) const
     {
      if(m_selected_position_idx < 0 || m_selected_position_idx >= ArraySize(m_positions))
         return(0);

      switch(property)
        {
         case POSITION_TICKET:     return((long)m_positions[m_selected_position_idx].ticket);
         case POSITION_MAGIC:      return(m_positions[m_selected_position_idx].magic);
         case POSITION_TYPE:       return((long)m_positions[m_selected_position_idx].type);
         case POSITION_TIME:       return((long)m_positions[m_selected_position_idx].time_open);
         default:                  return(0);
        }
     }

   double PositionGetDouble(const ENUM_POSITION_PROPERTY_DOUBLE property) const
     {
      if(m_selected_position_idx < 0 || m_selected_position_idx >= ArraySize(m_positions))
         return(0.0);

      switch(property)
        {
         case POSITION_VOLUME:        return(m_positions[m_selected_position_idx].volume);
         case POSITION_PRICE_OPEN:    return(m_positions[m_selected_position_idx].price_open);
         case POSITION_PRICE_CURRENT: return(m_positions[m_selected_position_idx].price_current);
         case POSITION_SL:            return(m_positions[m_selected_position_idx].sl);
         case POSITION_TP:            return(m_positions[m_selected_position_idx].tp);
         case POSITION_PROFIT:        return(m_positions[m_selected_position_idx].profit);
         case POSITION_SWAP:          return(m_positions[m_selected_position_idx].swap);
         default:                     return(0.0);
        }
     }

   //+---------------------------------------------------------------+
   //| Deal / History Setup Helpers (Used by Unit Tests)             |
   //+---------------------------------------------------------------+
   void AddDeal(const SMockDeal &deal)
     {
      int size = ArraySize(m_deals);
      ArrayResize(m_deals, size + 1);
      m_deals[size] = deal;
     }

   bool HistorySelect(const datetime from_date, const datetime to_date)
     {
      m_history_selected = true;
      m_history_from     = from_date;
      m_history_to       = to_date;
      return(true);
     }

   int HistoryDealsTotal(void) const
     {
      if(!m_history_selected)
         return(0);

      int count = 0;
      int size = ArraySize(m_deals);
      for(int i = 0; i < size; i++)
        {
         if(m_deals[i].time >= m_history_from && m_deals[i].time <= m_history_to)
            count++;
        }
      return(count);
     }

   ulong HistoryDealGetTicket(const int index)
     {
      if(!m_history_selected)
         return(0);

      int count = 0;
      int size = ArraySize(m_deals);
      for(int i = 0; i < size; i++)
        {
         if(m_deals[i].time >= m_history_from && m_deals[i].time <= m_history_to)
           {
            if(count == index)
              {
               m_selected_deal_ticket = m_deals[i].ticket;
               return(m_deals[i].ticket);
              }
            count++;
           }
        }
      m_selected_deal_ticket = 0;
      return(0);
     }

   long HistoryDealGetInteger(const ulong ticket, const ENUM_DEAL_PROPERTY_INTEGER property) const
     {
      int size = ArraySize(m_deals);
      for(int i = 0; i < size; i++)
        {
         if(m_deals[i].ticket == ticket)
           {
            switch(property)
              {
               case DEAL_TICKET:   return((long)m_deals[i].ticket);
               case DEAL_ORDER:    return((long)m_deals[i].order);
               case DEAL_TIME:     return((long)m_deals[i].time);
               case DEAL_TYPE:     return((long)m_deals[i].type);
               case DEAL_ENTRY:    return((long)m_deals[i].entry);
               case DEAL_MAGIC:    return(m_deals[i].magic);
               default:            return(0);
              }
           }
        }
      return(0);
     }

   double HistoryDealGetDouble(const ulong ticket, const ENUM_DEAL_PROPERTY_DOUBLE property) const
     {
      int size = ArraySize(m_deals);
      for(int i = 0; i < size; i++)
        {
         if(m_deals[i].ticket == ticket)
           {
            switch(property)
              {
               case DEAL_VOLUME:     return(m_deals[i].volume);
               case DEAL_PRICE:      return(m_deals[i].price);
               case DEAL_COMMISSION: return(m_deals[i].commission);
               case DEAL_SWAP:       return(m_deals[i].swap);
               case DEAL_PROFIT:     return(m_deals[i].profit);
               default:              return(0.0);
              }
           }
        }
      return(0.0);
     }

   string HistoryDealGetString(const ulong ticket, const ENUM_DEAL_PROPERTY_STRING property) const
     {
      int size = ArraySize(m_deals);
      for(int i = 0; i < size; i++)
        {
         if(m_deals[i].ticket == ticket)
           {
            switch(property)
              {
               case DEAL_SYMBOL:   return(m_deals[i].symbol);
               case DEAL_COMMENT:  return(m_deals[i].comment);
               default:            return("");
              }
           }
        }
      return("");
     }

   //+---------------------------------------------------------------+
   //| Pending Order Setup Helpers (Used by Unit Tests)              |
   //+---------------------------------------------------------------+
   void AddOrder(const SMockPendingOrder &order)
     {
      int size = ArraySize(m_orders);
      ArrayResize(m_orders, size + 1);
      m_orders[size] = order;
     }

   bool RemoveOrder(const ulong ticket)
     {
      int size = ArraySize(m_orders);
      for(int i = 0; i < size; i++)
        {
         if(m_orders[i].ticket == ticket)
           {
            for(int j = i; j < size - 1; j++)
               m_orders[j] = m_orders[j + 1];
            ArrayResize(m_orders, size - 1);
            return(true);
           }
        }
      return(false);
     }

   int OrdersTotal(void) const
     {
      return(ArraySize(m_orders));
     }

   ulong OrderGetTicket(const int index)
     {
      if(index < 0 || index >= ArraySize(m_orders))
        {
         m_selected_order_ticket = 0;
         return(0);
        }
      m_selected_order_ticket = m_orders[index].ticket;
      return(m_orders[index].ticket);
     }

   long OrderGetInteger(const ulong ticket, const ENUM_ORDER_PROPERTY_INTEGER property) const
     {
      int size = ArraySize(m_orders);
      for(int i = 0; i < size; i++)
        {
         if(m_orders[i].ticket == ticket)
           {
            switch(property)
              {
               case ORDER_TICKET: return((long)m_orders[i].ticket);
               case ORDER_MAGIC:  return(m_orders[i].magic);
               case ORDER_TYPE:   return((long)m_orders[i].type);
               case ORDER_STATE:  return((long)m_orders[i].state);
               case ORDER_TIME_SETUP: return((long)m_orders[i].time_setup);
               default:           return(0);
              }
           }
        }
      return(0);
     }

   string OrderGetString(const ulong ticket, const ENUM_ORDER_PROPERTY_STRING property) const
     {
      int size = ArraySize(m_orders);
      for(int i = 0; i < size; i++)
        {
         if(m_orders[i].ticket == ticket)
           {
            switch(property)
              {
               case ORDER_SYMBOL:  return(m_orders[i].symbol);
               case ORDER_COMMENT: return(m_orders[i].comment);
               default:            return("");
              }
           }
        }
      return("");
     }
  };

#endif
//+------------------------------------------------------------------+
