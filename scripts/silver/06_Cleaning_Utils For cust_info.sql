-- Clean & Load Table 1

-- 1.Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT 
cst_id ,
COUNT(*)
FROM bronze.crm_cus_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check For Unwanted Spaces
-- Expectations : No Results

SELECT
	cst_key 
FROM bronze.crm_cus_info
WHERE cst_key <> TRIM(cst_key) ;

SELECT
	cst_firstname 
FROM bronze.crm_cus_info
WHERE cst_firstname <> TRIM(cst_firstname) ;

SELECT
	cst_lastname 
FROM bronze.crm_cus_info
WHERE cst_lastname <> TRIM(cst_lastname) ;

SELECT
	cst_marital_status 
FROM bronze.crm_cus_info
WHERE cst_marital_status <> TRIM(cst_marital_status) ;

SELECT
	cst_gndr 
FROM bronze.crm_cus_info
WHERE cst_gndr <> TRIM(cst_gndr) ;

-- Data Standardization & Consistency

SELECT
	DISTINCT cst_gndr 
FROM bronze.crm_cus_info ; 

SELECT
	DISTINCT cst_marital_status 
FROM bronze.crm_cus_info ;