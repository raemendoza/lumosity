import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats as stats
from typing import Callable, Iterable

# IMPORT DATA
df = pd.read_csv('final_data.csv')

# TYPE CHECKS AND FONT SET
hours = list(range(24))
weekdays = ['Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun']
seasons = ['Winter', 'Spring', 'Summer', 'Fall']
ages = ['20–29', '30–39', '40–49', '50–59', '60–69', '70–79']
ages_young = ['20–29', '30–39', '40–49']
ages_old = ['50–59', '60–69', '70–79']
genders = ['male', 'female']
ethnicities = ['white', 'black', 'hispanic', 'asian', 'other']
sleep_vals = [5, 6, 7, 8, 9]
mood_vals = [-2, -1, 0, 1, 2]

df['hour'] = df['hour'].astype(int)
df['weekday'] = pd.Categorical(df['weekday'], weekdays, ordered=True)
df['season'] = df['season'].str.capitalize()
df['season'] = pd.Categorical(df['season'], seasons, ordered=True)
df['agegroup'] = pd.Categorical(df['agegroup'], ages, ordered=True)
df['gender'] = pd.Categorical(df['gender'], genders, ordered=True)
df['ethnicity'] = pd.Categorical(df['ethnicity'], ethnicities, ordered=True)
df['mood'] = df['mood'].astype(int)
df['sleep'] = df['sleep'].astype(int)


plt.rcParams['font.family'] = 'Times New Roman'

## COLOR MAPPINGS FOR PLOTS
hour_colors = plt.colormaps['RdYlBu_r'](np.concatenate([
    np.linspace(0, 0.55, 6),
    np.linspace(0.55, 0.8, 6),
    np.linspace(0.8, 0.55, 6),
    np.linspace(0.55, 0, 6)
]))
wd_colors = ['#7B7B7B', '#A0785A', '#6BAED6', '#74C476', '#F4A582', '#FDD0A2', '#C994C7']
season_colors = ['#5B8DB8', '#6DBF67', '#F4AC3A', '#D9534F']
age_colors_young = {'20–29': '#2f2f2f', '30–39': '#6a6a6a', '40–49': '#bdbdbd'}
age_colors_old = {'50–59': '#6baed6', '60–69': '#3182bd', '70–79': '#08519c'}
age_colors = {**age_colors_young, **age_colors_old}
gender_colors = {'male': '#1f77b4', 'female': '#d62728'}
ethnicity_colors = {
        'white': '#1f77b4',
        'black': '#d62728',
        'hispanic': '#2ca02c',
        'asian': '#ff7f0e',
        'other': '#9467bd'
}
mood_colors = plt.colormaps['plasma'](np.linspace(0.15, 0.85, 5))
sleep_colors = plt.colormaps['plasma'](np.linspace(0.15, 0.85, len(sleep_vals)))

## HELPER FUNCTIONS AND VARIABLES
x_week = np.arange(-1, len(weekdays) + 1)
x_ticks = np.arange(len(weekdays))


def wrap168(series: np.ndarray, pad_x: int) -> np.ndarray:
    return np.concatenate([series[-pad_x:], series])


def wrap_week(series: pd.Series | pd.DataFrame) -> pd.Series | pd.DataFrame:
    return pd.concat([series.iloc[[-1]], series, series.iloc[[0]]])


def _agg_se(data: pd.DataFrame, group: list[str], col: str, ci: bool = False) -> pd.DataFrame:
    s = data.groupby(group, observed=True)[col].agg(['mean', 'std', 'count'])
    s['se'] = s['std'] / np.sqrt(s['count'])
    if ci:
        s['ci95'] = s['se'] * stats.t.ppf(0.975, s['count'] - 1)
    return s


def _band_plot(ax: plt.Axes, st: pd.DataFrame, keys: Iterable, colors: Iterable, label_fn: Callable) -> None:
    x = np.arange(25)
    for key, color in zip(keys, colors):
        s = st.loc[key].reindex(range(24))
        mean_pad = np.r_[s['mean'].values, s['mean'].iloc[0]]
        se_pad = np.r_[s['se'].values, s['se'].iloc[0]]
        ax.plot(x, mean_pad, linewidth=3, color=color, label=label_fn(key))
        ax.fill_between(x, mean_pad - se_pad, mean_pad + se_pad, color=color, alpha=0.25)


def _error_bar_week(ax: plt.Axes, st: pd.DataFrame, keys: Iterable, colors: Iterable, label_fn: Callable) -> None:
    for key, color in zip(keys, colors):
        s = st.loc[key].reindex(weekdays)
        ax.errorbar(x_week, wrap_week(s['mean']), yerr=wrap_week(s['ci95']),
                    fmt='-o', linewidth=3, color=color, label=label_fn(key), capsize=5)


## BEGIN PLOT FUNCTIONS


def plot_timeline(data=df):
    full_index = pd.MultiIndex.from_product([weekdays, range(24)], names=['weekday', 'hour'])
    mood_stats = _agg_se(data, ['weekday', 'hour'], 'mood').reindex(full_index)
    sleep_stats = _agg_se(data, ['weekday', 'hour'], 'sleep').reindex(full_index)

    weekday_indices = [0, 2, 4, 6]
    weekday_positions = [12 + 24 * i for i in weekday_indices]
    weekday_labels = [weekdays[i] for i in weekday_indices]

    pad = 3
    x = np.arange(-pad, 168)

    mood_y = wrap168(mood_stats['mean'].values, pad)
    mood_err = wrap168(mood_stats['se'].values, pad)
    sleep_y = wrap168(sleep_stats['mean'].values, pad)
    sleep_err = wrap168(sleep_stats['se'].values, pad)

    fig, axes = plt.subplots(1, 2, figsize=(16, 6), sharex=True)
    axes[0].errorbar(x, mood_y, yerr=mood_err, fmt='-', color='black', ecolor='black', elinewidth=1.5, capsize=0,
                     linewidth=3)
    axes[1].errorbar(x, sleep_y, yerr=sleep_err, fmt='-', color='black', ecolor='black', elinewidth=1.5, capsize=0,
                     linewidth=3)

    axes[0].set_ylabel('Average Mood', fontsize=18)
    axes[1].set_ylabel('Average Sleep Duration (h)', fontsize=18)
    axes[0].set_ylim(mood_stats['mean'].mean() - 0.35 / 2, mood_stats['mean'].mean() + 0.35 / 2)
    axes[1].set_ylim(sleep_stats['mean'].mean() - 0.80 / 2, sleep_stats['mean'].mean() + 0.80 / 2)

    tick_positions = list(range(0, 169, 24))
    for ax in axes:
        ax.grid(True, linestyle='-', alpha=1, linewidth=1.5)
        ax.set_xticks(tick_positions)
        ax.set_xlim(-pad, 168)
        ax.set_xticklabels(tick_positions, fontsize=14)
        ax.tick_params(axis='y', labelsize=14, width=1.5, length=6)
        for label in ax.get_yticklabels():
            label.set_fontname('Times New Roman')
        ax.text(1.025, -0.018, 'h', transform=ax.transAxes, fontsize=14, ha='left', va='top')
        for pos, day in zip(weekday_positions, weekday_labels):
            ax.text(pos / 168, 0.95, day, ha='center', va='bottom', transform=ax.transAxes, fontsize=14)

    for ax, label in zip(axes, ['A', 'B']):
        ax.text(-0.03, 1.05, label, transform=ax.transAxes, fontsize=22, fontweight='bold', va='top', ha='right')

    plt.tight_layout()
    plt.savefig('Fig1.pdf')


def plot_hour_mood(data=df):
    gender_stats = _agg_se(data, ['gender', 'hour'], 'mood')
    sleep_hour_stats = _agg_se(data, ['sleep', 'hour'], 'mood')

    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    # Panel A: Hour × Gender
    ax = axes[0]
    _band_plot(axes[0], gender_stats, gender_colors.keys(), gender_colors.values(), str.capitalize)

    ax.set_ylabel('Average Mood', fontsize=18)
    ax.legend(frameon=False, prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'A', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel B: Hour × Sleep
    ax = axes[1]
    _band_plot(axes[1], sleep_hour_stats, sleep_vals, sleep_colors, lambda k: f'{k} h')

    ax.legend(frameon=False, ncol=5, loc='lower center', prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'B', transform=ax.transAxes, fontsize=22, fontweight='bold')

    plt.setp(axes, ylim=(-0.1, 0.7))
    for ax in axes:
        ax.set_xticks(range(0, 25, 3))
        ax.set_xticklabels([str(h) for h in range(0, 25, 3)])
        ax.set_xlim(0, 24)
        ax.grid(True, linewidth=1.5)
        ax.tick_params(axis='both', labelsize=14)
        ax.text(1.020, -0.02, 'h', transform=ax.transAxes, fontsize=14, ha='left', va='top')
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_fontname('Times New Roman')

    plt.tight_layout()
    plt.savefig('Fig2.pdf')


def plot_week_mood(data=df):
    sleep_wd_stats = _agg_se(data, ['sleep', 'weekday'], 'mood', ci=True)
    age_wd_stats = _agg_se(data[data['agegroup'].isin(
        ages_young + ages_old)], ['agegroup', 'weekday'], 'mood', ci=True)

    fig, axes = plt.subplots(1, 3, figsize=(20, 6))

    # Panel A: Sleep × Weekday
    ax = axes[0]
    _error_bar_week(axes[0], sleep_wd_stats, sleep_vals, sleep_colors, lambda k: f'{k} h')

    ax.set_ylabel('Average Mood', fontsize=18)
    ax.legend(frameon=False, ncol=len(sleep_vals), loc='upper center',
              bbox_to_anchor=(0.5, 1), columnspacing=0.9,
              prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'A', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel B: Young ages × Weekday
    ax = axes[1]
    _error_bar_week(ax, age_wd_stats, ages_young, age_colors_young.values(), lambda k: f'{k} y')

    ax.legend(frameon=False, prop={'family': 'Times New Roman', 'size': 14}, loc='lower right')
    ax.text(-0.08, 1.05, 'B', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel C: Old ages × Weekday
    ax = axes[2]
    _error_bar_week(ax, age_wd_stats, ages_old, age_colors_old.values(), lambda k: f'{k} y')

    ax.legend(frameon=False, prop={'family': 'Times New Roman', 'size': 14}, loc='lower right')
    ax.text(-0.08, 1.05, 'C', transform=ax.transAxes, fontsize=22, fontweight='bold')

    plt.setp(axes, ylim=(-0.1, 0.7))
    for ax in axes:
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(weekdays)
        ax.set_xlim(-0.25, len(weekdays) - 0.75)
        ax.grid(True, linewidth=1.5)
        ax.tick_params(axis='both', labelsize=14)
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_fontname('Times New Roman')

    plt.tight_layout()
    plt.savefig('Fig3.pdf')


def plot_hour_sleep(data=df):
    gender_sleep_stats = _agg_se(data, ['gender', 'hour'], 'sleep')
    ethnicity_sleep_stats = _agg_se(data, ['ethnicity', 'hour'], 'sleep')
    age_sleep_stats = _agg_se(data, ['agegroup', 'hour'], 'sleep')
    mood_sleep_stats = _agg_se(data, ['mood', 'hour'], 'sleep')

    fig, axes = plt.subplots(2, 2, figsize=(15, 11))
    axes = axes.flatten()

    # Panel A: Hour × Gender
    ax = axes[0]
    _band_plot(ax, gender_sleep_stats, gender_colors.keys(), gender_colors.values(), str.capitalize)

    ax.set_ylabel('Average Sleep Duration (h)', fontsize=18)
    ax.legend(frameon=False, prop={'family': 'Times New Roman', 'size': 15})
    ax.text(-0.08, 1.05, 'A', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel B: Hour × Ethnicity
    ax = axes[1]
    _band_plot(axes[1], ethnicity_sleep_stats, ethnicity_colors.keys(), ethnicity_colors.values(), str.capitalize)

    ax.legend(frameon=False, ncol=2, prop={'family': 'Times New Roman', 'size': 15})
    ax.text(-0.08, 1.05, 'B', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel C: Hour × Age
    ax = axes[2]
    _band_plot(axes[2], age_sleep_stats, age_colors.keys(), age_colors.values(), lambda k: f'{k} y')

    ax.set_ylabel('Average Sleep Duration (h)', fontsize=18)
    ax.legend(frameon=False, ncol=2, prop={'family': 'Times New Roman', 'size': 15})
    ax.text(-0.08, 1.05, 'C', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel D: Hour × Mood
    ax = axes[3]
    _band_plot(axes[3], mood_sleep_stats, sorted(df['mood'].unique()), mood_colors, str)

    ax.legend(frameon=False, ncol=5, loc='lower center', prop={'family': 'Times New Roman', 'size': 15})
    ax.text(-0.08, 1.05, 'D', transform=ax.transAxes, fontsize=22, fontweight='bold')

    plt.setp(axes, ylim=(5.9, 7.6))
    for ax in axes:
        ax.set_xticks(range(0, 25, 3))
        ax.set_xlim(0, 24)
        ax.axhline(y=7, color='gray', linestyle='dotted', linewidth=2)
        ax.grid(True, linewidth=1.5)
        ax.tick_params(axis='both', labelsize=14)
        ax.text(1.018, -0.019, 'h', transform=ax.transAxes, fontsize=14, ha='left', va='top')
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_fontname('Times New Roman')

    plt.tight_layout()
    plt.savefig('Fig4.pdf')


def plot_week_sleep(data=df):
    gender_wd_stats = _agg_se(data, ['gender', 'weekday'], 'sleep', ci=True)
    ethnicity_wd_stats = _agg_se(data, ['ethnicity', 'weekday'], 'sleep', ci=True)
    age_wd_stats = _agg_se(data[data['agegroup'].isin(ages_young + ages_old)], ['agegroup', 'weekday'], 'sleep',
                           ci=True)

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    axes = axes.flatten()

    # Panel A: Gender
    ax = axes[0]
    _error_bar_week(axes[0], gender_wd_stats, gender_colors.keys(), gender_colors.values(), str.capitalize)

    ax.set_ylabel('Average Sleep Duration (h)', fontsize=18)
    ax.legend(frameon=False, ncol=1, prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'A', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel B: Ethnicity
    ax = axes[1]
    _error_bar_week(axes[1], ethnicity_wd_stats, ethnicity_colors.keys(), ethnicity_colors.values(), str.capitalize)

    ax.legend(frameon=False, ncol=2, columnspacing=0.9, prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'B', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel C: Young ages
    ax = axes[2]
    _error_bar_week(axes[2], age_wd_stats, ages_young, age_colors_young.values(), lambda k: f'{k} y')

    ax.set_ylabel('Average Sleep Duration (h)', fontsize=18)
    ax.legend(frameon=False, ncol=1, columnspacing=0.8, prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'C', transform=ax.transAxes, fontsize=22, fontweight='bold')

    # Panel D: Old ages
    ax = axes[3]
    _error_bar_week(axes[3], age_wd_stats, ages_old, age_colors_old.values(), lambda k: f'{k} y')

    ax.legend(frameon=False, ncol=1, columnspacing=0.8, loc='upper left',
              prop={'family': 'Times New Roman', 'size': 14})
    ax.text(-0.08, 1.05, 'D', transform=ax.transAxes, fontsize=22, fontweight='bold')

    plt.setp(axes, ylim=(6.5, 7.5))
    for ax in axes:
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(weekdays)
        ax.set_xlim(-0.25, len(weekdays) - 0.75)
        ax.axhline(y=7, color='gray', linestyle='dotted', linewidth=2)
        ax.grid(True, linewidth=1.5)
        ax.tick_params(axis='both', labelsize=14)
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_fontname('Times New Roman')

    plt.tight_layout()
    plt.savefig('Fig5.pdf')


def plot_descriptives(data=df):
    hour_counts = data['hour'].value_counts().reindex(hours)
    wd_counts = data['weekday'].value_counts().reindex(weekdays)
    season_counts = data['season'].value_counts().reindex(seasons)

    y_lims = [(0, 30000), (0, 80000), (0, 300000)]

    fig, axes = plt.subplots(1, 3, figsize=(20, 6))

    for ax, data, labels, panel, x_label, y_lim, colors in zip(
            axes,
            [hour_counts, wd_counts, season_counts],
            [hours, weekdays, seasons],
            ['A', 'B', 'C'],
            ['Hour of Day', 'Weekday', 'Season'],
            y_lims,
            [hour_colors, wd_colors, season_colors]

    ):
        x = np.arange(len(labels))
        ax.bar(x, data, color=colors, linewidth=1)
        ax.set_xticks(x)
        ax.set_xlim(-0.5, len(labels) - 0.5)
        ax.set_xticklabels(labels, rotation=45 if len(labels) > 7 else 0, ha='center')
        ax.set_xlabel(x_label, fontsize=16)
        ax.set_ylim(y_lim)
        ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda c, _: f'{int(c):,}'))
        ax.grid(False)
        ax.tick_params(axis='both', labelsize=14)
        ax.text(-0.08, 1.05, panel, transform=ax.transAxes, fontsize=22, fontweight='bold')
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_fontname('Times New Roman')

    axes[0].set_ylabel('Frequency', fontsize=18)
    plt.tight_layout()
    plt.savefig('FigS1.pdf')


if __name__ == '__main__':
    plot_timeline()
    plot_hour_mood()
    plot_hour_sleep()
    plot_week_mood()
    plot_week_sleep()
    plot_descriptives()
