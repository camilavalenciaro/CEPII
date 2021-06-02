
clear all
set more off
set excelxlsxlargefile on
set matsize 1000


** Globals
gl outputs Y:/Research/CamilaValenciaa/CEPII/hs96/outputs
gl inputs Y:/Research/CamilaValenciaa/CEPII/hs96/inputs
gl todrop Y:/Research/CamilaValenciaa/CEPII/hs96/todrop
gl codes Y:/Research/CamilaValenciaa/CEPII/hs96/codes

cd ${todrop}


** countries

import delimited "${inputs}/country_code_baci96.csv", clear

replace country="Belgium" if country=="Belgium-Luxembourg"
replace country="Cote d'Ivoire" if country=="Côte dIvoire"
replace country="Korea" if country=="Rep. of Korea"
replace country="Macedonia" if country=="TFYR of Macedonia"
replace country="Moldova" if country=="Rep. of Moldova"
replace country="Netherlands Antilles" if country=="Neth. Antilles"
replace country="Tanzania" if country=="United Rep. of Tanzania"

drop if iso3=="NULL"

save "country_code_baci96.dta", replace


** Trade (CEPII)

forv year=1998(1)2017 {

unzipfile "${inputs}/baci96_`year'.zip", replace
import delimited "baci96_`year'.csv", clear

merge m:1 i using "country_code_baci96.dta", keepus(iso3)
drop if _merge!=3
drop _merge i
ren iso3 iso_exp // exporter

ren j i
merge m:1 i using "country_code_baci96.dta", keepus(iso3)
drop if _merge!=3
drop _merge i
ren iso3 iso_imp // importer

ren t year

tostring hs6, gen(hs1996_6d)
replace hs1996_6d="0"+string(hs6) if hs6<100000

keep iso_exp iso_imp hs1996_6d year v q
order iso_exp iso_imp hs1996_6d year v q

duplicates drop iso_exp iso_imp hs1996_6d, force

lab var iso_exp "Exporter"
lab var iso_imp "Importer"
lab var hs1996_6d "6-digit HS code (1996)"
lab var year "Year"
lab var v "Export value"
lab var q "Export volume"

save "${outputs}/baci96_`year'.dta", replace
erase "baci96_`year'.csv"
}
