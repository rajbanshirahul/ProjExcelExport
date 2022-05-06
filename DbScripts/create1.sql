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


CREATE OR ALTER PROCEDURE [dbo].[spGetEmployeeReport]
	@PageSize INT OUTPUT,
	@PageIndex INT OUTPUT,
	@Search VARCHAR(3000) = NULL,
	@SearchFilter VARCHAR(MAX) = NULL,
	@ExactMatch BIT = 0,
	@SortBy VARCHAR(128) = NULL,
	@SortOrder VARCHAR(10) = NULL,
	@FilteredCount BIGINT OUTPUT,
	@TotalRecordsCount BIGINT OUTPUT,
	@TotalPageCount INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	---- DATA SOURCE
	DECLARE @DataSourceObject VARCHAR(128) = '[dbo].[vEmployees]';
	
	DECLARE
		@DefaultMinPageSize INT = 1,
		@DefaultPageSize INT = 10000,
		@DefaultMaxPageSize INT = 100000,
		@DefaultMinPageIndex INT = 1;
	
	DECLARE
		@Skip INT = 0,
		@Take INT = @DefaultPageSize;

	---- Default SortBy (ORDER BY) column
	DECLARE @SortByDefault VARCHAR(128) = 'Id';

	IF @PageIndex < @DefaultMinPageIndex SET @PageIndex = @DefaultMinPageIndex;
	IF @PageSize > @DefaultMaxPageSize SET @PageSize = @DefaultMaxPageSize;
	IF @PageSize < @DefaultMinPageSize SET @PageSize = @DefaultPageSize;

	SET @Skip = @PageSize * (@PageIndex - 1);
	SET @Take = @PageSize;

	---- QUERY and COUNT statement declaration and partial initialization
	DECLARE
		@SQL NVARCHAR(4000),
		@SQLFilteredCount NVARCHAR(4000),
		@SQLTotalRecordsCount NVARCHAR(4000);

	SET @SQL = 'SELECT [Id]
		  ,[FirstName]
		  ,[LastName]
		  ,[Email]
		  ,[SocialSecurityNumber]
		  ,[Department]
		  ,[Title]
		  ,[City]
		  ,[Salary]
	  FROM ' + @DataSourceObject;

	SET @SQLFilteredCount = 'SELECT @FilteredCount = COUNT(1) FROM ' + @DataSourceObject;
	SET @SQLTotalRecordsCount = 'SELECT @TotalRecordsCount = COUNT(1) FROM ' + @DataSourceObject;

	---- FLAGS for conditional operations
	DECLARE
		@EnabledSearch BIT = 0,
		@EnabledSearchFilter BIT = 0,
		@EnabledSortBy BIT = 0,
		@EnabledSortOrder BIT = 0,
		@ExistsKeySortBy BIT = 0;

	IF NOT ISNULL(@Search, '') = '' SET @EnabledSearch = 1;
	IF NOT ISNULL(@SearchFilter, '') = '' SET @EnabledSearchFilter = 1;
	IF NOT ISNULL(@SortBy, '') = '' SET @EnabledSortBy = 1;
	IF NOT ISNULL(@SortOrder, '') = '' SET @EnabledSortOrder = 1;

	---- BEGIN; Columns specification to search in
	DECLARE @SearchColumns TABLE ([value] VARCHAR(128));

	---- columns specification to search in when search filter is applied
	IF @EnabledSearch = 1 AND @EnabledSearchFilter = 1
	BEGIN
		INSERT INTO @SearchColumns
			SELECT [value] FROM STRING_SPLIT(@SearchFilter, ',')
			WHERE TRIM([value]) IN
				(SELECT [name] FROM sys.all_columns WHERE object_id = OBJECT_ID(@DataSourceObject));
	END

	---- default columns specification to search in when no search filter is applied
	IF @EnabledSearch = 1 AND @EnabledSearchFilter = 0
	BEGIN
		INSERT INTO @SearchColumns
			VALUES
				('[Id]'),
				('[FirstName]'),
				('[LastName]'),
				('[Email]'),
				('[SocialSecurityNumber]'),
				('[Department]'),
				('[Title]'),
				('[City]'),
				('[Salary]');
	END ---- END; Columns specification to search in

	IF @EnabledSearch = 1 AND @EnabledSearchFilter = 1 AND @ExactMatch = 1
	BEGIN
		DECLARE @SearchString VARCHAR(MAX) = '';
		SELECT @SearchString =
			CASE
				WHEN @SearchString = '' THEN
					COALESCE(CONCAT(@SearchString, [value], ' = ''', @Search, ''''), [value])
				ELSE
					COALESCE(CONCAT(@SearchString, ' AND ', [value], ' = ''', @Search, ''''), [value])
			END
		FROM @SearchColumns;

		SET @SQL = @SQL + ' WHERE ' + @SearchString;
		SET @SQLFilteredCount = @SQLFilteredCount + ' WHERE ' + @SearchString;
	END

	IF @EnabledSearch = 1 AND @EnabledSearchFilter = 1 AND @ExactMatch = 0
	BEGIN
		DECLARE @SearchString2 VARCHAR(MAX) = '';
		SELECT @SearchString2 =
			CASE
				WHEN @SearchString2 = '' THEN
					COALESCE(CONCAT(@SearchString2, [value], ' LIKE ''%', @Search, '%'''), [value])
				ELSE
					COALESCE(CONCAT(@SearchString2, ' OR ', [value], ' LIKE ''%', @Search + '%'''), [value])
			END
		FROM @SearchColumns;

		SET @SQL = @SQL + ' WHERE ' + @SearchString2;
		SET @SQLFilteredCount = @SQLFilteredCount + ' WHERE ' + @SearchString2;
	END

	IF (@EnabledSearch = 1 AND @EnabledSearchFilter = 0 AND @ExactMatch = 0)
		OR (@EnabledSearch = 1 AND @EnabledSearchFilter = 0 AND @ExactMatch = 1)
	BEGIN
		DECLARE @SearchString3 VARCHAR(MAX) = '';
		SELECT @SearchString3 =
			CASE
				WHEN @SearchString3 = '' THEN
					COALESCE(CONCAT(@SearchString3, [value], ' LIKE ''%', @Search, '%'''), [value])
				ELSE
					COALESCE(CONCAT(@SearchString3, ' OR ', [value], ' LIKE ''%', @Search + '%'''), [value])
			END
		FROM @SearchColumns;

		SET @SQL = @SQL + ' WHERE ' + @SearchString3;
		SET @SQLFilteredCount = @SQLFilteredCount + ' WHERE ' + @SearchString3;
	END

	---- SET @FilteredCount and @SQLTotalRecordsCount variables before sorting the data for efficient count operation
	EXEC sp_executesql @SQLFilteredCount, N'@FilteredCount INT OUTPUT', @FilteredCount OUTPUT;
	EXEC sp_executesql @SQLTotalRecordsCount, N'@TotalRecordsCount INT OUTPUT', @TotalRecordsCount OUTPUT;

	---- If @Skip value is less than total matched results count, reset @PageIndex to 1
	IF @FilteredCount <= @Skip
	BEGIN
		SET @Skip = 0;
		SET @PageIndex = @DefaultMinPageIndex;
	END

	---- Evaluate and SET total page count
	IF @FilteredCount < 1
		SET @TotalPageCount = 1
	ELSE IF (@FilteredCount % @PageSize) = 0
		SET @TotalPageCount = @FilteredCount / @PageSize;
	ELSE SET @TotalPageCount = (@FilteredCount / @PageSize) + 1

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
				(SELECT name FROM sys.all_columns WHERE object_id = OBJECT_ID(@DataSourceObject)) AS ColNames
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
				+ ' ORDER BY ' + @SortByDefault + ' ' + @SortOrder;
	END

	SET @SQL = @SQL
		+ ' OFFSET' + CONCAT(' ', @Skip) + ' ROWS'
		+ ' FETCH NEXT' + CONCAT(' ', @Take) + ' ROWS ONLY;'
	
	---- Final execution of dynamic query
	EXEC (@SQL);
	SET NOCOUNT OFF;
END
GO





---- TEST: PROC
--DECLARE @FCount BIGINT, @TCount BIGINT, @PageIndex INT = 1, @TotalPageCount INT, @PageSize INT = 200000;

--EXEC [dbo].[spGetEmployeeReport]
--	@PageSize = @PageSize OUTPUT, @PageIndex = @PageIndex OUTPUT, @Search = 'sales',
--	@SearchFilter = 'Department', @ExactMatch = 0, @FilteredCount = @fcount OUTPUT,
--	@TotalRecordsCount = @tcount OUTPUT, @TotalPageCount = @TotalPageCount OUTPUT;

--SELECT @FCount FilteredCount, @TCount AS TotalCount, @PageIndex AS PageIndex, @PageSize AS PageSize