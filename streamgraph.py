import requests
import yaml
import sys
from collections import Counter

import numpy as np
import pandas
import matplotlib.pyplot as plt


LANG_INDEX = 0
TIME_INDEX = 1
PERIOD = 60 * 60 * 24


def data_for_interval(data, start, interval):
    """Return the subset of data that occured in a time interval."""
    time_col = data[:, TIME_INDEX]
    mask = (time_col > start) & (time_col < (start + interval))
    return data[mask]


def languages_for_period(languages, data, period):
    lang_data = data_for_interval(data, period, PERIOD)[:, LANG_INDEX]
    counter = Counter(lang_data)

    return [counter.get(lang, 0) for lang in languages]


def language_stats(languages, data, periods):
    """Calculate a histogram for each language and each week."""
    return np.array([
        languages_for_period(languages, data, period)
        for period in periods
    ]).astype(np.float64).T


def render_data(filename, yaml_data):
    """Display a streamgraph of the commit data."""
    data = pandas.read_csv(filename).as_matrix()
    languages = np.unique(data[:, LANG_INDEX])

    time = np.arange(
        np.min(data[:, TIME_INDEX]),
        np.max(data[:, TIME_INDEX]),
        PERIOD
    )
    stats = language_stats(languages, data, time)
    colors = [yaml_data[lang].get('color', '#EEEEEE') for lang in languages]

    fig, ax = plt.subplots()
    ax.stackplot(time, *stats, baseline='sym', colors=colors)
    plt.show()


yaml_url = 'https://raw.githubusercontent.com/github/linguist/master/lib/linguist/languages.yml'
language_yaml = yaml.load(requests.get(yaml_url).content)

render_data(sys.stdin, language_yaml)
