	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
	keep if dq == tq(2010q4)|dq == tq(2011q4)|dq == tq(2012q4)|dq == tq(2013q4)|dq == tq(2014q4)|dq == tq(2015q4)

	collapse (sum) deposits_centralisable special_deposits , by(year cib)

	gen centralise_to_spec = deposits_centralisable/special

	replace centralise_to_spec = 0 if deposits_centralisable == 0

	keep cib year centralise_to_spec

	save $raw\share_centralisable.dta, replace

	use $raw\cefit_clean_monthly.dta, replace

	keep if agent=="TOTAL"

	tsset cibcounty time

	drop if time < tm(2009m10)
	drop if time > tm(2015m12)

	merge m:1 cib year  using $raw\share_centralisable.dta

	drop if _m == 2

	bys cib : egen max_sh = max(centralise_to_spec) if year <= 2010
	replace centralise_to_spec = max_sh if centralise_to_spec == .
	drop max_sh

	replace centralise_to_spec = 0 if _m == 1 & centralise_to_spec ==.

	drop _m

	gen deposits_centralisable = centralise_to_spec * d_regulated_tot
	gen complement_deposits = (1 - centralise_to_spec) * d_regulated_tot

				gen cib_s = string(cib)
				gen caisse_ep = substr(cib_s,5,1) if gea == 1163
				destring caisse_ep, gen(caisse_epar)
				drop caisse_ep
				gen caisse_ep =(caisse_epar==5)
				drop caisse_epar

	gen 		deposits_net = deposits_centralisable * 0.2 	if (caisse_ep ==1 | gea == 29) & year == 2009
	replace 	deposits_net = deposits_centralisable * 0.2 	if (caisse_ep ==1 | gea == 29) & year == 2010
	replace deposits_net = deposits_centralisable * 0.24 	if (caisse_ep ==1 | gea == 29) & year == 2011
	replace deposits_net = deposits_centralisable * 0.3 	if (caisse_ep ==1 | gea == 29) & year == 2012
	replace deposits_net = deposits_centralisable * 0.36 	if (caisse_ep ==1 | gea == 29) & year == 2013
	replace deposits_net = deposits_centralisable * 0.38 	if (caisse_ep ==1 | gea == 29) & year == 2014
	replace deposits_net = deposits_centralisable * 0.39 	if (caisse_ep ==1 | gea == 29) & year == 2015

	replace deposits_net = 0 	if (gea == 788)

	replace deposits_net = deposits_centralisable * 0.76 	if  deposits_net ==. & year == 2009
	replace deposits_net = deposits_centralisable * 0.76 	if  deposits_net ==. & year == 2010
	replace deposits_net = deposits_centralisable * 0.66 	if  deposits_net ==. & year == 2011
	replace deposits_net = deposits_centralisable * 0.6 	if  deposits_net ==. & year == 2012
	replace deposits_net = deposits_centralisable * 0.63 	if  deposits_net ==. & year == 2013
	replace deposits_net = deposits_centralisable * 0.6 	if  deposits_net ==. & year == 2014
	replace deposits_net = deposits_centralisable * 0.6		if  deposits_net ==. & year == 2015

	replace deposits_net = d_regulated_tot if deposits_net ==.

		tsfill,full
		bysort cibcounty : carryforward agent, gen(agent_fill)
		sort cibcounty time

		cap drop _end _seq _spell lenght
		tsspell, f(L.time == .)
		bys cibcounty _spell : egen length = max(_seq)

		local varlist "deposits* complement* d_* c_* VAR210 VAR256 d_livrets"
		foreach i of var `varlist' {
		replace `i' =0 if `i'==.
		}

		gen  d_all_tot_new = d_all_tot - d_regulated_tot + (deposits_net + complement_deposits)

		gen DR 		= d_regulated_tot / d_all_total
		gen DRnew 	= (deposits_net + complement_deposits) / d_all_tot_new

		tsset cibcounty time
		gen DR_lag 	= L1.DR
		gen DR_lag2 = L2.DR
		gen DRnew_lag 	= L1.DRnew
		gen DRnew_lag2  = L2.DRnew

		merge m:1 time using $raw\livreta.dta
		drop if _m==2
		drop _m

		gen DR1_gap		= DR_lag * gap

		gen DR1new_gap	= DRnew_lag * gap

		gen loan=ln(c_all)

		gen st_credit = ln(c_st_credit)

		gen st_credit_scr = ln(c_st_credit + c_overdraft + VAR210)

		gen lt_credit = ln(c_lt_credit +c_export_credit )

		gen leasing = ln(c_leasing)

		gen arf = ln(VAR210)

		rename VAR210 c_arf

		gen mortgage=ln(c_mort)

		gen regulated_mortgage=ln(c_regulated_mortgage)

		gen regular_mortgage=ln(c_regular)

		gen overdraft= ln(c_overdraft)

		gen new_loan=0
		replace new_loan=1 if loan > 0 & loan !=.

		gen new_mortgage=0
		replace new_mortgage=1 if mortgage > 0 & mortgage !=.

		gen new_regulated_mortgage=0
		replace new_regulated_mortgage=1 if regulated_mortgage  > 0 & regulated_mortgage !=.

		gen new_regular_mortgage=0
		replace new_regular_mortgage=1 if regular_mortgage  > 0 & regular_mortgage !=.

		gen new_st_credit_scr=0
		replace new_st_credit_scr=1 if st_credit_scr > 0 & st_credit_scr !=.

		gen new_lt_credit=0
		replace new_lt_credit=1 if lt_credit > 0 & lt_credit !=.

		gen new_st_credit=0
		replace new_st_credit=1 if st_credit > 0 & st_credit !=.

	keep if month ==3 | month ==6 | month ==9 | month==12

	gen quarter = 1 if month == 3
	replace quarter = 2 if month == 6
	replace quarter = 3 if month == 9
	replace quarter = 4 if month == 12

	gen dq = yq(y,q)

	format dq %tq

	keep DR* gap cib county cibcounty time gea nom* dq

	save $raw\CEFIT_cib_county_DR_adjusted.dta, replace
