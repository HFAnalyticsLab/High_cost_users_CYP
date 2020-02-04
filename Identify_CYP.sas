libname descpap "...\SAS\Data\revised\";

%let age_limit = 25;

/*Import data*/
data finalcosts;
	set descpap.finalcosts;
	where startage < &age_limit;
run;

/*Checks on sample size*/
proc sql;
	create table children as
	select top5,
			count(patid) as count
	from finalcosts
	group by top5;
run;

proc sql;
	create table ages as 
	select startage,
			count(patid) as count
	from finalcosts
	where top5 = "top 5%"
	group by startage;
run;

/*set new age category*/
data finalcosts2; 
	set finalcosts;
	format age_cat2 $5.;
	age_cat2 = 'NA';
	if startage < 5 then age_cat = '<5';
	else if startage >= 5 and startage < 10 then age_cat2 = '5-9';
	else if startage >= 10 and startage < 15 then age_cat2 = '10-14';
	else if startage >= 15 and startage < 20 then age_cat2 = '15-19';
	else if startage >= 20 and startage < 25 then age_cat2 = '20-24';
run;


proc sql;
	create table ages2 as
	select age_cat2,
			count(patid) as count
	from finalcosts2
	where top5 = "top 5%"
	group by age_cat2;
run;

/*set new top 5%*/
PROC RANK DATA=finalcosts2 OUT=percentile TIEs=high GROUPS=100;
	VAR finalcost;
	RANKS fcperc2;
RUN;

data finalcosts3;
	set percentile;
	FORMAT c_top5 $10.;
	IF fcperc2>=95 THEN c_top5 ='top 5%';
	ELSE c_top5 = 'bottom 95%';
run;

/*Checks on sample size*/
proc sql;
	create table children2 as
	select c_top5,
			count(patid) as count
	from finalcosts3
	group by c_top5;
run;