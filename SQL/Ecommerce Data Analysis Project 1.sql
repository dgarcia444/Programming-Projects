USE mavenfuzzyfactory;

-- 1. pull monthly trends for gsearch sessions and gsearch orders

SELECT * FROM website_sessions;
SELECT * FROM orders;

SELECT 
	MIN(DATE(website_sessions.created_at)) AS start_date,
	COUNT(DISTINCT website_sessions.website_session_id) AS gsearch_sessions,
    COUNT(DISTINCT orders.order_id) AS gsearch_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(website_sessions.created_at))
;

-- 2. Similar monthly trend for gsearch
-- Split out nonbrand and brand campaigns
SELECT 
	MIN(DATE(website_sessions.created_at)) AS start_date,
    website_sessions.utm_campaign AS campaigns,
	COUNT(DISTINCT website_sessions.website_session_id) AS gsearch_sessions,
    COUNT(DISTINCT orders.order_id) AS gsearch_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(website_sessions.created_at)), campaigns
;

-- 3. Dive into nonbrand, pull monthly sessions and orders: split by device type
SELECT 
	MIN(DATE(website_sessions.created_at)) AS dates,
    website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY MONTH(DATE(website_sessions.created_at)), website_sessions.device_type
;

-- 4. Pulling monthly trends for Gsearch, alongside monthly trends for each of the other channels
SELECT 
	MIN(DATE(website_sessions.created_at)) AS start_date,
    website_sessions.utm_source AS sources,
	COUNT(DISTINCT website_sessions.website_session_id) AS channel_sessions,
    COUNT(DISTINCT orders.order_id) AS channel_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	 AND utm_source IS NOT NULL
GROUP BY MONTH(DATE(website_sessions.created_at)), sources
;

-- 5. Pull session to order conversion rate by month
SELECT 
	MIN(DATE(website_sessions.created_at)) AS start_date,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    CONCAT(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100,'%') AS session_to_order_rate
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	 -- AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(website_sessions.created_at))
;

-- 6. For the Gsearch lander test, estimate the revenue that was earned
-- Look at the session to order conversion rate from the test (July 19th - July 28th)
-- Use nonbrand sessions & revenue since then
SELECT * FROM website_pageviews;

SELECT
	MIN(created_at) AS start_date,
    MIN(website_pageview_id),
    pageview_url
FROM website_pageviews
WHERE pageview_url = '/lander-1'
;

-- Gather first pageview id for each relevant session
CREATE TEMPORARY TABLE first_views
SELECT 
	MIN(DATE(website_pageviews.created_at)) AS start_date,
    website_pageviews.website_session_id AS sessions,
    MIN(website_pageviews.website_pageview_id) AS first_view_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28'
GROUP BY sessions
;

DROP TABLE first_views;

-- 2. Identify the landing_page url for each session
-- limit this to lander-1
CREATE TEMPORARY TABLE landing_page
SELECT
	first_views.start_date,
    first_views.sessions, 
    website_pageviews.pageview_url AS landing_page
FROM first_views
LEFT JOIN website_pageviews
	ON first_views.sessions = website_pageviews.website_session_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1')
;

SELECT * FROM landing_page;
DROP TABLE landing_page;

-- compare conversion rates from home and lander-1
-- compare estimated revenue earned for each order during the test
SELECT
	landing_page.landing_page,
    COUNT(DISTINCT landing_page.sessions) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    CONCAT(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT landing_page.sessions)*100,'%') AS conv_rate,
    SUM(price_usd) AS revenue
FROM landing_page
LEFT JOIN orders
	ON orders.website_session_id = landing_page.sessions
GROUP BY landing_page.landing_page
;

-- find the most recent pageview for gsearch nonbrand where traffic was sent to home
-- this is the moment when the landing page test ended
-- this is our starting point for comparing since the test ended
SELECT
	MAX(DATE(website_sessions.created_at)) AS most_recent_date,
	MAX(website_sessions.website_session_id) as most_recent_page_id,
    website_pageviews.pageview_url AS recent_page 
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND website_sessions.created_at < '2012-11-27'
;

-- Count how many sessions we've had since the test ended
SELECT
	COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions_since_test_ended, -- sessions since test ended
    COUNT(DISTINCT website_sessions.website_session_id)*0.008543 AS sessions_gained_since_test, -- sessions * difference in conversion rate
    SUM(orders.price_usd)*0.008543 AS revenue_gained_since_test
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.website_session_id > 17145 -- the final session of the landing page testS
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand';
    
-- 7. Show 2 full conversion funnels from:
-- 1) /home -> /products -> /cart -> /shipping -> /billing -> /thank-you-for-your-order
-- 2) /lander-1 -> /products -> /cart -> /shipping -> /billing -> /thank-you-for-your-order

SELECT * FROM website_sessions;
-- grab a list of all pages
SELECT 
	DISTINCT pageview_url
FROM website_pageviews;

-- Select all pageviews for relevant sessions
-- 1) /home -> /products -> /cart -> /shipping -> /billing -> /thank-you-for-your-order
-- 2) /lander-1 -> /products -> /cart -> /shipping -> /billing -> /thank-you-for-your-order

-- funnels 
CREATE TEMPORARY TABLE funnels
SELECT
	website_session_id,
    MAX(home) AS started_at_home,
    MAX(lander) AS started_at_lander,
    MAX(products) as reached_products,
    MAX(mrfuzzy) AS reached_mrfuzzy,
    MAX(cart) AS reached_cart,
    MAX(shipping) AS reached_shipping,
    MAX(billing) AS reached_billing,
    MAX(orders) AS reached_the_end
FROM(
SELECT 
	website_sessions.website_session_id,
    website_pageviews.pageview_url AS pages,
    website_pageviews.created_at AS start_date,
    -- creating flags
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END as home,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END as lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS orders
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-29'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
	-- AND website_pageviews.pageview_url IN ('/home', '/products', '/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order') -- getting from home
ORDER BY 
	website_sessions.website_session_id,
    website_pageviews.created_at
)AS funnels
GROUP BY website_session_id
;

SELECT * FROM funnels;
DROP TABLE funnels;

-- now translate into click rates

-- make a case statement to differentiate the conversion funnels, 
-- if the start flags is 1, then flag as seen, group by the result
SELECT
	CASE
		WHEN started_at_home = 1 THEN 'Home Start'
        WHEN started_at_lander = 1 THEN 'Lander Start'
        ELSE 'Logic failed, try again'
        END AS 'Starting Points',
    COUNT(DISTINCT CASE WHEN reached_products = 1 THEN website_session_id ELSE NULL END) AS to_products, -- count sessions that went to product
    COUNT(DISTINCT CASE WHEN reached_mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy, -- count sessions that went to mrfuzzy page
    COUNT(DISTINCT CASE WHEN reached_cart = 1 THEN website_session_id ELSE NULL END) AS to_cart, -- count sessions that went to cart
    COUNT(DISTINCT CASE WHEN reached_shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping, -- count sessions that went to product
    COUNT(DISTINCT CASE WHEN reached_billing = 1 THEN website_session_id ELSE NULL END) AS to_billing, -- count sessions that went to mrfuzzy page
    COUNT(DISTINCT CASE WHEN reached_the_end = 1 THEN website_session_id ELSE NULL END) AS to_end_of_order -- count sessions that went to cart
FROM funnels
GROUP BY 1
;

-- now calculate the click rate for each conversion funnel
SELECT
	CASE
		WHEN started_at_home = 1 THEN 'Home Start'
        WHEN started_at_lander = 1 THEN 'Lander Start'
        ELSE 'Logic failed, try again'
        END AS 'Starting Points',
    CONCAT(COUNT(DISTINCT CASE WHEN reached_products = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id)*100,'%') AS to_products, 
    CONCAT(COUNT(DISTINCT CASE WHEN reached_mrfuzzy = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN reached_products = 1 THEN website_session_id ELSE NULL END)*100,'%') AS to_mrfuzzy, 
    CONCAT(COUNT(DISTINCT CASE WHEN reached_cart = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN reached_mrfuzzy = 1 THEN website_session_id ELSE NULL END)*100,'%') AS to_cart, 
    CONCAT(COUNT(DISTINCT CASE WHEN reached_shipping = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN reached_cart = 1 THEN website_session_id ELSE NULL END)*100,'%') AS to_shipping, 
    CONCAT(COUNT(DISTINCT CASE WHEN reached_billing = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN reached_shipping = 1 THEN website_session_id ELSE NULL END)*100,'%') AS to_billing, 
    CONCAT(COUNT(DISTINCT CASE WHEN reached_the_end = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN reached_billing = 1 THEN website_session_id ELSE NULL END)*100,'%') AS to_end_of_order 
FROM funnels
GROUP BY 1
;

-- 8. Quantify the impact from the billing page test
-- Analyze the lift generated from the lest (9/10 - 11/10) in terms of revenue per billing page session
-- sessions generated after the test was completed
-- Pull the number of billing page sessions for the past month to understand monthly impact

-- Get the conversion rate for billing and billing-2

-- Gather first pageview id for each relevant session
CREATE TEMPORARY TABLE first_views_2
SELECT 
	MIN(DATE(website_pageviews.created_at)) AS start_date,
    website_pageviews.website_session_id AS sessions,
    MIN(website_pageviews.website_pageview_id) AS first_view_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
	-- AND utm_source = 'gsearch'
    -- AND utm_campaign = 'nonbrand'
    AND website_sessions.created_at BETWEEN '2012-09-10' AND '2012-11-10'
GROUP BY sessions
;

SELECT * FROM first_views_2;
DROP TABLE first_views_2;

CREATE TEMPORARY TABLE landing_pages_billing
SELECT
	first_views_2.start_date,
    first_views_2.sessions, 
    website_pageviews.pageview_url AS landing_page
FROM first_views_2
LEFT JOIN website_pageviews
	ON first_views_2.sessions = website_pageviews.website_session_id
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
;

SELECT * FROM landing_pages_billing;
DROP TABLE landing_pages_billing;

-- Analyze the conversion rate
SELECT
	landing_pages_billing.landing_page,
    COUNT(DISTINCT landing_pages_billing.sessions) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    CONCAT(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT landing_pages_billing.sessions)*100,'%') AS conv_rate,
	CONCAT('$',ROUND(SUM(price_usd)/COUNT(DISTINCT landing_pages_billing.sessions),2)) AS revenue_per_session
FROM landing_pages_billing
LEFT JOIN orders
	ON orders.website_session_id = landing_pages_billing.sessions
GROUP BY landing_pages_billing.landing_page
;

-- 0.611111 - 0.437811 = 0.173301 (gsearch, nonbrand) improvement on conversion rate
-- 0.626911 - 0.455927 = 0.170984 (all traffic)
-- price/sessions
-- Billing - $22.79 per session 
-- Billing 2  - $31.34 per session

SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;
-- Grab the amount of views on the billing pages for the past month (10-27 to 11-27)
-- multiply the amount of sessions by the revenue lift ($8.51) to determine the total value od the billing pages
SELECT
	COUNT(DISTINCT website_pageviews.website_session_id) AS 'Sessions for November So Far',
    ROUND(COUNT(DISTINCT website_pageviews.website_session_id)*0.170984) AS 'Gained Sessions for the past month',
	CONCAT('$',ROUND(SUM(orders.price_usd)/COUNT(DISTINCT website_pageviews.website_session_id),2)) AS 'Revenue Per Session from 10-27 to 11-27',
    CONCAT('$',ROUND(COUNT(DISTINCT website_pageviews.website_session_id)*8.51,2)) AS 'Total Value of Billing Pages from 10-27 to 11-27'
FROM website_pageviews
LEFT JOIN orders
	 ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-10-27' AND '2012-11-27'
	AND website_pageviews.pageview_url IN ('/billing','/billing-2')
;
