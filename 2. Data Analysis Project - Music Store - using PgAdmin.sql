
--------------- PROJECT DATA ANALYSIS - MUSIC STORE ----------------------------------------------------

/*   Skills used -	STANDARD SQL QUERY, SUB-QUERY, JOIN, CTE, WINDOWS FUNCTIONS , RECURSVIE  */

USE Music_Store;

---------------------------- QUERY SET 1 :- BASIC ------------------------------------------------------

-- 1. Who is the senior most employee based on job title?

SELECT * 
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- 2. Which countries have the most invoices?

SELECT billing_country, COUNT(invoice_id) AS Total_Bill_per_Country
FROM invoice
GROUP BY billing_country
ORDER BY Total_Bill_per_Country DESC


-- 3. What are the top 3 values of billing invoices?

SELECT invoice_id, total
FROM invoice
--GROUP BY billing_country
ORDER BY total DESC
LIMIT 5;


--4. Which city has the best customers? We would like to throw a promotional Music Festival in the city 
--   we made the most money. Write a query that returns one city that has the highest sum of invoice totals.
--   Return both the city name & sum of all invoice totals?

SELECT billing_city, SUM(total) AS total_invoices
FROM invoice
GROUP BY billing_city
ORDER BY total_invoices DESC
--LIMIT 5


-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--    Write a query that returns the person who has spent the most money.

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_invoice
FROM customer c 
     JOIN invoice i
	 on c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY total_invoice DESC
LIMIT 5;



----------------------------------- QUERY SET 2 :- MODERATE ------------------------------------------

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--    Return your list ordered alphabetically by email starting with A.

SELECT DISTINCT c.email, c.first_name, c.last_name, g.name
FROM customer c
    JOIN invoice i
	  ON c.customer_id = i.customer_id
	JOIN invoice_line il
	  ON i.invoice_id = il.invoice_id
	JOIN track t
	  ON il.track_id = t.track_id
	JOIN genre g
	  ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY c.email;
	  
--OPTIMIZED QUERY IS --This but it will all column except genre column.
SELECT DISTINCT c.email, c.first_name, c.last_name
FROM customer c
    JOIN invoice i
	  ON c.customer_id = i.customer_id
	JOIN invoice_line il
	  ON i.invoice_id = il.invoice_id
WHERE track_id IN (
	               SELECT track_id
	               FROM track t
			           JOIN genre g
	                     ON t.genre_id = g.genre_id
                   WHERE g.name LIKE 'Rock'
	               )
ORDER BY c.email;

-- SUBQUERY --
SELECT track_id
FROM track t
    JOIN genre g
      ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock';


-- 2. Let's invite the artists who have written the most rock music in our dataset. Write a query that 
--    returns the Artist name and total track count of the top 10 rock bands.

SELECT ar.artist_id, ar.name AS artist_name, COUNT(ar.artist_id) AS Number_of_Songs
FROM artist ar
    JOIN album al
	  ON ar.artist_id = al.artist_id
	JOIN track t
	  ON al.album_id = t.album_id
    JOIN genre g
	  ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY ar.artist_id
ORDER BY Number_of_Songs DESC
LIMIT 10;


-- 3. Return all the track names that have a song length longer than the average song length. 
--    Return the Name and Milliseconds for each track. 
--    Order by the song length with the longest songs listed first.

SELECT name AS track_name, milliseconds --SUM(milliseconds)/COUNT(milliseconds)
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds)
	FROM track
	)
ORDER BY milliseconds DESC;

-- MAX Length = 5,286,953
-- AVERAGE    =   393,599
-- MIN length =   393,691
-- MIN length =     1,071




----------------------------------- QUERY SET 4 :- ADVANCE --------------------------------------------


-- 1. Find how much amount spent by each customer on artists? 
--    Write a query to return customer name, artist name and total spent.

-- ENQUERY QUERY --
SELECT ar.name AS artist_name , SUM(il.unit_price*il.quantity) AS total_sales --SUM(i.total) AS total_spent
FROM invoice_line il
	JOIN track t
	  ON t.track_id = il.track_id
	JOIN album al
	  ON al.album_id = t.album_id
	JOIN artist ar
	  ON ar.artist_id = al.artist_id
GROUP BY ar.name
ORDER BY 2 DESC
LIMIT 1;

-- MAIN QUREY --

WITH best_selling_artist AS (
	SELECT ar.artist_id AS artist_id, ar.name AS artist_name, SUM(il.unit_price*il.quantity) AS total_sales
	FROM invoice_line il
	    JOIN track t
	      ON t.track_id = il.track_id
	    JOIN album al
	      ON al.album_id = t.album_id
	    JOIN artist ar
	      ON ar.artist_id = al.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
	)

SELECT c.customer_id, c.first_name AS customer_first_name, c.last_name AS customer_last_name, bsa.artist_name AS artist_name, 
       SUM(il.unit_price*il.quantity) AS total_spent
FROM invoice i
    JOIN customer c
	  ON i.customer_id = c.customer_id
	JOIN invoice_line il
	  ON il.invoice_id = i.invoice_id
	JOIN track t
	  ON t.track_id = il.track_id
	JOIN album al
	  ON al.album_id = t.album_id
	JOIN best_selling_artist bsa
	  ON bsa.artist_id = al.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;
	

-- 2. We want to find out the most popular music Genre for each country.
--    We determine the most popular genre as the genre with the highest amount of purchases. 
--    Write a query that returns each country along with the top Genre. 
--    For countries where the maximum number of purchases is shared return all Genres.

	-- METHOD - 1
WITH popular_genre AS (
	SELECT COUNT(il.quantity) AS purchases, c.country, g.genre_id, g.name, 
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS Row_No
	FROM invoice_line il
	    JOIN invoice i
	      ON i.invoice_id = il.invoice_id
        JOIN customer c
	      ON c.customer_id = i.customer_id
        JOIN track t
	      ON t.track_id = il.track_id	    
	    JOIN genre g
	      ON g.genre_id = t.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
	)
	
SELECT country, purchases, genre_id, name
FROM popular_genre
WHERE Row_No <= 1;

	-- METHOD - 2

WITH RECURSIVE
   sales_per_country AS (
              SELECT COUNT(*) AS purchases_per_genre, c.country, g.genre_id, g.name
              FROM invoice_line il
                  JOIN invoice i
	                ON i.invoice_id = il.invoice_id
                  JOIN customer c
	                ON c.customer_id = i.customer_id
                  JOIN track t
	                ON t.track_id = il.track_id
	              JOIN genre g
	                ON g.genre_id = t.genre_id
	          GROUP BY 2,3,4
	          ORDER BY 2
   ),
   max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_gerne_number, country
       FROM sales_per_country
	   GROUP BY 2
	   ORDER BY 2)

SELECT sales_per_country.*
FROM sales_per_country
    JOIN max_genre_per_country
	  ON sales_per_country.country = max_genre_per_country.max_genre
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number


-- 3. Write a query that determines the customer that has spent the most on music for each country.
--    Write a query that returns the country along with the top customer and how much they spent
--    for countries where the top amount spent is shared, provide all customers who spent this amount.

	-- METHOD - 1
WITH RECURSIVE
    customer_with_country AS (
		SELECT c.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
		FROM invoice i
		JOIN customer c
		  ON c.customer_id = i.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
		
    country_max_spending AS (
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)
		
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending cs
  ON cc.billing_country = cs.billing_country
WHERE cc.total_spending = cS.max_spending
ORDER BY 1;

	-- METHOD - 2
WITH customer_with_country AS (
		SELECT c.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
	           ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS Row_No
		FROM invoice i
		JOIN customer c
		  ON c.customer_id = i.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 5 DESC)
		
SELECT *
FROM customer_with_country
WHERE Row_No <= 1;


------------------------------------------ END ----------------------------------------------------------
