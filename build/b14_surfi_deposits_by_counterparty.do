tempfile bycp total_r hh_r hh_nr snf_hh_r pdm_ca

foreach res in r nr {

        if "`res'" == "r" {
                local infile "$raw/deposit_surfi_clean2"
        }
        else {
                local infile "$raw/deposit_surfi_non_resi_clean2"
        }

        use "`infile'", replace

        gen     quarter = 1 if month == 1  | month ==  2 | month ==  3
        replace quarter = 2 if month == 6  | month ==  4 | month ==  5
        replace quarter = 3 if month == 9  | month ==  7 | month ==  8
        replace quarter = 4 if month == 12 | month == 11 | month == 10

        gen dq = yq(y, quarter)
        format dq %tq

        gen tot_deposits = M_S02_0660 + special_deposits + M_S02_0870 ///
                         + M_S02_0880 + M_S02_0700

        collapse (sum) tot_deposits regulated_rate_deposits deposits_centralisable, ///
                 by(contrepartie cib dq)

        save "`bycp'", replace

        use "`bycp'", replace
        collapse (sum) tot_deposits regulated_rate_deposits deposits_centralisable, ///
                 by(cib dq)
        if "`res'" == "r" {
                save "`total_r'", replace
        }
        else {
                append using "`total_r'"
                collapse (sum) tot_deposits regulated_rate_deposits deposits_centralisable, ///
                         by(cib dq)
                save "$raw/deposit_total.dta", replace
        }

        use "`bycp'", replace
        keep if contrepartie == "Particuliers"
        if "`res'" == "nr" {
                drop contrepartie
        }
        rename tot_deposits            tot_deposits_households
        rename regulated_rate_deposits regulated_deposits_households
        rename deposits_centralisable  deposits_centralisable_h
        save "`hh_`res''", replace

        use "`bycp'", replace
        keep if contrepartie == "Societes non financieres" | ///
                contrepartie == "Entrepreneurs individuels"
        collapse (sum) tot_deposits regulated_rate_deposits deposits_centralisable, ///
                 by(cib dq)
        rename tot_deposits            tot_deposits_snf
        rename regulated_rate_deposits regulated_deposits_snf
        rename deposits_centralisable  deposits_centralisable_snf

        merge 1:1 cib dq using "`hh_`res''"
        drop _m

        local varlist "tot_deposits_households regulated_deposits_househ tot_deposits_snf regulated_deposits_snf deposits_centralisable_*"
        foreach i of var `varlist' {
                replace `i' = 0 if `i' == .
        }

        if "`res'" == "r" {
                save "`snf_hh_r'", replace
        }
}

append using "`snf_hh_r'"

collapse (sum) tot_deposits_households regulated_deposits_househ ///
               deposits_centralisable_h tot_deposits_snf ///
               regulated_deposits_snf deposits_centralisable_snf, by(cib dq)

rename tot_deposits_households      dep_household
rename tot_deposits_snf             dep_snf
rename regulated_deposits_househ    reg_household
rename regulated_deposits_snf       reg_snf
rename deposits_centralisable_h     centralisable_h
rename deposits_centralisable_snf   centralisable_snf

save "$raw/deposit_surfi_snf_household.dta", replace

        use "$raw/DR_surfi_gea_DR2_v2.dta", replace
        keep cib pdm_check dq
        drop if pdm_check == .
        save "`pdm_ca'", replace

        use "$raw/deposit_surfi_snf_household.dta", replace
        merge 1:1 cib dq using "`pdm_ca'"
        drop _m

        gen year = yofd(dofq(dq))
        merge m:1 cib year using "$raw/gea_y.dta"
        drop if _m == 2
        drop _m

        bank_network_flag caisse_ca 27 6
        replace caisse_ca = 0 if cib == 30006
        lab var caisse_ca "Caisse Mutualiste du Credit Agricole"

        local varlist "reg* centralisable*"
        foreach i of var `varlist' {
                gen casa = 0
                replace casa = `i' if cib == 30006
                replace caisse_ca = 1 if cib == 30006
                bys caisse_ca dq : egen casa_`i' = max(casa)
                replace casa_`i' = 0 if casa_`i' == .
                drop casa
        }

        local varlist "reg* centralisable*"
        foreach i of var `varlist' {
                replace `i' = casa_`i' * pdm_check if caisse_ca == 1
        }
        drop casa*

        drop if cib == 30006
        drop if gea == -1
        drop if dq  == tq(2010q2)

        drop if cib == 11808

        save "$raw/DR_surfi_gea_household_snf.dta", replace

        use "$raw/deposit_total.dta", replace

        gen year = yofd(dofq(dq))
        merge m:1 cib year using "$raw/gea_y.dta"
        drop if _m == 2
        drop _m

        bank_network_flag caisse_ep 1163 5

        apply_centralisation, source(deposits_centralisable) ///
                              target(deposits_net) firstyear(2010)

        gen total_deposit_adj = tot_deposits - deposits_centralisable + deposits_net

        keep cib dq total_deposit*
        save "$raw/DR_surfi_tot_deposit_adj.dta", replace

        use "$raw/DR_surfi_gea_household_snf.dta", replace

        merge m:1 cib dq using "$raw/DR_surfi_tot_deposit_adj.dta"
        keep if _m == 3
        drop _m

        bank_network_flag caisse_ep 1163 5

        apply_centralisation, source(centralisable_snf) ///
                              target(deposits_net_snf) firstyear(2010)
        apply_centralisation, source(centralisable_h) ///
                              target(deposits_net_h)   firstyear(2010)

        gen household_deposit = dep_household - centralisable_h   + deposits_net_h
        gen snf_deposit       = dep_snf       - centralisable_s   + deposits_net_s

        gen household_over_total_deposits = household_deposit / total_deposit_adj
        gen snf_over_total_deposits       = snf_deposit       / total_deposit_adj

        save "$raw/DR_surfi_gea_household_snf_b.dta", replace
