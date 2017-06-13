# Violation Data Analysis

Often, safety condition of a mine deteriorates before an accident happens. For example, before the 2010 Upper Big Branch Mine disaster, one of the largest in the U.S. history, the mine displayed an alarming rising trend of safety violations. Similar building-up behaviors apply to other major mining accidents in the U.S. According to the Mine Safety and Health Administration (MSHA), on average, there are more than a hundred thousand citations and orders issued yearly. The MSHA accident and inspection databases are an untapped resource for safety analysis. Our model analyzes semi-structured data from MSHA, attempting to uncover a company's safety culture from its public regulatory records. This work has implications for developing a data-driven early warning system. In the future, we plan to extend this research to inspection data from the Occupational Safety and Health Administration (OSHA) and the Environmental Protection Agency (EPA).

## Goal Statement

Create a statistical model as follows:

- Training data: historical data of mines, mine accidents, and MSHA violations
- Input: mine type, (mine identifier), past data of this mine, i.e., accidents and violations
- Output: chance of this mine to have a severe (resulting fatality or disability) accident in the future

## Data Source(s)

- Current data set used for this project: https://arlweb.msha.gov/OpenGovernmentData/OGIMSHA.asp
- Other data set: https://enforcedata.dol.gov/views/data_catalogs.php

## R Code Structure ("Project Houston")

- Main script
    + `/Houston/src/main.R`
- Subsidiary scripts
    + `/Houston/src/import_msha_txt.R`
    + `/Houston/src/consolidate_data.R`
    + `/Houston/src/conditional_logistic.R`
- Function scripts
    + `/Houston/src/prepare_violation.R`
    + `/Houston/src/roll_over.R`

## Current Tasks

- Edit `/Houston/src/conditional_logistic.R`
    + Add a section with `clogit` on `strata(MINE_ID)`
    + Save as `in_sample_model_mine_id`
    + Rename `in_sample_model` as `in_sample_model_mine_type` (also rename `out_sample_model`)
- Create `/Houston/src/test_clogit_model.R` to test on the latest MSHA data

## Updates

#### 06/12/2017

- Minor edits on Catherine's codes
    + Added `/Houston/src/main.R`
    + Replaced `load()` and `.RData` with `source()` and `.R` to import functions
    + Fixed a problem where extracted `.txt` files are not deleted in `/Houston/src/import_msha_txt.R`
    + Added `out_sample_model` in `/Houston/src/conditional_logistic.R`