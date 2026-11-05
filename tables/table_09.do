{
	use $raw\zcf_tot_infiben_V3.dta,replace

	reghdfe large_ratio_tot2 	 DRreg_gap DRreg, 	 $fixed2
	estadd local zcf 			"yes" , replace
	estadd local countydq 		"yes" , replace
	estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store large_ratio

	drop if N<=5

	reghdfe large_ratio_tot2 	 DRreg_gap DRreg, 	 $fixed2
	estadd local zcf 			"yes" , replace
	estadd local countydq 		"yes" , replace
	estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store large_ratio_n5

	use $raw\zcf_debt_mlt.dta,replace

		merge 1:1 zcf dq using $raw\gapm1_zcf_dq_share_st_V2

		keep if _m==3
		drop _m

	rename sh_DRnew_lag_tot  DRreg
	rename sh_DRnew_spec_lag_tot DRspec

	gen DRreg_gap  = DRreg * gap
	gen DRspec_gap = DRspec * gap

	egen countydq = group(dq county_f)

		reghdfe mlt_ratio DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store mlt_reg_2

	drop if N<= 5

		reghdfe mlt_ratio DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store mlt_reg_2n5

	use $raw\zcf_tot_infiben_V3.dta,replace

		reghdfe l_tot DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store tot_reg_2

	drop if N<= 5

		reghdfe l_tot DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store tot_reg_2n5

	use $raw\temp_reg_allfirms_2.dta,replace

	gen year = yofd(dofq(dq))

	merge m:1 firm using $raw\naf4
	destring naf4, replace

	keep if _m==3
	drop _m

	merge m:1 naf4 year using $raw\bankruptcy_rate_naf4

	drop if _m ==2

	replace vhigh_bankruptcy_risk= 0 if vhigh_bankruptcy_risk==.

	gen N_firm=1

		collapse (sum) debt tot N_firm , by(zcf dq vhigh_bankruptcy_risk )

		gen county_f 	 = int(zcf/1000)

		sort zcf vhigh_bankruptcy_risk dq
		gen debt_f 	= debt if vhigh_bankruptcy_risk ==1
		gen tot_f 	= tot if vhigh_bankruptcy_risk ==1

		bys zcf dq : egen debt_risky = max(debt_f)
		bys zcf dq : egen tot_risky = max(tot_f)

		gen debt_nf 	= debt if vhigh_bankruptcy_risk ==0
		gen tot_nf 		= tot if vhigh_bankruptcy_risk ==0

		bys zcf dq : egen debt_nrisky = max(debt_nf)
		bys zcf dq : egen tot_nrisky  = max(tot_nf)

		replace debt_nrisky =0 if debt_nrisky ==.
		replace tot_nrisky=0 if tot_nrisky ==.

		replace debt_risky =0 if debt_risky ==.
		replace tot_risky =0 if tot_risky ==.

		gen risky_ratio_debt = debt_risky / (debt_nrisky + debt_risky)
		gen risky_ratio_tot  = tot_risky / (tot_nrisky + tot_risky)

		winsor risky_ratio_debt,gen(risky_ratio_debtw) p(0.01)
		winsor risky_ratio_tot ,gen(risky_ratio_totw) p(0.01)

		collapse (last) risky_ratio_* (sum) N (last) county_f  , by(zcf dq)

		gen year = yofd(dofq(dq))
		drop if year == 2009

		merge 1:1 zcf dq using $raw\gapm1_zcf_dq_share_st_V2

		keep if _m==3
		drop _m

	rename sh_DRnew_lag_tot  DRreg
	rename sh_DRnew_spec_lag_tot DRspec

		gen DRreg_gap  = DRreg * gap
		gen DRspec_gap = DRspec * gap

	egen countydq = group(dq county_f)

		reghdfe risky_ratio_debt DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store bankruptcy_reg_2

	drop if N<= 5

		reghdfe risky_ratio_debt DRreg DRreg_gap, 	$fixed2
		estadd local zcf 			"yes" , replace
		estadd local countydq 		"yes" , replace
		estadd local n_clus_zcf	 	= e(N_clust1)  ,replace
		estadd local Nobs 			= e(N) , replace
		est store bankruptcy_reg_2n5

		label var DRreg 	"Deposit ratio"
		label var DRreg_gap "Deposit ratio $\times$ Gap"

		label var DRspec 	 "DRspec"
		label var DRspec_gap "DRspecgap"

		esttab tot_reg_2 large_ratio  bankruptcy_reg_2 mlt_reg_2 tot_reg_2n5 large_ratio_n5  bankruptcy_reg_2n5 mlt_reg_2n5 ///
		using $tex/table_09.tex, ///
		star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
		order(DRreg_gap DRreg) keep(DRreg_gap DRreg) ///
		stats(zcf countydq n_clus_zcf N r2, ///
		fmt(%3s %3s %9.0fc %9.0fc %3.2f) ///
		labels("ZIP-code FE" "County-quarter FE" "N ZIP-code clusters" ///
		"Observations" "R$^2$")) ///
		label mtitles ("ln(Total credit)" "Large firms / Total credit"  "High-bankruptcy ind. / Total credit" "MLT credit / Total credit"  "ln(Total credit)" "Large firms / Total credit"  "High-bankruptcy ind. / Total credit" "MLT credit / Total credit") booktabs  ///
		mgroups("All"  "$>$5 firms" ///
		, pattern(1 0 0 0  1 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) ///
		span erepeat(\cmidrule(lr){@span})) ///
		style(tex)

}
