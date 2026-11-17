-- Clean & Load Table 2

SELECT * FROM bronze.crm_prd_info ;

-- 1.Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	prd_id,
	COUNT(*) 
FROM bronze.crm_prd_info 
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Check For Unwanted Spaces
-- Expectations : No Results

SELECT
	prd_key 
FROM bronze.crm_prd_info
WHERE prd_key <> TRIM(prd_key) ;

SELECT
	prd_nm 
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm) ;

-- 3. Check for NULLs or Negative Numbers
-- Expectations: No Results

SELECT 
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL ;

-- 4.Data Standardization & Consistency

SELECT
	DISTINCT prd_line 
FROM bronze.crm_prd_info ;

-- 5.Date Standardize 

SELECT
	*
FROM bronze.crm_prd_info 
WHERE prd_start_dt > prd_end_dt ;

	-- Test
	SELECT
		* ,
		LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt_test
	FROM bronze.crm_prd_info
	WHERE prd_key IN ( 'AC-HE-HL-U509-R' , 'CO-RF-FR-R92R-62') ;
