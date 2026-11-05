{

	use $raw\temp_in_sample2.dta,replace

	reghdfe ln_tot DR2010_gap  , $regspec_im_fbt_b
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_1_dr2010

	reghdfe ln_tot DR2010_gap, $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_2_dr2010

	reghdfe ln_tot DR2010_gap DRtot2010_gap, $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_3_dr2010

	reghdfe ln_tot DR2010_gap HH_credit_lag0 HH_gap0 , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_dr2010_hhcredit

	gen equity_gap 	 = gap * equity_ratio_lag
	gen asset_gap	 = gap * ln_asset_lag

	reghdfe ln_tot equity_gap equity_ratio_lag  DR2010_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_equity_dr2010

	reghdfe ln_tot asset_gap ln_asset_lag DR2010_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_asset_dr2010

	reghdfe ln_tot asset_gap equity_gap ln_asset_lag equity_ratio_lag DR2010_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_asset_equity_dr2010

	gen gap_in_bp = gap * 100

	gen bucket1 = 0
	replace bucket1 = 1 if (gap_in_bp <= 120)

	gen bucket2 = 0
	replace bucket2 = 1 if (gap_in_bp  > 120 &  gap_in_bp  <= 150 )

	gen bucket3 = 0
	replace bucket3 = 1 if (gap_in_bp  > 150 & gap_in_bp  != .)

	foreach var in bucket1 bucket2 bucket3 {
	gen dr_2010_`var'		= dr_2010 * `var'
	}

	reghdfe ln_tot  dr_2010_bucket2 dr_2010_bucket3, $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store base_surfi_dr2010_bucket

		label var HH_credit_lag0   "Share of lending to households"
		label var HH_gap0		  "Share of lending to households $\times$ Gap"

		label var dr_2010	 "Deposit ratio"
		label var DR2010_gap 	 "Deposit ratio $\times$ Gap"

		label var dr_tot2010  	 "Total deposit ratio"
		label var DRtot2010_gap 	 "Tot.Deposit ratio $\times$ Gap"

		label var dr_2010_bucket3	 "Deposit ratio $\times$ Gap in top tercile"
		label var dr_2010_bucket2   "Deposit ratio $\times$ Gap in 2nd tercile"

		label var asset_gap 		 "Bank size $\times$ Gap"
		label var ln_asset_lag 	 	"Bank size"

		label var equity_gap		 	"Equity ratio $\times$ Gap"
		label var equity_ratio_lag  	"Equity ratio"

		esttab 	base_surfi_1_dr2010 base_surfi_2_dr2010 	base_surfi_3_dr2010 	///
		base_dr2010_hhcredit ///
		base_surfi_equity_dr2010 base_surfi_asset_dr2010 ///
		base_asset_equity_dr2010  base_surfi_dr2010_bucket	 	///
		using $tex/table_A2.tex , ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(DR2010_gap   DRtot2010_gap  HH_gap0 HH_credit_lag0 equity_gap equity_ratio_lag asset_gap ln_asset_lag dr_2010_bucket3	 dr_2010_bucket2  ) ///
		keep( DR2010_gap   DRtot2010_gap  HH_gap0 HH_credit_lag0 equity_gap equity_ratio_lag asset_gap ln_asset_lag dr_2010_bucket3	 dr_2010_bucket2  ) ///
		stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
		fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "BHC-quarter FE" "N bank clusters" ///
		"N" "R$^2$")) ///
		label mtitles ("" "" "" "" "" "" "" "") booktabs  ///
		mgroups("ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" ///
		, pattern(1 1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex)

		}
