	use $raw\temp_stat_des4.dta, replace
	merge 1:1 cib dq using $raw\bank_list.dta, assert(3) nogen

	preserve
		use cib dq mlt tot using $raw\temp_in_sample2.dta, clear
		collapse (sum) mlt tot , by(cib dq)
		gen mlt_corp_scr = mlt / tot
		keep cib dq mlt_corp_scr
		tempfile mltscr
		save `mltscr'
	restore
	merge 1:1 cib dq using `mltscr', keep(1 3) nogen

	preserve
		use $raw\large_small_cibcounty_reg_v2.dta, clear
		collapse (mean) c_mlt_r , by(cib dq)
		tempfile cmlt
		save `cmlt'
	restore
	merge 1:1 cib dq using `cmlt', keep(1 3) nogen

	preserve
		use $raw\REG_bank_county_cefit.dta, clear
		collapse (sum) c_all c_snf c_mort_household c_ei , by(cib dq)
		foreach v in c_all c_snf c_mort_household c_ei {
			replace `v' = `v'/1000000
		}
		tempfile cef
		save `cef'
	restore
	merge 1:1 cib dq using `cef', keep(1 3) nogen

	merge 1:1 cib dq using $raw\DR_surfi_gea_household_snf_b.dta , ///
		keepusing(household_over_total_deposits snf_over_total_deposits) keep(1 3) nogen

	gen byte high = deposit_quartile > 2

	local vartab DRtotal_lag household_over_total_deposits snf_over_total_deposits ///
	             c_all c_snf c_mort_household c_ei c_mlt_r mlt_corp_scr ///
	             equity_ratio_lag total_assets

	eststo high_all : estpost tabstat `vartab' if high==1 , s(mean p5 p25 p50 p75 p95 sd N) col(s)
	eststo low_all  : estpost tabstat `vartab' if high==0 , s(mean p5 p25 p50 p75 p95 sd N) col(s)

	local mycells cells("mean(label(Mean) fmt(%9.2f)) p5(label(p5) fmt(%9.2f)) p25(label(p25) fmt(%9.2f)) p50(label(Median) fmt(%9.2f)) p75(label(p75) fmt(%9.2f)) p95(label(p95) fmt(%9.2f)) sd(label(Std.Dev.) fmt(%9.2f)) count(label(Nb.Obs.) fmt(%9.0f))")

	local myvarlabels ///
	varlabels( ///
	DRtotal_lag     "Total deposit ratio\$_{bt}\$" ///
	household_over_total_deposits "\$\frac{\text{Household deposits}}{\text{Total deposits}}\$" ///
	snf_over_total_deposits       "\$\frac{\text{Corporate deposits}}{\text{Total deposits}}\$" ///
	c_all            "Total loans in billion \euro" ///
	c_snf            "Corporate loans in billion \euro" ///
	c_mort_household "Loans to households in billion \euro" ///
	c_ei             "Loans to self-employed in billion \euro" ///
	c_mlt_r          "\$\frac{\text{MLT loans}}{\text{Total loan portfolio}}\$" ///
	mlt_corp_scr     "\$\frac{\text{MLT corporate loans}}{\text{Corporate loan portfolio}}\$" ///
	equity_ratio_lag "Equity ratio\$_{bt}\$" ///
	total_assets     "Assets\$_{bt}\$ in billion \euro" ///
	)

	esttab high_all using $tex/table_03.tex, replace fragment ///
		`mycells' `myvarlabels' ///
		label noobs nonumber nomtitles collabels(none) ///
		prehead("\begin{table}[htbp]\centering" "\caption{}" ///
		        "\begin{tabular}{l*{8}{c}}" "\hline\hline" ///
		        " & Mean & p5 & p25 & Median & p75 & p95 & Std.Dev. & Nb.Obs.\\") ///
		posthead("\hline \multicolumn{9}{l}{\emph{Banks with regulated-deposit ratios in the top half}}\\ \hline")

	esttab low_all using $tex/table_03.tex, append fragment ///
		`mycells' `myvarlabels' ///
		label noobs nonumber nomtitles collabels(none) plain ///
		posthead("\hline \multicolumn{9}{l}{\emph{Banks with regulated-deposit ratios in the bottom half}}\\ \hline") ///
		postfoot("\hline\hline" "\end{tabular}" "\end{table}")
