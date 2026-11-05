	use ind* zcf debt firm_cc firm und st mlt dq DR_lag DR1_gap county gea cibcounty cib naf3 lme_first using $raw\temp_reg_sme.dta,replace

	capture drop r_loan
	capture drop micro
	capture drop tot

	gen r_loan =ln(debt)
	gen micro = 0
	replace micro=1 if lme_first==1
	gen tot= debt + und

	keep naf3 independent indemin cib zcf firm dq debt und st mlt tot r_loan DR_lag DR1_gap county gea cibcounty micro lme_first

	egen firm_cc = group(firm cibcounty)

		gen i =1
		bys firm_cc dq : egen n=sum(i)
		drop if n > 1 & micro == 0
		drop n

	save $raw\temp_reg_allfirms_2.dta,replace

		xtset firm_cc dq

		egen firm_dq = group(firm dq)
		egen county_dq = group(county dq)
		egen gea_dq = group(gea dq)
		egen cc_dq = group(cibcounty dq)

	save $raw\temp_reg_allfirms.dta,replace
