eul:2.71828182845 /We must define Euler's number as it is not innately within Kona.

/ =========SECTION 1: MOVING AVERAGE RELATIVE VALUE STRATEGY=========

/ =====================================================================
/ O(N) VECTORIZED MOVING AVERAGE (PREFIX-SUM ARCHITECTURE)
/ 
/ This function bypasses the O(N * W) complexity of standard looping MAs.
/ 1. Prefix-Sum (+\x): Calculates the running total of the array ONCE.
/ 2. Window Isolation (s[w+!n]-s[!n]): Finds the sum of any window by 
/    subtracting the dropped tail from the newly added head.
/ 3. Memory Preservation: Uses negative drops (-1_) to shift the signal, 
/    preventing the CPU cache thrashing caused by array reversals.
/ 4. Dimension Alignment: Pads the front ((w-1)#0) to guarantee array 
/    lengths match perfectly for downstream vectorized multiplication.
/ =====================================================================

/ --- 1.1. DATA INGESTION ---

a:(","\'a:0:"HistDataAPPLE.csv")
prc:|0,{[k]. 1_ k}'1_(+a)[1]
r:0,-':_log |1_|prc

/ --- 1.2. MA STRAT EXECUTION ENGINE ---

ma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),-1_(s[w+!n]-s[!n])*%w}
ma_str:{[h1;h2;p]s:-1_0,((ma[h1;p])>ma[h2;p])
	c:0,0.0005*1=+':s;t:((r*s)-c)
	100*(eul^+/t)-1}

/ --- 1.3. COMBINATION CHECK ---
*v[>v:{[j](ma_str[j[0];j[1];prc];j[0];j[1])}',/{[x]x,'1_!x}'1_!20]
