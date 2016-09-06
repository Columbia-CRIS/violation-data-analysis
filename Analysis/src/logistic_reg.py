#!usr/bin/env ipython

"""Load MSHA data and run a logistic regression.

@author: Albert
@version: 0.0.0
@date: 09/05/16

"""

import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression


def test_1(data_file_path):
    """Test for `simulated_y2000_mine_data.csv`.
    """
    data = pd.read_csv(data_file_path, sep=',', header=0)

    # logistic regression
    x_dev = data['Sum of num_violations'].as_matrix()
    x_train = np.vstack(x_dev)
    y_train = data['accident_label_t_plus_1'].as_matrix()

    x_prod = data['Sum of num_violation_t_plus_1'].as_matrix()
    x_test = np.vstack(x_prod)

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)
    #prob = lr.predict_proba(x_test)
    prediction = lr.predict(x_test)

    return prediction


def test_2(data_file_path, feature_name):
    """Test for all mining data.
    
    Use an artificial ``accident_label``.
    """
    data = pd.read_csv(data_file_path, sep=',', header=0)

    msk = np.random.rand(len(data)) < 0.8
    x_dev = data[msk][feature_name].as_matrix()
    x_train = np.vstack(x_dev)
    y_train = data[msk]['accident_label'].as_matrix()

    x_prod = data[~msk][feature_name].as_matrix()
    x_test = np.vstack(x_prod)

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)
    prediction = lr.predict(x_test)

    return prediction


if __name__ == "__main__":
    dataset = ['../data/simulated_y2000_mine_data.csv',
               '../data/Recent_5_Mine_Accidents_Data.csv']

    np.random.seed(100)

    print(test_1(dataset[0]))
    print(test_2(dataset[1], 'num_violations'))
