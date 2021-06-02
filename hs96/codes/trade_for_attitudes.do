********************************************************************************
* Trade 
* Trade: CEPII
* Camila Valencia
* *******************************************************************************

/* This do file generate the imports per country and per product of Latin American
countries from the world and from China. Also calculates imports of final goods 
from the world and China. 
Exports and net exports per country and per product of Latin American countries
to China and the world*/


clear all
set more off
set excelxlsxlargefile on
set matsize 1000


** Globals
gl outputs Y:/Research/CamilaValencia/CEPII/hs96/outputs
gl inputs Y:/Research/CamilaValencia/CEPII/hs96/inputs
gl todrop Y:/Research/CamilaValencia/CEPII/hs96/todrop
gl codes Y:/Research/CamilaValencia/CEPII/hs96/codes
gl concordance Y:/Research/CamilaValencia/CEPII/hs96/codes/concordance

cd ${todrop}


** Including trade with Hong Kong
gl hkg_adj YES
if "${hkg_adj}"=="YES" {
gl ending "_adj"
gl chinam `"inlist(iso_exp,"CHN","HKG")"'
gl chinax `"inlist(iso_imp,"CHN","HKG")"'
}
else {
gl chinam `"iso_exp=="CHN""'
gl chinax `"iso_imp=="CHN""'
}


** CPI, US

wbopendata, language(en - English) country() topics() indicator(FP.CPI.TOTL) clear long

keep if countrycode=="USA" & year>=1998 & year<=2017
keep year fp_cpi_totl

tempvar var1 var2
gen `var1'=fp_cpi_totl if year==2017
egen `var2'=max(`var1')
replace fp_cpi_totl=fp_cpi_totl/`var2'
drop `var1' `var2'

ren fp_cpi_totl cpi_usa
save "${todrop}/cpi_USA_2017.dta", replace




** Total imports and imports from China

forv year=1998/2017 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_imp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_imp,"GTM", "HND", "MEX","NIC","PAN","PRY","PER","URY","VEN")

* LAC (as a whole) imports
preserve
bys hs1996_6d: egen double m_lac_world=total(v)
gen double v2=cond(${chinam},v,.) // Imports from China
bys hs1996_6d: egen double m_lac_chn=total(v2)
bys hs1996_6d: gen obs=_n
keep if obs==1
keep hs1996_6d year m_*
save "imports_`year'.dta", replace
restore

*Total imports per country and product
bys iso_imp hs1996_6d: egen double m_world=total(v)

*Imports from China per LAC country and product
gen double v2=cond(${chinam},v,.)
bys iso_imp hs1996_6d: egen double m_chn=total(v2)

bys iso_imp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_imp hs1996_6d year m_*

save "importsLAC_`year'.dta", replace

}

*Imports from the World and China per country and product for the period 1998-2017

use "importsLAC_1998.dta", clear

forv year=1999/2017 {
append using "importsLAC_`year'.dta"
erase "importsLAC_`year'.dta"
}

fillin iso_imp hs1996_6d year
replace m_world=0 if _fillin==1
replace m_chn=0 if _fillin==1
drop _fillin

lab var m_world "Imports from World, current 1000 USD"
lab var m_chn "Imports from China, current 1000 USD"

so iso_imp hs1996_6d year
lab var iso_imp "Country ISO code"
save "${outputs}/importsLAC_current_1998-2017.dta", replace
erase "importsLAC_1998.dta"



** Total exports and exports to China

forv year=1998/2017 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_exp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_exp,"GTM", "HND","MEX","NIC","PAN","PRY","PER","URY","VEN")

* LAC (as a whole) exports
preserve
bys hs1996_6d: egen double x_lac_world=total(v)
gen double v2=cond(${chinax},v,.) // Exports to China
bys hs1996_6d: egen double x_lac_chn=total(v2)
bys hs1996_6d: gen obs=_n
keep if obs==1
keep hs1996_6d year x_*
save "exports_`year'.dta", replace
restore

*Total exports per country and product
bys iso_exp hs1996_6d: egen double x_world=total(v)

*Exports to China per LAC country and product
gen double v2=cond(${chinax},v,.)
bys iso_exp hs1996_6d: egen double x_chn=total(v2)

bys iso_exp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_exp hs1996_6d year x_*

save "exportsLAC_`year'.dta", replace

}

*Exports to the World and China per country and product for the period 1998-2016

use "exportsLAC_1998.dta", clear

forv year=1999/2017 {
append using "exportsLAC_`year'.dta"
erase "exportsLAC_`year'.dta"
}

fillin iso_exp hs1996_6d year
replace x_world=0 if _fillin==1
replace x_chn=0 if _fillin==1
drop _fillin

lab var x_world "Exports to World, current 1000 USD"
lab var x_chn "Exports to China, current 1000 USD"

ren iso_exp iso_imp
lab var iso_imp "Country ISO code"
so iso_imp hs1996_6d year
save "${outputs}/exportsLAC_current_1998-2017.dta", replace
erase "exportsLAC_1998.dta"




** Net exports to the World and China

*Net exports to the World and China per country and product for the period 1998-2016

use "${outputs}/importsLAC_current_1998-2017.dta", clear
merge 1:1 iso_imp hs1996_6d year using "${outputs}/exportsLAC_current_1998-2017.dta"
replace x_world=0 if x_world==.
replace x_chn=0 if x_chn==.
drop _merge

foreach ending in world chn {
gen double xn_`ending'=x_`ending'-m_`ending'
}
lab var xn_world "Net exports to World, current 1000 USD"
lab var xn_chn "Net exports to China, current 1000 USD"
drop m_world m_chn x_world x_chn

save "${outputs}/netexportsLAC_current_1998-2017.dta", replace


*------------------------------------------------------------------------------*



** Total imports of final goods and imports of final goods from China

forv year=1998/2017 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_imp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_imp,"GTM", "HND","MEX","NIC","PAN","PRY","PER","URY","VEN")

ren hs1996_6d HS6_string
merge m:1 HS6_string using "${inputs}/concordance_HS1_to_BEC.dta", keepus(goodclass)
drop if _merge==2
drop _merge
keep if goodclass==3 // only final goods
drop goodclass
ren HS6_string hs1996_6d

*Total imports per country and product
bys iso_imp hs1996_6d: egen double m_world=total(v)

*Imports from China per LAC country and product
gen double v2=cond(${chinam},v,.)
bys iso_imp hs1996_6d: egen double m_chn=total(v2)

bys iso_imp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_imp hs1996_6d year m_*

save "importsLAC_`year'.dta", replace

}

*Imports from the World and China per country and product for the period 1998-2016 (only final goods)

use "importsLAC_1998.dta", clear

forv year=1999/2017 {
append using "importsLAC_`year'.dta"
erase "importsLAC_`year'.dta"
}

fillin iso_imp hs1996_6d year
replace m_world=0 if _fillin==1
replace m_chn=0 if _fillin==1
drop _fillin



lab var m_world "Imports of FG from the World, current 1000 USD"
lab var m_chn "Imports of FG from China, current 1000 USD"

so iso_imp hs1996_6d year
lab var iso_imp "Country ISO code"
save "${outputs}/importsfgLAC_current_1998-2017.dta", replace
erase "importsLAC_1998.dta"



*------------------------------------------------------------------------------*

use "${outputs}/importsLAC_current_1998-2017.dta", clear
collapse (sum) m_world m_chn, by(year iso_imp)
lab var m_world "Total imports, current 1000 USD"
lab var m_chn "Imports from China, current 1000 USD"
save "${todrop}/imports_year.dta", replace

use "${outputs}/exportsLAC_current_1998-2017.dta", clear
collapse (sum) x_world x_chn, by(year iso_imp)
lab var x_world "Total exports, current 1000 USD"
lab var x_chn "Exports to China, current 1000 USD"
save "${todrop}/exports_year.dta", replace

use "${outputs}/netexportsLAC_current_1998-2017.dta", clear
collapse (sum) xn_world xn_chn, by(year iso_imp)
lab var xn_world "Net exports, current 1000 USD"
lab var xn_chn "Net exports from China, current 1000 USD"
save "${todrop}/netexports_year.dta", replace

use "${outputs}/importsfgLAC_current_1998-2017.dta", clear
collapse (sum) m_world m_chn, by(year iso_imp)
ren m_world mfg_world
ren m_chn mfg_chn
lab var mfg_world "Final Good imports, current 1000 USD"
lab var mfg_chn "Final Good Imports from China, current 1000 USD" 
save "${todrop}/importsfg_year.dta", replace

merge 1:1 iso year using "${todrop}/imports_year.dta", nogen
merge 1:1 iso year using "${todrop}/exports_year.dta", nogen
merge 1:1 iso year using "${todrop}/netexports_year.dta", nogen
ren iso_imp iso
save "${outputs}/tradedata_98-17.dta", replace








