"""
INSEE housing microdata — Student version (Master ESA)
------------------------------------------------------
Simple and readable script showing what we did in our student project:
1) Load DVF (2014–2023) + INSEE salary panels (2014–2022)
2) Basic cleaning and simple quality checks
3) Join with employment zones (and add Region)
4) Build yearly indicators by zone (counts and means)
5) Run a very simple OLS as an example

This repo only shares code + synthetic/anonymised samples.
Place the real raw files locally in data/raw/ (not committed).

How to run (locally):
- Put raw files in projects/insee-housing/data/raw/
- Install: pandas, numpy, matplotlib, statsmodels
- Run this file in your IDE or:  python student_version.py
"""

from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm

# -------------------- Paths (relative, student-friendly) --------------------
BASE = Path(__file__).resolve().parents[1]  # projects/insee-housing/
DATA_RAW = BASE / "data" / "raw"
DATA_OUT = BASE / "data" / "processed"
FIG_DIR = BASE / "reports" / "figures"

DATA_OUT.mkdir(parents=True, exist_ok=True)
FIG_DIR.mkdir(parents=True, exist_ok=True)

DVF_FILE = DATA_RAW / "DVF_2014_2023.csv"
ZONES_FILE = DATA_RAW / "zone_emploi_insee.xlsx"

# Salary files: base_salaire_2014.xlsx ... base_salaire_2022.xlsx (sheet "COM")
SALARY_FILES = {}
for y in range(2014, 2023):
    SALARY_FILES[y] = DATA_RAW / f"base_salaire_{y}.xlsx"

# -------------------- 1) Load DVF with very simple cleaning -----------------
def load_dvf_simple(path):
    if not path.exists():
        raise FileNotFoundError(f"Missing file: {path}")
    df = pd.read_csv(path, low_memory=False)

    # Dates and year
    df["date_mutation"] = pd.to_datetime(df.get("date_mutation"), errors="coerce")
    df["year"] = df["date_mutation"].dt.year

    # Commune code as string
    df["code_commune"] = df.get("code_commune").astype(str).str.strip()

    # Simple PLM (Paris/Lyon/Marseille) regrouping rule used in the project
    cc = df["code_commune"].copy()
    cc = np.where(cc.str.startswith("751"), "75056", cc)  # Paris
    cc = np.where(cc.str.startswith("6938"), "69385", cc) # Lyon
    cc = np.where(cc.str.startswith("132"), "13055", cc)  # Marseille
    df["code_commune"] = cc

    # Remove exact duplicates
    df = df.drop_duplicates()

    return df

# -------------------- 2) Load salary panels (stacked) -----------------------
def load_salary_panel(files_dict):
    # We build a long table: code_commune, annee, salaire
    tables = []
    for year in sorted(files_dict.keys()):
        f = files_dict[year]
        if not f.exists():
            print(f"[WARN] Salary file not found for {year}: {f.name}")
            continue
        t = pd.read_excel(f, sheet_name="COM")
        # Keep only code + salary column for the given year
        code_col = "CODGEO"
        salary_col = f"SNHM{str(year)[-2:]}"  # e.g., SNHM14
        t = t[[code_col, salary_col]].copy()
        t.columns = ["code_commune", "salaire"]
        t["annee"] = year
        t["code_commune"] = t["code_commune"].astype(str).str.strip()
        tables.append(t)
    if len(tables) == 0:
        raise FileNotFoundError("No salary files found in data/raw/")
    panel = pd.concat(tables, ignore_index=True)
    return panel

# -------------------- 3) Load employment zones + Region ---------------------
def assign_region(code_dept):
    regions = {
        "Auvergne-Rhône-Alpes": ["01","03","07","15","26","38","42","43","63","69","73","74"],
        "Bourgogne-Franche-Comté": ["21","25","39","58","70","71","89","90"],
        "Bretagne": ["22","29","35","56"],
        "Centre-Val de Loire": ["18","28","36","37","41","45"],
        "Grand Est": ["08","10","51","52","54","55","57","67","68","88"],
        "Hauts-de-France": ["02","59","60","62","80"],
        "Île-de-France": ["75","77","78","91","92","93","94","95"],
        "Normandie": ["14","27","50","61","76"],
        "Nouvelle-Aquitaine": ["16","17","19","23","24","33","40","47","64","79","86","87"],
        "Occitanie": ["09","11","12","30","31","32","34","46","48","65","66","81","82"],
        "Pays de la Loire": ["44","49","53","72","85"],
        "Provence-Alpes-Côte d'Azur": ["04","05","06","13","83","84"],
        "Corse": ["2A","2B"],
    }
    code = str(code_dept)
    for reg, depts in regions.items():
        if code in depts:
            return reg
    return "Autres"

def load_zones_simple(path):
    if not path.exists():
        raise FileNotFoundError(f"Missing file: {path}")
    z = pd.read_excel(path, sheet_name="Composition_communale", skiprows=4, header=0)
    z = z.iloc[1:].reset_index(drop=True)  # drop repeated header row if present
    z = z.rename(columns={"Code géographique communal": "code_commune"})
    z["code_commune"] = z["code_commune"].astype(str).str.strip()
    if "Département" in z.columns:
        z["Region"] = z["Département"].apply(assign_region)

    # Keep only the columns we need
    drop_cols = [
        "Libellé zone d'emploi 2020",
        "Partie régionale de la zone d’emploi trans-régionale",
        "Région"
    ]
    for c in drop_cols:
        if c in z.columns:
            z = z.drop(columns=c)
    return z

# -------------------- 4) Merge DVF + zones + salaries -----------------------
def merge_all(dvf, zones, salary_panel):
    merged = dvf.merge(zones, on="code_commune", how="left")
    merged = merged.dropna(subset=["Zone d'emploi 2020"])  # keep rows with a zone
    merged = merged.rename(columns={"year": "annee"})

    # Prepare keys
    merged["code_commune"] = merged["code_commune"].astype(str).str.strip()
    salary_panel["code_commune"] = salary_panel["code_commune"].astype(str).str.strip()

    # Left join to keep all DVF rows
    merged = merged.merge(salary_panel, on=["code_commune", "annee"], how="left")
    return merged

# -------------------- 5) Simple quality checks (print) ----------------------
def quality_checks(df):
    print("\n--- Simple quality checks ---")
    print("Rows:", len(df))
    print("Missing rate (top 10 columns):")
    miss = df.isna().mean().sort_values(ascending=False).head(10)
    print((miss * 100).round(2).astype(str) + " %")
    print("Duplicate rows:", df.duplicated().sum())

# -------------------- 6) Yearly indicators by zone -------------------------
def build_panel_by_zone(merged):
    """
    Very simple indicators:
    - nb_mutations (count)
    - surface_moyenne (mean of surface_reelle_bati)
    - nombre_piece_moyen (mean of nombre_pieces_principales)
    - salaire_moyen (mean of salaire)
    """
    # Keep only columns we need, and drop rows missing 'annee'
    cols = ["annee", "Zone d'emploi 2020", "surface_reelle_bati",
            "nombre_pieces_principales", "salaire"]
    temp = merged[cols].dropna(subset=["annee", "Zone d'emploi 2020"])

    # Group by year and zone
    g = temp.groupby(["annee", "Zone d'emploi 2020"])
    panel = g.agg(
        nb_mutations=("annee", "count"),
        surface_moyenne=("surface_reelle_bati", "mean"),
        nombre_piece_moyen=("nombre_pieces_principales", "mean"),
        salaire_moyen=("salaire", "mean")
    ).reset_index()

    # Replace NaNs by 0 in means only if needed (keep it simple)
    panel[["surface_moyenne", "nombre_piece_moyen", "salaire_moyen"]] = (
        panel[["surface_moyenne", "nombre_piece_moyen", "salaire_moyen"]].fillna(0)
    )
    return panel

# -------------------- 7) Very simple OLS example ----------------------------
def run_simple_ols(panel):
    """
    y = salaire_moyen
    X = nb_mutations, surface_moyenne, nombre_piece_moyen
    (We keep it very basic on purpose.)
    """
    X = panel[["nb_mutations", "surface_moyenne", "nombre_piece_moyen"]].copy()
    X = sm.add_constant(X)
    y = panel["salaire_moyen"].copy()
    model = sm.OLS(y, X).fit()
    print("\n--- OLS summary (very simple) ---")
    print(model.summary())
    return model

# -------------------- 8) One simple figure for the README -------------------
def save_figure_surface_hist(dvf):
    s = dvf["surface_reelle_bati"].dropna()
    if len(s) == 0:
        return
    plt.figure()
    s.plot(kind="hist", bins=40, title="Surface (m²) — distribution")
    plt.xlabel("surface_reelle_bati")
    plt.tight_layout()
    fig_path = FIG_DIR / "surface_distribution.png"
    plt.savefig(fig_path, dpi=160)
    plt.close()
    print(f"Saved figure: {fig_path}")

# ================================ MAIN ======================================
if __name__ == "__main__":
    # Load
    dvf = load_dvf_simple(DVF_FILE)
    salary_panel = load_salary_panel(SALARY_FILES)
    zones = load_zones_simple(ZONES_FILE)

    # Merge + checks
    merged = merge_all(dvf, zones, salary_panel)
    quality_checks(merged)

    # Save merged
    merged_out = DATA_OUT / "dvf_zones_with_salary_simple.csv"
    merged.to_csv(merged_out, index=False)
    print(f"Saved merged dataset: {merged_out}")

    # Panel + save
    panel = build_panel_by_zone(merged)
    panel_out = DATA_OUT / "panel_zone_2014_2022_simple.csv"
    panel.to_csv(panel_out, index=False)
    print(f"Saved panel: {panel_out}")

    # Figure + OLS
    save_figure_surface_hist(dvf)
    _ = run_simple_ols(panel)
