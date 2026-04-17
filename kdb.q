-1"========== Q-ALPHA-ENGINE: VECTORIZED HIGH-FREQUENCY BACKTESTER ==========";

/ Parse the CSV: splits by comma, transposes, takes price column, drops header & $ sign
raw:flip","vs'read0`:HistDataAPPLE.csv;
prc:reverse 0.0,"F"$ 1_'1_raw 1;


-1"\n====== SECTION 1: MOVING AVERAGE CROSSOVER (TREND FOLLOWING) ======";

ma:{[w;x]s:0.0,sums x;n:1+(count x)-w;((w-1)#0.0),-1_(s[w+til n]-s[til n])%w};
mastr:{[h1;h2;p]s:-1_0.0,ma[h1;p]>ma[h2;p];
    r:0.0,1_deltas log -1_ p;c:0.0,0.0005*1_1=differ s;  / 'differ' replaces the 1=+':s XOR trick
    t:(r*s)-c;100*(exp sum t)-1};

-1"\nOptimal Parameters (Return; Window1; Window2):";
/ Q has a built-in cross product function, making parameter matrices much cleaner
pairs1:raze{x,/:1_til x}each 1_til 20;
show first desc{(mastr[x 0;x 1;prc];x 0;x 1)}each pairs1;

-1"Section 1:Running time (Milliseconds; Bytes Allocated):";
show system "ts first desc{(mastr[x 0;x 1;prc];x 0;x 1)}each raze{x,/:1_til x}each 1_ til 20";


-1"\n====== SECTION 2: Z-SCORE MEAN REVERSION (STATISTICAL ARBITRAGE) ======";

zma:{[w;x]s:0.0,sums x;n:1+(count x)-w;((w-1)#0.0),(s[w+til n]-s[til n])%w};
zstrat:{[w;tr;p]m:zma[w;p];sd:sqrt zma[w;p*p]-m*m;
    z:((p-m)%(sd+1e-5))*m>0;s:-1_0.0,(neg tr)>z;
    c:0.0,0.0005*1_1=differ s;r:0.0,1_deltas log p;
    t:(r*s)-c;100*(exp sum -1_t)-1};

-1"\nSection 2: 1D Sweep - Opt. Param. (Return; Window):";
show first desc {(zstrat[x;2.0;prc];x)}each 1_til 100;
-1"Running time (Milliseconds; Bytes Allocated):";
show system "ts first desc {(zstrat[x;2.0;prc];x)}each 1_til 100";

-1"\n2D Institutional Stress Test - Opt. Param. (Return; Window; Threshold):";
pairs2:(1_til 100)cross 0.5 1 1.5 2 2.5 3 3.5 4;
show first desc{(zstrat[x 0;x 1;prc];x 0;x 1)}each pairs2;
-1 "Running time (Milliseconds; Bytes Allocated):";
show system "ts first desc{(zstrat[x 0;x 1;prc];x 0;x 1) }each(1_til 100)cross 0.5 1 1.5 2 2.5 3 3.5 4";


-1"\n====== SECTION 3: RELATIVE STRENGTH INDEX (MOMENTUM OSCILLATOR) ======";

rsistrat:{[w;tr;p]d:0.0,1_deltas p;u:d*d>0;dw:(0.0-d)*0>d;
    au:zma[w;u];ad:zma[w;dw];rs:au%ad+10e-4;
    rsi:100.0-100.0%1.0+rs;s:-1_0.0,(tr>rsi)*au+ad>0;
    c:0.0,0.0005*1_1=differ s;r:0.0,1_deltas log p;
    t:(r*s)-c;100*(exp sum -1_t)-1};

-1"\n1D Sweep - Optimal Parameters (Return; Window):";
show first desc{(rsistrat[x;30.0;prc];x)}each 2_til 40;
-1 "Running time (Milliseconds; Bytes Allocated):";
show system "ts first desc{(rsistrat[x;30.0;prc];x)}each 2_til 40";

-1"\n2D Surface Sweep - Optimal Parameters (Return; Window; Threshold):";
pairs3:(1_til 100)cross 1 1.5 2 3 4 5 6 7 10 30 31 35 45 50;
show first desc { (rsistrat[x 0; x 1; prc]; x 0; x 1) } each pairs3;
-1"Running time (Milliseconds; Bytes Allocated):";
show system "ts first desc{(rsistrat[x 0;x 1;prc];x 0;x 1)}each(1_til 100)cross 1 1.5 2 3 4 5 6 7 10 30 31 35 45 50";
