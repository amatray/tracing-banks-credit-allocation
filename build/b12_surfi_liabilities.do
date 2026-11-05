 use "$bdf\situation_france_final_trim.dta", replace

 save $raw\situation_raw_trim.dta, replace

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

	keep year dq cib rais_*  S01_0510 S02_* S03_1910 S05_0620 S05_0670 S0H_0010

	local varlist "S01_ S02_* S03_* S05_* S0H_0010"
	foreach i of var `varlist' {
	replace `i'= 0 if `i' ==.
	}

		local varlist "S*"
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	rename  M_S01_0510 	interbank_funding
	rename  M_S02_0610	client_operation
	gen total_deposits = client_operation - M_S02_0630 - M_S02_0650 - M_S02_0930
	rename  M_S03_1910	market_funding
	rename M_S05_0620 equity
	rename  M_S0H_0010	total_assets

	order year dq cib total_asset equity client_operation interbank_funding total_deposits market_funding rais_*

	sort cib dq

	gen total_liabilities = interbank_funding + client_operation + market_funding
	drop if total_liabilities == 0

	gen total_deposit_ratio 		= total_deposits 	/ total_liabilities
	gen interbank_funding_ratio 	= interbank_funding / total_liabilities
	gen market_funding_ratio 		= market_funding	/ total_liabilities

	replace total_deposit_ratio =0 if total_deposit_ratio  < 0

	gen equity_ratio = equity / total_asset
	gen ln_asset = ln(total_assets)

	winsor equity_ratio, gen(equity_ratiow) p(0.01)
	drop equity_ratio
	rename equity_ratiow equity_ratio

	tsset cib dq

	gen equity_ratio_lag = L1.equity_ratio
	gen ln_asset_lag = L1.ln_asset

	replace total_deposits = 0 if total_deposits < 0

	keep cib dq equity_ratio* ln_* year total_deposit* interbank_funding* market_funding* total_liabilities equity total_assets

	drop if year >= 2016

	save $raw\liabilities_trim, replace
