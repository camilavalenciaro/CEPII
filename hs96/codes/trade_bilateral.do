********************************************************************************
* Bilateral trade 
* Trade: CEPII
* Camila Valencia
* *******************************************************************************

/* This do file generate the total exports, exports to OECD countries and Herfindahl
index at the destination level and product level */

clear all
set more off
set excelxlsxlargefile on
set matsize 1000


** Globals
gl outputs Y:/Research/CamilaValencia/CEPII/hs96/outputs
gl inputs Y:/Research/CamilaValencia/CEPII/hs96/inputs
gl todrop Y:/Research/CamilaValencia/CEPII/hs96/todrop
gl codes Y:/Research/CamilaValencia/CEPII/hs96/codes

cd ${todrop}



*                                   Trade data                                 *
*------------------------------------------------------------------------------*

forv year=1998(1)2017 {

use "${outputs}/baci96_`year'.dta", clear

* Exports and imports all countries in `year' by product

preserve
bys iso_exp hs1996_6d: egen double exports_cp=total(v)
duplicates drop iso_exp hs1996_6d, force
keep iso_exp hs1996_6d year exports_cp
ren iso_exp iso
save "exports_cp_`year'.dta", replace
restore

preserve
bys iso_imp hs1996_6d: egen double imports_cp=total(v)
duplicates drop iso_imp hs1996_6d, force
keep iso_imp hs1996_6d imports_cp
ren iso_imp iso
save "imports_cp_`year'.dta", replace

merge 1:1 iso hs1996_6d using "${todrop}/exports_cp_`year'.dta"
replace exports_cp=0 if exports_cp==.
replace imports_cp=0 if imports_cp==.
drop _merge
lab var iso "Country ISO"
lab var imports_cp "Aggregate imports"
lab var exports_cp "Aggregate exports"
order iso hs1996_6d year

save "trade_cp_`year'.dta", replace
erase "exports_cp_`year'.dta"
erase "imports_cp_`year'.dta"
restore

* Aggregated bilateral exports and imports in 2017

bys iso_exp iso_imp: egen double exports_cc=total(v)
ren iso_exp iso2
ren iso_imp iso1
lab var exports_cc "Bilateral exports"
keep iso2 iso1 year exports_cc
duplicates drop iso2 iso1, force

save "trade_cc_`year'.dta", replace

* Herfindahl: products

use "trade_cp_`year'.dta", clear

foreach var in imports exports {
bys iso: egen double `var'=total(`var'_cp)
gen double sh_`var'_cp=`var'_cp/`var'
gen double sh_`var'_cp2=sh_`var'_cp^2
}

bys iso: egen double H_m_p=total(sh_imports_cp2)
bys iso: egen double H_x_p=total(sh_exports_cp2)

duplicates drop iso, force
keep iso year H*
lab var H_m_p "Herfindahl index (imports at the product level)"
lab var H_x_p "Herfindahl index (exports at the product level)"

save "Herfindahl_index_product_`year'.dta", replace

* Herfindahl: countries

use "trade_cc_`year'.dta", clear

preserve
bys iso1: egen double imports=total(exports_cc)
gen double sh_imports_cc=exports_cc/imports
gen double sh_imports_cc2=sh_imports_cc^2
bys iso1: egen double H_m_c=total(sh_imports_cc2)
duplicates drop iso1, force
ren iso1 iso
keep iso year H_m_c
lab var H_m_c "Herfindahl index (imports at the origin level)"
save "Herfindahl_index_countries_m_`year'.dta", replace
restore

bys iso2: egen double exports=total(exports_cc)
gen double sh_exports_cc=exports_cc/exports
gen double sh_exports_cc2=sh_exports_cc^2
bys iso2: egen double H_x_c=total(sh_exports_cc2)
duplicates drop iso2, force
ren iso2 iso
keep iso year H_x_c
lab var H_x_c "Herfindahl index (exports at the destination level)"

merge 1:1 iso using "Herfindahl_index_countries_m_`year'.dta"
drop _merge

merge 1:1 iso using "Herfindahl_index_product_`year'.dta"
drop _merge

order iso year H_m_c H_x_c H_m_p H_x_p
lab var iso "Country ISO"

save "Herfindahl_index_`year'.dta", replace
erase "Herfindahl_index_product_`year'.dta"
erase "Herfindahl_index_countries_m_`year'.dta"
}

*------------------------------------------------------------------------------*

* Share of trade with OECD countries (2017)

use "${todrop}/trade_cc_2017.dta", clear

gen oecd=0
replace oecd=1 if inlist(iso1,"AUS","AUT","BEL","CAN","CHL","CZE","DNK","EST")
replace oecd=1 if inlist(iso1,"FIN","FRA","DEU","GRC","HUN","ISL","IRL","ISR")
replace oecd=1 if inlist(iso1,"ITA","JPN","KOR","LVA","LTU","LUX","MEX","NLD")
replace oecd=1 if inlist(iso1,"NZL","NOR","POL","PRT","SVK","SVN","ESP","SWE")
replace oecd=1 if inlist(iso1,"CHE","TUR","GBR","USA")

gen double var1=exports_cc*oecd
bys iso2: egen double exports_oecd=total(var1)
bys iso2: egen double exports=total(exports_cc)
gen double sh_x_oecd=exports_oecd/exports
drop var1

duplicates drop iso2, force
ren iso2 iso
keep iso year exports_oecd exports sh_x_oecd

lab var iso "Country ISO code"
lab var year "Year trade"
lab var exports_oecd "Exports to OECD countries"
lab var exports "Total exports"
lab var sh_x_oecd "Share of exports to OECD countries"

merge 1:1 iso using "Herfindahl_index_2017.dta", keepus(H_m_c H_x_c H_m_p H_x_p)
drop _merge

save "${outputs}/data_oecd_herfindahl_2017.dta", replace
