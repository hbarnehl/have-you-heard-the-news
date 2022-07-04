*=============================================================================*
*					 			 Final Paper							      *
/*============================================================================*
Used data:
- Wave 6 of the World Values Survey
- Varieties of Democracy Dataset v 11

The do-file made-up of the following parts:

1. Merging Datasets
2. Recoding
3. Descriptives
4. Testing for Assumptions
5. Analysis
6. Visualisation of Interaction
*/

* set directories

global dir "D:\OneDrive - UvA\Universität\Research Master Social Sciences\Year 1\Block V\Fixed and Random Effects\Final Paper"

//create saving directories
global data "$dir\Data"
global posted "$dir\Posted"
global tables "$dir\Tables"
global figures "$dir\Figures"

*=============================================================================*
*					 	    	Merging Datasets						      *
*=============================================================================*
* Preparing QoG for merged
use "$data\Qog.dta", clear

encode cname, gen(cntry)

// syncing country variable with Vdem country variable
recode cntry (3=3 "Algeria") (11=9 "Azerbaijan") (7=5 "Argentina") (9=7 "Australia") (8 = 6 "Armenia") (24=22 "Brazil") (16=15 "Belarus") (35=34 "Chile") (36=35 "China") (180=175 "Taiwan") (37=36 "Colombia") (46=41 "Cyprus") (53=47 "Ecuador") (58=52 "Estonia") (68=59 "Georgia") (69=61 "Germany") (72=62 "Ghana") (79=68 "Haiti") (83=77 "India") (86=80 "Iraq") (91=86 "Japan") (93=88 "Kazakhstan") (92=87 "Jordan") (97=165 "South Korea") (98=91 "Kuwait") (99=92 "Kyrgyzstan") (102=95 "Lebanon") (105=98 "Libya") (112=103 "Malaysia") (119=110 "Mexico") (125=115 "Morocco") (131=120 "Netherlands") (132=121 "New Zealand") (135=124 "Nigeria") (140=130 "Pakistan") (145=139 "Peru") (146=140 "Philippines") (147=142 "Poland") (149=144 "Qatar") (150=147 "Romania") (151=148 "Russia") (152=149 "Rwanda") (162=158 "Singapore") (164=160 "Slovenia") (167=164 "South Africa") (211=202 "Zimbabwe") (169=168 "Spain") (177=172 "Sweden") (183=178 "Thailand") (188=182 "Trinidad and Tobago") (189=183 "Tunesia") (190=184 "Turkey") (195=189 "Ukraine") (54=48 "Egypt") (198=192 "USA") (199=193 "Uruguay") (200=194 "Uzbekistan") (206=199 "Yemen") (nonm=.), gen(country)

drop if country==.

// keep only relevant years
keep if year>2009 & year<2017

// rename press freedom index
rename rsf_pfi pfi 

// keep only relevant variables
keep country year pfi

save "$data\QoG merge ready.dta", replace

* Preparing Vdem for merge
use "$data\V-Dem.dta", clear

encode country_name, gen(country) // encoding country to use for later merging

rename (v2mecenefm v2meharjrn v2meslfcen) (censor harass autocensor) //rename relevant vars

rename e_migdppc gdppc // rename gdp per capita

keep if year>2009 & year<2017 // drop irrelevant years
 
drop if (censor==. | harass==. | autocensor==.) // drop country year combinations with missing values

keep year country censor harass autocensor gdppc // keep only relevant vars

save "$data\V-Dem merge ready.dta", replace

* Preparing WVS for merge
use "$data\WV6.dta", clear

drop if V2==275 | V2==344 // dropping Palestine and Hong Kong

keep V2 V115 V116 V117 V217-V220 V84 V242 V240 V239 V248 V262 V258 // keep only relevant vars

rename (V115 V116 V117 V217 V218 V219 V220 V84 V242 V240 V262 V239 V248 V258) ///
(trstgov trstprt trstprl ppr mgz tv rd intpol age sex year income edu weights) // giving meaningful varnames
 
// syncing V2 with country variable of Vdem
recode V2 (12=3 "Algeria") (31=9 "Azerbaijan") (32=5 "Argentina") (36=7 "Australia") (51 = 6 "Armenia") (76=22 "Brazil") (112=15 "Belarus") (152=34 "Chile") (156=35 "China") (158=175 "Taiwan") (170=36 "Colombia") (196=41 "Cyprus") (218=47 "Ecuador") (233=52 "Estonia") (268=59 "Georgia") (276=61 "Germany") (288=62 "Ghana") (332=68 "Haiti") (356=77 "India") (368=80 "Iraq") (392=86 "Japan") (398=88 "Kazakhstan") (400=87 "Jordan") (410=165 "South Korea") (414=91 "Kuwait") (417=92 "Kyrgyzstan") (422=95 "Lebanon") (434=98 "Libya") (458=103 "Malaysia") (484=110 "Mexico") (504=115 "Morocco") (528=120 "Netherlands") (554=121 "New Zealand") (566=124 "Nigeria") (586=130 "Pakistan") (604=139 "Peru") (608=140 "Philippines") (616=142 "Poland") (634=144 "Qatar") (642=147 "Romania") (643=148 "Russia") (646=149 "Rwanda") (702=158 "Singapore") (705=160 "Slovenia") (710=164 "South Africa") (716=202 "Zimbabwe") (724=168 "Spain") (752=172 "Sweden") (764=178 "Thailand") (780=182 "Trinidad and Tobago") (788=183 "Tunesia") (792=184 "Turkey") (804=189 "Ukraine") (818=48 "Egypt") (840=192 "USA") (858=193 "Uruguay") (860=194 "Uzbekistan") (887=199 "Yemen"), gen(country)

save "$data\WVS merge ready.dta", replace

use "$data\WVS merge ready.dta", clear

merge m:1 country year using "$data\V-Dem merge ready.dta"

keep if _merge == 3
drop _merge

merge m:1 country year using "$data\QoG merge ready.dta"

keep if _merge == 3
drop _merge


save "$data\merged.dta", replace

*=============================================================================*
*					 			 	Recoding							      *
*=============================================================================*

* Recoding
use "$data\merged.dta", clear

// generating political trust variable
gen pol_trust = ((trstprl + trstgov + trstprt)/3)*-1+4 // Generate political trust variable
drop if pol_trust ==.
label var pol_trust "Political Trust"

// generate press freedom variable
factor censor harass autocensor // carry out factor analysis of three free press components
predict f1 // predict each country's score on latent freedom of press variable
gen freepress = ((f1+2.723055)/4.257231)*10 //transform scores linearly to range between 0 and 1
label var freepress "Press Freedom"

// recoding press freedom index so that higher values mean more freedom
gen p_f_i = (pfi*-1)+100
drop pfi
rename p_f_i pfi
label var pfi "Press Freedom Index"

// recoding media vars so that higher values mean more consumption
recode ppr (1=4 "Daily") (2=3 "Weekly") (3=2 "Monthly") (4=1 "Less than monthly") (5=0 "Never"), gen(newspaper)
label var newspaper "Newspaper consumption"

recode tv (1=4 "Daily") (2=3 "Weekly") (3=2 "Monthly") (4=1 "Less than monthly") (5=0 "Never"), gen(television)
label var television "Television consumption"

recode rd (1=4 "Daily") (2=3 "Weekly") (3=2 "Monthly") (4=1 "Less than monthly") (5=0 "Never"), gen(radio)
label var radio "Radio consumption"

// Recoding sex into male dummy variable
recode sex (2=0 "Female") (1=1 "Male"), gen(male)
label var male "Male"

// create centered age variable
center age
label var c_age "Age centred"

// Recode education to make it more easily interpretable
recode edu (1/2 = 0 "No completed education") (3/4=1 "Completed primary") (6=1) (5=2 "Completed lower secondary") (7/8=3 "Completed higher secondary") (9=4 "Completed tertiary"), gen(education)
label var education "Highest Education"

// Recode interest in politics so that higher values indicate higher interest
recode intpol (4=0 "Not at all interested") (3=1 "Not very interested") (2=2 "Somewhat interested") (1=3 "Very interested"), gen(pol_interest)
label var pol_interest "Political interest"

// Two ways of operationalising news consumption
gen massmedia2 = (newspaper+television+radio)/3 //average news consumption
label var massmedia2 "Average news consumption across media"

gen massmedia = max(newspaper, television, radio) // maximum news consumption
label var massmedia "Highest news consumption across media"

// Keep only relevant vars
keep pfi income male massmedia television newspaper radio age weights country pol_trust freepress c_age education pol_interest gdppc

keep if !missing(pfi, income, male, massmedia, television, newspaper, radio, age, weights, country, pol_trust, freepress, c_age, education, pol_interest)

save "$data\master.dta", replace
*=============================================================================*
*					 	 		Descriptives 	 							  *
*=============================================================================*
use "$data\master.dta", clear

// summary statistics
estpost sum pol_trust tele radio news income male freepress age education pol_interest [aweight=weights]
esttab . using "$tables/Table 1.rtf", ///
cells ("mean(fmt(2)) sd min(fmt(0)) max(fmt(0))") ///
label nonum title("Table 1. Summary statistics of variables") /// 
addnotes("Note: WVS 6, V-Dem, own calculations.") replace

// Figure showing variation in press freedom
preserve
egen pickone = tag(country)
twoway (scatter pfi free, sort mcolor(black) msize(2-pt)msymbol(smcircle) ///
mlabel(country) mlabsize(vsmall)) if pickone==1, scheme(cleanplots)
graph export "$figures/Figure 01.tif", replace
drop pickone
restore

*=============================================================================*
*							Testing for Assumptions 						  *
*=============================================================================*

use "$data\master.dta", clear

quietly mixed pol_trust income male tele radio news c_age education pol_interest freepress || [aweights= weights] country: tele radio news, cov(unstr)
	
* Generate 3 residuals 
predict linearp, xb // linear prediction
predict res, rstandard // Level-1 residual
predict BLUP_tele BLUP_radio BLUP_news BLUP_country, reffects // Level-2 slope residual, Level-2 intercept residual
label var BLUP_tele "BLUPs for television"
label var BLUP_radio "BLUPs for radio"
label var BLUP_news "BLUPs for newspaper"
label var BLUP_country "BLUPs for country"

// Level-1 residuals

* Residuals plotted against inverse normal
qnorm res, scheme(cleanplots)
graph export "$figures/figure 02 - Residuals Normal.tif", replace //export graph 

* Residuals histogram
hist res,   ///
	 normal scheme(cleanplots) ///
	 xtitle(Level-1 residuals)
graph export "$figures/figure 03 - Residuals Histo.tif", replace //export graph 

* Plotting residuals against predicted values
preserve
sample 2 // Take a 2 percent random sample
scatter res linearp, yline(0) scheme(cleanplots)
graph export "$figures/figure 04 - Residuals Pred.tif", replace //export graph 
restore


// Random Intercept residuals

egen pickone = tag(country)

* Residuals plotted against inverse normal
qnorm BLUP_country if pickone == 1, scheme(cleanplots)
graph export "$figures/figure 05 - Country Normal.tif", replace //export graph 

* Residuals histogram
hist BLUP_country if pickone == 1, ///
	 normal bin(9) scheme(cleanplots)             ///
	 xtitle(Level-2 intercept residuals)
graph export "$figures/figure 06 - Country Histo.tif", replace //export graph 

* Plotting residuals against predicted values
scatter BLUP_country linearp if pickone == 1, yline(0) scheme(cleanplots)
graph export "$figures/figure 07 - Country Pred.tif", replace //export graph 


// Television slope residuals

* Residuals plotted against inverse normal
qnorm BLUP_tele if pickone == 1, scheme(cleanplots)
graph export "$figures/figure 08 - Tele Norm.tif", replace //export graph 

* Residuals histogram
hist BLUP_tele if pickone == 1, ///
     normal bin(7) scheme(cleanplots)              ///
	 xtitle(Level-2 television slope residuals)
graph export "$figures/figure 09 - Tele Histo.tif", replace //export graph 

* Plotting residuals against predicted values
scatter BLUP_tele linearp if pickone == 1, yline(0) scheme(cleanplots)
graph export "$figures/figure 10 - Tele Pred.tif", replace //export graph 

// Radio slope residuals

* Residuals plotted against inverse normal
qnorm BLUP_radio if pickone == 1, scheme(cleanplots)
graph export "$figures/figure 11 - Radio Normal.tif", replace //export graph 

* Residuals histogram
hist BLUP_radio if pickone == 1, ///
     normal bin(7) scheme(cleanplots)               ///
	 xtitle(Level-2 radio slope residuals)
graph export "$figures/figure 12 - Radio Histo.tif", replace //export graph 

* Plotting residuals against predicted values
scatter BLUP_radio linearp if pickone == 1, yline(0) scheme(cleanplots)
graph export "$figures/figure 13 - Radio Pred.tif", replace //export graph 

// Newspaper slope residuals

* Residuals plotted against inverse normal
qnorm BLUP_news if pickone == 1, scheme(cleanplots)
graph export "$figures/figure 14 - News Normal.tif", replace //export graph 

* Residuals histogram
hist BLUP_news if pickone == 1, ///
     normal bin(7) scheme(cleanplots)               ///
	 xtitle(Level-2 newspaper slope residuals)
graph export "$figures/figure 15 - News Histo.tif", replace //export graph 

* Plotting residuals against predicted values
scatter BLUP_news linearp if pickone == 1, yline(0) scheme(cleanplots)
graph export "$figures/figure 16 - News Pred.tif", replace //export graph 

*=============================================================================*
*					 	 		Analysis 	 								  *
*=============================================================================*
use "$data\master.dta", clear

// Empty Model
mixed pol_trust || [aweights=weights] country:
eststo m0
esttab m0 using "$tables\table2.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 2. Null Model") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual", none) ///
se obslast addnotes("Note:  WVS 6 and V-Dem dataset") ///
label replace 

// Control Variables
mixed pol_trust income male c_age education pol_interest freepress|| [aweights= weights] country: 
eststo m1
esttab m1 using "$tables\table3.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 3. Individual-level variables") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual", none) ///
se obslast addnotes("Note: WVS 6 and V-Dem dataset") ///
label replace 

// Random-Intercept
mixed pol_trust income male tele radio news c_age education pol_interest freepress|| [aweights= weights] country: 
eststo m2
esttab m2 using "$tables\table4.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 4. Individual-level variables") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual", none) ///
se obslast addnotes("Note: WVS 6 and V-Dem dataset") ///
label replace 

// Random Slope Test // Each of the random slopes improves the model
preserve
foreach var of varlist tele radio news {
mixed pol_trust income male tele radio news c_age education pol_interest freepress || [aweights= weights] country: `var', var
eststo `var'
lrtest m0 `var'
} 
restore

// So the model will be specified with three random slopes
mixed pol_trust income male tele radio news c_age education pol_interest freepress || [aweights= weights] country: tele radio news
eststo m3
esttab m3 using "$tables\table5.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 5. Individual- and country-level variables") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual", none) ///
se obslast addnotes("Note: WVS 6 and V-Dem dataset") ///
label replace 

// Cross-level interaction
gen freextele = freep*tele
lab var freext "Free press*television"
gen freexradio = freep*radio
lab var freexr "Free press*radio"
gen freexnews = freep*news
lab var freexn "Free press*newspaper"

mixed pol_trust income male freepress tele radio news freext freexr freexn c_age education pol_interest || [aweights= weights] country: tele radio news
eststo m4
esttab m4 using "$tables\table6.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 6. Cross-level interactions") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual", none) ///
se obslast addnotes("Note: WVS 6 and V-Dem dataset") ///
label replace 

esttab using "$tables\table7.rtf", star(* 0.05 ** 0.01 *** 0.001) /// 
title("Table 7. Multilevel regression analysis") /// 
transform(ln*: exp(2*@) 2*exp(2*@)) ///
eqlabels("" "variance country" "variance individual" "Variance Television" "Variance Radio" "Variance Newspaper", none) ///
se obslast addnotes("Note: WVS 6 and V-Dem dataset") ///
label replace 

*=============================================================================*
*			 			Visualisation of Interaction 						  *
*=============================================================================*

*Plotting predicted effects of newspaper consumption 
quietly mixed pol_trust income male tele radio i.news##c.freepress c_age education pol_interest || [aweights= weights] country: tele radio news, mle var
margins, at(freep=(0(1)10) news=(0 4))
marginsplot, ///
	plot1opts(lcolor(black) lpattern(dash)) ///
	plot2opts(lcolor(black) lpattern(solid)) ///
	recastci(rarea) ///
	ci1opts(fcolor("102 194 165 %25") lcolor(white%0)) ///
	ci2opts(fcolor("255 153 51 %25") lcolor(white%0)) ///
	plotopts(plotregion(fcolor(white)) graphregion(fcolor(white)) xla(,grid) ///
	ytitle("Predicted Pol. Trust") ///
	title("none") ///
	legend(title("Newspaper consumption", size(medsmall)) col(3)) )
graph export "$figures/Figure 18.tif", replace //export graph 

* Plotting average marginal effects of reading newspaper daily
quietly mixed pol_trust income male tele radio i.news##c.freepress c_age education pol_interest || [aweights= weights] country: tele radio news, mle var
margins, dydx(newspaper) at(freepress=(0(1)10)) //calculate AMEs
marginsplot, ///
	yline(0, lpattern(solid)) ///
	plot1opts(lcolor("102 194 165 %0") lpattern(dash) msymbol(none)) ///
	plot2opts(lcolor("102 194 165 %0") lpattern(dash) msymbol(none)) ///
	plot3opts(lcolor("102 194 165 %0") lpattern(dash) msymbol(none)) ///
	plot4opts(lcolor(black) lpattern(dash)) ///
	recastci(rarea) ///
	ci1opts(fcolor("102 194 165 %0") lcolor(white%0)) ///
	ci2opts(fcolor("255 153 51 %0") lcolor(white%0)) ///
	ci3opts(fcolor("255 153 51 %0") lcolor(white%0)) ///
	ci4opts(fcolor("255 153 51 %25") lcolor(white%0)) ///
	plotopts(plotregion(fcolor(white)) graphregion(fcolor(white)) xla(,grid)) ///
	legend(off) ytitle("Marginal Effect on Political Trust")  ///
title("Marginal Effect of reading newspaper daily")
graph export "$figures/Figure 19.tif", replace //export graph 