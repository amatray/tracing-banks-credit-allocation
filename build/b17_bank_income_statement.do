	use cib date_arrete S06_1420 S07_1620 S07_0020 using $bdf\cpte_resu_france_final.dta, replace
	gen int year = floor(date_arrete / 10000)
	gen double minus_loss = -S07_1620
	egen double profit = rowtotal(S06_1420 minus_loss), missing
	gen double profitability = profit / S07_0020 if S07_0020 > 0
	keep cib year profitability
	save $raw\bank_profitability.dta, replace

	keep cib
	duplicates drop
	expand 8
	bys cib : gen int year = 2008 + _n
	merge 1:1 cib year using $raw\bank_profitability.dta, keep(master match) nogen

	bys cib : egen int first_year = min(cond(!missing(profitability), year, .))
	gen double v_first = profitability if year == first_year
	bys cib : egen double first_val = max(v_first)

	gen byte prof_fill = missing(profitability) & year <= 2010 & year < first_year & !missing(first_year)
	replace profitability = first_val if prof_fill == 1

	gen int dq = yq(year, 4)
	format dq %tq
	keep cib dq profitability prof_fill
	label var profitability "Profits/revenues: (S06_1420 - S07_1620)/S07_0020, CPTE_RESU, year N on N-Q4"
	label var prof_fill 	"1 = leading 2009-2010 value filled with the first observed value"
	save $raw\bank_profitability.dta, replace

	use cib date_arrete S06_0020 S06_0200 S06_0220 S06_0230 S06_0320 using $bdf\cpte_resu_france_final.dta, replace
	gen int year = floor(date_arrete / 10000)
	egen double deposit_expense = rowtotal(S06_0200 S06_0220 S06_0230 S06_0320) if !missing(S06_0020)
	replace deposit_expense = deposit_expense / 1000
	keep cib year deposit_expense
	save $raw\bank_deposit_expense.dta, replace

	use cib date_arrete S0H_0010 S02_0660 S02_0870 S02_0710 S02_0880 using $raw\situation_raw_trim.dta, replace
	gen int year = floor(date_arrete / 10000)
	egen double deposits_q = rowtotal(S02_0660 S02_0870 S02_0710 S02_0880) if !missing(S0H_0010) & S0H_0010 > 0
	collapse (mean) avg_deposits = deposits_q (count) n_d = deposits_q, by(cib year)
	replace avg_deposits = . if n_d < 4
	replace avg_deposits = avg_deposits / 1000
	drop n_d

	merge 1:1 cib year using $raw\bank_deposit_expense.dta, nogen
	label var deposit_expense "Deposit interest: S06_0200+0220+0230+0320, k EUR"
	label var avg_deposits    "Mean 4 Q-ends S02_0660+0870+0710+0880 (same deposits), k EUR"
	save $raw\bank_deposit_cost.dta, replace
