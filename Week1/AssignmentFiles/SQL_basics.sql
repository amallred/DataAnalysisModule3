USE coffeeshop_db;

-- =========================================================
-- BASICS PRACTICE
-- Instructions: Answer each prompt by writing a SELECT query
-- directly below it. Keep your work; you'll submit this file.
-- =========================================================

-- Q1) List all products (show product name and price), sorted by price descending.
select name, price from products
order by price desc;
-- Q2) Show all customers who live in the city of 'Lihue'.
select * from customers where city = 'Lihue';
-- Q3) Return the first 5 orders by earliest order_datetime (order_id, order_datetime).
select order_id, order_datetime from orders
order by order_datetime asc
limit 5;
-- Q4) Find all products with the word 'Latte' in the name.
select * from products where name like '%Latte%';
-- Q5) Show distinct payment methods used in the dataset.
SELECT DISTINCT payment_method FROM orders;
-- Q6) For each store, list its name and city/state (one row per store).
SELECT name, city, state FROM stores;

-- Q7) From orders, show order_id, status, and a computed column total_items
--     that counts how many items are in each order.

-- NEW ATTEMPT WITHOUT DIRECTLY REFERENCING OTHER STUDENT'S WORK AND AFTER FINISHING THE MYSTERY ASSIGNMENT
select o.order_id as order_id,
	o.status as status,
    sum(oi.quantity) as total_items
from orders o
left join order_items oi
	on oi.order_id = o.order_id
group by o.order_id;
-- Note: after completing the other assignments, this was much easier to wrap my head around.



-- ALTER TABLE orders ADD COLUMN total_items TINYINT UNSIGNED NOT NULL DEFAULT 0;
-- ALTER TABLE orders ADD COLUMN total_items TINYINT;
-- UPDATE orders o1
-- JOIN order_items o2 ON o1.order_id = o2.order_id
-- SET o1.total_items = o2.quantity;
-- SELECT order_id, status, total_items FROM orders;

-- The following solution is from a classmate after we discussed resourses and ideas. It works correctly and mine does not. I aim to make mine work without outright copying theirs. For now, I need to step away.
-- select o.order_id, o.status, sum(oi.quantity) as total_items from orders o
-- join order_items oi on o.order_id = oi.order_id
-- group by o.order_id, o.status;
-- select * from order_items;
-- Reference: https://stackoverflow.com/questions/27376152/how-to-add-a-column-to-a-table-from-another-table-in-mysql 

-- Q8) Show orders placed on '2025-09-04' (any time that day).
SELECT * FROM orders where order_datetime like '%2025-09-04%';
-- Q9) Return the top 3 most expensive products (price, name).
SELECT name, price FROM products ORDER BY price DESC LIMIT 3;
-- Q10) Show customer full names as a single column 'customer_name'
--      in the format "Last, First".
SELECT *, concat(last_name, ' ', first_name) AS customer_name FROM customers
-- Reference: https://www.geeksforgeeks.org/sql/how-to-concat-two-columns-into-one-with-the-existing-column-name-in-mysql/