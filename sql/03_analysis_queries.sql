-- Olist E-Commerce analysis: business questions answered in SQL (MySQL 8)
--
-- Rules used in every query:
--   * Only delivered orders (order_status = 'delivered')
--   * Revenue = SUM(order_items.price); freight is excluded
--   * Customers are counted with customer_unique_id (customer_id is per order)
--   * Currency: Brazilian Reais (R$)
--
-- Each result was exported to CSV and loaded into Excel with Power Query.

USE olist_project;

/* ---------------- Q0. KPI summary (export: 00_kpi_summary.csv) ---------------- */
SELECT
 (SELECT COUNT(DISTINCT order_id) FROM orders WHERE order_status = 'delivered') AS total_orders,
 (SELECT ROUND(SUM(oi.price), 2) FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered') AS total_revenue,
 (SELECT COUNT(DISTINCT c.customer_unique_id) FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered') AS unique_customers,
 (SELECT ROUND(AVG(r.review_score), 2) FROM order_reviews r
    JOIN orders o ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered') AS avg_review_score,
 (SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1)
    FROM orders
    WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL) AS avg_delivery_days;

/* ---------------- Q1. Monthly revenue, orders and growth (01_monthly_revenue.csv) ---------------- */
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
           COUNT(DISTINCT o.order_id) AS total_orders,
           SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT order_month, total_orders, ROUND(revenue, 2) AS revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month))
             / LAG(revenue) OVER (ORDER BY order_month) * 100, 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

/* ---------------- Q2. Revenue by product category (02_category_revenue.csv) ---------------- */
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue,
       ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2) AS revenue_share_pct,
       RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC;

/* ---------------- Q3a. Repeat vs one-time customers (03_customer_type.csv) ---------------- */
WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS order_count,
           SUM(oi.price) AS revenue
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT CASE WHEN order_count = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM cust
GROUP BY customer_type;

/* ---------------- Q3b. Monthly cohort retention (03b_cohort_retention.csv) ---------------- */
-- A cohort = customers whose first delivered order was in the same month.
-- month_number = months since that first order (0 = the first order month).
WITH orders_c AS (
    SELECT c.customer_unique_id,
           DATE_FORMAT(o.order_purchase_timestamp, '%Y%m') AS ym
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort AS (
    SELECT customer_unique_id, MIN(ym) AS cohort_ym
    FROM orders_c
    GROUP BY customer_unique_id
),
activity AS (
    SELECT DISTINCT oc.customer_unique_id, co.cohort_ym,
           PERIOD_DIFF(oc.ym, co.cohort_ym) AS month_number
    FROM orders_c oc
    JOIN cohort co ON oc.customer_unique_id = co.customer_unique_id
)
SELECT cohort_ym, month_number, COUNT(DISTINCT customer_unique_id) AS customers
FROM activity
WHERE month_number <= 6
GROUP BY cohort_ym, month_number
ORDER BY cohort_ym, month_number;

/* ---------------- Q4a. Review score vs delivery time (04_review_vs_delivery.csv) ---------------- */
SELECT r.review_score,
       COUNT(*) AS reviews,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
       ROUND(100 * AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date), 1) AS pct_late
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;

/* ---------------- Q4b. Late vs on-time average score (04b_late_vs_ontime.csv) ---------------- */
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On time' END AS delivery_status,
       COUNT(*) AS reviews,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

/* ---------------- Q4c. Delivery time by customer state (04c_delivery_by_state.csv) ---------------- */
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

/* ---------------- Q5. Payment methods (05_payment_methods.csv) ---------------- */
-- An order can use more than one payment type, so order counts overlap;
-- use total_value for shares.
SELECT payment_type,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(payment_value), 2) AS total_value,
       ROUND(100 * SUM(payment_value) / SUM(SUM(payment_value)) OVER (), 2) AS value_share_pct,
       ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
WHERE order_id IN (SELECT order_id FROM orders WHERE order_status = 'delivered')
GROUP BY payment_type
ORDER BY total_value DESC;
