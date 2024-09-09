
SELECT * FROM df_orders
-- so intially in the  pandas query when  we do the "if exists" thing, pandas automatically assigns very large dataypes in sql, so we dont want that, so we will create a table defining the dataypes on our own and then append it
--#df.to_sql('df_orders', con=conn , index=False, if_exists = 'replace')----OLD
--#df.to_sql('df_orders', con=conn , index=False, if_exists = 'append')--NEW

drop table df_orders


create table df_orders(
[order_id] int primary key , [order_date] date , [ship_mode] varchar (20),
[segment] varchar (20),
[country] varchar (20),
[city] varchar (20),
[state] varchar (20),
[postal_code] varchar(20),
[region] varchar (20),
[category] varchar (20),
[sub_category] varchar (20),
[product_id] varchar (50),
[quantity] int,
[discount] decimal (7,2),
[sale_price] decimal (7,2),
[profit] decimal (7,2))

select * from df_orders

-- ANALYSING DATA:

--1. find top 10 highest reveue generating products 
select top 10 product_id,sum(sale_price) as sales
from df_orders
group by product_id
order by sales desc

--2. find top 5 highest selling products in each region
with cte as (
select region,product_id,sum(sale_price) as sales
from df_orders
group by region,product_id)
select * from (
select *
, row_number() over(partition by region order by sales desc) as rn
from cte) A
where rn<=5



--3. find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
WITH cte AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte 
GROUP BY order_month
ORDER BY order_month;



--4. for each category which month had highest sales 
with cte as (
select category,format(order_date,'yyyyMM') as order_year_month
, sum(sale_price) as sales 
from df_orders
group by category,format(order_date,'yyyyMM')
--order by category,format(order_date,'yyyyMM')
)
select * from (
select *,
row_number() over(partition by category order by sales desc) as rn
from cte
) a
where rn=1


--5.which sub category had highest growth by profit in 2023 compare to 2022
with cte as (
select sub_category,year(order_date) as order_year,
sum(sale_price) as sales
from df_orders
group by sub_category,year(order_date)
--order by year(order_date),month(order_date)
	)
, cte2 as (
select sub_category
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by sub_category
)
select top 1 *
,(sales_2023-sales_2022)
from  cte2
order by (sales_2023-sales_2022) desc

