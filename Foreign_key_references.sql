--All of this tables foreign keys
SELECT 
	object_name(f.referenced_object_id) AS [Table this table references],
	c.name as [referencing column]
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns c ON c.object_id = fc.parent_object_id AND c.column_id = fc.parent_column_id
WHERE f.parent_object_id = object_id('dbo.Employee','U');


--all foreign key references to this table
SELECT 
	object_name(f.parent_object_id) AS [Table that references this table],
	c.name as [referencing column]
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns c ON c.object_id = fc.parent_object_id AND c.column_id = fc.parent_column_id
WHERE f.referenced_object_id = object_id('dbo.Employee','U');
