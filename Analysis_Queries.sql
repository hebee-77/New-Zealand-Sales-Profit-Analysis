--KPI

--A.OverView

--1.Table Preview
select top 5 * from nz_sales;

--2.Information about Table
select
column_name,
data_type,
character_maximum_length,
IS_NULLABLE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='nz_sales';


--3. Total revenue and total profit for the year

select 
round(sum(Sales),2) as Total_Sales,
round(sum(Profit),2) as Total_Profit
from nz_sales
where year(Order_Date)=2023;

--4. Total number of orders

select 
count(Order_ID) as Total_Orders
from nz_sales;

--5. Overall profit margin

select
sum(Sales)as Total_Sales,
sum(Profit)as Total_Profit,
(sum(profit)*1.0/nullif(sum(Sales),0))*100 as Profit_Margin
from nz_sales;

--6. Region with highest total sales

select top 1
Region,
sum(Sales) as Total_Sales
from nz_sales
group by Region
order by Total_Sales desc;

--7. Product category contributing most to revenue

select top 1
Category,
sum(Sales) as Total_Revenue
from nz_sales
group by Category
order by Total_Revenue desc;

 --B. Performance by Segment

 --8.Top 10 products by revenue

 select 
 top 10
[Product],
sum(Sales) as Total_Revenue
from nz_sales
group by [Product]
order by Total_Revenue desc;

--9.Top 10 products by profit 

select 
top 10 
[Product],
sum(Profit) as Total_Profit
from nz_sales
group by [Product]
order by Total_Profit desc;

--10.Most profitable vs least profitable regions

select 
top 2
Region,
sum(Profit) as Total_Profit
from nz_sales
group by Region
order by Total_Profit desc;

select
top 2
Region,
sum(Profit) as Total_Profit
from nz_sales
group by Region
order by Total_Profit asc;

--11.Best product within each category 

WITH ranked_products AS (
    SELECT
        Category,
        [product],
        SUM(sales) AS total_sales,
        RANK() OVER (PARTITION BY category ORDER BY SUM(Sales) DESC) AS rnk
    FROM nz_sales
    GROUP BY Category, [Product]
)
SELECT
    Category,
    [Product],
    total_sales
FROM ranked_products
WHERE rnk = 1
ORDER BY Category;

-- C. Trend Analysis

--12.Monthly sales & profit trend

select 
format(Order_Date, 'yyyy-MM'),
sum(Sales) as Total_Sales,
sum(Profit) as Total_Profit
from nz_sales
group by format(Order_Date, 'yyyy-MM');

--13. Months with peak / lowest revenue

--Peak Revenue
select
top 1
format(Order_Date,'yyyy-MM') as Order_Month,
sum(Sales) as Total_Revenue
from nz_sales
group by format(Order_Date,'yyyy-MM')
order by Total_Revenue desc;

--Lowest Revenue
select 
top 1
format(Order_Date,'yyyy-MM') as Order_Month,
sum(Sales) as Total_Revenue
from nz_sales
group by format(Order_Date,'yyyy-MM')
order by Total_Revenue asc;

--14.Most Profitable Region Over Time

WITH monthly AS (
    SELECT
        Region,
        YEAR(Order_Date) AS sales_year,
        MONTH(Order_Date) AS sales_month,
        SUM(Profit) AS monthly_profit
    FROM nz_sales
    GROUP BY region, YEAR(Order_Date), MONTH(Order_Date)
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY monthly_profit DESC) AS rnk
    FROM monthly
)
SELECT
    Region,
    COUNT(*) AS Months_Ranked_1,
    SUM(monthly_profit) AS Total_Profit_in_Ranked_Months
FROM ranked
WHERE rnk = 1
GROUP BY region
ORDER BY months_ranked_1 DESC, total_profit_in_ranked_months DESC;

--15.Quaterly Sales Trends by Region

select 
Region,
concat('Q',DATEPART(quarter,Order_Date),' ',year(Order_Date))as Sales_Quater,
sum(Sales) as Total_Sales
from nz_sales
group by Region,concat('Q',DATEPART(quarter,Order_Date),' ',year(Order_Date))
order by Region, Sales_Quater

--D.Profitability

--16.Profit Margin For each Product

select Product,
Profit/Sales as ProfitMargin
from nz_sales

--17.Profitable Product within each category

select top 5
[Product],Category,
sum(Profit) as Profitable_Products
from nz_sales
group by [Product],Category
order by Profitable_Products desc;

--18.Compare profit margins between categories 

SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CASE 
        WHEN SUM(Sales) = 0 THEN 0
        ELSE (SUM(profit) * 1.0 / SUM(Sales)) * 100
    END AS Profit_Margin_Percent
FROM nz_sales
GROUP BY category
ORDER BY profit_margin_percent DESC;

--E. Strategic Insights & Recommendations

--19.Categories to Prioritize

WITH metrics AS (
  SELECT
    Category,
    SUM(Sales) AS Total_Revenue,
    SUM(Profit) AS Total_Profit,
    (SUM(Profit)*1.0 / NULLIF(SUM(Sales),0))*100 AS Margin
  FROM nz_sales
  GROUP BY Category
)
SELECT
    Category,
    Total_Revenue,
    Total_Profit,
    Margin,
    CASE 
        WHEN Margin > 0.15 AND Total_Revenue > (SELECT PERCENTILE_CONT(0.5) 
                                                WITHIN GROUP (ORDER BY Total_Revenue) OVER ())
        THEN 'High priority'
        WHEN Margin BETWEEN 0.05 AND 0.15 THEN 'Maintain / Optimize'
        ELSE 'Low priority'
    END AS priority_bucket
FROM metrics
ORDER BY total_profit DESC;

--20.Identify Underperforming Products (Low Sales & Profit)

with Product_performance as(
    select 
        [Product],
        round(sum(Sales),2) as Total_sales,
        round(sum(Profit),2) as profit
    from nz_sales
    group by [Product]
),
threshold as (
    select
        PERCENTILE_CONT(0.25) within group(order by sum(Total_Sales) desc) over() as sales_threshold,
        Percentile_cont(0.25) within group(order by sum(Profit) desc) over() as profit_threshold
    from  Product_performance
    )
select
       p.[Product],
       P.Total_sales,
       p.profit
from Product_performance p
cross join (select top 1 * from threshold )t

where p.Total_sales <t.sales_threshold AND
      p.profit < t.profit_threshold
order by p.profit desc;

