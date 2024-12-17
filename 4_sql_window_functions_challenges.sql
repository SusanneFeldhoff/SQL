USE Chinook;


-- 1. Rank the customers by total sales

SELECT CustomerId,
	SUM(Total),
	RANK() OVER (Order BY SUM(Total) DESC) AS Total_Sales
    FROM invoice
    GROUP BY CustomerId
    Order by SUM(Total)DESC;

-- 2. Select only the top 10 ranked customer from the previous question

WITH CustomerRanking AS(
	SELECT CustomerId,
		SUM(Total),
		RANK() OVER (Order BY SUM(Total) DESC) AS Total_Sales
		FROM invoice
		GROUP BY CustomerId
		Order by SUM(Total)DESC)
SELECT *
FROM CustomerRanking
WHERE Total_Sales BETWEEN 1 and 10;
    
-- 3. Rank albums based on the total number of tracks sold.

SELECT t.albumid,
	COUNT(il.trackID),
	RANK() OVER (ORDER BY COUNT(il.trackID) DESC) AS Top_Albums
FROM invoiceline as il
JOIN track as t
GROUP BY AlbumId;

-- 4. Do music preferences vary by country? What are the top 3 genres for each country?

WITH Genre_Country AS(
	SELECT c.country,g.name,
		RANK() OVER (PARTITION BY c.country ORDER BY COUNT(il.trackID)) AS Top_Genre
	FROM customer AS c 
	JOIN invoice USING (CustomerId)
	JOIN invoiceline AS il USING(InvoiceId)
	JOIN track USING( trackId) 
	JOIN genre AS g USING(GenreId)
	GROUP BY c.country,g.name)
SELECT *
FROM Genre_Country
WHERE Top_Genre BETWEEN 1 AND 3;

-- 5. In which countries is Blues the least popular genre?

WITH Genre_Country AS(
	SELECT c.country,g.name,
		RANK() OVER (PARTITION BY c.country ORDER BY COUNT(il.trackID)) AS ranking
	FROM customer AS c 
	JOIN invoice USING (CustomerId)
	JOIN invoiceline AS il USING(InvoiceId)
	JOIN track USING  (trackId) 
	JOIN genre AS g USING(GenreId)
	GROUP BY c.country,g.name)
SELECT * 
FROM Genre_Country
WHERE name = "Blues" AND ranking = 1;

-- 6. Has there been year on year growth? By how much have sales increased per year?

SELECT YEAR(InvoiceDate),
	SUM(Total),
	LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate)) AS PreviousYearSales,
    SUM(Total) - LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate)) AS Yearly_difference
From invoice
GROUP BY YEAR(InvoiceDate);

-- 7. How do the sales vary month-to-month as a percentage? 

SELECT 
		MONTH(InvoiceDate) AS Month_,
        YEAR(InvoiceDate) AS Year_,
		SUM(Total) AS SalesPerMonth,
        LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)) AS SalesPreviousMonth,
        Round((SUM(Total)- LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)))/LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)),2) AS MonthlyChange
FROM invoice
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate);
    
-- 8. What is the monthly sales growth, categorised by whether it was an increase or decrease compared to the previous month?

CREATE TEMPORARY TABLE ChangeCategory AS(
	SELECT 
		MONTH(InvoiceDate) AS Month_,
        YEAR(InvoiceDate) AS Year_,
		SUM(Total) AS SalesPerMonth,
        LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)) AS SalesPreviousMonth,
        Round((SUM(Total)- LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)))/LAG(SUM(Total)) OVER (ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)),2) AS MonthlyChange
	FROM invoice
	GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate));
    
SELECT *,
	CASE
		WHEN MonthlyChange > 0 THEN "increase"
		WHEN MonthlyChange < 0 THEN "decrease"
		ELSE "NoChange"
	END AS CategoryChange
FROM ChangeCategory;

-- 9. How many months in the data showed an increase in sales compared to the previous month?

CREATE TEMPORARY TABLE  Categories AS (
	SELECT *,
		CASE
			WHEN MonthlyChange > 0 THEN "increase"
			WHEN MonthlyChange < 0 THEN "decrease"
			ELSE "NoChange"
		END AS CategoryChange
	FROM ChangeCategory);

SELECT COUNT(*)
FROM Categories
WHERE CategoryChange = "increase";


-- 10. As a percentage of all months in the dataset, how many months in the data showed an increase in sales compared to the previous month?

SELECT ROUND( 16/COUNT(DATE_FORMAT(InvoiceDate, "%Y - %m")) * 100,2) AS perc_Month_Increase
FROM invoice;

-- 11. How have purchases of rock music changed quarterly? Show the quarterly change in the amount of tracks sold

CREATE TEMPORARY TABLE Rock_Sales AS(
	SELECT 
		CONCAT(YEAR(InvoiceDate), "-Q", QUARTER(InvoiceDate)) AS Quarter, 
		COUNT(il.TrackId) AS Track_Count, 
		g.Name
	FROM invoice AS i
	JOIN invoiceline AS il USING(InvoiceId)
	JOIN track AS t USING (TrackId)
	JOIN genre AS g USING (GenreId)
    WHERE g.Name = "Rock"
	Group by Quarter);
    
SELECT *,
	LAG(Track_Count) OVER (ORDER BY Track_Count) AS Previous_Quarter_Sales,
    Track_Count - LAG(Track_Count) OVER (ORDER BY Track_Count) AS Difference
FROM Rock_Sales;

-- 12. Determine the average time between purchases for each customer.

WITH Time_Diff AS(
	SELECT InvoiceDate, 
			CustomerId,
			LAG(InvoiceDate) Over( Partition by CustomerId) AS PreviousDate,
			timestampdiff(DAY,LAG(InvoiceDate) Over( Partition by CustomerId),InvoiceDate) AS Difference
			-- RANK()  OVER (PARTITION by CustomerID ORDER BY InvoiceDate)
	FROM invoice
	ORDER BY CustomerId)
SELECT CustomerId, ROUND(AVG(Difference),2) AS Avg_Days_between_purchases
FROM Time_Diff
GROUP BY CustomerId;