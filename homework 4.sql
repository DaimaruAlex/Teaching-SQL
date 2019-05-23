--№1 Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
-- так как таких сотрудников не было обнаружено, все сотрудники с признаком IsSalesPerson имели продажи 
--был модифицирован пользователь с PersonID = 11 для показательности запроса 

--Модификация
UPDATE Application.People
SET IsSalesperson = 1, IsSystemUser = 0
WHERE PersonID = 11

-- Выборка
--а) вариант без WITH
SELECT FullName
FROM [Application].People
WHERE PersonID NOT IN (SELECT Sales.Invoices.SalespersonPersonID 
					   FROM Sales.Invoices) 
and IsSalesperson = 1

--б) вариант с WITH

;WITH t as (
	SELECT Sales.Invoices.SalespersonPersonID 
	FROM Sales.Invoices
)
SELECT FullName
FROM [Application].People p
LEFT OUTER JOIN t ON t.SalespersonPersonID = p.PersonID
WHERE t.SalespersonPersonID IS NULL
AND IsSalesperson = 1

--№2 Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса
--а) вариант с подзапросом
SELECT *
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) minimal
					FROM Warehouse.StockItems)


--б) вариат с WITH

WITH Min_Price AS (
		SELECT MIN(UnitPrice) minimal
		FROM Warehouse.StockItems
)
SELECT *
FROM Warehouse.StockItems SI
INNER JOIN Min_Price MP ON SI.UnitPrice = MP.minimal

--№3 Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей 
--из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE).

--а) Вариант с WITH
WITH Max_Pay as (

SELECT TOP(5) CustomerID, MAX(TransactionAmount) Max_tran
FROM Sales.CustomerTransactions
GROUP BY CustomerID
ORDER BY Max_tran DESC

)

SELECT *
FROM Sales.Customers c
INNER JOIN Max_Pay MP ON C.CustomerID = MP.CustomerID 

--б) Вариант с подзапросом

SELECT *
FROM Sales.Customers
WHERE CustomerID = ANY (SELECT s.CustomerID 
						FROM (SELECT TOP(5) CustomerID, MAX(TransactionAmount) Max_tran
					 FROM Sales.CustomerTransactions
					 GROUP BY CustomerID
					 ORDER BY Max_tran DESC) s)

--в) Вариант с подзапросом в JOIN

SELECT *
FROM Sales.Customers c
INNER JOIN (SELECT s.CustomerID 
			FROM (
				 SELECT TOP(5) CustomerID, MAX(TransactionAmount) Max_tran
				 FROM Sales.CustomerTransactions
				 GROUP BY CustomerID
				 ORDER BY Max_tran DESC) s
			) sub ON c.CustomerID = sub.CustomerID


--№4 Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров,
--а также Имя сотрудника, который осуществлял упаковку заказов

WITH SubQ AS (
		SELECT TOP(3) StockItemID,
					  StockItemName, 
					  MAX(UnitPrice) max_unit
		FROM Warehouse.StockItems
		GROUP BY StockItemID,StockItemName
		ORDER BY max_unit DESC
),
Expensive_Cities AS (
		SELECT CityID,
			   CityName,
			   so.SalespersonPersonID PersonID
		FROM [Application].Cities ac
		INNER JOIN Sales.Customers sc ON ac.CityID = sc.DeliveryCityID
		INNER JOIN Sales.Orders so ON so.CustomerID = sc.CustomerID
		INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
		INNER JOIN SubQ e ON e.StockItemID = sol.StockItemID
		GROUP BY CityID,CityName,
				 so.SalespersonPersonID
)
SELECT sub.CityID,
	   sub.CityName,
	   ap.FullName
FROM Expensive_Cities sub
INNER JOIN [Application].People ap ON SUB.PersonID = ap.PersonID


--№5 Объясните, что делает и оптимизируйте запрос
/* Запрос отображает данные накладной (номер накладной, дату создания, продавца, общую сумму по накладной
 и общую сумму выбранных товаров в заказе). При этом выводятся заказы, по которым итоговая сумма больше 27 тыс.
 Вариантов по оптимизации не смог придумать */

WITH T AS (
		SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT Invoices.InvoiceID, 
	   Invoices.InvoiceDate,
	   (SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	   ) AS SalesPersonName,
	   SalesTotals.TotalSumm AS TotalSummByInvoice, 
	   (SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
									FROM Sales.Orders
									WHERE Orders.PickingCompletedWhen IS NOT NULL	
										  AND Orders.OrderId = Invoices.OrderId)	
	   ) AS TotalSummForPickedItems
FROM Sales.Invoices 
JOIN T AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC