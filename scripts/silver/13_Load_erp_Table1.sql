-- Clean & Load Table cust_az12
INSERT INTO silver.erp_cust_az12 (
		CID ,
		BDATE ,
		GEN 
	)
SELECT 
	CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID , 4 , LEN(CID))
		 ELSE CID
	END AS CID, 
	CASE WHEN BDATE > GETDATE() THEN NULL
		 ELSE BDATE
	END AS BDATE ,
	CASE WHEN UPPER(TRIM(GEN)) IN ('F' , 'FEMALE' ) THEN 'Female'
		 WHEN UPPER(TRIM(GEN)) IN ('M' , 'MALE') THEN 'Male' 
		 ELSE 'n/a'
	END AS GEN
FROM bronze.erp_cust_az12 

SELECT * FROM silver.erp_cust_az12 ;