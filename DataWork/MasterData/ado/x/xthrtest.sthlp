{smcl}
{* *! version 1.0.3  14sep2016}{...}
{cmd:help xthrtest}{right: ({browse "http://www.stata-journal.com/article.html?article=st0514":SJ18-1: st0514})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:xthrtest} {hline 2}}Heteroskedasticity-robust test for first-order panel serial correlation


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xthrtest}
[{varlist}]
{ifin}
[{cmd:,} {it:option}] 

{synoptset 10}{...}
{synopthdr:option}
{synoptline}
{synopt:{opt force}}skip checking if residuals include the fixed effect{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xthrtest} calculates the (time-dependent) heteroskedasticity-robust (HR)
statistic for serial correlation described in Born and Breitung (2016) for
{varlist} of {cmd:`ue'} residuals.

{pstd}
The underlying concept of the test boils down to regressing backward-demeaned
residuals on lagged forward-demeaned residuals using a heteroskedasticity- and
autocorrelation-robust estimator.  An F test is then performed on the
estimated coefficients.  {bf:xthrtest} calculates the HR statistic that is
asymptotically equivalent to this F test.


{marker options}{...}
{title:Option}

{phang}
{opt force} skips checking if residuals include the fixed effect.  The test
only works if the dataset contains no gaps and the residuals provided include
the fixed effect.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:xthrtest} is valid only for fixed-effect models without gaps.  Unbalanced
panels (different starts and ends) are allowed.

{pstd}
You must use the {cmd:ue} option of {helpb predict} when predicting the
residuals.  That is, this test requires the fixed-effect included residuals
(ci + eit).

{pstd}
Any mistakes are my own.


{marker examples}{...}
{title:Example}

{phang}{cmd:. sysuse xtline1.dta}{p_end}

{phang}{cmd:. xtreg calories, fe}{p_end}
{phang}{cmd:. predict ue_residuals_1, ue}{p_end}
{phang}{cmd:. xthrtest ue_residuals_1}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xthrtest} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(pvalue}{it:i}{cmd:)}}p-values are also stored as scalars (often
more convenient){p_end}
{synopt:{cmd:r(hr}{it:i}{cmd:)}}same for the HR statistics{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(p)}}p-values{p_end}
{synopt:{cmd:r(HR)}}values of the Q(P) statistics{p_end}
{p2colreset}{...}


{marker references}{...}
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
