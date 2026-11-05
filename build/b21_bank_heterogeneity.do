	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace
		keep cib dq ln_asset_lag equity_ratio_lag year
		drop if equity_r == .
		bys cib : egen min_dq = min(dq)

		gen equity_first = equity if dq == min_dq
		replace min_dq = min_dq + 1 if min_dq != 203
		replace equity_first = equity_r if dq == min_dq

		bys cib year : egen equity_ratio_year=mean(equity_r)

		keep if dq == min_dq
		keep cib equity_f

		xtile equity_first_tercile = equity_first, nq(3)
		xtile equity_first_quintile = equity_first, nq(5)
		xtile equity_first_median = equity_first, nq(2)
		xtile equity_first_decile = equity_first, nq(10)

	save $raw\equity_first, replace

	use $raw\bank_liq_trim, replace
		tsset cib dq
		sort cib dq

		gen time = dq
		gen date = dq
		gen liq_quar = .
		gen liq_quin = .

		foreach var in liq_ratio {
		gen `var'_lag =L1.`var'
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq_q = liq_ratio if dq == `m' , nq(3)
		replace liq_quar = liq_q  if liq_quar == .
		drop liq_q
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq_q = liq_ratio if dq == `m' , nq(3)
		replace liq_quin = liq_q  if liq_quin == .
		drop liq_q
		}

		keep if dq >= tq(2010q4)
		drop if date > tq(2015q4)

		sort cib dq
		drop if liq_ratio == .
		by cib : gen pres = _n

		gen liq_quar_first 		= 0
		gen liq_quin_first 		= 0

		gen liq_r_first 	= 0

		replace liq_quar_first   	= liq_quar if pres == 1
		replace liq_quin_first   	= liq_quin if pres == 1

		replace liq_r_first		 	 = liq_ratio if pres ==1

		foreach var in  liq_quar_first liq_quin_first liq_r_first {
		bys cib: egen max_`var' = max(`var')
		drop `var'
		rename max_`var' `var'
		}

		rename liq_quar_first 	liquidity_quar_first
		rename liq_quin_first 	liquidity_quin_first
		rename liq_r_first  	liquidity_r_first

		rename liq_ratio 		liquidity_ratio
		rename liq_ratio_lag 	liquidity_ratio_lag

		save $raw\liq, replace

	use $raw\bank_car_trim, replace
		tsset cib dq
		sort cib dq

		gen time = dq
		gen date = dq
		gen liq_quar = .
		gen liq_quar2 = .
		gen badloan_quar = .
		gen badloanL_quar = .
		gen badasset_quar = .
		gen leverage_quar = .
		gen leverage2_quar = .
		gen interbank_quar = .
		gen badloanL_quint = .

		foreach var in b_interbank1_exp b_badloans b_badloans_L b_badassets b_cash2 b_cash1 b_leverage2 b_leverage {
		gen `var'_lag =L1.`var'
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq_q = b_cash1_lag if dq == `m' , nq(3)
		replace liq_quar = liq_q  if liq_quar == .
		drop liq_q
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq2_q = b_cash2_lag if dq == `m' , nq(3)
		replace liq_quar2 = liq2_q  if liq_quar2 == .
		drop liq2_q
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq_q = b_badloans_lag if dq == `m' , nq(3)
		replace badloan_quar = liq_q  if badloan_quar == .
		drop liq_q
		}

		forval m = `=tq(2010q4)'/`=tq(2015q4)' {
		xtile liq_q = b_badloans_L_lag if dq == `m' , nq(3)
		replace badloanL_quar = liq_q  if badloanL_quar == .
		drop liq_q
		}
		keep if dq >= tq(2010q4)
		drop if date > tq(2015q4)

		sort cib dq
		by cib : gen pres= _n

		gen liq_quar_first 		= 0
		gen liq2_quar_first 	= 0
		gen badloan_quar_first 	= 0
		gen badloanL_quar_first 	= 0
		gen badloanL_quint_first 	= 0

		gen liq_r_first 	= 0
		gen liq2_r_first 	= 0
		gen badloan_r_first = 0
		gen badloanL_r_first = 0

		replace liq_quar_first   	= liq_quar if pres == 1
		replace liq2_quar_first   	= liq_quar2 if pres == 1
		replace badloan_quar_first  = badloan_quar if pres == 1
		replace badloanL_quar_first  = badloanL_quar if pres == 1
		replace badloanL_quint_first  = badloanL_quint if pres == 1

		replace liq_r_first		 	 = b_cash1 if pres ==1
		replace liq2_r_first		 = b_cash2 if pres ==1
		replace badloan_r_first  	= b_badloans if pres == 1
		replace badloanL_r_first  	= b_badloans_L if pres == 1

		foreach var in   liq_quar_first liq2_quar_first  badloan_quar_first badloanL_quar_first badloanL_quint_first {
		bys cib: egen max_`var' = max(`var')
		drop `var'
		rename max_`var' `var'
		}

		foreach var in  liq_r_first liq2_r_first  badloan_r_first badloanL_r_first {
		bys cib: egen max_`var' = max(`var')
		drop `var'
		rename max_`var' `var'
		}

		save $raw\car, replace
