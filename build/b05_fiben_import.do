clear
set more off

tempfile bilan_all desc_all
local bilan_files ""
local desc_files  ""

global vlist_flux "A3 A4 CR2 FC FF FI FJ FK FL FM FN FO FP FQ FR FS FT FU FV FW FX FY FZ GA GB GC GD GE GF GH GI GM GN GP GQ GR GS GU HA HB HC HD HE HF HG HH HJ HK HL HM HN HP HQ KF LP MY NC _0J _0K _0Q _5S _5T UF UH UK XQ YU YY YZ ZE"

global vlist_num "AA AC AF AH AJ AL AN AP AR AT AV AX BL BN BP BR BT BV BX BZ CB CH CM CF CD CX DA DI DK DJ DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ EA EB EH FK FL FM FN FO FP FQ FR FS FT FU FV FW FX FY FZ GA GB GC GD GE GH GI GM GP GQ GR GS GT HA HC HE HF HG HJ HK HP HQ KF LP MY NC UF UH UK UY UZ VB VC VC2 VI VI2 VN VP VQ VW VX YP YQ YR YS YU ZE ZF _1A _5S _5T _5U _8C _8D DS DT DM DV DN D9 LS"

forvalues yyyy = 2008/2016 {

        tempfile b`yyyy'

        import delimited using ///
                "$bilans/Bilans_Sociaux_-_Elements_de_Bilan_(Hors_Centrale_de_Bilan)20250520094629_`yyyy'.csv", ///
                delimiters(";") clear stringcols(_all)

        qui do "$do/programs/fiben_rename_balance.do"

        keep siren annee D4 D5 ///
                AA AC AF AH AJ AL AN AP AR AT AV AX ///
                BL BN BP BR BT BV BX BZ CB CH CM ///
                CF CD CX ///
                DA DI DK DJ DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ ///
                EA EB EH ///
                FK FL FM FN FO FP FQ FR FS FT FU FV FW FX FY FZ ///
                GA GB GC GD GE GH GI GM GP GQ GR GS GT ///
                HA HC HE HF HG HJ HK HP HQ ///
                KF LP MY NC ///
                UF UH UK UY UZ ///
                VB VC VC2 VI VI2 VN VP VQ VW VX ///
                YP YQ YR YS YU ///
                ZE ZF ///
                _1A _5S _5T _5U _8C _8D ///
                DS DT DM DV DN ///
                D9 LS

        qui foreach var of varlist $vlist_num {
                capture destring `var', replace force
        }

        compress
        save "`b`yyyy''", replace
        local bilan_files `"`bilan_files' "`b`yyyy''""'
}

forvalues yyyy = 2008/2016 {

        tempfile d`yyyy'

        import delimited using ///
                "$desc/Bilans_Sociaux_-_Descriptifs_20250520094600_`yyyy'.csv", ///
                delimiters(";") clear stringcols(_all)

        qui do "$do/programs/fiben_rename_descriptive.do"

        capture drop famille sousfamille population periodicite source
        capture drop classenafv2 groupenafv2 divisionnaf libelle nes10bdf nes17bdf nes64bdf nes129bdf

        local masterlist "siren annee D4 D5 D20 D30 D32 D33 D36 datecreat depart region catjur etabetr mono_multi_etab"
        local keeplist = ""

        foreach i of local masterlist {
                capture confirm variable `i'
                if !_rc {
                        local keeplist "`keeplist' `i'"
                }
        }

        keep `keeplist'

        compress
        save "`d`yyyy''", replace
        local desc_files `"`desc_files' "`d`yyyy''""'
}

        clear
        append using `bilan_files', force
        compress
        save "`bilan_all'", replace

        clear
        append using `desc_files', force
        compress
        save "`desc_all'", replace

        use "`bilan_all'", clear

        merge m:1 siren D4 using "`desc_all'"
        keep if _m == 3
        drop _m

        sort siren D4

        save "$raw/fiben_total.dta", replace
