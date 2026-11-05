	version 17
	global root "<path to this replication package>"

	do "$root/config.do"
	run "$do/programs/helpers.do"
	do "$do/programs/specifications.do"

	timer clear 1
	timer on 1

	local build ///
		b01_scr_clean ///
		b02_scr_panel ///
		b03_banking_groups ///
		b04_cefit_deposits ///
		b05_fiben_import ///
		b06_fiben_clean ///
		b07_fiben_scr_match ///
		b08_fiben_balance_sheets ///
		b09_rates ///
		b10_scr_sme_sample ///
		b11_scr_all_firms ///
		b12_surfi_liabilities ///
		b13_surfi_deposit_ratio ///
		b14_surfi_deposits_by_counterparty ///
		b15_surfi_securities ///
		b16_bank_characteristics ///
		b17_bank_income_statement ///
		b18_credit_panel ///
		b19_cefit_bank_county_dr ///
		b20_bank_sample ///
		b21_bank_heterogeneity ///
		b22_zcf_exposure ///
		b23_bankruptcy_rates ///
		b24_zcf_aggregates ///
		b25_fiben_real_effects ///
		b26_bank_county_panel ///
		b27_bank_county_outcomes ///
		b28_table_inputs

	foreach step of local build {
		display as text _n(2) "{hline 78}" _n as result ">>> BUILD: `step'" _n as text "{hline 78}"
		do "$do/build/`step'.do"
	}

	local tables ///
		table_02 table_03 table_04 table_05 table_06 table_07 table_08 table_09 table_10 ///
		table_A1 table_A2 table_A3 table_A4 table_A5 table_A6 table_A7 table_A8 table_A9 table_A10

	foreach tab of local tables {
		display as text _n(2) "{hline 78}" _n as result ">>> TABLE: `tab'" _n as text "{hline 78}"
		do "$do/tables/`tab'.do"
	}

	display as text _n(2) "{hline 78}" _n as result ">>> FIGURES" _n as text "{hline 78}"
	do "$do/figures/figures.do"

	timer off 1
	timer list 1
	display as result _n "Replication complete: tables in $tex, figures in $fig"
	capture log close replication
