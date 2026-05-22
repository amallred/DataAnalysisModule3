-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
select order_id, sum(quantity) as total_items from order_items
group by order_id;
-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').
select order_id, sum(total_items)  
from orders where status='paid'
group by order_id;
-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.

	-- Add column order_date with date as datatype
alter table orders add order_date DATE; 
	-- set data in each row in order_date, pulling the date from order_datetime
update orders set order_date = cast(order_datetime as DATE) where order_id > 0; 
select order_date, count(order_id) as orders_count 
from orders
group by order_date;
	-- References:
	-- Split datetime https://stackoverflow.com/questions/17678551/splitting-date-into-2-columns-date-time-in-sql
	-- https://stackoverflow.com/questions/1122790/fill-entire-sql-table-column
	-- https://www.bytebase.com/reference/mysql/error/1175-using-safe-update-mode/

-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
select avg(total_items)from orders
where (status = 'paid');
	-- Reference: https://www.geeksforgeeks.org/sql/sql-subquery/
    
-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.
select product_id, sum(quantity) as total_units
from order_items
group by product_id 
order by total_units desc;

-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').

select product_id, sum(order_id IN (SELECT order_id FROM orders WHERE status='paid')) as total_units_paid
from order_items
group by product_id
order by total_units_paid desc;

-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
select store_id, count(distinct customer_id) as unique_customers
from orders
where status = 'paid'
group by store_id;

-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.
select DAYNAME(order_datetime) as day_name, sum(order_id) as orders_count
from orders
where status = 'paid'
group by day_name 
order by orders_count desc
limit 1;

-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).
select order_date, sum(order_id) as orders_count
from orders
group by order_date 
having orders_count > 3;
	-- NOTE TO TEACHER: I have the order_date column from the basics questions, but I'd redo this by doing select date(order_datetime) as order_date ...
    
-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
select store_id, payment_method, sum(status = 'paid') as paid_orders_count
from orders
group by store_id, payment_method
order by store_id asc;
	-- Reference: https://stackoverflow.com/questions/2421388/using-group-by-on-multiple-columns

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
select 100*sum(payment_method = 'app')/count(*) as pct_app_paid_orders
from orders
where status = 'paid';
	-- Reference: https://stackoverflow.com/questions/24682734/percentage-of-rows-that-match-condition

-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
select hour(order_datetime) as hour_of_day, count(order_id) as orders_count
from orders
where status = 'paid'
group by hour_of_day
order by orders_count desc;

-- ================
