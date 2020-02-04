# A descriptive analysis of health care use by high cost children and young people in England

This project analyses the distribution of both primary and seconday health care costs in England. We identified the top 5% of children and young people of health care services by cost, using a large nationally representative sample from the Clinical Practice Research Datalink (CPRD). 

#### Project Status: In progress

## Project Description

Little is known about how health spending is distributed amongst the population or how we can identify children and young people at risk of requiring higher spending. Our study aims firstly to identify total health spending costs and relative differences across services for the top 5% of high cost children and young people and secondly to characterise the features of this group. 

This analysis is an extention of a [working paper](https://www.health.org.uk/publications/a-descriptive-analysis-of-health-care-use-by-high-cost-high-need-patients-in-england) which analysed the distribution of both primary and seconday health care costs in England.

## Data source

We used data from the Clinical Practice Research Datalink (CPRD) linked to Hospital Episode Statistics (HES) - ISAC protocol number [17_150R](https://www.cprd.com/protocol/high-need-patients-chronic-conditions-primary-and-secondary-care-utilisation-and-costs). We also used [NHS reference costs](improvement.nhs.uk/resources/reference-costs/) and [PSSRU unit costs](www.pssru.ac.uk/project-pages/unit-costs/2015/index.php) to cost the clinical records. Futher detail in the references section below.

Data used for this analysis were anonymised in line with the ICO's Anonymisation Code of Practice. The data were accessed in The Health Foundation's Secure Data Environment, which is a secure data analysis facility (accredited for the ISO27001 information security standard, and recognised for the NHS Digital Data Security and Protection Toolkit). No information that could directly identify a patient or other individual was used.  For ease of undertaking analysis, data objects may have been labelled e.g. 'patient_ID'.  These do not refer to NHS IDs or other identifiable patient data.

## How does it work?

As the data used for this analysis is not publically available, this code cannot be used to replicate the analysis on this dataset. However, with modifications the code will be able to be used on other patient-level CPRD extracts. 

### Requirements

These scripts were written in SAS Enterprise Guide Version 7.12 and RStudio Version 1.1.383. 
The following R packages are used: 

* **[haven](https://cran.r-project.org/web/packages/haven/index.html)**
* **[here](https://cran.r-project.org/web/packages/here/index.html)**
* **[tidyverse](https://cran.r-project.org/web/packages/tidyverse/index.html)**
* **[naniar](https://cran.r-project.org/web/packages/naniar/index.html)**
* **[tidylog](https://cran.r-project.org/web/packages/tidylog/index.html)**

### Getting started

This project is based on the results of our original [high cost user analysis](https://github.com/HFAnalyticsLab/High_cost_users). This code should be modified and run first before using the scripts in this repository.

The SAS script (Identify_CYP) should be run on the results of the orignial analysis to identify the CYP cohort.

The two R scripts contain code for the descriptive analysis:

* **00_descriptives** - descriptive statistics of the top 5% and bottom 95% of the population.
* **01_comborbidities** - creates comorbidity flags and runs descriptive statistics on comorbidities.

## Useful references

1. Curtis L, Burns A. Unit Costs of Health and Social Care 2015. p. 177 & p. 174 Kent: Personal Social Services Research Unit; 2015. [www.pssru.ac.uk/project-pages/unit-costs/2015/index.php](www.pssru.ac.uk/project-pages/unit-costs/2015/index.php). Accessed December 20, 2015

2. NHS Improvement. NHS Reference Costs. [improvement.nhs.uk/resources/reference-costs/](improvement.nhs.uk/resources/reference-costs/). Published 2017. Accessed April 13, 2018.

3. NHS Digital. HRG4+ 2017/18 Reference Costs Grouper. [digital.nhs.uk/services/national-casemix-office/downloads-groupers-and-tools/costing-hrg4-2017-18-reference-costs-grouper](digital.nhs.uk/services/national-casemix-office/downloads-groupers-and-tools/costing-hrg4-2017-18-reference-costs-grouper). Accessed April 12, 2019.

4. Wiljaars L, Gilbert R, Hardelid P. Chronic conditions in children and young people: learning from administrative data. Archives of Disease in Childhood. 2016;101:881-885 [https://adc.bmj.com/content/101/10/881](https://adc.bmj.com/content/101/10/881)

## Authors - please feel free to get in touch

* **Kathryn Dreyer** - [@kathrynadreyer](https://twitter.com/kathrynadreyer) - [kathdreyer](https://github.com/kathdreyer)

## License

This project is licensed under the [MIT License](LICENSE.md).

## Acknowledgments

This project is in collaboration with Dr Dougal Hargreaves and Dr Thomas Beaney at Imperial College London.

