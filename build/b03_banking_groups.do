cd $raw
import excel "$data\excel\GEASAABA.xlsx", sheet("Feuil1") firstrow clear
save gea.dta,replace

import excel "$data\excel\GEA DENOMINATION.xlsx", sheet("Feuil1") firstrow clear
merge 1:m ECHEANCE GEA using gea.dta
drop if _m==1
drop _m
save gea_dq.dta,replace

use gea_dq.dta,replace
drop DATEMODIFI
rename ECHEANCE date
rename CIB cib
rename GEA gea
rename DENOMINATION denom

cap drop year
gen year = int(date/100)

sort cib year date
collapse (last) gea denom TB ORG , by(year cib)

gen gea_absorbant = 1163 if gea == 1073 | gea == 28 | gea ==765

gen gea_save = gea
replace gea=1163 if gea_save==1073 ///
				| gea_save==28 ///
				| gea_save==765

rename ORG org

	gen new_gea = gea
	replace new_gea = org if gea==-1 & TB==1

save gea_y.dta,replace
