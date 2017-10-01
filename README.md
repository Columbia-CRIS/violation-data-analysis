# A Data-Driven Early Warning System for Mining Accidents

## Background

Often, safety condition of a mine deteriorates before an accident happens. For example, before the 2010 Upper Big Branch Mine disaster, one of the largest in the U.S. history, the mine displayed an alarming rising trend of safety violations. Similar building-up behaviors apply to other major mining accidents in the U.S. According to the Mine Safety and Health Administration (MSHA), on average, there are more than a hundred thousand citations and orders issued yearly. The MSHA accident and inspection databases are an untapped resource for safety analysis. Our model analyzes semi-structured data from MSHA, attempting to uncover a company's safety culture from its public regulatory records. This work has implications for developing a data-driven early warning system. In the future, we plan to extend this research to inspection data from the Occupational Safety and Health Administration (OSHA) and the Environmental Protection Agency (EPA).

## Goal Statement 

Create a statistical model as follows:

- Training data: historical data of mines, mine accidents, and MSHA violations
- Input: mine type (or mine identifier), past data of this mine, i.e., accidents and violations
- Output: chance of this mine to have a severe (resulting fatality or disability) accident in the future

## Data Source

- Current data set used for this project: https://arlweb.msha.gov/OpenGovernmentData/OGIMSHA.asp
- Other data set: https://enforcedata.dol.gov/views/data_catalogs.php
- **IMPORTANT**: [arlweb.msha.gov](arlweb.msha.gov) no longer includes proper headers in their data dumps (i.e., the first row contains actual values instead of column names). 
- Old data sets are uploaded to GitHub via Git Large File Storage (LFS). [Install](https://git-lfs.github.com) Git LFS to work with large files.

## Repository Hierarchy

|Description|Working directory|Sub-directory|File|
|:-|:-|:-|:-|
|Main script|[`./Houston/`](Houston/)|[`src/`](Houston/src/)|[`main.R`](Houston/src/main.R)|
|Data consolidation|||[`consolidate_data.R`](Houston/src/consolidate_data.R)|
|Statistical model|||[`conditional_logistic.R`](Houston/src/conditional_logistic.R)|
|Function 1|||[`prepare_violation.R`](Houston/src/prepare_violation.R)|
|Function 2|||[`roll_over.R`](/Houston/src/roll_over.R)
|Consolidated data||[`output/`](Houston/output/)|[`Consolidated.RData`](Houston/output/Consolidated.RData)|
|Result|||[`Result_clogit.RData`](Houston/output/Result_clogit.RData)|
|Mine data||[`data/`](Houston/data/)|[`Mines.RData`](Houston/data/Mines.RData)|
|Accident data|||[`Accidents.RData`](Houston/data/Accidents.RData)|
|Violation data|||[`AssessedViolations.RData`](Houston/data/AssessedViolations.RData)|

- Required R packages: `caret`, `dplyr`, `e1071`, `RcppRoll`, `plm`, `survival`

## Manuscript

- Work in progress. Contact Yu.

## Updates

#### 2017-10-01

- The MSHA data website we used before ([link](arlweb.msha.gov)) no longer offers proper headers for their txt data dumps. We will not update our processed data (`.RData`) any more.
- Accidents, violations, and mines were updated on 2017-04-08.
- They are uploaded to GitHub via Git Large File Storage ([LFS](https://git-lfs.github.com)).

#### 2017-06-13

- Updated `README.md`

#### 2017-06-12

- Minor edits on Catherine's codes
    + Added `/Houston/src/main.R`
    + Replaced `load()` and `.RData` with `source()` and `.R` to import functions
    + Fixed a problem where extracted `.txt` files are not deleted in `/Houston/src/import_msha_txt.R`
    + Added `out_sample_model` in `/Houston/src/conditional_logistic.R`