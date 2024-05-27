//+------------------------------------------------------------------+
//|                                                 MagicButtons.mq4 |
//|                                  Copyright 2023, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link      ""
#property version   "1.00"
#property strict
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
CAppDialog dialogWindow;
CButton sellButton, buyButton;
input double TP = 4.0;
input double SL = 16.0;
input double riskPercentage = 1.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   dialogWindow.Create(0, "dialogWindow", 0, 50, 50, 250, 130);
   dialogWindow.Caption("Magic Button");
   sellButton.Create(0, "sellButton", 0,20,10, 90, 40);
   sellButton.Text("Sell");
   dialogWindow.Add(sellButton) ;
   buyButton.Create(0, "buyButton", 0, 100,10,170,40) ;
   buyButton.Text("Buy");
   dialogWindow.Add(buyButton) ;
   dialogWindow.Run() ;
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| ChartEvent fuction                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
//---
   dialogWindow.OnEvent(id, lparam, dparam, sparam);
   if (sellButton.Contains((int) lparam, (int) dparam)) {
      sellButton.Pressed(true);
   } else {
      sellButton.Pressed(false);
   }

   if (buyButton.Contains((int) lparam, (int)dparam)) {
      buyButton.Pressed(true);
   } else {
      buyButton.Pressed(false);
   }

   if (id==CHARTEVENT_OBJECT_CLICK && sparam=="sellButton") {
      OpenSell();
   }

   if (id==CHARTEVENT_OBJECT_CLICK && sparam=="buyButton") {
      OpenBuy();
   }
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   dialogWindow.Destroy(reason);

}
//+------------------------------------------------------------------+
//| Expert open sell order function                                  |
//+------------------------------------------------------------------+
void OpenSell() {
   double nTickValue = 1.0;
   if ((Digits == 3) || (Digits == 5) || (Digits == 1)) {
      nTickValue = 10.0;
   }
   Print("nTickValue = " + (string)nTickValue);
   double price = NormalizeDouble(Bid, Digits);
   double stoploss = NormalizeDouble(Ask + SL * Point * nTickValue, Digits);
   double takeprofit = NormalizeDouble(Ask - TP * Point * nTickValue, Digits);
   int ticket = OrderSend(Symbol(), OP_SELL, CalculateLotSize(), price, 0, stoploss, takeprofit, "Sell order - Magic Button", 16384, 0, clrGreen);
   if(ticket<0) {
      Print("OrderSend failed with error #",GetLastError());
   } else {
      Print("OrderSend placed successfully at price= " + (string)price + ", lotSize = " + (string)CalculateLotSize() + ", stoploss = " + (string)stoploss + ", takeProfit = " + (string)takeprofit);
   }
}

//+------------------------------------------------------------------+
//| Expert open buy order function                                   |
//+------------------------------------------------------------------+
void OpenBuy() {
   double nTickValue = 1.0;
   if ((Digits == 3) || (Digits == 5) || (Digits == 1)) {
      nTickValue = 10.0;
   }
   Print("nTickValue = " + (string)nTickValue);
   double price = NormalizeDouble(Ask, Digits);
   double stoploss = NormalizeDouble(Bid - SL * Point * nTickValue, Digits);
   double takeprofit = NormalizeDouble(Bid + TP * Point * nTickValue, Digits);
   int ticket = OrderSend(Symbol(), OP_BUY, CalculateLotSize(), price, 0, stoploss, takeprofit, "Buy order - Magic Button", 16384, 0, clrGreen);
   if(ticket<0) {
      Print("OrderSend failed with error #",GetLastError());
   } else {
      Print("OrderSend placed successfully at price= " + (string)price + ", lotSize = " + (string)CalculateLotSize() + ", stoploss = " + (string)stoploss + ", takeProfit = " + (string)takeprofit);
   }
}

//+------------------------------------------------------------------+
//| Expert lot size calculator function                               |
//+------------------------------------------------------------------+
double CalculateLotSize() {
// Calculate the position size.
   double lotSize, lotSize2 = 0;
   
   double nTickValue = 1.0;
   if ((Digits == 3) || (Digits == 5) || (Digits == 1)) {
      nTickValue = 10.0;
   }
// We apply the formula to calculate the position size and assign the value to the variable.
   lotSize = (AccountBalance() * (riskPercentage / 100)) / (SL * nTickValue);
   lotSize2 = MathRound(lotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   Print("lot size = " + (string)lotSize);
   Print("lot size 2 = " + (string)lotSize2);
   return lotSize;
}
//+------------------------------------------------------------------+
