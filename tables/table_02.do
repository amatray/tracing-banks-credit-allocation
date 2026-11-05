{
	if "$regspec5" == "" global regspec5 "absorb(cibcounty county_time gea_time) vce(cluster cibcounty)"

	{

	use $raw\temp_stat_des4.dta, replace

	lab var DRnew 			  "Deposit ratio_bt (Q4 2010 − Q4 2015)"
	lab var DRtot 			  "Total deposit ratio_bt"
	lab var equity_ratio 	  "Equity ratio_bt"
	lab var total_assets      "Assets_bt in bn \euro"
	lab var ibk_asset2w       "Interbank/Assets_bt"
	lab var liq_ratio 		  "Liquidity ratio_bt"
	lab var HH_credit_lag     "Share of credit to households_bt"

	replace HH_credit_lag = 0 if HH_credit_lag ==.

	gen in_sample=1 if DRtot!=.

	local vartab DRnew DRtot equity_ratio total_assets liq_ratio HH_credit_lag
	eststo panelA :  estpost tabstat `vartab' if in_sample==1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

		use $raw\savings_rate.dta, replace
		gen gap  = (livret_a - dfr) *100
		label var gap   	"Livret A - DF rate"

		drop if year<2010
		drop if year>2015

		replace gap=gap/100

		local vartab gap
		eststo gap :  estpost tabstat `vartab', s(mean p5 p25 p50 p75 p95 sd N) col(s)

	}

	{
	use tot using $raw\temp_in_sample2.dta, replace
	count

	local vartab tot
	eststo panelB :  estpost tabstat `vartab', s(mean p5 p25 p50 p75 p95 sd N) col(s)

	}

	{

	use $raw\large_small_cibcounty_reg_v2.dta, replace

	gen DRnew_gap  		= DRnew_lag  * gap

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)

	gen double small_corp = 1 - sh_large_debt

	reghdfe small_corp DRnew_gap DRnew_lag , $regspec5
	gen s_small_corp = e(sample)
	eststo panelC_row1 :  estpost tabstat small_corp if s_small_corp == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	reghdfe small_r_w DRnew_gap DRnew_lag , $regspec5
	gen s_small_r_w = e(sample)
	eststo panelC_row2 :  estpost tabstat small_r_w if s_small_r_w == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	reghdfe c_mlt_r DRnew_gap DRnew_lag , $regspec5
	gen s_c_mlt_r = e(sample)
	eststo panelC_row6 :  estpost tabstat c_mlt_r if s_c_mlt_r == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	use $raw\REG_bank_county_cefit.dta, replace

	gen ei_sum2 = c_ei / (c_all)

	reghdfe ei_sum2 DRnew_gap DRnew_lag , $regspec5
	gen s_ei_sum2 = e(sample)
	eststo panelC_row3 :  estpost tabstat ei_sum2 if s_ei_sum2 == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	use $raw\bankruptcy_loans_4.dta, replace

	merge m:1 cib dq using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, keep(3) nogen

	merge m:1 dq using $raw\livreta_gap_dq.dta, keep(3) nogen

	merge 1:1 cib county dq using $raw\sample_cib_county.dta, keep(3) nogen

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)
	egen cibcounty 	 = group(cib county)

	gen DRnew_gap = DRnew_lag * gap

	reghdfe bankruptcy_vhigh_debt DRnew_gap DRnew_lag , $regspec5
	gen s_bankruptcy = e(sample)
	eststo panelC_row4 :  estpost tabstat bankruptcy_vhigh_debt if s_bankruptcy == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	use $raw\risky_rating.dta, replace

	merge m:1 cib dq using $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta, keep(3) nogen

	merge m:1 dq using $raw\livreta_gap_dq.dta, keep(3) nogen

	egen county_time = group(county dq)
	egen gea_time 	 = group(gea dq)
	egen cibcounty 	 = group(cib county)

	gen DRnew_gap = DRnew_lag * gap

	reghdfe risky_debt DRnew_gap DRnew_lag , $regspec5
	gen s_risky = e(sample)
	eststo panelC_row5 :  estpost tabstat risky_debt if s_risky == 1, s(mean p5 p25 p50 p75 p95 sd N) col(s)

	}

	{
	use $raw\zcf_tot_infiben_V3.dta,replace

		reghdfe l_tot DRreg DRreg_gap, 	$fixed2
		cap drop in_sample
		gen in_sample =e(sample)
		keep if in_sample== 1

	local vartab DRreg tot
	eststo panelD :  estpost tabstat `vartab', s(mean p5 p25 p50 p75 p95 sd N) col(s)

	}

	{

	use $raw\firm_reg_real_all_b_surfi_v2.dta,replace
	capture drop _m
	merge 1:1 firm year using $raw\Fiben_inv.dta
	keep if _m ==3

		reghdfe  capex2 	  $rhs , 	$specification
		gen in_sample = e(sample)
		keep if in_sample == 1

		replace stock_inv  = stock_inv  /1000
		replace immophy    = immophy  /1000

	local vartab DRreg_lag stock_inv immophy tangible_ppew inv_ppe2w yp
	foreach var in `vartab' {
		replace `var' = 0 if `var' == .
		}
	eststo panelE :  estpost tabstat `vartab', s(mean p5 p25 p50 p75 p95 sd N) col(s)

	}

	{
local mycells cells("mean(label(Mean) fmt(%9.2f)) p5(label(p5) fmt(%9.2f)) p25(label(p25) fmt(%9.2f)) p50(label(Median) fmt(%9.2f)) p75(label(p75) fmt(%9.2f)) p95(label(p95) fmt(%9.2f)) sd(label(Std.Dev.) fmt(%9.2f)) count(label(Nb.Obs.) fmt(%9.0f))")

local myvarlabels ///
varlabels( ///
	DRnew 			  "Deposit ratio_bt (Q4 2010 − Q4 2015)" ///
	DRtot 			  "Total deposit ratio_bt" ///
	equity_ratio 	  "Equity ratio_bt" ///
	total_assets      "Assets_bt in bn \euro" ///
	ibk_asset2w       "Interbank/Assets_bt" ///
	liq_ratio 		  "Liquidity ratio_bt" ///
	HH_credit_lag     "Share of credit to households_bt" ///
	gap 			  "Gap_t" ///
	tot 				"Total credit" ///
    small_corp             "Loans to small firms / Corporate loans" ///
    small_r_w              "Loans to small firms / Total loans" ///
    ei_sum2                "Loans to self-employed / Total loans" ///
    bankruptcy_vhigh_debt  "Loans to high-bankruptcy industries / Total loans" ///
    risky_debt             "Loans to risky firms / Loans to rated firms" ///
    c_mlt_r                "MLT loans / Total loans" ///
	DRreg			"Deposit ratio_zt"  ///
	stock_inv 		"Capital Assets in million \euros"  ///
	immophy	 	    "PP\&E in million \euros"  ///
	tangible_ppew 	"Tangible inv./PP\&E"  ///
	inv_ppe2w 		"CapEx/Capital Assets"  ///
	yp				"N of employees" ///
)

esttab panelA using $tex/table_02.tex, replace fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) ///
    prehead("\begin{table}[htbp]\centering" ///
            "\caption{}" ///
            "\begin{tabular}{l*{8}{c}}" ///
            "\hline\hline" ///
            " & Mean & p5 & p25 & Median & p75 & p95 & Std.Dev. & Nb.Obs.\\") ///
    posthead("\hline")

esttab gap using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelB using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none)

esttab panelC_row1 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none)

esttab panelC_row2 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelC_row3 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelC_row4 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelC_row5 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelC_row6 using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) plain

esttab panelD using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none)

esttab panelE using $tex/table_02.tex, append fragment ///
    `mycells' ///
    `myvarlabels' ///
    label noobs nonumber nomtitles collabels(none) ///
    postfoot("\hline\hline" ///
             "\end{tabular}" ///
             "\end{table}")
	}

}
