capture program drop bank_network_flag
program define bank_network_flag
        args newvar geacode digitval

        capture confirm variable cib_s
        if _rc {
                gen cib_s = string(cib)
        }

        tempvar dig dign
        gen `dig'  = substr(cib_s, 5, 1) if gea == `geacode'
        destring `dig', gen(`dign')

        capture drop `newvar'
        gen `newvar' = (`dign' == `digitval')
end

capture program drop apply_centralisation
program define apply_centralisation
        syntax , SOURce(varname) TARget(name) [ FIRSTyear(int 2010) ]

        local hist2009 0.2
        local hist2010 0.2
        local hist2011 0.24
        local hist2012 0.3
        local hist2013 0.36
        local hist2014 0.38
        local hist2015 0.39

        local nouv2009 0.76
        local nouv2010 0.76
        local nouv2011 0.66
        local nouv2012 0.6
        local nouv2013 0.63
        local nouv2014 0.6
        local nouv2015 0.6

        gen `target' = `source' * `hist`firstyear'' ///
                if (caisse_ep == 1 | gea == 29) & year == `firstyear'

        local y1 = `firstyear' + 1
        forvalues yy = `y1'/2015 {
                replace `target' = `source' * `hist`yy'' ///
                        if (caisse_ep == 1 | gea == 29) & year == `yy'
        }

        replace `target' = 0 if (gea == 788)

        forvalues yy = `firstyear'/2015 {
                replace `target' = `source' * `nouv`yy'' ///
                        if `target' == . & year == `yy'
        }
end
