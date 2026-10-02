# UPI Synthetic Transaction Dataset — Methodology & Assumptions

## Overview
`upi_transactions.csv` contains **202,490 synthetic UPI transactions** spanning
**Jan 1 – Dec 31, 2025**, generated with Python (NumPy, Pandas, Faker). This is
**not real data** — real UPI transaction-level data isn't publicly available at
this granularity. The dataset is built to be *statistically realistic*, not
factually accurate to any real bank or user.

## Population design
- **18,000 synthetic customers**, each with a home state/city, a home bank, and
  a baseline average ticket size (log-normal distribution, so most customers
  spend modestly and a few spend a lot — mimics real income distributions).
  Customers also carry an "activity weight" so some transact far more often
  than others (power-law-ish usage, like real apps).
- **2,200 synthetic merchants** across 8 categories (Grocery, Food Delivery,
  Fuel, E-commerce, Utility Bills, Pharmacy, Travel, Entertainment), each with
  its own typical ticket size and a "quality score" that affects its success rate.
- Customers and merchants repeat across transactions — this is what makes
  RFM segmentation and "amount vs. customer's own history" fraud logic possible.

## Geographic weighting
16 states / ~40 cities, weighted to roughly mirror real UPI volume
concentration (Maharashtra, Karnataka, Delhi, Telangana, Tamil Nadu highest).
Weights are **directional estimates**, not sourced from NPCI data.

## Seasonality (why the transaction volume moves the way it does)
- **Weekday/weekend**: weekends get a 1.25x multiplier (more P2M/leisure spend).
- **Salary days**: 1st/2nd and last 2-3 days of each month get a 1.4x multiplier.
- **Festival windows**: New Year, Holi, Independence Day, Diwali (biggest spike,
  2-2.4x), Nov sale period, Christmas — all get temporary multipliers.
- **Hourly pattern**: quiet 1-5 AM, ramps up through the morning, lunch bump
  (1-2 PM), biggest peak in the evening (7-10 PM).

## Failure-rate design (why ~7.25% of transactions fail)
Each bank has a hand-assigned "reliability" score (0.955–0.99). Two banks
(**Yes Bank, Canara Bank**) are deliberately weaker — and additionally suffer a
simulated **infra degradation in August** (reliability drops further), so the
dataset supports a concrete "which bank needs infra investment, and when"
narrative. Failure probability also ticks up slightly during peak hours
(9-11 AM, 7-10 PM) to simulate server load. Failed transactions get a
weighted-random reason (bank server down, insufficient balance, timeout,
invalid VPA, limit exceeded, incorrect PIN).

## Fraud injection (ground truth kept separately)
**2.56% of transactions (5,178 rows)** are deliberately injected fraud-pattern
transactions, tagged in `fraud_ground_truth.csv` (transaction_id,
is_fraud_ground_truth, fraud_pattern) — **this file is intentionally excluded
from the main CSV**, since a real analyst wouldn't have ground truth either.
Use it only to score precision/recall of the rule-based detector you build in
Phase 3, not as an input feature.

Four patterns, chosen because they map to known real-world UPI fraud typologies:

| Pattern | Logic | Count |
|---|---|---|
| `velocity_abuse` | Same VPA fires 6-15 transactions within a 10-25 min window | 1,847 |
| `amount_spike` | Transaction amount is 8-20x that customer's own historical average | 1,588 |
| `odd_hour_anomaly` | Transaction shifted to 2-4 AM for a customer with no such history | 1,100 |
| `probing` | 3-6 small failed attempts (invalid VPA / wrong PIN) followed by one success — classic account-testing behavior | 643 |

## Known limitations (be upfront about these in an interview)
- Fraud patterns are injected with fixed, somewhat clean signatures — real
  fraud is noisier and adversarial (fraudsters adapt to detection rules).
  This makes the rule-based detector look better than it would in production.
- Bank/merchant reliability scores are hand-picked, not fit to real incident
  data.
- No real device fingerprint, IP, or geolocation drift signals — those are
  major real-world fraud features this dataset can't simulate.
- Amounts are modeled as log-normal/normal blends; real spend distributions
  have fatter tails and category-specific quirks (e.g. EMI-like recurring
  amounts) not captured here.

## Files
- `upi_transactions.csv` — the production dataset (202,490 rows, 15 columns)
- `fraud_ground_truth.csv` — transaction_id + fraud label/pattern, for validation only
