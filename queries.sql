-- Q1: What is the average number of films rented per day, 
-- and the average days between rentals for the top 5 renting customers?
-- Solution:
WITH t1 AS (SELECT customer_id,
                   COUNT(*) AS num_of_films_rented,
			       DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS customer_rank
            FROM rental
            GROUP BY 1
            ORDER BY 2 DESC
		    LIMIT 5),
	 t2 AS (SELECT t1.customer_rank,
			       t1.customer_id,
        		   CONCAT(c.last_name, ' ', c.first_name) AS full_name,
			       DATE_TRUNC('day', r.rental_date) AS day,
                   COUNT(*) AS num_of_films_rented_per_day,
			       CAST(DATE_TRUNC('day', rental_date) AS DATE) - CAST(LAG(DATE_TRUNC('day', rental_date)) OVER (PARTITION BY t1.customer_id ORDER BY DATE_TRUNC('day', rental_date)) AS DATE) AS days_between_rentals
            FROM t1
            JOIN rental r
			ON t1.customer_id = r.customer_id
			JOIN customer c
			ON r.customer_id = c.customer_id
            GROUP BY 1, 2, 3, 4)
SELECT customer_rank,
       full_name,
       ROUND(AVG(num_of_films_rented_per_day)) AS avg_num_of_films_rented_per_day,
	   ROUND(AVG(days_between_rentals)) AS avg_days_between_rentals
FROM t2
GROUP BY 1, 2
ORDER BY 1;



-- Q2: What is the most rented film category in (India, China, United States, Japan and Brazil) and how many times they were rented?
-- Solution:

WITH t1 AS (SELECT country,
			       cat.name AS category_name,
	               COUNT(*) AS num_of_rentals
            FROM category cat
            JOIN film_category f_cat
            ON cat.category_id = f_cat.category_id
            JOIN film f
            ON f_cat.film_id = f.film_id
            JOIN inventory i
            ON f.film_id = i.film_id
            JOIN rental r
            ON i.inventory_id = r.inventory_id
			JOIN customer c 
		    ON r.customer_id = c.customer_id
		    JOIN address a
		    ON c.address_id = a.address_id
		    JOIN city 
		    ON a.city_id = city.city_id
		    JOIN country 
		    ON city.country_id = country.country_id
			WHERE country IN ('India', 'China', 'United States', 'Japan', 'Brazil')
            GROUP BY 1, 2),
	 t2 AS (SELECT country,
	               MAX(num_of_rentals) AS max_num_of_rentals
			FROM t1
		    GROUP BY 1)
SELECT t2.country,
       t1.category_name,
	   MAX(num_of_rentals) AS max_num_of_rentals
FROM t1
JOIN t2
ON t1.country = t2.country AND t1.num_of_rentals = t2.max_num_of_rentals
GROUP BY 1, 2
ORDER BY 3 DESC;
		    
-- Q3: What is the most and least profitable films in store 1,And how many times they were rented?
-- Solution:
WITH t1 AS (SELECT f.title,
	               r.rental_id,
	               p.amount,
	               COUNT(*) AS num_of_rentals
            FROM film f
            JOIN inventory i
            ON f.film_id = i.film_id
            JOIN rental r
            ON i.inventory_id = r.inventory_id
            JOIN payment p
            ON r.rental_id = p.rental_id
            WHERE i.store_id = 1
            GROUP BY 1, 2, 3),
    t2 AS  (SELECT t1.title, 
			        SUM(num_of_rentals) AS num_of_rentals
			FROM t1
			GROUP BY 1
			ORDER BY 1),
	t3 AS  (SELECT t1.title,
		           SUM(t1.amount) AS total_earnings
		    FROM t1
		    GROUP BY 1
		    ORDER BY 2 DESC
		    LIMIT 1),
	t4 AS  (SELECT t1.title,
		           SUM(t1.amount) AS total_earnings
		    FROM t1
		    GROUP BY 1
		    ORDER BY 2 
		    LIMIT 1)
SELECT t2.title,
       sub.total_earnings,
	   t2.num_of_rentals
FROM t2
JOIN(SELECT *
	 FROM t3
     UNION
     SELECT *
     FROM t4) AS sub
ON t2.title = sub.title
ORDER BY 2 DESC;


-- Q4: What is the most and least preferred film length by customers?
-- Solution:
WITH t1 AS (SELECT CASE WHEN f.length < 60 THEN 'less than 1 hour'
			            WHEN f.length BETWEEN 60 AND 120 THEN '1 - 2 hours'
			            WHEN f.length BETWEEN 121 AND 180 THEN '2 - 3 hours'
			            ELSE 'more than 3 hours'
			       END AS length_of_film,
			       COUNT(f.length) AS num_of_rentals
            FROM film f
            JOIN inventory i
            ON f.film_id = i.film_id
            JOIN rental r
            ON i.inventory_id = r.inventory_id
			GROUP BY 1)
SELECT *
FROM t1
ORDER BY 2 DESC;


			