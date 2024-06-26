﻿//+------------------------------------------------------------------+
//|                                                     Trap12PM.mq4 |
//|                                  Copyright 2023, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link      ""
#property version   "1.00"
#property strict

//THIS EA WORK ONLY ON M15!!

input int EndTimeHour = 13;
input int EndTimeMinute = 0;
input int riskPercentage = 1.0;
input bool useFixedLots = false;
input double fixedLots = 1.0;
input double MonthlyProfitTarget = 200.00;
input bool iMagic = 1200;

datetime lastTradeDate = 0;
double high = 0;
double low = 0;
double rangeInPips = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

//---
   if(useFixedLots && fixedLots == 0) {
      return(INIT_PARAMETERS_INCORRECT);
   }

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   ObjectDelete("MyRectangle");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

// Check if current time matches the specified candle opening time
   if(Hour() == EndTimeHour && Minute() == EndTimeMinute && Seconds() == 1 && DayOfWeek() != 1) {
      // Get the high and low of the current candle
      high = High[1];
      low = Low[1];

      // Calculate the range in pips
      //rangeInPips = high - low) / Point;
      rangeInPips = high - low;

      // Print the range to the journal
      Print("Time is ", TimeCurrent(), " ");
      Print("Range of the candle from 11:45 to 12:00 is ", rangeInPips, " pips");
      Print("High of the candle from 11:45 to 12:00 is ", high, " ");
      Print("Low of the candle from 11:45 to 12:00 is ", low, " ");
   }


   if((TimeCurrent() > StrToTime("13:15")) && (lastTradeDate != TimeDay(TimeCurrent())) && DayOfWeek() != 1) {
      if(high < Close[1]) {
         sendOrder(OP_BUY, rangeInPips); //buy
         lastTradeDate = TimeDay(TimeCurrent());
      } else if(low > Close[1]) {
         sendOrder(OP_SELL, rangeInPips);
         lastTradeDate = TimeDay(TimeCurrent());
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendOrder(int command, double stopAndProfit) {

   double openPrice = 0.0;
   double stopLossPrice = 0.0;
   double takeProfitPrice = 0.0;
   double nDigits = calculateNormalizedDigits();
   double lotSize = useFixedLots ? fixedLots : calculateLotSize(stopAndProfit);

   if(command == OP_BUY) {
      openPrice=NormalizeDouble(Ask,Digits);
      stopLossPrice=NormalizeDouble(Ask - stopAndProfit, Digits);
      takeProfitPrice=NormalizeDouble(Ask + stopAndProfit, Digits);

   } else {
      openPrice=NormalizeDouble(Bid,Digits);
      stopLossPrice=NormalizeDouble(Bid + stopAndProfit, Digits);
      takeProfitPrice=NormalizeDouble(Bid - stopAndProfit, Digits);
   }

// We define a variable to store and store the result of the function.
   int orderNumber;
   orderNumber=OrderSend(Symbol(),command,lotSize, openPrice, 0, stopLossPrice, takeProfitPrice);

// We verify if the order has gone through or not and print the result.
   if(orderNumber>0) {
      Print("Order ",orderNumber," open");
   } else {
      Print("Order failed with error - ",GetLastError());
   }

   Print("openPrice: ", openPrice, " stopLoss: ", stopLossPrice, " takeProfit: ", takeProfitPrice, " lots: ", lotSize, " nDigits: ", nDigits);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateNormalizedDigits() {
   if(Digits<=3) {
      return(0.01);
   } else if(Digits>=4) {
      return(0.0001);
   } else return(0);
}

//+------------------------------------------------------------------+
//|   Calculate the position size.                                   |
//+------------------------------------------------------------------+
double calculateLotSize(double SL) {
   double LotSize = 0;
// We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
// If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5)) {
      nTickValue = nTickValue * 10;
   }
// We apply the formula to calculate the position size and assign the value to the variable.
   Print(AccountBalance(), " ", riskPercentage, " ", SL, " ", nTickValue);
   LotSize = (AccountBalance() * riskPercentage / 100) / (SL * nTickValue);
   return LotSize;
}
//+------------------------------------------------------------------+  
//+------------------------------------------------------------------+
