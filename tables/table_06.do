{

	use $raw\temp_in_sample2.dta, replace
	drop if dq < tq(2011q4)
	gen pre = (dq < tq(2013q3))
	egen _tagb = tag(cib)
	xtile _DRq0 = dr_entry if _tagb , nq(4)
	egen DRq = max(_DRq0) , by(cib)
	drop _tagb _DRq0

	gen high_dr = (DRq>2)
	gen pre_high = pre * high_dr

	reghdfe ln_tot pre_high , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store did_pre_high_median

	drop high_dr pre_high
	gen high_dr = (DRq>3)
	gen pre_high = pre * high_dr

	reghdfe ln_tot pre_high , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store did_pre_high_quartile

	drop high_dr pre_high
	gen pre_high = pre * dr_entry

	reghdfe ln_tot  pre_high , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store did_pre_continuous_dr

	gen cib_s =string(cib)
	gen caisse_ep = substr(cib_s,5,1) if gea == 1163
	destring caisse_ep, gen(caisse_epar)
	drop caisse_ep
	gen caisse_ep =(caisse_epar==5)
	drop caisse_epar

	gen incumbent =(gea == 29 | gea == 788 | caisse_ep == 1)

	drop pre_high
	gen pre_high = pre * incumbent

	reghdfe ln_tot pre_high , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store did_pre_incumbent

		label var pre_high 	 "Pre  $\times$ High DR"

		esttab did_pre_continuous_dr	did_pre_high_median did_pre_high_quartile  did_pre_incumbent	///
		using $tex/table_06.tex , ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(pre_high) keep(pre_high ) ///
		stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
		fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "Banking-group-quarter FE" "N bank clusters" ///
		"N" "R$^2$")) ///
		label mtitles ( "DR" "Above median DR" "Top quartile DR" "Incumbent bank") booktabs  ///
		mgroups("High DR, defined as : " ///
		, pattern(1 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex)

}
