-- ============================================================
-- Medicare Inpatient Cost & Quality Analysis
-- Schema definition (PostgreSQL)
--
-- Data sources:
--   1. CMS Medicare Inpatient Hospitals - by Provider and Service
--      (IPPS discharges, charges & payments by hospital x DRG)
--   2. CMS Hospital General Information (Care Compare)
--      (hospital metadata + overall star ratings)
-- ============================================================

-- Dimension: one row per hospital (Care Compare)
CREATE TABLE hospitals (
    facility_id            VARCHAR(6) PRIMARY KEY,  -- CMS Certification Number (CCN)
    facility_name          TEXT        NOT NULL,
    city                   TEXT,
    state                  CHAR(2),
    zip_code               VARCHAR(10),
    county                 TEXT,
    hospital_type          TEXT,
    hospital_ownership     TEXT,
    emergency_services     BOOLEAN,
    overall_rating         SMALLINT    CHECK (overall_rating BETWEEN 1 AND 5)
);

-- Fact: one row per hospital x MS-DRG (annual aggregates)
CREATE TABLE inpatient_charges (
    provider_ccn           VARCHAR(6)  NOT NULL,
    provider_name          TEXT        NOT NULL,
    provider_city          TEXT,
    provider_state         CHAR(2),
    provider_zip           VARCHAR(5),
    ruca_code              TEXT,                    -- rural-urban commuting area
    ruca_desc              TEXT,
    drg_code               VARCHAR(3)  NOT NULL,
    drg_desc               TEXT        NOT NULL,
    total_discharges       INTEGER     NOT NULL,
    avg_covered_charges    NUMERIC(12,2) NOT NULL,  -- what the hospital billed
    avg_total_payment      NUMERIC(12,2) NOT NULL,  -- what was actually paid (all payers)
    avg_medicare_payment   NUMERIC(12,2) NOT NULL,  -- Medicare's portion
    PRIMARY KEY (provider_ccn, drg_code)
);

-- Indexes to support the analysis workload
CREATE INDEX idx_charges_state ON inpatient_charges (provider_state);
CREATE INDEX idx_charges_drg   ON inpatient_charges (drg_code);
CREATE INDEX idx_hospitals_state ON hospitals (state);

-- Note: inpatient_charges.provider_ccn joins to hospitals.facility_id.
-- FK intentionally omitted: the two files are published on different
-- cycles, so a small share of CCNs won't match (handled via LEFT JOIN).
