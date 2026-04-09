/ ================KONA-ALPHA-ENGINE: VECTORIZED HIGH-FREQUENCY BACKTESTER================

/ =========SECTION 0: DATA INGESTION & GLOBALS=========

/ --- 0.1. DATA INGESTION ---

a:(","\'a:0:"HistDataAPPLE.csv")
prc:|0,{[k]. 1_ k}'1_(+a)[1]

/Non-native definitions
eul:2.71828182845


/ =========SECTION 1: MOVING AVERAGE CROSSOVER (TREND FOLLOWING)=========

/ =====================================================================
/ O(N) VECTORIZED MOVING AVERAGE (PREFIX-SUM ARCHITECTURE)
/ This function bypasses the O(N * W) complexity of standard looping MAs.
/ 1. Prefix-Sum (+\x): Calculates the running total of the array ONCE.
/ 2. Window Isolation (s[w+!n]-s[!n]): Finds the sum of any window by 
/    subtracting the dropped tail from the newly added head.
/ 3. Memory Preservation: Uses negative drops (-1_) to shift the signal, 
/    preventing the CPU cache thrashing caused by array reversals.
/ 4. Dimension Alignment: Pads the front ((w-1)#0) to guarantee array 
/    lengths match perfectly for downstream vectorized multiplication.
/ =====================================================================

/ --- 1.1. MA STRAT EXECUTION ENGINE ---

ma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),-1_(s[w+!n]-s[!n])*%w}
ma_str:{[h1;h2;p]s:-1_0,((ma[h1;p])>ma[h2;p])
		r:0,-':_log -1_ p;c:0,0.0005*1=+':s
		t:((r*s)-c);100*(eul^+/t)-1}

/ --- 1.2. COMBINATION CHECK AND BENCHMARK---

/In this case we test all the window combinations for pairs of integers up to 20
*v[>v:{[j](ma_str[j[0];j[1];prc];j[0];j[1])}',/{[x]x,'1_!x}'1_!20]

/We can check the run time for the example above (approx 197ms)
\t *v[>v:{[j](ma_str[j[0];j[1];prc];j[0];j[1])}',/{[x]x,'1_!x}'1_!20] 


/ ========= SECTION 2: Z-SCORE MEAN REVERSION (STATISTICAL ARBITRAGE) =========

/ =====================================================================
/ O(N) STATISTICAL ARBITRAGE ENGINE & VARIANCE IDENTITY
/ This engine evaluates mean reversion without a single rolling loop.
/ 1. Variance Identity: Calculates rolling standard deviation in strict 
/    O(N) time using Var(X) = E[X^2] - (E[X])^2, reusing the ma prefix-sum.
/ 2. Padding Mask (m>0): Multiplies the Z-score by a boolean array to 
/    instantly zero-out the initial padding phase, preventing float explosions.
/ 3. Zero-Division Protection: Adds 1e-5 to the standard deviation denominator
/    to safely bypass hardware interrupts during flat/stagnant market periods.
/ 4. Single-Pass State Extraction: The argmax sweep (*a[>a...]) evaluates
/    and sorts the final PnL matrix dynamically in a single line of memory.
/ =====================================================================

/ --- 2.1. STATISTICAL EXECUTION ENGINE ---

zma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),(s[w+!n]-s[!n])*%w}

z_strat:{[w;tr;p]m:zma[w;p];sd:(zma[w;p*p]-(m*m))^.5
    	z:((p-m)*%(sd+1e-5))*(m>0);s:-1_ 0,((-tr)>z)
		c:0,0.0005*1=+':s;r:0.0,-':_log p;t:(r*s)-c;100*(eul^+/-1_ t)-1}

/ --- 2.2. PARAMETER SWEEP AND BENCHMARK---

/In this case we are testing this on windows of up to 100 days, with a Z-score threshold of 2
*a[>a:{(z_strat[x;2;prc];x)}'1_!100]

/We can check the runtime of the example above (approximately 117ms)
\t *a[>a:{(z_strat[x;2;prc];x)}'1_!100]

/For fun here is another example; where we do the same parameter
/sweep on window and also we compute it for 8 thresholds
*b[>b:{[t]*a[>a:{[x](z_strat[x;t;prc];x;t)}'1_!100]}'(.5;1;1.5;2;2.5;3;3.5;4)]

/Checking the runtime yields ~1.3s (for exactly 792 complete 
/historical backtests on 1249 days worth of data each!)
\t *b[>b:{[t]*a[>a:{[x](z_strat[x;t;prc];x;t)}'1_!100]}'(.5;1;1.5;2;2.5;3;3.5;4)]


/ ========= SECTION 3: RELATIVE STRENGTH INDEX (MOMENTUM OSCILLATOR) =========

/ =====================================================================
/ O(N) BOOLEAN MASKING & MOMENTUM ENGINE
/ This engine evaluates the classic RSI oscillator strictly through vectorized matrix routing.
/ 1. Boolean Data Routing: Isolates positive and negative price differences in strict 
/    O(N) time using mathematical truth masks ((d>0) and (0>d)), eliminating 
/    pipeline-stalling conditional if/else branches.
/ 2. Prefix-Sum Smoothing: Reuses the O(N) cumulative sum moving average architecture 
/    to calculate Average Gains (au) and Average Losses (ad) simultaneously.
/ 3. Reciprocal Math & Protection: Utilizes the monadic reciprocal operator (%) and 
/    adds 10e-4 to the denominator to prevent division-by-zero float explosions 
/    when the asset flatlines.
/ 4. Zero-Pad Masking: Multiplies the final signal by ((au+ad)>0) to perfectly 
/    suppress false-positive "oversold" triggers during the initial warmup phase.
/ =====================================================================

/ --- 3.1. RSI EXECUTION ENGINE ---

rsi_ma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),(s[w+!n]-s[!n])*%w}

rsi_strat:{[w;tr;p]d:p--1_ (*p),p;u:d*(d>0);dw:(0.0-d)*(0>d)
        au:rsi_ma[w;u];ad:rsi_ma[w;dw];rs:au*%(ad+10e-4);rsi:100.0-(100.0*%(1.0+rs))
        s:-1_ 0,((tr>rsi)*((au+ad)>0));c:0,0.0005*1=+':s;r:0.0,-':_log p
        t:(r*s)-c;100*(eul^+/-1_ t)-1}

/ --- 3.2. PARAMETER SWEEP AND BENCHMARK ---

/ In this case, we are sweeping the moving average windows from 2 up to 40 days, 
/ locking in a fixed "Oversold" RSI threshold of 30.
*a[>a:{[x](rsi_strat[x;30;prc];x)}'2_!40]

/ We can check the runtime of the 1D parameter sweep above (approx 133ms):
\t *a[>a:{[x](rsi_strat[x;30;prc];x)}'2_!40]

/ For a true institutional stress test, here is the 2D Parameter Surface Sweep.
/ We sweep 98 moving average windows (2 to 99 days) across 14 distinct Oversold Thresholds.
/ This grid search executes 1,372 independent, multi-year historical backtests in a single pass.
*b[>b:{[t]*a[>a:{[x](rsi_strat[x;t;prc];x;t)}'2_!100]}'(1;1.5;2;3;4;5;6;7;10;30;31;35;45;50)]

/ Checking the runtime for the full multi-dimensional surface sweep.
/ Benchmark: Evaluates ~61.7 million discrete matrix operations in ~3 seconds on a single thread.
\t *b[>b:{[t]*a[>a:{[x](rsi_strat[x;t;prc];x;t)}'2_!100]}'(1;1.5;2;3;4;5;6;7;10;30;31;35;45;50)]
