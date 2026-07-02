#!/usr/bin/env python3
"""
Run every analysis query in sql/analysis/ against the Postgres database.
Saves each result to outputs/results/<query>.csv and a combined
outputs/results/all_results.json (consumed by the dashboard).

Connection is controlled via the standard libpq environment variables
(PGHOST, PGPORT, PGUSER, PGPASSWORD) or DATABASE_URL. Defaults to a
local database named "medicare".
"""
import csv
import glob
import json
import os
from decimal import Decimal

import psycopg2

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUERY_DIR = os.path.join(ROOT, "sql", "analysis")
OUT_DIR = os.path.join(ROOT, "outputs", "results")
DSN = os.environ.get("DATABASE_URL", "dbname=medicare")


def jsonable(v):
    """psycopg2 returns NUMERIC columns as Decimal; the dashboard does
    arithmetic (toFixed, sort) on these values, so they need to stay
    JS numbers rather than becoming strings."""
    return float(v) if isinstance(v, Decimal) else v


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    con = psycopg2.connect(DSN)
    all_results = {}
    for path in sorted(glob.glob(os.path.join(QUERY_DIR, "q*.sql"))):
        name = os.path.splitext(os.path.basename(path))[0]
        sql = open(path).read()
        cur = con.cursor()
        try:
            cur.execute(sql)
        except psycopg2.Error as e:
            print(f"FAIL  {name}: {e}")
            con.rollback()
            continue
        cols = [d[0] for d in cur.description]
        rows = [[jsonable(v) for v in row] for row in cur.fetchall()]
        with open(os.path.join(OUT_DIR, f"{name}.csv"), "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(cols)
            w.writerows(rows)
        all_results[name] = {"columns": cols, "rows": rows}
        print(f"OK    {name}: {len(rows)} rows")
    with open(os.path.join(OUT_DIR, "all_results.json"), "w") as fh:
        json.dump(all_results, fh)
    con.close()


if __name__ == "__main__":
    main()
