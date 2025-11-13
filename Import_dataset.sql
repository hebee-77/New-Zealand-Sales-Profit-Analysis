--Data has been imported
--Data has been loaded to the new table
--Table name is nz_sales
--First 5 rows of the table

select top 5 * from nz_sales

exec sp_rename 'nz_sales', 'nz_sales';