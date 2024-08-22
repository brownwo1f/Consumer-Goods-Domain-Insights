# Query 1
SELECT distinct market FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";  

# Query 2
WITH unique_products_2020  as (
	select count(distinct product_code) as unique_products_2020
	from fact_sales_monthly
	where fiscal_year = 2020 ), 
unique_products_2021 as (
	select count(distinct product_code) as unique_products_2021
	from fact_sales_monthly
	where fiscal_year = 2021 )
SELECT unique_products_2020, unique_products_2021,
((unique_products_2021- unique_products_2020) / unique_products_2020) *100 as  percentage_chg
FROM unique_products_2020, unique_products_2021;


# Query 3
SELECT segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

# Query 4
WITH product_count_2020 as (
	select segment, count(distinct fact_sales_monthly.product_code) as pc_2020
    from fact_sales_monthly
    inner join dim_product
    on fact_sales_monthly.product_code = dim_product.product_code
    where fact_sales_monthly.fiscal_year = 2020
    group by segment),
product_count_2021 as (
	select segment, count(distinct fact_sales_monthly.product_code) as pc_2021
    from fact_sales_monthly
    inner join dim_product
    on fact_sales_monthly.product_code = dim_product.product_code
    where fact_sales_monthly.fiscal_year = 2021
    group by segment)
SELECT distinct product_count_2020.segment, product_count_2020.pc_2020,
product_count_2021.pc_2021, (product_count_2021.pc_2021 - product_count_2020.pc_2020) as difference
FROM product_count_2020
inner join product_count_2021
on product_count_2020.segment = product_count_2021.segment
order by difference desc;

-- first we calculate segment wise (group by) product count for the year 2020
-- second we calculate segment wise (group by) product count for the year 2021
-- segment comes from dim_product table and fiscal year comes from fact_sales_monthly table
-- product_code is common column which is used to join both tables 
-- now after making the CTE from first and second
-- we have two new temp tables with segment as common column
-- taking segment column from anyone table, count for 2020, count for 2021, and calculating
-- the difference
-- we again join both temp tables via common segment column
-- using group by again is not required as the counts are already aggregated in CTE quries
-- at last we order by the table in desc order of difference as requested


# Query 5
WITH highest as (
	select dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
	from dim_product
	inner join fact_manufacturing_cost
	on dim_product.product_code = fact_manufacturing_cost.product_code
	order by manufacturing_cost desc limit 1),
lowest as (
	select dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
	from dim_product
	inner join fact_manufacturing_cost
	on dim_product.product_code = fact_manufacturing_cost.product_code
	order by manufacturing_cost limit 1)
SELECT * FROM highest
UNION ALL
SELECT * FROM lowest;


# Query 6
SELECT dim_customer.customer_code, dim_customer.customer,
ROUND(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct) * 100, 2) as avg_discount_pct
FROM fact_pre_invoice_deductions
INNER JOIN dim_customer
ON dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
WHERE fact_pre_invoice_deductions.fiscal_year = 2021 and dim_customer.market = "India"
GROUP BY dim_customer.customer_code, dim_customer.customer
ORDER BY avg_discount_pct DESC LIMIT 5;

# Query 7
select monthname(fact_sales_monthly.date), year(fact_sales_monthly.date), ROUND(sum(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price) / 1000000,2) as gross_sales_amount
from fact_sales_monthly
join dim_customer on dim_customer.customer_code = fact_sales_monthly.customer_code
join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
where dim_customer.customer = "Atliq Exclusive"
group by monthname(fact_sales_monthly.date), year(fact_sales_monthly.date);


# Query 8
select quarter(fact_sales_monthly.date) as quarter, sum(fact_sales_monthly.sold_quantity) as total_sold_quantity
from fact_sales_monthly
where year(fact_sales_monthly.date) = 2020
group by quarter(fact_sales_monthly.date)
order by total_sold_quantity desc;


# Query 9
WITH gross_sales as (
	select dim_customer.channel, ROUND(SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)/ 1000000, 2) as gross_sales_mln
	from dim_customer
	join fact_sales_monthly on dim_customer.customer_code = fact_sales_monthly.customer_code
	join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
	where fact_sales_monthly.fiscal_year = 2021 and fact_gross_price.fiscal_year = 2021
	group by dim_customer.channel),
percentage as (
	select SUM(gross_sales.gross_sales_mln) as total
    from gross_sales)
SELECT gross_sales.channel, gross_sales.gross_sales_mln, ROUND((gross_sales.gross_sales_mln / percentage.total) *100 , 2 ) as pct_share
from gross_sales, percentage;

-- in this we calculated gross sales in million by multiplying sold quantities by gross price 
-- data was from 3 tables so we joined accordingly 
-- request was about fiscal year 2021 and group by channels
-- to calculate total we took the gross sales value from first cte and added it for all channels 
-- at last we calculated percentage by dividing each channel share by total and mult by 100


# Query 10

with ranking as (
	select dim_product.division, dim_product.product_code, dim_product.product, fact_sales_monthly.sold_quantity, 
	dense_rank() over(partition by dim_product.division order by fact_sales_monthly.sold_quantity desc) as rank_order
	from dim_product
	inner join fact_sales_monthly
	on fact_sales_monthly.product_code = dim_product.product_code
	where fact_sales_monthly.fiscal_year = 2021)
select division, product_code, product, sold_quantity, rank_order
from ranking
where rank_order <= 3
order by division, rank_order;

-- in this we took division, product_code, product from dim_product table
-- and sold_quantity from fact_sales_monthly table
-- within the cte keeping most of the things as is
-- we calculated the rank on the basis of sold_quantities within each division
-- dense_rank is perfect for this use case as it does not skip rank in case of ties 
-- we partitioned the data on the basis of division (partition by) and then ordered them by sold quantities (order by)
-- in descending order and dense rank() gave the rank to them 
-- also there is 2021 fiscal year where clause as requested 
-- in final select statement we extracted data from our ranking cte and put condition so that only top 3 ranks are shown
-- them ordering them by division and rank order in ascending order 
