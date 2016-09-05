#!usr/bin/env ipython

"""Load oil&gas big 5 violation data and run a logistic regression.

@author: Albert
@version: 0.0
@date: 08/19/16

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


if __name__ == "__main__":
    dataset = ['../data/oil_and_gas_violators_v1.csv']

    # Use dataset[0]
    data = pd.read_csv(dataset[0], sep=',', header=0)

    colname = data.columns.values.tolist()

    year_data = data.set_index('year')

    parent_data = data.set_index('parent')

    # Company data
    berk = parent_data.loc['Berkshire Hathaway']
    bp = parent_data.loc['BP']
    exxon = parent_data.loc['EXXON MOBIL CORP']
    shell = parent_data.loc['Royal Dutch Shell']
    tesoro = parent_data.loc['Tesoro']

    # Development data
    berk_dev = berk.set_index('year').loc[:'2010']
    bp_dev = bp.set_index('year').loc[:'2010']
    exxon_dev = exxon.set_index('year').loc[:'2010']
    shell_dev = shell.set_index('year').loc[:'2010']
    tesoro_dev = tesoro.set_index('year').loc[:'2010']

    # Production data
    berk_prod = berk.set_index('year').loc['2011':]
    bp_prod = bp.set_index('year').loc['2011':]
    exxon_prod = exxon.set_index('year').loc['2011':]
    shell_prod = shell.set_index('year').loc['2011':]
    tesoro_prod = tesoro.set_index('year').loc['2011':]


    #-------------------------------
    #### Treatment - first trail ###
    #-------------------------------
    # Take average of each factor
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

    # Add a label based on penalty
    # A naive way to make accident label is use bernoulli dist convert penalty
    #     percentage to binary label.
    penalty_sum = sum(data_dev.total_penalties)
    data_dev['pct_penalty'] = data_dev.total_penalties / penalty_sum

    np.random.seed(100)

    data_dev['accident_label'] = convert_accident_label_bernoulli(
                                     data_dev.pct_penalty)


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
    print(prediction)

    years = bp_prod.reset_index().year.values.tolist()
    #Plot predication vs. year
    plt.xlim(2010, 2017)
    plt.ylim(-0.5, 1.5)
    plt.plot(years, prediction, 'bs')
    plt.show()
