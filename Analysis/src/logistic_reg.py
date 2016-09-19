#!usr/bin/env ipython

"""Load MSHA data and run a logistic regression.

@author: Albert
@version: 0.0.1
@date: 09/15/16

"""

import pandas as pd
import numpy as np
from sklearn import cross_validation
from sklearn.linear_model import LogisticRegression
from sklearn.learning_curve import learning_curve
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


def test_1(data_file_path, feature_list):
    """Plot two-feature decision boundary.

    ``log(penalty)`` vs. ``num_violation``

    Data:
        `top_5_accident_mines_geq_30.csv`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0, inplace=True)

    data[feature_list[2]] = np.log(data[feature_list[2]] + 1)
    x_train = data[[feature_list[0], feature_list[2]]].values
    y_train = data['accident_label_t_plus_1'].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr, resolution=0.5)
    plt.xlabel(feature_list[0])
    plt.ylabel('log of ' + feature_list[2])
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_2(data_file_path, feature_list):
    """Plot two-feature decision boundary.

    ``num_violation_t`` vs. ``num_violation_t_minus_1``

    Data:
        `Recent_5_Mine_Accidents_Data_training_2.csv`

    """
    data = pd.read_csv(data_file_path)
    data.fillna(0)

    x_train = data[feature_list[0:2]].values
    y_train = data['accident_label_t_plus_1'].values

    lr = LogisticRegression(C=500)
    lr.fit(x_train, y_train)

    plot_decision_regions(x_train, y_train, classifier=lr, resolution=0.5)
    plt.xlabel(feature_list[0])
    plt.ylabel(feature_list[1])
    plt.legend(loc='upper left')

    # plt.tight_layout()
    # plt.savefig('../lr.png', dpi=300)
    plt.show()


def test_3(data_file_path, feature_list):
    """Check whether label is reasonable.

    Plot ``num_violation`` vs. ``accident_label_t_plus_1``

    Data:
        `top_5_accident_mines_geq_80.csv`

    """
    data = pd.read_csv(data_file_path)

    acc_label = data['accident_label_t_plus_1']
    x_val = data[feature_list[2]]

    plt.scatter(x_val, acc_label)
    plt.xlabel(feature_list[2])
    plt.ylabel('accident_label_t_plus_1')
    plt.ylim(-0.5, 1.5)
    # plt.legend(loc='upper left')

    plt.show()


def test_4(data_file_path, feature_list):
    """Plot learning curve.

    """
    data = pd.read_csv(data_file_path)

    x_train = data[feature_list[0:1]].values
    y_train = data['accident_label_t_plus_1'].values

    title = 'Learning Curve'
    cv = cross_validation.ShuffleSplit(x_train.shape[0], random_state=100)
    estimator = LogisticRegression(C=500)
    plot_learning_curve(estimator, title, x_train, y_train, cv=cv)

    plt.show()


if __name__ == "__main__":
    dataset = ['../data/Recent_5_Mine_Accidents_Data_training_2.csv',
               '../data/top_5_accident_mines_processed_geq_30.csv',
               '../data/top_5_accident_mines_processed_geq_80.csv']
    feature_list = ['num_violations',
                    'num_violations_t_minus_1',
                    'total_penalties']

    # test_1(dataset[1], feature_list)
    # test_2(dataset[0], feature_list)
    # test_3(dataset[2], feature_list)
    test_4(dataset[1], feature_list)
