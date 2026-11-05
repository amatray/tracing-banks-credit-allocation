	use $raw\Fiben_selection_2008_2016.dta, replace
	keep firm year cash* oblig* fl* bl bn bp br br
	gen inventory = bl + bn + bp + br + br
	drop b*
	save $raw\cash.dta, replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
		keep DRnew*  dq cib

		gen quarter = quarter(dofq(dq))
		keep if quarter == 4
		gen year = yofd(dofq(dq))
		sort cib year

	save $raw\DR_surfi_v2.dta,replace

	use $raw\temp_reg_allfirms_2.dta,replace

		egen firm_cib = group(firm cib)

		gen year = yofd(dofq(dq))

		collapse (sum) tot (last) year firm  cib indemin , by(firm_cib dq)

		collapse (last) firm tot cib indemin , by(firm_cib year)

		bys firm year : egen sum_tot = total(tot)
		bys firm_cib year : egen sum_cib_tot = total(tot)

		merge m:1 cib year using $raw\DR_surfi_v2.dta

		drop dq
		drop if _m==2
		drop _m

		sort firm firm_cib year

		gen weight_reg 	 = (sum_cib_tot/sum_tot) * DRnew
		gen weight_spec  = (sum_cib_tot/sum_tot) * DRnew_spec

		collapse (sum) weight* (last) indemin , by (firm year)

		replace year = year+1

		sort firm year

	save $raw\firm_weighted_dr_surfi_v2.dta,replace

		use $raw\livreta.dta, replace
		keep if month ==1
		keep gap year

		merge 1:m year using $raw\firm_weighted_dr_surfi_v2
		keep if _m ==3
		drop _m
		rename weight_reg 	DRreg
		rename weight_spec 	DRspec

		tsset firm year

	save $raw\firm_weighted_dr_gap_surfi_v2.dta,replace

	use $raw\Fiben_bs_2010_2016.dta, replace
	merge 1:1 firm year using $raw\firm_weighted_dr_gap_surfi_v2.dta

	keep if _m == 3

	drop _m

	merge 1:1 firm year using $raw\cash.dta
	keep if _m == 3

	drop _m

	sort firm year
	save $raw\firm_reg_real_all_surfi_v2.dta,replace

	use $raw\firm_reg_real_all_surfi_v2.dta,replace

	gen DR1reg_gap 	= DRreg * gap
	rename DRreg 	DRreg_lag

	gen DR1spec_gap = DRspec * gap
	rename DRspec 	DRspec_lag

	egen ind_cc 		= group(naf3 firm_county)
	egen ind_cc_year 	= group(ind_cc year)
	egen ind_year 		= group(naf3 year)
	egen cc_year 		= group(firm_county year)

	cap drop bank_lev* book_leverage book_lev2
	drop capex*

	gen tot_inv = invr + invcorp

	gen capex2 = tot_inv / totress_lag
	gen tangible2 =  invcorp / totress_lag

	gen fin_leverage	= endfi2 / totress
	gen bank_leverage	= empbanc / totress

	gen fin_leverage2	= endfi2 / totress_lag
	gen bank_leverage2	= empbanc / totress_lag

	gen bank_leverage_lag	= empbanc_lag / totress_lag

	gen ln_emp =ln(yp)

	capture drop cash_r*

	gen cash_r  = cash / totress
	gen cash_r2 = cash / totress_lag

	gen sale =ln(fl)

	gen inventory_sale = inventory / fl

	local varlist "cash_r*  "
	foreach i of var `varlist' {
	winsor `i' , gen (`i'_w) p(0.02)
	drop `i'
	rename `i'_w `i'
	}

	local varlist "inventory_sale cash_r* book_leverage bank_leverage  fin_leverage capex* tangible*"
	foreach i of var `varlist' {
	winsor `i' , gen (`i'_w) p(0.01)
	drop `i'
	rename `i'_w `i'
	}

	local varlist "bank_leverage_lag"
	foreach i of var `varlist' {
	winsor `i' , gen (`i'_w) p(0.01)
	drop `i'
	rename `i'_w `i'
	}

	save $raw\firm_reg_real_all_b_surfi_v2.dta,replace
