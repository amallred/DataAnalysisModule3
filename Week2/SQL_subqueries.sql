USE coffeeshop_db;

-- =========================================================
-- SUBQUERIES & NESTED LOGIC PRACTICE
-- =========================================================

-- Q1) Scalar subquery (AVG benchmark):
--     List products priced above the overall average product price.
--     Return product_id, name, price.

select product_id, name, price
	from products
    where price > (
		select avg(price) 
        from products
    );

-- =========================================================
-- =========================================================

-- Q2) Scalar subquery (MAX within category):
--     Find the most expensive product(s) in the 'Beans' category.
--     (Return all ties if more than one product shares the max price.)
--     Return product_id, name, price.

select p.product_id, p.name, p.price
from products p 
-- join categories c
-- 	on c.category_id = p.category_id
where p.price = (
	select max(price) from products p
	join categories c
		on c.category_id = p.category_id
	where c.name = 'Beans'
);

-- Checking what the max Bean price is
-- select max(price) from products p
-- join categories c
-- 	on c.category_id = p.category_id
-- where c.name = 'Beans';

-- =========================================================
-- =========================================================

-- Q3) List subquery (IN with nested lookup):
--     List customers who have purchased at least one product in the 'Merch' category.
--     Return customer_id, first_name, last_name.
--     Hint: Use a subquery to find the category_id for 'Merch', then a subquery to find product_ids.

select c.customer_id, c.first_name, c.last_name
from customers c
where c.customer_id in ( -- Identify customers with Merch orders
	select o.customer_id
		from orders o
		where o.order_id in ( -- Locate orders with Merch products
			select order_id
				from order_items oi
				where oi.product_id in ( -- Locate products with Merch id
					select product_id
						from products	
						where category_id = ( -- Find the id for Merch category
								select category_id 
									from categories cat
									where cat.name = 'Merch'
		))));

-- I used ChatGPT to help walk me through translating the paths and my logic into the actual code. Id did not provide me any code, just a sounding board. 
-- These nested subqueries made me feel icky. I'd rather do this with Joins.

-- =========================================================
-- =========================================================

-- Q4) List subquery (NOT IN / anti-join logic):
--     List products that have never been ordered (their product_id never appears in order_items).
--     Return product_id, name, price.

select product_id, name, price
from products 
where product_id not in (
	select product_id 
    from order_items
);

select product_id, name, price
from products 
where product_id in (
	select product_id 
    from order_items
) is not true; -- yields the same results

-- This returns a null row, which I found exists in the products table.
-- Looking into things, it looks like NULL and NOT IN don't work well together
-- https://dev.mysql.com/blog-archive/a-must-know-about-not-in-in-sql-more-antijoin-optimization/

-- =========================================================
-- =========================================================

-- Q5) Table subquery (derived table + compare to overall average):
--     Build a derived table that computes total_units_sold per product
--     (SUM(order_items.quantity) grouped by product_id).
--     Then return only products whose total_units_sold is greater than the
--     average total_units_sold across all products.
--     Return product_id, product_name, total_units_sold.


-- This didn't work but I felt I was close. I had ChatGPT walk me through the 
-- logic of rearranging it

-- select p.product_id as product_id, 
-- 		p.name as product_name,
--         qty_per_prod.total_units_sold as total_units_sold
--         -- Get total quantity sold of each product
-- from products p 
-- join ( select product_id, sum(quantity) as total_units_sold
-- 		from order_items
--         group by product_id
-- 	) as qty_per_prod
--  on qty_per_prod.product_id = p.product_id
--     -- Get average total units sold
-- join (
-- 	select avg(total_units_sold)
--     from order_items
-- ) as avg_qty_sold
-- on avg_qty_sold.product_id = qty_per_prod.product_id 
-- join products p
-- on p.product_id = qty_per_prod.product_id
-- where qty_per_prod.total_units_sold > avg_qty_sold.avg_qty
-- ;

select p.product_id as product_id, 
		p.name as product_name,
        qty_per_prod.total_units_sold as total_units_sold
from products p
join (
	select product_id, 
			sum(quantity) as total_units_sold
		from order_items
        group by product_id
	) as qty_per_prod -- Get average total units sold
on qty_per_prod.product_id = p.product_id

where qty_per_prod.total_units_sold > (
	select avg(total_units_sold) -- Get total quantity sold of each product
		from ( 
			select product_id, 
					sum(quantity) as total_units_sold
				from order_items
				group by product_id
			) as qty_per_prod
);
