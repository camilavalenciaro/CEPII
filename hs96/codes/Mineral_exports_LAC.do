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

use "${outputs}/exportsLAC_current_1998-2017.dta", clear
egen x_total=sum(x_world), by(iso_imp year)
destring hs1996_6d, gen (x)
keep if x>269999 & x<280000
egen x_min=sum(x_world), by(iso_imp year)
gen share_min_x= x_min/x_total
collapse (mean) x_total x_min share_min_x, by(iso_imp year)
ren iso_imp iso

merge 1:1 iso year using "Y:/Research/CamilaValencia/PoliticalEconomy/todrop/GDP_98-17.dta", nogen
gen gdp=ny_gdp_mktp_cd
drop region-tg_val_totl_gd_zs
gen share_min_gdp=x_min/gdp
order iso countryname year gdp x_total x_min share_min_gdp share_min_x 
replace share_min_gdp= share_min_gdp*100
replace share_min_x= share_min_x*100
export excel using "${todrop}/mineral_exports_LAC.xls", sheetreplace firstrow(variables)
