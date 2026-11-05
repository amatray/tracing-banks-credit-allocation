	use $raw\situation_raw_trim.dta, replace

	gen date=string(date_arrete,"%02.0f")

	gen year = substr(date,1,4)
	gen month = substr(date,5,2)
	destring year,replace
	destring month,replace
	drop date

	gen time = ym(y,m)
	format time %tm

	gen dq  = qofd(dofm(time))
	format dq %tq

	drop time month

	gen titres = S03_0520 + S03_0110 + S03_0460 + S03_0750 + S03_0770 + S03_0980 + S03_1130 + S03_1380

	keep year dq cib rais_* titres  S04_0250 S03_1910 S03_0010 S01_0020 S01_0180  S0H_0010 S03_1910 S01_0510 S02_0610 S03_1910 S05_0620

	local varlist "titres  S04_0250 S03_0010 S03_1910 S01_0020 S01_0180  S0H_0010 S03_1910 S01_0510 S02_0610 S03_1910 S05_0620"
	foreach i of var `varlist' {
	replace `i'= 0 if `i' ==.
	}

		local varlist "S* titres "
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	rename  M_S0H_0010	total_assets
	rename  M_S01_0020	cash
	rename  M_S01_0180	reserves
	rename 	M_S03_1910	securities
	rename  M_S05_0620  bk_equity

	sort cib dq

	gen liq_ratio = (cash + reserves) / total_assets

	winsor liq_ratio, gen (liq_ratiow) p(0.01)
	drop liq_ratio
	rename liq_ratiow liq_ratio

	drop if year >= 2016

	xtile liq_quartile  = liq_ratio, nq(4)
	xtile liq_quintile = liq_ratio, nq(5)

	tsset cib dq

	gen liq_quartile_lag = L1.liq_quartile
	gen liq_quintile_lag = L1.liq_quintile

	replace liq_quartile_lag  = liq_quartile if liq_quartile_lag  ==.
	replace liq_quintile_lag  = liq_quintile if liq_quintile_lag  ==.

	gen asset_lag = L1.total_assets

	gen 	equity_to_asset = bk_equity /asset_lag
	winsor  equity_to_asset , gen(equity_to_assetw) p(0.01)

	save $raw\bank_liq_trim, replace

	use $raw\situation_raw_trim.dta, replace

	gen date=string(date_arrete,"%02.0f")

	gen year = substr(date,1,4)
	gen month = substr(date,5,2)
	destring year,replace
	destring month,replace
	drop date

	gen time = ym(y,m)
	format time %tm

	gen dq  = qofd(dofm(time))
	format dq %tq

	drop time month

	rename S05_0680 net_income

	keep cib dq year net_inc S0H_0010

	local varlist "S0H_0010 net_inc"
	foreach i of var `varlist' {
	replace `i'= 0 if `i' ==.
	}

		local varlist "S* net_inc "
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	rename  M_S0H_0010	total_assets
	label var total_assets "Total assets in bn EUR, quarterly"
	drop net_inc*
	rename M_net_income net_income
	label var net_inc "Net income, yearly"

	collapse (sum) net_inc (mean) total_asset, by(year cib)
	sort cib year

	xtset cib year
	gen net_inc_fwd = F1.net_income

	drop   net_income
	rename net_inc_fwd net_income

	drop if year > 2015

	save $raw\bank_net_income_yearly, replace

	use $raw\Surfi_bank_portfolio.dta, replace
	collapse titres_rev* bons_tresor action titres_interb parts,by(cib madate public)

	drop if titres_rev_fixe == 0 & titres_rev_variable == 0
	rename madate dq

	gen 	tot_titre 	 		= titres_rev_fixe + titres_rev_variable
	replace tot_titre			= tot_titre/ 1000

	bys cib dq : egen total_portfolio = sum(tot_titre)

	bys cib dq : egen total_bt  	  = sum(bons_t)
	replace total_bt				  = total_bt/ 1000

	bys cib dq : egen total_action  	  = sum(action)
	replace total_action				  = total_action/ 1000

	bys cib dq : egen total_variable 	  = sum(titres_rev_variable )
	replace total_variable				  = total_variable / 1000

	bys cib dq : egen total_fixe 	  = sum(titres_rev_fixe)
	replace total_fixe				  = total_fixe / 1000

	bys cib dq : egen total_interbank 	  = sum(titres_interb)
	replace total_interbank 			  = total_interbank  / 1000

	gen tot_prive 				  = tot_titre if public == 0
	keep if public == 0

	rename dq madate
	merge 1:1 cib madate using $raw\actions_assimiles_SNF.dta
	drop if _m ==2
	drop _m

	rename madate dq
	rename actions_assimiles_SNF  actions_SNF
	keep cib dq total_portfolio total_bt tot_prive actions_SNF total_interbank  total_action total_fixe total_variable

	gen year  = year(dq)
	gen month = month(dq)
	gen time = ym(y,m)
	format time %tm

	drop dq
	gen dq  = qofd(dofm(time))
	format dq %tq
	drop time

	xtset cib dq
	gen   total_portfolio_lag = L1.total_portfolio

	replace actions_SNF	= actions_SNF/ 1000
	gen sh_sans_risque  = total_bt 	     	/ total_portfolio
	gen sh_prive 		= tot_prive 	 	/ total_portfolio
	gen sh_action 		= total_action 	 	/ total_portfolio
	gen sh_action_SNF 	= actions_SNF 	 	/ total_portfolio
	gen sh_variable		= total_variable 	/ total_portfolio
	gen sh_fixe		    = total_fixe 	 	/ total_portfolio
	gen sh_interbank	= total_interbank 	/ total_portfolio

	drop if dq ==tq(2010q3)
	save $raw\portfolio_raw_trim.dta, replace

	use $raw\situation_raw_trim.dta, replace

	gen date=string(date_arrete,"%02.0f")

	gen year = substr(date,1,4)
	gen month = substr(date,5,2)
	destring year,replace
	destring month,replace
	drop date

	gen time = ym(y,m)
	format time %tm

	gen dq  = qofd(dofm(time))
	format dq %tq

	drop time month

	local varlist "S*"
	foreach i of var `varlist' {
	replace `i'= 0 if `i' ==.
	}

		local varlist "S*"
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	gen interbank_loan1 = M_S01_0180 + M_S01_0190
	gen b_interbank1_exp=(M_S01_0180 + M_S01_0190 + M_S01_0550 + M_S01_0620)/(2*M_S0H_0050)
	gen b_interbank1_net=(M_S01_0180 + M_S01_0190 - M_S01_0550 - M_S01_0620)/(2*M_S0H_0050)

	gen interbank_loan2 = M_S01_0070 + M_S01_0180 + M_S01_0190
	gen b_interbank2_exp=(M_S01_0070 + M_S01_0180 + M_S01_0190 + M_S01_0550 + M_S01_0560 + M_S01_0620)/(2*M_S0H_0050)
	gen b_interbank2_net=(M_S01_0070 + M_S01_0180 + M_S01_0190 - M_S01_0550 - M_S01_0560 - M_S01_0620)/(2*M_S0H_0050)

	gen interbank_loan3 = M_S01_0180 + M_S01_0190 + M_S01_0230
	gen b_interbank3_exp=(M_S01_0180 + M_S01_0190 + M_S01_0230 + M_S01_0550 + M_S01_0560 + M_S01_0620 + M_S01_0590)/(2*M_S0H_0050)
	gen b_interbank3_net=(M_S01_0180 + M_S01_0190 + M_S01_0230 - M_S01_0550 - M_S01_0560 - M_S01_0620 - M_S01_0590)/(2*M_S0H_0050)

	gen b_cash1=(M_S01_0010)/M_S0H_0050
	gen b_cash2=(M_S01_0020)/M_S0H_0050

	gen b_loans1=M_S02_0020
	gen b_loans2=M_S02_0130 + M_S02_0380

	gen b_totsize=M_S0H_0050

	gen b_leverage=(M_S05_0530+M_S05_0620)/M_S0H_0050
	gen b_leverage2=(M_S05_0530+M_S05_0620+M_S05_0220+M_S05_0380+M_S05_0520)/M_S0H_0050

	gen b_badloans=M_S02_0410/M_S0H_0050
	gen b_badassets=(M_S02_0410+M_S03_1730)/M_S0H_0050
	gen b_badloans_L=M_S02_0410/M_S02_0020
	replace b_badloans_L = 0 if b_badloans_L ==.

	keep cib dq b_* interbank_lo*

	save $raw\bank_car_trim, replace
