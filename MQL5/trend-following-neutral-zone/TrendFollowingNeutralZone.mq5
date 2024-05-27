//+------------------------------------------------------------------+
//|                                    TrendFollowingNeutralZone.mq5 |
//|                                  Copyright 202, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link ""
#property version "1.00"
//----INCLUDE--------------------------------------------------------+
#include "../Include/PositionsManager.mqh"
#include <JAson.mqh>

//+------------------------------------------------------------------+
#define INF 0x6FFFFFFF
//+------------------------------------------------------------------+
MqlRates rates[];
bool changeNeutralZone;
double CCI[];
double upperLevel;
double lowerLevel;
int CCI_handle;
int magicNum = 5555;
//+------------------------INPUT-------------------------------------+
//Size in lotti
input double positionSize = 0.1;
//start trading time
input int myStartTrade = 8;
//end trading time
input int myEndTrade = 18;
//StopLoss in PIP
input int myStop = 50;
//TakeProfit in PIP
input int myProfit = 100;
// trade exit mode
input int exit;
//enable telegram notification
input bool telegram = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(CCI, true);

   changeNeutralZone = true;

//--- creation of the indicator iCCI
   CCI_handle = iCCI(NULL, 0, 5, PRICE_CLOSE);
//--- report if there was an error in object creation
   if (CCI_handle < 0) {
      Print("The creation of iCCI has failed: Runtime error =", GetLastError());
      //--- forced program termination
      return (-1);
   }
   return (INIT_SUCCEEDED);
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
   if (dtTimeCurrent.hour >= myStartTrade && dtTimeCurrent.hour < myEndTrade && GetOpenPositionsForSpecificSymbol(magicNum, _Symbol) == 0) {

      if(changeNeutralZone) {
         CalculateNeutralZone();
         changeNeutralZone = false;
      }

      CopyBuffer(CCI_handle, 0, 0, 3, CCI);
      double CCIValue = CCI[1];
      double close = iClose(_Symbol, 0, 1);

      if (CCIValue > 90 && close > upperLevel) {
         Print("CCIValue : " + (string) CCIValue + " - upperLevel: " + (string) upperLevel + " - lowerLevel: " + (string) lowerLevel + " - iClose candela precedente: " + (string)close);
         SendOrder(ORDER_TYPE_BUY, _Symbol, 0, myStop, myProfit, magicNum, positionSize);
         changeNeutralZone = true;
      }

      if (CCIValue < -90 && close < lowerLevel) {
         Print("CCIValue : " + (string) CCIValue + " - upperLevel: " + (string) upperLevel + " - lowerLevel: " + (string) lowerLevel + " - iClose candela precedente: " + (string)close);
         SendOrder(ORDER_TYPE_SELL, _Symbol, 0, myStop, myProfit, magicNum, positionSize);
         changeNeutralZone = true;
      }
   } else {
      if(GetOpenPositionsForSpecificSymbol(magicNum, _Symbol) != 0) {
         changeNeutralZone = true;
         switch(exit) {
         case 1:
            ClosePositionsAtEndSessionOnlyWithProfit(magicNum, myEndTrade);
            break;
         case 2:
            ClosePositionAtEndSession(magicNum, myEndTrade);
            break;
         case 3:
            ClosePositionAtEndOfWeek(magicNum, myEndTrade);
            break;
         }
      }
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result) {
   CJAVal jv;
   char data[];

   if(telegram) {
      if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
         long     deal_entry        =0;
         double   deal_profit       =0.0;
         double   deal_volume       =0.0;
         string   deal_symbol       ="";
         long     deal_magic        =0;
         long     deal_reason       =-1;
         if(HistoryDealSelect(trans.deal)) {
            deal_entry=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
            deal_profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
            deal_volume=HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
            deal_symbol=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
            deal_magic=HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
            deal_reason=HistoryDealGetInteger(trans.deal,DEAL_REASON);
            jv["entry"]=deal_entry;
            jv["profit"]=deal_profit;
            jv["volume"]=deal_volume;
            jv["symbol"]=deal_symbol;
            jv["ea-strategy"]="Trend Following Netrual Zone";
            jv["magic"]=deal_magic;
            jv["reason"]=deal_reason;
            ArrayResize(data, StringToCharArray(jv.Serialize(), data, 0, WHOLE_ARRAY)-1);
         } else {
            return;
         }

         string _url = "http://127.0.0.1";
         string _headers = "Content-Type: application/json";
         string stringresult = "";

         char response[];
         string result_headers;
         ResetLastError();

         int res = WebRequest("POST", _url, _headers, 30000, data, response, result_headers);

         if (res == -1) {
            Print("Error in WebRequest. Error code =", GetLastError());
            //--- URL may not exist in white list, so there is a message for it
            MessageBox("Add '" + _url + "' to white list in options in experts page. ", "Error: ", MB_ICONINFORMATION);
         } else {
            if (res == 200) {
               //--- Succesfully downloaded
               PrintFormat("Succesfully done WebRequest, size %d.", ArraySize(response));
            } else
               PrintFormat("Error WebRequest url '%s', code %d", _url, res);
         }
      }
   }
}

void CalculateNeutralZone() {

   int copied = CopyRates(_Symbol, PERIOD_M5, 0, 144, rates);
   double highestClose = 0;
   double lowestClose = INF;

   if(copied>0) {
      Print("Barre della zona neutra copiate: "+ (string)copied);
      for(int i = 0; i < copied; i++) {
         //close price > open price means green candle
         if(rates[i].close > rates[i].open) {
            if(rates[i].close > highestClose) {
               highestClose = rates[i].close;
            }
         }

         //red candle
         if(rates[i].close < rates[i].open) {
            if(rates[i].close < lowestClose ) {
               lowestClose = rates[i].close;
            }
         }
      }
   } else {
      Print("Fallimento nell'ottenimento dei dati dello storico per il simbolo: ", Symbol());
   }

   upperLevel = highestClose;
   lowerLevel = lowestClose;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
