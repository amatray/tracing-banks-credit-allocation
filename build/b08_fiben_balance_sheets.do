	use $raw\Fiben_scr_cibcounty.dta, replace

	drop if lme_first==1

	keep firm dq naf3 cote* depart tx_rentab* tx_det_fin oblig dividr cie empbanc ///
	     collater_det_bq collater_assets tx_int_detfin r_cashflow age ln_age year fyear ///
	     di dw dx bv D4 D20 ebecbr fl yp caproap totress endfi banc engcb preteurr ///
	     invcorp invr immophy immoinc bfre autofir lme_first

	drop if fyear ==.
	bys firm fyear (dq cotebdf) : replace cotebdf = cotebdf[_N]
	bys firm fyear (dq naf3)    : replace naf3   = naf3[_N]
	drop dq
	duplicates drop
	isid firm fyear

	tsset firm fyear

	gen firm_county = depart

		gen rating_num=0 if cotebdf=="0"
		replace rating_num = 1 if cotebdf == "3++"
		replace rating_num = 2 if cotebdf == "3+"
		replace rating_num = 3 if cotebdf == "3"
		replace rating_num = 4 if cotebdf == "4+"
		replace rating_num = 5 if cotebdf == "4"
		replace rating_num = 6 if cotebdf == "5+"
		replace rating_num = 7 if cotebdf == "5"
		replace rating_num = 8 if cotebdf == "6"
		replace rating_num = 9 if cotebdf == "7"
		replace rating_num = 10 if cotebdf == "8"
		replace rating_num = 11 if cotebdf == "9"
		replace rating_num = 12 if cotebdf == "P"

		bys firm : gen rating_lag = L1.rating_num
		gen downgrade = 1 if (rating_lag > rating_num) & rating_lag !=.
		replace downgrade = 0 if rating_lag !=. & downgrade ==.

		bys firm : gen notch_dif = rating_lag - rating_num
		gen severe_downgrade = 1 if (notch_dif > 2) & notch_dif !=.
		replace severe_downgrade = 0 if severe_downgrade==. & notch_dif !=.

	drop if totress == .
	drop if totress <= 0

	local varlist "ebecbr fl yp caproap totress endfi banc oblig empbanc engcb dividr preteurr invcorp invr immophy  immoinc  bfre autofir"
	foreach i of var `varlist' {
	by firm : gen `i'_lag=L1.`i'
	}

	bys firm : gen investment1= invcorp/immophy_lag

	bys firm : gen delta_immo = immophy - immophy_lag
	bys firm : gen investment3= delta_immo/immophy_lag

	bys firm : gen investment2= (invcorp + invr)/(immophy_lag+immoinc_lag)

	bys firm : gen delta_sales = ln(fl) - ln(fl_lag)
	gen ln_sale = ln(fl)

	bys firm : gen delta_ta = ln(totress) - ln(totress_lag)

	gen size= ln(totress)

	bys firm : gen delta_endfi = ln(endfi2+1)- ln(L1.endfi2+1)
	gen ln_endfi =ln(endfi2)
	gen ln_endfi_excb=ln(endfi2-engcb)

	bys firm : gen nwk = bfre/fl

	bys firm : gen CF 	= autofir / totress_lag

	label var ln_age "Log of firm's nber of years of existence"
	label var age "Nber. of years of existence"

	gen ln_yp = ln(yp)

	gen sales= fl/totress_lag

	gen capex1= invr/totress_lag
	gen capex2= invcorp/totress_lag

	gen book_leverage =endfi2/totress_lag

	gen tan_asset = immophy/totress_lag

	gen profitability = ebecbr/totress_lag
	gen prof_sale=ebecbr/fl

	gen econ_prof = ebecbr /(bfre + immophy)

	local varlist "sales capex1 capex2 book_leverage tan_asset profitability prof_sale econ_prof"
	foreach i of var `varlist' {
	by firm : gen `i'_lag=L1.`i'
	winsor `i' , gen (`i'_w) p(0.01)
	drop `i'
	rename `i'_w `i'
	}

	drop if year == 2009

		drop if year==2008
		drop if year==2016

	save $raw\Fiben_bs_2010_2016.dta, replace

		use $raw\Fiben_bs_2010_2016, replace
		keep firm year
		sort firm year
		duplicates drop firm year, force
		save $raw\fiben_list.dta,replace

		use $raw\Fiben_bs_2010_2016, replace
		keep firm year fl totress lme_first yp cotebdf
		rename fl sale
		replace totress = totress/ 1000

		replace sale = sale/ 1000

		gen small_lme = (lme_first==1)
		gen small_1  = (sale < 1)
		gen small_2  = ((sale < 2 & (yp<10 | yp==.)) | (totress <2 & (yp<10 | yp==.)))
		gen small_3  = (sale < 3 )
		gen small_5  = (sale < 5 )

		keep firm year small_*
		save $raw\temp_small, replace
