cd $raw
use 2008_qclean_XXXX.dta, clear

global mybase "2009 2010 2011 2012 2013 2014 2015 2016"

foreach base in $mybase {

	append using `base'_qclean_XXXX.dta

}

	drop y
	gen y = int(date/100)
	gen m =  mod(date,100)
	gen d = ym(y,m)
	format d %tm
	gen timed = dofm(d)
	gen timeq = qofd(timed)
	format timeq %tq
	cap drop timed m date
	rename timeq dq
	rename d dm
	order y dq dm
	drop dm

	bys siren (y) : gen first = _n == 1
	gen lme_f = lme if first == 1
	egen lme_first = max(lme_f), by(siren)
	cap drop lme_f first

	keep if inrange(lme_first,1,4)

	egen indcheck = mean(independent), by(siren)
	replace indcheck = 0 if indcheck < 1
	lab var indcheck "Independent all life long"
	save cn20082016_sme_panel_qtr_SME, replace

	use cn20082016_sme_panel_qtr_SME, clear

	cap drop siren_branch
	cap drop sirenstr

	egen siren_branch = group(siren cibbranch)
	rename zip_code zcf
	rename zip_code_branch zcb

	order siren_branch dq siren cibbranch zcf zcb county loan
	xtset siren_branch dq

	sort siren_branch dq
	gen tot_exp = loan + ie + it + af + tot_cb + guarantee
	order siren cibbranch dq loan tot_exp  ie it oc od af tot_cb guarantee

	preserve
	replace tot_exp = 0 if loan == .
	collapse (mean) tot_exp, by(siren dq)
		cap drop _end _seq _spell lenght
		tsset siren dq
		tsspell, f(L.dq == .)
		bys siren _spell : egen lenght = max(_seq)
		keep if lenght > 7
		gen panel = 1
		collapse(mean) panel, by(siren)
		keep siren panel
	save $raw/panel_siren_sme_qtr.dta, replace
	restore

	merge m:1 siren using $raw/panel_siren_sme_qtr.dta
	keep if panel == 1

	save cn20082016_sme_panel_qtr_SME_clean, replace
