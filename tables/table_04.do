{

	use cib date_arrete S06_1420 S07_1620 using $bdf\cpte_resu_france_final.dta, replace
	gen int year = floor(date_arrete / 10000)
	gen double minus_loss = -S07_1620
	egen double ni_is = rowtotal(S06_1420 minus_loss), missing
	replace ni_is = ni_is / 1000
	keep cib year ni_is
	save $raw\t4_ni_is.dta, replace

	use $raw\bank_level_regression, replace

	egen bhc_year = group(gea year)

	gen zero_inc = (net_income == 0)
	bys cib : egen nb_zero = sum(zero_inc)
	keep if nb_zero == 0

	gen size = ln(b_totsize)
	xtset cib year
	foreach var in liq_ratio size b_badassets {
	gen `var'_lag = L1.`var'
	}

	drop if year < 2011
	gen i = 1
	bys cib : egen pres = sum(i)
	keep if pres == 5
	drop i pres

	egen _tagb = tag(cib)
	xtile _DRq0 = dr_entry if _tagb , nq(4)
	egen DRq = max(_DRq0) , by(cib)
	drop _tagb _DRq0
	gen high_dr = (DRq > 2)

	merge 1:1 cib year using $raw\bank_deposit_cost.dta, keepusing(deposit_expense avg_deposits) keep(master match) nogen
	merge 1:1 cib year using $raw\t4_ni_is.dta, keep(master match) nogen

	gen pre = (year < 2013)
	gen double pre_cont  = pre * dr_entry
	gen double pre_top50 = pre * high_dr

	save $raw\t4_frame.dta, replace

	use $raw\t4_frame.dta, replace
	gen double rate = 100 * deposit_expense / avg_deposits if avg_deposits > 0 & deposit_expense >= 0 & !missing(deposit_expense, avg_deposits)

	reghdfe rate if !missing(rate, liq_ratio_lag, size_lag, b_badassets_lag), absorb(cib year bhc_year)
	keep if e(sample)
	count

	quietly _pctile rate, p(1 99)
	gen double rate_w = min(max(rate, r(r1)), r(r2))

	gen double pre_high = pre_cont

	reghdfe rate_w pre_high , $regspec_cib
	estadd local controls 	"" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_paid_cont

	reghdfe rate_w pre_high liq_ratio_lag size_lag b_badassets_lag , $regspec_cib
	estadd local controls 	"Y" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_paid_cont_cov

	replace pre_high = pre_top50

	reghdfe rate_w pre_high , $regspec_cib
	estadd local controls 	"" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_paid_top50

	reghdfe rate_w pre_high liq_ratio_lag size_lag b_badassets_lag , $regspec_cib
	estadd local controls 	"Y" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_paid_top50_cov

	use $raw\t4_frame.dta, replace
	keep if net_income > 0 & !missing(net_income) & ni_is > 0 & !missing(ni_is)
	gen double ln_ni = ln(ni_is)

	gen double pre_high = pre_cont

	reghdfe ln_ni pre_high , $regspec_cib
	estadd local controls 	"" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_ni_cont

	reghdfe ln_ni pre_high liq_ratio_lag size_lag b_badassets_lag , $regspec_cib
	estadd local controls 	"Y" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_ni_cont_cov

	replace pre_high = pre_top50

	reghdfe ln_ni pre_high , $regspec_cib
	estadd local controls 	"" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_ni_top50

	reghdfe ln_ni pre_high liq_ratio_lag size_lag b_badassets_lag , $regspec_cib
	estadd local controls 	"Y" , replace
	estadd local bank		"Y" , replace
	estadd local bhcy 		"Y" , replace
	estadd local n_clus_cib = e(N_clust1) , replace
	est store t4_ni_top50_cov

	esttab 	///
	t4_paid_cont t4_paid_cont_cov t4_paid_top50 t4_paid_top50_cov ///
	t4_ni_cont t4_ni_cont_cov t4_ni_top50 t4_ni_top50_cov ///
	using $tex/table_04.tex , ///
	star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
	order(pre_high) keep(pre_high) ///
	varlabels(pre_high "Treatment $\times$ High-gap period") ///
	stats(controls bank bhcy n_clus_cib N r2, ///
	fmt(%3s %3s %3s %9.0fc %9.0fc %3.2f) ///
	labels("Bank controls$_{t-1}$" "Bank FE" "BHC-year FE" "N bank clusters" "N" "R$^2$")) ///
	booktabs ///
	mtitles("Dep. ratio Q3 2010" "Dep. ratio Q3 2010" "Top 50\%" "Top 50\%" ///
	"Dep. ratio Q3 2010" "Dep. ratio Q3 2010" "Top 50\%" "Top 50\%") ///
	mgroups("Average interest paid" "ln(Net income)" ///
	, pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
	span erepeat(\cmidrule(lr){@span})) ///
	style(tex)

}
