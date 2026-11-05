{

	use cib dq DRnew_lag using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
	replace dq = dq - 1
	rename DRnew_lag DR_b
	save $raw\tA9_bank_dr.dta, replace

	use firm cib dq tot using $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta, replace
	recast double tot
	collapse (sum) tot, by(firm cib dq)
	drop if tot == 0
	merge m:1 cib dq using $raw\tA9_bank_dr.dta, keep(master match)
	replace DR_b = 0 if _merge == 1
	replace DR_b = 0 if _merge == 3 & missing(DR_b)
	drop _merge
	gen double credit_dr = tot * DR_b
	collapse (sum) credit = tot credit_dr, by(firm dq)
	gen double exposure = credit_dr / credit
	xtset firm dq
	gen double credit_lag = L.credit
	gen double E_i = L.exposure
	merge m:1 dq using $raw\livreta_gap_dq.dta, keepusing(gap) keep(master match) nogen
	save $raw\tA9_firm_quarter.dta, replace

	use firm dq zcf using $raw\temp_reg_allfirms_2.dta, replace
	collapse (max) zcf, by(firm dq)
	save $raw\tA9_firm_zcf.dta, replace

	use $raw\tA9_firm_quarter.dta, replace
	merge 1:1 firm dq using $raw\tA9_firm_zcf.dta, keep(master match) nogen
	keep if inrange(dq, tq(2010q4), tq(2015q4))
	keep if !missing(credit, credit_lag, E_i, gap, zcf) & credit > 0 & credit_lag > 0
	merge m:1 zcf using "$crosswalk", keepusing(ze2010 county_f) keep(master match)
	drop if _merge == 1 | missing(ze2010, county_f)
	drop _merge
	bys zcf dq: gen long zip_firms = _N
	keep if zip_firms >= 5
	gen double ln_credit = ln(credit)
	gen double own_gap = E_i * gap
	save $raw\tA9_support.dta, replace

	use $raw\tA9_support.dta, replace
	egen long geo_id = group(zcf)
	bys geo_id dq: egen double lag_total = total(credit_lag)
	gen double w = credit_lag / lag_total
	gen double exposure_part = w * E_i
	bys geo_id dq: egen double E_g = total(exposure_part)
	gen double geo_gap = E_g * gap
	reghdfe ln_credit own_gap geo_gap E_i E_g [aw=w], absorb(firm dq) vce(cluster geo_id) tolerance(1e-10)
	estadd local firm 		"yes" , replace
	estadd local quarter 	"yes" , replace
	estadd local n_clus 	= e(N_clust)  ,replace
	estadd local Nobs 		= e(N) , replace
	est store a9_zcf

	use $raw\tA9_support.dta, replace
	egen long geo_id = group(ze2010)
	bys geo_id dq: egen double lag_total = total(credit_lag)
	gen double w = credit_lag / lag_total
	gen double exposure_part = w * E_i
	bys geo_id dq: egen double E_g = total(exposure_part)
	gen double geo_gap = E_g * gap
	reghdfe ln_credit own_gap geo_gap E_i E_g [aw=w], absorb(firm dq) vce(cluster geo_id) tolerance(1e-10)
	estadd local firm 		"yes" , replace
	estadd local quarter 	"yes" , replace
	estadd local n_clus 	= e(N_clust)  ,replace
	estadd local Nobs 		= e(N) , replace
	est store a9_ze

	use $raw\tA9_support.dta, replace
	egen long geo_id = group(county_f)
	bys geo_id dq: egen double lag_total = total(credit_lag)
	gen double w = credit_lag / lag_total
	gen double exposure_part = w * E_i
	bys geo_id dq: egen double E_g = total(exposure_part)
	gen double geo_gap = E_g * gap
	reghdfe ln_credit own_gap geo_gap E_i E_g [aw=w], absorb(firm dq) vce(cluster geo_id) tolerance(1e-10)
	estadd local firm 		"yes" , replace
	estadd local quarter 	"yes" , replace
	estadd local n_clus 	= e(N_clust)  ,replace
	estadd local Nobs 		= e(N) , replace
	est store a9_county

	label var own_gap "Own deposit ratio $\times$ Gap"
	label var geo_gap "Geographic deposit ratio $\times$ Gap"
	label var E_i     "Own deposit ratio"
	label var E_g     "Geographic deposit ratio"

	esttab a9_zcf a9_ze a9_county ///
	using $tex/table_A9.tex, ///
	star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
	order(own_gap geo_gap E_i E_g) keep(own_gap geo_gap E_i E_g) ///
	stats(firm quarter n_clus N r2, ///
	fmt(%3s %3s %9.0fc %9.0fc %3.2f) ///
	labels("Firm FE" "Quarter FE" "N geography clusters" "Observations" "R$^2$")) ///
	label mtitles("Commune" "Employment zone" "Department") booktabs ///
	style(tex)

}
