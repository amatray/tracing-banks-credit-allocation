	use cibcounty DRnew using $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta,replace
	drop if DRnew ==.
	keep cibcounty
	duplicates drop
	save $raw\cibcounty_list, replace

	use $raw\REG_bank_county_cefit_DR_ln0.dta, replace
	drop DR*
	merge m:1 cibcounty  using  $raw\cibcounty_list
	keep if _m == 3
	drop _m

	gen year = yofd(dofq(dq))
	drop if year <2010
	drop if year >2015

	drop if dq < tq(2010q3)

	merge m:1 cib dq using  $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta
	drop if _m ==2
	drop _m

	gen DRnew_gap  			= DRnew_lag  * gap
	gen DRnew_spec_gap 		= DRnew_spec_lag * gap
	gen DR1tot_gap 		 	= DRtotal_lag * gap

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)

	save $raw\REG_bank_county_cefit.dta, replace

	use $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta,replace
	keep cib county cibcounty gea tot debt mlt dq firm in_fiben
	gen year = yofd(dofq(dq))

	merge m:1 firm year using $raw\temp_small, keepusing(small_1)
	drop if _m ==2
	replace small = 1 if small == .

	collapse (sum) tot debt (last) cib county year, by(cibcounty dq small)

	gen large = debt if small == 0
	bys cibcounty dq : egen large_f  = max(large)
	replace large_f = 0 if large_f == .
	drop large

	gen not_large = debt if small == 1
	bys cibcounty dq : egen small_f  = max(not_large)
	replace small_f = 0 if small_f == .
	drop not_large

	collapse (sum) debt tot (last) cib county small_f large_f, by(cibcounty dq)

	gen sh_large_debt = large_f / debt
	gen sh_small_debt = small_f / debt

	save $raw\large_cibcounty_dq_v2.dta,replace

	use $raw\REG_bank_county_cefit_DR_ln0.dta, replace
	drop DR*
	merge m:1 cibcounty  using $raw\cibcounty_list
	keep if _m == 3
	drop _m

	gen year = yofd(dofq(dq))
	drop if year <2010
	drop if year >2015

	drop if dq < tq(2010q3)

	merge m:1 cib dq using  $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta
	drop if _m ==2
	drop _m
	save $raw\surfi_cibcounty.dta, replace

	use $raw\surfi_cibcounty.dta, replace
	merge 1:1 cib county dq using $raw\large_cibcounty_dq_v2
	drop if _m == 2
	drop _m

	replace sh_large_debt = 0 if sh_large_debt ==.
	replace large_f		  = 0 if large_f ==.

	replace sh_small_debt = 0 if sh_small_debt ==.
	replace small_f		  = 0 if small_f ==.

	gen large_r 		  = large_f / c_all
	winsor large_r, gen(large_r_w) p(0.01)

	gen small_r 		  = small_f / c_all
	winsor small_r, gen(small_r_w) p(0.01)

	replace debt		  = 0 if debt ==.
	gen tot_corp_r = debt / c_all
	gsort -tot_corp_r
	winsor tot_corp_r, gen(tot_corp_r_w) p(0.01)

	gen c_mlt_r = (c_all - c_st_credit - c_overdraft  )/c_all

	save $raw\large_small_cibcounty_reg_v2.dta, replace

	use $raw\Fiben_bs_2010_2016.dta, replace
	keep firm year rating_lag rating_num
	rename rating_num rating
	save $raw\rating.dta,replace

	use cib county gea tot debt firm dq   using $raw\reg_allfirms_surfi_adj_V2_trim3.dta, replace
	keep cib county gea tot debt firm dq
	gen year = yofd(dofq(dq))

	sort firm year
	merge m:1 firm year using $raw\rating.dta

	keep if _m ==3
	drop _m

	collapse (sum) tot debt (last) rating  rating_lag , by(firm cib county dq)

	gen risky_firm =(rating > 4)

	collapse (sum) tot debt , by(cib county risky_firm dq)

	bys cib county dq : egen cc_tot = sum(tot)
	bys cib county dq : egen cc_debt = sum(debt)

	gen risky_d 	= debt / cc_debt 	if risky_firm == 1
	gen risky_t 	= tot / cc_tot 		if risky_firm ==1

	replace risky_d  = 0 if risky_d ==.
	replace risky_t  = 0 if risky_t ==.

	bys cib county dq : egen risky_debt = max(risky_d)
	bys cib county dq : egen risky_tot  = max(risky_t)

	collapse (last) risky_debt risky_tot ,by(cib county dq )

	save $raw\risky_rating.dta,replace

	use $raw\reg_allfirms_surfi_adj_V2_trim3.dta, replace
	keep cib county gea tot debt firm  dq
	gen year = yofd(dofq(dq))
	merge m:1 firm year using $raw\siren_CN

	keep if _m == 3

	collapse (sum) tot debt , by(naf4 cib county dq)

	bys cib county dq: egen tot_tot = sum(tot)
	bys cib county dq: egen tot_debt =sum(debt)

	gen sh_tot  = tot / tot_tot
	gen sh_debt = debt / tot_debt

	gen year = yofd(dofq(dq))

	destring naf4, replace
	merge m:1 naf4 year using $raw\bankruptcy_rate_naf4

	drop if _m ==2
	replace bankruptcy_ratew = 0 if bankruptcy_ratew ==.
	replace vhigh_bankruptcy_risk = 0 if vhigh_bankruptcy_risk == .
	replace high_bankruptcy_risk = 0 if high_bankruptcy_risk == .

	replace sh_debt = 0 if sh_debt == .
	replace sh_tot = 0 if sh_tot == .
	drop _m

	gen bankruptcy_high_tot =   sh_tot  * high_bankruptcy_risk
	gen bankruptcy_high_debt =  sh_debt * high_bankruptcy_risk

	gen bankruptcy_vhigh_tot =   sh_tot  * vhigh_bankruptcy_risk
	gen bankruptcy_vhigh_debt =  sh_debt * vhigh_bankruptcy_risk

	gen bankruptcy_vvhigh_tot =   sh_tot  * vvhigh_bankruptcy_risk
	gen bankruptcy_vvhigh_debt =  sh_debt * vvhigh_bankruptcy_risk

	collapse (sum)  bankruptcy_vvhigh* bankruptcy_vhigh* bankruptcy_high* , by(cib county dq)

	save $raw\bankruptcy_loans_4.dta,replace
