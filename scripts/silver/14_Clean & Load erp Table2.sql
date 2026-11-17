-- Clean & Load Table erp_loc_a101 

INSERT INTO silver.erp_loc_a101 (
	CID ,
	CNTRY 
	)
SELECT 
	REPLACE(CID , '-' ,'') AS CID,
	CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
		 WHEN TRIM(CNTRY) IN ('US' , 'USA') THEN 'United States'
		 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
		 ELSE TRIM(CNTRY)
	END AS CNTRY
FROM bronze.erp_loc_a101 ;

-- Data Standardization & Consistency

SELECT DISTINCT 
	CNTRY
FROM  bronze.erp_loc_a101; 

SELECT * FROM  silver.erp_loc_a101 ;