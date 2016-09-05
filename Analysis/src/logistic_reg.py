#!usr/bin/env ipython

"""Load OSHA oil&gas big 5 violation data and run a logistic regression.

@author: Albert
@version: 0.1.1
@date: 08/24/16

The regression takes 1973-2004 data to predict 2005 and moving onwards.
The regression model is a single factor model of ``violation/inspection``.

TODO:
    * generalize preprocess.
    * Both industrial model and company model should be generalized, and put
    in different files.

"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
from sklearn.linear_model import LogisticRegression


def convert_accident_label_bernoulli(p):
    """Convert pct_penalty to accident label using bernoulli distribution.

    Args:
        p (float): percentage penalty in the industry.

    Returns:
        int: accident label; binary, 0 for safe, 1 for not safe.

    """

    label = stats.bernoulli.rvs(p)

    return label


def preprocess(data, training_index, test_index, threshold):
    """Preprocess the big 5 data.

    Only works for big 5 data. Naive treatment of time series by taking
    average.

    Args:
        data (pandas.DataFrame): data loaded from csv.

        training_index (str): a year index, separate the original data to
        training and test.

        test_index (str): a year index, separate the original data to
        training and test.

        threshold (float): a threshold penalty value that determines accident

    Returns:
        pandas.DataFrame: resulting training and test DataFrames.
    """

    parent_data = data.set_index('parent')

    # Company data
    berk = parent_data.loc['Berkshire Hathaway']
    bp = parent_data.loc['BP']
    exxon = parent_data.loc['EXXON MOBIL CORP']
    shell = parent_data.loc['Royal Dutch Shell']
    tesoro = parent_data.loc['Tesoro']

    # Development data
    berk_dev = berk.set_index('year').loc[:training_index]
    bp_dev = bp.set_index('year').loc[:training_index]
    exxon_dev = exxon.set_index('year').loc[:training_index]
    shell_dev = shell.set_index('year').loc[:training_index]
    tesoro_dev = tesoro.set_index('year').loc[:training_index]

    # Production data
    berk_prod = berk.set_index('year').loc[test_index:]
    bp_prod = bp.set_index('year').loc[test_index:]
    exxon_prod = exxon.set_index('year').loc[test_index:]
    shell_prod = shell.set_index('year').loc[test_index:]
    tesoro_prod = tesoro.set_index('year').loc[test_index:]

    # Take average of each factor, naive treatment
    berk_mean = berk_dev.mean()
    bp_mean = bp_dev.mean()
    exxon_mean = exxon_dev.mean()
    shell_mean = shell_dev.mean()
    tesoro_mean = tesoro_dev.mean()

    dev_dict = {'Berkshire Hathaway': berk_mean,
                'BP': bp_mean,
                'EXXON MOBIL CORP': exxon_mean,
                'Royal Dutch Shell': shell_mean,
                'Tesoro': tesoro_mean}

    data_dev = pd.DataFrame.from_dict(dev_dict).transpose()

    temp_label = list()
    for i, val in enumerate(data_dev.total_penalties.values.tolist()):
        if val >= threshold:
            temp_label.append(1)
        else:
            temp_label.append(0)

    data_dev['accident_label'] = temp_label

    return data_dev, berk_prod, bp_prod, exxon_prod, shell_prod, tesoro_prod


def preprocess_single_company(data, comp_name, training_index, 
                                  test_index, threshold):
    """Preprocess the single company data.

    Only works for big 5 data. Naive treatment of time series by taking
    average.

    Args:
        data (pandas.DataFrame): data loaded from csv.

        comp_name (str): company name.

        training_index (str): a year index, separate the original data to
        training and test.

        test_index (str): a year index, separate the original data to
        training and test.

        threshold (float): a threshold penalty value that determines accident

    Returns:
        pandas.DataFrame: resulting training and test DataFrames.
    """

    parent_data = data.set_index('parent')

    temp_comp = parent_data.loc[comp_name]
    temp_dev = temp_comp.set_index('year').loc[:training_index]
    temp_prod = temp_comp.set_index('year').loc[test_index:]

    temp_label = list()
    for i, val in enumerate(temp_dev.total_penalties.values.tolist()):
        if val >= threshold:
            temp_label.append(1)
        else:
            temp_label.append(0)

    temp_dev['accident_label'] = temp_label

    return temp_dev, temp_prod


if __name__ == "__main__":
    dataset = ['../data/oil_and_gas_violators_v1.csv',
               '../data/ViolationTracker_publicdataset_2aug16_maindata.csv']

    # Use dataset[0]
    data = pd.read_csv(dataset[0], sep=',', header=0)

    colname = data.columns.values.tolist()

    year_data = data.set_index('year')

    np.random.seed(100)

    # Test 1, use averaged big 5 data
    #processed_data = preprocess(data, '2004', '2005', 10000)
    #data_dev = processed_data[0]
    #bp_prod = processed_data[2]

    # Test 2, use BP time series data
    # Use 2003 before data as training, use 2004 to predict 2005, etc.
    processed_data = preprocess_single_company(data, 
                                               'BP', '2003', 
                                               '2004', 10000)
    data_dev = processed_data[0]
    bp_prod = processed_data[1]

    # logistic regression
    x_dev = data_dev['viols_per_inspection'].as_matrix()
    x_train = np.vstack(x_dev)
    y_train = data_dev['accident_label'].as_matrix()

    x_prod = bp_prod['viols_per_inspection'].as_matrix()
    bp_test = np.vstack(x_prod)

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)
    prob = lr.predict_proba(bp_test)
    prediction = lr.predict(bp_test)

    years = bp_prod.reset_index().year.values.tolist()
    years = [x+1 for x in years]

    # Plot predication vs. year
    plt.xlim(2003, 2017)
    plt.ylim(-0.5, 1.5)
    plt.plot(years, prediction, 'bs')
    plt.show()
