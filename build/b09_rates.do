		import excel $data\excel\Rate_eonia_ordinary_snf.xlsx, sheet("Feuil1") firstrow clear
		save $raw\rate.dta, replace

		use $raw\rate.dta, replace

		gen month = month(time)
		gen year = year(time)

		gen date = ym(year, month)
		format date %tm
		sort date

		save $raw\savings_rate.dta, replace

	use $raw\rate.dta, replace

	capture drop month
	capture drop year
	gen month = month(time)
	gen year = year(time)

	capture drop my
	capture drop time
	gen my = ym(y,m)
	gen time = my
	format time %tm
	sort time

	drop if year > 2016

	rename livret_a rate_livreta
	rename dfr df

	gen gap = rate_livreta - df

	keep rate_livreta month year df gap my time
	order rate_livreta month year df gap my time

	compress
	save $raw\livreta.dta, replace

	use $raw\cefit_clean_monthly.dta, replace

	keep if agent=="TOTAL"

	tsset cibcounty time

		tsfill,full
		bysort cibcounty : carryforward agent, gen(agent_fill)
		sort cibcounty time

		cap drop _end _seq _spell lenght
		tsspell, f(L.time == .)
		bys cibcounty _spell : egen length = max(_seq)

		local varlist "d_* c_* VAR210 VAR256 d_livrets"
		foreach i of var `varlist' {
		replace `i' =0 if `i'==.
		}

		gen DR = d_regulated_tot / d_all_tot
		tsset cibcounty time
		gen DR_lag =L1.DR
		gen DR_lag2 =L2.DR

		merge m:1 time using $raw\livreta.dta
		drop if _m==2
		drop _m

		gen DR1_df= DR_lag * df
		gen DR1_gap= DR_lag * gap

		gen loan=ln(1+c_all)

		gen st_credit = ln(1+c_st_credit)

		gen st_credit_scr = ln(1+c_st_credit + c_overdraft + VAR210)

		gen lt_credit = ln(1+c_lt_credit +c_export_credit )

		gen leasing = ln(1+c_leasing)

		gen arf = ln(1+VAR210)

		gen mortgage=ln(1+c_mort)

		gen regulated_mortgage=ln(1+c_regulated_mortgage)

		gen regular_mortgage=ln(1+c_regular)

		gen overdraft= ln(1+c_overdraft)

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

	save $raw\ALL_reg.dta, replace
