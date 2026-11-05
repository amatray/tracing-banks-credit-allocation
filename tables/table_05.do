{

	use cib dq profitability using $raw\bank_profitability.dta, replace
	keep if quarter(dofq(dq)) == 4
	gen int year = year(dofq(dq)) + 1
	rename profitability profitability_py
	keep cib year profitability_py
	save $raw\t5_prof_py.dta, replace

	use cib dq DRtotal_lag liq_ratio using $raw\temp_stat_des4.dta, replace
	gen int year = year(dofq(dq))
	merge m:1 cib year using $raw\t5_prof_py.dta, keep(master match) nogen
	drop year
	save $raw\t5_bankframe.dta, replace

	use $raw\temp_in_sample2.dta, replace
	cap drop DRtotal_lag
	cap drop liq_ratio
	cap drop profitability_py
	merge m:1 cib dq using $raw\t5_bankframe.dta, keep(master match) nogen

	count if missing(DRtotal_lag)
	count if missing(liq_ratio)
	count if missing(profitability_py)

	egen byte bq = tag(cib dq)
	_pctile liq_ratio if bq == 1 & !missing(liq_ratio), p(1 99)
	gen double w_liq_ratio = min(max(liq_ratio, r(r1)), r(r2)) if !missing(liq_ratio)
	_pctile profitability_py if bq == 1 & !missing(profitability_py), p(1 99)
	gen double w_profitability_py = min(max(profitability_py, r(r1)), r(r2)) if !missing(profitability_py)

	gen double asset_gap 			= gap * ln_asset_lag
	gen double g_DRtotal_lag		= DRtotal_lag * gap
	gen double g_liq_ratio			= w_liq_ratio * gap
	gen double g_profitability_py	= w_profitability_py * gap

	gen gap_in_bp = gap *100
	gen bucket1 = 0
	replace bucket1 = 1 if (gap_in_bp <= 120)
	gen bucket2 = 0
	replace bucket2 = 1 if (gap_in_bp  > 120 &  gap_in_bp  <= 150 )
	gen bucket3 = 0
	replace bucket3 = 1 if (gap_in_bp  > 150 & gap_in_bp  != .)
	gen DRnew_bucket2 = DRnew_lag * bucket2
	gen DRnew_bucket3 = DRnew_lag * bucket3

	gen double deviation = .
	replace deviation = 0.00 if dq==203
	replace deviation = 0.00 if dq==204
	replace deviation = 0.00 if dq==205
	replace deviation = 0.00 if dq==206
	replace deviation = 0.00 if dq==207
	replace deviation = -0.3333333333333333333333333333 if dq==208
	replace deviation = -0.50 if dq==209
	replace deviation = -0.1666666666666666666666666667 if dq==210
	replace deviation = 0.00 if dq==211
	replace deviation = 0.1666666666666666666666666667 if dq==212
	replace deviation = 0.25 if dq==213
	replace deviation = 0.25 if dq==214
	replace deviation = 0.25 if dq==215
	replace deviation = 0.4166666666666666666666666667 if dq==216
	replace deviation = 0.50 if dq==217
	replace deviation = 0.50 if dq==218
	replace deviation = 0.50 if dq==219
	replace deviation = 0.6666666666666666666666666667 if dq==220
	replace deviation = 0.75 if dq==221
	replace deviation = 0.4166666666666666666666666667 if dq==222
	replace deviation = 0.25 if dq==223
	count if missing(deviation)
	gen byte D = abs(deviation) > 1e-10 if !missing(deviation)

	egen byte tag_dq = tag(dq)
	sum gap if tag_dq == 1
	local sd_gap = r(sd)
	gen double DRn_gap 		= DRnew_lag * gap / `sd_gap'
	gen double DRn_gap_D 	= DRn_gap * D
	gen double DRn_gap_noD 	= DRn_gap * (1 - D)

	compress
	save $raw\t5_panel.dta, replace

	use $raw\t5_panel.dta, replace

	reghdfe ln_tot DRnew_lag DR1new_gap , $regspec_im_fbt_b
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c1

	reghdfe ln_tot DRnew_lag DR1new_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c2

	reghdfe ln_tot DRnew_lag DR1new_gap ln_asset_lag asset_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c3

	reghdfe ln_tot DRnew_lag DR1new_gap DRtotal_lag g_DRtotal_lag , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c4

	reghdfe ln_tot DRnew_lag DR1new_gap w_liq_ratio g_liq_ratio , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c5

	reghdfe ln_tot DRnew_lag DR1new_gap w_profitability_py g_profitability_py , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c6

	reghdfe ln_tot DRnew_lag DR1new_gap DRtotal_lag g_DRtotal_lag w_liq_ratio g_liq_ratio ///
		w_profitability_py g_profitability_py , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c7

	reghdfe ln_tot DRnew_lag DRnew_bucket2 DRnew_bucket3 , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c8

	reghdfe ln_tot DRnew_lag DRn_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c9

	reghdfe ln_tot DRnew_lag DRn_gap_D DRn_gap_noD , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store t5_c10

	label var DRnew_lag 			"Deposit ratio"
	label var DR1new_gap 			"Deposit ratio $\times$ Gap"
	label var asset_gap 			"Bank size $\times$ Gap"
	label var g_DRtotal_lag 		"Total deposits / liabilities $\times$ Gap"
	label var g_liq_ratio 			"Liquidity ratio $\times$ Gap"
	label var g_profitability_py 	"Profits / revenues$_{t-1}$ $\times$ Gap"
	label var DRnew_bucket3 		"Deposit ratio $\times$ Gap in top tercile"
	label var DRnew_bucket2 		"Deposit ratio $\times$ Gap in 2$^{\text{nd}}$ tercile"
	label var DRn_gap 				"Deposit ratio $\times$ $\widetilde{Gap}$"
	label var DRn_gap_D 			"Deposit ratio $\times$ $\widetilde{Gap}$ $\times$ D"
	label var DRn_gap_noD 			"Deposit ratio $\times$ $\widetilde{Gap}$ $\times$ (1 - D)"

	esttab t5_c1 t5_c2 t5_c3 t5_c4 t5_c5 t5_c6 t5_c7 t5_c8 t5_c9 t5_c10 ///
	using $tex/table_05.tex, ///
	star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
	order(DRnew_lag DR1new_gap asset_gap g_DRtotal_lag g_liq_ratio g_profitability_py ///
		DRnew_bucket3 DRnew_bucket2 DRn_gap DRn_gap_D DRn_gap_noD) ///
	keep(DRnew_lag DR1new_gap asset_gap g_DRtotal_lag g_liq_ratio g_profitability_py ///
		DRnew_bucket3 DRnew_bucket2 DRn_gap DRn_gap_D DRn_gap_noD) ///
	stats(firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
	fmt(%3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
	labels("Firm-bank-county FE" "Firm-quarter FE" "County-quarter FE" "BHC-quarter FE" ///
	"N bank clusters" "Observations" "R$^2$")) ///
	label nomtitles booktabs style(tex)

}
