tempfile f_all f_household f_snf f_ei

foreach cp in all household snf ei {

        use "$raw/cefit_clean_monthly.dta", replace

        if "`cp'" == "all" {
                keep if agent == "TOTAL"
        }
        else if "`cp'" == "household" {
                keep if household == 1
        }
        else if "`cp'" == "snf" {
                keep if snf == 1
        }
        else if "`cp'" == "ei" {
                keep if entrepreuneur == 1
        }

        keep if month == 3 | month == 6 | month == 9 | month == 12

        gen dq = qofd(dofm(time))
        format dq %tq
        sort cibcounty dq

        tsset cibcounty dq

        merge m:1 cib year using "$raw/share_centralisable.dta"
        drop if _m == 2

        bys cib : egen max_sh = max(centralise_to_spec) if year <= 2010
        replace centralise_to_spec = max_sh if centralise_to_spec == .
        drop max_sh

        replace centralise_to_spec = 0 if _m == 1 & centralise_to_spec == .

        drop _m

        gen deposits_centralisable = centralise_to_spec * d_regulated_tot
        gen complement_deposits    = (1 - centralise_to_spec) * d_regulated_tot

        bank_network_flag caisse_ep 1163 5

        apply_centralisation, source(deposits_centralisable) ///
                              target(deposits_net) firstyear(2009)

        replace deposits_net = d_regulated_tot if deposits_net == .

        tsfill, full
        bysort cibcounty : carryforward agent, gen(agent_fill)
        sort cibcounty time

        cap drop _end _seq _spell length
        tsspell, f(L.time == .)
        bys cibcounty _spell : egen length = max(_seq)

        local varlist "deposits* complement* d_* c_* VAR210 VAR256 d_livrets"
        foreach i of var `varlist' {
                replace `i' = 0 if `i' == .
        }

        gen d_all_tot_new = d_all_tot - d_regulated_tot + (deposits_net + complement_deposits)

        gen DR    = d_regulated_tot / d_all_total
        gen DRnew = (deposits_net + complement_deposits) / d_all_tot_new

        xtset cibcounty dq
        gen DRnew_lag = L1.DRnew

        merge m:1 time using "$raw/livreta.dta"
        drop if _m == 2
        drop _m
        drop if gap == .

        gen DRnew_gap = DRnew_lag * gap

        gen loan_`cp'           = ln(c_all)
        gen st_credit_`cp'      = ln(c_st_credit)
        gen st_credit_scr_`cp'  = ln(c_st_credit + c_overdraft + VAR210)
        gen lt_credit_exp_`cp'  = ln(c_lt_credit + c_export_credit)
        gen lt_credit_`cp'      = ln(c_lt_credit)
        gen leasing_`cp'        = ln(c_leasing)
        gen arf_`cp'            = ln(VAR210)
        gen mortgage_`cp'       = ln(c_mort)
        gen overdraft_`cp'      = ln(c_overdraft)

        if "`cp'" == "all" {
                keep cibcounty c_* VAR210 cib county gea dq DRnew_lag DRnew_gap gap ///
                     loan* st_credit* lt_credit* leasing* arf* mortgage* overdraft*
        }
        else if "`cp'" == "household" {
                rename c_all       c_household
                rename c_mortgages c_mort_household
                keep cibcounty c_mort* c_household cib county gea dq DRnew_lag DRnew_gap gap ///
                     loan* st_credit* lt_credit* leasing* arf* mortgage* overdraft*
        }
        else {
                rename c_all c_`cp'
                keep cibcounty c_`cp' cib county gea dq DRnew_lag DRnew_gap gap ///
                     loan* st_credit* lt_credit* leasing* arf* mortgage* overdraft*
        }

        save "`f_`cp''", replace
}

use "`f_all'", replace
merge 1:1 cibcounty dq using "`f_snf'",       nogen
merge 1:1 cibcounty dq using "`f_household'", nogen
merge 1:1 cibcounty dq using "`f_ei'",        nogen

save "$raw/REG_bank_county_cefit_DR_ln0.dta", replace
