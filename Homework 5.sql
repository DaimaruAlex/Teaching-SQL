use WideWorldImporters
--№1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
-- С детализацией по товарам без сортировки
SELECT
	wsi.StockItemName [Товар],
	YEAR(i.ConfirmedDeliveryTime) [Год продажи],
	MONTH(I.ConfirmedDeliveryTime) [Месяц продажи],
	AVG(il.UnitPrice*il.Quantity) [Средний чек],
	SUM(il.UnitPrice*il.Quantity) [Общая сумма]
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems wsi ON il.StockItemID = wsi.StockItemID
WHERE i.ConfirmedDeliveryTime is not null
GROUP BY ROLLUP (wsi.StockItemName, YEAR(ConfirmedDeliveryTime), MONTH(ConfirmedDeliveryTime))

-- С детализацией по товарам с сортировки
SELECT
	wsi.StockItemName [Товар],
	YEAR(i.ConfirmedDeliveryTime) [Год продажи],
	MONTH(I.ConfirmedDeliveryTime) [Месяц продажи],
	AVG(il.UnitPrice*il.Quantity) [Средний чек],
	SUM(il.UnitPrice*il.Quantity) [Общая сумма]
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems wsi ON il.StockItemID = wsi.StockItemID
WHERE i.ConfirmedDeliveryTime is not null
GROUP BY ROLLUP (wsi.StockItemName, YEAR(ConfirmedDeliveryTime), MONTH(ConfirmedDeliveryTime))
ORDER BY YEAR(ConfirmedDeliveryTime), MONTH(ConfirmedDeliveryTime)


--№2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 
--(Сделал в рамках общей выручки по товару за месяц, если брать тоталы по месяцам они варируются в рамках миллионов)

--а) оставляя деталиpацию до вида товара
SELECT
	wsi.StockItemName [Товар],
	YEAR(I.ConfirmedDeliveryTime),
	MONTH(I.ConfirmedDeliveryTime) [Месяц продажи],
	AVG(il.UnitPrice*il.Quantity) [Средний чек],
	SUM(il.UnitPrice*il.Quantity) [Общая сумма]
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems wsi ON il.StockItemID = wsi.StockItemID
WHERE i.ConfirmedDeliveryTime is not null
GROUP BY ROLLUP (wsi.StockItemName,MONTH(ConfirmedDeliveryTime), YEAR(ConfirmedDeliveryTime))
HAVING SUM(il.UnitPrice*il.Quantity) > 10000 

--№3 Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.
-- Сделано так же в рамках товара.

SELECT
	wsi.StockItemName [Товар],
	YEAR(ConfirmedDeliveryTime) [Год продажи],
	MONTH(ConfirmedDeliveryTime) [Месяц продажи],
	SUM(il.UnitPrice*il.Quantity) [Сумма продаж],
	MIN(i.ConfirmedDeliveryTime) [Дата первой продажи],
	SUM(Quantity) [Количество проданного за месяц]
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems wsi ON il.StockItemID = wsi.StockItemID
WHERE i.ConfirmedDeliveryTime is not null
GROUP BY ROLLUP (wsi.StockItemName,YEAR(ConfirmedDeliveryTime),MONTH(ConfirmedDeliveryTime))
HAVING SUM(Quantity) < 50