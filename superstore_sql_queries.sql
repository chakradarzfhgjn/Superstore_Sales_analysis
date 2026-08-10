--Calculate the Year-over-Year (YoY) total sales performance across the entire lifespan of the dataset

select DATE_TRUNC('year',order_date)as Yearly,sum(sales) as Revenue
from superstore_orders
group by DATE_TRUNC('year',order_date)
order by yearly asc


--For each country, what was the total sales revenue generated across each product category 
--during that country's very first active operational year?

with yearly_cte as(
select country,category,SUM(sales)as revenue,DATE_TRUNC('year',order_date)as yearly,
DENSE_RANK()over(partition by country order by DATE_TRUNC('year',order_date))as ranking
from superstore_orders
group by country,category,DATE_TRUNC('year',order_date)
)
select country,category,revenue,yearly,ranking
from yearly_cte
where ranking=1;


--What is the annual net profit margin percentage for each product category?

select category,round((sum(profit)/sum(sales)*100)::numeric,2) as profit_margin,
DATE_TRUNC('year',order_date)as yearly
from superstore_orders
group by category,DATE_TRUNC('year',order_date)


--Which top 3 country-month combinations generated the highest single-month sales revenue during the year 2014?

select country,sum(sales)as revenue,DATE_TRUNC('month',order_date)as month
from superstore_orders
where order_date>='2014-1-1' and order_date<='2014-12-31'
group by country,DATE_TRUNC('month',order_date)
order by revenue desc
limit 3


--For each customer, what was the date of their most recent purchase, 
--the date of their prior purchase, and how many days elapsed between those two orders?

with ranked_orders as(
select customer_name,order_date,
lag(order_date,1)over(partition by customer_name order by order_date asc)as previous_order,
row_number()over(partition by customer_name order by order_date desc)as rn
from superstore_orders
)
select customer_name,order_date as latest_order_date,previous_order as second_latest_order_date,
(order_date::date - previous_order::date)as days_between_last_two_orders
from ranked_orders
where rn=1;


-- How many distinct discount percentages exist in each discount tier across product categories?

with discount_cte as(
select category,discount,
case
    when discount<=0.20 then 'Low discount'
    when discount>0.20 and discount<=0.50 then 'Moderate discount'
    else 'High discount'
    end as discount_tier
from superstore_orders
group by category,discount
)
select category,discount_tier,count(*) as distinct_discount_count
from discount_cte
group by category,discount_tier
order by category,discount_tier;


-- What is the total shipping revenue collected across each combination of shipping mode and order priority, ordered by priority?

select round(sum(shipping_cost)::numeric,2)as total_shipping_cost,ship_mode,order_priority
from superstore_orders
group by ship_mode,order_priority
order by order_priority asc


--How do sales revenue, total net profit, and profit margin percentage vary across product categories
--when comparing non-discounted, low-discount ($\le$ 20%), and high-discount (> 20%) sales?


select category,
case 
    when discount = 0 then 'No Discount'
    when discount <= 0.20 then 'Low Discount'
    else 'High Discount'
end as discount_bucket,
round(sum(sales)::numeric,2)as total_sales,
round(sum(profit)::numeric,2)as total_profit,
round((sum(profit)/sum(sales)*100)::numeric,2)as profit_margin_pct
from superstore_orders
group by category,discount_bucket
order by category,discount_bucket;


--What is the overall ranking of each country based on total sales revenue generated across the dataset's entire lifespan (top 10)?

with country_sales as(
select country,round(sum(sales)::numeric,2)as total_revenue,
dense_rank()over(order by sum(sales) desc)as revenue_rank
from superstore_orders
group by country
)
select country,total_revenue,revenue_rank
from country_sales
where revenue_rank<=10
order by revenue_rank asc;
