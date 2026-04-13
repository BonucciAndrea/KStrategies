"================NGN/K-ALPHA-ENGINE: VECTORIZED HIGH-FREQUENCY BACKTESTER================"
a:(","\'a:0:"HistDataAPPLE1.csv")
prc:|0,{[k]. 1_ k}'1_(+a)[1]

"=========SECTION 1: MOVING AVERAGE CROSSOVER (TREND FOLLOWING)========="
ma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),-1_(s[w+!n]-s[!n])%w}
mastr:{[h1;h2;p]s:-1_ 0.0,((ma[h1;p])>ma[h2;p]);r:0.0,1_-':`ln -1_ p
c:0.0,0.0005*1_1=+':s;t:((r*s)-c)
100*(`exp(+/t))-1}

"In this case we test all the window combinations for pairs of integers up to 20."
*v[>v:{[j](mastr[j[0];j[1];prc];j[0];j[1])}',/{[x]x,'1_!x}'1_!20]
"Running time"
\t *v[>v:{[j](mastr[j[0];j[1];prc];j[0];j[1])}',/{[x]x,'1_!x}'1_!20]



"========= SECTION 2: Z-SCORE MEAN REVERSION (STATISTICAL ARBITRAGE) ========="
zma:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),(s[w+!n]-s[!n])%w}
zstrat:{[w;tr;p]m:zma[w;p];sd:%zma[w;p*p]-m*m;z:((p-m)%(sd+1e-5))*(m>0)
s:-1_ 0,((-tr)>z);c:0,0.0005*1_1=+':s;r:0.0,1_-':`ln p
t:((r*s)-c);100*(`exp(+/-1_t))-1}

"1D Parameter Sweep: Windows up to 100 days, fixed Oversold threshold of 2"
*a[>a:{(zstrat[x;2;prc];x)}'1_!100]
"Running time"
\t *a[>a:{(zstrat[x;2;prc];x)}'1_!100]

"2D Institutional Stress Test: 99 Windows across 8 Distinct Oversold Thresholds"
*a[>a:,/{(zstrat[x;y;prc];x;y)}'/:[1_!100;.5 1 1.5 2 2.5 3 3.5 4]]
"Running time"
\t *a[>a:,/{(zstrat[x;y;prc];x;y)}'/:[1_!100;.5 1 1.5 2 2.5 3 3.5 4]]



"========= SECTION 3: RELATIVE STRENGTH INDEX (MOMENTUM OSCILLATOR) ========="
rsima:{[w;x]s:0.0,+\x;n:1+(#x)-w;((w-1)#0),(s[w+!n]-s[!n])%w}
rsistrat:{[w;tr;p]d:p--1_ (*p),p;u:d*(d>0);dw:(0.0-d)*(0>d)
au:rsima[w;u];ad:rsima[w;dw];rs:au%(ad+10e-4);rsi:100.0-(100.0%(1.0+rs))
s:-1_ 0,((tr>rsi)*((au+ad)>0));c:0,0.0005*1_1=+':s;r:0.0,1_-':`ln p
t:((r*s)-c);100*(`exp(+/-1_t))-1}

"In this case, we are sweeping the moving average windows from 2 up to 40 days, "
"locking in a fixed Oversold RSI threshold of 30."
*a[>a:{[x](rsistrat[x;30;prc];x)}'2_!40]
"Running time"
\t *a[>a:{[x](rsistrat[x;30;prc];x)}'2_!40]

"Checking the runtime for the full multi-dimensional surface sweep."
*a[>a:,/{(rsistrat[x;y;prc];x;y)}'/:[1_!100;1 1.5 2 3 4 5 6 7 10 30 31 35 45 50]]
"Running time"
\t *a[>a:,/{(rsistrat[x;y;prc];x;y)}'/:[1_!100;1 1.5 2 3 4 5 6 7 10 30 31 35 45 50]]
