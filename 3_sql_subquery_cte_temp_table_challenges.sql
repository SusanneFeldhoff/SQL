USE chinook;

-- 1. What is the difference in minutes between the total length of 'Rock' tracks and 'Jazz' tracks?

    
WITH Genre_Length AS(
	SELECT 
		SUM(Milliseconds) AS total, 
        g.Name
	FROM genre AS g
	LEFT JOIN track AS t USING(GenreId)
	WHERE g.Name = "Rock" OR g.Name = "Jazz"
	GROUP BY g.Name)
SELECT ABS((SELECT total FROM Genre_Length  WHERE Name = "Rock")/
        (SELECT total FROM Genre_Length WHERE Name = "Jazz")/
        1000/
        60) AS Lengthe_diff;


-- 2. How many tracks have a length greater than the average track length?

SELECT COUNT(TrackId)
FROM track
WHERE Milliseconds > (SELECT AVG(Milliseconds)
					  FROM track);


-- 3. What is the percentage of tracks sold per genre?


SELECT COUNT(il.TrackID)/(SELECT COUNT(TrackId) FROM invoiceline) * 100 AS Perc_Total, g.Name
FROM invoiceline AS il 
LEFT JOIN track AS t USING(TrackId)
LEFT JOIN genre as g USING(GenreId)
GROUP BY g.Name;


-- 4. Can you check that the column of percentages adds up to 100%?

WITH perc_per_genre AS(
	SELECT COUNT(il.TrackID)/(SELECT COUNT(TrackId) FROM invoiceline) * 100 AS Perc_Total, 
			g.Name
	FROM invoiceline AS il 
	LEFT JOIN track AS t USING(TrackId)
	LEFT JOIN genre as g USING(GenreId)
	GROUP BY g.Name)
SELECT SUM(Perc_Total)
FROM perc_per_genre;

-- 5. What is the difference between the highest number of tracks in a genre and the lowest?-- also including unsold ones

WITH titles_genre AS(
	SELECT g.Name, 
			COUNT(TrackId) AS total
	FROM genre AS g
	LEFT JOIN track USING(GenreId)
	GROUP BY g.Name)
SELECT Max(total) - MIN(total)
FROM titles_genre;

-- 6. What is the average value of Chinook customers (total spending)?

SELECT (SELECT SUM(Total) FROM invoice)/(SELECT COUNT(CustomerId) FROM customer);

-- 7. How many complete albums were sold? Not just tracks from an album, but the whole album bought on one invoice.


-- 8. What is the maximum spent by a customer in each genre?


-- 9. What percentage of customers who made a purchase in 2022 returned to make additional purchases in subsequent years?
    

-- 10. Which genre is each employee most successful at selling? Most successful is greatest amount of tracks sold.

WITH employee_genre AS(
	SELECT SUM(il.TrackId) AS sold, 
			SupportRepId AS employee, 
            g.Name AS Genre
	FROM customer
	JOIN invoice AS i USING(CustomerId)
	JOIN invoiceline AS il USING(InvoiceId)
	JOIN track AS t USING(trackId)
	JOIN genre AS g USING(GenreId)
	GROUP BY employee, Genre)
SELECT MAX(sold),employee, genre 
FROM employee_genre
GROUP BY employee, genre;

SELECT SUM(il.TrackId) AS sold, 
			SupportRepId AS employee, 
            g.Name AS Genre
	FROM customer
	JOIN invoice AS i USING(CustomerId)
	JOIN invoiceline AS il USING(InvoiceId)
	JOIN track AS t USING(trackId)
	JOIN genre AS g USING(GenreId)
	GROUP BY employee, Genre;
    
-- 11. How many customers made a second purchase the month after their first purchase?

