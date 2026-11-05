use "$bdf\m_clienre_france_final.dta", clear
save $raw\client_re.dta, replace

use $raw\client_re.dta, clear

	gen date=string(date_arrete,"%02.0f")

	gen year = substr(date,1,4)
	gen month = substr(date,5,2)
	destring year,replace
	destring month,replace
	drop date

	gen time = ym(y,m)
	format time %tm

	local varlist "S02_07* S02_08* S02_04* S02_06* S02_0300 S02_0060 S04_0700 S04_0340 S04_0610"

		foreach i of var `varlist' {
		replace `i'= 0 if `i' ==.
		}

		local varlist "S*"
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	gen M_S02_0630_sum = M_S02_0630_inf1 + M_S02_0630_1a2 + M_S02_0630_sup2
	replace M_S02_0630 = M_S02_0630_sum if M_S02_0630 == 0 & (M_S02_0630_sum !=0)

	gen regulated_rate_deposits =  M_S02_0740 + M_S02_0750 + M_S02_0760 + M_S02_0770 + M_S02_0780 + M_S02_0790 + M_S02_0800 + M_S02_0810

	gen special_deposits =  M_S02_0720 + M_S02_0820 + M_S02_0740 + M_S02_0750 + M_S02_0760 + M_S02_0770 + M_S02_0780 + M_S02_0790 + M_S02_0800 + M_S02_0810

	gen ordinary = M_S02_0720 + M_S02_0820

	gen special_ag =  M_S02_0710

	gen checking_account = M_S02_0660

	gen total_credit 	= M_S02_0060 + M_S04_0700 + M_S04_0340 + M_S04_0610
	lab var total_credit 				"Total credit granted by the bank"
	gen total_credit_hh = 0
	replace total_credit_hh = total_credit if contrepartie =="Particuliers"
	gen total_credit_corporate = 0
	replace total_credit_corporate = total_credit if contrepartie =="Societes non financieres"

	rename M_S02_0630 financial_debt
	lab var financial_debt "Emprunts aupres de la clinetele financiere"

	label var special_deposits "Total Special Regime Saving (deposits and term-deposits) Accounts"

	rename M_S02_0720 livret_regular
	label var livret_regular "Regular livrets"

	rename M_S02_0740 livret_A
	label var livret_A "-- Livrets A"

	rename M_S02_0750 livret_bleu
	label var livret_bleu "-- Livrets bleus"

	rename M_S02_0760 livret_jeune
	label var livret_jeune "-- Livrets jeunes"

	gen livret_spe = livret_A + livret_bleu + livret_jeune
	label var livret_spe "Special livrets (A,bleus,jeunes)"

	rename M_S02_0770 lep
	label var lep "LEP"

	rename M_S02_0780 ldd
	label var ldd "LDD"

	rename M_S02_0790 cel
	label var cel "CEL"

	rename M_S02_0800 pel
	label var pel "PEL"

	rename M_S02_0810 pep
	label var pep "PEP"

	rename M_S02_0820 other_saving
	label var other_saving  "Other special regime saving accounts"

	gen deposits_centralisable = livret_A + livret_bleu + lep

	gen deposits_complement = regulated_rate_deposits - deposits_centralisable

	drop activit*
	rename code_contrepartie client

	drop if year==2017

	gen counterpart = "."
	replace  counterpart = "SocialSecurityAdmin"  if contrepartie =="Administrations publiques hors administrations centrales"
	replace  counterpart = "Entrepreneurs" if contrepartie =="Entrepreneurs individuels"
	replace  counterpart =  "NonProfit" if contrepartie =="Institutions sans but lucratif au service des menages"
	replace  counterpart = "Households" if contrepartie =="Particuliers"
	replace  counterpart = "NonFinancialCompanies"  if contrepartie =="Societes non financieres"
	replace  counterpart = "InsurancePensionfunds" if contrepartie =="Societes d assurance et fonds de pension"

	save $raw\deposit_surfi_clean2, replace

	use $raw\deposit_surfi_clean2, replace

	sort cib time contre*
	gen quarter =1 if month == 1 | month ==2| month ==3
	replace quarter =2 if month == 6  | month ==4 | month ==5
	replace quarter =3 if month == 9  | month ==7 | month ==8
	replace quarter =4 if month == 12 |month ==11 |month ==10

	gen dq = yq(y,quarter)

	format dq %tq

	collapse (mean) total* financial_debt deposits_complement ordinary deposits_centralisable cel pel other livret_A livret_bleu lep ldd checking regulated_rate_deposits special_ag special_deposits, by(contrepartie cib dq)

	collapse (sum)total* financial_debt ordinary deposits_complement deposits_centralisable cel pel other livret_A livret_bleu lep ldd checking regulated_rate_deposits special_ag special_deposits, by(cib dq)

	save $raw\liab_deposits_resid_dq_2.dta , replace

use "$bdf\m_cliennr_france_final.dta", clear
save $raw\client_nr.dta, replace

use $raw\client_nr.dta, replace

	gen date=string(date_arrete,"%02.0f")
	gen year = substr(date,1,4)
	gen month = substr(date,5,2)
	destring year,replace
	destring month,replace
	drop date

	gen time = ym(y,m)
	format time %tm

	local varlist "S02_07* S02_08* S02_04* S02_06* S02_0300 S02_0060 S04_0700 S04_0340 S04_0610"
		foreach i of var `varlist' {
		replace `i'= 0 if `i' ==.
		}

		local varlist "S*"
		foreach i of var `varlist' {
		gen M_`i' = `i' / 1000
		}

	gen M_S02_0630_sum = M_S02_0630_inf1 + M_S02_0630_1a2 + M_S02_0630_sup2
	replace M_S02_0630 = M_S02_0630_sum if M_S02_0630 == 0 & (M_S02_0630_sum !=0)

	gen regulated_rate_deposits =  M_S02_0740 + M_S02_0750 + M_S02_0760 + M_S02_0770 + M_S02_0780 + M_S02_0790 + M_S02_0800 + M_S02_0810

	gen special_deposits =  M_S02_0720 + M_S02_0820 + M_S02_0740 + M_S02_0750 + M_S02_0760 + M_S02_0770 + M_S02_0780 + M_S02_0790 + M_S02_0800 + M_S02_0810

	gen ordinary = M_S02_0720 + M_S02_0820

	gen special_ag =  M_S02_0710

	gen checking_account = M_S02_0660

	gen total_credit_nr 	= M_S02_0060 + M_S04_0700 + M_S04_0340 + M_S04_0610
	lab var total_credit_nr 				"Total credit granted by the bank"
	gen total_credit_hh_nr = 0
	replace total_credit_hh_nr = total_credit_nr if contrepartie =="Particuliers"
	gen total_credit_corporate_nr = 0
	replace total_credit_corporate_nr = total_credit_nr if contrepartie =="Societes non financieres"

	rename M_S02_0630 financial_debt
	lab var financial_debt "Emprunts aupres de la clinetele financiere"

	label var special_deposits "Total Special Regime Saving (deposits and term-deposits) Accounts"

	rename M_S02_0720 livret_regular
	label var livret_regular "Regular livrets"

	rename M_S02_0740 livret_A
	label var livret_A "-- Livrets A"

	rename M_S02_0750 livret_bleu
	label var livret_bleu "-- Livrets bleus"

	rename M_S02_0760 livret_jeune
	label var livret_jeune "-- Livrets jeunes"

	gen livret_spe = livret_A + livret_bleu + livret_jeune
	label var livret_spe "Special livrets (A,bleus,jeunes)"

	rename M_S02_0770 lep
	label var lep "LEP"

	rename M_S02_0780 ldd
	label var ldd "LDD"

	rename M_S02_0790 cel
	label var cel "CEL"

	rename M_S02_0800 pel
	label var pel "PEL"

	rename M_S02_0810 pep
	label var pep "PEP"

	rename M_S02_0820 other_saving
	label var other_saving  "Other special regime saving accounts"

	gen deposits_centralisable = livret_A + livret_bleu + lep

	gen deposits_complement = regulated_rate_deposits - deposits_centralisable

	drop activit*
	rename code_contrepartie client

	drop if year==2017

	save $raw\deposit_surfi_non_resi_clean2, replace

	use $raw\deposit_surfi_non_resi_clean2, replace

	gen quarter =1 if month == 1 | month ==2| month ==3
	replace quarter =2 if month == 6  | month ==4 | month ==5
	replace quarter =3 if month == 9  | month ==7 | month ==8
	replace quarter =4 if month == 12 |month ==11 |month ==10

	gen dq = yq(y,quarter)

	format dq %tq

	collapse (mean) total* financial_debt deposits_complement ordinary deposits_centralisable livret_A livret_bleu lep ldd cel pel other checking regulated_rate_deposits special_ag special_deposits, by(contrepartie cib dq)

	collapse (sum) total* financial_debt ordinary deposits_complement deposits_centralisable livret_A livret_bleu lep ldd cel pel other checking regulated_rate_deposits special_ag special_deposits, by(cib dq)

	rename checking_account 		checking_account_nr
	rename regulated_rate_deposits 	regulated_rate_deposits_nr
	rename special_deposits 		special_deposits_nr

	rename special_ag 				special_ag_nr
	rename livret_A 				livret_A_nr
	rename livret_bleu 				livret_bleu_nr
	rename lep						lep_nr
	rename ldd						ldd_nr
	rename cel 						cel_nr
	rename pel 						pel_nr
	rename other_saving 			other_saving_nr
	rename deposits_centralisable 	deposits_centralisable_nr
	rename deposits_complement		deposits_complement_nr
	rename ordinary 				ordinary_nr

	rename financial_debt 			financial_debt_nr

	save $raw\liab_deposits_non_resid_dq_2.dta , replace

	use  $raw\liab_deposits_non_resid_dq_2.dta , replace

	merge 1:1 cib dq using $raw\liab_deposits_resid_dq_2.dta

	drop _m

	foreach i in total_credit total_credit_nr  total_credit_hh total_credit_hh_nr financial_debt financial_debt_nr ordinary_nr deposits_centralisable_nr ordinary deposits_centralisable deposits_complement cel cel_nr pel pel_nr other_saving other_saving_nr  livret_A livret_A_nr livret_bleu livret_bleu_nr lep_nr lep ldd ldd_nr checking_account checking_account_nr special_ag special_ag_nr special_deposits special_deposits_nr regulated_rate_deposits regulated_rate_deposits_nr {
		replace `i' = 0 if `i' ==.
	}

	replace checking_account = checking_account + checking_account_nr

	replace special_deposits = special_deposits + special_deposits_nr
	replace regulated_rate_deposits = regulated_rate_deposits + regulated_rate_deposits_nr
	replace livret_A = livret_A + livret_A_nr
	replace livret_bleu = livret_bleu + livret_bleu_nr
	replace lep = lep + lep_nr
	replace ldd = ldd + ldd_nr
	replace cel = cel + cel_nr
	replace pel = pel + pel_nr
	replace other_saving = other_saving + other_saving_nr

	replace deposits_centralisable = deposits_centralisable + deposits_centralisable_nr
	replace deposits_complement = deposits_complement + deposits_complement_nr
	replace ordinary = ordinary + ordinary_nr

	replace financial_debt = financial_debt + financial_debt_nr

	replace total_credit 			= total_credit + total_credit_nr
	replace total_credit_corporate  = total_credit_corporate + total_credit_corporate_nr
	replace total_credit_hh 		= total_credit_hh + total_credit_hh_nr

	gen HH_credit = total_credit_hh / total_credit

	gen year = yofd(dofq(dq))

	keep cib dq year HH* total_credit total_credit_corporate total_credit_hh financial_debt ordinary deposits_complement* deposits_centralisable livret_A livret_bleu lep ldd cel pel other_saving checking_account regulated_rate_deposits special_deposits

	drop if year >= 2016

	save $raw\DR_surfi2_v2.dta , replace

	use $raw\DR_surfi2_v2.dta , replace

	merge m:1 cib year using $raw\gea_y.dta

	drop if _m==2
	drop _m
	sort new_gea cib dq
	save $raw\DR_surfi_gea2_v2.dta , replace

	use $raw\DR_surfi_gea2_v2.dta , replace

		tostring cib, gen(cib_s)
		gen caisse_ca = substr(cib_s,5,1) if gea == 27
		destring caisse_ca, gen(caisse_cag)
		drop caisse_ca
		gen caisse_ca =(caisse_cag==6)
		replace caisse_ca = 0 if cib==30006

		drop caisse_cag
		lab var caisse_ca "Caisse Mutualiste du Crédit Agricole"

		gen casa = 0
		replace casa = regulated_rate_deposits if cib == 30006
		replace caisse_ca = 1 if cib == 30006
		bys caisse_ca dq : egen casa_reg = max(casa)
		drop casa

		gen casa = 0
		replace casa = special_deposits if cib == 30006
		bys caisse_ca dq : egen casa_spec = max(casa)
		drop casa

		gen casa = 0
		replace casa = deposits_centralisable if cib == 30006
		bys caisse_ca dq : egen casa_cent = max(casa)
		drop casa

		gen casa = 0
		replace casa = deposits_complement if cib == 30006
		bys caisse_ca dq : egen casa_comp = max(casa)
		drop casa

		gen casa = 0
		replace casa = ordinary if cib == 30006
		bys caisse_ca dq: egen casa_ordinary = max(casa)
		drop casa

		replace caisse_ca = 0 if cib == 30006

		gen casa = 0
		replace casa = financial_debt if cib == 39996
		replace caisse_ca = 1 if cib == 39996
		bys caisse_ca dq : egen casa_fin_debt = max(casa)
		drop casa
		replace caisse_ca = 0 if cib == 39996

		bys dq  : egen tot_check = sum(checking) if caisse_ca == 1
		bys cib dq : gen pdm_check = checking / tot_check
		bys dq : egen test = sum(pdm_check)
		drop test
		sort cib dq

		replace regulated_rate_deposits = casa_reg * pdm_check if caisse_ca == 1
		replace special_deposits = casa_spec * pdm_check if caisse_ca == 1

		replace deposits_centralisable  	= casa_cent * pdm_check if caisse_ca == 1
		replace deposits_complement 		= casa_comp * pdm_check if caisse_ca == 1
		replace ordinary					= casa_ordinary * pdm_check if caisse_ca == 1

		replace financial_debt	 			= casa_fin_debt * pdm_check if caisse_ca == 1

		drop casa*

		drop if cib == 30006
		drop if gea == -1

	drop if dq == tq(2010q2)

	save $raw\DR_surfi_gea_DR2_v2.dta , replace

	save $raw\DR_surfi_gea_DR_b3.dta , replace

	use $raw\DR_surfi_gea_DR_b3.dta , replace

		bys gea dq : egen gea_reg = sum(regulated)
		bys cib dq : egen cib_reg = sum(reg)
		gen pdm_cib_reg = cib_reg /gea_reg

		bys gea dq : egen test =sum(pdm_cib)
		drop test

		cap drop mutualist mutualist_poste main_retail

		gen mutualist = 0
		replace mutualist = 1 if gea== 1163 | gea == 29 | gea== 27

		gen mutualist_poste = 0
		replace mutualist_poste = 1 if gea== 1163 | gea == 29 | gea== 27 | gea == 788

		gen main_retail =0
		replace main_retail =1 if  gea == 30| gea== 768| gea== 160 | gea== 1163 | gea == 29 | gea== 27 | gea == 788

		cap drop outlier
		gen outlier = (pdm_cib_reg >0.33 & pdm_cib_reg !=. & mutualist == 1)

		sort gea dq cib

			gen caisse_ep = substr(cib_s,5,1) if gea == 1163
			destring caisse_ep, gen(caisse_epar)
			drop caisse_ep
			gen caisse_ep =(caisse_epar==5)
			drop caisse_epar

	sort cib dq
	bys dq : egen tot_reg_cm = sum(reg) if inlist(cib, 15959, 15749, 15459, 15899, 15489, 15889, 15999, 15629, 15519, 15969, 15589)

	drop  if cib == 11808

	save $raw\DR_surfi_gea_DR_bis3.dta , replace

	use $raw\DR_surfi_gea_DR_bis3.dta , replace
	merge m:1 cib dq year using $raw\liabilities_trim
	drop if _m == 1
	drop _m

	bys dq : egen sum_dep_ca = sum(total_deposits) if caisse_ca == 1

	replace total_deposits 	  = total_deposits + regulated_rate_deposits if caisse_ca == 1
	replace total_liabilities = total_liabilities + regulated_rate_deposits if caisse_ca == 1

	gen 	deposits_net = deposits_centralisable * 0.2 	if (caisse_ep ==1 | gea == 29) & year == 2010
	replace deposits_net = deposits_centralisable * 0.24 	if (caisse_ep ==1 | gea == 29) & year == 2011
	replace deposits_net = deposits_centralisable * 0.3 	if (caisse_ep ==1 | gea == 29) & year == 2012
	replace deposits_net = deposits_centralisable * 0.36 	if (caisse_ep ==1 | gea == 29) & year == 2013
	replace deposits_net = deposits_centralisable * 0.38 	if (caisse_ep ==1 | gea == 29) & year == 2014
	replace deposits_net = deposits_centralisable * 0.39 	if (caisse_ep ==1 | gea == 29) & year == 2015

	replace deposits_net = 0 	if (gea == 788)

	replace deposits_net = deposits_centralisable * 0.76 	if  deposits_net ==. & year == 2010
	replace deposits_net = deposits_centralisable * 0.66 	if  deposits_net ==. & year == 2011
	replace deposits_net = deposits_centralisable * 0.6 	if  deposits_net ==. & year == 2012
	replace deposits_net = deposits_centralisable * 0.63 	if  deposits_net ==. & year == 2013
	replace deposits_net = deposits_centralisable * 0.6 	if  deposits_net ==. & year == 2014
	replace deposits_net = deposits_centralisable * 0.6		if  deposits_net ==. & year == 2015

	save $raw\DR_surfi_gea_DR_c3.dta , replace

	use $raw\DR_surfi_gea_DR_c3.dta , replace

		local varlist "regulated_rate_deposits deposits_net  deposits_complement financial_debt"
		foreach i of var `varlist' {
		replace `i'= 0 if `i' ==. & total_deposits != 0
		}

	gen tot_liab_new = total_liabilities -  regulated_rate_deposits + (deposits_net + deposits_complement)

	gen DRnew = (deposits_net + deposits_complement) / tot_liab_new

	replace ordinary = 0 if ordinary ==.
	gen DRnew_spec = (deposits_net + deposits_complement + ordinary) / tot_liab_new

	gen DRtotal = (total_deposits - regul + deposits_net + deposits_complement) / tot_liab_new

	gen deposit_transferred = regulated_rate_deposits - deposits_net
	gen DRtransfer = deposit_transferred / tot_liab_new

		tsset cib dq

		gen DRnew_lag  = L1.DRnew
		gen DRnew_lag2 = L2.DRnew

		gen DRnew_spec_lag  = L1.DRnew_spec
		gen DRnew_spec_lag2 = L2.DRnew_spec

		gen DRtotal_lag = L1.DRtotal
		gen DRtotal_lag2 = L2.DRtotal

		gen DRtransfer_lag  = L1.DRtransfer
		gen DRtransfer_lag2 = L2.DRtransfer

		gen HH_credit_lag = L1.HH_credit

		drop if dq==tq(2010q2)

		drop if dq==tq(2010q3)

	save $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace
	keep cib dq ln_asset_lag equity_ratio_lag
	save $raw\equity, replace

	use $raw\DR_surfi_gea_DR_final_adjusted_V2_trim3.dta , replace
	keep cib dq HH_credit total_credit_hh total_credit*
	replace HH_credit = 0 if HH_c ==.

	save $raw\HH, replace
