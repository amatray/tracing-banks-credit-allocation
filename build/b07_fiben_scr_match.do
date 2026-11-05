	cd $raw
	use cn20082016_sme_panel_qtr_SME_clean, replace
	keep siren cib dq  y lme_first naf3 zcf zcb cotebdf independent indcheck gea region county oc ta te ca co cc af cc bm bi
	save scr_sme_sample.dta,replace

	use scr_sme_sample.dta,replace
	gen dep=string(zcb)
	gen county_s = substr(dep,1,2) if zcb >= 10000
	replace county_s = substr(dep,1,1) if zcb < 10000
	destring(county_s), gen (county)
	drop dep county_s
	lab var county "County of the bank branch with which the firm has a LR"

	gen dep_f=string(zcf)
	gen county_s = substr(dep_f,1,2) if zcf >= 10000
	replace county_s = substr(dep_f,1,1) if zcf < 10000
	destring(county_s), gen (county_f)
	drop dep_f county_s
	lab var county_f "County of firm"

	gen cibcounty=string(cib,"%02.0f")+string(county,"%02.0f")

	gen undrawn = oc
	gen mlt 	= ta + te
	gen newst	= ca + co
	gen st	 	= ca+co+cc+af
	gen arf 	= cc +af
	gen cb		= bm+bi

	gen i=1
	bys siren cibcounty dq : egen multi_b =sum(i)

	collapse (sum) und mlt newst st arf cb (last) cotebdf cib zcf zcb lme_first naf3 gea independent indcheck county* region y, by(siren cibcounty dq)

	sort cibcounty dq y
	rename siren firm
	lab var region " Firm region"
	rename y year

	gen i=1
	bys firm county dq : egen multi_cibc =sum(i)
	gen multi_cibcounty =0
	replace multi_cibcounty =1 if multi_cibc > 1 & multi_cibc !=.
	drop multi_cibc
	drop i

	gen i=1
	bys firm gea county dq : egen multi_geac =sum(i)
	gen multi_geacounty =0
	replace multi_geacounty =1 if multi_geac > 1 & multi_geac !=.
	drop multi_geac
	drop i

	lab var multi_cibcounty "Multi-cib firm within county c in quarter t"
	lab var multi_geacounty "Multi-gea firm within county c in quarter t"

	save scr_county_list_b.dta, replace

	use Fiben_selection_2008_2016.dta, clear

	merge 1:m firm year using scr_county_list_b.dta
	drop if _m==1

	gen in_fiben=0
	replace in_fiben=1 if _m==3
	drop _m

	destring cibcounty, gen(temp)
	drop cibcounty
	rename temp cibcounty

	save Fiben_scr_cibcounty.dta, replace
