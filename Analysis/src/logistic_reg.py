#!usr/bin/env ipython

"""Load MSHA data and run a logistic regression.

@author: Albert
@version: 0.0.0
@date: 09/05/16

"""

import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap


def plot_decision_regions(X, y, classifier, resolution=0.02):

    # setup marker generator and color map
    markers = ('s', 'x', 'o', '^', 'v')
    colors = ('red', 'blue', 'lightgreen', 'gray', 'cyan')
    cmap = ListedColormap(colors[:len(np.unique(y))])

    # plot the decision surface
    x1_min, x1_max = X[:, 0].min() - 1, X[:, 0].max() + 1
    x2_min, x2_max = X[:, 1].min() - 1, X[:, 1].max() + 1
    xx1, xx2 = np.meshgrid(np.arange(x1_min, x1_max, resolution),
                           np.arange(x2_min, x2_max, resolution))
    Z = classifier.predict(np.array([xx1.ravel(), xx2.ravel()]).T)
    Z = Z.reshape(xx1.shape)
    plt.contourf(xx1, xx2, Z, alpha=0.4, cmap=cmap)
    plt.xlim(xx1.min(), xx1.max())
    plt.ylim(xx2.min(), xx2.max())

    # plot class samples
    for idx, cl in enumerate(np.unique(y)):
        plt.scatter(x=X[y == cl, 0], y=X[y == cl, 1],
                    alpha=0.8, c=cmap(idx),
                    marker=markers[idx], label=cl)


def test_1(data_file_path):
    """Test using `simulated_y2000_mine_data.csv`.

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
    prediction = lr.predict(x_test)

    return prediction


def test_2(data_file_path, feature_name):
    """Test for all mining data.

    Use an artificial ``accident_label``.

    Data:
        Recent_5_Mine_Accidents_Data.csv

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


def test_3(training_file_path, test_file_path, feature_name):
    """Try new input data frame.

    Use `y_{t+1} vs. x_t`

    Data:
        Recent_5_Mine_Accidents_Data_training.csv',
        Recent_5_Mine_Accidents_Data_test.csv'

    """
    data_training = pd.read_csv(training_file_path)
    data_test = pd.read_csv(test_file_path)

    x_dev = data_training[feature_name].as_matrix()
    x_train = np.vstack(x_dev)
    y_train = data_training['accident_label_t_plus_1'].as_matrix()

    x_prod = data_test[feature_name].as_matrix()
    x_test = np.vstack(x_prod)

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)
    prediction = lr.predict(x_test)

    return prediction


def test_4(training_file_path, feature_list):
    """Plot two-feature decision boundary.

    Data:
        Recent_5_Mine_Accidents_Data_training.csv

    """
    data_training = pd.read_csv(training_file_path)
    data_training.fillna(0, inplace=True)

    data_training[feature_list[2]] = np.log(data_training[feature_list[2]] + 1)
    x_train = data_training[[feature_list[0], feature_list[2]]].values
    y_train = data_training['accident_label_t_plus_1'].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr, resolution=0.5)
    plt.xlabel(feature_list[0])
    plt.ylabel('log of ' + feature_list[2])
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_5(training_file_path, feature_list):
    """Plot two-feature decision boundary.

    Data:
        Recent_5_Mine_Accidents_Data_training_2.csv

    """
    data_training = pd.read_csv(training_file_path)
    data_training.fillna(0)

    x_train = data_training[feature_list[0:2]].values
    y_train = data_training['accident_label_t_plus_1'].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr, resolution=0.5)
    plt.xlabel(feature_list[0])
    plt.ylabel(feature_list[1])
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


if __name__ == "__main__":
    dataset = ['../data/simulated_y2000_mine_data.csv',
               '../data/Recent_5_Mine_Accidents_Data.csv',
               '../data/Recent_5_Mine_Accidents_Data_training.csv',
               '../data/Recent_5_Mine_Accidents_Data_test.csv',
               '../data/Recent_5_Mine_Accidents_Data_training_2.csv',
               '../data/top_5_accident_mines_processed.csv']
    feature_list = ['num_violations',
                    'num_violations_t_minus_1',
                    'total_penalties']

    np.random.seed(100)

    # print(test_1(dataset[0]))
    # print(test_2(dataset[1], feature_list[0]))
    # print(test_3(dataset[2], dataset[3], feature_list[0]))
    test_4(dataset[5], feature_list)
    test_5(dataset[4], feature_list)
