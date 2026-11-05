use "$lec\TITRE_PTF_EC.dta", clear
count

duplicates drop _all, force
count

drop Famille Sous_famille Population Source Tableau Variante_Tableau
drop Code_categorie_de_population Categorie_de_population Debut_de_periode
destring valeur_du_fait, replace

tostring Date_d_arrete, generate(datelb)
gen year  = substr(datelb,1,4)
gen month = substr(datelb,5,2)
gen day   = substr(datelb,7,2)
destring year month day, replace
gen madate = mdy(month, day, year)
format madate %d
drop datelb year month day

rename Activite                 activite
rename Code_CIB                 cib
rename Code_Element_SURFI       code_surfi
rename Date_d_arrete            date_arrete
rename Frequence                frequence
rename Unite                    unite
rename Titre                    titre
rename Residence                residence
rename Emetteur                 emetteur
rename Monnaie                  monnaie
rename Taxonomie                taxonomie
rename Raison_sociale           raison_sociale
rename Code_Description_du_fait code_description_du_fait
rename Description_du_fait      description_du_fait
rename Element_SURFI            element_surfi
rename Duree_initiale           duree_initiale
sort  cib siren code_description_du_fait madate
order cib siren madate date_arrete code_description_du_fait code_surfi monnaie ///
      activite emetteur residence duree_initiale valeur_du_fait taxonomie frequence unite decimals

drop if unite == "iso4217:XPF"
drop if unite == ":pure"
count

duplicates drop cib siren madate code_surfi monnaie emetteur residence duree_initiale , force
count
save "$raw\TITRE_PTF_EC_red.dta", replace

use "$raw\TITRE_PTF_EC_red.dta", clear

drop taxonomie frequence unite decimals titre description_du_fait element_surfi ///
     raison_sociale code_description_du_fait date_arrete

gen emet2 = ""
replace emet2 = "SE2" if substr(emetteur,1,3) == "SE2"
replace emet2 = "SE3" if substr(emetteur,1,3) == "SE3"
replace emet2 = "SE4" if substr(emetteur,1,3) == "SE4"
replace emet2 = "SE5" if substr(emetteur,1,3) == "SE5"
replace emet2 = "SE6" if substr(emetteur,1,3) == "SE6"
replace emet2 = "SE7" if substr(emetteur,1,3) == "SE7"
replace emet2 = "SE8" if substr(emetteur,1,3) == "SE8"
replace emet2 = "SE9" if substr(emetteur,1,3) == "SE9"
replace emet2 = "SEA" if substr(emetteur,1,3) == "SEA"
replace emet2 = "SEB" if substr(emetteur,1,3) == "SEB"
replace emet2 = "SEC" if substr(emetteur,1,3) == "SEC"
replace emet2 = "SEE" if substr(emetteur,1,3) == "SEE"
replace emet2 = "SEF" if substr(emetteur,1,3) == "SEF"
replace emet2 = "SEG" if substr(emetteur,1,3) == "SEG"
drop emetteur

gen duree2 = ""
replace duree2 = "SD8" if substr(duree_initiale,1,3) == "SD8"
replace duree2 = "SD9" if substr(duree_initiale,1,3) == "SD9"
drop duree_initiale

gen resid2 = ""
replace resid2 = "SF1" if substr(residence,1,3) == "SF1"
replace resid2 = "SF2" if substr(residence,1,3) == "SF2"
replace resid2 = "SF3" if substr(residence,1,3) == "SF3"
replace resid2 = "SF4" if substr(residence,1,3) == "SF4"
drop residence

reshape wide valeur_du_fait, i(cib siren madate monnaie activite resid2 emet2 duree2) j(code_surfi) string

rename valeur_du_faitS* S*
rename (emet2 duree2 resid2) (emetteur duree_initiale residence)
sort  cib siren madate monnaie activite residence emetteur
order cib siren madate monnaie activite residence emetteur

label variable residence "résidence"
replace residence = "SF1 : résidents"               if residence == "SF1"
replace residence = "SF2 : non-résidents"           if residence == "SF2"
replace residence = "SF3 : non-residents EMUM"      if residence == "SF3"
replace residence = "SF4 : non-residents non-EMUM"  if residence == "SF4"

label variable duree_initiale "durée_initiale"
replace duree_initiale = "SD8 : Durée initiale inférieure ou égale à 5 ans" if duree_initiale == "SD8"
replace duree_initiale = "SD9 : Durée initiale supérieure à 5 ans"          if duree_initiale == "SD9"

label variable emetteur "emetteur"
replace emetteur = "SE2 : Etablissements de crédit"                                        if emetteur == "SE2"
replace emetteur = "SE3 : OPCVM monétaires"                                                if emetteur == "SE3"
replace emetteur = "SE4 : Clientèle"                                                       if emetteur == "SE4"
replace emetteur = "SE5 : Clientèle hors administrations publiques"                        if emetteur == "SE5"
replace emetteur = "SE6 : Clientèle financière hors OPCVM monétaires"                      if emetteur == "SE6"
replace emetteur = "SE7 : Fonds communs de créances, de titrisation, sociétés de titrisation" if emetteur == "SE7"
replace emetteur = "SE8 : Sociétés d'assurance et fonds de pension"                        if emetteur == "SE8"
replace emetteur = "SE9 : Sociétés d'assurance"                                            if emetteur == "SE9"
replace emetteur = "SEA : Sociétés non financières"                                        if emetteur == "SEA"
replace emetteur = "SEB : Administrations publiques"                                       if emetteur == "SEB"
replace emetteur = "SEC : Administrations centrales"                                       if emetteur == "SEC"
replace emetteur = "SEE : Administrations publiques locales"                               if emetteur == "SEE"
replace emetteur = "SEF : Administrations de sécurité sociale"                             if emetteur == "SEF"
replace emetteur = "SEG : Etats fédérés"                                                   if emetteur == "SEG"

save "$raw\TITRE_PTF_EC_FIN.dta", replace

use "$raw\TITRE_PTF_EC_FIN.dta", clear
keep if year(madate) >= 2010 & year(madate) <= 2015
keep if (month(madate) == 3  & day(madate) == 31 | ///
         month(madate) == 6  & day(madate) == 30 | ///
         month(madate) == 9  & day(madate) == 30 | ///
         month(madate) == 12 & day(madate) == 31 )
drop if year(madate) == 2010 & month(madate) == 6 & day(madate) == 30

keep  cib siren madate monnaie activite residence emetteur duree_initiale ///
      S03_0280 S03_0390 S03_0330 S03_0420 S04_0270 S03_0310
rename S03_0280 titres_rev_fixe
rename S03_0390 titres_rev_variable
rename S03_0330 bons_tresor
rename S03_0420 actions_assimiles
rename S04_0270 parts_titres
rename S03_0310 titres_interbanc

drop if cib==10907 & siren==457204071
drop if cib==11899 & siren==355801929
drop if cib==15250 & siren==323601807
drop if cib==15250 & siren==448417766
drop if cib==16275 & siren==383000692
drop if cib==16850 & siren==333871259
drop if cib==17510 & siren==265907741
drop if cib==17679 & siren==652057969
drop if cib==18739 & siren==331521120
drop if cib==18739 & siren==388911877
drop if cib==30051 & siren==421263047
drop if cib==30438 & siren==490100260
drop if cib==30628 & siren==775758485
drop if cib==30748 & siren==334961745
drop if cib==41189 & siren==542031448
drop if cib==41249 & siren==775753486
drop if cib==50140 & siren==267500007
save "$raw\TITRE_PTF_EC_TRIM.dta", replace
count

use "$raw\TITRE_PTF_EC_TRIM.dta", clear
drop if emetteur == ""
gen public = 0
replace public = 1 if substr(emetteur,1,3) == "SEB" | substr(emetteur,1,3) == "SEC" | ///
                      substr(emetteur,1,3) == "SEE" | substr(emetteur,1,3) == "SEF" | ///
                      substr(emetteur,1,3) == "SEG"
drop duree_initiale activite
sort  cib madate monnaie residence emetteur public
order cib madate monnaie residence emetteur public
save "$raw\TITRE_PTF_EC_AGREG.dta", replace

use "$raw\TITRE_PTF_EC_AGREG.dta", clear
collapse (sum) titres_rev_fixe bons_tresor titres_rev_variable actions_assimiles ///
               parts_titres titres_interbanc , by(cib siren madate public)
save "$raw\Surfi_bank_portfolio", replace

use "$raw\TITRE_PTF_EC_AGREG.dta", clear
keep if substr(emetteur,1,3) == "SEA"
rename actions_assimiles actions_assimiles_SNF
collapse (sum) actions_assimiles_SNF, by(cib siren madate)
save "$raw\actions_assimiles_SNF.dta", replace
