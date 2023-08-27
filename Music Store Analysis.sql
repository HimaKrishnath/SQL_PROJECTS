
select * from employee;
/* Question set
who is the senior most employee based on job title*/
select first_name, last_name, title, 2023-extract( year from hire_date) as Years_of_service from employee
order by hire_date, last_name;

/* Country with most invoices*/

select * from invoice;
select count(*) as Number_of_invoices,billing_country from invoice 
group by billing_country
order by Number_of_invoices desc;

/* What are top 3 values of total invoice*/
select  floor(total)as Top_3 from invoice
order by total desc limit 3;


/* which city has the best customers? To throw a music festical based on total invoices a city makes */
select billing_city, floor(sum(total)) as t from invoice 
group by billing_city
order by t  desc limit 3;

/* Best customer , person who spent more money*/
select * from customer;
select c.customer_id, c.first_name, c.last_name, sum(i.total) as Total_Purchase from customer c 
join invoice i using(customer_id)
group by c.customer_id
order by Total_Purchase  desc;

select * from genre;

/* Return email,firstname,last name and genre of the all music listeners*/
select c.email, c.first_name, c.last_name  from customer c
join invoice n using(customer_id)
join invoice_line i using (invoice_id)
join track t using (track_id)
join genre g using (genre_id)
where g.name='Rock'
order by c.email;

select c.email, c.first_name, c.last_name  from customer c
join invoice n using(customer_id)
join invoice_line i using (invoice_id)
where track_id in (
select track_id from track t 
join genre g using (genre_id)
where g.name='Rock' ) 
order by c.email;


/*invite an artist who has the most rock songs and give the top 10 rock bands */
select * from track;
select a.name, count(*)as c  from artist a
join  album l using(artist_id)
join track t using (album_id)
join genre g using (genre_id)
where g.name like 'Rock'
group by  a.name
order by c  desc limit 10 ;



/* Return all the track names having song length longer than an avgerage song length return all the songs name and milliseconds of each track */


select name, milliseconds  from track
where  milliseconds > 
(
select avg(milliseconds) as avg_track from track
)
order by milliseconds desc;




/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */	

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */


/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;



