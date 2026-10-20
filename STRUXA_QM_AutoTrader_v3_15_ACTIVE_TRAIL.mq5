//+------------------------------------------------------------------+
//| STRUXA_QM_AutoTrader_v3_15_ACTIVE_TRAIL.mq5                        |
//| Complete V3.15 active trail execution build                                       |
//| Structural QM scoring + execution unlock + active money trail             |
//+------------------------------------------------------------------+
#property strict
#property version   "3.15"
#property description "STRUXA QM AutoTrader V3.15 active money trail"

#include <Trade/Trade.mqh>
CTrade trade;

enum STRUXA_ZONE_STATE
{
   STATE_CANDIDATE = 0,
   STATE_ARMED = 1,
   STATE_TRIGGERED = 2,
   STATE_USED = 3,
   STATE_MISSED = 4,
   STATE_EXPIRED = 5,
   STATE_BLOCKED_RISK = 6,
   STATE_BLOCKED_SPACING = 7,
   STATE_DEFERRED = 8,
   STATE_REJECTED_SCORE = 9
};

enum STRUXA_SETUP_TYPE
{
   SETUP_QM = 0,
   SETUP_IQM = 1,
   SETUP_QMC = 2,
   SETUP_QMM = 3,
   SETUP_QMR = 4,
   SETUP_MEF = 5,
   SETUP_FAKEOUT = 6
};

enum STRUXA_DIRECTION
{
   DIR_BUY = 1,
   DIR_SELL = -1
};

#define SETUP_TAG_COUNT 14

input string          InpEAName                    = "STRUXA_QM_AutoTrader_v3_15_ACTIVE_TRAIL";
input ulong           InpMagicNumber               = 26062543;
input ENUM_TIMEFRAMES InpExecutionTF               = PERIOD_M5;
input ENUM_TIMEFRAMES InpZoneTF1                   = PERIOD_M15;
input ENUM_TIMEFRAMES InpZoneTF2                   = PERIOD_M30;
input ENUM_TIMEFRAMES InpBiasTF1                   = PERIOD_H1;
input ENUM_TIMEFRAMES InpBiasTF2                   = PERIOD_H4;

input bool            InpEnableAutoTrading         = true;
input bool            InpUsePendingOrders          = true;
input bool            InpExecuteMarketIfTouched    = true;
input string          InpTradeComment              = "STRUXA_QM_V315T";

input bool            InpUseQM                     = true;
input bool            InpUseIQM                    = true;
input bool            InpUseQMC                    = true;
input bool            InpUseQMM                    = true;
input bool            InpUseQMR                    = true;
input bool            InpUseMEF                    = true;
input bool            InpUseFakeout                = true;
input bool            InpShowSetupStatsTable       = true;
input bool            InpShowGroupedStats          = true;

input int             InpLookbackBars              = 420;
input int             InpSwingLeftRight            = 2;
input int             InpMaxZones                  = 60;
input int             InpTerminalArchiveMax        = 500;
input int             InpPendingExpiryBars         = 72;
input int             InpMaxBarsAfterBreak         = 48;
input int             InpMinBreakCloseBars         = 2;
input int             InpMaxBuyOrders              = 5;
input int             InpMaxSellOrders             = 5;
input int             InpMinTradeScore             = 75;
input int             InpCandidateMinScore         = 60;
input int             InpStandardQMTradeMinScore   = 58;
input int             InpStandardQMCandidateMinScore = 55;
input double          InpMinimumRR                 = 2.0;
input double          InpRiskPercent               = 0.25;
input double          InpFixedLot                  = 0.0;
input bool            InpAllowMinLotWhenRiskLow    = true;
input bool            InpOnePositionPerSymbol      = false;
input bool            InpOnePendingPerDirection    = false;
input int             InpMinutesBetweenTrades      = 0;
input int             InpMaxSpreadPoints           = 350;
input int             InpSlippagePoints            = 50;

input bool            InpUsePropFirmGuards         = true;
input double          InpPropAccountSize           = 5000.0;
input double          InpMaxDailyDDPercent         = 4.0;
input double          InpMaxOverallDDPercent       = 8.0;
input double          InpDailySoftStopMoney        = 150.0;
input double          InpDailyHardStopMoney        = 190.0;
input double          InpOverallSoftStopMoney      = 300.0;
input double          InpOverallHardStopMoney      = 390.0;
input bool            InpCancelPendingOnDDLock     = true;
input bool            InpClosePositionsOnHardDD    = true;

input bool            InpUseSessionFilter          = false;
input int             InpLondonStartHour           = 7;
input int             InpLondonEndHour             = 12;
input int             InpNYStartHour               = 13;
input int             InpNYEndHour                 = 21;

input bool            InpUseRSIDivergence          = true;
input bool            InpUseMACDDivergence         = true;
input bool            InpUseOBVConfirmation        = true;
input int             InpRSIPeriod                 = 14;
input int             InpMACDFast                  = 12;
input int             InpMACDSlow                  = 26;
input int             InpMACDSignal                = 9;
input int             InpATRPeriod                 = 14;
input int             InpOBVFlatBars               = 8;
input double          InpOBVFlatThreshold          = 0.06;

input bool            InpUseMoneyLockTrailing      = true;
input double          InpTrailStartMoney           = 20.0;
input double          InpTrailLockMoney            = 5.0;
input bool            InpUseActiveMoneyTrail       = true;
input double          InpTrailGivebackMoney        = 15.0;
input double          InpTrailStepMoney            = 2.5;
input bool            InpUseTrailEmergencyClose    = true;
input double          InpTrailEmergencyBandMoney   = 1.0;
input double          InpSLBufferPips              = 5.0;
input double          InpFallbackRR                = 4.0;
input double          InpEntryATRMultiplier        = 0.15;
input double          InpSLATRMultiplier           = 1.25;
input double          InpTargetRR                  = 4.0;
input int             InpQMPremiumBaseScore        = 82;
input bool            InpQMIgnoreMissingConfirmPenalty = true;
input bool            InpRequireStructuralQM        = true;
input int             InpQMStructureLookbackBars    = 96;
input double          InpQMHeadBreakATR             = 0.20;
input double          InpQMBreakConfirmATR          = 0.10;
input int             InpQMPremiumScoreBoost        = 8;
input bool            InpTesterIgnoreSession        = true;
input bool            InpTesterIgnoreOnePosition    = true;
input bool            InpTesterIgnoreSpacing        = true;
input int             InpRetryCooldownBars         = 1;
input int             InpMaxRetriesPerZone         = 2;
input bool            InpUseStopOrdersForBreakout  = true;
input int             InpMarketTouchBufferPts      = 30;
input int             InpBrokerMinExtraBufferPts   = 20;
input bool            InpBlockCloseOnlySymbol      = true;
input double          InpMinLotRiskCapMultiplier    = 20.0;
input double          InpMinLotAbsoluteRiskCap      = 200.0;
input bool            InpPrintLotDiagnostics        = true;

input bool            InpUseScorePenalties         = true;
input int             InpLateEntryBars             = 8;
input int             InpLateEntryPenalty          = 12;
input int             InpTouchedQMLPenalty         = 18;
input int             InpWideSLPenalty             = 15;
input int             InpFlatOBVPenalty            = 10;
input int             InpCrowdedZonePenalty        = 12;
input int             InpWideSLPenaltyThresholdPts = 3500;
input int             InpCrowdedZoneDistancePts    = 350;
input int             InpCrowdedZoneMaxCount       = 2;

input bool            InpDrawObjects               = true;
input bool            InpHideTerminalZones         = true;
input bool            InpDrawTerminalZones         = false;
input int             InpTerminalCleanupBars       = 24;
input bool            InpPurgeTerminalFromRegistry = true;
input int             InpTerminalRegistryPurgeBars = 96;
input int             InpTemporaryBlockExpiryBars  = 30;
input int             InpRetiredKeyTTLBars         = 600;
input bool            InpDrawBlockedDebugZones     = true;

input bool            InpPrintDebug                = true;
input bool            InpLogOrderBlocks            = true;

struct Zone
{
   ulong             id;
   string            key;
   string            shortTag;
   int               state;
   int               direction;
   int               setupType;

   datetime          setupTime;
   datetime          createdTime;
   datetime          lastUpdateTime;
   datetime          expiryTime;
   datetime          retryAfterTime;
   datetime          terminalTime;

   int               setupBarShift;
   int               score;
   int               retries;
   int               tempBlocks;
   string            lastBlockReason;

   double            entry;
   double            sl;
   double            tp;
   double            zoneHigh;
   double            zoneLow;
   double            rr;
   double            atr;

   bool              lateEntry;
   bool              touchedQML;
   bool              wideSL;
   bool              flatOBV;
   bool              crowded;

   ulong             orderTicket;
   ulong             positionTicket;
};

struct GuardState
{
   bool hardLocked;
   bool softLocked;
   string reason;
};

struct SetupStat
{
   string tag;
   int setupType;
   int direction;

   long appearances;
   long registered;
   long rejectedScore;
   long armed;
   long blockedTemp;
   long orderSent;
   long executed;
   long closed;
   long wins;
   long losses;
   long breakeven;

   double grossProfit;
   double grossLoss;
   double netProfit;
   double bestTrade;
   double worstTrade;
};

Zone     g_active[];
Zone     g_archive[];
int      g_activeCount       = 0;
int      g_archiveCount      = 0;
ulong    g_nextZoneId        = 1;

SetupStat g_stats[];
ulong     g_positionIds[];
int       g_positionStatsIndexes[];
int       g_positionTrackCount = 0;
ulong     g_seenEntryDeals[];
int       g_seenEntryDealCount = 0;
ulong     g_seenCloseDeals[];
int       g_seenCloseDealCount = 0;
ulong     g_trailTickets[];
double    g_trailPeakProfits[];
double    g_trailLockProfits[];
bool      g_trailArmed[];
int       g_trailTrackCount = 0;

int      g_rsiHandle         = INVALID_HANDLE;
int      g_macdHandle        = INVALID_HANDLE;
int      g_obvHandle         = INVALID_HANDLE;
int      g_atrHandle         = INVALID_HANDLE;

datetime g_lastBarTime       = 0;
datetime g_lastTradeTime     = 0;
double   g_dayStartBalance   = 0.0;
int      g_dayKey            = -1;
bool     g_hardDDLock        = false;
bool     g_softDDLock        = false;
string   g_lastAction        = "INIT";
string   g_lastSkip          = "none";
string   g_prefix            = "STRUXA_V315_";

void DebugPrint(const string label, const string msg)
{
   if(!InpPrintDebug)
      return;

   g_lastAction = label + ": " + msg;
   Print("[", InpEAName, "] ", label, " ", msg);
}

string DirectionName(const int direction)
{
   if(direction == DIR_BUY)
      return "BUY";
   return "SELL";
}

string StateName(const int state)
{
   switch(state)
   {
      case STATE_CANDIDATE:       return "CANDIDATE";
      case STATE_ARMED:           return "ARMED";
      case STATE_TRIGGERED:       return "TRIGGERED";
      case STATE_USED:            return "USED";
      case STATE_MISSED:          return "MISSED";
      case STATE_EXPIRED:         return "EXPIRED";
      case STATE_BLOCKED_RISK:    return "BLOCKED_RISK";
      case STATE_BLOCKED_SPACING: return "BLOCKED_SPACING";
      case STATE_DEFERRED:        return "DEFERRED";
      case STATE_REJECTED_SCORE:  return "REJECTED_SCORE";
      default:                    return "UNKNOWN";
   }
}

string SetupName(const int setupType)
{
   switch(setupType)
   {
      case SETUP_QM:      return "QM";
      case SETUP_IQM:     return "iQM";
      case SETUP_QMC:     return "QMC";
      case SETUP_QMM:     return "QMM";
      case SETUP_QMR:     return "QMR";
      case SETUP_MEF:     return "MEF";
      case SETUP_FAKEOUT: return "FAKEOUT";
      default:            return "SETUP";
   }
}

string SetupTag(const int setupType, const int direction)
{
   return DirectionName(direction) + "_" + SetupName(setupType);
}


int CandidateScoreMin(const int setupType)
{
   if(setupType == SETUP_QM)
      return InpStandardQMCandidateMinScore;

   return InpCandidateMinScore;
}

int TradeScoreMin(const int setupType)
{
   if(setupType == SETUP_QM)
      return InpStandardQMTradeMinScore;

   return InpMinTradeScore;
}

bool FamilyEnabled(const int setupType)
{
   switch(setupType)
   {
      case SETUP_QM:      return InpUseQM;
      case SETUP_IQM:     return InpUseIQM;
      case SETUP_QMC:     return InpUseQMC;
      case SETUP_QMM:     return InpUseQMM;
      case SETUP_QMR:     return InpUseQMR;
      case SETUP_MEF:     return InpUseMEF;
      case SETUP_FAKEOUT: return InpUseFakeout;
      default:            return false;
   }
}

int StatsIndex(const int setupType, const int direction)
{
   if(setupType == SETUP_QM)
      return (direction == DIR_BUY ? 0 : 1);
   if(setupType == SETUP_IQM)
      return (direction == DIR_BUY ? 2 : 3);
   if(setupType == SETUP_QMC)
      return (direction == DIR_BUY ? 4 : 5);
   if(setupType == SETUP_QMM)
      return (direction == DIR_BUY ? 6 : 7);
   if(setupType == SETUP_QMR)
      return (direction == DIR_BUY ? 8 : 9);
   if(setupType == SETUP_MEF)
      return (direction == DIR_BUY ? 10 : 11);
   if(setupType == SETUP_FAKEOUT)
      return (direction == DIR_BUY ? 12 : 13);

   return -1;
}

void ResetSetupStat(SetupStat &s, const string tag, const int setupType, const int direction)
{
   s.tag = tag;
   s.setupType = setupType;
   s.direction = direction;
   s.appearances = 0;
   s.registered = 0;
   s.rejectedScore = 0;
   s.armed = 0;
   s.blockedTemp = 0;
   s.orderSent = 0;
   s.executed = 0;
   s.closed = 0;
   s.wins = 0;
   s.losses = 0;
   s.breakeven = 0;
   s.grossProfit = 0.0;
   s.grossLoss = 0.0;
   s.netProfit = 0.0;
   s.bestTrade = 0.0;
   s.worstTrade = 0.0;
}

void InitSetupStats()
{
   ArrayResize(g_stats, SETUP_TAG_COUNT);

   ResetSetupStat(g_stats[0],  "BUY_QM",       SETUP_QM,      DIR_BUY);
   ResetSetupStat(g_stats[1],  "SELL_QM",      SETUP_QM,      DIR_SELL);
   ResetSetupStat(g_stats[2],  "BUY_iQM",      SETUP_IQM,     DIR_BUY);
   ResetSetupStat(g_stats[3],  "SELL_iQM",     SETUP_IQM,     DIR_SELL);
   ResetSetupStat(g_stats[4],  "BUY_QMC",      SETUP_QMC,     DIR_BUY);
   ResetSetupStat(g_stats[5],  "SELL_QMC",     SETUP_QMC,     DIR_SELL);
   ResetSetupStat(g_stats[6],  "BUY_QMM",      SETUP_QMM,     DIR_BUY);
   ResetSetupStat(g_stats[7],  "SELL_QMM",     SETUP_QMM,     DIR_SELL);
   ResetSetupStat(g_stats[8],  "BUY_QMR",      SETUP_QMR,     DIR_BUY);
   ResetSetupStat(g_stats[9],  "SELL_QMR",     SETUP_QMR,     DIR_SELL);
   ResetSetupStat(g_stats[10], "BUY_MEF",      SETUP_MEF,     DIR_BUY);
   ResetSetupStat(g_stats[11], "SELL_MEF",     SETUP_MEF,     DIR_SELL);
   ResetSetupStat(g_stats[12], "BUY_FAKEOUT",  SETUP_FAKEOUT, DIR_BUY);
   ResetSetupStat(g_stats[13], "SELL_FAKEOUT", SETUP_FAKEOUT, DIR_SELL);

   ArrayResize(g_positionIds, 0);
   ArrayResize(g_positionStatsIndexes, 0);
   ArrayResize(g_seenEntryDeals, 0);
   ArrayResize(g_seenCloseDeals, 0);
   g_positionTrackCount = 0;
   g_seenEntryDealCount = 0;
   g_seenCloseDealCount = 0;
}

void StatsAddAppearance(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].appearances++;
}

void StatsAddRegistered(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].registered++;
}

void StatsAddRejectedScore(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].rejectedScore++;
}

void StatsAddArmed(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].armed++;
}

void StatsAddBlocked(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].blockedTemp++;
}

void StatsAddOrderSent(const int setupType, const int direction)
{
   int idx = StatsIndex(setupType, direction);
   if(idx >= 0 && idx < ArraySize(g_stats))
      g_stats[idx].orderSent++;
}

bool UlongSeen(const ulong &arr[], const int count, const ulong value)
{
   for(int i = 0; i < count; i++)
   {
      if(arr[i] == value)
         return true;
   }
   return false;
}

void AddSeenUlong(ulong &arr[], int &count, const ulong value)
{
   if(value == 0)
      return;

   if(UlongSeen(arr, count, value))
      return;

   ArrayResize(arr, count + 1);
   arr[count] = value;
   count++;
}

int StatsIndexFromComment(const string comment)
{
   for(int i = 0; i < ArraySize(g_stats); i++)
   {
      string token = "|" + g_stats[i].tag + "|";
      if(StringFind(comment, token) >= 0)
         return i;
   }

   for(int i = 0; i < ArraySize(g_stats); i++)
   {
      string token = "|" + g_stats[i].tag;
      int pos = StringFind(comment, token);
      if(pos >= 0)
      {
         int after = pos + StringLen(token);
         if(after >= StringLen(comment) || StringSubstr(comment, after, 1) == "|")
            return i;
      }
   }

   return -1;
}

void TrackPositionStatsIndex(const ulong positionId, const int statsIndex)
{
   if(positionId == 0 || statsIndex < 0)
      return;

   for(int i = 0; i < g_positionTrackCount; i++)
   {
      if(g_positionIds[i] == positionId)
      {
         g_positionStatsIndexes[i] = statsIndex;
         return;
      }
   }

   ArrayResize(g_positionIds, g_positionTrackCount + 1);
   ArrayResize(g_positionStatsIndexes, g_positionTrackCount + 1);
   g_positionIds[g_positionTrackCount] = positionId;
   g_positionStatsIndexes[g_positionTrackCount] = statsIndex;
   g_positionTrackCount++;
}

int StatsIndexFromPosition(const ulong positionId)
{
   if(positionId == 0)
      return -1;

   for(int i = 0; i < g_positionTrackCount; i++)
   {
      if(g_positionIds[i] == positionId)
         return g_positionStatsIndexes[i];
   }
   return -1;
}

void StatsAddEntryDeal(const int statsIndex, const ulong dealTicket)
{
   if(statsIndex < 0 || statsIndex >= ArraySize(g_stats))
      return;

   if(UlongSeen(g_seenEntryDeals, g_seenEntryDealCount, dealTicket))
      return;

   AddSeenUlong(g_seenEntryDeals, g_seenEntryDealCount, dealTicket);
   g_stats[statsIndex].executed++;
}

void StatsAddClosedDeal(const int statsIndex, const ulong dealTicket, const double profit)
{
   if(statsIndex < 0 || statsIndex >= ArraySize(g_stats))
      return;

   if(UlongSeen(g_seenCloseDeals, g_seenCloseDealCount, dealTicket))
      return;

   AddSeenUlong(g_seenCloseDeals, g_seenCloseDealCount, dealTicket);

   bool first = (g_stats[statsIndex].closed == 0);
   g_stats[statsIndex].closed++;
   g_stats[statsIndex].netProfit += profit;

   if(profit > 0.0)
   {
      g_stats[statsIndex].wins++;
      g_stats[statsIndex].grossProfit += profit;
   }
   else if(profit < 0.0)
   {
      g_stats[statsIndex].losses++;
      g_stats[statsIndex].grossLoss += MathAbs(profit);
   }
   else
   {
      g_stats[statsIndex].breakeven++;
   }

   if(first || profit > g_stats[statsIndex].bestTrade)
      g_stats[statsIndex].bestTrade = profit;

   if(first || profit < g_stats[statsIndex].worstTrade)
      g_stats[statsIndex].worstTrade = profit;

   double pf = (g_stats[statsIndex].grossLoss > 0.0 ? g_stats[statsIndex].grossProfit / g_stats[statsIndex].grossLoss : 0.0);

   DebugPrint("CLOSED",
              StringFormat("%s pnl=%.2f closed=%d wins=%d losses=%d net=%.2f pf=%.2f",
                           g_stats[statsIndex].tag,
                           profit,
                           (int)g_stats[statsIndex].closed,
                           (int)g_stats[statsIndex].wins,
                           (int)g_stats[statsIndex].losses,
                           g_stats[statsIndex].netProfit,
                           pf));
}

string StatLine(const SetupStat &s)
{
   double winRate = (s.closed > 0 ? (double)s.wins * 100.0 / (double)s.closed : 0.0);
   double pf = 0.0;
   if(s.grossLoss > 0.0)
      pf = s.grossProfit / s.grossLoss;
   else if(s.grossProfit > 0.0)
      pf = 999.0;

   return StringFormat("%-13s App:%4d Exec:%4d Cl:%4d W:%3d L:%3d Win:%6.2f Net:%8.2f PF:%6.2f",
                       s.tag,
                       (int)s.appearances,
                       (int)s.executed,
                       (int)s.closed,
                       (int)s.wins,
                       (int)s.losses,
                       winRate,
                       s.netProfit,
                       pf);
}

void AddGroupLine(string &out, const string name, const int first, const int second)
{
   long app = g_stats[first].appearances + g_stats[second].appearances;
   long exec = g_stats[first].executed + g_stats[second].executed;
   long closed = g_stats[first].closed + g_stats[second].closed;
   long wins = g_stats[first].wins + g_stats[second].wins;
   long losses = g_stats[first].losses + g_stats[second].losses;
   double net = g_stats[first].netProfit + g_stats[second].netProfit;
   double gp = g_stats[first].grossProfit + g_stats[second].grossProfit;
   double gl = g_stats[first].grossLoss + g_stats[second].grossLoss;
   double winRate = (closed > 0 ? (double)wins * 100.0 / (double)closed : 0.0);
   double pf = 0.0;
   if(gl > 0.0)
      pf = gp / gl;
   else if(gp > 0.0)
      pf = 999.0;

   out += StringFormat("%-13s App:%4d Exec:%4d Cl:%4d W:%3d L:%3d Win:%6.2f Net:%8.2f PF:%6.2f\n",
                       name,
                       (int)app,
                       (int)exec,
                       (int)closed,
                       (int)wins,
                       (int)losses,
                       winRate,
                       net,
                       pf);
}

void AddAllQMGroupLine(string &out)
{
   long app = 0;
   long exec = 0;
   long closed = 0;
   long wins = 0;
   long losses = 0;
   double net = 0.0;
   double gp = 0.0;
   double gl = 0.0;

   for(int i = 0; i <= 9; i++)
   {
      app += g_stats[i].appearances;
      exec += g_stats[i].executed;
      closed += g_stats[i].closed;
      wins += g_stats[i].wins;
      losses += g_stats[i].losses;
      net += g_stats[i].netProfit;
      gp += g_stats[i].grossProfit;
      gl += g_stats[i].grossLoss;
   }

   double winRate = (closed > 0 ? (double)wins * 100.0 / (double)closed : 0.0);
   double pf = 0.0;
   if(gl > 0.0)
      pf = gp / gl;
   else if(gp > 0.0)
      pf = 999.0;

   out += StringFormat("%-13s App:%4d Exec:%4d Cl:%4d W:%3d L:%3d Win:%6.2f Net:%8.2f PF:%6.2f\n",
                       "ALL_QM_CORE",
                       (int)app,
                       (int)exec,
                       (int)closed,
                       (int)wins,
                       (int)losses,
                       winRate,
                       net,
                       pf);
}

void AddAllModelsLine(string &out)
{
   long app = 0;
   long exec = 0;
   long closed = 0;
   long wins = 0;
   long losses = 0;
   double net = 0.0;
   double gp = 0.0;
   double gl = 0.0;

   for(int i = 0; i < ArraySize(g_stats); i++)
   {
      app += g_stats[i].appearances;
      exec += g_stats[i].executed;
      closed += g_stats[i].closed;
      wins += g_stats[i].wins;
      losses += g_stats[i].losses;
      net += g_stats[i].netProfit;
      gp += g_stats[i].grossProfit;
      gl += g_stats[i].grossLoss;
   }

   double winRate = (closed > 0 ? (double)wins * 100.0 / (double)closed : 0.0);
   double pf = 0.0;
   if(gl > 0.0)
      pf = gp / gl;
   else if(gp > 0.0)
      pf = 999.0;

   out += StringFormat("%-13s App:%4d Exec:%4d Cl:%4d W:%3d L:%3d Win:%6.2f Net:%8.2f PF:%6.2f\n",
                       "ALL_MODELS",
                       (int)app,
                       (int)exec,
                       (int)closed,
                       (int)wins,
                       (int)losses,
                       winRate,
                       net,
                       pf);
}

int DateKey(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   return dt.year * 10000 + dt.mon * 100 + dt.day;
}

datetime NextBarTime()
{
   datetime bt = iTime(_Symbol, InpExecutionTF, 0);
   int sec = PeriodSeconds(InpExecutionTF);
   if(sec <= 0)
      sec = 300;
   return bt + sec * MathMax(1, InpRetryCooldownBars);
}

double PointValue()
{
   double p = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(p <= 0.0)
      p = _Point;
   return p;
}

double PipValue()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5)
      return PointValue() * 10.0;
   return PointValue();
}

double NormalizePrice(double price)
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

int VolumeDigitsByStep(double step)
{
   if(step <= 0.0)
      return 2;

   int digits = 0;
   double s = step;
   while(digits < 8 && MathAbs(s - MathRound(s)) > 0.00000001)
   {
      s *= 10.0;
      digits++;
   }
   return digits;
}

double NormalizeVolume(double volume)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0)
      step = 0.01;

   volume = MathFloor(volume / step) * step;
   volume = MathMax(minLot, MathMin(maxLot, volume));

   return NormalizeDouble(volume, VolumeDigitsByStep(step));
}

bool IsNewBar()
{
   datetime t = iTime(_Symbol, InpExecutionTF, 0);
   if(t <= 0)
      return false;

   if(g_lastBarTime == 0)
   {
      g_lastBarTime = t;
      return true;
   }

   if(t != g_lastBarTime)
   {
      g_lastBarTime = t;
      return true;
   }

   return false;
}

bool GetBufferValue(const int handle, const int buffer, const int shift, double &value)
{
   value = 0.0;
   if(handle == INVALID_HANDLE)
      return false;

   double data[];
   ArraySetAsSeries(data, true);
   int copied = CopyBuffer(handle, buffer, shift, 1, data);
   if(copied < 1)
      return false;

   value = data[0];
   return true;
}

double ATRValue(const int shift)
{
   double v = 0.0;
   if(GetBufferValue(g_atrHandle, 0, shift, v) && v > 0.0)
      return v;

   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, InpExecutionTF, 0, 10, r) >= 3)
      return MathMax(r[1].high - r[1].low, PointValue() * 100.0);

   return PointValue() * 100.0;
}

bool ActiveKeyExists(const string key)
{
   for(int i = 0; i < g_activeCount; i++)
   {
      if(g_active[i].key == key)
         return true;
   }
   return false;
}

bool ArchiveKeyExists(const string key)
{
   for(int i = 0; i < g_archiveCount; i++)
   {
      if(g_archive[i].key == key)
         return true;
   }
   return false;
}

void DeleteZoneObjects(const Zone &z)
{
   string base = g_prefix + z.shortTag + "_";
   ObjectsDeleteAll(0, base);
}

void PushArchive(const Zone &src)
{
   Zone z;
   z = src;
   z.terminalTime = TimeCurrent();

   if(!InpDrawTerminalZones)
      DeleteZoneObjects(z);

   if(g_archiveCount < InpTerminalArchiveMax)
   {
      g_archive[g_archiveCount] = z;
      g_archiveCount++;
      return;
   }

   Zone purged;
   purged = g_archive[0];

   for(int i = 1; i < g_archiveCount; i++)
      g_archive[i - 1] = g_archive[i];

   g_archive[g_archiveCount - 1] = z;

   DebugPrint("TERMINAL_PURGED",
              StringFormat("%s %s archive capacity", StateName(purged.state), purged.key));
}

void RemoveActiveAt(const int index)
{
   if(index < 0 || index >= g_activeCount)
      return;

   for(int i = index + 1; i < g_activeCount; i++)
      g_active[i - 1] = g_active[i];

   g_activeCount--;
}

void MoveActiveToTerminal(const int index, const int terminalState, const string reason)
{
   if(index < 0 || index >= g_activeCount)
      return;

   Zone z = g_active[index];
   z.state = terminalState;
   z.lastUpdateTime = TimeCurrent();
   z.terminalTime = TimeCurrent();

   PushArchive(z);
   RemoveActiveAt(index);

   if(InpPrintDebug)
      Print("[", InpEAName, "] ", StateName(terminalState), " ", z.key, " ", reason);
}

void PurgeArchive()
{
   if(g_archiveCount <= 0)
      return;

   int sec = PeriodSeconds(InpExecutionTF);
   if(sec <= 0)
      sec = 300;

   datetime cutoff = TimeCurrent() - sec * InpTerminalRegistryPurgeBars;
   int write = 0;

   for(int i = 0; i < g_archiveCount; i++)
   {
      bool purgeByAge = (g_archive[i].terminalTime > 0 && g_archive[i].terminalTime < cutoff);
      if(purgeByAge)
      {
         DeleteZoneObjects(g_archive[i]);
         DebugPrint("TERMINAL_PURGED",
                    StringFormat("%s %s age", StateName(g_archive[i].state), g_archive[i].key));
         continue;
      }

      if(write != i)
         g_archive[write] = g_archive[i];

      write++;
   }

   g_archiveCount = write;
}

void ExpireActiveZones()
{
   for(int i = g_activeCount - 1; i >= 0; i--)
   {
      if(g_active[i].state == STATE_TRIGGERED)
         continue;

      if(g_active[i].expiryTime > 0 && TimeCurrent() > g_active[i].expiryTime)
      {
         MoveActiveToTerminal(i, STATE_EXPIRED, "expiry");
         continue;
      }

      if(g_active[i].state == STATE_ARMED &&
         g_active[i].tempBlocks >= InpTemporaryBlockExpiryBars)
      {
         string blockReason = g_active[i].lastBlockReason;
         bool isSessionWait = (StringFind(blockReason, "session") >= 0);
         bool isPositionWait = (StringFind(blockReason, "position exists") >= 0);
         bool isSpacingWait = (StringFind(blockReason, "spacing") >= 0);

         if(!isSessionWait && !isPositionWait && !isSpacingWait)
         {
            MoveActiveToTerminal(i, STATE_DEFERRED, "too many temporary blocks");
            continue;
         }
      }
   }
}

int CountLiveByDirection(const int direction)
{
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      long type = PositionGetInteger(POSITION_TYPE);
      if(direction == DIR_BUY && type == POSITION_TYPE_BUY)
         count++;
      if(direction == DIR_SELL && type == POSITION_TYPE_SELL)
         count++;
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(!OrderSelect(ticket))
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      if((ulong)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
         continue;

      long type = OrderGetInteger(ORDER_TYPE);
      if(direction == DIR_BUY &&
         (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_STOP_LIMIT))
         count++;

      if(direction == DIR_SELL &&
         (type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_SELL_STOP || type == ORDER_TYPE_SELL_STOP_LIMIT))
         count++;
   }

   return count;
}

bool AnyPositionForSymbol()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return true;
   }

   return false;
}

bool PendingForDirection(const int direction)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(!OrderSelect(ticket))
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      if((ulong)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
         continue;

      long type = OrderGetInteger(ORDER_TYPE);
      if(direction == DIR_BUY &&
         (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_STOP_LIMIT))
         return true;

      if(direction == DIR_SELL &&
         (type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_SELL_STOP || type == ORDER_TYPE_SELL_STOP_LIMIT))
         return true;
   }

   return false;
}

bool PositionExistsByTag(const string tag)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      string comment = PositionGetString(POSITION_COMMENT);
      if(StringFind(comment, tag) >= 0)
         return true;
   }

   return false;
}

bool HistoryHasEntryByTag(const string tag, const datetime fromTime)
{
   datetime start = fromTime - 86400;
   if(start < 0)
      start = 0;

   if(!HistorySelect(start, TimeCurrent()))
      return false;

   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;

      if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
         continue;

      if((ulong)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagicNumber)
         continue;

      string comment = HistoryDealGetString(deal, DEAL_COMMENT);
      if(StringFind(comment, tag) < 0)
         continue;

      long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_INOUT)
         return true;
   }

   return false;
}

void CancelAllPending()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(!OrderSelect(ticket))
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      if((ulong)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
         continue;

      trade.OrderDelete(ticket);
   }
}

void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      trade.PositionClose(ticket);
   }
}

void ResetDailyGuardIfNeeded()
{
   int key = DateKey(TimeCurrent());
   if(g_dayKey == -1)
   {
      g_dayKey = key;
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      return;
   }

   if(key != g_dayKey)
   {
      g_dayKey = key;
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_softDDLock = false;
      g_hardDDLock = false;

      DebugPrint("DAILY_RESET",
                 StringFormat("DayStartBalance=%.2f", g_dayStartBalance));
   }
}

GuardState CurrentGuardState()
{
   GuardState gs;
   gs.hardLocked = false;
   gs.softLocked = false;
   gs.reason = "";

   if(!InpUsePropFirmGuards)
      return gs;

   ResetDailyGuardIfNeeded();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyLoss = g_dayStartBalance - equity;
   double overallLoss = InpPropAccountSize - equity;
   double dailyPct = 0.0;
   double overallPct = 0.0;

   if(g_dayStartBalance > 0.0)
      dailyPct = dailyLoss / g_dayStartBalance * 100.0;

   if(InpPropAccountSize > 0.0)
      overallPct = overallLoss / InpPropAccountSize * 100.0;

   if(dailyLoss >= InpDailyHardStopMoney || dailyPct >= InpMaxDailyDDPercent)
   {
      gs.hardLocked = true;
      gs.reason = StringFormat("daily hard dd %.2f %.2f%%", dailyLoss, dailyPct);
   }
   else if(overallLoss >= InpOverallHardStopMoney || overallPct >= InpMaxOverallDDPercent)
   {
      gs.hardLocked = true;
      gs.reason = StringFormat("overall hard dd %.2f %.2f%%", overallLoss, overallPct);
   }
   else if(dailyLoss >= InpDailySoftStopMoney)
   {
      gs.softLocked = true;
      gs.reason = StringFormat("daily soft dd %.2f", dailyLoss);
   }
   else if(overallLoss >= InpOverallSoftStopMoney)
   {
      gs.softLocked = true;
      gs.reason = StringFormat("overall soft dd %.2f", overallLoss);
   }

   if(gs.hardLocked)
   {
      if(!g_hardDDLock)
      {
         g_hardDDLock = true;
         DebugPrint("BLOCKED_TEMP", gs.reason);

         if(InpCancelPendingOnDDLock)
            CancelAllPending();

         if(InpClosePositionsOnHardDD)
            CloseAllPositions();
      }
   }
   else if(gs.softLocked)
   {
      if(!g_softDDLock)
      {
         g_softDDLock = true;
         DebugPrint("BLOCKED_TEMP", gs.reason);
      }
   }

   return gs;
}

bool SessionAllowed()
{
   if(!InpUseSessionFilter)
      return true;

   if(InpTesterIgnoreSession && MQLInfoInteger(MQL_TESTER))
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;

   bool london = (h >= InpLondonStartHour && h < InpLondonEndHour);
   bool ny     = (h >= InpNYStartHour && h < InpNYEndHour);

   return (london || ny);
}

int CurrentSpreadPoints()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double p = PointValue();

   if(ask <= 0.0 || bid <= 0.0 || p <= 0.0)
      return 999999;

   return (int)MathRound((ask - bid) / p);
}

bool IsSwingHigh(const MqlRates &rates[], const int i, const int lr)
{
   double v = rates[i].high;
   for(int k = 1; k <= lr; k++)
   {
      if(rates[i - k].high >= v)
         return false;
      if(rates[i + k].high > v)
         return false;
   }
   return true;
}

bool IsSwingLow(const MqlRates &rates[], const int i, const int lr)
{
   double v = rates[i].low;
   for(int k = 1; k <= lr; k++)
   {
      if(rates[i - k].low <= v)
         return false;
      if(rates[i + k].low < v)
         return false;
   }
   return true;
}

bool OBVIsFlat()
{
   if(g_obvHandle == INVALID_HANDLE)
      return false;

   int bars = MathMax(3, InpOBVFlatBars);
   double obv[];
   ArraySetAsSeries(obv, true);

   if(CopyBuffer(g_obvHandle, 0, 1, bars, obv) < bars)
      return false;

   double hi = obv[0];
   double lo = obv[0];

   for(int i = 1; i < bars; i++)
   {
      hi = MathMax(hi, obv[i]);
      lo = MathMin(lo, obv[i]);
   }

   double base = MathMax(1.0, MathAbs(obv[0]));
   double range = MathAbs(hi - lo);

   return (range / base <= InpOBVFlatThreshold);
}

bool RSIConfirm(const int direction, const int shift)
{
   if(!InpUseRSIDivergence)
      return true;

   double r1 = 0.0;
   double r2 = 0.0;

   if(!GetBufferValue(g_rsiHandle, 0, shift, r1))
      return false;
   if(!GetBufferValue(g_rsiHandle, 0, shift + MathMax(3, InpSwingLeftRight + 1), r2))
      return false;

   if(direction == DIR_BUY)
      return (r1 > r2 || r1 < 35.0);

   return (r1 < r2 || r1 > 65.0);
}

bool MACDConfirm(const int direction, const int shift)
{
   if(!InpUseMACDDivergence)
      return true;

   double main1 = 0.0;
   double main2 = 0.0;

   if(!GetBufferValue(g_macdHandle, 0, shift, main1))
      return false;
   if(!GetBufferValue(g_macdHandle, 0, shift + MathMax(3, InpSwingLeftRight + 1), main2))
      return false;

   if(direction == DIR_BUY)
      return (main1 > main2);

   return (main1 < main2);
}

int CountCrowdedSameDirection(const int direction, const double entry)
{
   int count = 0;
   double p = PointValue();
   double maxDist = InpCrowdedZoneDistancePts * p;

   for(int i = 0; i < g_activeCount; i++)
   {
      if(g_active[i].direction != direction)
         continue;

      if(MathAbs(g_active[i].entry - entry) <= maxDist)
         count++;
   }

   return count;
}

bool WasQMLTouchedAfterPivot(const MqlRates &rates[], const int pivotShift, const int direction, const double entry)
{
   for(int i = pivotShift - 1; i >= 1; i--)
   {
      if(direction == DIR_BUY && rates[i].low <= entry)
         return true;

      if(direction == DIR_SELL && rates[i].high >= entry)
         return true;
   }

   return false;
}

int FindOlderSwingLow(const MqlRates &rates[], const int startShift, const int maxShift, const int lr)
{
   int total = ArraySize(rates);
   int upper = MathMin(maxShift, total - lr - 2);

   for(int i = startShift; i <= upper; i++)
   {
      if(IsSwingLow(rates, i, lr))
         return i;
   }

   return -1;
}

int FindOlderSwingHigh(const MqlRates &rates[], const int startShift, const int maxShift, const int lr)
{
   int total = ArraySize(rates);
   int upper = MathMin(maxShift, total - lr - 2);

   for(int i = startShift; i <= upper; i++)
   {
      if(IsSwingHigh(rates, i, lr))
         return i;
   }

   return -1;
}

bool BreakConfirmedAfterHead(const MqlRates &rates[], const int headShift, const int direction, const double breakLevel, const double buffer)
{
   int latest = MathMax(1, headShift - 1);

   for(int i = latest; i >= 1; i--)
   {
      if(direction == DIR_BUY)
      {
         if(rates[i].close > breakLevel + buffer || rates[i].high > breakLevel + buffer)
            return true;
      }
      else
      {
         if(rates[i].close < breakLevel - buffer || rates[i].low < breakLevel - buffer)
            return true;
      }
   }

   return false;
}

bool IsStructuralQM(const MqlRates &rates[], const int shift, const int direction, const double atr)
{
   if(!InpRequireStructuralQM)
      return IsPremiumQMStructure(rates, shift, direction, atr);

   if(atr <= 0.0)
      return false;

   int lr = MathMax(1, InpSwingLeftRight);
   int maxShift = shift + MathMax(20, InpQMStructureLookbackBars);
   double headBuffer = MathMax(atr * InpQMHeadBreakATR, 5.0 * PointValue());
   double breakBuffer = MathMax(atr * InpQMBreakConfirmATR, 3.0 * PointValue());

   if(direction == DIR_BUY)
   {
      int olderLow = FindOlderSwingLow(rates, shift + lr + 1, maxShift, lr);
      int olderHigh = FindOlderSwingHigh(rates, shift + lr + 1, maxShift, lr);

      if(olderLow < 0 || olderHigh < 0)
         return false;

      bool headMadeLL = (rates[shift].low < rates[olderLow].low - headBuffer);
      bool brokeNeck  = BreakConfirmedAfterHead(rates, shift, DIR_BUY, rates[olderHigh].high, breakBuffer);

      if(!headMadeLL || !brokeNeck)
         return false;

      return IsPremiumQMStructure(rates, shift, direction, atr);
   }

   int oldHigh = FindOlderSwingHigh(rates, shift + lr + 1, maxShift, lr);
   int oldLow  = FindOlderSwingLow(rates, shift + lr + 1, maxShift, lr);

   if(oldHigh < 0 || oldLow < 0)
      return false;

   bool headMadeHH = (rates[shift].high > rates[oldHigh].high + headBuffer);
   bool brokeNeck  = BreakConfirmedAfterHead(rates, shift, DIR_SELL, rates[oldLow].low, breakBuffer);

   if(!headMadeHH || !brokeNeck)
      return false;

   return IsPremiumQMStructure(rates, shift, direction, atr);
}

bool IsPremiumQMStructure(const MqlRates &rates[], const int shift, const int direction, const double atr)
{
   double body = MathAbs(rates[shift].close - rates[shift].open);
   double range = rates[shift].high - rates[shift].low;
   if(range <= 0.0 || atr <= 0.0)
      return false;

   double upper = rates[shift].high - MathMax(rates[shift].open, rates[shift].close);
   double lower = MathMin(rates[shift].open, rates[shift].close) - rates[shift].low;

   double bodyRatio = body / range;
   double upperRatio = upper / range;
   double lowerRatio = lower / range;

   bool sizeOk = (range >= atr * 0.20 && range <= atr * 2.20);
   bool bodyOk = (bodyRatio >= 0.08 && bodyRatio <= 0.82);
   bool rejectionOk = false;

   if(direction == DIR_BUY)
      rejectionOk = (lowerRatio >= 0.08 || rates[shift].low < rates[shift + 1].low);
   else
      rejectionOk = (upperRatio >= 0.08 || rates[shift].high > rates[shift + 1].high);

   return (sizeOk && bodyOk && rejectionOk);
}

int ChooseSetupType(const MqlRates &rates[], const int shift, const int direction, const double atr)
{
   double body = MathAbs(rates[shift].close - rates[shift].open);
   double range = rates[shift].high - rates[shift].low;
   double upper = rates[shift].high - MathMax(rates[shift].open, rates[shift].close);
   double lower = MathMin(rates[shift].open, rates[shift].close) - rates[shift].low;

   double bodyRatio = (range > 0.0 ? body / range : 0.0);
   double upperRatio = (range > 0.0 ? upper / range : 0.0);
   double lowerRatio = (range > 0.0 ? lower / range : 0.0);

   bool rsiOk = RSIConfirm(direction, shift);
   bool macdOk = MACDConfirm(direction, shift);

   if(IsStructuralQM(rates, shift, direction, atr))
      return SETUP_QM;

   if(range > atr * 1.95)
      return SETUP_MEF;

   if(direction == DIR_SELL && upperRatio >= 0.62)
      return SETUP_FAKEOUT;

   if(direction == DIR_BUY && lowerRatio >= 0.62)
      return SETUP_FAKEOUT;

   if(bodyRatio <= 0.25 &&
      ((direction == DIR_BUY && lowerRatio >= 0.30) || (direction == DIR_SELL && upperRatio >= 0.30)))
      return SETUP_QMM;

   if(rsiOk && macdOk)
      return SETUP_QMC;

   if(rsiOk && !macdOk)
      return SETUP_IQM;

   if(!rsiOk && macdOk)
      return SETUP_QMR;

   return SETUP_QMR;
}

int ScoreZone(Zone &z, const MqlRates &rates[], const int shift)
{
   int score = (z.setupType == SETUP_QM ? InpQMPremiumBaseScore + InpQMPremiumScoreBoost : 68);

   double body = MathAbs(rates[shift].close - rates[shift].open);
   double range = rates[shift].high - rates[shift].low;
   double upper = rates[shift].high - MathMax(rates[shift].open, rates[shift].close);
   double lower = MathMin(rates[shift].open, rates[shift].close) - rates[shift].low;

   if(range > 0.0)
   {
      if(z.direction == DIR_BUY && lower / range >= 0.35)
         score += 8;

      if(z.direction == DIR_SELL && upper / range >= 0.35)
         score += 8;

      if(body / range <= 0.35)
         score += 4;
   }

   if(z.rr >= InpMinimumRR)
      score += 8;
   else
      score -= 12;

   bool rsiConfirmed = RSIConfirm(z.direction, shift);
   bool macdConfirmed = MACDConfirm(z.direction, shift);

   if(z.setupType == SETUP_QM && InpQMIgnoreMissingConfirmPenalty)
   {
      if(rsiConfirmed)
         score += 4;
      if(macdConfirmed)
         score += 4;
   }
   else
   {
      if(rsiConfirmed)
         score += 6;
      else
         score -= 4;

      if(macdConfirmed)
         score += 5;
      else
         score -= 4;
   }

   z.flatOBV = false;
   if(InpUseOBVConfirmation)
   {
      z.flatOBV = OBVIsFlat();
      if(z.flatOBV)
         score -= InpFlatOBVPenalty;
      else
         score += 3;
   }

   if(InpUseScorePenalties)
   {
      z.lateEntry = (shift > InpLateEntryBars);
      z.touchedQML = WasQMLTouchedAfterPivot(rates, shift, z.direction, z.entry);

      double slPts = MathAbs(z.entry - z.sl) / PointValue();
      z.wideSL = (slPts > InpWideSLPenaltyThresholdPts);

      int crowded = CountCrowdedSameDirection(z.direction, z.entry);
      z.crowded = (crowded >= InpCrowdedZoneMaxCount);

      int latePenalty = InpLateEntryPenalty;
      int touchedPenalty = InpTouchedQMLPenalty;
      int widePenalty = InpWideSLPenalty;
      int crowdedPenalty = InpCrowdedZonePenalty;

      if(z.setupType == SETUP_QM)
      {
         latePenalty = 2;
         touchedPenalty = 0;
         widePenalty = 0;
         crowdedPenalty = 2;
      }

      if(z.lateEntry)
         score -= latePenalty;

      if(z.touchedQML)
         score -= touchedPenalty;

      if(z.wideSL)
         score -= widePenalty;

      if(z.crowded)
         score -= crowdedPenalty;
   }

   score = MathMax(0, MathMin(100, score));
   return score;
}

bool BuildZoneFromPivot(const MqlRates &rates[], const int shift, const int direction, Zone &z)
{
   double atr = ATRValue(shift);
   double p = PointValue();
   double slBuffer = InpSLBufferPips * PipValue();

   ZeroMemory(z);

   z.id = g_nextZoneId;
   z.direction = direction;
   z.setupTime = rates[shift].time;
   z.createdTime = TimeCurrent();
   z.lastUpdateTime = TimeCurrent();
   z.expiryTime = TimeCurrent() + PeriodSeconds(InpExecutionTF) * InpPendingExpiryBars;
   z.setupBarShift = shift;
   z.state = STATE_CANDIDATE;
   z.atr = atr;
   z.orderTicket = 0;
   z.positionTicket = 0;
   z.retries = 0;
   z.tempBlocks = 0;
   z.lastBlockReason = "";

   z.setupType = ChooseSetupType(rates, shift, direction, atr);

   if(direction == DIR_BUY)
   {
      z.entry = rates[shift].low + atr * InpEntryATRMultiplier;
      z.sl = rates[shift].low - atr * InpSLATRMultiplier - slBuffer;
      double risk = MathAbs(z.entry - z.sl);
      if(risk < p * 10.0)
         return false;

      z.tp = z.entry + risk * MathMax(InpTargetRR, InpMinimumRR);
      z.zoneLow = MathMin(rates[shift].low, z.entry);
      z.zoneHigh = MathMax(z.entry + atr * InpEntryATRMultiplier, z.entry);
   }
   else
   {
      z.entry = rates[shift].high - atr * InpEntryATRMultiplier;
      z.sl = rates[shift].high + atr * InpSLATRMultiplier + slBuffer;
      double risk = MathAbs(z.sl - z.entry);
      if(risk < p * 10.0)
         return false;

      z.tp = z.entry - risk * MathMax(InpTargetRR, InpMinimumRR);
      z.zoneHigh = MathMax(rates[shift].high, z.entry);
      z.zoneLow = MathMin(z.entry - atr * InpEntryATRMultiplier, z.entry);
   }

   z.entry = NormalizePrice(z.entry);
   z.sl = NormalizePrice(z.sl);
   z.tp = NormalizePrice(z.tp);
   z.zoneHigh = NormalizePrice(z.zoneHigh);
   z.zoneLow = NormalizePrice(z.zoneLow);

   double riskAbs = MathAbs(z.entry - z.sl);
   double rewardAbs = MathAbs(z.tp - z.entry);
   if(riskAbs <= 0.0)
      return false;

   z.rr = rewardAbs / riskAbs;

   z.shortTag = StringFormat("%s_%I64u", SetupName(z.setupType), z.id);
   z.key = StringFormat("%s_%s_%I64d",
                        DirectionName(direction),
                        SetupName(z.setupType),
                        (long)z.setupTime);

   z.score = ScoreZone(z, rates, shift);

   return true;
}

bool AddCandidateZone(Zone &z)
{
   StatsAddAppearance(z.setupType, z.direction);

   if(!FamilyEnabled(z.setupType))
   {
      StatsAddRejectedScore(z.setupType, z.direction);
      DebugPrint("REJECTED_DISABLED",
                 StringFormat("%s disabled by input", SetupTag(z.setupType, z.direction)));
      return false;
   }

   int candidateMin = CandidateScoreMin(z.setupType);
   if(z.score < candidateMin)
   {
      StatsAddRejectedScore(z.setupType, z.direction);
      DebugPrint("REJECTED_SCORE",
                 StringFormat("%s @ %.2f S=%d min=%d",
                              SetupTag(z.setupType, z.direction),
                              z.entry,
                              z.score,
                              candidateMin));
      return false;
   }

   if(ActiveKeyExists(z.key) || ArchiveKeyExists(z.key))
      return false;

   if(g_activeCount >= InpMaxZones)
   {
      g_lastSkip = "active registry full";
      DebugPrint("BLOCKED_TEMP",
                 StringFormat("active registry full %s", z.key));
      return false;
   }

   g_active[g_activeCount] = z;
   g_activeCount++;
   g_nextZoneId++;
   StatsAddRegistered(z.setupType, z.direction);

   DebugPrint("REGISTERED",
              StringFormat("%s @ %.2f S=%d RR=%.2f active=%d/%d",
                           SetupTag(z.setupType, z.direction),
                           z.entry,
                           z.score,
                           z.rr,
                           g_activeCount,
                           InpMaxZones));
   return true;
}

void ScanForSetups()
{
   if(g_activeCount >= InpMaxZones)
   {
      g_lastSkip = "scan skipped active full";
      return;
   }

   int needBars = MathMax(InpLookbackBars, InpSwingLeftRight * 2 + 20);
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, InpExecutionTF, 0, needBars, rates);
   if(copied < InpSwingLeftRight * 2 + 10)
      return;

   int maxShift = MathMin(copied - InpSwingLeftRight - 1, InpMaxBarsAfterBreak);
   int registeredNow = 0;

   for(int shift = InpSwingLeftRight + 1; shift <= maxShift; shift++)
   {
      if(g_activeCount >= InpMaxZones)
         break;

      if(IsSwingLow(rates, shift, InpSwingLeftRight))
      {
         Zone z;
         if(BuildZoneFromPivot(rates, shift, DIR_BUY, z))
         {
            if(AddCandidateZone(z))
               registeredNow++;
         }
      }

      if(g_activeCount >= InpMaxZones)
         break;

      if(IsSwingHigh(rates, shift, InpSwingLeftRight))
      {
         Zone z;
         if(BuildZoneFromPivot(rates, shift, DIR_SELL, z))
         {
            if(AddCandidateZone(z))
               registeredNow++;
         }
      }

      if(registeredNow >= 6)
         break;
   }
}

void UpdateArmedState()
{
   for(int i = 0; i < g_activeCount; i++)
   {
      if(g_active[i].state != STATE_CANDIDATE)
         continue;

      int tradeMin = TradeScoreMin(g_active[i].setupType);
      if(g_active[i].score >= tradeMin)
      {
         g_active[i].state = STATE_ARMED;
         g_active[i].lastUpdateTime = TimeCurrent();
         StatsAddArmed(g_active[i].setupType, g_active[i].direction);

         DebugPrint("ARMED",
                    StringFormat("%s S=%d RR=%.2f key=%s",
                                 SetupTag(g_active[i].setupType, g_active[i].direction),
                                 g_active[i].score,
                                 g_active[i].rr,
                                 g_active[i].key));
      }
   }
}

double CalculateLotForPrices(const double entry, const double sl, string &reason)
{
   reason = "";

   if(InpFixedLot > 0.0)
      return NormalizeVolume(InpFixedLot);

   double equityRef = AccountInfoDouble(ACCOUNT_BALANCE);
   if(InpPropAccountSize > 0.0)
      equityRef = MathMin(equityRef, InpPropAccountSize);

   double riskMoney = equityRef * InpRiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double slDistance = MathAbs(entry - sl);

   if(riskMoney <= 0.0 || tickValue <= 0.0 || tickSize <= 0.0 || slDistance <= 0.0)
   {
      reason = StringFormat("bad lot inputs riskMoney=%.2f tickValue=%.6f tickSize=%.6f dist=%.6f",
                            riskMoney, tickValue, tickSize, slDistance);
      if(InpPrintLotDiagnostics)
         DebugPrint("LOT_BLOCK", reason);
      return 0.0;
   }

   double riskPerLot = (slDistance / tickSize) * tickValue;
   if(riskPerLot <= 0.0)
   {
      reason = StringFormat("riskPerLot invalid %.6f", riskPerLot);
      if(InpPrintLotDiagnostics)
         DebugPrint("LOT_BLOCK", reason);
      return 0.0;
   }

   double rawLot = riskMoney / riskPerLot;

   if(minLot <= 0.0)
      minLot = 0.01;
   if(step <= 0.0)
      step = 0.01;
   if(maxLot <= 0.0)
      maxLot = minLot;

   if(rawLot < minLot)
   {
      double minRisk = minLot * riskPerLot;
      double maxAllowedMinRisk = riskMoney * MathMax(1.0, InpMinLotRiskCapMultiplier);
      if(InpMinLotAbsoluteRiskCap > 0.0)
         maxAllowedMinRisk = MathMax(maxAllowedMinRisk, InpMinLotAbsoluteRiskCap);

      if(InpAllowMinLotWhenRiskLow && minRisk <= maxAllowedMinRisk)
      {
         if(InpPrintLotDiagnostics)
         {
            DebugPrint("LOT_FALLBACK",
                       StringFormat("raw=%.5f min=%.5f minRisk=%.2f planned=%.2f cap=%.2f dist=%.6f",
                                    rawLot, minLot, minRisk, riskMoney, maxAllowedMinRisk, slDistance));
         }
         return NormalizeVolume(minLot);
      }

      reason = StringFormat("rawLot=%.5f below minLot=%.5f minRisk=%.2f planned=%.2f cap=%.2f dist=%.6f",
                            rawLot, minLot, minRisk, riskMoney, maxAllowedMinRisk, slDistance);
      if(InpPrintLotDiagnostics)
         DebugPrint("LOT_BLOCK", reason);
      return 0.0;
   }

   double lot = NormalizeVolume(rawLot);
   if(lot < minLot || lot > maxLot)
   {
      reason = StringFormat("normalized lot invalid raw=%.5f lot=%.5f min=%.5f max=%.5f",
                            rawLot, lot, minLot, maxLot);
      if(InpPrintLotDiagnostics)
         DebugPrint("LOT_BLOCK", reason);
      return 0.0;
   }

   return lot;
}

double CalculateLotByRisk(const Zone &z)
{
   string reason = "";
   return CalculateLotForPrices(z.entry, z.sl, reason);
}

double BrokerMinDistance()
{
   double p = PointValue();
   int stops = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freeze = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   int extra = MathMax(0, InpBrokerMinExtraBufferPts);
   int minPts = MathMax(stops, freeze) + extra;

   if(minPts < 1)
      minPts = extra > 0 ? extra : 5;

   return minPts * p;
}

bool TradeModeAllowsOpen(const int direction, string &reason)
{
   reason = "";

   long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);

   if(mode == SYMBOL_TRADE_MODE_DISABLED)
   {
      reason = "symbol trade disabled";
      return false;
   }

   if(mode == SYMBOL_TRADE_MODE_CLOSEONLY)
   {
      reason = "symbol is close-only; use broker trade-enabled symbol";
      return false;
   }

   if(mode == SYMBOL_TRADE_MODE_LONGONLY && direction == DIR_SELL)
   {
      reason = "symbol long-only; sell blocked";
      return false;
   }

   if(mode == SYMBOL_TRADE_MODE_SHORTONLY && direction == DIR_BUY)
   {
      reason = "symbol short-only; buy blocked";
      return false;
   }

   return true;
}

bool CorrectStopsForMarket(const Zone &z, double &sl, double &tp, string &reason)
{
   reason = "";

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist = BrokerMinDistance();
   double baseRisk = MathAbs(z.entry - z.sl);
   double atrRisk = MathMax(z.atr * InpSLATRMultiplier + InpSLBufferPips * PipValue(), minDist * 2.0);
   double risk = MathMax(baseRisk, atrRisk);
   double rr = MathMax(InpTargetRR, MathMax(InpFallbackRR, InpMinimumRR));

   if(z.direction == DIR_BUY)
   {
      if(sl <= 0.0 || sl >= bid - minDist)
         sl = bid - risk;
      if(tp <= 0.0 || tp <= ask + minDist)
         tp = ask + risk * rr;

      sl = NormalizePrice(sl);
      tp = NormalizePrice(tp);

      if(sl >= bid - minDist)
      {
         reason = "market buy sl too close";
         return false;
      }
      if(tp <= ask + minDist)
      {
         reason = "market buy tp too close";
         return false;
      }
   }
   else
   {
      if(sl <= 0.0 || sl <= ask + minDist)
         sl = ask + risk;
      if(tp <= 0.0 || tp >= bid - minDist)
         tp = bid - risk * rr;

      sl = NormalizePrice(sl);
      tp = NormalizePrice(tp);

      if(sl <= ask + minDist)
      {
         reason = "market sell sl too close";
         return false;
      }
      if(tp >= bid - minDist)
      {
         reason = "market sell tp too close";
         return false;
      }
   }

   return true;
}

bool CorrectStopsForPending(const Zone &z, const ENUM_ORDER_TYPE orderType, double &entry, double &sl, double &tp, string &reason)
{
   reason = "";

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist = BrokerMinDistance();
   double baseRisk = MathAbs(z.entry - z.sl);
   double atrRisk = MathMax(z.atr * InpSLATRMultiplier + InpSLBufferPips * PipValue(), minDist * 2.0);
   double risk = MathMax(baseRisk, atrRisk);
   double rr = MathMax(InpTargetRR, MathMax(InpFallbackRR, InpMinimumRR));

   entry = NormalizePrice(entry);
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   if(orderType == ORDER_TYPE_BUY_LIMIT)
   {
      if(entry >= ask - minDist)
      {
         reason = "buy limit entry too close";
         return false;
      }

      if(sl >= entry - minDist)
         sl = NormalizePrice(entry - risk);
      if(tp <= entry + minDist)
         tp = NormalizePrice(entry + risk * rr);

      if(sl >= entry - minDist || tp <= entry + minDist)
      {
         reason = "buy limit stops invalid";
         return false;
      }
   }
   else if(orderType == ORDER_TYPE_BUY_STOP)
   {
      if(entry <= ask + minDist)
      {
         reason = "buy stop entry too close";
         return false;
      }

      if(sl >= entry - minDist)
         sl = NormalizePrice(entry - risk);
      if(tp <= entry + minDist)
         tp = NormalizePrice(entry + risk * rr);

      if(sl >= entry - minDist || tp <= entry + minDist)
      {
         reason = "buy stop stops invalid";
         return false;
      }
   }
   else if(orderType == ORDER_TYPE_SELL_LIMIT)
   {
      if(entry <= bid + minDist)
      {
         reason = "sell limit entry too close";
         return false;
      }

      if(sl <= entry + minDist)
         sl = NormalizePrice(entry + risk);
      if(tp >= entry - minDist)
         tp = NormalizePrice(entry - risk * rr);

      if(sl <= entry + minDist || tp >= entry - minDist)
      {
         reason = "sell limit stops invalid";
         return false;
      }
   }
   else if(orderType == ORDER_TYPE_SELL_STOP)
   {
      if(entry >= bid - minDist)
      {
         reason = "sell stop entry too close";
         return false;
      }

      if(sl <= entry + minDist)
         sl = NormalizePrice(entry + risk);
      if(tp >= entry - minDist)
         tp = NormalizePrice(entry - risk * rr);

      if(sl <= entry + minDist || tp >= entry - minDist)
      {
         reason = "sell stop stops invalid";
         return false;
      }
   }
   else
   {
      reason = "unsupported pending order type";
      return false;
   }

   return true;
}

bool ResolveExecutionMode(const Zone &z,
                          bool &useMarket,
                          ENUM_ORDER_TYPE &orderType,
                          double &entry,
                          double &sl,
                          double &tp,
                          string &reason)
{
   reason = "";
   useMarket = false;
   orderType = ORDER_TYPE_BUY_LIMIT;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double p = PointValue();
   double minDist = BrokerMinDistance();
   double touchBuffer = MathMax(InpMarketTouchBufferPts * p, minDist);

   entry = NormalizePrice(z.entry);
   sl = NormalizePrice(z.sl);
   tp = NormalizePrice(z.tp);

   if(z.direction == DIR_BUY)
   {
      if(InpUsePendingOrders && entry < ask - minDist)
         orderType = ORDER_TYPE_BUY_LIMIT;
      else if(InpUsePendingOrders && InpUseStopOrdersForBreakout && entry > ask + minDist)
         orderType = ORDER_TYPE_BUY_STOP;
      else if(InpExecuteMarketIfTouched && MathAbs(entry - ask) <= touchBuffer)
         useMarket = true;
      else
      {
         reason = "buy entry not executable yet";
         return false;
      }
   }
   else
   {
      if(InpUsePendingOrders && entry > bid + minDist)
         orderType = ORDER_TYPE_SELL_LIMIT;
      else if(InpUsePendingOrders && InpUseStopOrdersForBreakout && entry < bid - minDist)
         orderType = ORDER_TYPE_SELL_STOP;
      else if(InpExecuteMarketIfTouched && MathAbs(entry - bid) <= touchBuffer)
         useMarket = true;
      else
      {
         reason = "sell entry not executable yet";
         return false;
      }
   }

   if(useMarket)
   {
      if(z.direction == DIR_BUY)
         entry = NormalizePrice(ask);
      else
         entry = NormalizePrice(bid);

      return CorrectStopsForMarket(z, sl, tp, reason);
   }

   return CorrectStopsForPending(z, orderType, entry, sl, tp, reason);
}

void TempBlockZone(const int index, const string reason)
{
   if(index < 0 || index >= g_activeCount)
      return;

   g_active[index].retryAfterTime = NextBarTime();
   g_active[index].tempBlocks++;
   g_active[index].lastBlockReason = reason;
   StatsAddBlocked(g_active[index].setupType, g_active[index].direction);
   g_active[index].lastUpdateTime = TimeCurrent();

   g_lastSkip = reason;

   DebugPrint("BLOCKED_TEMP",
              StringFormat("%s retry=%s key=%s blocks=%d",
                           reason,
                           TimeToString(g_active[index].retryAfterTime, TIME_DATE | TIME_MINUTES),
                           g_active[index].key,
                           g_active[index].tempBlocks));

   bool isSessionWait = (StringFind(reason, "session") >= 0);
   bool isPositionWait = (StringFind(reason, "position exists") >= 0);
   bool isSpacingWait = (StringFind(reason, "spacing") >= 0);

   if(g_active[index].tempBlocks >= InpTemporaryBlockExpiryBars &&
      !isSessionWait && !isPositionWait && !isSpacingWait)
   {
      MoveActiveToTerminal(index, STATE_DEFERRED,
                           StringFormat("repeated block: %s", reason));
   }
}

bool IsWithinExecutionPool(const int zoneIndex)
{
   if(zoneIndex < 0 || zoneIndex >= g_activeCount)
      return false;

   int direction = g_active[zoneIndex].direction;
   int indexes[3];
   double dist[3];

   for(int k = 0; k < 3; k++)
   {
      indexes[k] = -1;
      dist[k] = DBL_MAX;
   }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double mid = (bid + ask) * 0.5;

   for(int i = 0; i < g_activeCount; i++)
   {
      if(g_active[i].state != STATE_ARMED)
         continue;

      if(g_active[i].direction != direction)
         continue;

      double d = MathAbs(g_active[i].entry - mid);

      for(int k = 0; k < 3; k++)
      {
         if(d < dist[k])
         {
            for(int j = 2; j > k; j--)
            {
               dist[j] = dist[j - 1];
               indexes[j] = indexes[j - 1];
            }

            dist[k] = d;
            indexes[k] = i;
            break;
         }
      }
   }

   for(int k = 0; k < 3; k++)
   {
      if(indexes[k] == zoneIndex)
         return true;
   }

   return false;
}

bool SendOrderForZone(const int index)
{
   if(index < 0 || index >= g_activeCount)
      return false;

   Zone z = g_active[index];

   string modeReason = "";
   if(!TradeModeAllowsOpen(z.direction, modeReason))
   {
      TempBlockZone(index, modeReason);
      return false;
   }

   bool useMarket = false;
   ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY_LIMIT;
   double sendEntry = z.entry;
   double sendSL = z.sl;
   double sendTP = z.tp;
   string reason = "";

   if(!ResolveExecutionMode(z, useMarket, orderType, sendEntry, sendSL, sendTP, reason))
   {
      TempBlockZone(index, reason);
      return false;
   }

   string lotReason = "";
   double lot = CalculateLotForPrices(sendEntry, sendSL, lotReason);
   if(lot <= 0.0)
   {
      TempBlockZone(index, StringFormat("risk volume blocked %s", lotReason));
      return false;
   }

   datetime expiry = TimeCurrent() + PeriodSeconds(InpExecutionTF) * InpPendingExpiryBars;

   string comment = StringFormat("%s|%s|%I64u",
                                 InpTradeComment,
                                 SetupTag(z.setupType, z.direction),
                                 z.id);

   bool ok = false;

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippagePoints);

   if(useMarket)
   {
      if(z.direction == DIR_BUY)
         ok = trade.Buy(lot, _Symbol, 0.0, sendSL, sendTP, comment);
      else
         ok = trade.Sell(lot, _Symbol, 0.0, sendSL, sendTP, comment);
   }
   else
   {
      if(orderType == ORDER_TYPE_BUY_LIMIT)
         ok = trade.BuyLimit(lot, sendEntry, _Symbol, sendSL, sendTP, ORDER_TIME_SPECIFIED, expiry, comment);
      else if(orderType == ORDER_TYPE_BUY_STOP)
         ok = trade.BuyStop(lot, sendEntry, _Symbol, sendSL, sendTP, ORDER_TIME_SPECIFIED, expiry, comment);
      else if(orderType == ORDER_TYPE_SELL_LIMIT)
         ok = trade.SellLimit(lot, sendEntry, _Symbol, sendSL, sendTP, ORDER_TIME_SPECIFIED, expiry, comment);
      else if(orderType == ORDER_TYPE_SELL_STOP)
         ok = trade.SellStop(lot, sendEntry, _Symbol, sendSL, sendTP, ORDER_TIME_SPECIFIED, expiry, comment);
   }

   if(!ok)
   {
      int rc = (int)trade.ResultRetcode();
      string msg = StringFormat("ordersend failed rc=%d %s", rc, trade.ResultRetcodeDescription());

      if(rc == 10044)
      {
         g_lastSkip = "symbol close-only / use trade-enabled broker suffix";
         MoveActiveToTerminal(index, STATE_BLOCKED_RISK, msg);
         return false;
      }

      TempBlockZone(index, msg);

      if(rc == 10016)
         g_lastSkip = "invalid stops after correction";

      return false;
   }

   g_active[index].state = STATE_TRIGGERED;
   g_active[index].entry = sendEntry;
   g_active[index].sl = sendSL;
   g_active[index].tp = sendTP;
   g_active[index].orderTicket = trade.ResultOrder();
   g_active[index].positionTicket = trade.ResultDeal();
   g_active[index].lastUpdateTime = TimeCurrent();
   g_lastTradeTime = TimeCurrent();
   StatsAddOrderSent(z.setupType, z.direction);

   DebugPrint("EXECUTED",
              StringFormat("%s lot=%.2f mode=%s entry=%.2f sl=%.2f tp=%.2f ticket=%I64u key=%s",
                           SetupTag(z.setupType, z.direction),
                           lot,
                           useMarket ? "MARKET" : EnumToString(orderType),
                           sendEntry,
                           sendSL,
                           sendTP,
                           trade.ResultOrder(),
                           z.key));
   return true;
}

bool CommonExecutionBlocks(const int index)
{
   if(index < 0 || index >= g_activeCount)
      return true;

   if(TimeCurrent() < g_active[index].retryAfterTime)
      return true;

   GuardState gs = CurrentGuardState();
   if(gs.hardLocked || gs.softLocked)
   {
      TempBlockZone(index, gs.reason);
      return true;
   }

   string modeReason = "";
   if(!TradeModeAllowsOpen(g_active[index].direction, modeReason))
   {
      TempBlockZone(index, modeReason);
      return true;
   }

   if(!SessionAllowed())
   {
      TempBlockZone(index, "session");
      return true;
   }

   int spread = CurrentSpreadPoints();
   if(spread > InpMaxSpreadPoints)
   {
      TempBlockZone(index, StringFormat("spread %d>%d", spread, InpMaxSpreadPoints));
      return true;
   }

   bool testerMode = (MQLInfoInteger(MQL_TESTER) != 0);
   bool ignoreSpacing = (testerMode && InpTesterIgnoreSpacing);
   bool ignoreOnePosition = (testerMode && InpTesterIgnoreOnePosition);

   if(!ignoreSpacing && g_lastTradeTime > 0 && InpMinutesBetweenTrades > 0 && (TimeCurrent() - g_lastTradeTime) < InpMinutesBetweenTrades * 60)
   {
      TempBlockZone(index, "spacing");
      return true;
   }

   if(!ignoreOnePosition && InpOnePositionPerSymbol && AnyPositionForSymbol())
   {
      TempBlockZone(index, "position exists same symbol");
      return true;
   }

   if(InpOnePendingPerDirection && PendingForDirection(g_active[index].direction))
   {
      TempBlockZone(index, "pending exists same direction");
      return true;
   }

   int liveSameDir = CountLiveByDirection(g_active[index].direction);
   if(g_active[index].direction == DIR_BUY && liveSameDir >= InpMaxBuyOrders)
   {
      TempBlockZone(index, "max buy orders");
      return true;
   }

   if(g_active[index].direction == DIR_SELL && liveSameDir >= InpMaxSellOrders)
   {
      TempBlockZone(index, "max sell orders");
      return true;
   }

   if(!IsWithinExecutionPool(index))
   {
      TempBlockZone(index, "outside nearest execution pool");
      return true;
   }

   return false;
}

void ExecuteArmedPool()
{
   if(!InpEnableAutoTrading)
      return;

   int selected[6];
   int count = 0;

   for(int k = 0; k < 6; k++)
      selected[k] = -1;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double mid = (bid + ask) * 0.5;

   for(int pass = 0; pass < 2; pass++)
   {
      int direction = (pass == 0 ? DIR_BUY : DIR_SELL);
      int localIdx[3];
      double localDist[3];

      for(int k = 0; k < 3; k++)
      {
         localIdx[k] = -1;
         localDist[k] = DBL_MAX;
      }

      for(int i = 0; i < g_activeCount; i++)
      {
         if(g_active[i].state != STATE_ARMED)
            continue;

         if(g_active[i].direction != direction)
            continue;

         double d = MathAbs(g_active[i].entry - mid);

         for(int k = 0; k < 3; k++)
         {
            if(d < localDist[k])
            {
               for(int j = 2; j > k; j--)
               {
                  localDist[j] = localDist[j - 1];
                  localIdx[j] = localIdx[j - 1];
               }

               localDist[k] = d;
               localIdx[k] = i;
               break;
            }
         }
      }

      for(int k = 0; k < 3; k++)
      {
         if(localIdx[k] >= 0 && count < 6)
         {
            selected[count] = localIdx[k];
            count++;
         }
      }
   }

   for(int i = 0; i < count; i++)
   {
      int idx = selected[i];
      if(idx < 0 || idx >= g_activeCount)
         continue;

      if(g_active[idx].state != STATE_ARMED)
         continue;

      if(CommonExecutionBlocks(idx))
         continue;

      SendOrderForZone(idx);
   }
}

void ManageTriggeredZones()
{
   for(int i = g_activeCount - 1; i >= 0; i--)
   {
      if(g_active[i].state != STATE_TRIGGERED)
         continue;

      bool orderLive = false;
      if(g_active[i].orderTicket > 0)
         orderLive = OrderSelect(g_active[i].orderTicket);

      bool positionLive = PositionExistsByTag(g_active[i].shortTag);

      if(!orderLive && !positionLive && HistoryHasEntryByTag(g_active[i].shortTag, g_active[i].createdTime))
      {
         MoveActiveToTerminal(i, STATE_USED, "trade completed");
         continue;
      }

      if(!orderLive && !positionLive && g_active[i].expiryTime > 0 && TimeCurrent() > g_active[i].expiryTime)
      {
         MoveActiveToTerminal(i, STATE_EXPIRED, "triggered order expired");
         continue;
      }
   }

   if(InpUseMoneyLockTrailing)
      ApplyMoneyLockTrailing();
}

int TrailTrackIndex(const ulong ticket)
{
   for(int i = 0; i < g_trailTrackCount; i++)
   {
      if(g_trailTickets[i] == ticket)
         return i;
   }

   int idx = g_trailTrackCount;
   ArrayResize(g_trailTickets, idx + 1);
   ArrayResize(g_trailPeakProfits, idx + 1);
   ArrayResize(g_trailLockProfits, idx + 1);
   ArrayResize(g_trailArmed, idx + 1);

   g_trailTickets[idx] = ticket;
   g_trailPeakProfits[idx] = 0.0;
   g_trailLockProfits[idx] = 0.0;
   g_trailArmed[idx] = false;
   g_trailTrackCount = idx + 1;

   return idx;
}

void TrailTrackRemoveAt(const int index)
{
   if(index < 0 || index >= g_trailTrackCount)
      return;

   for(int i = index; i < g_trailTrackCount - 1; i++)
   {
      g_trailTickets[i] = g_trailTickets[i + 1];
      g_trailPeakProfits[i] = g_trailPeakProfits[i + 1];
      g_trailLockProfits[i] = g_trailLockProfits[i + 1];
      g_trailArmed[i] = g_trailArmed[i + 1];
   }

   g_trailTrackCount--;
   ArrayResize(g_trailTickets, g_trailTrackCount);
   ArrayResize(g_trailPeakProfits, g_trailTrackCount);
   ArrayResize(g_trailLockProfits, g_trailTrackCount);
   ArrayResize(g_trailArmed, g_trailTrackCount);
}

void PurgeTrailTracker()
{
   for(int i = g_trailTrackCount - 1; i >= 0; i--)
   {
      if(!PositionSelectByTicket(g_trailTickets[i]))
         TrailTrackRemoveAt(i);
   }
}

void ApplyMoneyLockTrailing()
{
   PurgeTrailTracker();

   double p = PointValue();
   int stops = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freeze = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   int minPts = MathMax(stops, freeze) + MathMax(1, InpBrokerMinExtraBufferPts);
   double minDist = minPts * p;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      int trackIndex = TrailTrackIndex(ticket);

      if(profit > g_trailPeakProfits[trackIndex])
         g_trailPeakProfits[trackIndex] = profit;

      if(!g_trailArmed[trackIndex] && g_trailPeakProfits[trackIndex] >= InpTrailStartMoney)
      {
         g_trailArmed[trackIndex] = true;
         DebugPrint("TRAIL_ARMED", StringFormat("ticket=%I64u peak=%.2f start=%.2f", ticket, g_trailPeakProfits[trackIndex], InpTrailStartMoney));
      }

      if(!g_trailArmed[trackIndex])
         continue;

      long type = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double oldSL = PositionGetDouble(POSITION_SL);
      double oldTP = PositionGetDouble(POSITION_TP);

      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(volume <= 0.0 || tickValue <= 0.0 || tickSize <= 0.0)
         continue;

      double moneyPerPrice = volume * tickValue / tickSize;
      if(moneyPerPrice <= 0.0)
         continue;

      double desiredLock = InpTrailLockMoney;
      if(InpUseActiveMoneyTrail)
         desiredLock = MathMax(InpTrailLockMoney, g_trailPeakProfits[trackIndex] - InpTrailGivebackMoney);

      if(InpTrailStepMoney > 0.0)
         desiredLock = MathFloor(desiredLock / InpTrailStepMoney) * InpTrailStepMoney;

      desiredLock = MathMax(InpTrailLockMoney, desiredLock);

      if(desiredLock < g_trailLockProfits[trackIndex])
         desiredLock = g_trailLockProfits[trackIndex];

      double lockDistance = desiredLock / moneyPerPrice;
      double baseLockDistance = InpTrailLockMoney / moneyPerPrice;
      double newSL = oldSL;
      bool hasBaseProtection = false;
      bool modified = false;

      if(type == POSITION_TYPE_BUY)
      {
         newSL = NormalizePrice(openPrice + lockDistance);
         double baseSL = NormalizePrice(openPrice + baseLockDistance);
         hasBaseProtection = (oldSL > 0.0 && oldSL >= baseSL - p);

         if(newSL > bid - minDist)
         {
            DebugPrint("TRAIL_WAIT", StringFormat("ticket=%I64u profit=%.2f peak=%.2f target=%.2f newSL=%.2f bid=%.2f minDist=%.2f",
                                                ticket, profit, g_trailPeakProfits[trackIndex], desiredLock, newSL, bid, minDist));
         }
         else if(oldSL <= 0.0 || newSL > oldSL + p)
         {
            if(trade.PositionModify(ticket, newSL, oldTP))
            {
               g_trailLockProfits[trackIndex] = desiredLock;
               modified = true;
               DebugPrint("TRAIL_ACTIVE", StringFormat("ticket=%I64u profit=%.2f peak=%.2f locked=%.2f newSL=%.2f tp=%.2f",
                                                   ticket, profit, g_trailPeakProfits[trackIndex], desiredLock, newSL, oldTP));
            }
            else
            {
               DebugPrint("TRAIL_FAIL", StringFormat("ticket=%I64u rc=%d %s", ticket, (int)trade.ResultRetcode(), trade.ResultRetcodeDescription()));
            }
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         newSL = NormalizePrice(openPrice - lockDistance);
         double baseSL = NormalizePrice(openPrice - baseLockDistance);
         hasBaseProtection = (oldSL > 0.0 && oldSL <= baseSL + p);

         if(newSL < ask + minDist)
         {
            DebugPrint("TRAIL_WAIT", StringFormat("ticket=%I64u profit=%.2f peak=%.2f target=%.2f newSL=%.2f ask=%.2f minDist=%.2f",
                                                ticket, profit, g_trailPeakProfits[trackIndex], desiredLock, newSL, ask, minDist));
         }
         else if(oldSL <= 0.0 || newSL < oldSL - p)
         {
            if(trade.PositionModify(ticket, newSL, oldTP))
            {
               g_trailLockProfits[trackIndex] = desiredLock;
               modified = true;
               DebugPrint("TRAIL_ACTIVE", StringFormat("ticket=%I64u profit=%.2f peak=%.2f locked=%.2f newSL=%.2f tp=%.2f",
                                                   ticket, profit, g_trailPeakProfits[trackIndex], desiredLock, newSL, oldTP));
            }
            else
            {
               DebugPrint("TRAIL_FAIL", StringFormat("ticket=%I64u rc=%d %s", ticket, (int)trade.ResultRetcode(), trade.ResultRetcodeDescription()));
            }
         }
      }

      if(InpUseTrailEmergencyClose && !hasBaseProtection && !modified)
      {
         double emergencyCeiling = InpTrailStartMoney + MathMax(0.0, InpTrailEmergencyBandMoney);
         if(profit >= InpTrailLockMoney && profit <= emergencyCeiling)
         {
            if(trade.PositionClose(ticket, (ulong)InpSlippagePoints))
            {
               DebugPrint("TRAIL_EMERGENCY_CLOSE", StringFormat("ticket=%I64u profit=%.2f peak=%.2f baseLock=%.2f",
                                                               ticket, profit, g_trailPeakProfits[trackIndex], InpTrailLockMoney));
               TrailTrackRemoveAt(trackIndex);
            }
            else
            {
               DebugPrint("TRAIL_EMERGENCY_FAIL", StringFormat("ticket=%I64u rc=%d %s", ticket, (int)trade.ResultRetcode(), trade.ResultRetcodeDescription()));
            }
         }
      }
   }
}

color ZoneColor(const Zone &z)
{
   if(z.state == STATE_CANDIDATE)
      return clrDimGray;

   if(z.state == STATE_ARMED)
   {
      if(z.direction == DIR_BUY)
         return clrDodgerBlue;
      return clrMagenta;
   }

   if(z.state == STATE_TRIGGERED)
      return clrGold;

   return clrSilver;
}

void DrawZone(const Zone &z)
{
   if(!InpDrawObjects)
      return;

   if(z.state >= STATE_USED && !InpDrawTerminalZones)
      return;

   string base = g_prefix + z.shortTag + "_";
   string rect = base + "ZONE";
   string ent  = base + "ENTRY";
   string sl   = base + "SL";
   string tp   = base + "TP";
   string txt  = base + "TEXT";

   datetime t1 = z.createdTime;
   datetime t2 = z.expiryTime;

   if(t2 <= t1)
      t2 = t1 + PeriodSeconds(InpExecutionTF) * 12;

   color c = ZoneColor(z);

   if(ObjectFind(0, rect) < 0)
      ObjectCreate(0, rect, OBJ_RECTANGLE, 0, t1, z.zoneHigh, t2, z.zoneLow);

   ObjectSetInteger(0, rect, OBJPROP_COLOR, c);
   ObjectSetInteger(0, rect, OBJPROP_BACK, true);
   ObjectSetInteger(0, rect, OBJPROP_FILL, true);
   ObjectSetInteger(0, rect, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, rect, OBJPROP_WIDTH, 1);
   ObjectMove(0, rect, 0, t1, z.zoneHigh);
   ObjectMove(0, rect, 1, t2, z.zoneLow);

   if(ObjectFind(0, ent) < 0)
      ObjectCreate(0, ent, OBJ_HLINE, 0, 0, z.entry);
   ObjectSetInteger(0, ent, OBJPROP_COLOR, c);
   ObjectSetInteger(0, ent, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetDouble(0, ent, OBJPROP_PRICE, z.entry);

   if(ObjectFind(0, sl) < 0)
      ObjectCreate(0, sl, OBJ_HLINE, 0, 0, z.sl);
   ObjectSetInteger(0, sl, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, sl, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetDouble(0, sl, OBJPROP_PRICE, z.sl);

   if(ObjectFind(0, tp) < 0)
      ObjectCreate(0, tp, OBJ_HLINE, 0, 0, z.tp);
   ObjectSetInteger(0, tp, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, tp, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetDouble(0, tp, OBJPROP_PRICE, z.tp);

   string text = StringFormat("%s S=%d RR=%.2f %s",
                              SetupTag(z.setupType, z.direction),
                              z.score,
                              z.rr,
                              StateName(z.state));

   if(ObjectFind(0, txt) < 0)
      ObjectCreate(0, txt, OBJ_TEXT, 0, t1, z.zoneHigh);

   ObjectSetString(0, txt, OBJPROP_TEXT, text);
   ObjectSetInteger(0, txt, OBJPROP_COLOR, c);
   ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 8);
   ObjectMove(0, txt, 0, t1, z.zoneHigh);
}

void DrawActiveZones()
{
   if(!InpDrawObjects)
      return;

   for(int i = 0; i < g_activeCount; i++)
      DrawZone(g_active[i]);

   ChartRedraw(0);
}

void DrawDashboard()
{
   int candidates = 0;
   int armed = 0;
   int triggered = 0;
   int used = 0;
   int missed = 0;
   int expired = 0;
   int deferred = 0;

   for(int i = 0; i < g_activeCount; i++)
   {
      if(g_active[i].state == STATE_CANDIDATE)
         candidates++;
      else if(g_active[i].state == STATE_ARMED)
         armed++;
      else if(g_active[i].state == STATE_TRIGGERED)
         triggered++;
   }

   for(int i = 0; i < g_archiveCount; i++)
   {
      if(g_archive[i].state == STATE_USED)
         used++;
      else if(g_archive[i].state == STATE_MISSED)
         missed++;
      else if(g_archive[i].state == STATE_EXPIRED)
         expired++;
      else if(g_archive[i].state == STATE_DEFERRED)
         deferred++;
   }

   string s = "";
   s += StringFormat("%s\n", InpEAName);
   s += StringFormat("Mode: %s | TF: %s | Active: %d/%d | Archive: %d/%d\n",
                     InpEnableAutoTrading ? "AUTO" : "SCAN",
                     EnumToString(InpExecutionTF),
                     g_activeCount,
                     InpMaxZones,
                     g_archiveCount,
                     InpTerminalArchiveMax);

   s += StringFormat("CANDIDATE %d | ARMED %d | TRIGGERED %d | USED %d | MISSED %d | EXPIRED %d | DEFERRED %d\n",
                     candidates,
                     armed,
                     triggered,
                     used,
                     missed,
                     expired,
                     deferred);

   if(InpShowSetupStatsTable)
   {
      s += "\nSETUP STATS: Tag | App | Exec | Closed | W | L | Win% | Net | PF\n";
      for(int i = 0; i < ArraySize(g_stats); i++)
         s += StatLine(g_stats[i]) + "\n";
   }

   if(InpShowGroupedStats)
   {
      s += "\nGROUP TOTALS\n";
      AddGroupLine(s, "QM_TOTAL",      0, 1);
      AddGroupLine(s, "iQM_TOTAL",     2, 3);
      AddGroupLine(s, "QMC_TOTAL",     4, 5);
      AddGroupLine(s, "QMM_TOTAL",     6, 7);
      AddGroupLine(s, "QMR_TOTAL",     8, 9);
      AddGroupLine(s, "MEF_TOTAL",     10, 11);
      AddGroupLine(s, "FAKEOUT_TOTAL", 12, 13);
      AddAllQMGroupLine(s);
      AddAllModelsLine(s);
   }

   s += StringFormat("\nLast action: %s\nLast skip: %s",
                     g_lastAction,
                     g_lastSkip);

   Comment(s);
}

void PrintFinalStats()
{
   if(!InpPrintDebug)
      return;

   Print("[", InpEAName, "] FINAL_STATS_BEGIN");
   for(int i = 0; i < ArraySize(g_stats); i++)
   {
      if(g_stats[i].appearances == 0 && g_stats[i].executed == 0 && g_stats[i].closed == 0)
         continue;
      Print("[", InpEAName, "] FINAL_STATS ", StatLine(g_stats[i]));
   }

   string groups = "";
   AddGroupLine(groups, "QM_TOTAL",      0, 1);
   AddGroupLine(groups, "iQM_TOTAL",     2, 3);
   AddGroupLine(groups, "QMC_TOTAL",     4, 5);
   AddGroupLine(groups, "QMM_TOTAL",     6, 7);
   AddGroupLine(groups, "QMR_TOTAL",     8, 9);
   AddGroupLine(groups, "MEF_TOTAL",     10, 11);
   AddGroupLine(groups, "FAKEOUT_TOTAL", 12, 13);
   AddAllQMGroupLine(groups);
   AddAllModelsLine(groups);
   Print("[", InpEAName, "] FINAL_GROUPS\n", groups);
   Print("[", InpEAName, "] FINAL_STATS_END");
}

int OnInit()
{
   ArrayResize(g_active, MathMax(1, InpMaxZones));
   ArrayResize(g_archive, MathMax(1, InpTerminalArchiveMax));

   g_activeCount = 0;
   g_archiveCount = 0;
   g_nextZoneId = 1;
   InitSetupStats();

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippagePoints);

   g_rsiHandle = iRSI(_Symbol, InpExecutionTF, InpRSIPeriod, PRICE_CLOSE);
   g_macdHandle = iMACD(_Symbol, InpExecutionTF, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   g_obvHandle = iOBV(_Symbol, InpExecutionTF, VOLUME_TICK);
   g_atrHandle = iATR(_Symbol, InpExecutionTF, InpATRPeriod);

   if(g_rsiHandle == INVALID_HANDLE ||
      g_macdHandle == INVALID_HANDLE ||
      g_obvHandle == INVALID_HANDLE ||
      g_atrHandle == INVALID_HANDLE)
   {
      Print("[", InpEAName, "] indicator handle init failed");
      return INIT_FAILED;
   }

   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dayKey = DateKey(TimeCurrent());

   ObjectsDeleteAll(0, g_prefix);

   DebugPrint("INIT",
              StringFormat("complete v3.15 active trail loaded MaxZones=%d CandidateMin=%d TradeMin=%d StdQMCand=%d StdQMTrade=%d TargetRR=%.2f SL_ATR=%.2f DrawTerminal=%s",
                           InpMaxZones,
                           InpCandidateMinScore,
                           InpMinTradeScore,
                           InpStandardQMCandidateMinScore,
                           InpStandardQMTradeMinScore,
                           InpTargetRR,
                           InpSLATRMultiplier,
                           InpDrawTerminalZones ? "true" : "false"));

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   PrintFinalStats();
   if(g_rsiHandle != INVALID_HANDLE)
      IndicatorRelease(g_rsiHandle);

   if(g_macdHandle != INVALID_HANDLE)
      IndicatorRelease(g_macdHandle);

   if(g_obvHandle != INVALID_HANDLE)
      IndicatorRelease(g_obvHandle);

   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);

   Comment("");
}


void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   ulong deal = trans.deal;
   if(deal == 0)
      return;

   if(!HistoryDealSelect(deal))
      return;

   if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
      return;

   if((ulong)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagicNumber)
      return;

   long entryType = HistoryDealGetInteger(deal, DEAL_ENTRY);
   ulong positionId = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   string comment = HistoryDealGetString(deal, DEAL_COMMENT);
   int statsIndex = StatsIndexFromComment(comment);

   if(entryType == DEAL_ENTRY_IN || entryType == DEAL_ENTRY_INOUT)
   {
      if(statsIndex >= 0)
      {
         StatsAddEntryDeal(statsIndex, deal);
         TrackPositionStatsIndex(positionId, statsIndex);

         DebugPrint("ENTRY_TRACKED",
                    StringFormat("%s deal=%I64u pos=%I64u", g_stats[statsIndex].tag, deal, positionId));
      }
   }

   if(entryType == DEAL_ENTRY_OUT || entryType == DEAL_ENTRY_INOUT || entryType == DEAL_ENTRY_OUT_BY)
   {
      if(statsIndex < 0)
         statsIndex = StatsIndexFromPosition(positionId);

      if(statsIndex >= 0)
      {
         double profit = HistoryDealGetDouble(deal, DEAL_PROFIT) +
                         HistoryDealGetDouble(deal, DEAL_SWAP) +
                         HistoryDealGetDouble(deal, DEAL_COMMISSION);

         StatsAddClosedDeal(statsIndex, deal, profit);
      }
   }
}

void OnTick()
{
   ResetDailyGuardIfNeeded();

   ManageTriggeredZones();

   if(IsNewBar())
   {
      ExpireActiveZones();
      PurgeArchive();
      ScanForSetups();
      UpdateArmedState();
      DrawActiveZones();
   }

   ExecuteArmedPool();
   DrawDashboard();
}
//+------------------------------------------------------------------+
