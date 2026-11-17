-- Create Stored Procedure

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME
	SET @batch_start_time = GETDATE()
	BEGIN TRY

		PRINT '========================================================================' ;
		PRINT 'Loading Silver Layer' ;
		PRINT '========================================================================' ;

		PRINT '------------------------------------------------------------------------' ;
		PRINT ' Loading CRM Tables ' ;
		PRINT '------------------------------------------------------------------------' ;

		-- Table 1

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.crm_cus_info';
		TRUNCATE TABLE silver.crm_cus_info ;

		PRINT '>> Inserting Data Into: silver.crm_cus_info';
		INSERT INTO silver.crm_cus_info (
		cst_id ,
		cst_key , 
		cst_firstname ,
		cst_lastname ,
		cst_marital_status ,
		cst_gndr , 
		cst_create_date)

		SELECT 
			cst_id ,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname ,
			TRIM(cst_lastname) AS cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				 ELSE 'n/a'
			END AS cst_marital_status ,
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END AS cst_gndr,
			cst_create_date
		FROM
		(
			SELECT 
				* ,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cus_info
			WHERE cst_id IS NOT NULL
		)C
		WHERE flag_last = 1 ;

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		-- Table 2

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info ;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';

		IF OBJECT_ID('silver.crm_prd_info' , 'U') IS NOT NULL 
			DROP TABLE silver.crm_prd_info

		CREATE TABLE silver.crm_prd_info(
			prd_id INT ,
			cat_id NVARCHAR(50) ,
			prd_key NVARCHAR(50) ,
			prd_nm NVARCHAR(50) ,
			prd_cost INT ,
			prd_line NVARCHAR(50) ,
			prd_start_dt DATE ,
			prd_end_dt DATE,
			dwh_create_Date DATETIME2 DEFAULT GETDATE()
		) ;

		INSERT INTO silver.crm_prd_info(
			prd_id ,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost ,
			prd_line,
			prd_start_dt,
			prd_end_dt 
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key , 1 , 5) , '-' , '_') AS cat_id ,  -- Extract category ID
			SUBSTRING(prd_key , 7 , LEN(prd_key)) AS prd_key ,			 -- Extract product key
			prd_nm,
			ISNULL(prd_cost,0) AS prd_cost ,
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line ,	-- Map product line codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt ,
			CAST(
				LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
				AS DATE
				) AS prd_end_dt  -- Calculate end date as one day before the next start date
		FROM bronze.crm_prd_info ; 

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		-- Table 3

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details ;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';

		IF OBJECT_ID('silver.crm_sales_details' , 'U') IS NOT NULL 
			DROP TABLE silver.crm_sales_details

		CREATE TABLE silver.crm_sales_details (
			sls_ord_num NVARCHAR(50) ,
			sls_prd_key NVARCHAR(50) ,
			sls_cust_id INT ,
			sls_order_dt DATE ,
			sls_ship_dt DATE ,
			sls_due_dt DATE ,
			sls_sales INT,
			sls_quantity INT ,
			sls_price INT,
			dwh_create_Date DATETIME2 DEFAULT GETDATE()
		)

		INSERT INTO silver.crm_sales_details (
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price 
			)
		SELECT
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
			END AS sls_order_dt,
			CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_ship_dt ,
			CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
			END AS sls_due_dt ,
			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales <> sls_quantity * ABS(sls_price) 
				 THEN sls_quantity * ABS(sls_price) 
				 ELSE sls_sales
			END AS sls_sales,
			sls_quantity ,
			CASE WHEN sls_price IS NULL OR sls_price <=0 THEN sls_sales / NULLIF(sls_quantity , 0)
				 ELSE sls_price 
			END AS sls_price
		FROM bronze.crm_sales_details ;

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		PRINT '------------------------------------------------------------------------' ;
		PRINT 'Loading ERP Tables' ;
		PRINT '------------------------------------------------------------------------' ;

		-- Table 4

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12 ;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
	
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
		FROM bronze.erp_cust_az12 ;

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		-- Table 5

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101 ;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';

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

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		-- Table 6

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

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

		SET @end_time = GETDATE() 
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second , @start_time , @end_time) AS NVARCHAR) + ' seconds'
		PRINT '>> ------------------'

		SET @batch_end_time =  GETDATE() ;
		PRINT '========================================================================' ;
		PRINT ' Loading Bronze Layer is Completed '
		PRINT '  - Total Load Duration:  ' + CAST(DATEDIFF(second , @batch_start_time , @batch_end_time) AS NVARCHAR) + ' seconds ' ;
		PRINT '========================================================================' ;

	END TRY
	BEGIN CATCH
		PRINT '========================================================================' ;
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE() ;
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR) ;
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR) ;
		PRINT '========================================================================' ;
	END CATCH
END 

EXEC silver.load_silver ;