USE Chinook;

-- 1. Create a view help your colleagues see which countries have the most invoices

CREATE VIEW invoicesPerCountry AS
SELECT BillingCountry, SUM(InvoiceID) AS totalInvoices
FROM invoice
GROUP BY BillingCountry
ORDER BY SUM(InvoiceId) DESC;

SELECT * 
FROM invoicesPerCountry;

-- 2. Create a view help your colleagues see which cities have the most valuable customer base

CREATE VIEW MVCustomer AS
SELECT BillingCity, SUM(Total) AS Total
FROM invoice
GROUP BY BillingCity
ORDER BY SUM(Total) DESC;

SELECT * 
FROM MVCustomer;

-- 3. Create a view to identify the top spending customer in each country. Order the results from highest spent to lowest.

CREATE VIEW MVCustomerPerCountry AS
SELECT BillingCountry,CustomerID, MAX(Total) AS Total
FROM invoice
GROUP BY BillingCountry,CustomerID;

SELECT * 
FROM MVCustomerPerCountry;

-- 4. Create a view to show the top 5 selling artists of the top selling genre
-- If there are multiple genres that all sell well, give the top 5 of all top selling genres collectively

CREATE VIEW TopArtistInTopGenre AS
WITH TopGenre AS(
	SELECT g.name AS Genre, 
			COUNT(il.TrackId) AS AmountSold,
			rank() OVER (ORDER BY COUNT(il.TrackId) DESC) AS RankGenre
	FROM genre as g
	JOIN track USING(GenreId)
	JOIN invoiceline AS il USING(TrackId)
	GROUP BY g.name)
,
TopArtist AS(
	SELECT	g.name AS Genre,
				a.Name AS Artist,
				COUNT(il.TrackId) AS AmountSold,
				RANK() OVER (ORDER BY COUNT(il.TrackId) DESC) AS RankArtist
		FROM genre as g
		JOIN track USING(GenreId)
		JOIN invoiceline AS il USING(TrackId)
		JOIN Album USING(AlbumId)
		JOIN Artist AS a USING(ArtistId)
		WHERE  g.name = (SELECT Genre
							FROM TopGenre
                            WHERE RankGenre = 1)
		GROUP BY Genre, Artist)
SELECT *
FROM TopArtist
WHERE RankArtist <=5;

SELECT *
FROM TopArtistInTopGenre;


-------------------------------------------------------------------------------------------------------------------------------------- 
**************************************************************************************************************************************

-- 5. Create a stored procedure that, when provided with an InvoiceId, 
-- retrieves all orders and corresponding order items acquired by the customer who placed the specified order

DELIMITER $$

CREATE PROCEDURE InvoiceDetails (IN InputInvoiceId INT)

BEGIN
    SELECT 
        il.InvoiceLineId, 
        i.CustomerId,
        il.TrackId
    FROM invoice AS i
		JOIN invoiceline AS il USING (InvoiceId)
    WHERE i.InvoiceId = InputInvoiceId;
END $$

DELIMITER ;

CALL InvoiceDetails (10);

    
-- 6. Create a stored procedure to retrieve sales data from a given date range

DELIMITER $$

CREATE PROCEDURE SalesTimeRange (StartingDate DATETIME, EndingDate DATETIME)

BEGIN
	SELECT *
    FROM invoice
    WHERE InvoiceDate BETWEEN StartingDate AND EndingDate;
END $$

----------------------------------------------------------------------------------------------------------------------
**********************************************************************************************************************

-- 7. Create a stored function to calculate the average invoice amount for a given country

DELIMITER $$
DROP FUNCTION AverageInvoice$$

CREATE FUNCTION AverageInvoiceCountry(InputCountry VARCHAR(40))
RETURNS DECIMAL(10,2)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
    DECLARE AverageInvoice DECIMAL(10,2);
    
    SELECT AVG(Total) INTO AverageInvoice
    FROM invoice 
    WHERE BillingCountry = InputCountry;
    
    RETURN AverageInvoice;
END $$


DELIMITER ;

SELECT AverageInvoiceCountry("Germany");

-- 8. Create a stored function that returns the best-selling artist in a specified genre

DELIMITER $$

DROP FUNCTION BestSellingArtist$$
CREATE FUNCTION BestSellingArtist(InputGenreName VARCHAR(122))
RETURNS VARCHAR(120)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE BestSellingArtist VARCHAR(120);
   
    WITH TopArtist AS ( 
		SELECT a.Name AS artist, 
				COUNT(il.TrackId) AS TotalSales,
				RANK () OVER (ORDER BY COUNT(il.TrackId) DESC) AS ranking
		FROM genre AS g
			JOIN track AS t USING(GenreId)
			JOIN invoiceline AS il USING(TrackId)
			JOIN album USING(AlbumId)
			JOIN artist AS a USING(ArtistId)
		WHERE g.Name = InputGenreName
		GROUP By artist
		ORDER BY TotalSales)
        
	SELECT artist INTO BestSellingArtist
    FROM TopArtist
    WHERE ranking = 1;
    
    RETURN BestSellingArtist;
END$$
    
DELIMITER ;

SELECT BestSellingArtist ("Rock");
    

-- 9. Create a stored function to calculate the total amount that customer spent with the company

DELIMITER $$

CREATE FUNCTION TotalSpent(InputCumstomerId INT)
RETURNS DECIMAL(10,2)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE TotalSpent DECIMAL(10,2);
    
    SELECT SUM(Total) INTO TotalSpent
    FROM invoice
    WHERE CustomerId = InputCumstomerId;
    
    RETURN TotalSpent;
END $$

DELIMITER ;

SELECT TotalSpent(10);


-- 10. Create a stored function to find the average song length for an album

DELIMITER $$

CREATE FUNCTION AvgLength(InputAlbumId INT)
RETURNs DECIMAL(10,2)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE AvgLength DECIMAL(10,2);
    
	SELECT AVG(t.Milliseconds) INTO  AvgLength
	FROM album AS a
	JOIN track AS t USING (AlbumId)
	WHERE AlbumId = InputAlbumId;
    
    RETURN AvgLength;
END $$

DELIMITER ;

SELECT AvgLength(10);

-- 11. Create a stored function to return the most popular genre for a given country

DELIMITER $$

CREATE FUNCTION TopGenreInCountry(InputCountry VARCHAR(120))
RETURNS VARCHAR(120)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE TopGenre VARCHAR(120);
    
	WITH TopGenreCTE AS(
		SELECT COUNT(il.TrackID), g.Name AS GenreName
		FROM invoice AS i
		JOIN invoiceline AS il USING(InvoiceId)
		
        JOIN track AS t USING(TrackId)
		JOIN genre AS g USING(GenreId)
		WHERE BillingCountry = InputCountry
		Group By g.Name
		LIMIT 1)
	SELECT GenreName INTO TopGenre
    FROM TopGenreCTE;
	RETURN TopGenre;
END$$

DELIMITER ;

SELECT TopGenreInCountry("Germany");
