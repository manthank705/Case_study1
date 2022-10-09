--1--
SELECT s.customer_id, sum(m.price) AS total_sales
FROM sales s JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


--2--
SELECT s.customer_id, COUNT(DISTINCT s.order_date) as total_visits
FROM sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;


--3--
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

--4--
SELECT m.product_name, COUNT(1) AS total_purchases
FROM sales s JOIN menu m ON
s.product_id = m.product_id
GROUP BY M.product_name
ORDER BY COUNT(1) DESC
LIMIT 1;



--5--
WITH data AS
(
SELECT s.customer_id, s.product_id, COUNT(1) AS item_quantity, RANK() OVER(PARTITION BY customer_id order by COUNT(1) DESC)
FROM sales s 
GROUP BY s.customer_id, s.product_id
ORDER BY customer_id, COUNT(1) DESC
)
SELECT d.customer_id, m.product_name, d.item_quantity 
FROM data d JOIN menu m ON
d.product_id = m.product_id
WHERE rank = 1
ORDER BY d.customer_id;

--6--
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
SELECT s.customer_id, d2.order_date, m.product_name
FROM sales s JOIN data2 d2 ON
d2.customer_id =s.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.customer_id = d2.customer_id AND s.order_date = d2.order_date
ORDER BY s.customer_id

--7--

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
SELECT  DISTINCT s.customer_id, d2.order_date, m.product_name
FROM sales s JOIN data2 d2 ON
d2.customer_id =s.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.customer_id = d2.customer_id AND s.order_date = d2.order_date AND rnk = 1
ORDER BY s.customer_id

--8--
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
SELECT customer_id, count(1) AS , SUM(price) AS total
FROM data2
GROUP BY customer_id
ORDER BY customer_id




--9--
WITH data AS
(
SELECT s.customer_id, s.product_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN m.price * 20
ELSE m.price * 10
END AS points
FROM sales s JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id
)
SELECT d.customer_id, SUM(d.points) AS points
FROM data d
GROUP BY d.customer_id;



--10--
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
SELECT customer_id, SUM(points) AS points
FROM final
GROUP BY customer_id;


--11--
WITH data AS
(
SELECT s.customer_id, ms.join_date, s.order_date, m.product_name, m.price
FROM sales s LEFT JOIN members ms ON
s.customer_id = ms.customer_id
JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, order_date, product_name, price, 
CASE WHEN join_date = NULL THEN 'N'
WHEN order_date >= join_date THEN 'Y'
ELSE 'N'
END as member
FROM data
ORDER BY customer_id, order_date;


--12--

WITH data AS
(
SELECT s.customer_id, ms.join_date, s.order_date, m.product_name, m.price
FROM sales s LEFT JOIN members ms ON
s.customer_id = ms.customer_id
JOIN menu m ON s.product_id = m.product_id
),
data2 AS
(
SELECT customer_id, order_date, product_name, price, 
CASE WHEN join_date = NULL THEN 'N'
WHEN order_date >= join_date THEN 'Y'
ELSE 'N'
END as member
FROM data
ORDER BY customer_id, order_date
)
SELECT *, 
CASE WHEN member = 'N' THEN null 
ELSE 
DENSE_RANK()
OVER(PARTITION BY customer_id, member
	ORDER BY order_date) END AS ranking
FROM data2
ORDER BY customer_id, order_date;