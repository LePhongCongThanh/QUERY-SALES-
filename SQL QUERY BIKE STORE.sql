/*
CHECK TABLES SCHEME "PRODUCTION"
*/
SELECT TOP (5) *
FROM BIKESTORE.production.brands

SELECT TOP (5) *
FROM BIKESTORE.production.categories

SELECT TOP (5) *
FROM BIKESTORE.production.products

SELECT TOP (5) *
FROM BIKESTORE.production.stocks

--QUESTION 1:Find Product with Price > 5000, product name containing 2017 and stocks of this
WITH CTE_stocks as (
	SELECT product_id, SUM(quantity) as Stockeachproduct
	FROM BIKESTORE.production.stocks
	GROUP BY product_id
)

SELECT pr.product_id, product_name, brand_name, category_name, list_price, Stockeachproduct
FROM BIKESTORE.production.products as pr
INNER JOIN BIKESTORE.production.brands as br
	ON pr.brand_id = br.brand_id
INNER JOIN BIKESTORE.production.categories as ca
	ON pr.category_id = ca.category_id
INNER JOIN CTE_stocks as st
	ON pr.product_id = st.product_id
WHERE pr.list_price > 5000 
ORDER BY pr.list_price DESC

--QUESTION 2: WHAT PRODUCTS SHOULD ORDER MORE IF STOCKS < 25
WITH CTE_stocks as (
	SELECT product_id, SUM(quantity) as Stockeachproduct
	FROM BIKESTORE.production.stocks
	GROUP BY product_id
) --6

SELECT pr.product_id, product_name, brand_name, category_name, list_price, Stockeachproduct,
CASE
		WHEN Stockeachproduct <= 25 then 'YES'
		ELSE 'NO'
END as 'Orderyesno' --10
FROM BIKESTORE.production.products as pr --1
INNER JOIN BIKESTORE.production.brands as br --2
	ON pr.brand_id = br.brand_id --3
INNER JOIN BIKESTORE.production.categories as ca --4
	ON pr.category_id = ca.category_id --5
INNER JOIN CTE_stocks as st --7
	ON pr.product_id = st.product_id --8
ORDER BY Stockeachproduct ASC --9

--QUESTION 3: How many products should we order? 
WITH CTE_stocks as (
	SELECT product_id, SUM(quantity) as Stockeachproduct
	FROM BIKESTORE.production.stocks
	GROUP BY product_id
) --6

SELECT *,
COUNT(Orderyesno) OVER (PARTITION BY Orderyesno) as Numberoforder--10
FROM (
	SELECT pr.product_id, product_name, brand_name, category_name, list_price, Stockeachproduct,
	CASE
			WHEN Stockeachproduct <= 25 then 'YES'
			ELSE 'NO'
	END as 'Orderyesno'
	FROM BIKESTORE.production.products as pr --1
	INNER JOIN BIKESTORE.production.brands as br --2
		ON pr.brand_id = br.brand_id --3
	INNER JOIN BIKESTORE.production.categories as ca --4
		ON pr.category_id = ca.category_id --5
	INNER JOIN CTE_stocks as st --7
		ON pr.product_id = st.product_id ----9
) as subquery
ORDER BY Stockeachproduct ASC

--- OTher way
WITH CTE_stocks as (
	SELECT product_id, SUM(quantity) as Stockeachproduct
	FROM BIKESTORE.production.stocks
	GROUP BY product_id
) --6

SELECT Orderyesno,
COUNT(Orderyesno) as Numberoforder--12
FROM (
	SELECT pr.product_id, product_name, brand_name, category_name, list_price, Stockeachproduct,
	CASE
			WHEN Stockeachproduct <= 25 then 'YES'
			ELSE 'NO'
	END as 'Orderyesno' --10
	FROM BIKESTORE.production.products as pr --1
	INNER JOIN BIKESTORE.production.brands as br --2
		ON pr.brand_id = br.brand_id --3
	INNER JOIN BIKESTORE.production.categories as ca --4
		ON pr.category_id = ca.category_id --5
	INNER JOIN CTE_stocks as st --7
		ON pr.product_id = st.product_id ----9
) as subquery
GROUP BY Orderyesno --11
ORDER BY Numberoforder ASC; -13

--QUESTION 4: How many stocks and products in each store?
SELECT sto.store_id, store_name, phone, city,
SUM(quantity) as sumquantity,
COUNT(product_id) as numproduct
FROM BIKESTORE.production.stocks as sto
INNER JOIN BIKESTORE.sales.stores as st
	ON sto.store_id = st.store_id
GROUP BY sto.store_id, store_name, phone, city --when select many columns, must groupby all of these colums
ORDER BY sumquantity DESC

--QUESTION 5: Comparison of average price of Products of 2016 and 2017, 2018, 2019
SELECT model_year,
AVG(list_price) as AVGprice
FROM BIKESTORE.production.products
GROUP BY model_year
ORDER BY AVGprice

/*
CHECK TABLES SCHEME "SALES"
*/
SELECT TOP (5) *
FROM BIKESTORE.sales.customers

SELECT TOP (5) *
FROM BIKESTORE.sales.order_items

SELECT TOP (5) *
FROM BIKESTORE.sales.orders

SELECT TOP (5) *
FROM BIKESTORE.sales.staffs

SELECT TOP (5) *
FROM BIKESTORE.sales.stores

--QUESTION 6: HOW MANY CUSTOMERS HAVE NOT NULL PHONE?
SELECT COUNT(phone) as numberphonenull
FROM BIKESTORE.sales.customers
WHERE phone IS NOT NULL

--QUESTION 7: Name, phone,..of customers who buy the most number of  items --g
WITH CTE_max as (
	SELECT TOP (5) order_id,
	COUNT(item_id) as numberitem
	FROM BIKESTORE.sales.order_items
	GROUP BY order_id
)

SELECT
	CTE_max.order_id,
	numberitem,   
	cus.first_name +' '+ cus.last_name as full_name_cus, 
	cus.phone, cus.email, 
	st.store_name,
	sta.first_name +' '+ sta.last_name as full_namr_staff
FROM CTE_max 
INNER JOIN BIKESTORE.sales.orders as ord
	ON CTE_max.order_id = ord.order_id
INNER JOIN BIKESTORE.sales.customers as cus
	ON ord.customer_id = cus.customer_id
INNER JOIN BIKESTORE.sales.stores as st
	ON ord.store_id = st.store_id
INNER JOIN BIKESTORE.sales.staffs as sta
	ON ord.staff_id = sta.staff_id

--QUESTION 8: Total cash after discount
SELECT order_id, pr.product_name, quantity,
(or_it.list_price*quantity) - (or_it.list_price*discount*quantity) as totalcash	
FROM BIKESTORE.sales.order_items as or_it
INNER JOIN BIKESTORE.production.products as pr
	ON or_it.product_id = pr.product_id

--QUESTION 9: Totalcash per order
WITH CTE_cash as (
	SELECT order_id, pr.product_name, quantity,
	(or_it.list_price*quantity) - (or_it.list_price*discount*quantity) as totalcash		
	FROM BIKESTORE.sales.order_items as or_it
	INNER JOIN BIKESTORE.production.products as pr
		ON or_it.product_id = pr.product_id
)

SELECT *,
SUM(totalcash) OVER (PARTITION BY order_id) as totalcashorder
FROM CTE_cash;

--QUESTION 10: WHAT DATES HAVE THE MOST ORDERS
SELECT order_date,
COUNT(order_id) as numberorder
FROM BIKESTORE.sales.orders
GROUP BY order_date
ORDER BY numberorder DESC

--QUESTION 11: Revenue of each store

WITH CTE_cash as (
	SELECT or_it.order_id,store_id,
	(or_it.list_price*quantity) - (or_it.list_price*discount*quantity) as totalcash		
	FROM BIKESTORE.sales.order_items as or_it
	INNER JOIN BIKESTORE.sales.orders as ord
		ON or_it.order_id = ord.order_id 
)

SELECT CTE_cash.store_id, store_name, street,
SUM(totalcash) as totalrevennue 
FROM CTE_cash
INNER JOIN BIKESTORE.sales.stores as st
	ON CTE_cash.store_id = st.store_id
GROUP BY CTE_cash.store_id, store_name, street
ORDER BY totalrevennue DESC;


SELECT * 
FROM BIKESTORE.production.brands

