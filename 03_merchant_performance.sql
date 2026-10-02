-- ============================================================
-- Query 3: Merchant Performance
-- Answers: success rate, revenue contribution, avg ticket size,
-- and a ranking to flag merchants needing review
-- ============================================================
USE upi_insights;

-- 3a. Core merchant performance table (P2M transactions only)
CREATE OR REPLACE VIEW vw_merchant_performance AS
SELECT
    merchant_id,
    merchant_category,
    COUNT(*)                                              AS total_transactions,
    SUM(status = 'Success')                               AS successful_transactions,
    ROUND(SUM(status='Success') / COUNT(*) * 100, 2)      AS success_rate_pct,
    ROUND(SUM(CASE WHEN status='Success' THEN amount ELSE 0 END), 2) AS revenue,
    ROUND(AVG(amount), 2)                                  AS avg_ticket_size
FROM upi_transactions
WHERE transaction_type = 'P2M'
GROUP BY merchant_id, merchant_category
HAVING COUNT(*) >= 10   -- exclude near-zero-volume merchants from ranking noise
ORDER BY revenue DESC;

-- 3b. Top 20 merchants by revenue
CREATE OR REPLACE VIEW vw_top20_merchants_by_revenue AS
SELECT * FROM vw_merchant_performance
ORDER BY revenue DESC
LIMIT 20;

-- 3c. Bottom 20 merchants by success rate (candidates for review) — min volume filter
--     so we're not flagging a merchant with only 10 txns and 1 bad-luck failure
CREATE OR REPLACE VIEW vw_merchants_needing_review AS
SELECT * FROM vw_merchant_performance
WHERE total_transactions >= 30
ORDER BY success_rate_pct ASC
LIMIT 20;

-- 3d. Category-level rollup (which categories drive the most revenue/volume)
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    merchant_category,
    COUNT(*)                                              AS total_transactions,
    ROUND(SUM(status='Success') / COUNT(*) * 100, 2)      AS success_rate_pct,
    ROUND(SUM(CASE WHEN status='Success' THEN amount ELSE 0 END), 2) AS revenue,
    ROUND(AVG(amount), 2)                                  AS avg_ticket_size
FROM upi_transactions
WHERE transaction_type = 'P2M'
GROUP BY merchant_category
ORDER BY revenue DESC;

-- 3e. Merchant ranking with percentile bucket (for Power BI drill-down: Top/Mid/Bottom tier)
CREATE OR REPLACE VIEW vw_merchant_ranked AS
SELECT
    merchant_id,
    merchant_category,
    total_transactions,
    success_rate_pct,
    revenue,
    avg_ticket_size,
    NTILE(4) OVER (ORDER BY revenue DESC) AS revenue_quartile   -- 1 = top 25% by revenue
FROM vw_merchant_performance;
