"""
INSEE housing microdata – synthetic ETL demo
- Generates a small synthetic sample if no data is found
- Cleans & validates (missing values, duplicates, simple business rules)
- Saves cleaned dataset and a quick figure for the README
"""

from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parents[1]  # projects/insee-housing/
DATA_RAW = BASE / "data" / "raw"           # (kept empty in repo)
DATA_SAMPLE = BASE / "data" / "sample"
DATA_OUT = BASE / "data" / "processed"
FIG_DIR = BASE / "reports" / "figures"

for p in [DATA_SAMPLE, DATA_OUT, FIG_DIR]:
    p.mkdir(parents=True, exist_ok=True)

sample_path = DATA_SAMPLE / "housing_sample.csv"
clean_path = DATA_OUT / "housing_clean.csv"
fig_path = FIG_DIR / "area_distribution.png"

# 1) Load or generate synthetic sample
if sample_path.exists():
    df = pd.read_csv(sample_path)
else:
    rng = np.random.default_rng(42)
    n = 2000
    df = pd.DataFrame({
        "property_id": np.arange(n),
        "territory": rng.choice(["North", "South", "East", "West"], size=n),
        "area_m2": rng.normal(80, 25, size=n).round(1),
        "rooms": rng.integers(1, 7, size=n),
        "local_wage": rng.normal(2200, 400, size=n).round(0),
        "owner_change": rng.choice([0, 1], size=n, p=[0.7, 0.3])
    })

    # inject a few inconsistencies and missing values
    idx_bad = rng.choice(n, size=30, replace=False)
    df.loc[idx_bad, "rooms"] = 1
    df.loc[idx_bad, "area_m2"] = rng.normal(120, 10, size=30).round(1)  # big area but 1 room
    df.loc[rng.choice(n, 40, replace=False), "area_m2"] = np.nan
    df.loc[rng.choice(n, 40, replace=False), "local_wage"] = np.nan

    sample_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(sample_path, index=False)

# 2) Basic cleaning
# remove exact duplicates
df = df.drop_duplicates(subset=["property_id"], keep="first")

# simple outlier caps
df["area_m2"] = df["area_m2"].clip(lower=10, upper=300)
df["rooms"] = df["rooms"].clip(lower=1, upper=10)

# impute missing area by rooms median
df["area_m2"] = df.groupby("rooms")["area_m2"].transform(
    lambda s: s.fillna(s.median())
)
# impute missing wage by territory median
df["local_wage"] = df.groupby("territory")["local_wage"].transform(
    lambda s: s.fillna(s.median())
)

# 3) Validation rules / quality flags
df["flag_inconsistent_area_rooms"] = ((df["area_m2"] >= 100) & (df["rooms"] == 1)).astype(int)

# 4) Simple aggregation example (territorial indicators)
agg = (df
       .groupby("territory")
       .agg(mean_area=("area_m2", "mean"),
            median_wage=("local_wage", "median"),
            owner_change_rate=("owner_change", "mean"),
            inconsistency_rate=("flag_inconsistent_area_rooms", "mean"))
       .reset_index()
      )

print("Territorial indicators (head):")
print(agg.round(3).head())

# 5) Save cleaned data and a quick figure
DATA_OUT.mkdir(parents=True, exist_ok=True)
df.to_csv(clean_path, index=False)

plt.figure()
df["area_m2"].plot(kind="hist", bins=30, title="Area (m²) – distribution")
plt.xlabel("area_m2")
plt.tight_layout()
plt.savefig(fig_path, dpi=180)
plt.close()

print(f"\nSaved cleaned dataset to: {clean_path}")
print(f"Saved figure to: {fig_path}")
