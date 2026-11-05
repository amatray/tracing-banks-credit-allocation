	use $raw\temp_reg_allfirms_2.dta,replace
	gen year =yofd(dofq(dq))
	merge m:1 firm year using $raw\temp_small, keepusing(small_1)
	replace small = 1 if small == .

	gen N=1

	collapse (sum) debt tot N  , by(zcf dq small)

		sort zcf small dq
		gen debt_f 	= debt if small ==0
		gen tot_f 	= tot  if small ==0
		bys zcf dq : egen debt_large = max(debt_f)
		bys zcf dq : egen tot_large  = max(tot_f)

		gen debt_sm = debt if small ==1
		gen tot_sm 	= tot  if small ==1
		bys zcf dq : egen debt_small = max(debt_sm)
		bys zcf dq : egen tot_small  = max(tot_sm)

		replace debt_small =0 if debt_small ==.
		replace tot_small  =0 if tot_small ==.

		replace debt_large =0 if debt_large ==.
		replace tot_large =0 if tot_large ==.

		gen large_ratio_debt = debt_large / debt_small
		gen large_ratio_tot  = tot_large / tot_small
		gen large_ratio_debt2 = debt_large / (debt_small+debt_large)
		gen large_ratio_tot2  = tot_large / (tot_small+tot_large)

		winsor large_ratio_debt,gen(large_ratio_debtw) p(0.01)
		winsor large_ratio_tot ,gen(large_ratio_totw) p(0.01)

		sort zcf dq
		keep zcf dq debt tot large_ratio_debt* large_ratio_tot* N

		collapse (sum) debt tot N (last)  large_ratio_debt* large_ratio_tot* , by(zcf dq)

		gen l_debt = log(debt)
		gen l_tot  = log(tot)

		gen year = yofd(dofq(dq))
		drop if year == 2009

	save $raw\zcf_debt_tot_infiben_v2.dta,replace

	use $raw\zcf_debt_tot_infiben_v2.dta,replace

		merge 1:1 zcf dq using $raw\gapm1_zcf_dq_share_st_V2

		keep if _m==3
		drop _m
		rename sh_DRnew_lag_tot  DRreg
		rename sh_DRnew_spec_lag_tot DRspec

		gen DRreg_gap  = DRreg * gap
		gen DRspec_gap = DRspec * gap

	egen countydq = group(dq county_f)

	save $raw\zcf_tot_infiben_V3.dta,replace

	use $raw\temp_reg_allfirms_2.dta,replace

		gen N = 1

		gen mlt_ratio = mlt /tot
		winsor mlt_ratio , gen(mlt_ratio_w) p(0.01)

		gen mlt_st_ratio = mlt /st
		winsor mlt_st_ratio , gen(mlt_st_ratio_w) p(0.01)
		collapse (mean) mlt_ratio_w mlt_st_ratio_w (sum) N , by(zcf dq )

		gen year = yofd(dofq(dq))
		drop if year == 2009

	save $raw\zcf_debt_mlt.dta,replace

	use $raw\siren_CN, replace
	collapse (last) naf4, by(firm)
	save $raw\naf4, replace
