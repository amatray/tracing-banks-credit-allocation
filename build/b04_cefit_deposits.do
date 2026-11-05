	use $data\init\gea_cib_annuel_clean.dta ,replace
	keep cib gea nom* y
	gsort cib y -gea nom_cib
	duplicates drop cib y, force
	save $raw\gea_cib_2005_2005.dta,replace

	use $raw\gea_cib_2005_2005.dta,replace
	keep if year==2015
	drop year
	gen year=2016

	append using $raw\gea_cib_2005_2005.dta
	save $raw\gea_cib_y_clean.dta,replace

	use  $data\init\cefit_transpo_fin.dta, replace

	rename VAR100 d_checking_account

	rename VAR111 d_livrets
	rename VAR112 d_lep
	rename VAR113 d_ldd
	rename VAR114 d_cel
	rename VAR115 d_other_regulated_livrets

	rename VAR120 d_pel
	rename VAR130 d_pep

	rename VAR160 d_term_account
	rename VAR170 d_bons_de_caisse

	rename VAR410 d_TCN
	rename VAR411 d_CD
	rename VAR412 d_BMTN

	local varlist "d_*"
	foreach i of var `varlist' {
	replace `i' =0 if `i'==.
	}

	gen d_regulated_deposit = d_livrets + d_lep + d_ldd + d_cel + d_other + d_pel

	gen d_non_regulated = d_checking_account + d_pep + d_term_account + d_bons_de_caisse + d_TCN

	gen d_all = d_non_regulated + d_regulated

	label var d_all "Total Deposits and CDs"
	label var d_regulated "Regulated rate deposits"
	label var d_non_regulated "Non-regulated rate deposits"

	gen snf = 0
	replace snf= 1 if agent== "SNF"
	gen entrepreuneur = 0
	replace entrepreuneur = 1 if agent== "EI"
	gen household = 0
	replace household = 1 if agent== "PARTICULIERS"

	gen non_fin_no_resid = 0
	replace non_fin_no_resid = 1 if agent== "CLIENT_NON_FIN_NON_RES"

	gen Month = substr(date,6,2)
	destring Month, gen (month)
	drop Month

	gen Year = substr(date,1,4)
	destring Year, gen (year)
	drop Year

	gen my = ym(y,m)

	gen time = my
	format time %tm

	drop if Num_aire_geo== "2A" | Num_aire_geo== "2B"
	destring Num_aire_geo, gen (county)
	drop Num_aire_geo

		replace VAR210 =0 if VAR210 ==.
		label var VAR210 "Trade credit"

		replace VAR220 =0 if VAR220 ==.
		rename VAR220 c_export_credit
		label var c_export_credit "Export credit"

		local varlist "VAR231 VAR232 VAR233 VAR234 VAR235"
		foreach i of var `varlist' {
		replace `i' =0 if `i'==.
		}
		gen c_st_credit = VAR231 + VAR232 + VAR233 + VAR234 + VAR235
		label var c_st_credit "Working capital credit"

		replace VAR240 =0 if VAR240 ==.
		rename VAR240 c_lt_credit
		label var c_lt_credit "LT investment credit"

		local varlist "VAR251 VAR252 VAR253 VAR254 VAR255 VAR256"
		foreach i of var `varlist' {
		replace `i' =0 if `i'==.
		}

		gen c_mortgages = VAR251+VAR252+VAR253+VAR254+VAR255+VAR256
		label var c_mortgage "Mortgages"

		rename VAR251 c_regular_mortgage

		gen c_regulated_mortgage = VAR252+VAR253+VAR254+VAR255+VAR256

		replace VAR260 =0 if VAR260 ==.
		rename VAR260 c_overdraft
		label var c_overdraft "Overdraft"

		replace VAR270 =0 if VAR270 ==.
		rename VAR270 c_other_credit
		label var c_other_credit "Autres crédit"

		replace VAR280 =0 if VAR280 ==.
		rename VAR280 c_leasing
		label var c_leasing "Leasing"

		local varlist "c_*"
		foreach i of var `varlist' {
		replace `i' =0 if `i'==.
		}

		gen c_all = VAR210 + c_export_credit + c_mortgage + c_st_credit + c_lt_credit + c_overdraft + c_other_credit + c_leasing
		label var c_all "Total Credit"

			gen cibcounty=string(cib,"%02.0f")+string(county,"%02.0f")
			destring cibcounty, replace

			gen c_all_tot =c_all if agent=="TOTAL"
			bys cibcounty time : egen c_cibcounty_tot = max(c_all_tot)

	gen d_temp = d_all if agent=="TOTAL"
	replace d_temp=0 if d_temp==.
	bys cibcounty time : egen d_all_total = max(d_temp)
	drop d_temp

	gen d_temp = d_regulated if agent=="TOTAL"
	replace d_temp=0 if d_temp==.
	bys cibcounty time : egen d_regulated_total = max(d_temp)
	drop d_temp

	merge m:1 cib year using $raw\gea_cib_y_clean.dta
	drop if _m == 2
	drop _m

	gen mutualist = 0
	replace mutualist = 1 if gea== 1163 | gea == 29 | gea== 27

	gen mutualist_poste = 0
	replace mutualist_poste = 1 if gea== 1163 | gea == 29 | gea== 27 | gea == 788

	gen main_retail =0
	replace main_retail =1 if  gea == 30| gea== 768| gea== 160 | gea== 1163 | gea == 29 | gea== 27 | gea == 788

	save $raw\cefit_clean_monthly.dta, replace
