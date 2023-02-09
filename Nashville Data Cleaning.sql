/*
Nashville Housing Data Cleaning
*/

SELECT*
FROM Portfolio.dbo.Nashville

--------------------------------------------------------------------------------------------------------------------------
/*Standardize Date Format*/
UPDATE Portfolio.dbo.Nashville
SET SaleDate = CONVERT(Date,SaleDate)

 --------------------------------------------------------------------------------------------------------------------------
/*Populate Property Address data*/
SELECT UniqueID, ParcelID, PropertyAddress
FROM Portfolio.dbo.Nashville
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

--ParcelID can be use to identify LandUse and PropertyAdress, 
--Null PropertyAdress value can be filled with same parcelID from different rows 
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolio.dbo.Nashville AS a
INNER JOIN Portfolio.dbo.Nashville AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolio.dbo.Nashville AS a
INNER JOIN Portfolio.dbo.Nashville b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Crosscheck again
SELECT PropertyAddress
FROM Portfolio.dbo.Nashville
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

--------------------------------------------------------------------------------------------------------------------------
/* Breaking out Address into Individual Columns (Address, City, State) */
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)  as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as City
From Portfolio.dbo.Nashville;

ALTER TABLE Portfolio.dbo.Nashville
Add PropertyCity Nvarchar(255);

UPDATE Portfolio.dbo.Nashville
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));

Update Portfolio.dbo.Nashville
SET PropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );

--Crosscheck
SELECT PropertyAddress, PropertyCity
FROM Portfolio.dbo.Nashville;

-- Go to OwnerAdress
Select OwnerAddress
From Portfolio.dbo.Nashville;


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Portfolio.dbo.Nashville;

ALTER TABLE Portfolio.dbo.Nashville
ADD OwnerCity Nvarchar(255);

UPDATE Portfolio.dbo.Nashville
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

ALTER TABLE Portfolio.dbo.Nashville
ADD OwnerState Nvarchar(255);

UPDATE Portfolio.dbo.Nashville
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

UPDATE Portfolio.dbo.Nashville
SET OwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

-- Crosscheck
SELECT OwnerAddress, OwnerCity, OwnerState, SoldAsVacant
FROM Portfolio.dbo.Nashville;
--------------------------------------------------------------------------------------------------------------------------
/*Change 1 and 0 to Yes and No in "Sold as Vacant" field*/
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM Portfolio.dbo.Nashville
Group by SoldAsVacant
order by 2;

ALTER TABLE Portfolio.dbo.Nashville
ALTER COLUMN SoldAsVacant NVARCHAR(3)

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = '1' THEN 'Yes'
	   WHEN SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
END
FROM Portfolio.dbo.Nashville;

UPDATE Portfolio.dbo.Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = '1' THEN 'Yes'
	   WHEN SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Portfolio.dbo.Nashville;

-- Crosscheck
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Portfolio.dbo.Nashville
Group by SoldAsVacant
order by 2;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
/*Remove Duplicates*/
WITH RowNumCTE AS(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
	FROM Portfolio.dbo.Nashville)
SELECT *
From RowNumCTE
Where row_num > 1
ORDER by PropertyAddress;

WITH RowNumCTE AS(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
	FROM Portfolio.dbo.Nashville)
DELETE
FROM RowNumCTE
Where row_num > 1;

-- Crosscheck
SELECT *
FROM Portfolio.dbo.Nashville;
---------------------------------------------------------------------------------------------------------