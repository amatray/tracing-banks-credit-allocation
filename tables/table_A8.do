{

	use cib dq DRnew_lag using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
	replace dq = dq - 1
	rename DRnew_lag DR_b
	save $raw\tA8_bank_dr.dta, replace

	use firm dq zcf naf3 using $raw\temp_reg_allfirms_2.dta, replace
	collapse (max) zcf naf3, by(firm dq)
	save $raw\tA8_firm_attr.dta, replace

	use firm cib dq tot using $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta, replace
	collapse (sum) tot, by(firm cib dq)
	drop if missing(tot) | tot <= 0

	merge m:1 cib dq using $raw\tA8_bank_dr.dta, keep(master match)
	gen byte has_dr = (_merge == 3)
	drop _merge
	bys firm dq: egen double credit = total(tot)
	gen double sh = tot / credit
	replace DR_b = 0 if !has_dr
	gen double wdr = sh * DR_b

	gsort firm dq -tot cib
	by firm dq: gen long main_cib = cib[1]

	collapse (sum) x = wdr (first) main_cib credit, by(firm dq)

	gen double ln_credit = ln(credit)
	tsset firm dq
	gen double DRf_lag = L1.x
	merge m:1 dq using $raw\livreta_gap_dq.dta, keepusing(gap) keep(master match) nogen
	gen double DRf_gap = DRf_lag * gap

	merge 1:1 firm dq using $raw\tA8_firm_attr.dta, keep(master match) nogen
	gen int county_f = int(zcf / 1000)

	keep if inrange(dq, tq(2010q4), tq(2015q4))
	gen byte base = !missing(ln_credit, DRf_lag, DRf_gap, county_f, naf3)
	bys firm: egen int dq0 = min(cond(base, dq, .))
	format dq0 %tq
	gen int y0 = year(dofq(dq0))
	compress
	save $raw\tA8_firm_quarter.dta, replace

	use siren dq cotebdf using $raw\cn20082016_sme_panel_qtr_SME_clean.dta, replace
	rename siren firm
	drop if missing(cotebdf) | cotebdf == ""
	bys firm dq cotebdf: gen long n = _N
	bys firm dq (n cotebdf): keep if _n == _N
	keep firm dq cotebdf
	rename dq dq0
	save $raw\tA8_rating.dta, replace

	use siren cib dq using $raw\cn20082016_sme_panel_qtr_SME_clean.dta, replace
	rename (siren cib) (firm main_cib)
	collapse (min) first_dq = dq, by(firm main_cib)
	format first_dq %tq
	save $raw\tA8_relation_start.dta, replace
	sum first_dq
	local dq_min = r(min)

	use firm dq dq0 y0 main_cib using $raw\tA8_firm_quarter.dta, replace
	keep if dq == dq0
	drop dq

	gen int year = y0
	merge 1:1 firm year using $raw\temp_small.dta, keepusing(small_1) keep(master match)
	gen byte fiben = (_merge == 3)
	drop _merge year
	gen byte large = (small_1 == 0) & fiben
	drop small_1

	merge 1:1 firm dq0 using $raw\tA8_rating.dta, keep(master match)
	gen byte cote_found = (_merge == 3)
	drop _merge
    gen byte rated = (inlist(cotebdf, "3++", "3+", "3", "4+", "4", "5+", "5", "6") | ///
        inlist(cotebdf, "7", "8", "9", "P")) if cote_found

	merge m:1 firm main_cib using $raw\tA8_relation_start.dta, keep(master match)
	gen byte rel_found = (_merge == 3)
	drop _merge
	gen int rel_length = dq0 - first_dq + 1 if rel_found & first_dq <= dq0
	gen byte rel_censored = (first_dq == `dq_min') if !missing(rel_length)
	sum rel_length, d
	local rel_med = r(p50)
	gen byte longrel = (rel_length > `rel_med') if !missing(rel_length)
	count if !missing(rel_length)
	count if rel_censored == 1

	keep firm large fiben rated longrel
	save $raw\tA8_splits.dta, replace

	use $raw\tA8_firm_quarter.dta, replace
	merge m:1 firm using $raw\tA8_splits.dta, keep(master match) nogen
	egen long ind_cc_dq = group(county_f naf3 dq)
	global regspecA8 	"absorb(firm ind_cc_dq) vce(cluster firm)"

	reghdfe ln_credit DRf_lag DRf_gap if base, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_all

	reghdfe ln_credit DRf_lag DRf_gap if base & large == 1, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_large

	reghdfe ln_credit DRf_lag DRf_gap if base & large == 0, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_small

	reghdfe ln_credit DRf_lag DRf_gap if base & fiben == 1, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_fiben

	reghdfe ln_credit DRf_lag DRf_gap if base & fiben == 0, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_nofiben

	reghdfe ln_credit DRf_lag DRf_gap if base & rated == 1, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_rated

	reghdfe ln_credit DRf_lag DRf_gap if base & rated == 0, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_unrated

	reghdfe ln_credit DRf_lag DRf_gap if base & longrel == 1, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_long

	reghdfe ln_credit DRf_lag DRf_gap if base & longrel == 0, $regspecA8
	estadd local firm 		 "yes" , replace
	estadd local ind_cc_dq 	 "yes" , replace
	estadd local Nobs = e(N) , replace
	est store a8_short

	label var DRf_lag "Deposit ratio"
	label var DRf_gap "Deposit ratio $\times$ Gap"

	esttab a8_all a8_large a8_small a8_fiben a8_nofiben a8_rated a8_unrated a8_long a8_short ///
	using $tex/table_A8.tex, ///
	star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
	order(DRf_gap) keep(DRf_gap) ///
	stats(firm ind_cc_dq N r2, ///
	fmt(%3s %3s %9.0fc %3.2f) ///
	labels("Firm FE" "County-industry-quarter FE" "Observations" "R$^2$")) ///
	label mtitles("All" "Large" "Small" "In" "Outside" "Rated" "Unrated" "Long" "Short") booktabs ///
	mgroups("Full sample" "Size" "FIBEN" "Rating" "Relationship" ///
	, pattern(1 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
	span erepeat(\cmidrule(lr){@span})) ///
	style(tex)

}
