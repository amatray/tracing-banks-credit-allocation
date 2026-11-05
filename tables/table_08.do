{
	global regspec5 	"absorb(cibcounty county_time gea_time) vce(cluster cibcounty)"

	use $raw\large_small_cibcounty_reg_v2.dta, replace

	gen DRnew_gap  		= DRnew_lag  * gap

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)

	gen double small_corp = 1 - sh_large_debt

		reghdfe small_corp DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store small_corp

		reghdfe small_r_w  DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store small_r_cefit

		reghdfe c_mlt_r    DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store mlt_r

	use $raw\REG_bank_county_cefit.dta, replace

		gen ei_sum2 = c_ei / (c_all)
		reghdfe ei_sum2 	DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store ei_r_surfi

	use $raw\bankruptcy_loans_4.dta, replace

	merge m:1 cib dq using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, keep(3) nogen

	merge m:1 dq using $raw\livreta_gap_dq.dta, keep(3) nogen

	merge 1:1 cib county dq using $raw\sample_cib_county.dta, keep(3) nogen

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)
	egen cibcounty 	 = group(cib county)

	gen DRnew_gap = DRnew_lag * gap

		reghdfe bankruptcy_vhigh_debt DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store bankruptcy_debt_vhigh

	use $raw\risky_rating.dta, replace

	merge m:1 cib dq using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, keep(3) nogen

	merge m:1 dq using $raw\livreta_gap_dq.dta, keep(3) nogen

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)
	egen cibcounty 	 = group(cib county)

	gen DRnew_gap = DRnew_lag * gap

		reghdfe risky_debt DRnew_gap DRnew_lag , $regspec5
		estadd local c_time 		"yes" , replace
		estadd local cibcounty 		"yes" , replace
		estadd local gea_time  		"yes" , replace
		estadd local n_clus = e(N_clust)  ,replace
		estadd local Nobs = e(N) , replace
		est store risky_debt

		label var DRnew_lag  "Deposit ratio"
		label var DRnew_gap  "Deposit ratio $\times$ Gap"

		esttab small_corp small_r_cefit ei_r_surfi bankruptcy_debt_vhigh risky_debt mlt_r ///
		using $tex/table_08.tex, ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(DRnew_gap DRnew_lag) keep(DRnew_gap DRnew_lag) ///
		stats(cibcounty c_time gea_time n_clus N r2, ///
		fmt(%3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Bank-county FE" "County-quarter FE" "Banking-group-quarter FE" "N bank-county clusters" ///
		"Observations" "R$^2$")) ///
		label mtitles ("Corporate loans" "Total loans" "Total loans" "Total loans" "Rated firms" "Total loans") booktabs ///
		mgroups( "Small firms" "Small firms" "Self-employed" "High-bankruptcy industries" "Risky firms" "MLT loans" ///
		, pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex) nonumber

}
