Create database Hotel;

create table sales(
customer_id VARCHAR(45),
order_date DATE,
product_id INT
);
create table menu(
product_id INT,
product_name VARCHAR(255),
price DECIMAL(10,2)
);
create table members(
customer_id VARCHAR(45),
join_date DATE
);

INSERT INTO members (customer_id, join_date)
VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

INSERT INTO menu (product_id, product_name, price)
VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

INSERT INTO sales (customer_id, order_date, product_id)
VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);



--1.What is the total amount each customer spent at the restaurant?
SELECT 
    m.product_name, -- Selecting the product name from the menu table
    s.customer_id, -- Selecting the customer ID from the sales table
    SUM(m.price) AS total_spent -- Calculating the total amount spent by each customer on each product
FROM 
    menu m
JOIN 
    sales s ON m.product_id = s.product_id -- Joining the menu and sales tables based on the product ID
GROUP BY 
    s.customer_id, m.product_name; -- Grouping the results by customer ID and product name


--2.How many days has each customer visited the restaurant?
SELECT 
    customer_id, -- Selecting the customer ID
    COUNT(DISTINCT order_date) AS days_visited -- Counting the distinct days a customer visited
FROM 
    sales -- Using the 'sales' table
GROUP BY 
    customer_id; -- Grouping the results by customer ID

--3.What was the first item from the menu purchased by each customer?

SELECT customer_id, first_order_date, product_name AS first_product_name
FROM (
    -- Subquery to rank orders within each customer based on order date
    SELECT 
        s.customer_id, -- Selecting the customer ID
        s.order_date AS first_order_date, -- Alias for the order date representing the first order
        m.product_name, -- Selecting the product name
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS order_rank -- Creating order ranking within each customer
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
) ranked_orders
WHERE order_rank = 1 -- Filtering to include only the first order for each customer
ORDER BY first_order_date; -- Ordering the results by the first order date


--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name, COUNT(*) AS frequency
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
GROUP BY m.product_name -- Grouping the results by product name to count the occurrences of each product
ORDER BY frequency DESC -- Sorting the results in descending order of purchase frequency


--5.Which item was the most popular for each customer?
SELECT s.customer_id, m.product_name, COUNT(*) AS frequency
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
GROUP BY s.customer_id, m.product_name -- Grouping the results by customer ID and product name
ORDER BY frequency DESC -- Sorting the results in descending order of purchase frequency


--6.Which item was purchased first by the customer after they became a member?

SELECT TOP 1 s.customer_id, m.product_name, s.order_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
JOIN Members mem ON s.customer_id = mem.customer_id -- Joining the Members table to get the customer's join date
WHERE s.order_date > mem.Join_date -- Filtering orders after the customer joined as a member
ORDER BY s.order_date -- Sorting orders by order date


--7.Which item was purchased just before the customer became a member

SELECT TOP 1 s.customer_id, m.product_name, s.order_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
JOIN Members mem ON s.customer_id = mem.customer_id -- Joining the Members table to get the customer's join date
WHERE s.order_date < mem.Join_date -- Filtering orders just before the customer joined as a member
ORDER BY s.order_date DESC -- Sorting orders by order date in descending order



--8.What is the total items and amount spent for each member before they became a member?

SELECT mem.customer_id, COUNT(*) AS total_items, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
JOIN Members mem ON s.customer_id = mem.customer_id -- Joining the Members table to associate customers and their membership details
WHERE s.order_date < mem.Join_date -- Filtering orders placed before the customer joined as a member
GROUP BY mem.customer_id -- Grouping the results by customer ID to summarize purchases for each customer


--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, 
       SUM(
           CASE WHEN m.product_name = 'sushi' 
           THEN 2 * m.price * 10 -- Sushi earns double points (2x multiplier)
           ELSE m.price * 10 -- Other items earn regular points (1x multiplier)
           END
       ) AS points
FROM sales s
JOIN menu m ON s.product_id = m.product_id -- Joining sales and menu tables based on product ID
GROUP BY s.customer_id -- Grouping the results by customer ID to calculate points for each customer

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the
-- end of January?
SELECT Members.customer_id, 
       SUM(
           CASE
               WHEN sales.order_date BETWEEN Members.Join_date AND DATEADD(DAY, 7, Members.Join_date)
               THEN 2 * menu.price * 10 -- Customers earn double points on all items during the first week
               ELSE menu.price * 10 -- Regular points on all other purchases
           END
       ) AS points_in_january
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN Members ON sales.customer_id = Members.customer_id
WHERE MONTH(Members.Join_date) = 1
GROUP BY Members.customer_id
