{smcl}
{* *! Version 1.0.4 9nov2016}{...}
{cmd:help xtistest}{right: ({browse "http://www.stata-journal.com/article.html?article=st0514":SJ18-1: st0514})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:xtistest} {hline 2}}Portmanteau test for panel serial correlation{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtistest}
[{varlist}]
{ifin}
[{cmd:,} {it:options}] 

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:l:ags(}{it:integer}|{cmd:all)}}check for serial correlation up to {it:integer}{p_end}
{synopt:{opt orig:inal}}use Inoue and Solon (IS) calculation (should give same result){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtistest} calculates the Portmanteau test for panel serial correlation
described in Inoue and Solon (2006) for {varlist} of e-residuals.

{pstd}
The IS test is the panel counterpart to the Q test for time series.  It tests
for serial correlation of any order but can be restricted to consider only
autocorrelation up to a certain lag.  The test rapidly loses power as T gets
larger if no maximum is given.  In general, N should be large relative to T
for this test to function.


{marker options}{...}
{title:Options}

{phang}
{cmd:lags(}{it:integer}|{cmd:all)} specifies to check for autocorrelation up
to {it:integer}.  The default is {cmd:lags(2)}.  To obtain the full
portmanteau test, specify {cmd:lags(all)}.

{phang}
{opt original} specifies to use IS calculation.  The test by default uses the
Born and Breitung (2016) implementation, which is many times faster than the
description in Inoue and Solon (2006).  However, I include the {cmd:original}
computation option in case anyone finds a difference in outcomes between the
two.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:xtistest} is valid only for fixed-effect models.  Unbalanced panels of
any sort are allowed (unlike {cmd:xtqptest} and {cmd:xthrtest}, this test
allows gaps in the data).

{pstd}
Any mistakes are my own.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ** Example 1}{p_end}
{phang}{cmd:. sysuse xtline1.dta}{p_end}

{phang}{cmd:. xtreg calories, fe}{p_end}
{phang}{cmd:. predict residuals_1, e}{p_end}
{phang}{cmd:. xtistest residuals_1, lags(1)}{p_end}

{phang}{cmd:. ** Example 2}{p_end}
{phang}{cmd:. clear}{p_end}
{phang}{cmd:. local N = 200}{p_end}
{phang}{cmd:. local T = 5}{p_end}
{phang}{cmd:. set obs `=`N'*`T''}{p_end}

{phang}{cmd:. *** Panel structure}{p_end}
{phang}{cmd:. egen i = seq(), from(1) to(`N')}{p_end}
{phang}{cmd:. egen t = seq(), from(1) block(`N')}{p_end}
{phang}{cmd:. xtset i t}{p_end}

{phang}{cmd:. *** Variables}{p_end}
{phang}{cmd:. **** Fixed effect}{p_end}
{phang}{cmd:. generate c = rnormal(0, 5)}{p_end}
{phang}{cmd:. bysort i (t): replace c = c[1]}{p_end}

{phang}{cmd:. **** Regressors}{p_end}
{phang}{cmd:. generate x1 = rnormal()}{p_end}
{phang}{cmd:. generate x2 = rnormal()}{p_end}

{phang}{cmd:. **** Independent variable}{p_end}
{phang}{cmd:. generate ea = rnormal()}{p_end}
{phang}{cmd:. generate eb = rnormal()}{p_end}
{phang}{cmd:. replace eb = 0.4*L.eb + 0.2*L2.eb + rnormal() if ~missing(L.eb, L2.eb)}{p_end}
{phang}{cmd:. generate ya = c + 0.03*x1 + 0.6*x2 + ea}{p_end}
{phang}{cmd:. generate yb = c + 0.03*x1 + 0.6*x2 + eb}{p_end}

{phang}{cmd:. *** Regress}{p_end}
{phang}{cmd:. xtreg ya x1 x2, fe}{p_end}
{phang}{cmd:. predict res_a, e}{p_end}
{phang}{cmd:. xtreg yb x1 x2, fe}{p_end}
{phang}{cmd:. predict res_b, e}{p_end}

{phang}{cmd:. *** Test residuals}{p_end}
{phang}{cmd:. xtistest res*, lags(2)}{p_end}

{phang}{cmd:. *** Test as postestimation}{p_end}
{phang}{cmd:. xtreg ya x1 x2, fe}{p_end}
{phang}{cmd:. xtistest, lags(2)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtistest} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(pvalue}{it:i}{cmd:)}}p-values are also stored as scalars (often more convenient){p_end}
{synopt:{cmd:r(is}{it:i}{cmd:)}}same for the IS statistics{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(p)}}p-values{p_end}
{synopt:{cmd:r(IS)}}values of the IS statistics{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Born, B., and J. Breitung. 2016. Testing for serial correlation in
fixed-effects panel data models. {it:Econometric Reviews} 35: 1290-1316.

{phang}
Inoue, A., and G. Solon. 2006. A Portmanteau test for serially correlated
errors in fixed effects models. {it:Econometric Theory} 22: 835-851.


{title:Author}

{pstd}
Jesse Wursten{break}
Faculty of Economics and Business{break}
KU Leuven{break}
Leuven, Belgium{break}
{browse "mailto:jesse.wursten@kuleuven.be":jesse.wursten@kuleuven.be} 


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 18, number 1: {browse "http://www.stata-journal.com/article.html?article=st0514":st0514}{p_end}
