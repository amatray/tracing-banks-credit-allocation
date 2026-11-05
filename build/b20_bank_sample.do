	use $raw\temp_in_sample2.dta,replace
	keep cib dq DR1new_gap DRnew_lag gea
	duplicates drop
	merge 1:1 cib dq using $raw\bank_liq_trim
	keep if _m ==3
	drop _m

	merge 1:1 cib dq using $raw\portfolio_raw_trim.dta
	drop if _m == 2
	drop _m

	merge 1:1 cib dq using $raw\bank_car_trim
	drop if _m == 2
	drop _m

	gen ln_total_asset =ln(total_assets)

	gen ln_securities 	= ln(tot_prive)
	gen ln_bt 			= ln(total_bt)
	gen ln_action 		= ln(total_action)
	gen ln_action_SNF	= ln(actions_SNF)
	gen ln_variable 	= ln(total_variable)
	gen ln_fixe 		= ln(total_fixe)
	gen ln_ibk		    = ln(total_interbank)

	gen ln_ip 	 = ln(total_variable + total_fixe)
	gen ip_asset = (total_variable + total_fixe)/asset_lag

	gen ibk_asset1 = (interbank_loan1 + total_interbank) / asset_lag
	gen ibk_asset2 = (interbank_loan2 + total_interbank) / asset_lag
	gen ibk_asset3 = (interbank_loan3 + total_interbank) / asset_lag

	gen loan_to_asset   = b_loans1 / asset_lag
	gen loan_to_asset2  = b_loans2 / asset_lag

	foreach var in loan_to_asset loan_to_asset2 ibk_asset1 ibk_asset2 ibk_asset3 b_interbank3_exp b_interbank3_net b_interbank2_exp b_interbank2_net b_interbank1_exp b_interbank1_net ln_ip ip_asset ln_securities ln_bt ln_action ln_action_SNF ln_ibk ln_variable ln_fixe ln_total_asset equity_to_assetw sh_interbank sh_action_SNF sh_prive sh_sans_risque sh_action sh_variable sh_fixe{
	replace `var' = 0 if `var' == .
	}

	foreach var in loan_to_asset loan_to_asset2 ibk_asset1 ibk_asset2 ibk_asset3 b_interbank3_exp b_interbank3_net b_interbank2_exp b_interbank2_net b_interbank1_exp b_interbank1_net ip_asset sh_interbank sh_action_SNF sh_prive sh_sans_risque sh_action sh_variable sh_fixe{
	winsor `var' , gen(`var'w) p(0.01)
	}

	save $raw\bank_characteristics_sample.dta,replace

	use $raw\temp_reg_allfirms.dta,replace
	merge m:1 cibcounty dq using $raw\CEFIT_cib_county_DR_adjusted.dta

	keep if _m == 3

	gen year = yofd(dofq(dq))
	gen ln_tot 	=	ln(tot)

	save $raw\temp_reg_allfirms_adj.dta,replace
