{smcl}
{* *! version 1.0.2  26aug2016}{...}
{cmd:help xtqptest}{right: ({browse "http://www.stata-journal.com/article.html?article=st0514":SJ18-1: st0514})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:xtqptest} {hline 2}}Bias-corrected Lagrange multiplier-based test for panel serial correlation


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtqptest}
[{varlist}]
{ifin}
[{cmd:,} {it:options}] 

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:ags(integer)}}check for serial correlation up to {it:integer}{p_end}
{synopt:{opt or:der(integer)}}check for serial correlation of {it:integer}{p_end}
{synopt:{opt force}}skip checking if residuals include the fixed effect{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqptest} calculates the bias-corrected Q(P) statistic for serial
correlation described in Born and Breitung (2016) for {varlist} of
ue-residuals.

{pstd}
The underlying concept of the test is to regress current demeaned residuals on
past demeaned and bias-corrected residuals (up to order {cmd:lags()}) using a
heteroskedasticity- and autocorrelation-robust estimator.  A Wald test is then
performed on the estimated coefficients.  {bf:xtqptest} calculates the Q(p)
statistic that is asymptotically equivalent to this Wald test.

{pstd}
The authors have verified that the test in its current form is also valid for
unbalanced panels.  It might be slightly oversized (rejects the null too
often), but this is still a matter of debate.

{pstd}
If {cmd:order()} is specified, {cmd:xtqptest} calculates the Lagrange
multiplier (LM) LM(k) statistic instead (also described in Born and Breitung
[2016]).  This test also works with e-residuals.  Unlike the default option,
the {cmd:order()} version tests for serial correlation of order {cmd:order()}.
For example, only second-order correlation, not first- and second-order
correlation.

{pstd}
This test is based on heteroskedasticity- and autocorrelation-robust t test
of the predictive power of lagged (of order {cmd:order()}) demeaned residuals
on current demeaned residuals.


{marker options}{...}
{title:Options}

{phang}
{opt lags(integer)} specifies to check for autocorrelation up to {it:integer}.
The default is {cmd:lags(2)}.

{phang}
{opt order(integer)} specified to check for autocorrelation of {it:integer}.

{phang}
{opt force} skips checking if residuals include the fixed effect.  The test
only works if the dataset contains no gaps and the residuals provided include
the fixed effect.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:xtqptest} is valid only for fixed-effect models without gaps.  Unbalanced
panels (different starts and ends) are allowed.

{pstd}
You must use the {bf:ue} option when predicting the residuals.  That is, this
test requires the fixed effect-included residuals (ci + eit).

{pstd}
Any mistakes are my own.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse xtline1.dta}{p_end}

{phang}{cmd:. xtreg calories, fe}{p_end}
{phang}{cmd:. predict ue_residuals_1, ue}{p_end}
{phang}{cmd:. xtqptest ue_residuals_1, lags(1)}{p_end}
{phang}{cmd:. xtqptest ue_residuals_1, order(1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtqptest} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(pvalue}{it:i}{cmd:)}}p-values are also stored as scalars (often
more convenient){p_end}
{synopt:{cmd:r(qp}{it:i}{cmd:)}}same for the Q(P) statistics{p_end}
{synopt:{cmd:r(lm}{it:i}{cmd:)}}same for the LM(k) statistics{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(p)}}p-values{p_end}
{synopt:{cmd:r(QP)}}values of the Q(P) statistics{p_end}
{synopt:{cmd:r(LM)}}values of the LM(k) statistics{p_end}
{p2colreset}{...}


{marker reference}{...}
{title:Reference}

{phang}
Born, B., and J. Breitung. 2016. Testing for serial correlation in
fixed-effects panel data models. {it:Econometric Reviews} 35: 1290-1316.


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
