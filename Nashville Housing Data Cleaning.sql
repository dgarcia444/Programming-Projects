SELECT * FROM nashville_housing;

SELECT
	DISTINCT property_city
FROM nashville_housing
WHERE property_city IS NOT NULL
;

-- Data Cleaning

-- Standardize Sale Date
-- Get rid of the time of the dates in SaleDate

ALTER TABLE nashville_housing
	ALTER COLUMN SaleDate DATE;
GO

UPDATE nashville_housing
SET SaleDate = CONVERT(DATE, SALEDATE)
;

-- Populate Property Address
-- Get rid of all the NULLs in the PropertyAddress column

SELECT *
FROM nashville_housing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID
;

-- ParcelID is tied to property address
-- Look for ParcelIDs with a NULL prop_address and a populated prop_address
-- create a new column, replacing that NULL with the populated prop_address
SELECT 
	a.ParcelID,
	a.PropertyAddress AS property_address_a,
	b.ParcelID,
	b.PropertyAddress AS property_address_b,
	ISNULL(a.PropertyAddress, b.PropertyAddress) AS populated_property_address
FROM nashville_housing a
JOIN nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ] --make sure we get the same ParcelID but with different IDs
WHERE a.PropertyAddress IS NULL	
;

-- filling in the NULL property addresses
-- above query should return nothing after running this
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
;

-- Breaking out the property address into individual columns
-- Property housing has 1 delimiter, a single comma
-- Broken up into street, city

SELECT PropertyAddress
FROM nashville_housing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID
;

SELECT 
	-- grab the string before the delimiter
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS before_delimiter,
	-- grab the substring after the delimiter
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS after_delimiter
FROM nashville_housing
;

-- create two new columns with the values seperated by the comma

ALTER TABLE nashville_housing
ADD property_street_address NVARCHAR(255)
;
UPDATE nashville_housing
SET property_street_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)
;

ALTER TABLE nashville_housing
ADD property_city NVARCHAR(255)
;
UPDATE nashville_housing
SET property_city = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))
;

-- QA
SELECT 
	PropertyAddress,
	property_street_address,
	property_city
FROM nashville_housing
;

-- Break up the owner address
-- the owner address has 2 comma delimiters
-- broken up to street, city, state

SELECT 
	OwnerAddress
FROM nashville_housing
;

-- Using PARSENAME to break up the string
-- Have to replace comma delimeter with a period since PARSENAME looks for periods
SELECT
	PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS address,
	PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS city,
	PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS state
FROM nashville_housing
;

ALTER TABLE nashville_housing
ADD owner_street_address NVARCHAR(255)
;
UPDATE nashville_housing
SET owner_street_address = PARSENAME(REPLACE(OwnerAddress,',','.'),3)
;

ALTER TABLE nashville_housing
ADD owner_city NVARCHAR(255)
;
UPDATE nashville_housing
SET owner_city = PARSENAME(REPLACE(OwnerAddress,',','.'),2)
;

ALTER TABLE nashville_housing
ADD owner_state NVARCHAR(255)
;
UPDATE nashville_housing
SET owner_state = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
;

-- QA 
SELECT
	owner_street_address,
	owner_city,
	owner_state
FROM nashville_housing
;

-- Change Y&N to yes and no in "Sold as Vacant" field

-- See what's originally in SoldAsVacant 
SELECT
	DISTINCT SoldAsVacant,
	COUNT(SoldAsVacant) AS total_amount
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2 DESC
;

SELECT
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant END AS NewSoldAsVacant
FROM nashville_housing
WHERE SoldAsVacant IN ('Y','N')
;

-- Update the table
UPDATE nashville_housing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant END
;

-- Remove Duplicates

SELECT * FROM nashville_housing;

-- return all of the duplicate rows in the dataset
WITH row_num_cte AS (
SELECT
	*,
	ROW_NUMBER() 
	OVER(PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY ParcelID) row_num
FROM nashville_housing)
SELECT * 
FROM row_num_cte
WHERE row_num > 1 
;
-- ORDER BY PropertyAddress

-- delete all duplicates from data
WITH row_num_cte AS (
SELECT
	*,
	ROW_NUMBER() 
	OVER(PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY ParcelID) row_num
FROM nashville_housing
)
DELETE  
FROM row_num_cte
WHERE row_num > 1 
;


-- Remove extra columns
ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, PropertyAddress
;

-- Data Exploration

-- What are the most expensive properties
-- Do we look at sale price or total value??

SELECT * FROM nashville_housing;


-- how many properties are in each area
SELECT
	property_city,
	COUNT(DISTINCT UniqueID) AS total_#_of_properties
FROM nashville_housing
GROUP BY property_city
ORDER BY 2 DESC
;

-- looking at total sales by type of property
SELECT
	LandUse,
	COUNT(DISTINCT UniqueID) AS 'Total Sales',
	ROUND(AVG(SalePrice),2) AS 'Average Price'
FROM nashville_housing
GROUP BY LandUse
ORDER BY 2 DESC,3 DESC
;


-- What are the top 10 most valuable properties
SELECT
	property,
	property_city,
	LandUse,
	TotalValue
FROM (
SELECT
	DISTINCT property_street_address AS property,
	property_city,
	LandUse,
	TotalValue,
	rank() OVER(ORDER BY TotalValue DESC) AS ranks
FROM nashville_housing
WHERE TotalValue IS NOT NULL
) AS highest_valued_properties
WHERE ranks <= 10
ORDER BY 4 DESC
;


-- What are the 10 cheapest properties
SELECT
	property,
	property_city,
	LandUse,
	TotalValue
FROM (
SELECT
	DISTINCT property_street_address AS property,
	property_city,
	LandUse,
	TotalValue,
	rank() OVER(ORDER BY TotalValue) AS ranks
FROM nashville_housing
WHERE TotalValue IS NOT NULL
) AS highest_valued_properties
WHERE ranks <= 10
ORDER BY 4
;

-- Looking at top 10 homes that sold for the highest price
SELECT
	property,
	property_city,
	LandUse,
	SalePrice
FROM (
SELECT
	DISTINCT property_street_address AS property,
	property_city,
	LandUse,
	SalePrice,
	rank() OVER(ORDER BY SalePrice DESC) AS ranks
FROM nashville_housing
WHERE TotalValue IS NOT NULL
) AS highest_valued_properties
WHERE ranks <= 10
ORDER BY 4 DESC
;


-- Looking at Top 10 homes that sold for the lowest price

SELECT
	property,
	property_city,
	LandUse,
	SalePrice
FROM (
SELECT
	DISTINCT property_street_address AS property,
	property_city,
	LandUse,
	SalePrice,
	rank() OVER(ORDER BY SalePrice) AS ranks
FROM nashville_housing
WHERE TotalValue IS NOT NULL
) AS highest_valued_properties
WHERE ranks <= 10
ORDER BY 4 
;



-- Looking at the Average Sales Price and Average Value of a property over time
SELECT
	SaleDate,
	LandUse,
	SalePrice,
	ROUND(AVG(SalePrice) OVER (PARTITION BY LandUse ORDER BY SaleDate),2) AS avg_sale_price
FROM nashville_housing
;

SELECT
	SaleDate,
	LandUse,
	TotalValue,
	ROUND(AVG(TotalValue) OVER (PARTITION BY LandUse ORDER BY SaleDate),2) AS avg_value,
FROM nashville_housing
WHERE TotalValue IS NOT NULL
;

SELECT 
	SalePrice
FROM nashville_housing
WHERE SalePrice IS NULL
;


-- looking at sales by year
SELECT
	DISTINCT YEAR(SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY YEAR(SaleDate)
ORDER BY YEAR(SaleDate)
;


-- looking at the number of sales by month
SELECT
	DISTINCT DATENAME(month,SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY DATENAME(month,SaleDate)
-- ORDER BY MONTH(SaleDate)
;

-- Looking at sales by the day of the month
SELECT
	DISTINCT DAY(SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY DAY(SaleDate)
ORDER BY DAY(SaleDate)
;

-- Looking at rolling count of sales over time

-- subquery
SELECT
	SaleDate,
	LandUse,
	SalePrice,
	ROUND(SUM(SalePrice) OVER (PARTITION BY LandUse ORDER BY SaleDate),2) AS total_sales_revenue
FROM nashville_housing
;

SELECT
	DISTINCT LandUse,
	total_sales_revenue,
	rank() OVER (ORDER BY total_sales_revenue DESC) AS ranked
FROM (
SELECT
	SaleDate,
	LandUse,
	SalePrice,
	SUM(SalePrice) OVER (PARTITION BY LandUse ORDER BY SaleDate) AS total_sales_revenue
FROM nashville_housing
) AS rolling_sales_sum
GROUP BY LandUse, total_sales_revenue
ORDER BY 2 DESC
;

-- Creating views for future visualizations


CREATE VIEW avg_sale AS 
SELECT
	SaleDate,
	LandUse,
	SalePrice,
	ROUND(AVG(SalePrice) OVER (PARTITION BY LandUse ORDER BY SaleDate),2) AS avg_sale_price
FROM nashville_housing
;

CREATE VIEW avg_value AS 
SELECT
	SaleDate,
	LandUse,
	TotalValue,
	ROUND(AVG(TotalValue) OVER (PARTITION BY LandUse ORDER BY SaleDate),2) AS avg_value
FROM nashville_housing
WHERE TotalValue IS NOT NULL
;


CREATE VIEW yearly_sales AS
SELECT
	DISTINCT YEAR(SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY YEAR(SaleDate)
;


CREATE VIEW monthly_sales AS
SELECT
	DISTINCT DATENAME(month,SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY DATENAME(month,SaleDate)
;
;

CREATE VIEW daily_sales AS 
SELECT
	DISTINCT DAY(SaleDate) AS 'Month',
	COUNT(DISTINCT UniqueID) AS total_sales
FROM nashville_housing
GROUP BY DAY(SaleDate)
;

CREATE VIEW total_number_of_sales_by_type AS
SELECT
	LandUse,
	COUNT(DISTINCT UniqueID) AS 'Total Sales'
FROM nashville_housing
GROUP BY LandUse
;

