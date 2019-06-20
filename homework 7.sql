USE WideWorldImporters

set statistics time on

--Быстрая вставка во временную таблицу без объявления таблицы и полей к таблицам #temporary
use WideWorldImporters

;with Tot as (
SELECT i.InvoiceID,
	   c.CustomerName,
	   c.CustomerID,
	   i.InvoiceDate,
	   SUM(il.Quantity*il.UnitPrice) Prob
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
GROUP BY i.InvoiceID,
		 c.CustomerName,
		 c.CustomerID,
	     i.InvoiceDate
HAVING YEAR(i.InvoiceDate) >= 2015 --and c.CustomerName = 'Tailspin Toys (Ikatan, AK)'
),
Totalization as (SELECT *,
	   (
		  SELECT SUM( DISTINCT Prob)
		  FROM Tot t2
		  WHERE (t2.InvoiceDate<t.InvoiceDate 
				OR (MONTH(t2.InvoiceDate)=MONTH(t.InvoiceDate) and YEAR(t2.InvoiceDate) = YEAR(t.InvoiceDate)))
				and t2.CustomerID = t.CustomerID
	   ) ProbTotal
 FROM Tot t
)
SELECT * INTO #temporary
FROM Totalization
ORDER BY InvoiceDate, ProbTotal

SELECT *
FROM #temporary


-- С объявлением временной таблицы
CREATE TABLE #temp_table(
	InvoiceID INT NOT NULL,
	CustomerName NVARCHAR(50),
	CustomerID INT NOT NULL,
	InvoiceDate DATE,
	SumSale FLOAT,
	TotalSum FLOAT
)

;with Tot as (
SELECT i.InvoiceID,
	   c.CustomerName,
	   c.CustomerID,
	   i.InvoiceDate,
	   SUM(il.Quantity*il.UnitPrice) Prob
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
GROUP BY i.InvoiceID,
		 c.CustomerName,
		 c.CustomerID,
	     i.InvoiceDate
HAVING YEAR(i.InvoiceDate) >= 2015 --and c.CustomerName = 'Tailspin Toys (Ikatan, AK)'
),
Totalization as (SELECT *,
	   (
		  SELECT SUM( DISTINCT Prob)
		  FROM Tot t2
		  WHERE (t2.InvoiceDate<t.InvoiceDate 
				OR (MONTH(t2.InvoiceDate)=MONTH(t.InvoiceDate) and YEAR(t2.InvoiceDate) = YEAR(t.InvoiceDate)))
				and t2.CustomerID = t.CustomerID
	   ) ProbTotal
 FROM Tot t
)
INSERT INTO #temp_table
SELECT *
FROM Totalization
ORDER BY InvoiceDate, ProbTotal

SELECT * 
FROM #temp_table

-- с временной переменной
DECLARE @temp_table2 table(
	InvoiceID INT NOT NULL,
	CustomerName NVARCHAR(50),
	CustomerID INT NOT NULL,
	InvoiceDate DATE,
	SumSale FLOAT,
	TotalSum FLOAT
)
;with Tot as (
SELECT i.InvoiceID,
	   c.CustomerName,
	   c.CustomerID,
	   i.InvoiceDate,
	   SUM(il.Quantity*il.UnitPrice) Prob
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
GROUP BY i.InvoiceID,
		 c.CustomerName,
		 c.CustomerID,
	     i.InvoiceDate
HAVING YEAR(i.InvoiceDate) >= 2015 --and c.CustomerName = 'Tailspin Toys (Ikatan, AK)'
),
Totalization as (SELECT *,
	   (
		  SELECT SUM( DISTINCT Prob)
		  FROM Tot t2
		  WHERE (t2.InvoiceDate<t.InvoiceDate 
				OR (MONTH(t2.InvoiceDate)=MONTH(t.InvoiceDate) and YEAR(t2.InvoiceDate) = YEAR(t.InvoiceDate)))
				and t2.CustomerID = t.CustomerID
	   ) ProbTotal
 FROM Tot t
)

INSERT INTO @temp_table2
SELECT *
FROM Totalization
ORDER BY InvoiceDate, ProbTotal

select *
from @temp_table2

/*Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную*/

CREATE TABLE dbo.MyEmployees 
( 
EmployeeID smallint NOT NULL, 
FirstName nvarchar(30) NOT NULL, 
LastName nvarchar(40) NOT NULL, 
Title nvarchar(50) NOT NULL, 
DeptID smallint NOT NULL, 
ManagerID int NULL, 
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC) 
); 

INSERT INTO dbo.MyEmployees VALUES 
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL) 
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1) 
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273) 
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274) 
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274) 
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273) 
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285) 
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273) 
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16); 

select *
from dbo.MyEmployees;

with T (ManagerID, EmployeeID, FullName, Indent, Title, [Counter]) as
(
	select ManagerID
		  ,EmployeeID 
		  ,CONVERT(varchar(255),FirstName + ' ' + LastName) as FullName
		  ,CONVERT(varchar(255),'') as Indent 
		  ,Title
		  ,0 as [Counter]
	from dbo.MyEmployees
	where ManagerID is NULL
	union all
	select a.ManagerID
		  ,a.EmployeeID
		  ,CONVERT(varchar(255),'|' + b.Indent + FirstName + ' ' + LastName) as FullName
		  ,CONVERT(varchar(255),'|' + b.Indent) as Indent
		  ,a.Title
		  ,b.[Counter] + 1
	from dbo.MyEmployees as a
		inner join T as b
		on a.ManagerID = b.EmployeeID
)
select EmployeeID, FullName, Title, [Counter]
from T;