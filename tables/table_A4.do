{

	use $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta,replace

	reghdfe ln_tot DRnew_spec_lag DR1new_spec_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_2spec

	gen in_sample =e(sample)
	keep if in_sample== 1

	reghdfe ln_tot DRnew_spec_lag DR1new_spec_gap , $regspec_im_fbt_b
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_1spec

	use $raw\temp_reg_allfirms_adj.dta,replace
	drop if dq < tq(2010q1)
	drop if dq > tq(2015q4)

	rename DRnew_lag        DRnew_spec_lag
	rename DR1new_gap       DR1new_spec_gap

	reghdfe ln_tot $dependent1 , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_cefit_2

	cap drop in_sample
	gen in_sample =e(sample)
	keep if in_sample== 1

	reghdfe ln_tot $dependent1 , $regspec_im_fbt_b
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_cefit_1

		label var DRnew_spec_lag 	 "Spec.Deposit ratio"
		label var DR1new_spec_gap  	 "Spec.Deposit ratio $\times$ Gap"

		esttab 	base_cefit_1 base_cefit_2 base_surfi_1spec base_surfi_2spec	///
		using $tex/table_A4.tex , ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(DR1new_spec_gap DRnew_spec_lag ) keep(DR1new_spec_gap DRnew_spec_lag) ///
		stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
		fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "Banking-group-quarter FE" "N bank clusters" ///
		"N" "R$^2$")) ///
		label mtitles ("ln(Credit)" "" "" "" "" "" "" "") booktabs  ///
		mgroups("Regulated deposit + ordinary savings (branch level)"  "Regulated deposit + ordinary savings (bank level)" ///
		, pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex)

}
