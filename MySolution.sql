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
	select dim_product.segment, count(distinct fact_gross_price.product_code) as pc_2020
    from dim_product
    inner join fact_gross_price
	on fact_gross_price.product_code = dim_product.product_code
	where fact_gross_price.fiscal_year = 2020
	group by segment),
product_count_2021 as (
	select dim_product.segment, count(distinct fact_gross_price.product_code) as pc_2021
    from dim_product
    inner join fact_gross_price
	on fact_gross_price.product_code = dim_product.product_code
	where fact_gross_price.fiscal_year = 2021
	group by segment)
SELECT product_count_2021.segment, product_count_2020.pc_2020,
product_count_2021.pc_2021, (product_count_2021.pc_2021 - product_count_2020.pc_2020) as difference
FROM product_count_2020
inner join product_count_2021
on product_count_2020.segment = product_count_2021.segment
order by difference desc;


# Query 5
WITH highest as (
	select dim_product.segment, dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
	from dim_product
	inner join fact_manufacturing_cost
	on dim_product.product_code = fact_manufacturing_cost.product_code
	order by manufacturing_cost desc limit 1),
lowest as (
	select dim_product.segment, dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
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
select monthname(fact_sales_monthly.date), year(fact_sales_monthly.date), 
ROUND(sum(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price),2) as gross_sales_amount
from fact_sales_monthly
join dim_customer on dim_customer.customer_code = fact_sales_monthly.customer_code
join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
where dim_customer.customer = "Atliq Exclusive"
group by monthname(fact_sales_monthly.date), year(fact_sales_monthly.date);


# Query 8
select 
	case
		when month(fact_sales_monthly.date) in (9,10,11) then "Q1"
        when month(fact_sales_monthly.date) in (12,1,2) then "Q2"
        when month(fact_sales_monthly.date) in (3,4,5) then "Q3"
        when month(fact_sales_monthly.date) in (6,7,8) then "Q4"
	end as Quater,
    sum(fact_sales_monthly.sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fact_sales_monthly.fiscal_year = 2020
group by Quater
order by total_sold_quantity desc;


# Query 9
WITH gross_sales as (
	select dim_customer.channel, 
    ROUND(SUM((fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)/ 1000000), 2) as gross_sales_mln
	from dim_customer
	join fact_sales_monthly on dim_customer.customer_code = fact_sales_monthly.customer_code
	join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
	where fact_sales_monthly.fiscal_year = 2021
	group by dim_customer.channel),
percentage as (
	select SUM(gross_sales.gross_sales_mln) as total
    from gross_sales)
SELECT gross_sales.channel, gross_sales.gross_sales_mln, 
ROUND((gross_sales.gross_sales_mln / percentage.total) * 100 , 2 ) as pct_share
from gross_sales, percentage
order by pct_share desc;


# Query 10
with total_sold_quantity as (
	select dim_product.division, dim_product.product_code, dim_product.product, 
    dim_product.variant, sum(fact_sales_monthly.sold_quantity) as sold_quantity
	from dim_product
	inner join fact_sales_monthly
	on fact_sales_monthly.product_code = dim_product.product_code
	where fact_sales_monthly.fiscal_year = 2021
    group by dim_product.division, dim_product.product_code, dim_product.product, dim_product.variant),
ranking as (
	select division, product_code, product, variant, sold_quantity,
    dense_rank() over(partition by division order by sold_quantity desc) as ranking_order
    from total_sold_quantity)    
select total_sold_quantity.division, total_sold_quantity.product_code, 
total_sold_quantity.product, total_sold_quantity.variant, ranking.sold_quantity, ranking.ranking_order
from total_sold_quantity
join ranking 
on total_sold_quantity.product_code = ranking.product_code
where ranking_order in (1,2,3);
