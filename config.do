	clear all
	set more off, permanently
	set rmsg  on, permanently
	set matsize 11000
	set max_memory 32g

	global do     "$root"

	global scr    "<path to the credit register (Centrale des risques) Stata files CN_YYYY.dta>"
	global lec    "<path to the SURFI securities holdings (TITRE_PTF_EC)>"
	global bdf    "<path to the SURFI Stata files>"
	global bilans "<path to the FIBEN balance-sheet CSV extracts>"
	global desc   "<path to the FIBEN descriptive CSV extracts>"

	global raw    "<empty folder for intermediate datasets>"
	global data   "<folder holding the external inputs listed in README.md>"
	global tex    "<output folder for tables>"
	global fig    "<output folder for figures>"
	global log    "<output folder for logs>"

	global crosswalk "$data\geography_crosswalk.dta"

	foreach d in raw tex fig log {
		capture mkdir "${`d'}"
	}

	local install_packages 0
	if `install_packages' {
		foreach p in ftools reghdfe estout regsave winsor winsor4 tsspell carryforward egenmore {
			capture which `p'
			if _rc ssc install `p', replace
		}
		reghdfe, compile
	}

	capture log close _all
	local today = string(daily(c(current_date), "DMY"), "%tdCCYYNNDD")
	log using "$log/replication_`today'", replace name(replication)

	cd "$raw"
