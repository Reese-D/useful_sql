--Fill in the following linked server info
EXEC sp_addlinkedserver
@Server = N'ServerName',
@srvproduct=N'',
@provider=N'SQLNCLI',
@datasrc=N'ServerIpAddress';
GO

EXEC master.dbo.sp_addlinkedsrvlogin
		@rmtsrvname=N'ServerName',
		@useself=N'False',
		@locallogin=NULL,
		@rmtuser=N'Username',
		@rmtpassword=N'Password'

USE dbName; --Change this to whatever DB you want to use

--optionally create synonyms to specific tables from the linked server
GO
CREATE SYNONYM Synonym1 FOR
[ServerName].[dbName].[dbo].[SomeTable];
GO
CREATE SYNONYM Synonym2 FOR
[[ServerName]].[dbName].[dbo].[SomeOtherTable];
GO

------------------------------WORK HERE-------------------------------------------------

DECLARE @Total INT = 0
DECLARE @Rows INT,
        @BatchSize INT; 

SET @BatchSize = 2000; -- keep below 5000 to be safe

SET @Rows = @BatchSize; 
 
BEGIN TRY    
  WHILE (@Rows = @BatchSize)
  BEGIN
	
	  --Here's where you'll do the body of the work
	   
      SET @Rows = @@ROWCOUNT;
	  SET @Total = @Total + @Rows
	  PRINT @Total
  END;
END TRY
BEGIN CATCH
  RETURN;
END CATCH;
----------------------------------------------------------------------------------------
DROP SYNONYM Synonym1
GO
DROP SYNONYM Synonym2
GO
EXEC sp_droplinkedsrvlogin [ServerName], NULL
GO
EXEC sp_dropserver [ServerName]
GO

	  
	   