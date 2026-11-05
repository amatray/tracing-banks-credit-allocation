{

		use $raw\temp_in_sample2.dta,replace

		merge m:1  cib  using $raw\equity_first
		drop if _m == 2
		drop _m

		merge m:1 cib dq using $raw\liq
		drop if _m == 2
		drop _m

		merge m:1 cib dq using $raw\car
		drop if _m == 2
		drop _m

		save  $raw\temp_t7, replace

	use  $raw\temp_t7, replace

	cap drop d
	gen d = equity_first
	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap         * d

	reghdfe ln_tot $rhs_spec  , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store equity

	cap drop d DR_d DRgap_d gap_d
	gen d = (equity_first_tercile==1)

	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap         * d

	reghdfe ln_tot $rhs_spec , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store equity_low

	cap drop d DR_d DRgap_d gap_d
	gen d = liquidity_r_first
	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap         * d

	reghdfe ln_tot $rhs_spec  , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store liquidity

	cap drop d DR_d DRgap_d gap_d
	gen d = (liquidity_quin_first == 3 )

	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap * d

	reghdfe ln_tot $rhs_spec, $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store liquidity_high_q5

	cap drop d DR_d DRgap_d gap_d
	gen d = b_badloans_L_lag
	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap         * d

	reghdfe ln_tot $rhs_spec  , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store badloans_lag

	cap drop d DR_d DRgap_d gap_d
	gen d = (badloanL_quar == 3)
	gen DR_d 	= DRnew_lag   * d
	gen DRgap_d = DR1new_gap  * d
	gen gap_d 	= gap         * d

	reghdfe ln_tot $rhs_spec  , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store badloan_2

		label var DRnew_lag 	 "Deposit ratio"
		label var DR1new_gap 	 "Deposit ratio $\times$ Gap"

		label var  DRgap_d 		 "Deposit ratio $\times$ Gap $\times$ D"
		label var  DR_d  		 "Deposit ratio $\times$ D"
		label var  gap_d		 "Gap $\times$ D"
		label var  d			 "D"

		esttab 	equity equity_low	///
		liquidity liquidity_high_q5 ///
		badloans_lag badloan_2  ///
		using $tex/table_07.tex , ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order( DRgap_d  DR1new_gap DR_d  DRnew_lag gap_d d ) keep(DRgap_d  DR1new_gap DR_d  DRnew_lag gap_d d  ) ///
		stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
		fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "Banking-group-quarter FE" "N bank clusters" ///
		"N" "R$^2$")) ///
		label mtitles ( "D = Equity ratio" "D = 1 if Low equity" "D = Liquidity ratio"  "D = 1 if High Liquidity" "D = Share of non performing loans" "D = 1 if High share of non performing loans") booktabs  ///
		style(tex)

}
