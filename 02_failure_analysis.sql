-- ============================================================
-- Query 2: Failure Analysis
-- Answers: failure rate by bank / city / reason, and the
-- August infra-degradation story for Yes Bank & Canara Bank
-- ============================================================
USE upi_insights;

-- 2a. Failure rate by sender bank (overall)
CREATE OR REPLACE VIEW vw_failure_by_bank AS
SELECT
    sender_bank,
    COUNT(*)                                            AS total_transactions,
    SUM(status = 'Failed')                              AS failed_count,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)     AS failure_rate_pct
FROM upi_transactions
GROUP BY sender_bank
ORDER BY failure_rate_pct DESC;

-- 2b. Failure rate by bank AND month (to surface the August dip)
CREATE OR REPLACE VIEW vw_failure_by_bank_month AS
SELECT
    sender_bank,
    DATE_FORMAT(timestamp, '%Y-%m')                     AS txn_month,
    COUNT(*)                                            AS total_transactions,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)     AS failure_rate_pct
FROM upi_transactions
GROUP BY sender_bank, DATE_FORMAT(timestamp, '%Y-%m')
ORDER BY sender_bank, txn_month;

-- 2c. Failure rate by city (top 15 by transaction volume, to avoid tiny-sample noise)
CREATE OR REPLACE VIEW vw_failure_by_city AS
SELECT
    city, state,
    COUNT(*)                                            AS total_transactions,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)     AS failure_rate_pct
FROM upi_transactions
GROUP BY city, state
HAVING COUNT(*) >= 500
ORDER BY failure_rate_pct DESC;

-- 2d. Top failure reasons (overall distribution among failed transactions)
CREATE OR REPLACE VIEW vw_failure_reasons AS
SELECT
    failure_reason,
    COUNT(*)                                            AS occurrence_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM upi_transactions WHERE status='Failed') * 100, 2) AS pct_of_all_failures
FROM upi_transactions
WHERE status = 'Failed'
GROUP BY failure_reason
ORDER BY occurrence_count DESC;

-- 2e. Failure rate by merchant category (P2M only)
CREATE OR REPLACE VIEW vw_failure_by_category AS
SELECT
    merchant_category,
    COUNT(*)                                            AS total_transactions,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)     AS failure_rate_pct
FROM upi_transactions
GROUP BY merchant_category
ORDER BY failure_rate_pct DESC;
