{smcl}
{* *! version 1.4.1  05jun2014  Ben Jann}{...}
{cmd:help coefplot}{right: ({browse "http://www.stata-journal.com/article.html?article=up0046":SJ15-1: gr0059_1})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{hi:coefplot} {hline 2}}Plotting regression coefficients and other
results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:coefplot} {it:subgraph} [{cmd:||} {it:subgraph} ...] 
[{cmd:,} {help coefplot##globalopts:{it:globalopts}}]

{pstd}
where {it:subgraph} is defined as

{p 8 16 2}
{cmd:(}{it:plot}{cmd:)} [{cmd:(}{it:plot}{cmd:)} ...] 
[{cmd:,} {help coefplot##subgropts:{it:subgropts}}]

{pstd}
and {it:plot} is either {cmd:_skip} (to skip a plot) or

{p 8 16 2}
{it:model} [{cmd:\} {it:model} ...]
[{cmd:,} {help coefplot##plotopts:{it:plotopts}}]

{pstd}
and {it:model} is either

{p 8 16 2}
{it:name} [{cmd:,} {help coefplot##modelopts:{it:modelopts}}]

{pstd}
where {it:name} is the name of a stored model 
(see {manhelp estimates R}; type {cmd:.} or leave blank to refer to 
the active model) or

{p 8 16 2}
{helpb coefplot##matrix:{ul:m}atrix({it:mspec})} [{cmd:,} {help coefplot##modelopts:{it:modelopts}}]

{pstd}
to plot results from a matrix (see 
{help coefplot##matrix:{it:Plotting results from matrices}} below).
Parentheses around {it:plot} can be omitted if {it:plot} does not contain
spaces.

{synoptset 25 tabbed}{...}
{marker modelopts}{synopthdr:modelopts}
{synoptline}
{syntab:Main}
{synopt:{helpb coefplot##omitted:{ul:omit}ted}}include omitted 
coefficients
{p_end}
{synopt:{helpb coefplot##baselevels:{ul:base}levels}}include base levels
{p_end}
{synopt:{helpb coefplot##b:b({it:mspec})}}specify source to be plotted; default is {cmd:b(e(b))}{p_end}
{synopt:{helpb coefplot##at:at{sf:[}({it:spec}){sf:]}}}get plot positions from 
{cmd:e(at)}, or as specified by {it:spec}
{p_end}
{synopt:{helpb coefplot##keep:keep({it:coeflist})}}keep specified coefficients
{p_end}
{synopt:{helpb coefplot##drop:drop({it:coeflist})}}drop specified coefficients
{p_end}

{syntab:Confidence intervals}
{synopt:{helpb coefplot##noci:noci}}omit confidence intervals
{p_end}
{synopt:{helpb coefplot##levels:{ul:l}evels({it:numlist})}}set level(s) for 
confidence intervals
{p_end}
{synopt:{helpb coefplot##ci:ci({it:spec})}}provide confidence intervals
{p_end}
{synopt:{helpb coefplot##v:v({it:name})}}provide variances; default is {cmd:v(e(V))}
{p_end}
{synopt:{helpb coefplot##se:se({it:mspec})}}provide standard errors
{p_end}
{synopt:{helpb coefplot##df:df({it:spec})}}provide degrees of freedom
{p_end}
{synopt:{helpb coefplot##citype:citype(logit|{ul:norm}al)}}compute 
confidence intervals; default is {cmd:citype(normal)}
{p_end}

{syntab:Transform results}
{synopt:{helpb coefplot##eform:eform{sf:[}({it:coeflist}){sf:]}}}plot
exponentiated point estimates and confidence intervals
{p_end}
{synopt:{helpb coefplot##rescale:rescale({it:spec})}}rescale point estimates 
and confidence intervals
{p_end}
{synopt:{helpb coefplot##transform:{ul:trans}form({it:matchlist})}}transform 
point estimates and confidence intervals
{p_end}

{syntab:Names and labels}
{synopt:{helpb coefplot##rename:rename({it:matchlist})}}rename coefficients
{p_end}
{synopt:{helpb coefplot##eqrename:{ul:eqren}ame({it:matchlist})}}rename 
equations
{p_end}
{synopt:{helpb coefplot##asequation:{ul:aseq}uation{sf:[}({it:string}){sf:]}}}set equation
to model name or {it:string}
{p_end}
{synopt:{helpb coefplot##swapnames:{ul:swap}names}}swap coefficient names and 
equation names
{p_end}
{synopt:{helpb coefplot##mlabels:mlabels2({it:matchlist})}}specify marker labels
{p_end}

{syntab:Auxiliary results}
{synopt:{helpb coefplot##aux:aux({sf:{it:mspec} [{it:mspec} ...]})}}make
additional results available as {cmd:@aux1}, {cmd:@aux2}, etc.
{p_end}
{synoptline}

{synoptset 25 tabbed}{...}
{marker plotopts}{synopthdr:plotopts}
{synoptline}
{syntab:Pass thru}
{synopt:{help coefplot##modelopts:{it:modelopts}}}plot-specific model options;
see {help coefplot##place:{it:Placement of options}}
{p_end}

{syntab:Main}
{synopt:{helpb coefplot##label:{ul:lab}el({it:string})}}set label to be used for 
the plot in the legend 
{p_end}
{synopt:{helpb coefplot##key:key{sf:[}(ci {sf:[}{it:#}{sf:]}){sf:]}}}set key 
    symbol to be used for the plot in the legend 
    {p_end}
{synopt:{helpb coefplot##nokey:nokey}}do not include the plot in the legend
    {p_end}
{synopt:{helpb coefplot##pstyle:{ul:psty}le({it:pstyle})}}set overall 
style of the plot
{p_end}
{synopt:{helpb coefplot##axis:{ul:ax}is({it:#})}}set choice of axis for the plot; {cmd:1} {ul:<} {it:#} {ul:<} {cmd:9}
{p_end}
{synopt:{helpb coefplot##offset:offset({it:#})}}provide offset for plot 
positions
{p_end}
{synopt:{helpb coefplot##ifopt:{ul:if}opt({it:exp})}}restrict the contents of the plot
{p_end}
{synopt:{helpb coefplot##weight:{ul:w}eightopt({it:exp})}}set scale size of markers
{p_end}

{syntab:Markers}
{synopt:{it:{help marker_options}}}change the look of
markers (color, size, etc.)
{p_end}
{synopt:{helpb coefplot##mlabel:{ul:ml}abel}}add coefficient values as marker 
labels
{p_end}
{synopt:{it:{help marker_label_options}}}change the look and position of marker 
labels
{p_end}
{synopt:{helpb coefplot##recast:recast({it:plottype})}}plot results using 
{it:plottype}
{p_end}

{syntab:Confidence spikes}
{synopt:{helpb coefplot##cionly:cionly}}plot confidence spikes only
{p_end}
{synopt:{helpb coefplot##citop:citop}}draw confidence spikes in front
of markers
{p_end}
{synopt:{helpb coefplot##ciopts:{ul:ciop}ts({it:options})}}affect rendition 
of confidence spikes
{p_end}
{synopt:{helpb coefplot##cismooth:{ul:cis}mooth{sf:[}({it:options}){sf:]}}}add smoothed 
confidence intervals
{p_end}
{synoptline}

{synoptset 25 tabbed}{...}
{marker subgropts}{synopthdr:subgropts}
{synoptline}
{syntab:Pass thru}
{synopt:{help coefplot##modelopts:{it:modelopts}}}subgraph-specific model 
options; see {help coefplot##place:{it:Placement of options}}
{p_end}
{synopt:{help coefplot##plotopts:{it:plotopts}}}subgraph-specific plot 
options; see {help coefplot##place:{it:Placement of options}}
{p_end}

{syntab:Main}
{synopt:{helpb coefplot##bylabel:{ul:bylab}el({it:string})}}label to be used 
for the subgraph
{p_end}
{synoptline}

{synoptset 25 tabbed}{...}
{marker globalopts}{synopthdr:globalopts}
{synoptline}
{syntab:Pass thru}
{synopt:{help coefplot##modelopts:{it:modelopts}}}global model options; see 
{help coefplot##place:{it:Placement of options}} 
{p_end}
{synopt:{help coefplot##plotopts:{it:plotopts}}}global plot options; see 
{help coefplot##place:{it:Placement of options}}
{p_end}
{synopt:{help coefplot##subgropts:{it:subgropts}}}global subgraph options; 
see {help coefplot##place:{it:Placement of options}}
{p_end}

{syntab:Main}
{synopt:{helpb coefplot##horizontal:{ul:hor}izontal}}place coefficient values
on x axis; general default
{p_end}
{synopt:{helpb coefplot##vertical:{ul:vert}ical}}place coefficient values on y 
axis; default with {cmd:at()}{p_end}
{synopt:{helpb coefplot##relocate:{ul:reloc}ate({it:spec})}}assign 
specific positions to coefficients 
{p_end}
{synopt:{helpb coefplot##eqstrict:eqstrict}}be strict about equations{p_end}
{synopt:{helpb coefplot##order:order({it:coeflist})}}order coefficients 
{p_end}
{synopt:{helpb coefplot##bycoefs:{ul:byc}oefs}}arrange subgraphs by 
coefficients
{p_end}
{synopt:{helpb coefplot##norecycle:{ul:norec}ycle}}increment plot styles across 
subgraphs
{p_end}
{synopt:{helpb coefplot##nooffsets:{ul:nooff}sets}}do not offset plot 
positions
{p_end}
{synopt:{helpb coefplot##format:format({it:format})}}set the display format for
numeric labels
{p_end}

{syntab:Labels and grid lines}
{synopt:{helpb coefplot##nolabels:{ul:nolab}els}}use variable names instead of
labels
{p_end}
{synopt:{helpb coefplot##coeflabels:{ul:coefl}abels({it:spec})}}specify 
custom labels for coefficients{p_end}
{synopt:{helpb coefplot##noeqlabels:{ul:noeqlab}els}}suppress equation labels{p_end}
{synopt:{helpb coefplot##eqlabels:{ul:eql}abels({it:spec})}}specify labels 
for equations
{p_end}
{synopt:{helpb coefplot##headings:{ul:head}ings({it:spec})}}add headings between 
coefficients
{p_end}
{synopt:{helpb coefplot##groups:{ul:group}s({it:spec})}}add labels for groups of 
coefficients
{p_end}
{synopt:{helpb coefplot##plotlabels:{ul:plotl}abels({it:spec})}}(re)set plot 
labels
{p_end}
{synopt:{helpb coefplot##bylabels:bylabels({it:spec})}}(re)set subgraph 
labels
{p_end}
{synopt:{helpb coefplot##grid:grid({it:options})}}determine where grid lines are placed {p_end}

{syntab:Save results}
{synopt:{helpb coefplot##generate:{ul:gen}erate{sf:[}({it:prefix}){sf:]}}}generate 
variables containing the graph data
{p_end}
{synopt:{helpb coefplot##replace:replace}}overwrite existing variables
{p_end}

{syntab:Add plots}
{synopt:{helpb addplot_option:addplot({it:plot})}}add other plots to the 
graph
{p_end}
{synopt:{helpb coefplot##nodrop:nodrop}}do not drop observations
    {p_end}

{syntab:Y axis, X axis, Titles, Legend, Overall, By}
{synopt:{it:{help twoway_options}}}any options other than {cmd:by()} documented in {it:{manhelpi twoway_options G-3}}{p_end}
{synopt:{cmdab:byop:ts(}{it:{help by_option:byopts}}{cmd:)}}how subgraphs
are combined{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:coefplot} plots results from estimation commands or Stata matrices.
Results from multiple models or matrices can be combined into one graph.  The
default behavior of {cmd:coefplot} is to draw markers for coefficients and
horizontal spikes for confidence intervals.  However, {cmd:coefplot} can also
produce other types of graphs.


{marker options}{...}
{title:Options}
{dlgtab:Model options}

{marker omitted}{...}
{phang}
{cmd:omitted} includes omitted coefficients.  This may be useful if a model
contains coefficients that have been dropped due to collinearity.

{marker baselevels}{...}
{phang}
{cmd:baselevels} includes base levels of factor variables.

{marker b}{...}
{phang}
{cmd:b(}{it:mspec}{cmd:)} specifies the source from which the point
estimates and coefficient names are collected.  The default is to use (the
first row of) {cmd:e(b)} (or {cmd:e(b_mi)} if plotting results from
{helpb mi estimate}).  {cmd:b()} is discarded in matrix mode (see
{help coefplot##matrix:{it:Plotting results from matrices}} below).
{it:mspec} may be one of the following:

{p2colset 9 25 27 2}{...}
{p2col:{it:mpec}}Description{p_end}
{p2line}
{p2col:{it:name}}use first row of {cmd:e(}{it:name}{cmd:)}
{p_end}
{p2col:{it:name}{cmd:[}{it:#}{cmd:,.]}}use {it:#}th row of 
{cmd:e(}{it:name}{cmd:)}; may also type {it:name}{cmd:[}{it:#}{cmd:,]}
or {it:name}{cmd:[}{it:#}{cmd:]}
{p_end}
{p2col:{it:name}{cmd:[.,}{it:#}{cmd:]}}use {it:#}th column of 
{cmd:e(}{it:name}{cmd:)}; may also type {it:name}{cmd:[,}{it:#}{cmd:]}
{p_end}
{p2line}
{p2colreset}{...}

{marker at}{...}
{phang}
{cmd:at}[{cmd:(}{it:spec}{cmd:)}] causes plot positions to be determined
by the values in {cmd:e(at)} (or matrix {cmd:at}) or as specified by
{it:spec}.  The default is to create a categorical axis with coefficients
matched by their names.  However, if {cmd:at} is specified, the axis is
treated as continuous.  If {cmd:at} is specified, then labeling option
{cmd:coeflabels()}, {cmd:eqlabels()}, {cmd:headings()}, or {cmd:groups()} is
not allowed.  Also not allowed with {cmd:at} are options {cmd:bycoefs},
{cmd:order()}, and {cmd:relocate()}.  Furthermore, {cmd:at} has to be
specified for all models or for none.  {it:spec} is 

            [{it:atspec}] [{cmd:,} {opt t:ransform(exp)}]

{pmore}
    and {it:atspec} may be one of the following:

{p2colset 9 25 27 2}{...}
{p2col:{it:spec}}Description{p_end}
{p2line}
{p2col:{it:mspec}}as above for {helpb coefplot##b:b()}{p_end}
{p2col:{it:#}}use {it:#}th at-dimension ({manhelp margins R} only){p_end}
{p2col:{opt m:atrix(mspec)}}read from matrix instead of {cmd:e()}{p_end}
{p2col:{opt _coef}}use coefficient names as plot positions{p_end}
{p2col:{opt _eq}}use equation names as plot positions{p_end}
{p2line}
{p2colreset}{...}

{pmore}
If {cmd:at} is specified without argument, the plot positions are taken
from the first row of {cmd:e(at)} (or matrix {cmd:at}).  A special case
are results from {cmd:margins}, where recovering the plot positions is more
complicated.  The default in this case is to use the first at-dimension.
Type, for example, {cmd:at(2)} if multiple at-dimensions were specified
with {cmd:margins} and you want to use the second dimension.

{pmore}
When plotting results from {cmd:e()}, it is sometimes convenient to maintain
an external matrix with the plot positions instead of adding plot positions to
each {cmd:e()} set.  Here you can use syntax
{cmd:at(matrix(}{it:mspec}{cmd:))} to read the plot positions.  Note that
the vector of plot positions must have the same length as the coefficient
vectors of the plotted models; elements are matched by position, not by name.

{pmore}
Furthermore, {cmd:at(_coef)} or {cmd:at(_eq)} will use the coefficient
names or the equation names as plot positions, respectively.  This is useful
only if the coefficient names or the equation names are numeric.  Note that
you may use {helpb coefplot##rename:rename()} and
{helpb coefplot##eqrename:eqrename()} to strip a nonnumeric prefix or suffix 
from coefficient names or equation names.

{marker keep}{...}
{phang}
{cmd:keep(}{it:coeflist}{cmd:)} specifies the coefficients to be plotted.  The
default is to include all coefficients from the first (nonzero) equation of a
model and discard further equations.  {it:coeflist} is a space-separated list
of elements such as

{p2colset 9 25 27 2}{...}
{p2col:{it:coeflist}}Description{p_end}
{p2line}
{p2col:{it:coef}}keep coefficient {it:coef}
{p_end}
{p2col:{it:eq}{cmd::}}keep all coefficients from equation {it:eq}
{p_end}
{p2col:{it:eq}{cmd::}{it:coef}}keep coefficient {it:coef} from equation {it:eq}
{p_end}
{p2line}
{p2colreset}{...}

{pmore}
where {it:eq} and {it:coef} may contain {cmd:*} (any string) and {cmd:?} (any
nonzero character) wildcards.  For example, type {cmd:keep(*:)} or
{cmd:keep(*:*)} to plot all coefficients from all equations.

{pmore}
If {it:eq} is specified, it is applied to all subsequent names until a new
{it:eq} is specified.  For example, {cmd:keep(3:mpg price 4:weight)} will plot
coefficients {cmd:mpg} and {cmd:price} from equation {cmd:3} and coefficient
{cmd:weight} from equation {cmd:4}.

{marker drop}{...}
{phang}
{cmd:drop(}{it:coeflist}{cmd:)} drops the specified coefficients, where
{it:coeflist} is as above for {helpb coefplot##keep:keep()}.

{marker noci}{...}
{phang}
{cmd:noci} omits confidence intervals.

{marker levels}{...}
{phang}
{cmd:levels(}{it:{help numlist}}{cmd:)} sets the levels, as percentages, for
confidence intervals.  Specified values may be between 10.00 and 99.99 and can
have at most two digits after the decimal point.  The default is
{cmd:levels(95)} or as set by {helpb set level}.  If multiple values are
specified, multiple confidence intervals are plotted.  For example, type
{cmd:levels(99.9 99 95)} to plot the 99.9%, 99%, and 95% confidence intervals.
The default is to use (logarithmically) increasing line widths for multiple
confidence intervals.  This behavior is disabled as soon as {cmd:lwidth()} or
{cmd:recast()} is specified within {helpb coefplot##ciopts:ciopts()}.

{marker ci}{...}
{phang}
{cmd:ci(}{it:spec}{cmd:)} specifies the source from which to collect
confidence intervals.  The default is to compute confidence intervals for the
levels specified in {cmd:levels()} by using variances/standard errors (and,
possibly, degrees of freedom).  The {cmd:ci()} option is useful to plot
confidence intervals that have been provided by the estimation command (such
as, for example, {manhelp bootstrap R}).  {it:spec} is

            {it:cispec} [{it:cispec} ...]

{pmore}
where {it:cispec} is {it:name} to get the lower and upper confidence limits
from rows 1 and 2 of {cmd:e(}{it:name}{cmd:)} (or matrix {it:name}),
respectively.  Alternatively, {it:cispec} may be {cmd:(}{it:mspec}
{it:mspec}{cmd:)} to identify the lower and upper confidence limits, with
{it:mspec} as above for {helpb coefplot##b:b()}.  For example, after
{cmd:bootstrap}, {cmd:ci(ci_bc)} would get bias-corrected confidence
intervals from rows 1 and 2 of {cmd:e(ci_bc)}.  The same could be achieved by
{cmd:ci((ci_bc[1] ci_bc[2]))}.

{pmore}
{it:cispec} may also be {it:#} for a specific confidence level as in 
{helpb coefplot##levels:levels()}.  Hence, you may type, for example, 
{cmd:ci(95 myci)} to plot the usual 95% confidence intervals along
with custom confidence intervals provided in {cmd:e(myci)}.  Levels
specified in {cmd:ci()} take precedence over levels specified in
{cmd:levels()}.  However, you may also type {cmd:""} within
{cmd:ci()} to leave a position blank and use the specified level
from {cmd:levels()}.

{marker v}{...}
{phang}
{cmd:v(}{it:name}{cmd:)} specifies that the variances for confidence interval
computation are to be taken from the diagonal of {cmd:e(}{it:name}{cmd:)} (or
matrix {it:name}).  The default is {cmd:v(e(V))} (or {cmd:e(V_mi)} if plotting
results from {helpb mi estimate})..

{marker se}{...}
{phang}
{cmd:se(}{it:mspec}{cmd:)} provides standard errors to be used for
computation of confidence intervals.  The default is to compute confidence
intervals based on the variances in {cmd:e(V)} (see 
{helpb coefplot##v:v()} above).  {it:mspec} is as above for 
{helpb coefplot##b:b()}.

{marker df}{...}
{phang}
{cmd:df(}{it:spec}{cmd:)} specifies degrees of freedom (DF) to be taken
into account for confidence interval computation.  The default is to obtain DF
from scalar {cmd:e(df_r)} if defined (as in, for example, {helpb regress})
or, for results from {helpb mi estimate}, from matrix {cmd:e(df_mi)}.
Otherwise, no DF are taken into account.  Specify
{cmd:df(}{it:spec}{cmd:)} to provide custom DF.  {it:spec} may be

{p2colset 9 25 27 2}{...}
{p2col:{it:spec}}Description{p_end}
{p2line}
{p2col:{it:#}}set DF for all coefficients to {it:#}
{p_end}
{p2col:{it:mspec}}as above for {helpb coefplot##b:b()}{p_end}
{p2line}
{p2colreset}{...}

{marker citype}{...}
{phang}
{cmd:citype(logit}|{cmd:normal)} specifies the method to be used to compute
the limits of confidence intervals.  The default is {cmd:citype(normal)},
which computes confidence limits using untransformed coefficients and standard
errors.  Let b be the point estimate, se be the standard error, and
t be the (1-a/2) quantile of the standard normal distribution or the
t distribution (if DF are available; see above), where a is 1 minus the
confidence level (for example, a=5% for a 95% confidence interval).  Then
the limits of the {cmd:citype(normal)} confidence interval are defined as

            b +/- t * se

{pmore}
{cmd:citype(logit)} uses the logit transformation to compute the limits of
confidence intervals.  This is useful if the estimates to be plotted are
proportions and the confidence limits are supposed to lie between 0 and 1.
The limits of the {cmd:citype(logit)} confidence interval are computed as

            invlogit{logit(b) +/- t * se / [b * (1 - b)]}

{pmore}
(see {it:{mansection R proportionMethodsandformulas:Methods and formulas}}
in {mansection R proportion:{bf:[R] proportion}}).

{marker eform}{...}
{phang}
{cmd:eform}[{cmd:(}{it:coeflist}{cmd:)}] causes point estimates and confidence
intervals to be exponentiated.  This is useful if you want to plot hazard
ratios, incidence-rate ratios, odds ratios, or relative-risk ratios.  If
{cmd:eform} is specified without arguments, then all coefficients of the model
are exponentiated.  To exponentiate only selected coefficients, specify
{it:coeflist} as above for {helpb coefplot##keep:keep()}.

{marker rescale}{...}
{phang}
{cmd:rescale(}{it:spec}{cmd:)} rescales point estimates and confidence
intervals.  Type {cmd:rescale(}#{cmd:)} to rescale all coefficients by a
constant factor.  For example, {cmd:rescale(100)} will multiply all
coefficients by 100.  Alternatively, {it:spec} may be

            {it:coeflist} {cmd:=} {it:#} [{it:coeflist} {cmd:=} {it:#} ...]
    
{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}.

{marker transform}{...}
{phang}
{cmd:transform(}{it:matchlist}{cmd:)} transforms point estimates and
confidence intervals.  {it:matchlist} is

            {it:coeflist} {cmd:= "}{it:{help exp}}{cmd:"}  [{it:coeflist} {cmd:= "}{it:{help exp}}{cmd:"} ...]

{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}.  Within the
transformation expression, use {cmd:@} as a placeholder for the value to be
transformed.  For example, to take the square root of all coefficients, type
{cmd:transform(* = sqrt(@))}.  In addition, internal variables may be used as
explained in 
{it:{help coefplot##tempvar:Accessing internal temporary variables}}.  The transformation expression must be enclosed in double quotes
if it contains spaces.  If specified, {cmd:eform()} and {cmd:rescale()} are
applied before applying {cmd:transform()}.

{marker rename}{...}
{phang}
{cmd:rename(}{it:matchlist}{cmd:)} renames coefficients.  {it:matchlist} is

            {it:coeflist} {cmd:=} {it:newname} [{it:coeflist} {cmd:=} {it:newname} ...]

{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}, except the
wildcards are allowed only in equation names, and coefficient names may be
specified as {it:prefix}{cmd:*} to replace a prefix or {cmd:*}{it:suffix} to
replace a suffix.  For example, {cmd:rename(*.foreign = .cartype)} will rename
coefficients such as {cmd:0.foreign} and {cmd:1.foreign} to {cmd:0.cartype}
and {cmd:1.cartype}.  {it:newname} must be enclosed in double quotes if it
contains spaces.  For labeling coefficients, also see 
{helpb coefplot##coeflabels:coeflabels()}.

{marker eqrename}{...}
{phang}
{cmd:eqrename(}{it:matchlist}{cmd:)} renames equations.  {it:matchlist} is

            {it:eqlist} {cmd:=} {it:newname} [{it:eqlist} {cmd:=} {it:newname} ...]

{pmore}
where {it:eqlist} is a space-separated list of equation names.  Equation names
may be {it:prefix}{cmd:*} to replace a prefix or {cmd:*}{it:suffix} to replace
a suffix.  For example, {cmd:eqrename(rep78* = reprec)} will rename equations
such as {cmd:rep78_3} and {cmd:rep78_4} to {cmd:reprec_3} and {cmd:reprec_4}.
{it:newname} must be enclosed in double quotes if it contains spaces.  For
labeling equations, also see {helpb coefplot##eqlabels:eqlabels()}.

{marker asequation}{...}
{phang}
{cmd:asequation}[{cmd:(}{it:string}{cmd:)}] sets the equation name for all
included coefficients from the model to {it:string}.  This is useful to assign
an equation name to results that have been stored without information on
equations.  If {cmd:asequation} is specified without argument, the name of the
model is used.  If you apply the {cmd:asequation()} option, you may also want
to specify {helpb coefplot##eqstrict:eqstrict}.

{marker swapnames}{...}
{phang}
{cmd:swapnames} swaps coefficient names and equation names after collecting
the model's results.  The names are swapped after applying model options such
as {cmd:keep()}, {cmd:drop()}, or {cmd:rename()} but before applying global
options such as {cmd:coeflabel()}, {cmd:order()}, or {cmd:eqlabels()}.

{marker mlabels}{...}
{phang}
{cmd:mlabels2(}{it:matchlist}{cmd:)} specifies marker labels for coefficients.
{it:matchlist} is

            {it:coeflist} {cmd:=} {it:#} "{it:label}" [{it:coeflist} {cmd:=} {it:#} "{it:label}" ...]

{pmore}
where {it:coeflist} is as above for {helpb coefplot##keep:keep()}, and {it:#}
is a number 0-12 for the location of the marker label (see 
{manhelpi clockposstyle G-4}).

{marker aux}{...}
{phang}
{cmd:aux(}{it:mspec} [{it:mspec} ...]{cmd:)} collects additional results and
makes them available as internal variables.  {it:mspec} is as above for 
{helpb coefplot##b:b()}.  The internal variables are named {cmd:@aux1},
{cmd:@aux2}, ..., and can be used within {helpb coefplot##ifopt:ifopt()}, 
{helpb coefplot##weight:weightopt()}, {helpb coefplot##transform:transform()},
{helpb marker_label_options:mlabel()}, 
{helpb marker_label_options:mlabvposition()}, and 
{helpb addplot_option:addplot()} (see 
{it:{help coefplot##tempvar:Accessing internal temporary variables}} below).

{dlgtab:Plot options}

{marker label}{...}
{phang}
{cmd:label(}{it:string}{cmd:)} provides a label for the plot to be used in the
legend.  Use double quotes to create multiline labels.  For example,
{cmd:label("This is a" "long label")} would create a two-line label.  For text
effects (bold, italics, Greek letters, etc.) use Stata Markup and Control
Language (SMCL) tags as described in {manhelpi graph_text G-4}.

{marker key}{...}
{phang}
{cmd:key}[{cmd:(ci} [{it:#}]{cmd:)}] determines the key symbol to be used for
the plot in the legend. {cmd:key} without argument uses the plot's marker
symbol; this is the default. {cmd:key(ci)} determines the key symbol from the
(first) confidence interval. {cmd:key(ci} {it:#}{cmd:)} determines the key
symbol from the {it:#}th confidence interval; this is only useful if multiple
confidence intervals are included in the plot.

{marker nokey}{...}
{phang}
{cmd:nokey} prevents including the plot in the legend. 
    
{marker pstyle}{...}
{phang}
{cmd:pstyle(}{it:pstyle}{cmd:)} sets the overall style of the plot; see
{it:{manhelpi pstyle G-4}}.  {cmd:pstyle()} affects both coefficient markers
and confidence spikes.  To use a different plot style for confidence spikes,
add {cmd:pstyle()} within {helpb coefplot##ciopts:ciopts()}.

{marker axis}{...}
{phang}{cmd:axis(}{it:#}{cmd:)} specifies the scale axis to be used for the
plot, where {cmd:1} {ul:<} {it:#} {ul:<} {cmd:9}.  The default is to place all
plots on the same scale axis.

{marker offset}{...}
{phang}
{cmd:offset(}{it:#}{cmd:)} specifies a custom offset for the plot positions.
The default is to create automatic offsets to prevent overlap of confidence
spikes as soon as there are multiple plots.  The spacing between coefficients
is one unit, so {it:#} should usually be within -0.5 and 0.5.

{marker ifopt}{...}
{phang}
{cmd:ifopt(}{it:exp}{cmd:)} restricts the contents of the plot to coefficients
satisfying {it:exp}.  The option is useful when you want to select
coefficients, for example, based on their values, plot positions, or
confidence limits.  Within {it:exp}, refer to internal temporary variables as
explained in 
{it:{help coefplot##tempvar:Accessing internal temporary variables}} below.  For example, to include positive coefficients only, you
could type {cmd:ifopt(@b>=0)}.  Note that {cmd:ifopt()} does not affect the
rendition of the categorical axis (unless {helpb coefplot##at:at} is
specified).  That is, a complete categorical axis is created including labels
for all collected coefficients, even for the ones that have been removed from
the plot by {cmd:ifopt()}.

{marker weight}{...}
{phang}
{cmd:weightopt(}{it:exp}{cmd:)} scales the size of the markers according to
the size of the specified weights (see 
{it:{help scatter##remarks14:Weighted markers}} in {manhelp scatter G-2}).  Within {it:exp}, refer to internal
temporary variables as explained in 
{it:{help coefplot##tempvar:Accessing internal temporary variables}} below.  For example, to scale markers according
to the inverse of standard errors, type {cmd:weightopt(1/@se)}.
{cmd:weightopt()} has no effect if marker labels are specified.

{phang}
{it:marker_options} change the look of the coefficient markers (color, size,
etc.); see {it:{manhelpi marker_options G-3}}.

{marker mlabel}{...}
{phang}
{cmd:mlabel} adds point estimates as marker labels.  Use global option
{helpb coefplot##format:format()} to set the display format.  For adding
custom labels to specific markers, see model option 
{helpb coefplot##mlabels:mlabels2()} above.

{phang}
{it:marker_label_options} change the look and position of marker labels; see
{it:{manhelpi marker_label_options G-3}}.

{marker recast}{...}
{phang}
{cmd:recast(}{it:plottype}{cmd:)} plots the coefficients using {it:plottype};
supported plot types are {helpb scatter}, {helpb line}, 
{helpb twoway_connected:connected}, {helpb twoway_area:area}, 
{helpb twoway_bar:bar}, {helpb twoway_spike:spike}, 
{helpb twoway_dropline:dropline}, and {helpb twoway_dot:dot}.  The default is
{cmd:recast(scatter)}.  The chosen plot type affects the available plot
options.  For example, if the plot type is {helpb twoway_bar:bar}, then
{it:{help barlook_options}} will be available.  See the plot type's help file
for details.

{marker cionly}{...}
{phang}
{cmd:cionly} causes markers for point estimates to be suppressed.

{marker citop}{...}
{phang}
{cmd:citop} specifies that confidence intervals be drawn in front of the
markers for point estimates; the default is to draw confidence intervals
behind the markers.

{marker ciopts}{...}
{phang}
{cmd:ciopts(}{it:options}{cmd:)} affect the rendition of confidence intervals.
{it:options} are

{p2colset 9 28 30 2}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help line_options}}}change the look of spikes{p_end}
{p2col:{cmd:recast(}{it:plottype}{cmd:)}}plot the confidence intervals using 
{it:plottype}{p_end}
{p2line}
{p2colreset}{...}

{pmore}
Supported plot types are {helpb twoway_rarea:rarea}, {helpb twoway_rbar:rbar},
{helpb twoway_rspike:rspike}, {helpb twoway_rcap:rcap}, 
{helpb twoway_rcapsym:rcapsym}, {helpb twoway_rscatter:rscatter}, 
{helpb twoway_rline:rline}, and {helpb twoway_rconnected:rconnected}.  The
default is {cmd:ciopts(recast(rspike))}.  The chosen plot type
affects the available options within {cmd:ciopts()}.  For example, if the plot
type is {helpb twoway_rbar:rbar}, then {it:{help barlook_options}} will be
available.  See the plot type's help file for details.

{pmore}
If multiple confidence intervals are requested, then {it:{help stylelists}}
may be specified in the options within {cmd:ciopts()}.  For example,
{cmd:recast(rspike rcap ...)} would use {helpb twoway_rspike:rspike} for the
first confidence interval and {helpb twoway_rcap:rcap} for the remaining
confidence intervals; {cmd:lwidth(thin medium thick)} would use thin lines for
the first confidence interval, medium width lines for the second, and thick
lines for the third.

{marker cismooth}{...}
{phang}
{cmd:cismooth}[{cmd:(}{it:options}{cmd:)}] adds smoothed confidence intervals.
{it:options} may be one of the following:

{p2colset 10 33 35 2}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{cmd:n(}{it:n}{cmd:)}}number of (equally spaced) confidence levels; 
    default is {cmd:n(50)}; levels are placed in steps of 100/{it:n} from 100/2{it:n} to 
    100-100/2{it:n} (for example, 1, 3, 5, ..., 99 for {it:n}=50)
    {p_end}
{p2col:{cmdab:lw:idth(}{it:min max}{cmd:)}}set range of
    (relative) line widths; default is {cmd:range(2 15)}
    ({it:max} is exact only for {it:n}=50)
    {p_end}
{p2col:{cmdab:i:ntensity(}{it:min max}{cmd:)}}set range of 
    color intensities, as percentages; default is {cmd:intensity(}{it:min}
    {cmd:100)}, where {it:min} is determined as 4/(ceil({it:n}/2)+3)*100 (about 14 for {it:n}=50)
    {p_end}
{p2line}
{p2colreset}{...}

{pmore}
The confidence intervals produced by {cmd:cismooth} are placed behind
confidence intervals requested in {helpb coefplot##levels:levels()} and 
{helpb coefplot##ci:ci()}.  {helpb coefplot##ciopts:ciopts()} do not apply
to them.
    
{dlgtab:Subgraph options}

{marker bylabel}{...}
{phang}
{cmd:bylabel(}{it:string}{cmd:)} provides a label for the subgraph.  Use
double quotes to create multiline labels.  For example, 
{cmd:bylabel("This is a" "long label")} would create a two-line label.  For
text effects (bold, italics, Greek letters, etc.), use SMCL tags as described
in {manhelpi graph_text G-4}.
    
{pmore}
Subgraphs are implemented in terms of {helpb graph}'s {cmd:by()} option; see
{helpb coefplot##byopts:byopts()} below for options on how to combine and
render the subgraphs.

{dlgtab:Global options}

{marker horizontal}{...}
{phang}
{cmd:horizontal} places coefficient values on the x axis.  This is the default
unless {helpb coefplot##at:at} is specified.

{marker vertical}{...}
{phang}
{cmd:vertical} places coefficient values on the y axis.  This is the default
if {helpb coefplot##at:at} is specified.

{marker relocate}{...}
{phang}
{cmd:relocate(}{it:spec}{cmd:)} assigns specific positions to the coefficients
on the category axis.  {it:spec} is
    
            [{it:eq}{cmd::}]{it:coef} {cmd:=} {it:#} [[{it:eq}{cmd::}]{it:coef} {cmd:=} {it:#} ...]
    
{pmore}
where {it:eq} and {it:coef} may contain {cmd:*} (any string) and {cmd:?}
(any nonzero character) wildcards.  If {helpb coefplot##bycoefs:bycoefs} is
specified, use numbers (1, 2, ...) instead of {it:eq} and {it:coef} to address
the elements on the categorical axis.

{pmore}
The default for {cmd:coefplot} is to place coefficients at integer values 1,
2, 3, ... (from top to bottom in horizontal mode, and from left to right in
vertical mode).  The {cmd:relocate()} option allows you to specify alternative
values.  If, for example, you want to place coefficient {cmd:mpg} at value 2.5
on the category axis, you could type {cmd:relocate(mpg = 2.5)}.  If you only
want to change the order of coefficients and are fine with integer positions,
then use the {helpb coefplot##order:order()} option.  Note that the specified
positions are assigned before inserting gaps between equations, headings, and
groups (see {helpb coefplot##eqlabels:eqlabels()}, 
{helpb coefplot##headings:headings()}, and {helpb coefplot##groups:groups()}).
Hence, the final plot positions might deviate from the specified positions if
there are equation labels, headings, or group labels.

{marker eqstrict}{...}
{phang}
    {cmd:eqstrict} causes equation names to be taken into account (i.e. match coefficients by
    equation names and plot equation labels) even if there is only one equation per model.

{marker order}{...}
{phang}
{cmd:order(}{it:coeflist}{cmd:)} specifies the order of coefficients (not
allowed with {helpb coefplot##at:at}).  The default is to use the order as
found in the input models (and place {cmd:_cons} last, within equations).
{it:coeflist} is a space-separated list of elements such as the following:

{p2colset 9 28 30 2}{...}
{p2col:{it:coeflist}}Description{p_end}
{p2line}
{p2col:{cmd:.}}insert a gap
    {p_end}
{p2col:{it:eq}{cmd::.}}insert a gap within equation {it:eq}
    {p_end}
{p2col:{it:coef}}coefficient {it:coef}
    {p_end}
{p2col:{it:eq}{cmd::}}all coefficients from equation {it:eq}, in their current order
    {p_end}
{p2col:{it:eq}{cmd::}{it:coef}}coefficient {it:coef} from equation {it:eq}
    {p_end}
{p2line}
{p2colreset}{...}

{pmore}
where {it:coef} may contain {cmd:*} (any string) and {cmd:?} (any nonzero
character) wildcards.

{pmore}
If no equations are specified, then the requested order of coefficients is
repeated within each equation (keeping the existing order of equations).
Otherwise, the requested order is applied across equations.  Note that in the
later case, the first element in {cmd:order()} must be an equation name.
{it:eq} is applied to all subsequent elements until a new {it:eq} is
specified.  For example, {cmd:order(5:weight mpg * 4:turn *)} would yield the
following order: {cmd:weight} from equation {cmd:5}, {cmd:mpg} from equation
{cmd:5}, remaining coefficients from equation {cmd:5}, {cmd:turn} from
equation {cmd:4}, remaining coefficients from equation {cmd:4}, remaining
equations (if any).

{marker bycoefs}{...}
{phang}
{cmd:bycoefs} flips subgraphs and coefficients (not allowed with 
{helpb coefplot##at:at}).  If {cmd:bycoefs} is specified, a separate
subgraph is produced for each coefficient.  In this case, use integer numbers
(1, 2, ...) instead of coefficient names  to address the elements on the
categorical axis within options {helpb coefplot##relocate:relocate()}, 
{helpb coefplot##headings:headings()}, and {helpb coefplot##groups:groups()}.

{marker norecycle}{...}
{phang}
{cmd:norecycle} increments plot styles across subgraphs.  The default is to
start over with each new subgraph.

{marker nooffsets}{...}
{phang}
{cmd:nooffsets} suppresses automatic offsets for plot positions.

{marker format}{...}
{phang}
{cmd:format(}{it:format}{cmd:)} sets the display format for coefficients.
This affects the rendition of the axis and marker labels.  {it:format} may be
a numeric format or a date format (see {manhelp format D}).

{marker nolabels}{...}
{phang}
{cmd:nolabels} causes coefficients' names to be used as labels instead of
variable labels or value labels.

{marker coeflabels}{...}
{phang}
{cmd:coeflabels(}{it:spec}{cmd:)} specifies custom labels for coefficients
(not allowed with {helpb coefplot##at:at}).  {it:spec} is

{p 12 14 2}
[{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} [{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} ...]]
[{cmd:,} {cmdab:t:runcate(}#{cmd:)} {cmdab:w:rap(}#{cmd:)} {cmdab:nob:reak} 
{cmdab:i:nteraction(}{it:string}{cmd:)}
{it:{help axis_label_options:suboptions}}]

{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}.  Enclose
{it:label} in double quotes if it contains spaces, for example,
{bind:{cmd:coeflabels(foreign = "Car Type")}}.  Enclose {it:label} in compound
double quotes to create a multiline label, for example,
{bind:{cmd:coeflabels(foreign = `""This is a" "long label""')}}.
Alternatively, apply the {cmd:wrap()} option.  For text effects (bold,
italics, Greek letters, etc.), use SMCL tags as described in 
{manhelpi graph_text G-4}.

{pmore}
Option {opt truncate(#)} truncates coefficient labels to a maximum
length of {it:#} characters.  Option {opt wrap(#)} divides coefficient
labels into multiple lines, where each line has a maximum length of {it:#}
characters.  {cmd:truncate()} and {cmd:wrap()} operate on words.  That is,
they try to fill to the maximum length without breaking in the middle of a
word.  However, if a word is longer than {it:#} characters, it will be split
or truncated.  Specify {cmd:nobreak} to prevent {cmd:truncate()} and
{cmd:wrap()} from splitting or truncating words that are longer than {it:#}
characters.  If {cmd:truncate()} and {cmd:wrap()} are both specified,
{cmd:truncate()} is applied first.  {cmd:interaction()} specifies the string
to be used as delimiter in labels for interaction terms; the default is
{cmd:interaction(" # ")}.  {it:suboptions} are axis label suboptions as
described in {manhelpi axis_label_options G-3}.

{pmore}
Labels containing multiple lines are left unchanged by {cmd:truncate()} and
{cmd:wrap()}.  Therefore, if you do not like how {cmd:wrap()} breaks a
specific label, you can provide a custom variant of it in {cmd:coeflabels()}
while still using {cmd:wrap()} for the other labels.  {cmd:truncate()} and
{cmd:wrap()} may fail to process a label if it contains compound double
quotes; the label will be left unchanged in this case.

{marker noeqlabels}{...}
{phang}
{cmd:noeqlabels} suppresses equation labels.

{marker eqlabels}{...}
{phang}
{cmd:eqlabels(}{it:spec}{cmd:)} specifies custom labels for equations, one
after the other (not allowed with {helpb coefplot##at:at}).  {it:spec} is

{p 12 14 2}
[{cmd:"}{it:label}{cmd:"} [{cmd:"}{it:label}{cmd:"} ...]] [{cmd:,}
[{cmd:{ul:no}}]{cmdab:g:ap}[{cmd:(}#{cmd:)}]  {cmdab:ashead:ings}
{cmdab:off:set(}#{cmd:)} {cmdab:t:runcate(}#{cmd:)} {cmdab:w:rap(}#{cmd:)}
{cmdab:nob:reak} {it:{help axis_label_options:suboptions}}]

{pmore}
Enclose labels in double quotes if they contain spaces, for example,
{bind:{cmd:eqlabels("EQ one" "EQ two")}}.  Enclose labels in compound double
quotes to create multiline labels, for example, 
{bind:{cmd:eqlabels(`""This is a" "long label""')}}.  Alternatively, apply the {cmd:wrap()} option.  For text
effects (bold, italics, Greek letters, etc.), use SMCL tags as described in
{manhelpi graph_text G-4}.

{pmore}
{cmd:gap()} specifies the size of the gap between equations.  The default is
{cmd:gap(1)}.  {cmd:nogap} suppresses the gap between equations.
{cmdab:asheadings} treats equation labels as headings; see 
{helpb coefplot##headings:headings()}.  {cmd:offset()}, only allowed with
{cmd:asheadings}, offsets the labels.  {cmd:truncate()}, {cmd:wrap()},
{cmd:nobreak}, and {it:suboptions} are as above for 
{helpb coefplot##coeflabels:coeflabels()}.

{marker headings}{...}
{phang}
{cmd:headings(}{it:spec}{cmd:)} adds headings between coefficients (not
allowed with {helpb coefplot##at:at}).  {it:spec} is

{p 12 14 2}
{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} [{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} ...] 
[{cmd:,} [{cmd:{ul:no}}]{cmdab:g:ap}[{cmd:(}#{cmd:)}] 
{cmdab:off:set(}#{cmd:)} {cmdab:t:runcate(}#{cmd:)} 
{cmdab:w:rap(}#{cmd:)} {cmdab:nob:reak} 
{it:{help axis_label_options:suboptions}}]

{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}.  If 
{helpb coefplot##bycoefs:bycoefs} is specified, use numbers 1, 2, ... instead of
{it:coeflist} to address the elements on the categorical axis.  Enclose
{it:label} in double quotes if it contains spaces.  For example,
{bind:{cmd:headings(0.foreign = "Car Type")}} will print the heading 
"{cmd:Car Type}" before coefficient "{cmd:0.foreign}".  Enclose {it:label} in
compound double quotes to create a multiline label, for example,
{bind:{cmd:headings(foreign = `""This is a" "long heading""')}}.
Alternatively, apply the {cmd:wrap()} option.  For text effects (bold,
italics, Greek letters, etc.), use SMCL tags as described in 
{manhelpi graph_text G-4}.

{pmore}
{cmd:gap()} and {cmdab:offset()} are as above for 
{helpb coefplot##eqlabels:eqlabels()}.  {cmd:truncate()}, {cmd:wrap()},
{cmd:nobreak}, and {it:suboptions} are as above for 
{helpb coefplot##coeflabels:coeflabels()}.

{marker groups}{...}
{phang}
{cmd:groups(}{it:spec}{cmd:)} adds labels for groups of 
coefficients (not allowed with {helpb coefplot##at:at}).  The specified 
label will be printed beside (or, in vertical mode, below) the identified 
group of coefficients.  {it:spec} is

{p 12 14 2}
{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} [{it:coeflist} {cmd:=} {cmd:"}{it:label}{cmd:"} ...] 
[{cmd:,} [{cmd:{ul:no}}]{cmdab:g:ap}[{cmd:(}#{cmd:)}] 
{cmdab:t:runcate(}#{cmd:)} {cmdab:w:rap(}#{cmd:)} 
{cmdab:nob:reak} {it:{help axis_label_options:suboptions}}]

{pmore}
with {it:coeflist} as above for {helpb coefplot##keep:keep()}.  If 
{helpb coefplot##bycoefs:bycoefs} is specified, use numbers 1, 2, ... instead
of {it:coeflist} to address the elements on the categorical axis.  Enclose
{it:label} in double quotes if it contains spaces.  Enclose {it:label} in
compound double quotes to create a multiline label.  Alternatively, apply the
{cmd:wrap()} option.  For text effects (bold, italics, Greek letters, etc.),
use SMCL tags as described in {manhelpi graph_text G-4}.

{pmore}
{cmd:gap()} is as above for {helpb coefplot##eqlabels:eqlabels()}.
{cmd:truncate()}, {cmd:wrap()}, {cmd:nobreak}, and {it:suboptions} are as
above for {helpb coefplot##coeflabels:coeflabels()}.

{marker plotlabels}{...}
{phang}
{cmd:plotlabels(}{it:spec}{cmd:)} specifies labels for the plots to be used in
the legend.  Labels specified via {cmd:plotlabels()} take precedence over
labels specified in the {helpb coefplot##label:label()} plot option.  {it:spec}
is

{p 12 14 2}
[{cmd:"}{it:label}{cmd:"} [{cmd:"}{it:label}{cmd:"} ...]] [{cmd:,} {cmdab:t:runcate(}#{cmd:)} 
{cmdab:w:rap(}#{cmd:)} {cmdab:nob:reak}]

{pmore}
Enclose labels in double quotes if they contain spaces.  Enclose labels in
compound double quotes to create multiline labels.  Alternatively, apply the
{cmd:wrap()} option.  For text effects (bold, italics, Greek letters, etc.),
use SMCL tags as described in {manhelpi graph_text G-4}.  Options
{cmd:truncate()}, {cmd:wrap()}, and {cmd:nobreak} are as above for 
{helpb coefplot##coeflabels:coeflabels()}.

{marker bylabels}{...}
{phang}
{cmd:bylabels(}{it:spec}{cmd:)} specifies labels for the subgraphs.  Labels
specified via {cmd:bylabels()} take precedence over labels specified in the
{helpb coefplot##bylabel:bylabel()} subgraph option.  {it:spec} is

{p 12 14 2}
[{cmd:"}{it:label}{cmd:"} [{cmd:"}{it:label}{cmd:"} ...]] [{cmd:,} {cmdab:t:runcate(}#{cmd:)} 
{cmdab:w:rap(}#{cmd:)} {cmdab:nob:reak}]

{pmore}
Enclose labels in double quotes if they contain spaces.  Enclose labels in
compound double quotes to create multiline labels.  Alternatively, apply the
{cmd:wrap()} option.  For text effects (bold, italics, Greek letters, etc.),
use SMCL tags as described in {manhelpi graph_text G-4}.  Options
{cmd:truncate()}, {cmd:wrap()}, and {cmd:nobreak} are as above for 
{helpb coefplot##coeflabels:coeflabels()}.

{marker grid}{...}
{phang}
{cmd:grid(}{it:options}{cmd:)} affects the rendition of grid lines on
the category axis (not allowed with {helpb coefplot##at:at}).
{it:options} are

{p 12 14 2}
    {{cmdab:b:etween}|{cmdab:w:ithin}|{cmdab:n:one}} {it:{help axis_label_options:suboptions}}

{pmore}
{cmd:between} places grid lines between coefficient labels; {cmd:within}
places grid lines at the center of coefficient labels; {cmd:none} suppresses
grid lines.  {it:suboptions} are axis label suboptions as described in
{manhelpi axis_label_options G-3}.  In horizontal mode, the default is
{cmd:within} for single plots and {cmd:between} for multiple plots.  In
vertical mode, the default is {cmd:none}.  Alternatively, use 
{helpb axis_label_options:ytick()} and {helpb axis_label_options:xtick()} to
set grid lines.

{marker generate}{...}
{phang}
{cmd:generate}[{cmd:(}{it:prefix}{cmd:)}] generates variables containing the
graph data.  The variable names will be prefixed by {cmd:__} or as specified
by {it:prefix}.

{marker replace}{...}
{phang}
{cmd:replace} allows {cmd:coefplot} to overwrite existing variables.

{phang}
{cmd:addplot(}{it:plot}{cmd:)} provides a way to add other plots to the
generated graph; see {it:{manhelpi addplot_option G-3}}.

{marker nodrop}{...}
{phang}
    {cmd:nodrop} causes {cmd:coefplot} to keep all observations when generating
    the graph. The default is to eliminate unused observations temporarily 
    to increase speed.  {cmd:nodrop} may be useful in connection with the 
    {helpb coefplot##addplot:addplot()} option, if the graph does not contain 
    multiple subgraphs. {cmd:nodrop} has no effect if 
    {helpb coefplot##generate:generate()} is specified.
    {p_end}

{phang}
{it:twoway_options} are any of the options documented in 
{it:{manhelpi twoway_options G-3}}, excluding {cmd:by()}.

{marker byopts}{...}
{phang}
{cmd:byopts(}{it:byopts}{cmd:)} determines how subgraphs are combined.
{it:byopts} are as described in {it:{manhelpi by_option G-3}}.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

        {help coefplot##place:Placement of options} 
        {help coefplot##matrix:Plotting results from matrices}
        {help coefplot##tempvar:Accessing internal temporary variables}


  {marker place}{...}
  {title:Placement of options}

{pstd}
{cmd:coefplot} has four levels of options:

{phang}
1) {help coefplot##modelopts:{it:modelopts}} are options that apply to a
single model (or matrix).  They specify the information to be displayed.

{phang}
2) {help coefplot##plotopts:{it:plotopts}} are options that apply to a
single plot, possibly containing results from multiple models.  They
affect the rendition of markers and confidence intervals and provide a
label for the plot.

{phang}
3) {help coefplot##subgropts:{it:subgropts}} are options that apply to a
single subgraph, possibly containing multiple plots.

{phang}
4) {help coefplot##globalopts:{it:globalopts}} are options that apply to the
overall graph.

{pstd}
The levels are nested in the sense that upper-level options include all lower-level options.  That is, {help coefplot##globalopts:{it:globalopts}} includes
{help coefplot##subgropts:{it:subgropts}}, 
{help coefplot##plotopts:{it:plotopts}}, and 
{help coefplot##modelopts:{it:modelopts}}; 
{help coefplot##subgropts:{it:subgropts}} includes 
{help coefplot##plotopts:{it:plotopts}} and 
{help coefplot##modelopts:{it:modelopts}}; and 
{help coefplot##plotopts:{it:plotopts}} includes 
{help coefplot##modelopts:{it:modelopts}}.  However, upper-level options may
not be specified at a lower level.

{pstd}
If lower-level options are specified at an upper level, they serve as defaults
for all included lower-level elements.  For example, if you want to draw 99%
and 95% confidence intervals for all included models, specify 
{cmd:levels(99 95)} as a global option.

{phang2}
{cmd:. coefplot model1 model2 model3, levels(99 95)}

{pstd}
Options specified with an individual element override the defaults set by
upper-level options.  For example, if you want to draw 99% and 95% confidence
intervals for model 1 and model 2 and 90% confidence intervals for model 3,
you could type

{phang2}
{cmd:. coefplot model1 model2 (model3, level(90)), levels(99 95)}

{pstd}
There are some fine distinctions about the placement of options and how
they are interpreted.  For example, if you type

{phang2}
{cmd:. coefplot m1, {txt:{it:opts1}} || m2, {txt:{it:opts2}} {txt:{it:opts3}}}

{pstd}
then {it:opts2} and {it:opts3} are interpreted as global options.  If
you want to apply {it:opts2} only to {cmd:m2}, then type

{phang2} 
{cmd:. coefplot m1, {txt:{it:opts1}} || m2, {txt:{it:opts2}} ||, {txt:{it:opts3}}}

{pstd}
Similarly, if you type

{phang2} 
{cmd:. coefplot (m1, {txt:{it:opts1}} \ m2, {txt:{it:opts2}})}

{pstd}
then {it:opts2} will be applied to both models.  To apply {it:opts2} only
to {cmd:m2}, type

{phang2} 
{cmd:. coefplot (m1, {txt:{it:opts1}} \ m2, {txt:{it:opts2}}\)}

{pstd}
or, if you also want to include {it:opts3} to be applied to both models,
type

{phang2} 
{cmd:. coefplot (m1, {txt:{it:opts1}} \ m2, {txt:{it:opts2}} \, {txt:{it:opts3}})}

{pstd}
or

{phang2} 
{cmd:. coefplot (m1, {txt:{it:opts1}} \ m2, {txt:{it:opts2}} \), {txt:{it:opts3}}}

{pstd}
For multiple subgraphs, there is some ambiguity about where to specify the
plot options (unless global option {helpb coefplot##norecycle:norecycle} is
specified).  You can provide plot options with any of the models because plot
options are collected across subgraphs.  However, in case of conflict, the
plot options from the rightmost subgraph usually take precedence over earlier
plot options.


  {marker matrix}{...}
  {title:Plotting results from matrices}

{pstd}
Use syntax {opt matrix(mspec)} instead of the name of a stored model to plot
results from a matrix.  {it:mspec} may be one of the following:

{p2colset 9 21 23 2}{...}
{p2col:{it:name}}use first row of matrix {it:name}{p_end}
{p2col:{it:name}{cmd:[}{it:#}{cmd:,.]}}use {it:#}th row of 
matrix {it:name}; may also type {it:name}{cmd:[}{it:#}{cmd:,]} or 
{it:name}{cmd:[}{it:#}{cmd:]}
{p_end}
{p2col:{it:name}{cmd:[.,}{it:#}{cmd:]}}use {it:#}th column of 
matrix {it:name}; may also type {it:name}{cmd:[,}{it:#}{cmd:]}
{p_end}
{p2colreset}{...}

{pstd}
If the {cmd:matrix()} syntax is used, then option {helpb coefplot##b:b()}
is discarded and names given in {helpb coefplot##at:at()}, 
{helpb coefplot##ci:ci()}, {helpb coefplot##v:v()}, 
{helpb coefplot##se:se()}, {helpb coefplot##df:df()}, and 
{helpb coefplot##aux:aux()} refer to regular matrices instead of {cmd:e()}
matrices.

{pstd}
For example, to plot medians and their confidence intervals as computed by
{helpb centile}, you could type

{phang2}{cmd:sysuse auto}{p_end}
{phang2}{cmd:matrix C = J(3,3,.)}{p_end}
{phang2}{cmd:matrix colnames C = median ll95 ul95}{p_end}
{phang2}{cmd:matrix rownames C = mpg trunk turn}{p_end}
{phang2}{cmd:local i 0}{p_end}
{phang2}{cmd:foreach v of var mpg trunk turn}{p_end}
{phang2}{cmd:{c -(}}{p_end}
{phang3}{cmd:local ++ i}{p_end}
{phang3}{cmd:centile `v'}{p_end}
{phang3}{cmd:matrix C[`i',1] = r(c_1), r(lb_1), r(ub_1)}{p_end}
{phang2}{cmd:{c )-}}{p_end}
{phang2}{cmd:matrix list C}{p_end}
{phang2}{cmd:coefplot matrix(C[,1]), ci((C[,2] C[,3]))}{p_end}

{pstd}
Note that a single {cmd:coefplot} command can contain both regular syntax and
{cmd:matrix()} syntax.  For example, to add means to the graph above, you
could type

{phang2}{cmd:mean mpg trunk turn}{p_end}
{phang2}{cmd:estimates store mean}{p_end}
{phang2}{cmd:coefplot (matrix(C[,1]), ci((C[,2] C[,3]))) (mean)}{p_end}


  {marker tempvar}{...}
  {title:Accessing internal temporary variables}

{pstd}
{cmd:coefplot} maintains a number of internal variables that can be used
within {helpb coefplot##ifopt:ifopt()}, {helpb coefplot##weight:weightopt()}, 
{helpb coefplot##transform:transform()}, 
{helpb marker_label_options:mlabel()}, 
{helpb marker_label_options:mlabvposition()}, and 
{helpb addplot_option:addplot()}.  These variables are

{p2colset 9 21 23 2}{...}
{p2col:{cmd:@b}}point estimates
{p_end}
{p2col:{cmd:@ll}#}lower limits of confidence interval {it:#} (may use {cmd:@ll} for {cmd:@ll1})
{p_end}
{p2col:{cmd:@ul}#}upper limits of confidence interval {it:#} (may use {cmd:@ul} for {cmd:@ul1})
{p_end}
{p2col:{cmd:@V}}variances
{p_end}
{p2col:{cmd:@se}}standard errors
{p_end}
{p2col:{cmd:@df}}DF{p_end}
{p2col:{cmd:@at}}plot positions{p_end}
{p2col:{cmd:@plot}}plot ID (labeled)
{p_end}
{p2col:{cmd:@by}}subgraph ID (labeled)
{p_end}
{p2col:{cmd:@mlbl}}Marker labels set by {helpb coefplot##mlabels:mlabels2()} (string variable)
{p_end}
{p2col:{cmd:@mlpos}}Marker label positions set by {helpb coefplot##mlabels:mlabels2()}
{p_end}
{p2col:{cmd:@aux}#}auxiliary variables collected by {helpb coefplot##aux:aux()} (may use {cmd:@aux} for {cmd:@aux1})
{p_end}
{p2colreset}{...}

{pstd}
The internal variables can be used like other variables in the dataset.  For
example, option {cmd:mlabel(@plot)} would add plot labels as marker labels or
option {cmd:addplot(line @at @b)} would draw a connecting line through all
point estimates in the graph.


{marker examples}{...}
{title:Examples}

{phang}{bf:. {stata sysuse auto}}{p_end}
{phang}{bf:. {stata regress price mpg headroom trunk length turn}}{p_end}
{phang}{bf:. {stata coefplot, drop(_cons) xline(0)}}{p_end}
{phang}{bf:. {stata regress price mpg headroom trunk length turn if foreign==0}}{p_end}
{phang}{bf:. {stata estimates store domestic}}{p_end}
{phang}{bf:. {stata regress price mpg headroom trunk length turn if foreign==1}}{p_end}
{phang}{bf:. {stata estimates store foreign}}{p_end}
{phang}{bf:. {stata coefplot domestic foreign, drop(_cons) xline(0)}}{p_end}
{phang}{bf:. {stata coefplot domestic || foreign, drop(_cons) xline(0)}}{p_end}
{phang}{bf:. {stata coefplot domestic || foreign, yline(0) bycoefs vertical byopts(yrescale)}}{p_end}

{pstd}
For further examples, see Jann (2014).


{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:coefplot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n_ci)}}number of confidence intervals{p_end}
{synopt:{cmd:r(n_plot)}}number of plots{p_end}
{synopt:{cmd:r(n_subgr)}}number of subgraphs{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(graph)}}copy of {cmd:graph} command{p_end}
{synopt:{cmd:r(labels)}}coefficient labels{p_end}
{synopt:{cmd:r(eqlabels)}}equation labels{p_end}
{synopt:{cmd:r(groups)}}group labels{p_end}
{synopt:{cmd:r(headings)}}headings{p_end}


{marker references}{...}
{title:Reference}

{phang}
Jann, B. 2014. {browse "http://www.stata-journal.com/article.html?article=gr0059":Plotting regression coefficients and other estimates}.
{it:Stata Journal} 14: 708-737.


{marker author}{...}
{title:Author}

{pstd}Ben Jann{p_end}
{pstd}University of Bern{p_end}
{pstd}Bern, Switzerland{p_end}
{pstd}jann@soz.unibe.ch
{* {title:History}}
{*  08dec2014 (1.7.4)}
{*  - fysize() and fxsize() did not work in case of multiple plots; this is}
{*    fixed}
{*  - there was a small chance that coefplot left behind a mata object if the}
{*    user pressed break; this is fixed}
{*  - option -nodrop- added}
{*  - now uses "equation" as plot label instead of ".=equation" if model is .}
{*  - twoway plot options such as msymbol() were not correctly passed through}
{*    to the plots if specified at the subgraph level; this is fixed}
{*  - collecting plot options across subgraphs has been improved (not relevant}
{*    if norecycle is specified); the rules are: (1) plot options specified at}
{*    a lower level take precedence over later plot options specified at an}
{*    upper level. (2) within level, the rightmost option is used.}
{*  - coefplot now picks up results from e(b_mi) and e(V_mi) by default if}
{*    plotting results from -mi estimate-}
{*  - transform() suboption added to at()}
{*  - interaction() suboption added to coeflabels()}
{*  - plot options key() and nokey added}
{*  - replace option could fail due to conflicts with existing labels; this is}
{*    fixed}
{*    05jun2014 (1.7.1)}
{*    - grid() now allows suboptions}
{*    15may2014 (1.7.0)}
{*    - internal variables are now accessed as @b, @ll, @ul, ...}
{*   (syntax \`...' is discontinued)}
{*   - variances, SEs and DFs now available as internal variables (@V, @se, @df)}
{*   - {cmd:mlabels2()} option added}
{*   - {cmd:transform()} option added}
{*   - {cmd:aux()} option added}
{*   - {cmd:weightopt()} option added}
{*   - {cmd:asequation} now allowed without argument}
{*   - default prefix for {cmd:generate()} is now {cmd:__}}
{*   - CIs are now stored in wide format (that is, as separate variables)}
{*   26feb2014 (1.6.5)}
{*   - {cmd:ifopt()} option added}
{*   29jan2014 (version 1.6.1)}
{*   - {cmd:citype(logit}|{cmd:normal)} added}
{*   - {cmd:ciname()} now uses syntax {cmd:ciname((ll ul)} ...{cmd:)}}
{*   {cmd:ciname("ll ul"} ...{cmd:)} is still supported but undocumented}
{*   - option {cmd:swapnames} added}
{*   - options {cmd:atname(_coef)} and {cmd:atname(_eq)} added}
{*   23nov2013 (version 1.5.8)}
{*   - improved recovery of plot positions from {cmd:e(at)} for margins}
{*   - syntax {cmd:atname(matrix(}...{cmd:))} now possible}
{*   - {cmd:axis()} option added}
{*   - new suboptions in {cmd:eqlabels()}, {cmd:groups()}, {cmd:headings()}:}
{*   {cmd:gap()}, {cmd:wrap()}, {cmd:truncate()}, {cmd:nobreak}}
{*   - {cmd:plotlabels()} and {cmd:bylabels()} options added}
{*   28aug2013 (version 1.5.4)}
{*   - {cmd:cismooth()} added; {cmd:cishade} removed}
{*   - problem with too many {cmd:ciopts()} fixed}
{*   26aug2013 (version 1.5.2)}
{*   - {cmd:pstyle()} are now sensitive to plot types}
{*   25aug2013 (version 1.5.1)}
{*   - {cmd:coefplot} released on SSC}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 15, number 1: {browse "http://www.stata-journal.com/article.html?article=up0046":gr0059_1},{break}
                    {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=gr0059":gr0059}{p_end}
