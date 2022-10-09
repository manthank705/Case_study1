
# Case Study 1 - Danny's Diner

<img src="https://user-images.githubusercontent.com/77930192/185515689-0f3802f9-c91a-478e-ade6-961d4f1d59e6.png" alt="Danny's Diner Image" width="500px" height="500px"/>

*My attempt at solving the Danny's Diner case study of the 8 weeks SQL challenge using Postgresql*.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, 
especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. 
Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program.  
Additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## Available Data
![Danny's Diner](https://user-images.githubusercontent.com/77930192/185516328-5aa04194-e92b-497a-84aa-63882a653c92.png)  
Here's a view of the schema of the sample data provided.  
More details on the case study can be found [here](https://8weeksqlchallenge.com/case-study-1/).

## Case Study Solutions

**1. What is the total amount each customer spent at the restaurant?**  
```SQL
SELECT s.customer_id, sum(m.price) AS total_sales
FROM sales s JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

```

The sales and menu tables were joined to be able to acces the price information of the products bought by customers. This was then sumed up per customer to determine how much was spent by each. 

customer_id | total_sales
----------- | ------------
A           | 76
B           | 74
C           | 36

The sample data provided shows that customer A has spent the most closely followed by customer B. 


**2. How many days has each customer visited the restaurant?**  
```SQL
SELECT s.customer_id, COUNT(DISTINCT s.order_date) as total_visits
FROM sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

It is important to include the *distinct* funtion when counting the days as customers can visit the stoe tice in one day or purchase more than one item during their visit, and each purchse is recorded on a separate row.

customer_id | total_visits
----------- | --------------
A           | 4
B           | 6
C           | 2


**3. What was the first item from the menu purchased by each customer?**  
```SQL
with data AS
(
SELECT s.customer_id, s.order_date, rank() OVER(PARTITION BY s.customer_id Order BY s.order_date) AS rnk,
	s.product_id AS product_id
FROM sales s JOIN menu m
ON s.product_id = m.product_id
ORDER BY s.customer_id
)
SELECT DISTINCT d.customer_id, m.product_name FROM data d
JOIN menu m ON d.product_id = m.product_id
WHERE rnk = 1;
```

First we need to rank the products bought by each customer according to the order_date. we do this using the *rank() over(partition by )* functions. The result is instantiated in a common table expression called 'product rankings'. The final result is a query from this table joined to the menu table, to get the product name information, filtered to where the product rank is *1*, returning the first item purchased by each customer.

customer_id | product_name
----------- | ------------
A           | curry
A           | sushi
B           | curry
C           | ramen


**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**  
```SQL
SELECT m.product_name, COUNT(1) AS total_purchases
FROM sales s JOIN menu m ON
s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(1) DESC
LIMIT 1;
```

Each occurrence of the product ids in the sales table is counted, and the results are ordered by the highest product count. The top result is filtered as the most purchased product.

product_name | total_purchases
------------ | -------------------
ramen        | 8


**5. Which item was the most popular for each customer?**  
```SQL
WITH data AS
(
SELECT s.customer_id, s.product_id, COUNT(1) AS item_quantity, RANK() OVER(PARTITION BY customer_id order by COUNT(1) DESC)
FROM sales s 
GROUP BY s.customer_id, s.product_id
ORDER BY customer_id, COUNT(1) DESC
)
SELECT d.customer_id, m.product_name AS most_popular_product, d.item_quantity 
FROM data d JOIN menu m ON
d.product_id = m.product_id
WHERE rank = 1
ORDER BY d.customer_id;
```
First we need to rank the products bought by each customer according to the number of each product purchased. As with the 3rd question, we use the *rank() over(partition by )* functions. The result is instantiated in a common table expression called 'product_freq'. The final result is a query from this table joined to the menu table, to get the product name information, filtered to where the product rank is *1*, returning the most purchased product by each customer.

customer_id | most_popular_product | item_quantity
----------- | -------------------- | -------------
A           | ramen                | 3
B           | sushi                | 2
B           | curry                | 2
B           | ramen                | 2
C           | ramen                | 3


**6. Which item was purchased first by the customer after they became a member?**  
```SQL
WITH data AS
(
SELECT s.customer_id, m.join_date, s.order_date, s.product_id
FROM sales s JOIN members m ON
s.customer_id = m.customer_id
),
data2 AS
(
SELECT customer_id, MIN(order_date) AS order_date
FROM data 
WHERE order_date >= join_date
GROUP BY customer_id
)
SELECT s.customer_id, m.product_name, d2.order_date
FROM sales s JOIN data2 d2 ON
d2.customer_id =s.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.customer_id = d2.customer_id AND s.order_date = d2.order_date
ORDER BY s.customer_id;
```

Again we employ the use of a CTE to create a subset of data for purchases where customers have signed up to be members. This is determined by selecting records where the orders are made on or after the date a customer became a member. 


customer_id | product_name  | order_date
----------- | ------------  | ----------
A           | curry         | 2021-01-07
B           | sushi         | 2021-01-11


**7. Which item was purchased just before the customer became a member?**  
```SQL
WITH data AS
(
SELECT s.customer_id, m.join_date, s.order_date, s.product_id
FROM sales s JOIN members m ON
s.customer_id = m.customer_id
),
data2 AS
(
SELECT customer_id, order_date , RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnk
FROM data 
WHERE order_date < join_date
)
SELECT  DISTINCT s.customer_id, m.product_name, d2.order_date
FROM sales s JOIN data2 d2 ON
d2.customer_id =s.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.customer_id = d2.customer_id AND s.order_date = d2.order_date AND rnk = 1
ORDER BY s.customer_id

```

Here we create a subset of data for purchases before customers have signed up to be members. This is determined by selecting records where the orders are before the date a customer became a member. 


customer_id | product_name | order_date
----------- | ------------ | ----------
A           | curry        | 2021-01-01
A           | sushi        | 2021-01-01
B           | sushi        | 2021-01-04


**8. What is the total items and amount spent for each member before they became a member?**  
```SQL
WITH data AS
(
SELECT s.customer_id, m.join_date, s.order_date, s.product_id
FROM sales s JOIN members m ON
s.customer_id = m.customer_id
),
data2 AS
(
SELECT d.customer_id, d.order_date, d.product_id, me.price, 
CASE WHEN me.product_name = 'sushi' THEN me.price * 20
	ELSE me.price * 10
	END AS points
from data d JOIN menu me ON d.product_id = me.product_id
WHERE order_date < join_date
)
SELECT customer_id, COUNT(1) AS total_items, SUM(price) AS amount_spent
FROM data2
GROUP BY customer_id
ORDER BY customer_id
```
customer_id | total_items | amount_spent
----------- | ----------- | ------------
A           | 2           | 25
B           | 3           | 40


**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**  
```SQL
WITH data AS
(
SELECT s.customer_id, s.product_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN m.price * 20
ELSE m.price * 10
END AS points
FROM sales s JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id
)
SELECT d.customer_id, SUM(d.points) AS total_points
FROM data d
GROUP BY d.customer_id;
```

A CTE is created to denote points for products purchased using the 'Case' clause. This is then joined to the sales table to generate the final result set grouping sales by customer_id and summing the product points.

customer_id | total_points
----------- | ------------
A           | 860
B           | 940
C           | 360

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**  
```SQL
WITH data AS 
( 
SELECT s.customer_id, m.join_date, s.order_date, s.product_id 
FROM sales s JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < '2021-02-01'
), 
data2 AS 
( 
SELECT d.customer_id, d.order_date, d.product_id, me.price, 
CASE WHEN me.product_name = 'sushi' THEN me.price * 20 
ELSE me.price * 10 END AS points 
from data d JOIN menu me ON d.product_id = me.product_id 
WHERE order_date < join_date 
),
before_joining AS
(
SELECT customer_id, SUM(points) AS points
FROM data2
GROUP BY customer_id
ORDER BY customer_id
),
data3 AS
(
SELECT d.customer_id, d.join_date, d.order_date, (order_date - join_date) AS date_diff, d.product_id, me.price
from data d JOIN menu me ON d.product_id = me.product_id 
WHERE order_date >= join_date 
),
data4 AS
(
SELECT data3.customer_id, 
CASE WHEN data3.date_diff < 7 THEN data3.price * 20
WHEN data3.date_diff >= 7 AND me.product_name = 'sushi' THEN data3.price * 20
	ELSE data3.price * 10
END AS points 
FROM data3 JOIN menu me ON data3.product_id = me.product_id
ORDER BY data3.customer_id
),

after_joining AS
(
select customer_id, sum(points) AS points
	FROM data4
	GROUP BY customer_id
),
final AS
(
SELECT * FROM after_joining
UNION ALL
SELECT * FROM before_joining
)
SELECT customer_id, SUM(points) AS total_points
FROM final
GROUP BY customer_id;

```

A similar CTE is created as in the previous question using the 'Case' clause, which is adjusted to accommodate records where the order date is within a week of the join date, using the dateadd function. We only add 6 days as the join date is accounted for in the first week. The result set is filtered for orders on or before the last day of January. The final result set is then queried from this table.


customer_id | total_points
----------- | ------------
A           | 1370
B           | 820
