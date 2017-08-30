import sys
from collections import Counter

import numpy as np
import pandas
import matplotlib.pyplot as plt


COLOR_INDEX = 0
TIME_INDEX = 1
INTERVAL = 60 * 60 * 24


def data_for_interval(data, start, interval):
    """Return the subset of data that occured in a time interval."""
    time_col = data[:, TIME_INDEX]
    mask = (time_col > start) & (time_col < (start + interval))
    return data[mask]


def colors_for_interval(colors, data, start):
    """Aggregate color data for an interval."""
    colors_data = data_for_interval(data, start, INTERVAL)[:, COLOR_INDEX]
    counter = Counter(colors_data)

    return [counter.get(color, 0) for color in colors]


def language_stats(colors, data, INTERVALs):
    """Calculate a histogram for each language and each week."""
    return np.array([
        colors_for_interval(colors, data, INTERVAL)
        for INTERVAL in INTERVALs
    ]).astype(np.float64).T


def render_data(filename):
    """Display a streamgraph of the commit data."""
    try:
        data = pandas.read_csv(filename).as_matrix()
    except pandas.io.common.CParserError as e:
        return

    colors = np.unique(data[:, COLOR_INDEX])

    time = np.arange(
        np.min(data[:, TIME_INDEX]),
        np.max(data[:, TIME_INDEX]),
        INTERVAL
    )
    stats = language_stats(colors, data, time)

    fig, ax = plt.subplots()
    ax.stackplot(time, *stats, baseline='sym', colors=colors)
    plt.axis('off')
    plt.show()


render_data(sys.stdin)
