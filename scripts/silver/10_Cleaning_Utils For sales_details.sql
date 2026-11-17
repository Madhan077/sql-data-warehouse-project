-- Load & Clean Table 3

SELECT * FROM bronze.crm_sales_details ;

-- 1.Check for Duplicates in Primary Key
-- Expectations : No Result

SELECT
	sls_ord_num ,
	COUNT(*) 
FROM bronze.crm_sales_details 
GROUP BY sls_ord_num
HAVING COUNT(*) > 1
ORDER BY sls_ord_num DESC;

-- Test
SELECT
	*
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY sls_ord_num ORDER BY sls_due_dt DESC) AS flag_last
	FROM bronze.crm_sales_details)T
WHERE sls_ord_num IN ('SO75123');

-- 2.Check For UnWanted Spaces

SELECT
	sls_ord_num 
FROM bronze.crm_sales_details 
WHERE sls_ord_num <> TRIM(sls_ord_num) ;

SELECT
	sls_prd_key 
FROM bronze.crm_sales_details 
WHERE sls_prd_key <> TRIM(sls_prd_key) ;

-- Check For Invalid Dates

SELECT
	NULLIF(sls_order_dt , 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <=  0  
	  OR LEN(sls_order_dt) <> 8
	  OR sls_order_dt > 20500101
	  OR sls_order_dt < 19000101;

SELECT
	NULLIF(sls_ship_dt , 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <=  0  
	  OR LEN(sls_ship_dt) <> 8
	  OR sls_ship_dt > 20500101
	  OR sls_ship_dt < 19000101;

SELECT
	NULLIF(sls_due_dt , 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <=  0  
	  OR LEN(sls_due_dt) <> 8
	  OR sls_due_dt > 20500101
	  OR sls_due_dt < 19000101;

-- Check For Invalid Date Orders
SELECT
	*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt ;

-- Check Data Consistency: Between Sales ,  Quantity , and Price
-- >> Sales = Quantity * Price
-- >> Values Must not be NULL , zero , or negative

SELECT
	sls_sales AS old_sls_sales,
	sls_quantity ,
	sls_price AS old_sls_price,
	CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales <> sls_quantity * ABS(sls_price) 
		 THEN sls_quantity * ABS(sls_price) 
		 ELSE sls_sales
	END AS sls_sales ,
	CASE WHEN sls_price IS NULL OR sls_price <=0 THEN sls_sales / NULLIF(sls_quantity , 0)
		 ELSE sls_price 
	END AS sls_price 
FROM bronze.crm_sales_details 
WHERE sls_sales <> sls_quantity * sls_price 
	  OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	  OR sls_sales <=0 OR sls_quantity <=0  OR sls_price <=0
ORDER BY sls_sales ,sls_quantity,sls_price
