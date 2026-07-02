-- ============================================================
-- Q1. National KPIs: the headline numbers
-- Business question: What is the overall scale of Medicare
-- inpatient care — volume, billed charges vs actual payments?
-- Techniques: aggregate functions, derived metrics, NULLIF
-- ============================================================

SELECT
    COUNT(DISTINCT provider_ccn)                                   AS hospitals,
    COUNT(DISTINCT drg_code)                                       AS distinct_drgs,
    SUM(total_discharges)                                          AS total_discharges,
    ROUND(SUM(total_discharges * avg_covered_charges) / 1e9, 2)    AS billed_charges_usd_bn,
    ROUND(SUM(total_discharges * avg_total_payment)   / 1e9, 2)    AS total_payments_usd_bn,
    ROUND(SUM(total_discharges * avg_medicare_payment) / 1e9, 2)   AS medicare_payments_usd_bn,
    -- hospitals bill far more than they are paid; this is the average markup
    ROUND(SUM(total_discharges * avg_covered_charges)
        / NULLIF(SUM(total_discharges * avg_total_payment), 0), 2) AS charge_to_payment_ratio,
    ROUND(SUM(total_discharges * avg_total_payment)
        / NULLIF(SUM(total_discharges), 0), 0)                     AS avg_payment_per_discharge
FROM inpatient_charges;
