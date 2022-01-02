USE mavenfuzzyfactory;

-- Pulliing website_session and order volume 
-- trended by the quarter of each year- throughout the life of the busniess

SELECT
	YEAR(website_sessions.created_at) AS 'Year',
	QUARTER(website_sessions.created_at) AS 'Quarter',
    COUNT(DISTINCT website_sessions.website_session_id) AS Sessions,
    COUNT(DISTINCT orders.order_id) AS Orders
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
GROUP BY 1,2
;

SELECT * FROM products;

-- Showing quarterly figures of:
	-- Session-to-order conversion rate
    -- Revenue per order
    -- Revenue per session
    
SELECT
	YEAR(website_sessions.created_at) AS 'Year',
    QUARTER(website_sessions.created_at) AS 'Quarter',
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100
		AS 'Session-to-Order Conversion Rate',
	ROUND(SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id), 2) AS 'Revenue per Order',
    ROUND(SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id), 2) 
		AS 'Revenue per Session'
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
GROUP BY 1,2
;

-- Gathering quarterly views of orders from:
	-- Gsearch nonbrand
    -- Bsearch nonbrand
    -- Brand search overall
    -- organic search (searches from the website_
    -- direct type-in (user types in website name from browser)
    
SELECT
	YEAR(orders.created_at) AS 'Year',
    QUARTER(orders.created_at) AS 'Quarter',
    COUNT(DISTINCT CASE WHEN website_sessions.http_referer = 'https://www.gsearch.com' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
			AS 'Gsearch nonbrand Orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer = 'https://www.bsearch.com' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		AS 'Bsearch nonbrand orders',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		AS 'Brand Overall orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		AS 'Organic Search orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		AS 'Direct Type In orders'
FROM orders
LEFT JOIN website_sessions
	ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
;

-- Pulling overall session-to-order conversion rate for 
	-- Gsearch nonbrand
    -- Bsearch nonbrand
    -- Brand search overall
    -- organic search (searches from the website)
    -- direct type-in (user types in website name from browser)
    
SELECT
	  YEAR(website_sessions.created_at) AS 'Year',
       QUARTER(website_sessions.created_at) AS 'Quarter',
     -- MAKEDATE(YEAR(website_sessions.created_at), 1) + INTERVAL QUARTER(website_sessions.created_at) QUARTER -
	-- INTERVAL 1 QUARTER  AS 'Quarter',
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) * 100
			AS 'Gsearch nonbrand Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END)* 100
		AS 'Bsearch nonbrand Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) * 100
		AS 'Brand Overall Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN website_sessions.website_session_id ELSE NULL END) * 100
		AS 'Organic Search Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN website_sessions.website_session_id ELSE NULL END) * 100
		AS 'Direct Type In Conversion Rate'
FROM  website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
;
-- Pulling monthly trends for revenue and margin by product

SELECT
	YEAR(created_at) AS 'Year',
	MONTH(created_at) AS 'Month',
    -- DATE_FORMAT(created_at,'%m-%d-%Y') AS 'date',
    -- Product 1
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS 'Mr. Fuzzy Revenue',
    COUNT(CASE WHEN product_id = 1 THEN order_id ELSE NULL END) AS 'Mr. Fuzzy Sales',
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS 'Mr. Fuzzy Margin',
    -- Product 2
	SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS 'The Forever Love Bear Revenue',
    COUNT(CASE WHEN product_id = 2 THEN order_id ELSE NULL END) AS 'The Forever Love Bear Sales',
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Forever Love Bear Margin',
    -- Product 3
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS 'The Birthday Sugar Panda Revenue',
    COUNT(CASE WHEN product_id = 3 THEN order_id ELSE NULL END) AS 'The Birthday Sugar Panda Sales',
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Birthday Sugar Panda Margin',
    -- Product 4
	SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS 'The Hudson River Mini bear Revenue',
    COUNT(CASE WHEN product_id = 4 THEN order_id ELSE NULL END) AS 'The Hudson River Mini bear Sales',
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Hudson River Mini bear Margin',
    -- Total Sales, Revenue & Margin
    COUNT(DISTINCT order_id) AS 'Total Sales',
    SUM(price_usd) AS 'Total Revenue',
    SUM(price_usd - cogs_usd) AS 'Total Margin'
FROM order_items
GROUP BY 1,2
;

-- Taking a deep dive into the impact of introducing new products 

SELECT * FROM website_pageviews;

DROP TABLE IF EXISTS products_to_next_page;
CREATE TEMPORARY TABLE products_to_next_page
SELECT
    sessions_in_product.created_at AS created_at,
	sessions_in_product.sessions AS product_sessions, -- get all of the sessions that hit product
    website_pageviews.pageview_url AS next_page, -- grab the url of the next page
    MIN(website_pageviews.website_pageview_id) AS next_page_id -- grab the min pageview id, tells us the next page
FROM(
SELECT
	created_at, -- grab where the session is created at
    website_session_id AS sessions, -- grab the session
    website_pageview_id AS pageview_id -- grab the pageview_id for that session
FROM website_pageviews
WHERE pageview_url = '/products' -- where url == products
GROUP BY 1,2
) AS sessions_in_product
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = sessions_in_product.sessions -- make sure sessions are the same
    AND website_pageviews.website_pageview_id > sessions_in_product.pageview_id -- make sure website_pageviews's id is bigger than the subquery's pageview_id
GROUP BY product_sessions
;

SELECT * FROM products_to_next_page; -- QA

-- summarize the data
SELECT
	YEAR(products_to_next_page.created_at) AS 'Year', -- get the year
    MONTH(products_to_next_page.created_at) AS 'Month', -- get the month
    -- DATE_FORMAT(products_to_next_page.created_at,'%m-%d-%Y') AS 'date',
	COUNT(CASE WHEN next_page IS NOT NULL THEN product_sessions ELSE NULL END) AS next_page, -- count sessions that made it to the next page
    COUNT(DISTINCT product_sessions) AS total_sessions, -- count the total sessions
    COUNT(CASE WHEN next_page IS NOT NULL THEN product_sessions ELSE NULL END) -- get a percentage of sessions that made it to a next page
		/ COUNT(DISTINCT product_sessions) * 100 AS 'To Next Page',
	COUNT(DISTINCT orders.order_id) AS orders, -- grab total orders
    -- get a percentage of being on the products page leading to an order being placed
	COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT products_to_next_page.product_sessions) * 100  AS 'From /product to Placing an Order'
    
FROM products_to_next_page
LEFT JOIN orders
	ON orders.website_session_id = products_to_next_page.product_sessions
GROUP BY 1,2
;
SELECT * FROM orders;

-- Pulling sales data since the launch of the 4th product on Decenber 5th 2014
-- Also showing how each product cross sells from one another

SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM products;

SELECT 
	orders.primary_product_id,
    products.product_name,
    COUNT(DISTINCT orders.order_id) AS total_orders,
	SUM(order_items.price_usd) AS revenue,
    SUM(order_items.price_usd - order_items.cogs_usd) AS margin,
    ROUND(AVG(order_items.price_usd), 2) AS average_order_value,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS cross_sell_product_1,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS cross_sell_product_2,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS cross_sell_product_3,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) AS cross_sell_product_4,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_1,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_2,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) *100
		AS cross_sell_rate_3,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_4
FROM orders
LEFT JOIN order_items
	ON order_items.order_id = orders.order_id
    -- only bring in items that were cross-sold
    AND order_items.is_primary_item = 0 -- cross-sell only
JOIN products
	ON orders.primary_product_id = products.product_id
WHERE orders.created_at > '2014-12-05'
GROUP BY 1
;	

-- Creating views for visualization purposes 

CREATE VIEW session_and_order_volume AS 
SELECT
	-- YEAR(website_sessions.created_at) AS 'Year',
	-- QUARTER(website_sessions.created_at) AS 'Quarter',
	MAKEDATE(YEAR(website_sessions.created_at), 1) + INTERVAL QUARTER(website_sessions.created_at) QUARTER -
	INTERVAL 1 QUARTER  AS 'Quarter', -- makes visualizing the data easier
    COUNT(DISTINCT website_sessions.website_session_id) AS Sessions,
    COUNT(DISTINCT orders.order_id) AS Orders
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
    WHERE website_sessions.created_at < '2015-01-01'
GROUP BY 1
;

CREATE VIEW website_efficiency_metrics AS 
SELECT
	-- YEAR(website_sessions.created_at) AS 'Year',
    -- QUARTER(website_sessions.created_at) AS 'Quarter',
    MAKEDATE(YEAR(website_sessions.created_at), 1) + INTERVAL QUARTER(website_sessions.created_at) QUARTER -
	INTERVAL 1 QUARTER  AS 'Quarter',
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100
		AS 'Session-to-Order Conversion Rate',
	ROUND(SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id), 2) AS 'Revenue per Order',
    ROUND(SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id), 2) 
		AS 'Revenue per Session'
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2015-01-01'
GROUP BY 1
;

CREATE VIEW channel_traffic_analysis AS 
SELECT
	-- YEAR(orders.created_at) AS 'Year',
    -- QUARTER(orders.created_at) AS 'Quarter',
	DATE_FORMAT(orders.created_at,'%m-%d-%Y') AS 'date',
    COUNT(DISTINCT CASE WHEN website_sessions.http_referer = 'https://www.gsearch.com' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
			AS 'Gsearch nonbrand Orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer = 'https://www.bsearch.com' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		AS 'Bsearch nonbrand orders',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		AS 'Brand Overall orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		AS 'Organic Search orders',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		AS 'Direct Type In orders'
FROM orders
LEFT JOIN website_sessions
	ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1
;

CREATE VIEW channel_efficiency_analysis AS 
SELECT
	-- YEAR(website_sessions.created_at) AS 'Year',
    -- QUARTER(website_sessions.created_at) AS 'Quarter',
	-- DATE_FORMAT(website_sessions.created_at,'%m-%d-%Y') AS 'date',
    MAKEDATE(YEAR(website_sessions.created_at), 1) + INTERVAL QUARTER(website_sessions.created_at) QUARTER -
	INTERVAL 1 QUARTER  AS 'Quarter',
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) 
			AS 'Gsearch nonbrand Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END)
		AS 'Bsearch nonbrand Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) 
		AS 'Brand Overall Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NOT NULL AND website_sessions.utm_source IS NULL THEN website_sessions.website_session_id ELSE NULL END) 
		AS 'Organic Search Conversion Rate',
	COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN website_sessions.http_referer IS NULL AND website_sessions.utm_source IS NULL THEN website_sessions.website_session_id ELSE NULL END) 
		AS 'Direct Type In Conversion Rate'
FROM  website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2015-01-01'
GROUP BY 1
;


CREATE VIEW daily_revenue_trends AS 
SELECT
	-- YEAR(created_at) AS 'Year',
    -- MONTH(created_at) AS 'Month',
    DATE_FORMAT(created_at,'%m-%d-%Y') AS 'date',
    -- Product 1
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS 'Mr. Fuzzy Revenue',
    COUNT(CASE WHEN product_id = 1 THEN order_id ELSE NULL END) AS 'Mr. Fuzzy Sales',
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS 'Mr. Fuzzy Margin',
    -- Product 2
	SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS 'The Forever Love Bear Revenue',
    COUNT(CASE WHEN product_id = 2 THEN order_id ELSE NULL END) AS 'The Forever Love Bear Sales',
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Forever Love Bear Margin',
    -- Product 3
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS 'The Birthday Sugar Panda Revenue',
    COUNT(CASE WHEN product_id = 3 THEN order_id ELSE NULL END) AS 'The Birthday Sugar Panda Sales',
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Birthday Sugar Panda Margin',
    -- Product 4
	SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS 'The Hudson River Mini bear Revenue',
    COUNT(CASE WHEN product_id = 4 THEN order_id ELSE NULL END) AS 'The Hudson River Mini bear Sales',
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS 'The Hudson River Mini bear Margin',
    -- Total Sales, Revenue & Margin
    COUNT(DISTINCT order_id) AS 'Total Sales',
    SUM(price_usd) AS 'Total Revenue',
    SUM(price_usd - cogs_usd) AS 'Total Margin'
FROM order_items
GROUP BY 1
;

-- summarize the data
CREATE VIEW new_product_impact AS 
SELECT
	-- YEAR(products_to_next_pg.created_at) AS 'Year', -- get the year
    -- MONTH(products_to_next_pg.created_at) AS 'Month', -- get the month
    DATE_FORMAT(products_to_next_pg.created_at,'%m-%d-%Y') AS 'date',
	COUNT(CASE WHEN next_page IS NOT NULL THEN product_sessions ELSE NULL END) AS next_page, -- count sessions that made it to the next page
    COUNT(DISTINCT product_sessions) AS total_sessions, -- count the total sessions
    -- COUNT(CASE WHEN next_page IS NOT NULL THEN product_sessions ELSE NULL END) -- get a percentage of sessions that made it to a next page
		-- / COUNT(DISTINCT product_sessions) AS 'To Next Page',
	COUNT(DISTINCT orders.order_id) AS orders, -- grab total orders
    COUNT(DISTINCT products_to_next_pg.product_sessions) AS sessions_on_product_pg
    -- get a percentage of being on the products page leading to an order being placed
	-- COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT products_to_next_pg.product_sessions)  AS 'From /product to Placing an Order'
FROM(
SELECT
    sessions_in_product.created_at AS created_at,
	sessions_in_product.sessions AS product_sessions, -- get all of the sessions that hit product
    website_pageviews.pageview_url AS next_page, -- grab the url of the next page
    MIN(website_pageviews.website_pageview_id) AS next_page_id -- grab the min pageview id, tells us the next page
FROM(
SELECT
	created_at, -- grab where the session is created at
    website_session_id AS sessions, -- grab the session
    website_pageview_id AS pageview_id -- grab the pageview_id for that session
FROM website_pageviews
WHERE pageview_url = '/products' -- where url == products
GROUP BY 1,2
) AS sessions_in_product
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = sessions_in_product.sessions -- make sure sessions are the same
    AND website_pageviews.website_pageview_id > sessions_in_product.pageview_id -- make sure website_pageviews's id is bigger than the subquery's pageview_id
GROUP BY product_sessions
) AS products_to_next_pg
LEFT JOIN orders
	ON orders.website_session_id = products_to_next_pg.product_sessions
GROUP BY 1
;

CREATE VIEW cross_sell_analysis AS 
SELECT 
	orders.primary_product_id,
    products.product_name,
    COUNT(DISTINCT orders.order_id) AS total_orders,
	SUM(order_items.price_usd) AS revenue,
    SUM(order_items.price_usd - order_items.cogs_usd) AS margin,
    ROUND(AVG(order_items.price_usd), 2) AS average_order_value,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS cross_sell_product_1,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS cross_sell_product_2,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS cross_sell_product_3,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) AS cross_sell_product_4,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_1,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_2,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) *100
		AS cross_sell_rate_3,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) / COUNT(DISTINCT orders.order_id) * 100
		AS cross_sell_rate_4
FROM orders
LEFT JOIN order_items
	ON order_items.order_id = orders.order_id
    -- only bring in items that were cross-sold
    AND order_items.is_primary_item = 0 -- cross-sell only
JOIN products
	ON orders.primary_product_id = products.product_id
WHERE orders.created_at > '2014-12-05'
GROUP BY 1
;
