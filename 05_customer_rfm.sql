-- ============================================================
-- Query 5: Customer (payer_vpa) Base Table
-- Foundation for RFM segmentation AND Phase 3 fraud rules
-- (e.g. "amount vs customer's own historical average" needs
--  avg_amount / stddev_amount computed here)
-- ============================================================
USE upi_insights;

-- 5a. Core per-customer profile
CREATE OR REPLACE VIEW vw_customer_profile AS
SELECT
    payer_vpa,
    COUNT(*)                                              AS frequency,
    SUM(amount)                                           AS monetary_total,
    ROUND(AVG(amount), 2)                                 AS avg_amount,
    ROUND(STDDEV(amount), 2)                              AS stddev_amount,
    MIN(timestamp)                                        AS first_txn,
    MAX(timestamp)                                        AS last_txn,
    DATEDIFF((SELECT MAX(timestamp) FROM upi_transactions), MAX(timestamp)) AS recency_days,
    ROUND(SUM(status='Success') / COUNT(*) * 100, 2)      AS success_rate_pct,
    COUNT(DISTINCT merchant_category)                     AS distinct_categories,
    SUM(HOUR(timestamp) BETWEEN 2 AND 4)                  AS night_txn_count
FROM upi_transactions
GROUP BY payer_vpa;

-- 5b. RFM scoring (quintiles 1-5, 5 = best) — standard RFM approach
CREATE OR REPLACE VIEW vw_customer_rfm AS
SELECT
    payer_vpa,
    frequency,
    monetary_total,
    recency_days,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- lower recency_days = more recent = higher score
    NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
    NTILE(5) OVER (ORDER BY monetary_total ASC) AS m_score
FROM vw_customer_profile;

-- 5c. RFM segment labels (simple, explainable buckets)
CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT
    payer_vpa,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 4 AND f_score >= 3                 THEN 'Loyal'
        WHEN r_score <= 2 AND f_score >= 4                 THEN 'At Risk (was frequent)'
        WHEN r_score <= 2 AND f_score <= 2                 THEN 'Dormant'
        WHEN r_score >= 4 AND f_score <= 2                 THEN 'New / Occasional'
        ELSE 'Regular'
    END AS segment
FROM vw_customer_rfm;

-- 5d. Segment summary (for a quick "how many customers per segment" chart)
CREATE OR REPLACE VIEW vw_segment_summary AS
SELECT
    segment,
    COUNT(*)                    AS customer_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM vw_customer_segments) * 100, 2) AS pct_of_customers
FROM vw_customer_segments
GROUP BY segment
ORDER BY customer_count DESC;
