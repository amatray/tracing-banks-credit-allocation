tempfile scrnaf nfirm4 bk_siren bk_naf4

        use "$raw/scr_naf_2009.dta", replace
        forvalues base = 2010/2015 {
                append using "$raw/scr_naf_`base'.dta"
        }
        duplicates drop
        save "`scrnaf'", replace

        use "`scrnaf'", replace

		sort year siren naf4
		collapse (last) naf* , by(year siren)

        gen i = 1
        bys naf4 year : egen N_firm_naf4 = sum(i)

        collapse (last) N_firm_naf4 , by(y naf4)
        rename N_firm N_siren_4D
        destring naf4, replace
        save "`nfirm4'", replace

        import excel "$data/excel/siren_NAF.xlsx", sheet("Feuil1") firstrow clear

        drop naf_insee* naf_bdf
        rename naf_bdfs naf
        gen naf4 = substr(naf, 1, 4)

        gen i = 1
        bys naf4 y : egen N_bankruptcy_4D = sum(i)
        drop if naf == ""
        drop i
        save "`bk_siren'", replace

        use "`bk_siren'", replace
        collapse (last) N_bankruptcy_4D , by(naf4 y)
        destring naf4, replace
        save "`bk_naf4'", replace

        use "`nfirm4'", replace

        merge 1:1 naf4 y using "`bk_naf4'"
        drop if _m == 2
        replace N_bankruptcy = 0 if _m == 1
        drop _m

        gen bankruptcy_rate = N_bankruptcy_4D / N_siren_4D

        winsor bankruptcy_rate, gen(bankruptcy_ratew) p(0.01)

        replace y = y + 1

        xtile bankruptcy_t = bankruptcy_ratew, nq(3)
        xtile bankruptcy_q = bankruptcy_ratew, nq(4)

        gen high_bankruptcy_risk   = (bankruptcy_q  > 2)
        gen vhigh_bankruptcy_risk  = (bankruptcy_t == 3)
        gen vvhigh_bankruptcy_risk = (bankruptcy_q == 4)

        save "$raw/bankruptcy_rate_naf4.dta", replace

        use "`scrnaf'", replace
        rename siren firm

        collapse (last) naf4 , by(firm year)
        save "$raw/siren_CN.dta", replace

        collapse (last) naf4, by(firm)
        save "$raw/naf4.dta", replace
