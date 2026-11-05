	use $raw\ALL_reg.dta, replace

	keep if month ==3 | month ==6 | month ==9 | month==12

	gen quarter = 1 if month == 3
	replace quarter = 2 if month == 6
	replace quarter = 3 if month == 9
	replace quarter = 4 if month == 12

	gen dq = yq(y,q)

	format dq %tq

	sort cib county dq
	merge 1:m cibcounty dq using $raw\Fiben_scr_cibcounty.dta

	keep if _m==3
		drop if year <2009

	drop _m

		gen debt = mlt + st

		gen r_loan 	= ln(debt)
		gen r_und 	= ln(und)
		gen r_mlt 	= ln(mlt)
		gen r_st 	= ln(st)
		gen r_newst = ln(newst)
		gen r_arf 	= ln(arf)
		gen r_cb 	= ln(cb)

		sort firm cibcounty dq

	bys cib : egen _hasDR = max(DR < .)
	drop _hasDR

	save $raw\Fiben_scr_cefit_sme.dta, replace

	use  $raw\Fiben_scr_cefit_sme.dta, replace

		keep   zcf r_* firm dq county* cib cibcounty time DR_lag DR1_gap ///
 mutualist* naf3 indep* lme_first main_retail yp in_fiben ///
 debt und mlt newst st arf cb gea independent

	bys firm cibcounty: gen newid = 1 if _n==1
    replace newid = sum(newid)
	rename newid firm_cc

	cap drop dup
	gen i=1
	bys firm_cc dq : egen dup=sum(i)
	cap drop max_debt
	bys firm_cc dq : egen max_debt = max(debt)
	keep if max_debt == debt
	drop max_debt
	bys firm_cc dq : egen max_debt = max(und)
	keep if max_debt == und
	drop max_debt

	cap drop dup
	bys firm_cc dq : egen dup=sum(i)
	drop dup
	gsort firm_cc dq -debt cib
	duplicates drop firm_cc dq, force

	tsset firm_cc dq

	gen year = yofd(dofq(dq))

	bys firm : egen indemin = min(independent)

	gen mlt_ratio = mlt/(mlt+st)

	gen tot =debt + und
	gen r_tot =ln(tot)

		xtset firm_cc dq
		egen firm_dq = group(firm dq)
		egen county_dq = group(county dq)
		egen gea_dq = group(gea dq)
		egen cc_dq = group(cibcounty dq)

	save  $raw\temp_reg_sme.dta,replace
