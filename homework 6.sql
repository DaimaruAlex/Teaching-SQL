USE WideWorldImporters

--№1. Сделать расчет суммы продаж нарастающим итогом по месецам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
-- В запросе наглядно видно нарастающий итог только если наложить фильтр на опред. клиента, иначе из за агрегации до клиента данные несколько разрознены.
--а) Оконные функции
SELECT DISTINCT i.InvoiceID, 
	   c.CustomerName, 
	   i.InvoiceDate, 
	   /*YEAR(i.InvoiceDate) [Год],
	   MONTH(i.InvoiceDate) [Месяц],*/
	   SUM(il.Quantity*il.UnitPrice) OVER(PARTITION BY i.InvoiceID 
					ORDER BY YEAR(i.InvoiceDate),MONTH(i.InvoiceDate)) SumSale,
	   SUM(il.Quantity*il.UnitPrice)
			OVER (PARTITION BY c.CustomerName 
					ORDER BY YEAR(i.InvoiceDate),MONTH(i.InvoiceDate)) TotalSum
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
WHERE YEAR(i.InvoiceDate) >= 2015 
/*фильтр для наглядности :) and CustomerName = 'Tailspin Toys (Ikatan, AK)'*/
GROUP BY i.InvoiceID, 
	   c.CustomerName, 
	   i.InvoiceDate,
	   il.Quantity,
	   il.UnitPrice,
	   i.CustomerID,
	   il.InvoiceLineId
ORDER BY i.InvoiceDate, TotalSum

--б) Иной метод

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
)
SELECT *,
	   (
		  SELECT SUM( DISTINCT Prob)
		  FROM Tot t2
		  WHERE (t2.InvoiceDate<t.InvoiceDate 
				OR (MONTH(t2.InvoiceDate)=MONTH(t.InvoiceDate) and YEAR(t2.InvoiceDate) = YEAR(t.InvoiceDate)))
				and t2.CustomerID = t.CustomerID
	   ) ProbTotal
FROM Tot t
ORDER BY InvoiceDate, ProbTotal

--№2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) 
--в каждом месяце за 2016 год по 2 самых популярных продукта в каждом месяце.

;WITH Aggregated AS (
SELECT DISTINCT wi.StockItemName,
				wi.StockItemID,
				MONTH(i.InvoiceDate) [Month],
				SUM(Quantity) 
						OVER (PARTITION BY MONTH(i.InvoiceDate),wi.StockItemID 
								ORDER BY wi.StockItemName) MaxQuantity
FROM Warehouse.StockItems wi
INNER JOIN Sales.InvoiceLines sil ON wi.StockItemID = sil.StockItemID
INNER JOIN Sales.Invoices i ON i.InvoiceID = sil.InvoiceID
WHERE YEAR(i.InvoiceDate) = 2016
)

SELECT StockItemName,[Month], MaxQuantity
FROM (SELECT *,
			  DENSE_RANK() 
					OVER(PARTITION BY [Month]
							ORDER BY MaxQuantity DESC) ForTotal
	  FROM Aggregated) as Total
WHERE ForTotal < 3
ORDER BY [Month]

--№3 Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
 /*пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт*/

SELECT StockItemID,
	   StockItemName,
	   Brand,
	   UnitPrice,
	   ROW_NUMBER() 
			OVER(ORDER BY StockItemName) NumberAlph,
	   COUNT(StockItemName) 
			OVER() TotalItems,
	   COUNT(StockItemID) 
			OVER(PARTITION BY LEFT(StockItemName,1)) AmountByFirstLetter,
	   LAG(StockItemID) 
			OVER(ORDER BY StockItemName) PrevID,
	   LEAD(StockItemID) 
			OVER(ORDER BY StockItemName) NextID,
	   LAG(StockItemName,2,'No item') 
			OVER(ORDER BY StockItemName) PrevTwoRowItem,
	   NTILE(30) 
			OVER(PARTITION BY [TypicalWeightPerUnit] 
					ORDER BY StockItemName) GroupWeight
FROM Warehouse.StockItems

--№4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки

;WITH Lasted AS (
SELECT p.PersonID,
	   p.FullName,
	   c.CustomerID,
	   c.CustomerName,
	   i.InvoiceDate,
	   i.InvoiceID,
	   SUM(il.Quantity*il.UnitPrice) 
			OVER (PARTITION BY i.InvoiceID 
					ORDER BY i.InvoiceID
						ROWS BETWEEN UNBOUNDED PRECEDING and CURRENT ROW) SumDeal,
	   LAST_VALUE(CustomerName) 
			OVER (PARTITION BY PersonID 
					ORDER BY i.InvoiceID 
						ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) LastDeal
FROM [Application].People p
INNER JOIN Sales.Invoices i ON i.SalespersonPersonID = p.PersonID
INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
)
SELECT PersonID,
	   FullName,
	   CustomerID,
	   CustomerName,
	   InvoiceDate,
	   SumDeal 
FROM (select *,
	   DENSE_RANK() 
			OVER(PARTITION BY PersonID 
					ORDER BY PersonID,InvoiceID DESC,SumDeal DESC) ForTotal
FROM Lasted) as Total
WHERE ForTotal = 1

--№5 Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

;WITH Aggregation AS (
SELECT c.CustomerID,
	   c.CustomerName,
	   il.StockItemID,
	   si.StockItemName,
	   i.InvoiceDate,
	   i.InvoiceID,
	   SUM(il.UnitPrice*il.Quantity) 
			OVER(PARTITION BY c.CustomerID,il.StockItemID,i.InvoiceID 
					 ORDER BY i.InvoiceID,il.StockItemID ) SumDeal
FROM Sales.Customers c
INNER JOIN Sales.Invoices i ON i.CustomerID = c.CustomerID
INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems si ON si.StockItemID = il.StockItemID
)

SELECT CustomerID,
	   CustomerName,
	   StockItemID,
	   StockItemName,
	   SumDeal,
	   InvoiceDate
FROM (SELECT *,
			 DENSE_RANK() 
					OVER(PARTITION BY CustomerID 
							ORDER BY SumDeal DESC, InvoiceID) ForTotal
	  FROM Aggregation) Total
WHERE ForTotal < 3