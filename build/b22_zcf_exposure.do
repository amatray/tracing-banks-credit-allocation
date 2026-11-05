	use $raw\livreta.dta , clear

	gen dq = qofd(mdy(month, 1, year))
	format dq %tq

	keep if month == 1|month==4|month==7|month ==10
	keep gap dq
	save $raw\livreta_gapm1_dq.dta, replace

	use gea tot cib zcf dq using $raw\temp_reg_allfirms.dta,replace
	gen county_f = int(zcf/1000)
	collapse (sum) tot (last) gea county_f  , by(cib zcf dq)
	save $raw\credit_registry_zcf_sumtot_dq.dta, replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace

	merge m:1 dq using $raw\livreta_gapm1_dq.dta,nogen keep(3)
	save $raw\gapm1_cibDR_dq_V2,replace

		cap program drop merge_gapm1
	program merge_gapm1
		args infile outfile amt
		use `infile', replace
		merge m:1 cib dq using $raw\gapm1_cibDR_dq_V2, nogen keep(1 3)

		egen long _cz = group(cib zcf)
		tsset _cz dq
		gen double `amt'_l1 = L1.`amt'
		tsset, clear
		drop _cz

		bys zcf dq : egen double tot_l1_zcf = total(`amt'_l1)
		gen double share_l1 = `amt'_l1 / tot_l1_zcf
		bys zcf dq : egen double sumshare = total(share_l1)

		drop if year == .
		foreach var in DRnew_spec_lag DRnew_lag {
			gen double sh_`var'_`amt' = share_l1 * `var'
		}
		collapse (sum) sh_DR* (mean) gap (first) county_f (max) sumshare , by(zcf dq)

		drop sumshare
		drop if dq == tq(2010q3)
		save `outfile', replace
	end

	merge_gapm1		$raw\credit_registry_zcf_sumtot_dq.dta 		$raw\gapm1_zcf_dq_share_st_V2  tot
