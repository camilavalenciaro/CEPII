
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




use ${outputs}/baci96_2017.dta, replace

keep if inlist(iso_exp,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","SLV")/*
*/ | inlist(iso_exp,"MEX","NIC","PAN","PRY","PER","URY","VEN")/*
*/ | inlist(iso_exp,"SUR","FLK","GUY")/*
*/ | inlist(iso_exp,"PAN","HND","GTM","BHS","BRD","BLZ","HTI","JAM", "TTO")

destring hs1996_6d, gen(product)
keep if product < 250000

collapse (sum) v, by(hs1996_6d iso_imp)
collapse (sum) v, by(iso_imp)
egen total_exp=total(v)
gen percent_country= v/total_exp
gen nepercent=-percent_country
sort nepercent
rename iso_imp iso3
merge 1:m iso3 using country_code_baci96.dta
drop if _merge==2
drop _merge i iso2
order country,a(iso3)
gen percent = percent_country*100
keep iso3 country percent


export excel using "${outputs}/exp_agri_LAC.xlsx", firstrow(variables) sheet("Original") replace

