{

	use $raw\firm_reg_real_all_b_surfi_v2, clear

	capture drop _m
	merge 1:1 firm year using $raw\Fiben_inv.dta
	keep if _m ==3

		reghdfe  capex2 	  $rhs , 	$specification
		estadd local firm 		 "yes" , replace
		estadd local ind_cc_year "yes" , replace
		estadd local n_clus_cib = e(N_clust1)  ,replace
		estadd local Nobs = e(N) , replace
		est store capex2

		gen in_sample = e(sample)
		keep if in_sample == 1

		lab var ln_stock_invw 	"ln(immophy + immoinc)"
		lab var ln_emp			"ln(N of emp)"
		lab var ln_ppe			"ln(immophy)"
		lab var tangible_ppew 	"invcorp over stock inv lag"
		lab var inv_ppe2w 		"invtotr over stock inv lag"

		local varlist "ln_stock_invw ln_ppe inv_ppe2w tangible_ppew ln_emp"
		foreach var in `varlist' {
		reghdfe `var' $rhs, 	$specification
		estadd local firm 		 "yes" , replace
		estadd local ind_cc_year "yes" , replace
		estadd local n_clus_cib = e(N_clust1)  ,replace
		estadd local Nobs = e(N) , replace
		est store `var'
		}

		label var DRreg_lag "Deposit ratio"
		label var DR1reg_gap "Deposit ratio $\times$ Gap"

		esttab ln_stock_invw ln_ppe inv_ppe2w tangible_ppew ln_emp ///
		using $tex/table_A10.tex, ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(DR1reg_gap DRreg_lag) keep(DR1reg_gap DRreg_lag ) ///
		stats(firm ind_cc_year n_clus_cib N r2, ///
		fmt(%3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("Firm FE" "County-industry-year FE" "N firm clusters" ///
		"Observations" "R$^2$")) ///
		label mtitles ("ln(Total capital)" "ln(PP\&E)"  "CapEx / Total capital" "Tangible investment / PP\&E"  "ln(Employment)" ) booktabs  ///
		style(tex)

}
