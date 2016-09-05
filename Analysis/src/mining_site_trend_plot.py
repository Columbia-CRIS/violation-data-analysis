#!usr/bin/env ipython

"""Mining accident site data.

@author: Albert
@version: 0.0
@date: 08/31/16

TODO:
    ``plot_feature_vs_time()`` raises warnings and causes seaborn bugs, need fix.

"""

import pandas as pd
import seaborn as sns
from datetime import datetime


def to_str(vec):
    """Convert a vector of int to string.

    Args:
        vec (Series): vector of int64.

    Returns:
        list of string.

    """

    result = [str(i) for i in vec]
    return result


def plot_feature(x, y, input_data):
    """Plot y_feature vs. x_feature for mining accidents in MSHA database.

    Args:
        x (str): name of the feature that you want to plot as ``x`` variable.

        y (str): name of the feature that you want to plot as ``y`` variable.

        input_data (list of tuples): [(violator name, data file location,
        x_feature_slice_begin, x_feature_slice_end)].

    Returns:
        .png figures

    """

    for item in input_data:
        data = pd.read_csv(item[1], sep=',', header=0)
        temp = data[data['violator_name'] == item[0]]
        temp2 = temp.set_index(x).loc[item[2]:item[3]]
        violation_data = temp2.reset_index()

        # plot
        sns.set(style="ticks")
        fig = sns.jointplot(x=x,
                            y=y,
                            data=violation_data)
        fig.savefig("../graphs/MiningAcc/%s-%s-fig.png" % (item[0], y))


def plot_feature_vs_time(y, input_data):
    """Plot y_feature vs. time for mining accidents in MSHA database.

    Set X-axis as ``datetime`` object.

    Args:
        y (str): name of the feature that you want to plot as ``y`` variable.

        input_data (list of tuples): [(violator name, data file location,
        begin_time, end_time)].

    Returns:
        .png figures

    """

    for item in input_data:
        data = pd.read_csv(item[1], sep=',', header=0)
        temp = data[data['violator_name'] == item[0]]
        from_time = datetime.strptime(str(item[2]), '%Y')
        to_time = datetime.strptime(str(item[3]), '%Y')
        temp['iss_year'] = to_str(temp['iss_year'])
        temp['iss_year'] = pd.to_datetime(temp['iss_year'])
        temp2 = temp.set_index('iss_year').loc[from_time:to_time]
        violation_data = temp2.reset_index()

        # plot
        sns.set(style="ticks")
        fig = sns.jointplot(x='iss_year',
                            y=y,
                            data=violation_data,
                            stat_func=None)
        fig.savefig("../graphs/MiningAcc/%s-%s-fig.png" % (item[0], y))


if __name__ == "__main__":
    # dataset = (violator, file name, from, to)
    dataset = [('Performance Coal Company',
               '../data/Sites/Upper_Big_Branch_Data2.csv', 1995, 2009),
               ('Kentucky Darby Llc',
                '../data/Sites/Darby_Mine_Data.csv', 2001, 2005),
               ('Genwal Resources Inc',
                '../data/Sites/Crandall_Canyon_Mine_Data.csv', 1995, 2006),
               ('Wolf Run Mining Company',
                '../data/Sites/Sago_Mine_Data.csv', 2002, 2005),
               ('Jim Walter Resources Inc',
                '../data/Sites/No_5_Mine_Data.csv', 1982, 2000)]


    plot_feature("iss_year", "total_penalties", dataset)
    plot_feature("iss_year", "num_violations", dataset)
    #plot_feature_vs_time("num_violations", testset)
    #plot_feature_vs_time("total_penalties", testset)
