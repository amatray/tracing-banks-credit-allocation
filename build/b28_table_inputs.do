	use $raw\temp_in_sample2.dta, replace
	keep cib dq DRnew_lag DRtotal_lag HH_credit_lag HH_gap
	duplicates drop cib dq , force
	save $raw\temp_stat_des3.dta, replace

	use $raw\liabilities_trim, replace
	keep cib dq total_assets equity_ratio_lag
	merge 1:1 cib dq using $raw\DR_surfi2_v2
	drop _m
	merge 1:1 cib dq using $raw\temp_stat_des3.dta
	keep if _m ==3
	drop _m

	keep dq cib HH* DRnew_lag DRtotal_lag equity_ratio_lag total_assets total_credit_hh total_credit*
	foreach var in total_assets total_credit_hh total_credit total_credit_corporate {
	replace `var' = 0 if `var' == .
	replace `var' = `var' / 1000000
	}

	merge 1:1 cib dq using  $raw\bank_characteristics_sample.dta
	keep if _m==3
	drop _m

	save $raw\temp_stat_des4.dta, replace

	use $raw\temp_stat_des4.dta, replace
	duplicates drop cib dq, force
	xtile deposit_quartile  =  DRnew_lag , nq(4)

	keep deposit_quartile cib dq

	save $raw\bank_list.dta, replace

	use $raw\temp_in_sample2.dta, replace

	gen cib_s =string(cib)
	gen caisse_ep = substr(cib_s,5,1) if gea == 1163
	destring caisse_ep, gen(caisse_epar)
	drop caisse_ep
	gen caisse_ep =(caisse_epar==5)
	drop caisse_epar

	gen incumbent =(gea == 29 | gea == 788 | caisse_ep == 1)

	keep cib gea incumbent year
	duplicates drop

	save  $raw\bank_list2.dta,replace

	use $raw\time_invariant_dr, replace
	keep cib dr_entry
	duplicates drop
	merge 1:m cib using $raw\bank_list2.dta
	keep if _m==3
	drop _m
	save  $raw\bank_DRentry_high_low.dta,replace

	use $raw\bank_liq_trim, replace
	collapse (mean) equity_to_asset liq_ratio, by(cib year)
	save  $raw\temp_bank_year_charact.dta,replace

	use $raw\bank_car_trim, replace
	gen year = yofd(dofq(dq))
	drop if year > 2016
	collapse (mean) b_* , by(cib year)
	merge 1:1 cib year  using $raw\temp_bank_year_charact
	keep if _m==3
	drop _m
	merge 1:1 cib year  using $raw\bank_net_income_yearly
	drop _m
	merge 1:1 cib year using $raw\bank_DRentry_high_low.dta
	keep if _m ==3
	drop _m
	save $raw\bank_level_regression, replace

	use $raw\REG_bank_county_cefit.dta, replace

		gen ei_sum2 = c_ei / (c_all)
		reghdfe ei_sum2 	DRnew_gap DRnew_lag   , $regspec3

		gen sample = e(sample)
		keep if sample ==1
		keep cib county dq
		save $raw\sample_cib_county, replace
