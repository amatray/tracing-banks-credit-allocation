	global regspec_im_fbt_b  	"absorb (firm_cc firm_dq county_dq) vce (cluster cib)"
	global regspec_im_fbt_c  	"absorb (firm_cc firm_dq county_dq gea_dq) vce (cluster cib)"

	global regspec_cib 			"absorb(cib year bhc_year) vce (cluster cib)"

	global regspec3 			"absorb(cibcounty county_time gea_time) vce (cluster cib)"
	global regspec5 			"absorb(cibcounty county_time gea_time) vce(cluster cibcounty)"

	global specification 		"absorb(firm ind_cc_year) vce(cluster firm)"
	global specification2 		"absorb(firm ind_year) vce(cluster firm)"

	global rhs 					"DR1reg_gap DRreg_lag"
	global rhs_spec 			"DRgap_d DR1new_gap  DR_d  DRnew_lag gap_d d"

	global fixed2 				"absorb(zcf countydq) vce(cluster zcf)"

	global dependent1 			"DRnew_spec_lag DR1new_spec_gap"
