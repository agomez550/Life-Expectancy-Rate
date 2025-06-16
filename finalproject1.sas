
/*Uploaded the data from an Excel file */
PROC IMPORT OUT= WORK.testing 
            DATAFILE= "C:\Users\bi\Documents\biostats2\Life Expectancy D
ata1.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="'Life Expectancy Data1$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


/*Separated life expectancy averages and country status in two binary outcomes */
data life;
	set WORK.testing;
	if  Life_expectancy<73.4 then Life_category= 0;
	else if Life_expectancy>=73.4 then Life_category= 1; 
	if Status= 'Developed' then Status_A= 1;
	else if Status='Developing' then Status_A=0; 
run; 



/*Statistic summary of life expectancy according to country and Status in powerpoint */
proc means data=WORK.testing n mean std min max maxdec=2 ;
    class Country Status; 
	var Life_expectancy ; 
run; 

proc glm data=WORK.testing;
    class Country Status Year;
    model Life_expectancy = Adult_Mortality Status Country Hepatitis_B Polio Diphtheria BMI ;
run;

/* Bar Graphs in powerpoint*/ 
title 'Average Life Expectancy';
proc sgplot data=WORK.testing;
vbar Country / response= Life_expectancy stat=mean  barwidth=.5 ; 
run; 

title 'Status';
proc sgplot data=WORK.testing;
vbar Status / response= Life_expectancy stat=mean  barwidth=.5 ; 
run; 

/*Full Model Figure 1 and 2 */ 
proc logistic data=life;
	class Country Status_A; 
	model Life_category(ref='1') = Adult_Mortality Country Status_A Hepatitis_B Polio Diphtheria BMI; 
run; 

proc logistic data=life;
	class Country(ref='United States of America') Status(ref='Developed') / param= reference; 
	model Life_category(ref='1') = Adult_Mortality Status Country Hepatitis_B Polio Diphtheria BMI; 
run; 


/*Reduced Model Figure 3 and 5 */ 

proc logistic data=life;
	class  Status(ref='Developed') / param= reference; 
	model Life_category(ref='1') = Adult_Mortality Status Hepatitis_B Polio Diphtheria BMI; 
run; 


proc logistic data=life;
	model Life_category(ref='1') = Adult_Mortality Hepatitis_B Polio Diphtheria BMI; 
run; 


proc logistic data=life;
	model Life_category(ref='1') = Adult_Mortality Polio Diphtheria BMI; 
run; 


proc logistic data=life;
	model Life_category(ref='1') = Adult_Mortality Diphtheria BMI; 
run; 



 
/* Goodness-of-fit for model with continous covariates Figure 2 */ 
proc logistic data=life; 
class Country(ref='United States of America') Status(ref='Developed') / Param= Reference; 
model Life_category(ref='0') = Adult_Mortality Status Country Hepatitis_B Polio Diphtheria BMI /lackfit rsq;
output out=pred1 p=pred_prob;
run; 


proc logistic data=life;
	model Life_category(event='1')= Adult_Mortality Diphtheria BMI / lackfit rsq; 
	output out=pred2 p=pred_prob;
run; 

/*Calibration curve Figure 4 */
proc sql; 
	create table pred as
	select *, 1 as model from pred1
	outer union corr
	select *, 2 as model from pred2 
	order by model, pred_prob; 
quit; 

proc loess data= pred;
   by model;  
   model Life_category = pred_prob /smooth=0.75 degree =2; 
   ods output OutputStatistics = out; 
run; 

title 'Calibration curve';
ods graphics /width=5in height=3.5in;
proc sgplot data=out; 
lineparm x=0 y=0 slope=1;
series x=pred_prob y=pred / group=model markers markerattrs= (symbol=circle size=3) lineattrs=(thickness=1) name='plot';
xaxis label='Predicted Probability' labelattrs=(size=12) valueattrs=(size=12) values=(0 to 1 by 0.2);
yaxis label='Observed Probability' labelattrs=(size=12) valueattrs=(size=12) values=(0 to 1 by 0.2);
keylegend 'plot' / position= bottomright location=inside title='Model' valueattrs=(size=12) titleattrs=(size=12) across=1 noborder;
run; 

/* ROCplot Figure 4 */ 
proc logistic data=life;
	model Life_category (ref='1')= Adult_Mortality Diphtheria BMI / outroc= rocdata; 
run; 
ods graphics off; 
proc print data=rocdata;
run; 

ods graphics /height=6in width=6in; 
proc sgplot data=rocdata noautolegend;
 title 'UIS ROC CURVE'; 
 title 'Area Under the Curve= 0.9673';
 step y=_sensit_ x=_1mspec_ /lineattrs=(thickness=2 color=blue);
 lineparm x=0 y=0 slope=1 / lineattrs=(thickness=2 color=gray);
 xaxis grid valueattrs=(size=12) labelattrs=(size=12);
 yaxis grid valueattrs=(size=12) labelattrs=(size=12);
run; 
ods graphics off; 

/* 2x2 table */ 
proc freq order=data data=life; 
	tables Status_A*Life_category / chisq nopercent norow  expected relrisk cmh; 
run;

proc logistic data=life;
	class  Status_A(ref='1'); 
	model Life_category(ref='1') = Status_A; 
run; 

