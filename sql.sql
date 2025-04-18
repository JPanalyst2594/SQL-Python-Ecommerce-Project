use ecommers;

SELECT DISTINCT
    geolocation_city
FROM
    geolocation;
SELECT 
    COUNT(order_id)
FROM
    orders
WHERE
    YEAR(order_purchase_timestamp) = 2017;
 
SELECT 
    UPPER(products.product_category) AS cateogry,
    ROUND(SUM(payments.payment_value), 2) AS sales
FROM
    products
        JOIN
    order_items ON products.product_id = order_items.product_id
        JOIN
    payments ON payments.order_id = order_items.order_id
GROUP BY product_category;
 
 -- #Calculate the percentage of orders that were paid in installments. 
 
SELECT 
    (SUM(CASE
        WHEN payment_installments >= 1 THEN 1
        ELSE 0
    END)) / COUNT(*) * 100
FROM
    payments;
 
SELECT DISTINCT
    (customer_state), COUNT(customer_id)
FROM
    customers
GROUP BY customer_state;

SELECT 
    MONTHNAME(order_purchase_timestamp) AS months,
    COUNT(order_id)
FROM
    orders
WHERE
    YEAR(order_purchase_timestamp) = 2018
GROUP BY months; 
#### Find the average number of products per order, grouped by customer city.-- 
 
with count_per_order as (select orders.order_id ,orders.customer_id, count(order_items.order_id) as ior
from orders 
join order_items on orders.order_id = order_items.order_id
group by orders.order_id,orders.customer_id)
 
 select	customers.customer_city,round(avg(count_per_order.ior),2)
 from customers
 join count_per_order on customers.customer_id =count_per_order.customer_id
 group by customers.customer_city;
 
SELECT 
    UPPER(products.product_category) category,
    ROUND((SUM(payments.payment_value) / (SELECT 
                    SUM(payment_value)
                FROM
                    payments)) * 100,
            2) sales_percentage
FROM
    products
        JOIN
    order_items ON products.product_id = order_items.product_id
        JOIN
    payments ON payments.order_id = order_items.order_id
GROUP BY category
ORDER BY sales_percentage DESC;

SELECT 
    products.product_category,
    COUNT(order_items.product_id),
    ROUND(AVG(order_items.price), 2)
FROM
    products
        JOIN
    order_items ON products.product_id = order_items.product_id
GROUP BY products.product_category;
 
 
 
 #### Calculate the total revenue generated by each seller, and rank them by revenue.
 
 
select * , dense_rank()
over 
	(order by Revenue desc) as Ranks 
from 
(select  order_items.seller_id,
		round(sum(payments.payment_value),2) 
        as Revenue 
				 
from 
		order_items 
join 
		payments 
on 
		order_items.order_id =  payments.order_id
group by
		order_items.seller_id ) as a;
 
 ####   Calculate the moving average of order values for each customer over their order history.-- 
 

select customer_id,order_purchase_timestamp,payment,
avg(payment)
over(partition by customer_id 
order by order_purchase_timestamp 
rows between 2 preceding and current row) as Moving_avg from

(select  orders.customer_id,
		orders.order_purchase_timestamp,
        payments.payment_value as payment
from	orders 
	
join payments on 
			orders.order_id = payments.order_id)as a;
            
#####------Calculate the cumulative sales per month for each year.
select years, months,payments,sum(payments) 
over (order by years,months) as cumulative_Sales 
from (select year(orders.order_purchase_timestamp) as years,
month(orders.order_purchase_timestamp)as months,
round(sum(payment_value)) as payments
from orders join payments on 
orders.order_id = payments.order_id
group by years, months) as T ;
####-------------------Calculate the year-over-year growth rate of total sales

with a as(
select year(orders.order_purchase_timestamp) as years,round( sum(payment_value),2) as payments from orders join payments on 
orders.order_id = payments.order_id
group by years)

select years,(payments-lag(payments,1) over (order by years))/ (payments-lag(payments,1) over (order by years))* 100 
from a;

#####------------Calculate the retention rate of customers,defined as the percentage of customers who make another purchase within 6 months of their first purchase.

with first_order as 
(
 select 
		customers.customer_id,
        min(order_purchase_timestamp) as first_order_date 
from orders 
join customers on customers.customer_id = orders.customer_id
group by customers.customer_id
),

order_within_6_month as 
(
select 
		orders.customer_id,
        orders.order_purchase_timestamp
from orders 
join first_order  on first_order.customer_id = orders.customer_id
where orders.order_purchase_timestamp > first_order.first_order_date
and orders.order_purchase_timestamp <= date_add(first_order.first_order_date,interval 6 month)

), 
retained_customers as(
	select distinct customer_id from order_within_6_month
),
total_customer as 
(
 select count(distinct customer_id) as total from first_order
)
select
		(select count(*) from retained_customers) as customer_retained,
		(select total from total_customer) as total_customer,
round(
		(select count(*) from retained_customers)/
		(select total from total_customer) * 100,2
        )as total_6_month_retention_rate;

### ---------Identify the top 3 customers who spent the most money in each year.----

select years,id,total_money_spent,d_ranks from

(select year(orders.order_purchase_timestamp)  as years,
orders.customer_id as id,
round(sum(payments.payment_value)) as total_money_spent,


dense_rank() over(partition by year(orders.order_purchase_timestamp) 
order by sum(payments.payment_value ) desc) as d_ranks


 from orders join payments on orders.order_id = payments.order_id
group by year(orders.order_purchase_timestamp),id) as a
where  d_ranks<=3;







 
 
  