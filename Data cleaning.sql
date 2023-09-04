
/*
Cleaning Data in SQL querries 
*/


---------------------------------------------------------------------------------------------------
-- stabndardise Date Format

select *
from cleaning 

select SaleDate, convert (date,SaleDate)
from cleaning

update cleaning 
set SaleDate = convert(Date,SaleDate)

-- it didnt convert so we alter the table to add a new column 
 

Alter Table cleaning 
Add SaleDateConverted Date

update cleaning 
set SaleDateConverted = convert (Date,SaleDate)

---------------------------------------------------------------------------------------------------
--populate Property Address data


Select *
from cleaning 
--where propertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress,  b.ParcelID, b.PropertyAddress, isnull(a.propertyAddress, b.PropertyAddress)
from cleaning a
join cleaning b
 on a.ParcelID = b.ParcelID
 And a.[UniqueID ]<> b.[UniqueID ]
 where a.propertyAddress is null
 order by a.ParcelID

 Update a 
 set propertyAddress = isnull(a.propertyAddress, b.PropertyAddress)
 from cleaning a
join cleaning b
 on a.ParcelID = b.ParcelID
 And a.[UniqueID ]<> b.[UniqueID ]
 where a.propertyAddress is null


 ---------------------------------------------------------------------------------------------------
--Breaking out PropertyAddress into Individual columns ( Address, City, State)

select *
from cleaning 
--where propertyaddress is null
--order by ParcelID

-- starting at a very first value in propertyaddress and then look for the comma 

select 
substring(PropertyAddress, 1, charindex(',', PropertyAddress)-1) as Address
, substring(PropertyAddress, charindex(',', PropertyAddress)+1, Len(propertyAddress)) as City 
from cleaning 

Alter Table cleaning 
Add PropertySplitAddress Nvarchar(255)

update cleaning 
Set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress)-1)


Alter Table cleaning 
Add PropertySplitCity Nvarchar(255)

update cleaning 
Set PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress)+1, Len(propertyAddress))


 ---------------------------------------------------------------------------------------------------
----Breaking out OwnerAddress into Individual columns ( Address, City, State)

select *
from cleaning


select
Parsename(replace(OwnerAddress,',', '.' ),3),
Parsename(replace(OwnerAddress,',','.'),2),
Parsename(replace(OwnerAddress,',','.'),1)
from cleaning


Alter Table cleaning 
Add OwnerSplitAddress Nvarchar(255)

update cleaning 
set OwnerSplitAddress = Parsename(replace(OwnerAddress,',', '.' ),3)

Alter Table cleaning 
Add OwnerSplitCity Nvarchar(255)

update cleaning 
set OwnerSplitCity = Parsename(replace(OwnerAddress,',', '.' ),2)

Alter Table cleaning 
Add OwnerSplitState Nvarchar(255)

update cleaning 
set OwnerSplitState = Parsename(replace(OwnerAddress,',', '.' ),1)



 ---------------------------------------------------------------------------------------------------
--Change Y and N to Yes and No in "sold as Vacant" field

select distinct (soldAsvacant), count(soldAsvacant)
from cleaning 
group by soldasvacant



update cleaning 
set SoldAsVacant = 
CASE 
    when soldAsvacant = 'Y' then 'Yes'
	when soldAsvacant = 'N' then 'No'
	Else SoldAsvacant
	End

 ---------------------------------------------------------------------------------------------------
--Remove Duplicates

with RowNumCTE as (
select *,
	row_number() over (
	partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by uniqueID ) row_num
from cleaning 
)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress

-- now remove them 
with RowNumCTE as (
select *,
	row_number() over (
	partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by uniqueID ) row_num
from cleaning 
)
Delete
from RowNumCTE
where row_num >1
--order by PropertyAddress

---------------------------------------------------------------------------------------------------
--Delete Unused Columns


select *
from Cleaning

alter table cleaning
drop column owneraddress, taxdistrict, propertyaddress

alter table cleaning
drop column saleDate








