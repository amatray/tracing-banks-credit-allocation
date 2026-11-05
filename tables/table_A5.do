{
		use $raw\temp_in_sample2.dta,replace
		gen DR_gap 				= DRnew * gap
		gen DRlag2_gap		 	= DRnew_lag2   * gap
		gen DR2tot_gap 		    = DRtotal_lag2 * gap

		gen equity_gap 	 = gap * equity_ratio_lag
		gen asset_gap	 = gap * ln_asset_lag

	reghdfe ln_tot DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_2

	drop in_s
	gen in_sample =e(sample)
	keep if in_sample ==1

	reghdfe ln_tot 	DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_b
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_1
	reghdfe ln_tot DRtotal_lag2 DR2tot_gap DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_3

	reghdfe ln_tot DRlag2_gap DRnew_lag2 HH_credit_lag0 HH_gap0 , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_hhcredit

	gen gap_in_bp = gap *100

	gen bucket1 = 0
	replace bucket1 = 1 if (gap_in_bp <= 120)

	gen bucket2 = 0
	replace bucket2 = 1 if (gap_in_bp  > 120 &  gap_in_bp  <= 150 )

	gen bucket3 = 0
	replace bucket3 = 1 if (gap_in_bp  > 150 & gap_in_bp  != .)

	foreach var in bucket1 bucket2 bucket3 {
	gen DRnew_`var'		= DRnew_lag2 * `var'
	}

	reghdfe ln_tot DRnew_lag2 DRnew_bucket2 DRnew_bucket3 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_4b

	reghdfe ln_tot equity_gap equity_ratio_lag DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_equity

	reghdfe ln_tot asset_gap ln_asset_lag DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_asset

	reghdfe ln_tot equity_gap asset_gap ln_asset_lag equity_ratio_lag  DRlag2_gap DRnew_lag2 if (dq > tq(2010q4)), $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store rob_surfi_asset_equity

		label var DRnew_lag2 	 "Deposit ratio t-2"
		label var DRlag2_gap 	 "Deposit ratio t-2 $\times$ Gap"

		label var DRtotal_lag2   "Total deposit ratio t-2"
		label var DR2tot_gap 	 "Tot.Deposit ratio t-2 $\times$ Gap"

		label var DRnew_bucket2	 "Deposit ratio $\times$ Gap in 2nd tercile  "
		label var DRnew_bucket3	 "Deposit ratio $\times$ Gap in top tercile  "

		label var HH_credit_lag0   "Share of lending to households"
		label var HH_gap0		  "Share of lending to households $\times$ Gap"

		label var asset_gap 		 "Bank size $\times$ Gap"
		label var ln_asset_lag 	 	 "Bank size"

		label var equity_gap		 	"Equity ratio $\times$ Gap"
		label var equity_ratio_lag  	"Equity ratio"

		esttab 	rob_surfi_1 		rob_surfi_2 	rob_surfi_3 	///
		rob_surfi_hhcredit ///
		rob_surfi_equity rob_surfi_asset rob_surfi_asset_equity ///
		rob_surfi_4b 	 	///
		using $tex/table_A5.tex , ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order( DRlag2_gap DRnew_lag2 DRtotal_lag2 DR2tot_gap HH_gap0 HH_credit_lag0 equity_gap equity_ratio_lag asset_gap ln_asset_lag DRnew_bucket3 DRnew_bucket2 ) ///
		keep ( DRlag2_gap DRnew_lag2 DRtotal_lag2 DR2tot_gap HH_gap0 HH_credit_lag0 equity_gap equity_ratio_lag asset_gap ln_asset_lag DRnew_bucket3 DRnew_bucket2 ) ///
		stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
		fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "Banking-group-quarter FE" "N bank clusters" ///
		"N" "R$^2$")) ///
		label mtitles ("" "" "" "" "" "" "") booktabs  ///
		mgroups("ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" "ln(Credit)" ///
		, pattern(1 1 1 1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex)

}
