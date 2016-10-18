#!usr/bin/env ipython

"""Load MSHA data and run a logistic regression.

@author: Albert
@version: 0.0.2
@date: 10/17/16

Note:
    data file path is relative, use your own data file path

"""

import pandas as pd
import numpy as np
from sklearn import cross_validation
from sklearn.linear_model import LogisticRegression
from sklearn.learning_curve import learning_curve
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap


def plot_decision_regions(X, y, classifier, resolution=0.02):
    """Plot decision regions for binary features.

    """
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


def plot_learning_curve(estimator, title, X, y, ylim=None, cv=None,
                        n_jobs=1, train_sizes=np.linspace(.1, 1.0, 5)):
    """Generate a simple plot of the test and traning learning curve.

    Parameters:
        estimator : object type that implements the "fit" and "predict" methods
            An object of that type which is cloned for each validation.

        title : string
            Title for the chart.

        X : array-like, shape (n_samples, n_features)
            Training vector, where n_samples is the number of samples and
            n_features is the number of features.

        y : array-like, shape (n_samples) or (n_samples, n_features), optional
            Target relative to X for classification or regression;
            None for unsupervised learning.

        ylim : tuple, shape (ymin, ymax), optional
            Defines minimum and maximum yvalues plotted.

        cv : integer, cross-validation generator, optional
            If an integer is passed, it is the number of folds (defaults to 3).
            Specific cross-validation objects can be passed, see
            sklearn.cross_validation module for the list of possible objects

        n_jobs : integer, optional
            Number of jobs to run in parallel (default 1).

    """
    plt.figure()
    plt.title(title)
    if ylim is not None:
        plt.ylim(*ylim)
    plt.xlabel("Training examples")
    plt.ylabel("Score")
    train_sizes, train_scores, test_scores = learning_curve(
        estimator, X, y, cv=cv, n_jobs=n_jobs, train_sizes=train_sizes)
    train_scores_mean = np.mean(train_scores, axis=1)
    train_scores_std = np.std(train_scores, axis=1)
    test_scores_mean = np.mean(test_scores, axis=1)
    test_scores_std = np.std(test_scores, axis=1)
    plt.grid()

    plt.fill_between(train_sizes, train_scores_mean - train_scores_std,
                     train_scores_mean + train_scores_std, alpha=0.1,
                     color="r")
    plt.fill_between(train_sizes, test_scores_mean - test_scores_std,
                     test_scores_mean + test_scores_std, alpha=0.1, color="g")
    plt.plot(train_sizes, train_scores_mean, 'o-', color="r",
             label="Training score")
    plt.plot(train_sizes, test_scores_mean, 'o-', color="g",
             label="Cross-validation score")

    plt.legend(loc="best")
    return plt


def test_1(data_file_path, resolution=0.5, *args):
    """Plot two-feature decision boundary.

    ``log(penalty)`` vs. ``num_violation``

    Data:
        `top_5_accident_mines_geq_30.csv`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0, inplace=True)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    data[feature2] = np.log(data[feature2] + 1)
    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel('log of ' + feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_2(data_file_path, resolution=0.5, *args):
    """Plot two-feature decision boundary.

    ``num_violation_t`` vs. ``num_violation_t_minus_1``

    Data:
        `Recent_5_Mine_Accidents_Data_training_2.csv`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel(feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_3(data_file_path, *args):
    """Check whether label is reasonable.

    Plot ``num_violation`` vs. ``accident_label_t_plus_1``

    Data:
        `top_5_accident_mines_geq_80.csv`

    """
    data = pd.read_csv(data_file_path)

    feature1 = args[0]
    label = args[1]

    acc_label = data[label]
    x_val = data[feature1]

    plt.scatter(x_val, acc_label)
    plt.xlabel(feature1)
    plt.ylabel(label)
    plt.ylim(-0.5, 1.5)
    # plt.legend(loc='upper left')

    plt.show()


def test_4(data_file_path, randseed, *args):
    """Plot learning curve.

    """
    data = pd.read_csv(data_file_path)

    feature1 = args[0]
    label = args[1]

    x_train = data[[feature1]].values
    y_train = data[label].values

    title = 'Learning Curve'
    cv = cross_validation.ShuffleSplit(x_train.shape[0],
                                       random_state=randseed)
    estimator = LogisticRegression(C=500)
    plot_learning_curve(estimator, title, x_train, y_train, cv=cv)

    plt.show()


def test_5(data_file_path, resolution, *args):
    """`last_yr_penal` vs `last_yr_viols`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel(feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_6(data_file_path, resolution, *args):
    """`avg_last_3yr_viols` vs `last_yr_viols`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel(feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_7(data_file_path, resolution, *args):
    """`avg_last_3yr_penals` vs `last_yr_penals`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel(feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_8(data_file_path, resolution, *args):
    """`log(avg_last_3yr_penals)` vs `log(last_yr_penals)`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    feature1 = args[0]
    feature2 = args[1]
    label = args[2]

    data[feature1] = np.log(data[feature1] + 1)
    data[feature2] = np.log(data[feature2] + 1)
    x_train = data[[feature1, feature2]].values
    y_train = data[label].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr,
                          resolution=resolution)
    plt.xlabel(feature1)
    plt.ylabel(feature2)
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


if __name__ == "__main__":
    dataset = ['../data/Recent_5_Mine_Accidents_Data_training_2.csv',
               '../data/top_5_accident_mines_processed_geq_30.csv',
               '../data/top_5_accident_mines_processed_geq_80.csv',
               '../data/mine-id/4608791.csv',
               '../data/mine-id/4608436.csv',
               '../data/mine-id/4601437.csv',
               '../data/mine-id/4201715.csv',
               '../data/mine-id/1202215.csv',
               '../data/mine-id/4608791_label-geq2.csv',
               '../data/mine-id/master.csv',
               '../data/mine-id/4608791_rolling_quarterly.csv',
               '../data/mine-id/4608791_quarterly.csv',
               '../data/mine-id/4608791_yearly.csv',
               '../Data/mine-id/master_yearly.csv']
    feature_list = ['num_violations',
                    'num_violations_t_minus_1',
                    'total_penalties',
                    u'date',
                    u'last_yr_viols',
                    u'last_yr_penals',
                    u'avg_last_3yr_viols',
                    u'avg_last_3yr_penals',
                    'accident_label_t_plus_1',
                    u'accident_label']

    """
    # Group 1 - pre-accident feature tests
    test_1(dataset[1], 0.5, feature_list[0],
           feature_list[2], feature_list[8])
    test_2(dataset[0], 0.5, feature_list[0],
           feature_list[1], feature_list[8])
    test_3(dataset[2], feature_list[2], feature_list[8])
    test_4(dataset[1], 100, feature_list[0], feature_list[8])
    """

    """
    # Group 2 - mine-id logistic regression
    test_5(dataset[3], 50, feature_list[4],
           feature_list[5], feature_list[9])
    test_6(dataset[7], 10, feature_list[4],
           feature_list[6], feature_list[9])
    test_6(dataset[9], 10, feature_list[4],
           feature_list[6], feature_list[9])  # all 6 mine data in one csv
    test_7(dataset[3], 50, feature_list[5],
           feature_list[7], feature_list[9])
    """

    """
    # Group 3 - different time span
    test_6(dataset[10], 50, feature_list[4],
           feature_list[6], feature_list[9])  # quarterly rolling
    test_7(dataset[11], 100, feature_list[5],
           feature_list[7], feature_list[9])  # quarterly
    test_7(dataset[12], 100, feature_list[5],
           feature_list[7], feature_list[9])  # yearly
    test_6(dataset[13], 50, feature_list[4],
           feature_list[6], feature_list[9])  # yearly all 6 mind data
    """
    test_8(dataset[13], 0.5, feature_list[5],
           feature_list[7], feature_list[9])  # yearly all 6 mind data
