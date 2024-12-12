/*QUESTIONS TO CHECK THE DATASET*/

--Q1: Find all records where either the Unit price or Quantity is null.

SELECT *
FROM supermarket_sales
WHERE Unit_price IS NULL
    OR Quantity IS NULL

--Q2: List any missing or duplicated Invoice_ID values in the dataset.

SELECT *
FROM supermarket_sales
WHERE Invoice_ID IS NULL

SELECT Invoice_ID, COUNT(*) AS occurrence_count
FROM supermarket_sales
GROUP BY Invoice_ID
HAVING COUNT(*) > 1

--Q3: Find all incorrect or negative sales (for example, if Unit price or Quantity is negative)

SELECT *
FROM supermarket_sales
WHERE Unit_price < 0
    OR Quantity < 0

/*QUESTIONS RELATED TO COMPANY*/

--Q1 : This dataset is to analyse what Branch and when is this dataset?
SELECT DISTINCT Branch
    , MIN([Date]) AS start_date
    , MAX([Date]) AS end_date
    , MIN([Time]) AS start_time
    , MAX([Time]) AS end_time
FROM supermarket_sales
GROUP BY Branch
ORDER BY Branch

--Q2 : What is total sale and sale of each brand
SELECT ROUND(SUM(Unit_price * Quantity), 2) AS Total_sale
FROM supermarket_sales
SELECT Branch
    ,ROUND(SUM(Unit_price * Quantity), 2) AS Total_sale
FROM supermarket_sales
GROUP BY Branch
ORDER BY Total_sale DESC

--Q3 : How much sale of each brand by time
SELECT Branch
    ,DATEPART(MONTH, [Date]) AS 'Month'
    ,ROUND(SUM(Unit_price * Quantity), 2) AS Total_sale
FROM supermarket_sales
GROUP BY Branch, DATEPART(MONTH, [Date])
ORDER BY Total_sale DESC

--Q4 : How many orders are placed, by Branch and time
SELECT Branch
    ,DATEPART(MONTH, [Date]) AS 'Month' 
    ,COUNT(Invoice_ID) AS Total_order
FROM supermarket_sales
GROUP BY Branch, DATEPART(MONTH, [Date])
ORDER BY Total_order DESC

--Q5 : Total sale and Total order of each Product line
SELECT Product_line
    ,ROUND(SUM(Unit_price * Quantity),2) AS Total_sale
    ,COUNT(Invoice_ID) AS Total_order
FROM supermarket_sales
GROUP BY Product_line
ORDER BY Product_line

--Q6 : Which branch has the most invoices
SELECT Branch, count_invoice
FROM 
    (SELECT Branch, COUNT(Invoice_ID) AS count_invoice
    FROM supermarket_sales
    GROUP BY Branch) AS branch_invoice
WHERE count_invoice = (SELECT MAX(count_invoice) 
                        FROM
                            (SELECT Branch, COUNT(Invoice_ID) AS count_invoice
                            FROM supermarket_sales
                            GROUP BY Branch)AS branch_invoice)

--Q7 : How many invoices by payment method in the branch has the most invoices
SELECT Payment, COUNT(Invoice_ID) AS count_invoice
FROM supermarket_sales
WHERE Branch = 'A'
GROUP BY Payment;

--Q8 : What payment method is used most in each branch
WITH
    A AS
        (SELECT Branch, Payment, COUNT(Payment) AS count_payment
        FROM supermarket_sales
        GROUP BY Branch, Payment)
SELECT A.Branch, A.Payment, A.count_payment
FROM A
WHERE A.count_payment = (SELECT MAX(count_payment) 
                        FROM A AS B
                        WHERE A.Branch = B.Branch)
ORDER BY A.Branch

--Q9 : Find the month that has highest revenue
WITH
    A AS       
        (SELECT DATEPART(MONTH, [Date]) AS 'Month' 
                ,ROUND(SUM(Unit_price * Quantity), 2) AS Total_sale
        FROM supermarket_sales
        GROUP BY DATEPART(MONTH, [Date]))
SELECT A.[Month], A.Total_sale
FROM A
WHERE A.Total_sale = (SELECT MAX(Total_sale) FROM A AS a)

--Q10 : Find the AUP, APT, UPT index for each month
SELECT DATEPART(MONTH,[Date]) AS 'Month'
        ,ROUND(SUM(Unit_price*Quantity) / SUM(Quantity),2 ) AS AUP
        ,ROUND(SUM(Unit_price*Quantity) / COUNT(Invoice_ID),2) AS APT
        ,SUM(Quantity) / COUNT(Invoice_ID) AS UPT
FROM supermarket_sales
GROUP BY DATEPART(MONTH,[Date])
ORDER BY DATEPART(MONTH,[Date])

--Q11 : Orders in each time frame by hour
SELECT DATEPART(HOUR, [Time]) AS 'Hour'
        ,COUNT(Invoice_ID) AS count_order
FROM supermarket_sales
GROUP BY DATEPART(HOUR, [Time])
ORDER BY COUNT(Invoice_ID) DESC

--Q12 : How many orders in hour on average
SELECT COUNT(Invoice_ID) / DATEDIFF(HOUR, MIN([Time]), MAX([Time]))
FROM supermarket_sales

--Q13 : Which time frame the order quantity reach more than the average order per hour
SELECT DATEPART(HOUR, [Time]) AS 'Hour'
        ,COUNT(Invoice_ID) AS count_order
FROM supermarket_sales
GROUP BY DATEPART(HOUR, [Time])
HAVING COUNT(Invoice_ID) > (SELECT COUNT(Invoice_ID) / DATEDIFF(HOUR, MIN([Time]), MAX([Time]))
                            FROM supermarket_sales)
ORDER BY count_order DESC

--Q14 : Rating the sum of sale for each invoice (from normal to high), assume normal is below the AVG, and else

WITH
    A AS
        (SELECT Invoice_ID, ROUND((Unit_price*Quantity),0) AS sum_sale
        FROM supermarket_sales)
    ,B AS    
        (SELECT *, CASE
            WHEN sum_sale < (SELECT AVG(sum_sale) FROM A) THEN 'Normal'
            ELSE 'High'
            END AS Rating
        FROM A)
    SELECT Rating, COUNT(*) AS invoice_count -- Extra Q: how many high or low invoices
    FROM B
    GROUP BY Rating;

--Q15 : Display the proportion of invoice for each productline in those high invoice

WITH
    A AS
        (SELECT Invoice_ID, ROUND((Unit_price*Quantity),0) AS sum_sale
        FROM supermarket_sales)
    ,B AS    
        (SELECT *, CASE
            WHEN sum_sale < (SELECT AVG(sum_sale) FROM A) THEN 'Normal'
            ELSE 'High'
            END AS Rating
        FROM A)
    ,C AS    
        (SELECT S.Product_line
                ,COUNT(S.Product_line) AS count_invoice
        FROM B
        LEFT JOIN supermarket_sales S ON B.Invoice_ID = S.Invoice_ID
        WHERE B.Rating = 'High'
        GROUP BY S.Product_line)
    SELECT Product_line,
           ROUND(count_invoice *100 / (SELECT SUM(count_invoice) FROM C), 0) AS proportion
    FROM C
    ORDER BY proportion

--Q16: Calculate the average sale per order for each branch.

SELECT Branch
        ,ROUND(SUM(Unit_price*Quantity)/COUNT(Invoice_ID),2) AS avg_per_ord
FROM supermarket_sales
GROUP BY Branch

--Q17: Calculate the total quantity sold for each product line across all branches

SELECT Product_line, SUM(Quantity) AS qty_sold
FROM supermarket_sales
GROUP BY Product_line
ORDER BY qty_sold DESC

--Q18: Determine the highest sale amount for each product line and identify which invoice had that sale.

WITH
    A AS
        (SELECT Invoice_ID ,Product_line
                ,ROUND((Unit_price * Quantity),2) AS sale_amount
        FROM supermarket_sales)
    ,B AS
        (SELECT Product_line ,MAX(sale_amount) AS max_sale
        FROM A
        GROUP BY Product_line)
    SELECT A.Invoice_ID, A.Product_line, B.max_sale
    FROM B
    LEFT JOIN A ON A.sale_amount = B.max_sale 

--Q19: Find the total sales by Customer type (Member vs. Normal).

SELECT Customer_type, ROUND(SUM(Unit_price*Quantity),2) AS Total_sale
FROM supermarket_sales
GROUP BY Customer_type;

--Q20: List all invoices where the sale amount is greater than the average sale amount for that branch.

WITH
    A AS
        (SELECT Branch, Invoice_ID, ROUND(SUM(Unit_price*Quantity),2) AS sale_amount
        FROM supermarket_sales
        GROUP BY Branch, Invoice_ID)
    ,B AS
        (SELECT Branch, AVG(sale_amount) AS avg_sale
        FROM A
        GROUP BY Branch)
    SELECT A.Invoice_ID, A.Branch, A.sale_amount
    FROM A LEFT JOIN B ON A.Branch = B.Branch
    WHERE A.sale_amount > B.avg_sale

--Q21: Find out the average sale per product line in each branch.

WITH
    A AS
        (SELECT Branch, Product_line, ROUND(Unit_price*Quantity,2) AS sale
        FROM supermarket_sales)
    SELECT Branch, Product_line, ROUND(AVG(sale),0) AS avg_sale
    FROM A
    GROUP BY Branch, Product_line
    ORDER BY Branch

--Q24: Identify the most expensive product (highest unit price) sold for each city.

SELECT City, Unit_price AS highest_price
FROM supermarket_sales S
WHERE Unit_price = (SELECT MAX(Unit_price) 
                    FROM supermarket_sales
                    WHERE City = S.City)

--Q25: For each city, show the Branch, Total sales, and the number of invoices placed.

SELECT City
    ,Branch
    ,ROUND(SUM(Unit_price*Quantity),2) AS total_sales
    ,COUNT(Invoice_ID) AS no_of_inovice
FROM supermarket_sales
GROUP BY City, Branch;

--Q26: Identify which day of the week has the highest number of orders and total sales.

WITH
    A AS
        (SELECT DATENAME(WEEKDAY, [Date]) AS 'weekday'
            ,ROUND(SUM(Unit_price*Quantity),2) AS total_sale
            ,COUNT(Invoice_ID) AS no_of_ord
        FROM supermarket_sales
        GROUP BY DATENAME(WEEKDAY, [Date]))
    SELECT weekday, total_sale, no_of_ord
    FROM A
    WHERE total_sale = (SELECT MAX(total_sale) FROM A) 
        AND no_of_ord = (SELECT MAX(no_of_ord) FROM A)

--Q27: Determine the average sales per day for each branch.

SELECT Branch 
        ,ROUND(SUM(Unit_price * Quantity) / DATEDIFF(DAY, MIN([Date]), MAX([Date])),0) AS avg_day_sale
FROM supermarket_sales
GROUP BY Branch

--Q28: Find the highest sale on weekday, based on total sales.

SELECT TOP 1
    DATENAME(WEEKDAY, [Date]) AS weekday,
    ROUND(SUM(Unit_price * Quantity), 2) AS total_sales
FROM supermarket_sales
GROUP BY DATENAME(WEEKDAY, [Date])
ORDER BY total_sales DESC

--Q29: Show the monthly trend of sales for each branch (i.e., sales grouped by month).

SELECT Branch
    ,DATEPART(MONTH, [Date]) AS 'Month'
    ,ROUND(SUM(Unit_price * Quantity),0) AS monthly_sale
FROM supermarket_sales
GROUP BY Branch, DATEPART(MONTH, [Date])
ORDER BY Branch, [Month]

--Q30: Find the total sales for each product line in each city and rank them from highest to lowest.

SELECT City, Product_line
        ,ROUND(SUM(Unit_price * Quantity),0) AS total_sale
FROM supermarket_sales
GROUP BY City, Product_line
ORDER BY total_sale DESC

--Q31: For each branch, show the total sales for the Home and lifestyle product line and compare it to the total sales of all product lines in that branch.

WITH
    A AS
        (SELECT Branch, Product_line ,ROUND(SUM(Unit_price * Quantity),0) AS hl_sale
        FROM supermarket_sales
        WHERE Product_line = 'Home and lifestyle'
        GROUP BY Branch, Product_line)
    ,B AS
        (SELECT Branch, ROUND(SUM(Unit_price * Quantity),0) AS total_sale
        FROM supermarket_sales
        GROUP BY Branch)
    SELECT A.Branch, A.Product_line, A.hl_sale, B.total_sale, ROUND((A.hl_sale / B.total_sale) * 100, 0) AS proportion
    FROM A
    LEFT JOIN B ON A.Branch = B.Branch

--Q32: Determine the percentage increase or decrease in sales from the first month to the last month in the dataset.

WITH
    A AS
        (SELECT DATEPART(MONTH, [Date]) AS 'Month'
                ,ROUND(SUM(Unit_price * Quantity),0) AS sale_amount
        FROM supermarket_sales
        GROUP BY DATEPART(MONTH, [Date]))
    ,B AS
        (SELECT [Month] AS 'first/last_month', sale_amount
        FROM A
        WHERE [Month] = (SELECT MIN(A.[Month]) FROM A))
    ,C AS
        (SELECT [Month] AS 'first/last_month', sale_amount
        FROM A
        WHERE [Month] = (SELECT MAX(A.[Month]) FROM A))
SELECT 
    ((C.sale_amount - B.sale_amount) / B.sale_amount) * 100 AS percentage_change
FROM 
    B, C

--Q33: Find the number of orders and total sales where the quantity is more than average quantity, grouped by product line.

SELECT Product_line, COUNT(Invoice_ID) AS no_of_ord
        ,ROUND(SUM(Unit_price * Quantity),0) AS total_sale
FROM supermarket_sales
GROUP BY Product_line
HAVING SUM(Quantity) > (SELECT AVG(Quantity) 
                        FROM supermarket_sales)

--Q34: Identify the lowest sales invoice by Branch (show Invoice ID, Branch, Product line, and sales).

SELECT Invoice_ID
    , Branch
    , Product_line
    , ROUND(Unit_price * Quantity , 0) AS sale
FROM supermarket_sales
WHERE ROUND(Unit_price * Quantity , 0) = (SELECT MIN(ROUND(Unit_price * Quantity , 0)) 
                                        FROM supermarket_sales)

--Q35: Show the total sales for each Gender in the Electronic accessories product line, but only for invoices with a quantity greater than 5.

SELECT Gender, ROUND(SUM(Unit_price * Quantity),0) AS total_sale
FROM supermarket_sales
WHERE Product_line = 'Electronic accessories'
    AND Quantity >=5
GROUP BY Gender

--Q42: Use a window function to calculate the cumulative total sales for each branch, ordered by date.

SELECT 
    Branch,
    Date,
    ROUND(SUM(Unit_price * Quantity) OVER (PARTITION BY [Branch] ORDER BY [Date] ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS cumulative_sales
FROM 
    supermarket_sales
ORDER BY 
    Branch, Date

--Q43: Calculate the total profit for each product line (Profit = Sales - COGS).

WITH
    A AS
        (SELECT *
            ,ROUND((Unit_price * Quantity) ,0) AS sale
            ,ROUND((Unit_price * Quantity) - cogs, 2) AS profit
        FROM supermarket_sales)
    SELECT Product_line ,SUM(profit)
    FROM A
    GROUP BY Product_line

--Q45: Determine the average revenue per transaction for each city.

SELECT City, ROUND(SUM(Unit_price * Quantity) / COUNT(Invoice_ID),2) AS avg_sale
FROM supermarket_sales
GROUP BY City

/*QUESTIONS RELATED TO CUSTOMER*/

--Q1 : Which branch Customers make purchase most, belong to which City
SELECT Branch, City, COUNT(Invoice_ID) AS Total_order
FROM supermarket_sales
GROUP BY Branch, City
ORDER BY Total_order DESC

--Q2 : Find the total sale, total order and total quantiy by Gender
SELECT Gender
        ,ROUND(SUM(Unit_price*Quantity),2) AS Total_sale
        ,COUNT(Invoice_ID) AS Total_order
        ,SUM(Quantity) AS Total_quantity
FROM supermarket_sales
GROUP BY Gender
ORDER BY Total_sale DESC

--Q3 : For each productline, find the total order by Gender
SELECT Product_line, Gender, COUNT(Invoice_ID) AS Total_order
FROM supermarket_sales
GROUP BY Product_line, Gender
ORDER BY Total_order DESC

--Q4: Find the total sales by payment method (for all branches) and identify the most used payment method

SELECT Payment, ROUND(SUM(Unit_price * Quantity),0) AS total_sale
FROM supermarket_sales
GROUP BY Payment
ORDER BY total_sale DESC

--Q5: Determine the total number of orders by Customer type and Gender.

SELECT Customer_type, Gender, COUNT(Invoice_ID) AS no_of_ord
FROM supermarket_sales
GROUP BY Customer_type, Gender
ORDER BY Customer_type

--Q6: Find out the average quantity sold per order by Customer type (Normal vs. Member).

SELECT Customer_type ,AVG(Quantity) AS avg_quant
FROM supermarket_sales
GROUP BY Customer_type

--Q8: How many invoices were placed by each Gender for the Health and beauty product line?

SELECT Gender ,COUNT(Invoice_ID) AS count_invoice
FROM supermarket_sales
WHERE Product_line = 'Health and beauty'
GROUP BY Gender