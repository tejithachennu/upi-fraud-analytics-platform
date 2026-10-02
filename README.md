# UPI / Digital Payments Fraud & Transaction Analytics Platform

End-to-end analytics project: synthetic data generation → SQL aggregation →
Python fraud detection → Power BI dashboard → business insights summary.

## ⚠️ Dataset is synthetic

Real UPI transaction-level data is not publicly available. Everything here —
transactions, customers, merchants, fraud patterns — is generated with
documented, realistic logic (see `README_dataset.md`). No real user, bank
account, or transaction data is used anywhere in this project.

## Project structure

| File | Phase | Description |
|---|---|---|
| `upi_transactions.csv` | 1 | 202,490 synthetic transactions, Jan–Dec 2025 |
| `fraud_ground_truth.csv` | 1 | Hidden fraud labels — validation only, not a model input |
| `README_dataset.md` | 1 | Data generation methodology & assumptions |
| `01_volume_trends.sql` – `05_customer_rfm.sql` | 2 | SQL views for volume, failures, merchants, geography, RFM |
| `UPI_Fraud_EDA_Analysis.ipynb` | 3 | EDA + 4-rule fraud engine + validation + revenue impact |
| `fraud_flags_export.csv` | 3 | Per-transaction fraud flags, joined into Power BI |
| `UPI_Insights_Pastel_Theme.json` | 4 | Power BI custom theme |
| `UPI_Insights_Dashboard.pbix` | 4 | Interactive dashboard (built locally in Power BI Desktop) |
| `Business_Insights_Summary.docx` | 5 | One-page stakeholder summary |

## Methodology summary by phase

**Phase 1 — Data generation.** 18,000 synthetic customers and 2,200 merchants
across 8 categories, weighted across 16 states/~40 cities to mirror rough
real-world UPI volume concentration. Seasonality (weekday/weekend, salary
days, festivals, hourly peaks) and bank-specific reliability (including a
deliberate August dip for two weaker banks) are built in. 2.56% of
transactions are deliberately injected fraud across 4 typologies
(velocity abuse, amount spike, odd-hour anomaly, probing), with ground truth
kept in a separate file for validation only.

**Phase 2 — SQL.** Five view sets covering volume trends, failure analysis,
merchant performance, geographic patterns, and an RFM customer base table —
built and validated in MySQL 8.0, using window functions (`LAG`, `NTILE`,
`RANK`) throughout.

**Phase 3 — Fraud rules & EDA (Python).** Four independent, explainable rules
were implemented and validated against the hidden ground truth:

| Rule | Precision | Recall (own pattern) |
|---|---|---|
| Velocity abuse | 100% | 100% |
| Amount spike | 84.6% | 63.3% |
| Odd-hour anomaly | 38.2% | 84.8% |
| Probing | 100% | 100% |
| **Combined (any rule fires)** | **72.0%** | **85.6%** |
| **High confidence (2+ rules fire)** | **99.1%** | lower, high-certainty subset |

**Phase 4 — Power BI dashboard.** Single-page interactive dashboard with a
full drill-down chain (State → City → Merchant → Date → Transaction Type),
4 KPI cards, and 6 supporting charts (volume trend, failure rate by bank,
revenue by merchant category, transactions by state, revenue lost by bank,
suspicious transactions by pattern). Custom pastel theme applied consistently
across all visuals.

**Phase 5 — Business insights.** See `Business_Insights_Summary.docx` for the
5 headline findings and associated recommendations.

## Known limitations

- Fraud patterns are injected with relatively clean signatures; real fraud is
  noisier and adversarial, so real-world precision/recall would likely be
  lower than shown here.
- Bank/merchant reliability scores are hand-picked, not fit to real incident
  data.
- No device fingerprint, IP, or geolocation-drift signals — real fraud
  systems rely heavily on these, and this dataset can't simulate them.
- State/city volume weights are directional estimates, not sourced from
  NPCI or other official data.
- The odd-hour rule has notably low standalone precision (38%) — included
  deliberately to demonstrate a real false-positive tradeoff, not because
  it's a strong rule on its own.

## Reproducing this project

1. Generate the dataset: see `README_dataset.md` for the generation logic.
2. Load `upi_transactions.csv` into MySQL, run the 5 SQL scripts in order.
3. Open `UPI_Fraud_EDA_Analysis.ipynb` and run all cells top to bottom.
4. Open `UPI_Insights_Dashboard.pbix` in Power BI Desktop, refresh data
   sources to point at your local file paths.
