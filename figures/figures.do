{
	use $raw\savings_rate.dta, replace
	gen gap 		 = (livret_a - dfr) * 100
	replace dfr 	 = dfr * 100
	replace livret_a = livret_a * 100
	label var gap 		"Livret A - DF rate"
	label var dfr 		"Deposit Facility rate"
	label var livret_a 	"Livret A rate in bp"

	twoway (line dfr date, lwidth(medthick)) (line gap date, lwidth(medthick)), ///
		scheme(s2color8) graphregion(color(white)) ///
		yline(0, lcolor(gs6) lwidth(thin) lpattern(dash)) ///
		ylabel(, angle(0)) xlabel(`=tm(2008m1)'(24)`=tm(2018m1)') ///
		ytitle("Basis points") xtitle("") ///
		legend(region(lstyle(none)))
	graph export $fig\G_gap.pdf, replace

	twoway (line dfr date, lwidth(medthick)) (line gap date, lwidth(medthick)) ///
		(line livret_a date, lwidth(medthick) lcolor(green)), ///
		scheme(s2color8) graphregion(color(white)) ///
		yline(0, lcolor(gs6) lwidth(thin) lpattern(dash)) ///
		ylabel(, nogrid angle(0)) xlabel(`=tm(2008m1)'(24)`=tm(2018m1)', labsize(small)) ///
		ytitle("Basis points") xtitle("") ///
		legend(pos(6) col(2) region(lstyle(none)))
	graph export $fig\G_livret_gap_dfr.pdf, replace
}

{
	use cib using $raw\temp_in_sample2.dta, replace
	duplicates drop
	save $raw\f2_cib.dta, replace

	use cib dq DRnew using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, replace
	keep if quarter(dofq(dq)) == 4
	gen year = year(dofq(dq))
	merge m:1 cib using $raw\f2_cib.dta, keep(match) nogen
	bys cib : egen DR2010 = max(cond(year == 2010, DRnew, .))
	keep if inrange(year, 2011, 2015) & !missing(DRnew, DR2010)

	gen grp = .
	forvalues y = 2011/2015 {
		xtile g = DRnew if year == `y', nq(20)
		replace grp = g if year == `y'
		drop g
	}
	collapse (mean) DRnew DR2010 (count) n = cib, by(year grp)
	sum n

	twoway (function y = x, range(0 0.35) lcolor(gs9) lwidth(thin) lpattern(dash)) ///
		(scatter DR2010 DRnew if year == 2011, msymbol(O) mcolor("26 71 111")) ///
		(scatter DR2010 DRnew if year == 2012, msymbol(S) mcolor("144 53 59")) ///
		(scatter DR2010 DRnew if year == 2013, msymbol(D) mcolor("110 142 132")) ///
		(scatter DR2010 DRnew if year == 2014, msymbol(T) mcolor("108 70 117")) ///
		(scatter DR2010 DRnew if year == 2015, msymbol(X) mcolor("204 102 0")), ///
		graphregion(color(white)) plotregion(lstyle(none)) aspectratio(1) ///
		xlabel(0 (0.05) 0.35, format(%3.2f) labsize(small) grid glcolor(gs15)) ///
		ylabel(0 (0.05) 0.35, format(%3.2f) labsize(small) angle(0) grid glcolor(gs15)) ///
		xtitle("Regulated-deposit ratio in year shown", size(small)) ///
		ytitle("Regulated-deposit ratio in 2010", size(small)) ///
		legend(order(2 "2011" 3 "2012" 4 "2013" 5 "2014" 6 "2015") rows(1) pos(6) size(small) region(lstyle(none)))
	graph export $fig\G_stickiness_2023.pdf, replace
	erase $raw\f2_cib.dta
}

{
	use $raw\t5_panel.dta, replace

	gen double gap_bp = round(gap * 100, 0.01)
	gen byte bin = 1 if gap_bp <= 125
	replace bin = 2 if gap_bp > 125 & gap_bp <= 150
	replace bin = 3 if gap_bp > 150 & gap_bp <= 175
	replace bin = 4 if gap_bp > 175 & gap_bp <= 200
	replace bin = 5 if gap_bp > 200 & gap_bp < .

	cap drop tag_dq
	egen byte tag_dq = tag(dq)
	tab bin if tag_dq == 1

	forvalues k = 2/5 {
		gen double DR_bin`k' = DRnew_lag * (bin == `k')
	}
	reghdfe ln_tot DRnew_lag DR_bin2 DR_bin3 DR_bin4 DR_bin5 , $regspec_im_fbt_c
	local crit = invttail(e(df_r), .025)

	collapse (sum) n_q = tag_dq, by(bin)
	gen double b  = 0
	gen double lo = .
	gen double hi = .
	forvalues k = 2/5 {
		replace b  = _b[DR_bin`k'] if bin == `k'
		replace lo = _b[DR_bin`k'] - `crit' * _se[DR_bin`k'] if bin == `k'
		replace hi = _b[DR_bin`k'] + `crit' * _se[DR_bin`k'] if bin == `k'
	}
	list bin n_q b lo hi, noobs
	save $raw\f3_coef.dta, replace

	twoway (rcap hi lo bin, lcolor("26 71 111") lwidth(medthin)) ///
		(scatter b bin, msymbol(O) mcolor("26 71 111")), ///
		yline(0, lcolor(gs10) lwidth(thin)) ///
		ylabel(0 (-0.05) -0.25, format(%3.2f) angle(0) labsize(small)) ///
		xlabel(1 `" "≤125" "(reference)" "' 2 "125–150" 3 "150–175" 4 "175–200" 5 ">200", labsize(small) noticks) ///
		xscale(range(0.5 5.5)) ///
		ytitle("Deposit ratio × Gap bin", size(small)) xtitle("Gap (basis points)", size(small)) ///
		legend(off) graphregion(color(white)) plotregion(lstyle(none))
	graph export "$fig\Figure3.pdf", replace
	graph export "$fig\Figure3.png", replace width(2000)
}

{
	use $raw\temp_in_sample2.dta, replace
	drop if dq < tq(2011q4)

	xtile DRq = dr_entry, nq(4)
	gen high_dr = (DRq > 2)

	tab dq, g(d_quarter)
	forvalues i = 1/17 {
		gen high_d_quarter`i' = d_quarter`i' * high_dr
	}
	keep if DRq == 1 | DRq == 4
	drop high_d_quarter8

	reghdfe ln_tot high_d_quarter*, $regspec_im_fbt_c
	regsave using $raw\did_dynamic_test, replace

	use $raw\did_dynamic_test, replace
	gen t = _n - 7
	replace t = t - 1 if t < 1
	replace t = 0 if t == 10
	replace coef   = 0 if t == 0
	replace stderr = 0 if t == 0
	gen date = tq(2013q3) + t
	format date %tq
	gen max = coef + 1.96 * stderr
	gen min = coef - 1.96 * stderr
	sort t

	twoway (rspike max min date, lcol(ebblue*0.8) lwidth(thin)) ///
		(connected coef date, lcol(gs10*0.8) lw(thin) lp(shortdash) m(circle) mc(ebblue*1.2) msiz(vsmall)), ///
		graphregion(color(white) margin(2 6 2 2)) plotregion(margin(zero)) ///
		xtitle("") ytitle("") xlabel(206(2)223) ylabel(-0.15(0.05)0.1) ///
		legend(pos(6) order(1 "95% confidence interval" 2 "Banks in top vs. bottom quartile of regulated-deposit ratio distribution (Q3 2010)") ///
			col(1) size(small) region(fc(none)))
	graph export $fig\did_dynamic_median_dr.png, width(1000) replace
}

{
	use cib dq total_deposits using $raw\liabilities_trim.dta, replace
	gen double dep = total_deposits if total_deposits > 0
	tsset cib dq
	gen double g = (dep - L1.dep) / (0.5 * (dep + L1.dep))
	gen byte   n_g  = 0
	gen double s_g  = 0
	gen double ss_g = 0
	forvalues k = 0/7 {
		replace n_g  = n_g  + !missing(L`k'.g)
		replace s_g  = s_g  + cond(missing(L`k'.g), 0, L`k'.g)
		replace ss_g = ss_g + cond(missing(L`k'.g), 0, (L`k'.g)^2)
	}
	gen double deposit_growth_sd = sqrt(max(0, (ss_g - s_g^2 / n_g) / (n_g - 1))) if n_g >= 6
	keep cib dq deposit_growth_sd
	save $raw\fB2_dep_sd.dta, replace

	use cib date_arrete S06_0020 S07_0020 S06_1420 S07_1620 ///
		S06_0050 S06_0170 S06_0390 S06_0520 S06_0530 S06_0540 S06_0720 S06_0730 ///
		S07_0050 S07_0190 S07_0380 S07_0440 S07_0520 S07_0550 S07_0730 S07_0740 S07_0760 ///
		using $bdf\cpte_resu_france_final.dta, replace
	gen int year = floor(date_arrete / 10000)
	egen double interest_expense = rowtotal(S06_0050 S06_0170 S06_0390 S06_0520 S06_0530 S06_0540 S06_0720 S06_0730) if !missing(S06_0020)
	egen double interest_income  = rowtotal(S07_0050 S07_0190 S07_0380 S07_0440 S07_0520 S07_0550 S07_0730 S07_0740 S07_0760) if !missing(S07_0020)
	gen double minus_loss = -S07_1620
	egen double net_profit = rowtotal(S06_1420 minus_loss), missing
	keep cib year interest_expense interest_income net_profit
	save $raw\fB2_flows.dta, replace

	use cib date_arrete S0H_0010 S01_0010 S01_0020 S01_0180 S01_0510 S01_0620 using $raw\situation_raw_trim.dta, replace
	gen int year = floor(date_arrete / 10000)
	gen int dq   = yq(year, mod(floor(date_arrete / 100), 100) / 3)
	format dq %tq
	gen byte filed = !missing(S0H_0010) & S0H_0010 > 0
	foreach v in S01_0010 S01_0020 S01_0180 S01_0510 S01_0620 {
		gen double z_`v' = cond(missing(`v'), 0, `v') if filed
	}
	gen double assets_q = S0H_0010 if filed
	gen double net_interbank = ((z_S01_0010 - z_S01_0020 - z_S01_0180) - (z_S01_0510 - z_S01_0620)) / assets_q if filed
	keep cib dq year assets_q net_interbank
	save $raw\fB2_stocks_q.dta, replace

	collapse (mean) avg_assets = assets_q (count) n_a = assets_q, by(cib year)
	replace avg_assets = . if n_a < 4
	merge 1:1 cib year using $raw\fB2_flows.dta, nogen
	gen double roa = net_profit / avg_assets if avg_assets > 0
	gen double nim = (interest_income - interest_expense) / avg_assets if avg_assets > 0
	gen int dq = yq(year, 4)
	keep cib dq roa nim
	merge 1:1 cib dq using $raw\fB2_stocks_q.dta, keepusing(net_interbank) nogen
	drop if missing(net_interbank) & missing(roa) & missing(nim)
	save $raw\fB2_r2inputs.dta, replace

	use $raw\temp_stat_des4.dta, replace
	bysort cib (dq): gen double DRnew_initial = DRnew_lag[1]
	by cib: gen double DRtotal_initial = DRtotal_lag[1]
	by cib: gen double w_assets = total_assets[1]
	gen double ln_assets = ln(total_assets) if total_assets > 0 & total_assets < .
	egen long bhc_quarter = group(gea dq)
	merge 1:1 cib dq using $raw\bank_profitability.dta, keepusing(profitability prof_fill) keep(master match) nogen
	replace profitability = . if prof_fill == 1
	merge 1:1 cib dq using $raw\fB2_dep_sd.dta, keep(master match) nogen
	merge 1:1 cib dq using $raw\fB2_r2inputs.dta, keep(master match) nogen

	tempname pr
	postfile `pr' str24 x byte spec double b ci_low ci_high N banks sd_x sd_y using $raw\fB2_results.dta, replace
	foreach x in ln_assets equity_ratio_lag liq_ratio profitability deposit_growth_sd ///
		HH_credit_lag DRtotal_lag net_interbank roa nim {

		cap drop eligible ncell common xx
		gen byte eligible = !missing(DRnew_initial, DRnew_lag, DRtotal_initial, DRtotal_lag, `x', bhc_quarter, cib, w_assets) & w_assets > 0
		bys bhc_quarter : egen long ncell = total(eligible)
		gen byte common = eligible & ncell > 1
		quietly _pctile `x' if common, p(1 99)
		gen double xx = max(r(r1), min(r(r2), `x')) if common
		quietly summarize xx if common
		local sx = r(sd)
		quietly summarize DRnew_initial if common
		local sy = r(sd)

		forvalues j = 1/3 {
			if `j' == 1 reghdfe DRnew_initial xx if common [aw=w_assets], absorb(dq) vce(cluster cib) tolerance(1e-10)
			if `j' == 2 reghdfe DRnew_initial xx if common [aw=w_assets], absorb(bhc_quarter) vce(cluster cib) tolerance(1e-10)
			if `j' == 3 reghdfe DRnew_initial xx ibn.dq#c.DRtotal_initial if common [aw=w_assets], absorb(bhc_quarter) vce(cluster cib) tolerance(1e-10)
			post `pr' ("`x'") (`j') (_b[xx]) (_b[xx] - invttail(e(df_r), .025) * _se[xx]) ///
				(_b[xx] + invttail(e(df_r), .025) * _se[xx]) (e(N)) (e(N_clust)) (`sx') (`sy')
		}
	}
	postclose `pr'

	use $raw\fB2_results.dta, replace
	gen double b_std       = b       * sd_x / sd_y
	gen double ci_low_std  = ci_low  * sd_x / sd_y
	gen double ci_high_std = ci_high * sd_x / sd_y
	list x spec N banks, noobs sepby(x)
	save $raw\fB2_results.dta, replace

	gen byte row = .
	local r = 0
	foreach x in ln_assets equity_ratio_lag liq_ratio profitability deposit_growth_sd ///
		HH_credit_lag DRtotal_lag net_interbank roa nim {
		local ++r
		replace row = `r' if x == "`x'"
	}
	gen double position = row + (spec - 2) * 0.22

	twoway ///
		(rcap ci_high_std ci_low_std position if spec == 1, horizontal lcolor("26 71 111") lwidth(thin)) ///
		(scatter position b_std if spec == 1, msymbol(O) mcolor("26 71 111")) ///
		(rcap ci_high_std ci_low_std position if spec == 2, horizontal lcolor("144 53 59") lwidth(thin)) ///
		(scatter position b_std if spec == 2, msymbol(S) mcolor("144 53 59")) ///
		(rcap ci_high_std ci_low_std position if spec == 3, horizontal lcolor("110 142 132") lwidth(thin)) ///
		(scatter position b_std if spec == 3, msymbol(D) mcolor("110 142 132")), ///
		yscale(reverse range(0.5 10.5) noline) ///
		ylabel(1 "Log total assets" 2 "Equity ratio (lagged)" 3 "Liquidity ratio" ///
			4 "Profits / revenues" 5 "Deposit-growth volatility" ///
			6 "Household loan share (lagged)" 7 "Total deposits / liabilities (lagged)" ///
			8 "Net interbank lending / assets" 9 "Return on assets" 10 "Net interest margin", ///
			angle(0) labsize(small) noticks nogrid) ///
		ytitle("") xtitle("Initial exposure coefficient (standard-deviation units)", size(small)) ///
		xlabel(-1 (0.5) 1.5, labsize(small)) xline(0, lcolor(gs10) lwidth(thin)) ///
		legend(order(2 "Quarter fixed effects" 4 "Banking-group × quarter fixed effects" ///
			6 "Banking-group × quarter FE + deposit share × quarter") cols(1) size(small) position(6) region(lstyle(none))) ///
		graphregion(color(white)) plotregion(lstyle(none))
	graph export "$fig\FigureB2.pdf", replace
	graph export "$fig\FigureB2.png", replace width(2000)
}

{
	use cib contrepartie year month deposits_centralisable deposits_complement checking_account using $raw\deposit_surfi_clean2.dta, replace
	gen dq = yq(year, ceil(month / 3))
	collapse (mean) deposits_centralisable deposits_complement checking_account, by(contrepartie cib dq)
	gen main_c = 3
	replace main_c = 1 if contrepartie == "Societes non financieres" | contrepartie == "Entrepreneurs individuels"
	replace main_c = 2 if contrepartie == "Particuliers"
	collapse (sum) deposits_centralisable deposits_complement checking_account, by(main_c cib dq)
	save $raw\fB3_resid.dta, replace

	use cib contrepartie year month deposits_centralisable deposits_complement checking_account using $raw\deposit_surfi_non_resi_clean2.dta, replace
	gen dq = yq(year, ceil(month / 3))
	collapse (mean) deposits_centralisable deposits_complement checking_account, by(contrepartie cib dq)
	gen main_c = 3
	replace main_c = 1 if contrepartie == "Societes non financieres" | contrepartie == "Entrepreneurs individuels"
	replace main_c = 2 if contrepartie == "Particuliers"
	collapse (sum) deposits_centralisable_nr = deposits_centralisable deposits_complement_nr = deposits_complement ///
		checking_account_nr = checking_account, by(main_c cib dq)

	merge 1:1 cib main_c dq using $raw\fB3_resid.dta, nogen
	foreach i in deposits_centralisable deposits_complement checking_account checking_account_nr {
		replace `i' = 0 if `i' == .
	}
	replace checking_account 		= checking_account + checking_account_nr
	replace deposits_centralisable 	= deposits_centralisable + deposits_centralisable_nr
	replace deposits_complement 	= deposits_complement + deposits_complement_nr
	foreach i in deposits_centralisable deposits_complement {
		replace `i' = 0 if `i' == .
	}
	gen year = yofd(dofq(dq))
	drop if year == 2016 | dq == tq(2010q2)

	merge m:1 cib year using $raw\gea_y.dta, keepusing(gea) keep(master match) nogen
	tostring cib, gen(cib_s)
	gen caisse_ca = (substr(cib_s, 5, 1) == "6" & gea == 27 & !inlist(cib, 30006, 39996))

	gen casa = deposits_centralisable * (cib == 30006)
	bys dq : egen casa_cent = max(casa)
	replace casa = deposits_complement * (cib == 30006)
	bys dq : egen casa_comp = max(casa)
	bys dq : egen tot_check = sum(checking_account) if caisse_ca == 1
	replace deposits_centralisable 	= casa_cent * checking_account / tot_check if caisse_ca == 1
	replace deposits_complement 	= casa_comp * checking_account / tot_check if caisse_ca == 1
	drop if cib == 30006 | gea == -1 | cib == 11808

	merge m:1 cib dq year using $raw\liabilities_trim.dta, keepusing(total_liabilities) keep(match) nogen

	gen caisse_ep = (substr(cib_s, 5, 1) == "5" & gea == 1163)
	gen double rate = .
	replace rate = 0.2  if year == 2010
	replace rate = 0.24 if year == 2011
	replace rate = 0.3  if year == 2012
	replace rate = 0.36 if year == 2013
	replace rate = 0.38 if year == 2014
	replace rate = 0.39 if year == 2015
	replace rate = 0.76 if year == 2010 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0.66 if year == 2011 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0.6  if year == 2012 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0.63 if year == 2013 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0.6  if year == 2014 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0.6  if year == 2015 & !(caisse_ep == 1 | gea == 29)
	replace rate = 0    if gea == 788
	gen dep = deposits_centralisable * rate + deposits_complement
	collapse (sum) dep, by(cib dq)

	preserve
		use cib using $raw\temp_in_sample2.dta, replace
		duplicates drop
		save $raw\fB3_cib.dta, replace
	restore
	merge m:1 cib using $raw\fB3_cib.dta, keep(match) nogen
	erase $raw\fB3_cib.dta
	save $raw\fB3_bank_dq.dta, replace

	use $raw\livreta.dta, replace
	gen dq = qofd(mdy(month, 1, year))
	collapse (mean) gap, by(dq)
	save $raw\fB3_gap.dta, replace

	use $raw\fB3_bank_dq.dta, replace
	tsset cib dq
	gen flow2 = (dep - L1.dep) / (0.5 * (dep + L1.dep))
	bys dq : egen tot_dep = sum(dep)
	gen wflow2 = dep / tot_dep * flow2
	collapse (sum) wflow2, by(dq)
	merge 1:1 dq using $raw\fB3_gap.dta, keep(master match) nogen
	erase $raw\fB3_gap.dta
	keep if dq > tq(2010q3)
	format dq %tq
	save $raw\fB3_series.dta, replace

	twoway (bar wflow2 dq) (line gap dq, lwidth(medthick) yaxis(2)), ///
		scheme(s2color8) graphregion(color(white)) ///
		yline(0, lcolor(gs6) lwidth(thin) lpattern(dash)) ///
		ylabel(0 (0.01) 0.05, angle(0) axis(1)) ylabel(0.5 (0.5) 3, angle(0) axis(2)) ///
		ytitle("Deposit growth", axis(1) margin(r+3)) ytitle("Gap", axis(2) margin(l+3)) ///
		xlabel(`=tq(2010q4)'(4)`=tq(2015q4)') xtitle("") ///
		legend(order(1 "Quarterly change in deposit outstanding amounts (weighted average)" 2 "Livret A - DF rate") ///
			cols(1) size(small) pos(6) region(lstyle(none)))
	graph export "$fig\FigureB3.pdf", replace
	graph export "$fig\FigureB3.png", replace width(2000)
}
