# project-portfolio

Hi! I’m a Master ESA student (Econometrics & Applied Statistics) at the University of Orléans.  
This repository collects selected projects in **Python / R / SAS**: data preparation, econometrics, time series, and machine learning.  
All examples use **synthetic or anonymised data** (or public datasets) to respect confidentiality.

---

## What you’ll find here

- **projects/** – project folders with code, short READMEs, and minimal data samples  
  - `insee-housing/` – Python pipeline: large-scale cleaning (10M+ rows originally), data validation, joins with salary/territorial metadata, indicators by employment zone, and a simple OLS example.  
  - `r-shiny-credit/` – R Shiny app for credit-risk scoring on the UCI dataset: data exploration, logistic regression, ROC/AUC, and a small “personalised prediction” tool.  
  - *(more to come: scoring (LCL), IFRS9 time-series (Nexialog/Mobilize), climate stress test (Square Management), geopolitics & credit risk (Deloitte DRIM))*  
- **demo/** – short demo assets (MP4/GIF) when useful
- **reports/** – light figures or slides generated from the code (no sensitive material)

---

## Skills demonstrated

- **Data management**: collection, cleaning, validation, aggregation, simple business-rule checks  
- **Econometrics & stats**: OLS, logistic regression, panel/time-series basics  
- **ML basics**: scoring models, model evaluation (ROC/AUC, error rate)  
- **Tooling**: Python (pandas, numpy, matplotlib, statsmodels), R (tidyverse, Shiny, pROC), SAS (SQL/procs)  
- **Reproducibility**: clear folder structure, small synthetic samples, README instructions

---

## Quick demos

- **R Shiny – Credit Risk**: *(video demo)*  
  `[demo/Video_R_shinny_application.mp4]` (or YouTube link if hosted externally)

- **INSEE Housing**: high-level walkthrough in `projects/insee-housing/README.md`

---

##  How to run locally

### Python (example: INSEE Housing)
```bash
cd projects/insee-housing
# create/activate your env if you wish
pip install -r requirements.txt   # or install pandas, numpy, matplotlib, statsmodels
python src/insee_simplify_code.py
