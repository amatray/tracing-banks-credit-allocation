cd $scr

cd $raw
import excel "$data\excel\GEA_trimestriel décembre 2015.xlsx", sheet("Feuil1") firstrow clear

save gea_original.dta,replace

use gea_original.dta,replace

keep cib trimestre gea

destring cib, gen (new_cib)
drop cib
rename new_cib cib

gen year=year(trimestre)
gen month=month(trimestre)

keep if(month==12)
keep cib gea year
sort gea cib year

rename year m_year

drop if gea==.
gsort m_year cib -gea
duplicates drop m_year cib, force

save cib_gea_2016.dta,replace

forval base = 2008(1)2016 {

cd $scr

use CN_`base'.dta, replace

if inrange(`base', 2009, 2015) {
        preserve
                keep siren Code_NAF
                rename Code_NAF naf
                gen naf5 = substr(naf, 1, 5)
                gen naf4 = substr(naf, 1, 4)
                gen naf3 = substr(naf, 1, 3)
                gen naf2 = substr(naf, 1, 2)
                drop if naf == ""
                gen year = `base'
                duplicates drop
                compress
                save "$raw/scr_naf_`base'.dta", replace
        restore
}

cap rename date_d_arrete Date_d_arrete
cap rename mobilises Mobilises
cap rename mobilisables Mobilisables
cap rename Code_Type_d_Entreprise Code_Taille_LME
cap tostring Code_Taille_LME, replace

cap gen Code_Categorie_juridique = .
cap gen Code_Section_NAF_BdF = .
cap gen comgui = 0

gen y = int(Date_d_arrete / 100)

gen m = mod(Date_d_arrete, 100)
gen my = ym(y,m)

rename Date_d_arrete date
rename Code_CIB cib
rename Code_Guichet branch_id
rename Code_Categorie_juridique catjur
rename Code_Region region
rename Code_Pays country
rename Code_NAF_BdF NAF
rename Code_Section_NAF_BdF section
rename Indicateur_Groupe group_dummy
rename Code_Taille_LME size_lme
rename Code_Departement county
rename Code_Postal zip_code
rename comgui zip_code_branch
rename Code_Cote_BdF cotebdf

rename Mobilises mobilises
rename Mobilisables mobilisables
rename ac guarantee

rename tct tot_ct
rename tmlt tot_mlt
rename trhb tot_hb
rename trcb tot_cb

gen cibbranch=string(cib,"%02.0f")+string(branch_id,"%02.0f")
replace cotebdf = substr(cotebdf,2,4)
gen sizebdf = substr(cotebdf,1,2)

gen independent = 0
replace independent =1 if group_dummy =="0"

gen exposure  = mobilises + mobilisables
gen total_exposure  = mobilises + mobilisables + guarantee
gen loan = co + cc + ca + te + ta + oc + od

drop if total_exposure < 25

gen NAF3= substr(NAF,1,3)
destring NAF3, gen(naf3)

gen NAF2 = substr(string(naf3),1, 2)

drop if NAF2=="64"|NAF2=="65"|NAF2=="66"|NAF2=="84"|NAF2=="99"

gen lme = substr(size_lme, 1,1)
destring lme, replace

drop if cib==.
drop if branch==.
drop if missing(zip_code_branch)

cap drop if county =="2A"
cap drop if county =="2B"
destring county, replace

drop if county > 96
rename county department

destring zip_code, replace
rename department county_code

drop if country != "FR"

 drop if lme ==7 | lme == 0

 keep siren cibbranch cib branch_id date my y lme independent naf3 cotebdf region county_code zip_code zip_code_branch catjur exposure total_exposure loan tot* guarantee af ca cc co ie it bi bm ta te oc od
 order siren cibbranch cib branch_id date my y lme independent naf3 cotebdf region county_code zip_code zip_code_branch catjur exposure total_exposure loan tot* guarantee af ca cc co ie it bi bm ta te oc od

drop if catjur>=2110 & catjur<=2900

drop if catjur>=3110 & catjur<=3290

drop if catjur>=4110 & catjur <= 4160

drop if catjur>=5191 & catjur<=5196

drop if catjur==5370|catjur==5470|catjur==5570|catjur==5670|catjur==5770|catjur==6511

drop if catjur==6100

drop if catjur == 6411

drop if catjur >= 6511 & catjur <= 6599 & catjur != 6598

drop if catjur>=7111 & catjur<.

cd $raw

gen m_year = y
replace m_year = 2015 if m_year == 2016 | m_year == 2017
replace m_year = 2005 if m_year <= 2005

merge m:1 cib m_year using cib_gea_2016
keep if _m == 3
drop _m m_year

cd $raw
save `base'_qclean_XXXX.dta, replace

}
