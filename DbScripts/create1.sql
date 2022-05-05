USE [ExcelExport];
Go

CREATE OR ALTER VIEW [dbo].[vEmployees]
AS
	SELECT [Id]
		  ,[FirstName]
		  ,[LastName]
		  ,[Email]
		  ,[SocialSecurityNumber]
		  ,[Department]
		  ,[Title]
		  ,[City]
		  ,[Salary]
	FROM [dbo].[Employees]
GO


CREATE OR ALTER PROCEDURE [dbo].[spGerEmployeeReport]
	@PageSize INT,
	@PageIndex INT,
	@Search VARCHAR(3000) = NULL,
	@SortBy VARCHAR(128) = NULL,
	@SortOrder VARCHAR(10) = NULL,
	@FilteredCount BIGINT OUTPUT
AS
BEGIN
	DECLARE
		@Skip INT = 0,
		@Take INT;

	IF @PageIndex < 1 SET @PageIndex = 1;
	IF @PageSize < 1 SET @PageSize = 1000;

	SET @Skip = @PageSize * (@PageIndex - 1);
	SET @Take = @PageSize;

	DECLARE @SQL nvarchar(4000);
	SET @SQL = 'SELECT [Id]
		  ,[FirstName]
		  ,[LastName]
		  ,[Email]
		  ,[SocialSecurityNumber]
		  ,[Department]
		  ,[Title]
		  ,[City]
		  ,[Salary]
	  FROM [dbo].[vEmployees]';

	DECLARE
		@EnabledSearch BIT = 0,
		@EnabledSortBy BIT = 0,
		@EnabledSortOrder BIT = 0,
		@ExistsKeySortBy BIT = 0;

	IF NOT ISNULL(@Search, '') = '' SET @EnabledSearch = 1;
	IF NOT ISNULL(@SortBy, '') = '' SET @EnabledSortBy = 1;
	IF NOT ISNULL(@SortOrder, '') = '' SET @EnabledSortOrder = 1;

	IF @EnabledSearch = 1
	BEGIN
		SET @SQL = @SQL
		---- IMPORTANT: IF YOU CHANGE BELOW ROW FILTER OR GROUP FILTER CODE, UPDATE THE FILTER CODE FOR COUNT OPERATION ALSO
			+ ' WHERE'
			+ ' FirstName LIKE ''%' + @Search + '%'''
			+ ' OR LastName LIKE ''%' + @Search + '%'''
			+ ' OR Email LIKE ''%' + @Search + '%'''
			+ ' OR Department LIKE ''%' + @Search + '%'''
			+ ' OR Title LIKE ''%' + @Search + '%'''
			+ ' OR City LIKE ''%' + @Search + '%''';

		SELECT @FilteredCount = COUNT(*)
		---- IMPORTANT: IF YOU CHANGE BELOW ROW FILTER OR GROUP FILTER CODE, UPDATE THE RELATED FILTER CODE FOR DYNAMIC QUERY BUILDING
		FROM [dbo].[vEmployees]
		WHERE FirstName LIKE CONCAT('%', @Search, '%')
		OR LastName LIKE CONCAT('%', @Search, '%')
		OR Email LIKE CONCAT('%', @Search, '%')
		OR Department LIKE CONCAT('%', @Search, '%')
		OR Title LIKE CONCAT('%', @Search, '%')
		OR City LIKE CONCAT('%', @Search, '%');

	END
	ELSE
	BEGIN
		SELECT @FilteredCount = COUNT(*)
		FROM [dbo].[vEmployees];
	END

	---- Sort order for ORDER BY clause
	IF @EnabledSortOrder = 1
	BEGIN
		IF UPPER(@SortOrder) = 'DESC'
			SET @SortOrder = 'DESC'
		ELSE
			SET @SortOrder = 'ASC';
	END
	ELSE
	BEGIN
		SET @SortOrder = 'ASC';
	END

	---- Check if sort by key exists in the columns
	IF @EnabledSortBy = 1
	BEGIN
		IF EXISTS (
			SELECT name
			FROM
				(SELECT name FROM sys.all_columns WHERE object_id = OBJECT_ID('[dbo].[vEmployees]')) AS ColNames
			WHERE name = @SortBy
		)
		BEGIN
			SET @SQL = @SQL
				+ ' ORDER BY ' + @SortBy + ' ' + @SortOrder;
		END		 
	END
	ELSE
	BEGIN
		SET @SQL = @SQL
				+ ' ORDER BY Id' + ' ' + @SortOrder;
	END

	SET @SQL = @SQL
		+ ' OFFSET' + CONCAT(' ', @Skip) + ' ROWS'
		+ ' FETCH NEXT' + CONCAT(' ', @Take) + ' ROWS ONLY;'
	
	---- Final execution of dynamic query
	EXEC (@SQL);
END
GO
