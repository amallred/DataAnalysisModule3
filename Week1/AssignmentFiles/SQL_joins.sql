USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.

select p.name as product_name, c.name as category_name, price
from products p
inner join categories c
	on p.category_id = c.category_id;
    
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.

	-- 	Joining orders and order_items
select o.order_id as order_id, 
		o.order_datetime as order_datetime, 
		(select name from stores s where o.store_id = s.store_id) as store_name, 
        (select name from products p where oi.product_id = p.product_id)as product_name, 
        oi.quantity as quantity, 
        quantity * (select price from products p where oi.product_id = p.product_id) as line_total
from orders o
left join order_items oi
	on o.order_id = oi.order_id;
    
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).

	-- Joining from orders and order_items
    select concat(c.last_name, ', ',c.first_name)as customer_name, -- combine first and last names from customers
			s.name as store_name, -- store.name matches store_id
            o.order_datetime,  
            sum(oi.quantity * p.price) as order_total -- sum (oi quantity * p.price)
	from orders o
    inner join order_items oi 
		on o.order_id = oi.order_id
        and o.status = 'paid'
	left join customers c
		on o.customer_id = c.customer_id
	left join stores s
		on o.store_id = s.store_id
	left join products p
		on oi.product_id = p.product_id
	group by o.order_id;
	-- I originally had a lot of subqueries, but found that you can have multiple joins, so I restructured it as seen above.

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.

select c.first_name as first_name,
	c.last_name as last_name,
    c.city as city,
    c.state as state
from customers c 
left join orders o
	on c.customer_id = o.customer_id
where o.order_id is null;

	-- TO THE TEACHER: I'm actually pretty confident about this one, but the table is empty. Am I missing something?

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
select store_name, product_name, total_units from 
(select s.name as store_name,
		p.name as product_name,
        sum(oi.quantity) as total_units, -- chatgpt helped here; grouping had to happen before the window function
       row_number() over (
			partition by s.name
            order by s.name, sum(oi.quantity) desc
		) as ranked_item
from orders o
left join order_items oi
	on o.order_id = oi.order_id 
left join products p 
	on oi.product_id = p.product_id
left join stores s 
	on o.store_id = s.store_id
where o.status = 'paid'
group by s.name, p.name
) as ranked
where ranked_item = 1;

-- DISCLAIMER: I used chatgpt to help figure out the row_number() logic
-- other reference: https://stackoverflow.com/questions/48133947/sql-select-most-popular-items-in-each-store

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.

select s.name as store_name,
		p.name as product_name,
        i.on_hand as on_hand
from inventory i
left join stores s
	on i.store_id = s.store_id
left join products p
	on i.product_id = p.product_id
where i.on_hand < 12;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').

select s.name as store,
		concat(e.last_name, ', ', e.first_name) as manager_name,
		e.hire_date
from employees e
left join stores s
	on e.store_id = s.store_id
where e.title = 'Manager';

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

with item_revenue as (
	select 
		p.name as product_name,
        sum(oi.quantity * p.price) as total_revenue
	from order_items oi
    left join products p
		on oi.product_id = p.product_id
	left join orders o
		on oi.order_id = o.order_id
	where o.status = 'paid'
	group by p.name
)
select product_name,
		total_revenue
from item_revenue
where total_revenue > (select avg(total_revenue) from item_revenue);

	-- I used ChatGPT to check my answer; I missed the 'paid' filter

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.

select concat(c.last_name, ', ', c.first_name)as customer_name,
		max(o.order_datetime) as last_paid_order_date
from customers c
left join orders o
	on c.customer_id = o.customer_id
    and o.status = 'paid'
group by customer_name;

	-- I'm also fairly confident about this one and am not seeing any NULL values.

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).

select s.name as store_name,
		c.name as category,
        sum(oi.quantity) as total_units,
        sum(oi.quantity * p.price) as total_revenue
from stores s
left join orders o
	on o.store_id = s.store_id
left join order_items oi
	on o.order_id = oi.order_id
left join products p
	on oi.product_id = p.product_id
left join categories c
	on p.category_id = c.category_id
where o.status = 'paid'
group by store_name, category;