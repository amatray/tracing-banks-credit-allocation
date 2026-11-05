		use $raw\livreta.dta , clear

		gen dq = qofd(mdy(month, 1, year))
		format dq %tq

		collapse (mean) gap, by(dq)

		save $raw\livreta_gap_dq.dta, replace

		use $raw\livreta_gap_dq.dta, replace

		use  $raw\temp_reg_allfirms_2.dta,replace
		drop DR*

		sort cib dq

		drop if dq < tq(2010q3)
		drop if dq > tq(2015q4)

		sort dq

		merge m:1 dq using $raw\livreta_gap_dq.dta
		keep if _m==3
		drop _m

		sort cib dq

		merge m:1 cib dq using  $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta
		drop if _m ==2

		count

		drop _m

		gen DR1new_gap 		 = DRnew_lag  * gap
		gen DR1new_spec_gap  = DRnew_spec_lag * gap
		gen DR1tot_gap 		 = DRtotal_lag * gap

		gen 	HH_gap = HH_credit_lag * gap
		gen HH_credit_lag0 = cond(missing(HH_credit_lag), 0, HH_credit_lag)
		gen HH_gap0        = HH_credit_lag0 * gap

	drop if dq == tq(2010q3)

	count

	save $raw\reg_allfirms_surfi_adj_V2_trim3.dta,replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
	keep cib dq DRnew_lag DRtotal_lag

	bys cib : egen entry = min(dq)
	gen dr_init = DRnew_lag if dq == tq(2010q4)
	replace dr_init = 0 if dr_init == .
	bys cib : egen dr_entry = max(dr_init)
	drop dr_init

	gen dr_totinit = DRtotal_lag if dq == tq(2010q4)
	replace dr_totinit = DRtotal_lag if dr_totinit == . & dq == entry
	replace dr_totinit = 0 if dr_totinit ==.
	bys cib : egen dr_totentry = max(dr_totinit)
	drop dr_totinit

	bys cib : gen dr_init = DRnew_lag if dq == tq(2011q1)
	replace dr_init = DRnew_lag if dr_init == . & dq == entry
	replace dr_init = 0 if dr_init ==.
	bys cib : egen dr_2010 = max(dr_init)
	drop dr_init

	bys cib : gen dr_totinit = DRtotal_lag if dq == tq(2011q1)
	replace dr_totinit = DRtotal_lag if dr_totinit == . & dq == entry
	replace dr_totinit = 0 if dr_totinit ==.
	bys cib : egen dr_tot2010 = max(dr_totinit)
	drop dr_totinit

	keep dq cib dr_2010 dr_entry dr_tot2010 dr_totentry
	save $raw\time_invariant_dr, replace

	cd $raw
	use total_credit_hh total_credit HH_gap* HH_credit_lag* deposits_centralisable deposits_net regulated_rate* gap firm firm_cc dq county gea cibcounty cib indemin DR* tot debt mlt using $raw\reg_allfirms_surfi_adj_V2_trim3.dta, replace
	merge m:1 cib dq using $raw\equity

	drop if _m == 2

		xtset firm_cc dq

		egen firm_dq = group(firm dq)
		egen county_dq = group(county dq)
		egen gea_dq = group(gea dq)
		egen cc_dq = group(cibcounty dq)

		gen ln_tot 	=	ln(tot)
		gen drawn_r =	debt/tot
		gen mlt_r 	= 	mlt/tot
		gen mlt_r2 	= 	mlt/debt
		replace mlt_r2 = 0 if debt == 0

		lab var ln_tot  "ln(Total credit)"
		lab var drawn_r "Drawn debt / total debt"
		lab var mlt_r 	"MLT debt / Total debt"

		drop if ln_tot == .

		gen year = yofd(dofq(dq))
		drop _m

		merge  m:1 firm year using $raw\fiben_list.dta

		drop if _m == 2

		gen in_fiben =(_m == 3)

		drop _m

		merge m:1 cib dq using $raw\time_invariant_dr
		drop if _m ==2
		drop _m

		gen DR2010_gap 		 = dr_2010  * gap
		gen DRentry_gap 	 = dr_entry  * gap
		gen DRtot2010_gap 		= dr_tot2010  * gap
		gen DRtotentry_gap 	 	= dr_totentry  * gap

	save $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta,replace

	use $raw\temp_reg_allfirms_surfi_adj_V2_trim3.dta,replace

        reghdfe ln_tot DRnew_lag DR1new_gap , $regspec_im_fbt_c

        cap drop in_sample
        gen in_sample =e(sample)
        keep if in_sample== 1
        save $raw\temp_in_sample2.dta,replace
