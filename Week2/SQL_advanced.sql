USE coffeeshop_db;

-- =========================================================
-- ADVANCED SQL ASSIGNMENT
-- Subqueries, CTEs, Window Functions, Views
-- =========================================================
-- Notes:
-- - Unless a question says otherwise, use orders with status = 'paid'.
-- - Write ONE query per prompt.
-- - Keep results readable (use clear aliases, ORDER BY where it helps).

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
-- For each PAID order, compute order_total (= SUM(quantity * products.price)).
-- Return: order_id, customer_name, store_name, order_datetime, order_total.
-- Filter to orders where order_total is greater than the average PAID order_total
-- for THAT SAME store (correlated subquery).
-- Sort by store_name, then order_total DESC.

with order_total as ( -- Find each order's total
	select 
		s.store_id as store_id,
		o.order_id as order_id,
		sum(oi.quantity * p.price) as total
	from orders o
    join order_items oi on oi.order_id = o.order_id
    join products p on oi.product_id = p.product_id
    join stores s on s.store_id = o.store_id
    where o.status = 'paid'
    group by o.order_id
)
-- I originally had the avg order total per school here as a CTE and it worked. 
-- I had to reorganize to meet the 'correlated subquery' prompt.
select 
	o.order_id as order_id,
	concat(c.last_name, ', ', c.first_name) as customer_name,
	s.name as store_name,
	o.order_datetime as order_datetime,
	ot.total as order_total
from orders o
join customers c on c.customer_id = o.customer_id
join stores s on s.store_id = o.store_id
join order_total ot on o.order_id = ot.order_id
where ot.total > ( -- Find average order total per store
	select avg(ot.total) as avg_total
	from order_total ot
    where ot.store_id = s.store_id 
		-- ChatGPT helped me figure out how to connect this query
        -- to the current line's store in my code reorganization
)
order by s.name, ot.total DESC;

-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
-- Using a CTE, compute daily revenue per store:
--   revenue_day = SUM(quantity * products.price) grouped by store_id and DATE(order_datetime).
-- Then, for each store and date, return:
--   store_name, order_date, revenue_day,
--   rolling_3day_avg = average of revenue_day over the current day and the prior 2 days.
-- Use a window function for the rolling average.
-- Sort by store_name, order_date.

with daily_revenue as ( -- Using a CTE, compute daily revenue per store
	select 
		o.store_id as store_id,
		s.name as store_name,
		date(o.order_datetime) as order_date,
		sum(oi.quantity * p.price) as revenue_day
    from orders o
    join order_items oi on oi.order_id = o.order_id
    join products p on p.product_id = oi.product_id
    join stores s on o.store_id = s.store_id
    where o.status = 'paid'
    group by o.store_id, date(o.order_datetime)
)
select 
	store_name,
	order_date,
	revenue_day,
	round(avg(revenue_day) over (
		partition by store_id
		order by order_date 
			rows between 2 preceding and current row
		), 2 -- Round to 2 decimal points
        ) as rolling_3day_avg
from daily_revenue dr 
order by store_name, order_date;

-- References: https://dev.mysql.com/doc/refman/9.7/en/date-and-time-functions.html#function_month
-- https://stackoverflow.com/questions/16121023/calculating-a-moving-average-mysql
-- I lost another reference in my mass-closing of tabs
--  ChatGPT helped confirm the answer satisfies the question.

-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
-- Compute each customer's total spend across ALL stores (PAID only).
-- Return: customer_id, customer_name, total_spend,
--         spend_rank (DENSE_RANK by total_spend DESC).
-- Also include percent_of_total = customer's total_spend / total spend of all customers.
-- Sort by total_spend DESC.

with customer_total as (
	select o.customer_id as customer_id,
		concat(c.last_name, ', ', c.first_name) as customer_name,
        sum(oi.quantity * p.price) as total_spend
    from orders o
    join customers c on c.customer_id = o.customer_id
    join order_items oi on oi.order_id = o.order_id
    join products p on p.product_id = oi.product_id
	where o.status = 'paid'
    group by customer_id
)
select customer_id,
		customer_name,
        total_spend,
        dense_rank() over (order by total_spend desc) spend_rank,
        total_spend / sum(total_spend) over() as percent_of_total 
			-- I missed this line above when I checked my answer with ChatGPT
            -- I remember one of the videos talking about an empty over()
            -- applying to every row
from customer_total;

-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
-- For each store, find the top-selling product by REVENUE (not units).
-- Revenue per product per store = SUM(quantity * products.price).
-- Return: store_name, product_name, category_name, product_revenue.
-- Use a CTE to compute product_revenue, then a window function (ROW_NUMBER)
-- partitioned by store to select the top 1.
-- Sort by store_name.
 
 with product_revenue_calc as (
	 select 
		s.store_id as store_id,
		s.name as store_name,
		p.product_id as product_id,
		p.name as product_name,
		c.name as category_name,
		sum(oi.quantity * p.price) as product_revenue
	 from orders o
	 join stores s on s.store_id = o.store_id
	 join order_items oi on oi.order_id = o.order_id
	 join products p on p.product_id = oi.product_id
	 join categories c on c.category_id = p.category_id
	 where o.status = 'paid'
	 group by s.store_id, s.name, p.product_id, p.name, c.name
	),
    ranked_products as (
		 select 
			prc.store_name as store_name,
			prc.product_name as product_name,
			prc.category_name as category_name,
			prc.product_revenue as product_revenue,
			row_number() over (
				partition by prc.store_name
				order by prc.product_revenue desc) as product_rank
		from product_revenue_calc prc
    )
 
 select 
	rp.store_name as store_name,
    rp.product_name as product_name,
    rp.category_name as category_name,
	rp.product_revenue as product_revenue
from ranked_products rp
where product_rank = 1
order by store_name;
 
 -- I had the right code, but couldn't figure out how/where to plug in the window
 -- function (row_number() over (partition by prc.store_name order by 
 -- prc.product_revenue desc)). ChatGPT helped walk me through the logic of how 
 -- MySQL processes these and I decided to added a second CTE to filter by rank
 -- without selecting it.
 
-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
-- Return customers who have at least one PAID order in every store in the stores table.
-- Return: customer_id, customer_name.
-- Hint: Compare count(distinct store_id) per customer to (select count(*) from stores).

select 
	c.customer_id as customer_id,
    concat(c.last_name, ', ', c.first_name) as customer_name
from customers c
where (
	select count(distinct o.store_id)
		from orders o
		where o.customer_id = c.customer_id
			and o.status = 'paid'
			) 
			= -- count stores per person
	(select count(*) from stores)  -- count total unique stores
;

-- I really struggled with this one. I had to work with ChatGPT to talk through the 
-- where clause, but now I feel I understand its logic a bit better. It's like
-- where (per customer, how many stores have they visited) = (total stores available)
-- The tip was helpful, but really threw me off.

-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
-- For each customer, list their PAID orders in chronological order and compute:
--   prev_order_datetime (LAG),
--   minutes_since_prev (difference in minutes between current and previous order).
-- Return: customer_name, order_id, order_datetime, prev_order_datetime, minutes_since_prev.
-- Only show rows where prev_order_datetime is NOT NULL.
-- Sort by customer_name, order_datetime.

-- What I had before ChatGPT ========
-- select 
-- 	concat(c.last_name, ', ', c.first_name) as customer_name,
--     o.order_id as order_id,
--     o.order_datetime as order_datetime,
--     lag(order_datetime) over (order by order_datetime) as prev_order_datetime,
-- 	TIMESTAMPDIFF(MINUTE, prev_order_date, order_datetime) as minutes_since_prev
-- from orders o
-- join customers c on c.custoemr_id = o.custoemr_id
-- where prev_order_datetime is not null
-- 	and o.status = 'paid'
-- order by customer_name, order_datetime;

with customer_order as (
	select 
			c.customer_id,
			concat(c.last_name, ', ', c.first_name) as customer_name,
			o.order_id as order_id,
			o.order_datetime as order_datetime,
			lag(order_datetime) over (
				partition by customer_id
				order by order_datetime
			) as prev_order_datetime
		from orders o
		join customers c on c. customer_id = o.customer_id
		where o.status = 'paid'
)
select 
	customer_id,
    customer_name,
    order_id,
    order_datetime,
    prev_order_datetime,
    TIMESTAMPDIFF(MINUTE, prev_order_datetime, order_datetime) as minutes_since_prev
from customer_order
where prev_order_datetime is not null
order by customer_name, order_datetime;

-- REFERENCES: https://www.geeksforgeeks.org/sql/mysql-lead-and-lag-function/
	-- https://dev.mysql.com/doc/refman/5.7/en/date-and-time-functions.html#function_timestampdiff
-- ChatGPT helped me learn that you can't have a window function in a WHERE clause
	-- and you can't reference window functions in each other in the same SELECT clause
    -- I was also missing the partition by

-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
-- Create a view named v_paid_order_lines that returns one row per PAID order item:
--   order_id, order_datetime, store_id, store_name,
--   customer_id, customer_name,
--   product_id, product_name, category_name,
--   quantity, unit_price (= products.price),
--   line_total (= quantity * products.price)
--
-- After creating the view, write a SELECT that uses the view to return:
--   store_name, category_name, revenue
-- where revenue is SUM(line_total),
-- sorted by revenue DESC.

create view v_paid_order_lines as 
	select
		o.order_id as order_id,
        o.order_datetime as order_datetime,
        o.store_id as store_id,
        s.name as store_name,
        o.customer_id as customer_id,
        concat(c.last_name, ', ', c.first_name) as customer_name,
        oi.product_id as product_id,
        p.name as product_name,
        cat.name as category_name, 
        oi.quantity as quantity,
        p.price as unit_price,
        oi.quantity * p.price as line_total -- don't use sum(); we don't want to aggregate
    from orders o
    join customers c on c.customer_id = o.customer_id
    join order_items oi on oi.order_id = o.order_id
    join stores s on s.store_id = o.store_id
    join products p on p.product_id = oi.product_id
    join categories cat on cat.category_id = p.category_id
    where o.status = 'paid';

select 
	store_name,
    category_name,
    sum(line_total) as revenue
from v_paid_order_lines
group by store_name, category_name
order by revenue desc;

-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
-- Create a view named v_paid_store_payments with:
--   store_id, store_name, payment_method, revenue
-- where revenue is total PAID revenue for that store/payment_method.
--
-- Then query the view to return:
--   store_name, payment_method, revenue,
--   store_total_revenue (window SUM over store),
--   pct_of_store_revenue (= revenue / store_total_revenue)
-- Sort by store_name, revenue DESC.

create view v_paid_store_payments as
	select 
		o.store_id,
        s.name as store_name,
        o.payment_method,
        sum(oi.quantity * p.price) as revenue
	from orders o
    join stores s on s.store_id = o.store_id
    join order_items oi on oi.order_id = o.order_id
    join products p on p.product_id = oi.product_id
    where o.status = 'paid' 
    group by o.store_id, s.name, o.payment_method;
    
with store_revenue as (
	select
		store_name,
		payment_method,
		revenue,
		sum(revenue) over (partition by store_name) -- I had this as group by; chatgpt helped
													-- I also had an unnecessary group by
			as store_total_revenue
	from v_paid_store_payments
)
select 
	*,
    concat(format((revenue / store_total_revenue) * 100, 1), '%') as pct_of_store_revenue
from store_revenue
order by store_name, revenue desc;

-- REFERENCES: https://database.guide/format-a-number-as-a-percentage-in-mysql/

-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
-- Identify items where on_hand is low compared to recent demand:
-- Using a CTE, compute total_units_sold per store/product for PAID orders.
-- Then join inventory to that result and return rows where:
--   on_hand < total_units_sold
-- Return: store_name, product_name, on_hand, total_units_sold, units_gap (= total_units_sold - on_hand)
-- Sort by units_gap DESC.

with units_sold as (
	select
		o.store_id,
        s.name as store_name,
        oi.product_id,
        p.name as product_name,
        sum(quantity) as total_units_sold
	from orders o
    join order_items oi on oi.order_id = o.order_id
    join stores s on s.store_id = o.store_id
    join products p on p.product_id = oi.product_id
    where o.status = 'paid'
    group by o.store_id, s.name, oi.product_id, p.name
)
select
    u.store_name,
    u.product_name,
    i.on_hand,
    u.total_units_sold,
    u.total_units_sold - i.on_hand as units_gap
from units_sold u
join inventory i on i.store_id = u.store_id -- ChatGPT corrected me to matach to store, not product
order by units_gap desc;
