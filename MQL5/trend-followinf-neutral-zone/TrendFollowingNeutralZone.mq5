//+------------------------------------------------------------------+
//|                                    TrendFollowingNeutralZone.mq5 |
//|                                  Copyright 2023, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+

#include <Trade\Trade.mqh> //Instatiate Trades Execution Library
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information

//+------------------------------------------------------------------+

CTrade m_trade; // Trades Info and Executions library
CPositionInfo m_position; // Library for all position features and information

MqlRates arrayPriceZoneData[]; 
MqlRates arrayPriceData[];
MqlTradeRequest request;
MqlTradeResult result;

bool changeNeutralZone;
double minClose;
double maxClose;
double CCI[];                
int CCI_handle;
int MagicNumber = 5555;

//+------------------------INPUT-------------------------------------+
//Size in lotti
input double size = 0.1;
//start trading time
input int startTrading = 8;
//end trading time
input int endTrading = 18;
//StopLoss in PIP
input int stopLoss = 50;
//TakeProfit in PIP
input int takeProfit = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   ArraySetAsSeries(arrayPriceZoneData, true);
   ArraySetAsSeries(arrayPriceData, true);
   ArraySetAsSeries(CCI, true);
   
   changeNeutralZone = true;
   
   //--- creation of the indicator iCCI
   CCI_handle=iCCI(NULL, 0, 5, PRICE_CLOSE);
   //--- report if there was an error in object creation
   if(CCI_handle<0) {
      Print("The creation of iCCI has failed: Runtime error =", GetLastError());
      //--- forced program termination
      return(-1);
    }
   return(INIT_SUCCEEDED);
}
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   MqlDateTime dtTimeCurrent;
   TimeCurrent(dtTimeCurrent);
   
   
   
      int arrayPriceDataMemorized = CopyRates(_Symbol, _Period, 0, 2, arrayPriceData);
      if(arrayPriceDataMemorized <= 0) {
         Print("Fallimento nell'ottenimento dei dati dello storico per il simbolo: ", Symbol());
      }
   
      if(PositionsTotal() == 0) {
      
         if(dtTimeCurrent.hour == startTrading && dtTimeCurrent.min == 0 && dtTimeCurrent.sec == 0) {
            SetNeutralZone();
         }
         
         if(changeNeutralZone) {
            SetNeutralZone();
            changeNeutralZone = false;
         }
         
         CopyBuffer(CCI_handle, 0, 0, 3, CCI);
         double CCIValue = CCI[1];  
         
         if(dtTimeCurrent.hour >= startTrading && dtTimeCurrent.hour < endTrading) {
         
         Print("CCIValue : "+ (string)CCIValue + " - maxClose: " + (string)maxClose + " - minClose: " + (string)minClose + " - Close candela precedente: " + (string)arrayPriceData[1].close);
         if(CCIValue > 90 && arrayPriceData[1].close > maxClose) {
            SendOrder(ORDER_TYPE_BUY, _Symbol);
            changeNeutralZone = true;
         }
         
         if(CCIValue < -90 && arrayPriceData[1].close < minClose) {
            SendOrder(ORDER_TYPE_SELL, _Symbol);
            changeNeutralZone = true;
         }
       }
    }
    
    
    if(dtTimeCurrent.day_of_week == 5 && dtTimeCurrent.hour >= endTrading) {
      CloseAllPosition();
    }
 }  
//+------------------------------------------------------------------+

void SendOrder(ENUM_ORDER_TYPE orderType, string symbol) {

   //Nel caso di quotazioni con 3 o con 5 decimali dovremmo moltiplicare per 10
   //i valori ottenuti dai calcoli precedenti
   int P = 1; 
   if(_Digits == 5 || _Digits == 3 || _Digits == 1) {
     P = 10;
   }
   
   double SL;
   double TP;

   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type = orderType;
   request.magic = MagicNumber;
   request.symbol = symbol;
   if (orderType == ORDER_TYPE_SELL) {
      SL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) + 50 * _Point * P, _Digits);
      TP = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - 100 * _Point * P, _Digits);
      request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
      request.sl=SL;
      request.tp=TP;
   } else {
      SL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - 50 *  _Point * P, _Digits);
      TP = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + 100 * _Point * P, _Digits);
      request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      request.sl=SL;
      request.tp=TP;
   }
   request.volume = size;
   request.type_filling = ORDER_FILLING_FOK;
   request.deviation = 0;
   ZeroMemory(result);
   bool order = OrderSend(request, result);
}

void SetNeutralZone(void) {

      minClose = 100000.0;
      maxClose = 0.0;
      int arrayPriceDataMemorized = CopyRates(_Symbol, _Period, 1, 145, arrayPriceZoneData);
      if(arrayPriceDataMemorized>0) {
         Print("Barre della zona neutra copiate: "+ arrayPriceDataMemorized);
         for(int i = 0; i<arrayPriceData.Size(); i++) {
            //close price > open price means green candle
            if(arrayPriceData[i].close > arrayPriceData[i].open) {
               if(arrayPriceData[i].close > maxClose) {
                maxClose = arrayPriceData[i].close;
               }
            }
            
            //red candle
            if(arrayPriceData[i].close < arrayPriceData[i].open) {
               if(arrayPriceData[i].close < minClose ) {
                 minClose = arrayPriceData[i].close;
            }
         }
      }
   } else {
      Print("Fallimento nell'ottenimento dei dati dello storico per il simbolo: ",Symbol());
  }
}

void CloseAllPosition() {  
    for (int i = PositionsTotal() - 1; i >= 0; i--) {// loop all Open Positions
        if (m_position.SelectByIndex(i)) {
            if (m_position.Magic() == MagicNumber) {
                m_trade.PositionClose(m_position.Ticket()); // then delete it --period
                Sleep(100); // Relax for 100 ms
            }
        }
     }
}