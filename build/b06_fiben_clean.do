	cd "$raw"

	use fiben_total, clear

		rename annee year
		destring year, replace

		gen month=D5
		lab var year "Calendar year"
		keep if year>=2008 & year<=2016
		rename month fmonth
		destring fmonth, replace

		gen fyear=year if fmonth >= 6
		replace fyear=year-1 if fmonth < 6
		label var fyear fiscal_year

		drop if D5!="12"
		destring siren, gen(firm)
		sort firm year

		drop if depart == "2A" | depart == "2B"
		destring depart, gen (county) force
		drop if county > 95

	capture drop ancrea

		gen ancr=substr(datecreat,4,4)
		destring ancr, gen(ancrea1)
		drop ancr
		capture drop creat_st

		gen ancr=substr(datecreat,5,4)
		destring ancr, gen(ancrea2)
		replace ancrea1 = ancrea2 if ancrea1 > 2020
		replace ancrea1 = ancrea2 if ancrea1 < ancrea2 & ancrea2 < 2020

		rename ancrea1 ancrea
		drop ancrea2

		lab var ancrea "Creation year"

		gen age = year - ancrea
		gen ln_age = ln(age)
		lab var age "Age in years"
		lab var ln_age "Age"

	tsset firm fyear

	unab varlist: AA-CH DA-CD UF-YP VW VX VQ VI CM
	foreach var in `varlist' {
	  rename `var' `=strlower("`var'")'
	}

	local varlist yq yr firm fyear
	foreach var in `varlist' {
		gen `var'_lag = L1.`var'
		}

	local varlist _5S _5T _5U an  ap  ar  at  av  ax
	foreach var in `varlist' {
		replace `var' = 0 if `var' == .
		}

		gen vaj = fl + fm + fn - (fs + ft + fu + fv + fw)
		gen vajcbr = vaj + hp + hq + yu
		gen chpersr = fy + fz + _5S - _5T + yu

		gen ebecbr = vajcbr + fo - fx - chpersr + fq - gt
		gen enecbr = ebecbr + (fp - uf) - (ga + gb + gc + gd - _5S - uf + _5T) - ((hp*0.87) + (hq*0.65))

		gen stocks = bl + bn + bp + br + bt
		gen cie = bx + bv - dw - dx + ys

		gen autcde = uy + uz + vb + vn + vp + ch - (_8C + _8D + vw + vx + vq + _5U) - eb
		gen bfre = stocks + cie + autcde

		destring dy, replace force
		gen bfrhe = bz + cb - (uy + uz + vb + vn + vp + vc) - (dy + dz + ea - (_8C + _8D + vw + vx + vq)- vi)

		gen immophy = an + ap + ar + at + av + ax
		gen immoinc = cx + af + ah + aj + al

		gen immoexpl = immophy + yq + yr + immoinc
		gen capi_expl = bfre + immoexpl

		gen opcom = gh - gi
		gen finr = gp - gm - gs - ge
		gen excep = ha - he
		gen transf = (fp - uf) + (gm - uh) + (hc - uk)
		gen ophex = opcom + finr + excep + transf

		gen ebgcbr = ebecbr + ophex
		gen cafr = ebgcbr - gr - hk - (0.13*hp + 0.35*hq) - hj
		gen damopro = ga + gb + gc + gd - _5S + gq + hg - uf + _5T - uh - uk + (hp*0.87) + (hq*0.65)
		gen cafnetter = cafr - damopro
		gen caproap = dl - aa - cm
		gen autofir = cafr - ze - zf

		gen etatr = hk + fx
		gen preteurr = gr + (0.13*hp) + (0.35*hq)
		gen dividr = ze + zf
		gen rrepartr = etatr + preteurr + dividr + chpersr + hj + autofir

		gen invcorp = lp - my - nc
		gen invr = invcorp + kf
		gen invcbr = ((yq*0.87) + (yr*0.65)) - ((yq_lag*0.87) + (yr_lag*0.65)) + ((hp*0.87) + (hq*0.65))

		gen invtotr = invr
		replace invtotr = invr + invcbr if invcbr>=0

		replace yq = 0 if yq == .
		replace yr = 0 if yr == .

		gen amopro = dr + (0.13 * yq) + (0.35 * yr) + _1A - ac - _5U

		gen finpro = caproap + amopro
		gen oblig = ds + dt + dm
		gen empbanc = du - eh
		gen cbc = eh + ys
		gen engcb = (0.87*yq) + (0.65*yr)
		gen banc = empbanc + cbc + engcb
		gen autemp2 = dv + dn + vi - VI2

		replace  banc = 0 if banc == .
		replace oblig = 0 if oblig == .
		replace autemp2 = 0 if autemp2 == .
		replace VI2 = 0 if VI2 == .

		gen endfi2 = oblig + banc + autemp2 + VI2

		gen totress = finpro + endfi2

	gen tx_inv_tot= 100*invtotr / vajcbr
	gen tx_inv_corp= 100*invcorp/ vajcbr

	gen tx_det_fin = 100*endfi2/ caproap
	gen tx_det_bq = 100*banc / caproap
	gen tx_det_bqct = 100*( cbc + engcb)/ caproap
	gen tx_det_bqlt = 100*empbanc / caproap

	gen tx_rentab_globalek= 100*rrepartr /( caproap + endfi2)
	gen tx_rentab_globalefp= 100*rrepartr /( finpro + endfi2)

	gen r_cashflow= autofir/ totress

	gen tx_marge= 100*ebecbr / vajcbr

	gen tx_int_detfin= 100*preteurr/ endfi2

	gen collateral= immophy + stocks
	gen collater_det_bq= collateral/ banc
	gen collater_assets= collateral/ totress

	gen cash = cf + cd
	gen cash2 = cf + cd + ch - eb

	gen cash_r = cash 	/ totress
	gen cash_r2 = cash2 / totress

	gen vaj_capro 		  = vaj    / capro
	winsor vaj_capro,gen(va_caprow) p(0.01)

	gen vaj_ta 		  = vaj    / totress
	winsor vaj_ta, gen(va_taw) p(0.01)

	gen sale_capro 		  = fl    / capro
	winsor sale_capro,gen(sale_caprow) p(0.01)
	replace sale_caprow = 0 if capro < 0

	gen sale_ta 		  = fl    / totress
	winsor sale_ta, gen(sale_taw) p(0.01)
	replace sale_taw = 0 if totress < 0

	save $raw\Fiben_total_2008_2016.dta, replace

	keep  firm D3* sale_* depart va_taw va_caprow bl bn bp br bt  caf* tx_rentab* tx_det_fin oblig dividr cie empbanc collater_det_bq collater_assets tx_int_detfin r_cashflow age ln_age year fyear di dw dx bv dv ys bx D4 D20 ebecbr fl yp caproap totress endfi banc oblig empbanc engcb dividr preteurr invcorp invr immophy  immoinc  bfre autofir cash

	save $raw\Fiben_selection_2008_2016.dta, replace

	use $raw\Fiben_total_2008_2016.dta, replace
	tsset firm fyear
	gen stock_inv = immophy + immoinc
	gen tangible_ppe = invcorp/L1.immophy
	gen inv_ppe2 	= (invr + invcorp)/L1.stock_inv
	gen ln_ppe = ln(immophy)

	foreach var in inv_ppe tangible_ppe inv_ppe2 {
	winsor `var', gen(`var'w) p(0.01)
	}

	gen gr_immophy=0.5*(immophy-L1.immophy)/(immophy+L1.immophy)
	gen gr_ppe=0.5*(stock_inv-L1.stock_inv)/(stock_inv+L1.stock_inv)

	gen gr_log_immophy=log(immophy/L1.immophy)
	gen gr_log_ppe=log(stock_inv/L1.stock_inv)

	gen r_immophy = invcorp/L1.immophy
	gen r_ppe = (invr + invcorp)/L1.stock_inv

	gen gr1_immophy = (immophy-L1.immophy)/L1.immophy
	gen gr1_ppe = (stock_inv-L1.stock_inv)/L1.stock_inv

	 winsor4 gr1_immophy, method(winsor) outlier(iqr) level(5)
	 winsor4 gr1_ppe, method(winsor) outlier(iqr) level(5)

	winsor4 r_immophy, method(winsor) outlier(iqr) level(5)
	 winsor4 r_ppe, method(winsor) outlier(iqr) level(5)

	gen inv_tot = invr + invcorp

	replace inv_tot = 0 if inv_tot < 0
	replace invcorp = 0 if invcorp < 0

	gen ln_inv = ln(inv_tot)
	gen ln_tangible =ln(invcorp)

	tsset firm fyear

	gen delta_immo = (stock_inv - L1.stock_inv)/L1.totress

	gen ln_stock_inv = ln(stock_inv)

	foreach var in delta_immo ln_stock_inv {
	winsor `var', gen(`var'w) p(0.01)
	}

	keep firm year stock_inv immophy fyear delta_immow ln_stock_inv* ln_inv ln_tangible ln_ppe inv_ppew tangible_ppe* inv_ppe2w   gr_* gr1* r_*

	save $raw\Fiben_inv.dta, replace
