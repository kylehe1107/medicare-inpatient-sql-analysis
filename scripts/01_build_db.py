#!/usr/bin/env python3
"""
Build the PostgreSQL database from raw CMS CSVs.

Inputs (place in data/):
  - MUP_INP_*PrvSvc*.csv / MUP_IHP_*PRVSVC*.csv  (Medicare Inpatient by Provider & Service)
  - Hospital General Information CSV             (Care Compare)

Output:
  - a Postgres database (tables: inpatient_charges, hospitals)

Connection is controlled via the standard libpq environment variables
(PGHOST, PGPORT, PGUSER, PGPASSWORD) or DATABASE_URL. Defaults to a
local database named "medicare".
"""
import csv
import glob
import os
import re
import sys

import psycopg2

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
SCHEMA = os.path.join(ROOT, "sql", "01_schema.sql")
DSN = os.environ.get("DATABASE_URL", "dbname=medicare")


def norm(s: str) -> str:
    """normalize a header name: 'Facility ID' -> 'facility_id'"""
    return re.sub(r"[^a-z0-9]+", "_", s.strip().lower().replace("﻿", "")).strip("_")


def find_files():
    csvs = [f for f in glob.glob(os.path.join(DATA, "*.csv")) + glob.glob(os.path.join(DATA, "*.CSV"))]
    inpatient, hospital = None, None
    for f in csvs:
        with open(f, encoding="utf-8-sig", errors="replace") as fh:
            header = [norm(h) for h in next(csv.reader(fh))]
        if "drg_cd" in header or "drg_code" in header:
            inpatient = f
        elif "facility_id" in header or "hospital_overall_rating" in header:
            hospital = f
    return inpatient, hospital


INPATIENT_MAP = {
    "rndrng_prvdr_ccn": "provider_ccn",
    "rndrng_prvdr_org_name": "provider_name",
    "rndrng_prvdr_city": "provider_city",
    "rndrng_prvdr_state_abrvtn": "provider_state",
    "rndrng_prvdr_zip5": "provider_zip",
    "rndrng_prvdr_ruca": "ruca_code",
    "rndrng_prvdr_ruca_desc": "ruca_desc",
    "drg_cd": "drg_code",
    "drg_desc": "drg_desc",
    "tot_dschrgs": "total_discharges",
    "avg_submtd_cvrd_chrg": "avg_covered_charges",
    "avg_tot_pymt_amt": "avg_total_payment",
    "avg_mdcr_pymt_amt": "avg_medicare_payment",
}

HOSPITAL_MAP = {
    "facility_id": "facility_id",
    "facility_name": "facility_name",
    "citytown": "city",
    "city_town": "city",
    "city": "city",
    "state": "state",
    "zip_code": "zip_code",
    "countyparish": "county",
    "county_parish": "county",
    "hospital_type": "hospital_type",
    "hospital_ownership": "hospital_ownership",
    "emergency_services": "emergency_services",
    "hospital_overall_rating": "overall_rating",
}


def load_inpatient(cur, path):
    with open(path, encoding="utf-8-sig", errors="replace", newline="") as fh:
        reader = csv.reader(fh)
        header = [norm(h) for h in next(reader)]
        idx = {INPATIENT_MAP[h]: i for i, h in enumerate(header) if h in INPATIENT_MAP}
        cols = list(idx.keys())
        insert_sql = f"INSERT INTO inpatient_charges ({','.join(cols)}) VALUES ({','.join('%s' for _ in cols)})"
        rows, n = [], 0
        seen = set()
        for r in reader:
            key = (r[idx["provider_ccn"]], r[idx["drg_code"]])
            if key in seen:
                continue
            seen.add(key)
            rows.append([r[idx[c]] or None for c in cols])
            if len(rows) >= 20000:
                cur.executemany(insert_sql, rows)
                n += len(rows)
                rows = []
        if rows:
            cur.executemany(insert_sql, rows)
            n += len(rows)
    return n


def load_hospitals(cur, path):
    with open(path, encoding="utf-8-sig", errors="replace", newline="") as fh:
        reader = csv.reader(fh)
        header = [norm(h) for h in next(reader)]
        idx = {}
        for i, h in enumerate(header):
            if h in HOSPITAL_MAP and HOSPITAL_MAP[h] not in idx:
                idx[HOSPITAL_MAP[h]] = i
        cols = list(idx.keys())
        insert_sql = f"INSERT INTO hospitals ({','.join(cols)}) VALUES ({','.join('%s' for _ in cols)})"
        rows, seen = [], set()
        for r in reader:
            fid = r[idx["facility_id"]]
            if fid in seen:
                continue
            seen.add(fid)
            row = []
            for c in cols:
                v = r[idx[c]].strip() if idx[c] < len(r) else None
                if c == "overall_rating":
                    v = int(v) if v and v.isdigit() else None
                elif c == "emergency_services":
                    v = {"yes": True, "no": False}.get((v or "").lower())
                row.append(v if v not in ("", "Not Available") else None)
            rows.append(row)
        cur.executemany(insert_sql, rows)
    return len(rows)


def main():
    inpatient, hospital = find_files()
    if not inpatient or not hospital:
        sys.exit(f"Missing input CSVs in data/ (found inpatient={inpatient}, hospital={hospital})")

    con = psycopg2.connect(DSN)
    cur = con.cursor()
    cur.execute("DROP TABLE IF EXISTS inpatient_charges")
    cur.execute("DROP TABLE IF EXISTS hospitals")
    cur.execute(open(SCHEMA).read())
    n_hosp = load_hospitals(cur, hospital)
    n_inp = load_inpatient(cur, inpatient)
    con.commit()
    cur.execute("""SELECT COUNT(DISTINCT ic.provider_ccn) FROM inpatient_charges ic
                   JOIN hospitals h ON h.facility_id = ic.provider_ccn""")
    matched = cur.fetchone()[0]
    cur.execute("SELECT COUNT(DISTINCT provider_ccn) FROM inpatient_charges")
    total = cur.fetchone()[0]
    print(f"hospitals dim:        {n_hosp:,} rows")
    print(f"inpatient_charges:    {n_inp:,} rows")
    print(f"CCN join coverage:    {matched}/{total} hospitals matched to Care Compare")
    cur.close()
    con.close()


if __name__ == "__main__":
    main()
