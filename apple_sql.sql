-- Apple sales project 1M datasets
SELECT * FROM category;

SELECT  * FROM products;

SELECT * FROM stores;

SELECT * FROM sales;

SELECT  * FROM warranty;


-- Improving query performance

-- Before creating index
-- Execution time 226.350 ms
-- planning time 0.118
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 'P-44'

-- After Creating index
-- CREATE INDEX index_name (sales_product_id) on  table_anme(sales)(column_name)
CREATE INDEX sales_product_id ON sales(product_id);

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 'P-44'

--Execution time 7.828 ms
-- planning time 1.925 ms


-- Creating store_id index
-- Before creating index 
-- execution time = 222.953ms
-- planning time 0.152ms
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-33'

CREATE INDEX sale_store_id ON sales(store_id);

-- After creating store_id index
-- execution time= 2.740ms
-- planning time =1.922ms

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-33'

CREATE INDEX sales_sale_date ON sales(sale_date);


--1. Find each country and the number of stores
SELECT 
	country,
	COUNT(*) as number_of_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC


--2. What is the total number of units sold by each store?
SELECT 
	s.store_id,
	st.store_name,
	SUM(s.quantity) as total_units_sold
FROM sales s
JOIN stores st
ON  s.store_id = st.store_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- 3. How many sales occurred in December 2023?
SELECT
	COUNT(*) as total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM/YYYY') = '12/2023'


--4. How many stores have never had a warranty claim filed against any of their products?

SELECT COUNT(*) FROM stores
WHERE store_id NOT IN (
						SELECT 
							DISTINCT store_id
						FROM sales as s
						RIGHT JOIN warranty as w
						ON s.sale_id = w.sale_id
						);


--5. What percentage of warranty claims are marked as "Warranty Void"?

SELECT COUNT(*) FROM warranty

SELECT 
	ROUND(COUNT(claim_id)/
	(SELECT COUNT(*) FROM warranty)::numeric *
	100
	,2) as warranty_void_pecent_claim
FROM warranty 
WHERE repair_status= 'Warranty Void'

--6. Which store had the highest total units sold in the last year?

-- SELECT 
-- 	s.store_id,
-- 	st.store_name,
-- 	SUM(s.quantity)
-- FROM sales as s
-- JOIN stores as st
-- ON s.store_id = st.store_id
-- WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')
-- GROUP BY 1, 2
-- ORDER BY 3 DESC
-- LIMIT 1

--7. Count the number of unique products sold in the last year.
-- SELECT 
-- 	COUNT(DISTINCT product_id)
-- FROM sales
-- WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')

--8. What is the average price of products in each category?
SELECT 
	c.category_id,
	AVG(P.price) as avg_price,
	c.category_name
FROM  category c
JOIN products p
ON c.category_id = p.category_id
GROUP BY 1, 3
ORDER BY 2 DESC;


--9. How many warranty claims were filed in 2020?
SELECT 
	COUNT(*) as warranty_claimed
FROM warranty
WHERE EXTRACT( YEAR FROM claim_date) = 2020

--10. Identify each store and best selling day based on highest qty sold
-- store_id and day_name grouping
-- quantity sum

SELECT *
FROM
(	SELECT 
		store_id,
		TO_CHAR(sale_date, 'Day') as day_name,
		SUM(quantity) as total_unit_sold,
		RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) rn
	FROM sales
	GROUP BY 1,2
	--ORDER BY 1,3 DESC
) as t1
WHERE RN = 1



--11. Identify least selling product of each country for each year based on total unit sold

WITH product_rank
AS
	(SELECT 
		st.country,
		p.product_name,
		SUM(s.quantity) as total_quantity_sold,
		RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as rn
	FROM sales s
	JOIN stores st
	ON s.store_id = st.store_id
	JOIN products p
	ON s.product_id = p.product_id
	GROUP BY 1,2
--ORDER  BY 1,3 DESC
 )
 SELECT * 
 FROM product_rank
 WHERE rn =1


-- 12. How many warranty claims were filed within 180 days of a product sale?
-- SELECT 
-- 	w.*,
-- 	s.sale_date,
-- 	w.claim_date - sale_date as differnces
-- FROM warranty w
-- LEFT JOIN sales s
-- ON s.sale_id = w.sale_id
-- WHERE w.claim_date - sale_date <= 180

SELECT 
	COUNT(*)
FROM warranty w
LEFT JOIN sales s
ON s.sale_id = w.sale_id
WHERE w.claim_date - sale_date <= 180

--13. How many warranty claims have been filed for products launched in the last two years?
-- SELECT 
-- 	p.product_name,
-- 	COUNT(w.claim_id) as no_claim,
-- 	COUNT(s.sale_id)
-- FROM warranty as w
-- RIGHT JOIN
-- sales as s 
-- ON s.sale_id = w.sale_id
-- JOIN products as p
-- ON p.product_id = s.product_id
-- WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
-- GROUP BY 1
-- HAVING COUNT(w.claim_id) > 0


--14. List the months in the last 3 years where sales exceeded 5000 units from usa.
SELECT 
	TO_CHAR(sale_date, 'MM-YYYY') as month,
	SUM(s.quantity) as total_unit_sold
FROM sales as s
JOIN 
stores as st
ON s.store_id = st.store_id
WHERE 
	st.country = 'USA'
	AND
	s.sale_date >= 2023 - INTERVAL '3 year'
GROUP BY 1
HAVING SUM(s.quantity) > 5000




SELECT 
    TO_CHAR(s.sale_date, 'MM-YYYY') AS month,
    SUM(s.quantity) AS total_unit_sold
FROM sales AS s
JOIN stores AS st
    ON s.store_id = st.store_id
WHERE 
    st.country = 'USA'
    AND s.sale_date >= '2021-01-01'
    AND s.sale_date <  '2024-01-01'
GROUP BY 1
HAVING SUM(s.quantity) > 5000
ORDER BY MIN(s.sale_date);

--Q.15 Identify the product category with the most warranty claims filed in the last two years.

SELECT 
	c.category_name,
	COUNT(w.claim_id) as total_claims
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON p.product_id = s.product_id
JOIN 
category as c
ON c.category_id = p.category_id
WHERE 
	w.claim_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY 1



--16. Determine the percentage chance of receiving claims after each purchase for each country.

SELECT 
	country,
	total_unit_sold,
	total_claim,
	COALESCE(total_claim::numeric/total_unit_sold::numeric * 100, 0)
	as risk
FROM
(SELECT 
	st.country,
	SUM(s.quantity) as total_unit_sold,
	COUNT(w.claim_id) as total_claim
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
LEFT JOIN 
warranty as w
ON w.sale_id = s.sale_id
GROUP BY 1) t1
ORDER BY 4 DESC


--17. Analyse each stores year by year growth ratio
-- Each store and each year sales 
-- lag function

WITH yearly_sales
AS
(	SELECT 
		s.store_id,
		store_name,
		EXTRACT(YEAR FROM s.sale_date) as year,
		SUM(s.quantity * p.price) as total_sales
	FROM sales s
	JOIN products p
	ON s.product_id = p.product_id
	JOIN stores st
	ON st.store_id = s.store_id
	GROUP BY 1, 2, 3
	ORDER BY 2,3
),
growth_ratio
AS
(	SELECT 
		store_name,
		year, 
		LAG(total_sales ,1) OVER(PARTITION BY store_name ORDER BY year) last_year_sales,
		total_sales as current_year_sales
	FROM yearly_sales
)

SELECT 
	store_name,
	year,
	last_year_sales,
	current_year_sales,
	ROUND(
			(current_year_sales - last_year_sales)::numeric/
							last_year_sales::numeric * 100
	,3) as yearly_growth_ratio
FROM growth_ratio
WHERE last_year_sales IS NOT NULL
	AND 
	YEAR <> EXTRACT(YEAR FROM CURRENT_DATE)

--18. What is the correlation between product price and warranty claims for products sold in the last five years? 
--(Segment based on diff price)
-- Is the product price is proportional to warranty claims? 
SELECT 
	
	CASE
		WHEN p.price < 500 THEN 'Less Expenses Product'
		WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
		ELSE 'Expensive Product'
	END as price_segment,
	COUNT(w.claim_id) as total_Claim
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
JOIN 
products as p
ON p.product_id = s.product_id
WHERE claim_date >= CURRENT_DATE - INTERVAL '5 year'
GROUP BY 1

--19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total
--claims filed.
WITH paid_repair
AS
(	SELECT 
		s.store_id,
		COUNT(w.claim_id) as paid_repair
	FROM sales s
	RIGHT JOIN warranty w
	ON s.sale_id = w.sale_id
	WHERE w.repair_status = 'Paid Repaired'
	GROUP BY 1
),

total_repair
AS
(	SELECT 
		s.store_id,
		COUNT(w.claim_id) as total_repair
	FROM sales s
	RIGHT JOIN warranty w
	ON s.sale_id = w.sale_id
	GROUP BY 1
)
 SELECT 
 	tr.store_id,
	 st.store_name,
	pr.paid_repair,
	tr.total_repair,
	ROUND(
		pr.paid_repair::numeric /
		tr.total_repair::numeric *
		100 ,2) as paid_repair_percentage
FROM paid_repair pr
JOIN total_repair tr
ON pr.store_id = tr.store_id
JOIN stores st
ON tr.store_id = st.store_id

--20.Write SQL query to calculate the (MONTHLY RUNNING TOTAL) of sales for each store over the past
-- four years and compare the trends across this period?
WITH monthly_sales
AS
(SELECT 
	store_id,
	EXTRACT(YEAR FROM sale_date) as year,
	EXTRACT(MONTH FROM sale_date) as month,
	SUM(p.price * s.quantity) as total_revenue
FROM sales as s
JOIN 
products as p
ON s.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2,3
)
SELECT 
	store_id,
	month,
	year,
	total_revenue,
	SUM(total_revenue) OVER(PARTITION BY store_id ORDER BY year, month) as running_total
FROM monthly_sales


--21. Analyze sales trends of product over time, segmented into key time periods: from launch to 6 month, 
--6-12 months, 12-18 months, and beyond 18 months?
SELECT 
	p.product_name,
	CASE 
		WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 month'
		WHEN s.sale_date BETWEEN  p.launch_date + INTERVAL '6 month'  AND p.launch_date + INTERVAL '12 month' THEN '6-12' 
		WHEN s.sale_date BETWEEN  p.launch_date + INTERVAL '12 month'  AND p.launch_date + INTERVAL '18 month' THEN '6-12'
		ELSE '18+'
	END as product_life_cycle,
	SUM(s.quantity) as total_qty_sale
	
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC 

























