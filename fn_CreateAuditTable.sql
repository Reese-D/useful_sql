/*
	Right now there are a few constraints to this function
	1) The query is often > 4000 characters so it can't be sp_execute'd, instead just print the result of this function off and run that instead
	2) The audited table has to have a LastEditedByUserID for the AuditUserID to be created properly
	3) This only works with 1 primary key, not composite keys, however it would be fairly easy to modify the result for a composite key or update this function for that purpose
*/
ALTER FUNCTION fn_CreateAuditTable(
	@TableName NVARCHAR(255),
	@PrimaryKey NVARCHAR(255)
) RETURNS VARCHAR(MAX)
AS BEGIN

	DECLARE @AuditTableName NVARCHAR(MAX) = 'Audit.' + @TableName +'Audit'
	DECLARE @ConstraintName NVARCHAR(MAX) = '[PK_' + @TableName +'Audit]'

	DECLARE @ListStr NVARCHAR(MAX)
	DECLARE @Deleted NVARCHAR(MAX)
	DECLARE @Inserted NVARCHAR(MAX)
	DECLARE @Normal NVARCHAR(MAX)

	DECLARE @SQLQuery NVARCHAR(MAX)


	--get a list of all the table columns
	SELECT 
		@ListStr =  COALESCE(@ListStr +',', '') + '[' + c.Name + '] [' + t.Name + ']' + CASE WHEN t.name like '%char%' THEN '(' + CONVERT(VARCHAR(10), c.max_length) + ')' ELSE '' END,
		@Deleted = COALESCE(@Deleted + ',', '') + 'DELETED.' + c.Name,
		@Inserted = COALESCE(@Inserted + ',', '') + 'INSERTED.' + c.Name,
		@Normal = COALESCE(@Normal + ',', '') + c.name
	FROM    
		sys.columns c
	INNER JOIN 
		sys.types t ON c.user_type_id = t.user_type_id
	WHERE
		c.object_id = OBJECT_ID(@TableName)


	SET @SQLQuery = 
	'
	CREATE TABLE ' + @AuditTableName + '([AuditID] [int] IDENTITY(1,1) NOT NULL, [AuditTypeCode] CHAR, AuditUserID INT, UtcAuditDate DATETIME, ' + @ListStr + ', AuditSystemUsername VARCHAR(255),  
		CONSTRAINT' + @ConstraintName + ' PRIMARY KEY CLUSTERED 
		(
			[AuditID] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	GO
	'

	SET @SQLQuery = @SQLQuery + 
	'
	CREATE TRIGGER [dbo].[Trg_' + @TableName+ 'Audit] ON [dbo].[' + @TableName+ '] AFTER INSERT, UPDATE, DELETE NOT FOR REPLICATION
	AS
	IF EXISTS(SELECT * FROM DELETED) AND NOT EXISTS(SELECT * FROM INSERTED)
	BEGIN
		INSERT INTO '+ @AuditTableName + '(AuditTypeCode,AuditUserID,UtcAuditDate,' + @Normal + ',AuditSystemUsername)
		SELECT
			''D'' AS AuditTypeCode,
			DELETED.LastEditedByUserID AS AuditUserID,
			GETUTCDATE() AS UtcAuditDate,' 
			+ @Deleted 
			+ ', SUSER_NAME()
			FROM DELETED
	END

	IF EXISTS(SELECT * FROM INSERTED)
	BEGIN
		INSERT INTO '+ @AuditTableName + '(AuditTypeCode,AuditUserID,UtcAuditDate,' + @Normal + ',AuditSystemUsername)
			SELECT
				CASE
					WHEN DELETED.' + @PrimaryKey + ' IS NULL 
						THEN ''I''
					ELSE 
						''U''
				END AS AuditTypeCode,
				INSERTED.LastEditedByUserID AS AuditUserID,
				GETUTCDATE() AS UtcAuditDate,' 
				+ @Inserted 
				+ ', SUSER_NAME()
					FROM INSERTED
					LEFT JOIN DELETED ON DELETED.' + @PrimaryKey + ' = INSERTED.' + @PrimaryKey + '
					WHERE (DELETED.'+ @PrimaryKey +' IS NULL)
					OR     CHECKSUM(''A'',' + @Inserted + ')
						!= CHECKSUM(''A'',' + @Deleted + ')
	END

	GO'

	RETURN @SQLQuery 
END