-- Clean & Load Table erp_px_cat_g1v2

INSERT INTO silver.erp_px_cat_g1v2 (
	ID ,
	CAT ,
	SUBCAT ,
	MAINTENANCE
	)
SELECT 
	ID ,
	CAT ,
	SUBCAT ,
	MAINTENANCE
FROM bronze.erp_px_cat_g1v2 ; 


-- Check For Unwanted Spaces

SELECT
	CAT 
FROM bronze.erp_px_cat_g1v2 
WHERE CAT <> TRIM(CAT) ;

SELECT
	SUBCAT 
FROM bronze.erp_px_cat_g1v2 
WHERE SUBCAT <> TRIM(SUBCAT) ;

SELECT
	MAINTENANCE 
FROM bronze.erp_px_cat_g1v2 
WHERE MAINTENANCE <> TRIM(MAINTENANCE) ;

-- Data Standardization & Consistency

SELECT DISTINCT	
	CAT 
FROM bronze.erp_px_cat_g1v2 ;

SELECT DISTINCT	
	SUBCAT 
FROM bronze.erp_px_cat_g1v2 ;

SELECT DISTINCT	
	MAINTENANCE 
FROM bronze.erp_px_cat_g1v2 ;

