-- Identify Out-of-Range Dates

SELECT DISTINCT
	BDATE
FROM bronze.erp_cust_az12
WHERE BDATE < '1924-01-01' OR BDATE > GETDATE();

-- Data Standardization & Consistency

SELECT DISTINCT 
	GEN
FROM bronze.erp_cust_az12 ;


SELECT DISTINCT 
	GEN ,
	CASE WHEN UPPER(TRIM(GEN)) IN ('F' ,'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(GEN)) IN ('M' ,'MALE') THEN 'Male'
		 ELSE 'n/a'
	END AS GEN
FROM bronze.erp_cust_az12 ;