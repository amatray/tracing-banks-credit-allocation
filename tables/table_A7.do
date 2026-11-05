{
	use $raw\t5_panel.dta, replace

	reghdfe ln_tot DRnew_lag DR1new_gap , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local c_dep 			"" , replace
	estadd local c_liq 			"" , replace
	estadd local c_prof 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store a7_base

	reghdfe ln_tot DRnew_lag DR1new_gap ibn.dq#c.DRtotal_lag , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local c_dep 			"Y" , replace
	estadd local c_liq 			"" , replace
	estadd local c_prof 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store a7_dep

	reghdfe ln_tot DRnew_lag DR1new_gap ibn.dq#c.w_liq_ratio , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local c_dep 			"" , replace
	estadd local c_liq 			"Y" , replace
	estadd local c_prof 		"" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store a7_liq

	reghdfe ln_tot DRnew_lag DR1new_gap ibn.dq#c.w_profitability_py , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local c_dep 			"" , replace
	estadd local c_liq 			"" , replace
	estadd local c_prof 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store a7_prof

	reghdfe ln_tot DRnew_lag DR1new_gap ibn.dq#c.DRtotal_lag ibn.dq#c.w_liq_ratio ///
		ibn.dq#c.w_profitability_py , $regspec_im_fbt_c
	estadd local firm_cc 		"Y" , replace
	estadd local firm_dq 		"Y" , replace
	estadd local county_dq 		"Y" , replace
	estadd local gea_dq 		"Y" , replace
	estadd local c_dep 			"Y" , replace
	estadd local c_liq 			"Y" , replace
	estadd local c_prof 		"Y" , replace
	estadd local n_clus_cib 	= e(N_clust1)  ,replace
	estadd local Nobs 			= e(N) , replace
	est store a7_all

	label var DRnew_lag  "Deposit ratio"
	label var DR1new_gap "Deposit ratio $\times$ Gap"

	esttab a7_base a7_dep a7_liq a7_prof a7_all ///
	using $tex/table_A7.tex, ///
	star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) collabels(none) replace ///
	order(DR1new_gap DRnew_lag) keep(DR1new_gap DRnew_lag) ///
	stats(c_dep c_liq c_prof firm_cc firm_dq county_dq gea_dq n_clus_cib N r2, ///
	fmt(%3s %3s %3s %3s %3s %3s %3s %9.0fc %9.0fc %3.2f) ///
	labels("Total deposits / liabilities $\times$ quarter" "Liquidity ratio $\times$ quarter" ///
	"Profits / revenues$_{t-1}$ $\times$ quarter" "Firm-bank-county FE" "Firm-quarter FE" ///
	"County-quarter FE" "BHC-quarter FE" "N bank clusters" "Observations" "R$^2$")) ///
	label nomtitles booktabs style(tex)

}
