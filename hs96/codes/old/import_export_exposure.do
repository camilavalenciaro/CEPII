
clear all
set more off
set excelxlsxlargefile on
set matsize 1000


** Globals
gl outputs R:/VictorZuluaga/CEPII/hs96/outputs
gl inputs R:/VictorZuluaga/CEPII/hs96/inputs
gl todrop R:/VictorZuluaga/CEPII/hs96/todrop
gl codes R:/VictorZuluaga/CEPII/hs96/codes

cd ${todrop}


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


** Total imports and imports from China

forv year=1998/2016 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_imp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_imp,"MEX","NIC","PAN","PRY","PER","URY","VEN")

* LAC (as a whole) imports
preserve
bys hs1996_6d: egen m_lac_world=total(v)
gen v2=cond(iso_exp=="CHN",v,.) //Imports from China
bys hs1996_6d: egen m_lac_chn=total(v2)
bys hs1996_6d: gen obs=_n
keep if obs==1
keep hs1996_6d year m_*
save "imports_`year'.dta", replace
restore

*Total imports per country and product
bys iso_imp hs1996_6d: egen m_world=total(v)

*Imports from China per LAC country and product
gen v2=cond(iso_exp=="CHN",v,.)
bys iso_imp hs1996_6d: egen m_chn=total(v2)

bys iso_imp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_imp hs1996_6d year m_*

save "importsLAC_`year'.dta", replace

}

*Imports from the World and China per country and product for the period 1998-2016

use "importsLAC_1998.dta", clear

forv year=1999/2016 {
append using "importsLAC_`year'.dta"
erase "importsLAC_`year'.dta"
}

fillin iso_imp hs1996_6d year
replace m_world=0 if _fillin==1
replace m_chn=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

foreach j of var m_world m_chn {
replace `j'=`j'/cpi_usa
}
drop cpi_usa

lab var m_world "Imports from World, 2016 USD"
lab var m_chn "Imports from China, 2016 USD"

so iso_imp hs1996_6d year
lab var iso_imp "Country ISO code"
save "${outputs}/importsLAC_1998-2016.dta", replace
erase "importsLAC_1998.dta"

*LAC's imports from the World and China per country and product for the period 1998-2016

use "imports_1998.dta", clear

forv year=1999/2016 {
append using "imports_`year'.dta"
erase "imports_`year'.dta"
}

fillin hs1996_6d year
replace m_lac_world=0 if _fillin==1
replace m_lac_chn=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

foreach j of var m_lac_world m_lac_chn {
replace `j'=`j'/cpi_usa
}
drop cpi_usa

lab var m_lac_world "LAC's imports from World, 2016 USD"
lab var m_lac_chn "LAC's imports from China, 2016 USD"

so hs1996_6d year

save "imports_1998-2016.dta", replace

*

use "${outputs}/importsLAC_1998-2016.dta", clear
merge m:1 hs1996_6d year using "imports_1998-2016.dta"
drop _merge

replace m_lac_world=m_lac_world-m_world
replace m_lac_chn=m_lac_chn-m_chn

lab var m_lac_world "LAC's imports from World (excluding i imports), 2016 USD"
lab var m_lac_chn "LAC's imports from China (excluding i imports), 2016 USD"

drop m_world m_chn
save "${outputs}/importsLACiv_1998-2016.dta", replace
erase "imports_1998-2016.dta"


** Total exports and exports from China

forv year=1998/2016 {

use "${outputs}/baci96_`year'.dta", clear

keep if inlist(iso_exp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV") | inlist(iso_exp,"MEX","NIC","PAN","PRY","PER","URY","VEN")

* LAC (as a whole) exports
preserve
bys hs1996_6d: egen x_lac_world=total(v)
gen v2=cond(iso_imp=="CHN",v,.) //Exports to China
bys hs1996_6d: egen x_lac_chn=total(v2)
bys hs1996_6d: gen obs=_n
keep if obs==1
keep hs1996_6d year x_*
save "exports_`year'.dta", replace
restore

*Total exports per country and product
bys iso_exp hs1996_6d: egen x_world=total(v)

*Exports to China per LAC country and product
gen v2=cond(iso_imp=="CHN",v,.)
bys iso_exp hs1996_6d: egen x_chn=total(v2)

bys iso_exp hs1996_6d: gen obs=_n

keep if obs==1
keep iso_exp hs1996_6d year x_*

save "exportsLAC_`year'.dta", replace

}

*Exports to the World and China per country and product for the period 1998-2016

use "exportsLAC_1998.dta", clear

forv year=1999/2016 {
append using "exportsLAC_`year'.dta"
erase "exportsLAC_`year'.dta"
}

fillin iso_exp hs1996_6d year
replace x_world=0 if _fillin==1
replace x_chn=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

foreach j of var x_world x_chn {
replace `j'=`j'/cpi_usa
}
drop cpi_usa

lab var x_world "Exports to World, 2016 USD"
lab var x_chn "Exports to China, 2016 USD"

ren iso_exp iso_imp
lab var iso_imp "Country ISO code"
so iso_imp hs1996_6d year
save "${outputs}/exportsLAC_1998-2016.dta", replace
erase "exportsLAC_1998.dta"

*LAC's exports to the World and China per country and product for the period 1998-2016

use "exports_1998.dta", clear

forv year=1999/2016 {
append using "exports_`year'.dta"
erase "exports_`year'.dta"
}

fillin hs1996_6d year
replace x_lac_world=0 if _fillin==1
replace x_lac_chn=0 if _fillin==1
drop _fillin

merge m:1 year using "${todrop}/cpi_USA.dta"
drop _merge

foreach j of var x_lac_world x_lac_chn {
replace `j'=`j'/cpi_usa
}
drop cpi_usa

lab var x_lac_world "LAC's exports to World, 2016 USD"
lab var x_lac_chn "LAC's exports to China, 2016 USD"

so hs1996_6d year

save "exports_1998-2016.dta", replace

*

use "${outputs}/exportsLAC_1998-2016.dta", clear
merge m:1 hs1996_6d year using "exports_1998-2016.dta"
drop _merge

replace x_lac_world=x_lac_world-x_world
replace x_lac_chn=x_lac_chn-x_chn

lab var x_lac_world "LAC's exports to the World (excluding i exports), 2016 USD"
lab var x_lac_chn "LAC's exports to China (excluding i exports), 2016 USD"

drop x_world x_chn
save "${outputs}/exportsLACiv_1998-2016.dta", replace
erase "exports_1998-2016.dta"


** Net exports to the World and China

*Net exports to the World and China per country and product for the period 1998-2016

use "${outputs}/importsLAC_1998-2016.dta", clear
merge 1:1 iso_imp hs1996_6d year using "${outputs}/exportsLAC_1998-2016.dta"
replace x_world=0 if x_world==.
replace x_chn=0 if x_chn==.
drop _merge

foreach ending in world chn {
gen double xn_`ending'=x_`ending'-m_`ending'
}
lab var xn_world "Net exports to World, 2016 USD"
lab var xn_chn "Net exports to China, 2016 USD"
drop m_world m_chn x_world x_chn

save "${outputs}/netexportsLAC_1998-2016.dta", replace

*LAC's net exports to the World and China per country and product for the period 1998-2016

use "${outputs}/importsLACiv_1998-2016.dta", clear
merge 1:1 iso_imp hs1996_6d year using "${outputs}/exportsLACiv_1998-2016.dta"
replace x_lac_world=0 if x_lac_world==.
replace x_lac_chn=0 if x_lac_chn==.
drop _merge

foreach ending in world chn {
gen double xn_lac_`ending'=x_lac_`ending'-m_lac_`ending'
}
lab var xn_lac_world "LAC's net exports to World, 2016 USD"
lab var xn_lac_chn "LAC's net exports to China, 2016 USD"
drop m_lac_world m_lac_chn x_lac_world x_lac_chn

save "${outputs}/netexportsLACiv_1998-2016.dta", replace
