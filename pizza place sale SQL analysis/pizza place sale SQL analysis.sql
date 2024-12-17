/*TO CHECK THE DATASET FIRST*/

--Q1 : Check for if any null or missing value with relationship between tables
SELECT order_details.order_id, order_details.pizza_id
FROM order_details
LEFT JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
WHERE pizzas.pizza_id IS NULL

SELECT orders.order_id
FROM orders
LEFT JOIN order_details ON orders.order_id = order_details.order_id
WHERE order_details.order_id IS NULL

SELECT order_details.pizza_id
FROM order_details
LEFT JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
WHERE pizzas.pizza_id IS NULL


SELECT pizza_id, price
FROM pizzas
WHERE price IS NULL

--Q2 : Check for duplicate values

SELECT order_id, COUNT(*)
FROM order_details
GROUP BY order_id
HAVING COUNT(*) > 1 /*This query shows that order_id does not contain unique values
                    as data structure recorded a single order_id can buy different types of pizza*/

SELECT pizza_id, COUNT(*)
FROM pizzas
GROUP BY pizza_id
HAVING COUNT(*) > 1

/*Company Insight Questions (Business Metrics)*/

--Q : Total number of orders placed

SELECT COUNT(DISTINCT order_id) AS total_ord
FROM orders

--Q : Find the total quantity of each pizza type sold across all orders.

SELECT pt.name
    ,SUM(od.quantity) AS total_quantity
FROM pizza_types pt
    LEFT JOIN pizzas p ON p.pizza_type_id = pt.pizza_type_id
    LEFT JOIN order_details od ON p.pizza_id = od.pizza_id
    LEFT JOIN orders o ON od.order_id = o.order_id
GROUP BY pt.name
ORDER BY total_quantity DESC

--Q : Identify the top 5 pizzas by revenue

SELECT TOP 5 pt.name, ROUND(SUM(od.quantity * p.price),2) AS total_rev
FROM pizzas p
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id
    LEFT JOIN orders o ON o.order_id = od.order_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY total_rev DESC

--Q : Calculate the total number of pizzas sold for each size (S, M, L).

SELECT p.[size], SUM(od.quantity) AS total_quantity
FROM pizzas p
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id  
    LEFT JOIN orders o ON o.order_id = od.order_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY p.[size]
ORDER BY total_quantity DESC
--Q : Find the number of orders placed, total quantity and total revenue for each pizza size on the highest weekday of the highest revenue month, compare with the lowest ones

SELECT DATEPART(MONTH, o.[date]) AS 'highest month'
        , COUNT(DISTINCT o.order_id) AS total_ord
        , SUM(od.quantity) AS total_qty
        , ROUND(SUM(od.quantity * p.price), 2) AS rev
FROM pizzas P
    INNER JOIN order_details od ON od.pizza_id = p.pizza_id
    INNER JOIN orders o ON o.order_id = od.order_id
    INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE DATENAME(MONTH, o.[date]) = 'July'
    AND DATENAME(WEEKDAY, o.[date]) = 'Friday'
GROUP BY DATEPART(MONTH, o.[date])

SELECT DATEPART(MONTH, o.[date]) AS 'lowest month'
        , COUNT(DISTINCT o.order_id) AS total_ord
        , SUM(od.quantity) AS total_qty
        , ROUND(SUM(od.quantity * p.price), 2) AS rev
FROM pizzas P
    INNER JOIN order_details od ON od.pizza_id = p.pizza_id
    INNER JOIN orders o ON o.order_id = od.order_id
    INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE DATENAME(MONTH, o.[date]) = 'October'
    AND DATENAME(WEEKDAY, o.[date]) = 'Sunday'
GROUP BY DATEPART(MONTH, o.[date])

--Q : Calculate the total revenue generated per pizza type, along with the number of pizzas sold.

SELECT pt.name
    , ROUND(SUM(od.quantity * p.price),2) AS total_rev
    , SUM(od.quantity) AS qty_sold
FROM pizzas p
    INNER JOIN order_details od ON od.pizza_id = p.pizza_id
    INNER JOIN orders o ON o.order_id = od.order_id
    INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY total_rev DESC

--Q : Determine the average quantity of pizzas ordered per order.

SELECT SUM(od.quantity) / COUNT(DISTINCT o.order_id) AS avg_qty
FROM orders o
    LEFT JOIN order_details od ON od.order_id = o.order_id
    
--Q : Find the pizza with the highest price and the total revenue it generated.

SELECT pt.name 
    ,ROUND(SUM(od.quantity * p.price),2) AS total_rev
FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN pizzas p ON p.pizza_id = od.pizza_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE p.price = (SELECT MAX(pizzas.price) FROM pizzas)
GROUP BY pt.name

--Q : Show the total revenue for each pizza type and size combination.

SELECT pt.category, p.[size] 
    ,ROUND(SUM(od.quantity * p.price),2) AS total_rev
FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN pizzas p ON p.pizza_id = od.pizza_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category, p.[size]
ORDER BY pt.category

--Q : Find the total number of orders that contain at least one "Chicken" pizza.

SELECT COUNT(DISTINCT o.order_id)
FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN pizzas p ON p.pizza_id = od.pizza_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE pt.name LIKE '%Chicken%'

--Q Find the average order value for pizzas in the "Chicken" category.

SELECT ROUND(SUM(od.quantity * p.price) / COUNT(DISTINCT o.order_id),1) AS avg_ord_val
FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN pizzas p ON p.pizza_id = od.pizza_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE pt.category = 'Chicken'

--Q Calculate the percentage of orders that include more than 2 pizzas.

WITH
    A AS
        (SELECT o.order_id, SUM(od.quantity) AS qty
        FROM orders o
            LEFT JOIN order_details od ON o.order_id = od.order_id
        GROUP BY o.order_id
        HAVING SUM(od.quantity) > 2)
    SELECT COUNT(A.order_id) * 1.0 / COUNT(o.order_id) *100 AS 'percentage'
    FROM orders o
        LEFT JOIN A ON o.order_id = A.order_id

--Q Identify the 3 most frequently ordered pizzas for the last month.

SELECT TOP 3 pt.name
    , COUNT(o.order_id) AS count_ord
FROM pizzas p
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id
    LEFT JOIN orders o ON o.order_id = od.order_id
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE DATEPART(YEAR, o.[date]) = (SELECT MAX(DATEPART(YEAR, orders.[date])) FROM orders)
    AND DATEPART(MONTH, o.[date]) = (SELECT MAX(DATEPART(MONTH, orders.[date])) FROM orders)
GROUP BY pt.name
ORDER BY count_ord DESC

--Q Find the average price of pizzas ordered in each order.

SELECT o.order_id
    , AVG(p.price) AS avg_price_per_ord
FROM pizzas p
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id
    LEFT JOIN orders o ON o.order_id = od.order_id
GROUP BY o.order_id
ORDER BY avg_price_per_ord DESC

--Q Find the total quantity of pizzas sold for each pizza type across all sizes.

SELECT pt.category
    , SUM(od.quantity) AS total_qty
FROM pizzas p
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id
    LEFT JOIN orders o ON o.order_id = od.order_id
GROUP BY pt.category
ORDER BY total_qty DESC

--Q Show the total quantity of pizzas ordered for each pizza type and size, along with the total revenue.

SELECT pt.category
    , p.[size]
    , ROUND(SUM(p.price * od.quantity),2) AS total_rev
FROM pizzas p
    LEFT JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
    LEFT JOIN order_details od ON od.pizza_id = p.pizza_id
    LEFT JOIN orders o ON o.order_id = od.order_id
GROUP BY pt.category, p.[size]
ORDER BY total_rev DESC