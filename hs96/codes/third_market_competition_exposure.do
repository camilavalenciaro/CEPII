
clear all
set more off
set excelxlsxlargefile on
set matsize 1000


** Globals
gl outputs Y:/Research/CamilaValencia/CEPII/hs96/outputs
gl inputs Y:/Research/CamilaValencia/CEPII/hs96/inputs
gl todrop Y:/Research/CamilaValencia/CEPII/hs96/todrop
gl codesY:/Research/CamilaValencia/CEPII/hs96/codes

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

keep if countrycode=="USA" & year>=1998 & year<=2016
keep year fp_cpi_totl

tempvar var1 var2
gen `var1'=fp_cpi_totl if year==2016
egen `var2'=max(`var1')
replace fp_cpi_totl=fp_cpi_totl/`var2'
drop `var1' `var2'

ren fp_cpi_totl cpi_usa
save "${todrop}/cpi_USA.dta", replace


** Identifing the countries where each country in LAC was exporting at baseline
* We will use as baseline the years 1998, 1999, and 2000

forv year=1998/2000 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_exp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_exp,"MEX","NIC","PAN","PRY","PER","URY","VEN")

keep if v!=0 & v!=. // positive exports

keep iso_exp iso_imp hs1996_6d year

save "DexportsLAC_`year'.dta", replace

}

use "DexportsLAC_1998.dta", clear
append using "DexportsLAC_1999.dta"
append using "DexportsLAC_2000.dta"

drop year
duplicates drop iso_exp iso_imp hs1996_6d, force
save "third_markets.dta", replace

erase "DexportsLAC_1998.dta"
erase "DexportsLAC_1999.dta"
erase "DexportsLAC_2000.dta"


*** Chinese third-market competition ***

** Imports from China

forv year=1998/2016 {

use "${outputs}/baci96_`year'.dta", clear

drop if ${chinax} // we don't want to include China or Hong Kong as importers

*Imports from China per country and product
gen double v2=cond(${chinam},v,.)
bys iso_imp hs1996_6d: egen double m_chn=total(v2)

bys iso_imp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_imp hs1996_6d year m_chn

save "imports_`year'.dta", replace

}

*Imports from China per country and product for the period 1998-2016

use "imports_1998.dta", clear

forv year=1999/2016 {
append using "imports_`year'.dta"
erase "imports_`year'.dta"
}
erase "imports_1998.dta"

fillin iso_imp hs1996_6d year
replace m_chn=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

replace m_chn=m_chn/cpi_usa
drop cpi_usa

lab var m_chn "Imports from China, 2016 USD"

so iso_imp hs1996_6d year
lab var iso_imp "Country ISO code"
save "imports_1998-2016.dta", replace

** Computing the Chinese exports to third markets

use "third_markets.dta", clear
joinby iso_imp hs1996_6d using "imports_1998-2016.dta", unmatched(master)
drop _merge

bys iso_exp hs1996_6d year: egen double m_tm_chn=total(m_chn)
lab var m_tm_chn "Chinese exports to i's trade partners, 2016 USD"

bys iso_exp hs1996_6d year: gen obs=_n

keep if obs==1
keep iso_exp hs1996_6d year m_tm_chn

save "importstc_chn_1998-2016${ending}.dta", replace
erase "imports_1998-2016.dta"


*** Third-market competition ***

loc lac ARG BOL BRA CHL COL CRI DOM ECU SLV MEX NIC PAN PRY PER URY VEN

foreach iso of loc lac {

** Total imports

forv year=1998/2016 {

use "${outputs}/baci96_`year'.dta", clear

drop if iso_exp=="`iso'" // we don't want to include the exports from `iso'

*Imports from all the countries except `iso'
bys iso_imp hs1996_6d: egen double m_world=total(v)

bys iso_imp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_imp hs1996_6d year m_world

save "imports_`year'.dta", replace

}

*Imports from all the countries except `iso' per country and product for the period 1998-2016

use "imports_1998.dta", clear

forv year=1999/2016 {
append using "imports_`year'.dta"
erase "imports_`year'.dta"
}
erase "imports_1998.dta"

fillin iso_imp hs1996_6d year
replace m_world=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

replace m_world=m_world/cpi_usa
drop cpi_usa

lab var m_world "Imports from the world, 2016 USD"

so iso_imp hs1996_6d year
lab var iso_imp "Country ISO code"
save "imports_1998-2016.dta", replace

** Computing the third-market import competition

use "third_markets.dta", clear
keep if iso_exp=="`iso'"
joinby iso_imp hs1996_6d using "imports_1998-2016.dta", unmatched(master)
drop _merge

bys iso_exp hs1996_6d year: egen double m_tm_world=total(m_world)
lab var m_tm_world "Import competition in third markets, 2016 USD"

bys iso_exp hs1996_6d year: gen obs=_n

keep if obs==1
keep iso_exp hs1996_6d year m_tm_world


save "third_markets_`iso'.dta", replace
erase "imports_1998-2016.dta"

}
erase "third_markets.dta"

*

clear
foreach iso in ARG BOL BRA CHL COL CRI DOM ECU SLV MEX NIC PAN PRY PER URY VEN {
append using "third_markets_`iso'.dta"
erase "third_markets_`iso'.dta"
}

***

merge 1:1 iso_exp hs1996_6d year using "importstc_chn_1998-2016${ending}.dta", update
erase "importstc_chn_1998-2016${ending}.dta"
replace m_tm_world=0 if m_tm_world==. & _merge==2
replace m_tm_chn=0 if m_tm_chn==. & _merge==1
drop _merge
drop if year==.
so iso_exp hs1996_6d year
save "${outputs}/importstc_1998-2016${ending}.dta", replace
