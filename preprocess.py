import pandas as pd

# Load the original CSV
df = pd.read_csv("new_data.csv")

# Clean-up and process demographic data
age_counts = df['agegroup'].value_counts()
age_pcts = df['agegroup'].value_counts(normalize=True) * 100
# print(pd.DataFrame({'n': age_counts, '%': age_pcts.round(2)})) # proportion reader

ethnicity_counts = df['ethnicity'].value_counts()
ethnicity_pcts = df['ethnicity'].value_counts(normalize=True) * 100
# print(pd.DataFrame({'n': ethnicity_counts, '%': ethnicity_pcts.round(2)})) # proportion reader
ethnicity_levels = ['white', 'black', 'hispanic', 'asian', 'other']
df = df[~df['ethnicity'].isin(['native_american', 'pacific_islander'])]
df['ethnicity'] = pd.Categorical(df['ethnicity'], categories=ethnicity_levels)

df['gender'] = df['gender'].str.lower().str.strip()

df = df[(df["age"] >= 20) & (df["age"] < 80)].copy()
bins = [20, 30, 40, 50, 60, 70, 80]
labels = ['20–29', '30–39', '40–49', '50–59', '60–69', '70–79']
df["agegroup"] = pd.cut(df["age"], bins=bins, labels=labels, right=False)
df["agegroup"] = pd.Categorical(df["agegroup"], categories=labels, ordered=True)

# Clean-up and process time data
month_to_season = {
    'Dec': 'winter', 'Jan': 'winter', 'Feb': 'winter',
    'Mar': 'spring', 'Apr': 'spring', 'May': 'spring',
    'Jun': 'summer', 'Jul': 'summer', 'Aug': 'summer',
    'Sep': 'fall', 'Oct': 'fall', 'Nov': 'fall'
}
df['season'] = df['month'].map(month_to_season)

weekday_order = ['Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun']
df['weekday'] = pd.Categorical(df['weekday'], categories=weekday_order, ordered=True)
df['day_type'] = df['weekday'].apply(
    lambda x: 'weekend' if x in ['Sat', 'Sun'] else 'weekday'
)

# Export to a new CSV file
df.to_csv("final_data.csv", index=False)
