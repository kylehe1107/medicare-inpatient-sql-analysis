# Medicare Inpatient Care: Cost & Quality Analysis

I wanted to dig into what U.S. hospitals actually bill versus what Medicare pays, and whether paying more gets you better care. This project uses public CMS data covering about 3,000 hospitals, 500 MS-DRGs, and roughly 6 million inpatient discharges, all queried in SQL and pulled together into an interactive dashboard.

**[Open the dashboard](dashboard.html)** (self-contained HTML, just double-click it, no server needed)

## Key findings

Hospitals billed $432B for care that Medicare actually paid $88B for, so the average markup is about 4.9x. For-profit hospitals mark up the most aggressively (8.1x) compared to non-profit (around 4.5x) and government hospitals (around 3.9x), and a handful of extreme outliers bill over 20x what they get paid. Sepsis (DRG 871) alone eats up 11.6% of all Medicare inpatient spending, more than the next two DRGs combined. The exact same joint replacement procedure costs about 2x more depending on the state (roughly $13k in the cheapest states vs $26k in Maryland and Alaska), and there's over 3x variation between hospitals even within the same state. One thing I didn't expect: 5-star hospitals actually cost more per discharge ($22.1k) than 1-star hospitals ($16.4k). Some of that is case mix, since the gap shrinks once you standardize for a single procedure, but it still runs counter to the "better rating = cheaper care" assumption. Hospital volume also doesn't show any real economies of scale on payment per case.

## Data

| Dataset | Grain | Source |
|---|---|---|
| Medicare Inpatient Hospitals — by Provider & Service | hospital × MS-DRG, annual | [data.cms.gov](https://data.cms.gov/provider-summary-by-type-of-service/medicare-inpatient-hospitals/medicare-inpatient-hospitals-by-provider-and-service) |
| Hospital General Information (Care Compare) | hospital | [data.cms.gov](https://data.cms.gov/provider-data/dataset/xubh-q36u) |

The two sources join on the CMS Certification Number (CCN), adding ownership type and overall star rating to every charge record. Original Medicare (fee-for-service) Part A only; CMS suppresses rows with fewer than 11 discharges.

## The 12 analyses (`sql/analysis/`)

| # | Question | SQL techniques |
|---|---|---|
| q01 | National scale: discharges, billed vs paid, markup | aggregates, derived metrics |
| q02 | Which DRGs drive Medicare spend, and how concentrated is it? | CTE, `SUM() OVER`, running cumulative % |
| q03 | Which states are most expensive per discharge? | CTE, `RANK()`, weighted averages |
| q04 | Hospitals with extreme charge-to-payment markups | `HAVING` volume filter, `RANK()`, dim join |
| q05 | Price variation for an identical procedure (DRG 470) | weighted avg, within-state spread ratio |
| q06 | Billing behavior by ownership type (for-profit vs non-profit) | fact→dim join, grouped weighted metrics |
| q07 | Do higher star ratings cost more? | `FILTER (WHERE …)` conditional aggregation |
| q08 | Rural vs urban cost and volume divide | `CASE` bucketing on RUCA codes |
| q09 | The most common inpatient diagnosis per state | `ROW_NUMBER() OVER (PARTITION BY …)` |
| q10 | Market concentration: top-3 hospital share by state | nested CTEs, conditional aggregation |
| q11 | Which DRGs leave the biggest patient/third-party gap? | derived payment-gap metric |
| q12 | Do high-volume hospitals do it cheaper? (economies of scale) | `NTILE(4)` volume quartiles |

Everything runs against a real PostgreSQL database, no ORM, just raw SQL with CTEs, window functions, and `FILTER`.

## Project structure

```
├── data/                    # raw CMS CSVs (not committed — see below)
├── sql/
│   ├── 01_schema.sql        # DDL: star-ish schema, fact + dimension
│   └── analysis/            # q01–q12, one business question each
├── scripts/
│   ├── 01_build_db.py       # CSV → Postgres (cleaning, dedupe, type coercion)
│   ├── 02_run_queries.py    # runs every query, exports CSV + JSON
│   └── 03_build_dashboard.py# injects results into the dashboard template
├── outputs/
│   └── results/             # one CSV per query + all_results.json
└── dashboard.html           # interactive dashboard (Chart.js)
```

## Reproduce

1. Have PostgreSQL running locally and create a database: `createdb medicare`
2. `pip install -r requirements.txt`
3. Download the two CSVs (links above) into `data/`
4. `python3 scripts/01_build_db.py`
5. `python3 scripts/02_run_queries.py`
6. `python3 scripts/03_build_dashboard.py` → open `dashboard.html`

By default the scripts connect to `dbname=medicare` on localhost. To point elsewhere, set `DATABASE_URL` (e.g. `postgresql://user:pass@host:5432/medicare`).
