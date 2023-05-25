--CREATE TABLE
CREATE TABLE nashville_housing (
	UniqueID VARCHAR(50) PRIMARY KEY,
	ParcelID VARCHAR(50),
	LandUse VARCHAR(50),
	PropertyAddress VARCHAR(255),
	SaleDate DATE,
	SalePrice VARCHAR(50),
	LegalReference VARCHAR(50),
	SoldAsVacant BOOLEAN,
	OwnerName VARCHAR(255),
	OwnerAddress VARCHAR(255),
	Acreage REAL,
	TaxDistrict VARCHAR(255),
	LandValue INTEGER,
	BuildingValue INTEGER,
	TotalValue INTEGER,
	YearBuilt INTEGER,
	Bedrooms INTEGER,
	FullBath INTEGER,
	HalfBath INTEGER
);


--Null values in propertyaddress
SELECT *
FROM nashville_housing
WHERE propertyaddress IS NULL;

SELECT 
	nashville_a.parcelid,
	nashville_a.propertyaddress,
	nashville_b.parcelid,
	nashville_b.propertyaddress,
	COALESCE(nashville_a.propertyaddress,nashville_b.propertyaddress) AS correct_address
FROM nashville_housing as nashville_a
JOIN nashville_housing AS nashville_b
	ON nashville_a.parcelid = nashville_b.parcelid
	AND nashville_a.uniqueid != nashville_b.uniqueid
WHERE nashville_a.propertyaddress IS NULL;

UPDATE nashville_housing
SET propertyaddress = nashville_b.propertyaddress
FROM nashville_housing AS nashville_b
WHERE nashville_housing.uniqueid != nashville_b.uniqueid
	AND nashville_housing.parcelid = nashville_b.parcelid
	AND nashville_housing.propertyaddress IS NULL;

--Separate propertyaddress into address, city
SELECT propertyaddress,
SPLIT_PART(propertyaddress, ',', 1) AS address,
SPLIT_PART(propertyaddress, ',', 2) AS city
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD COLUMN property_split_add VARCHAR(255),
ADD COLUMN property_split_city VARCHAR(100);

UPDATE nashville_housing
SET property_split_add = SPLIT_PART(propertyaddress, ',', 1);

UPDATE nashville_housing
SET property_split_city = SPLIT_PART(propertyaddress, ',', 2);

--Separate owner address into address, city, state
SELECT owneraddress,
SPLIT_PART(owneraddress, ',', 1) AS address,
SPLIT_PART(owneraddress, ',', 2) AS city,
SPLIT_PART(owneraddress, ',', 3) AS state
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD COLUMN owner_split_add VARCHAR(255),
ADD COLUMN owner_split_city VARCHAR(100),
ADD COLUMN owner_split_state VARCHAR(100);

UPDATE nashville_housing
SET owner_split_add = SPLIT_PART(owneraddress, ',', 1);

UPDATE nashville_housing
SET owner_split_city = SPLIT_PART(owneraddress, ',', 2);

UPDATE nashville_housing
SET owner_split_state = SPLIT_PART(owneraddress, ',', 3);


--Remove duplicates
WITH house_cte AS (
	SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY parcelid,
					 propertyaddress,
					 saleprice,
					 saledate,
					 legalreference
					 ORDER BY uniqueid
					 ) AS row_num
	FROM nashville_housing
)
DELETE
FROM nashville_housing
USING house_cte
WHERE house_cte.row_num > 1
AND nashville_housing.uniqueid = house_cte.uniqueid

SELECT fullbath, COUNT(*) AS num FROM nashville_housing
GROUP BY fullbath
ORDER BY num
