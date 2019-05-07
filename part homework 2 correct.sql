--№1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
use WideWorldImporters
go
select *
from WideWorldImporters.Warehouse.StockItems
where StockItemName like 'Animal%' or StockItemName like '%urgent%'

--№2. Поставщики, у которых не было сделано ни одного заказа
use WideWorldImporters
go
select PS.SupplierName
from Purchasing.Suppliers AS PS 
LEFT OUTER JOIN Purchasing.PurchaseOrders as PPO on PS.SupplierID = PPO.SupplierID
where PPO.SupplierID is null


/* №3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, 
включите также к какой трети года относится дата - каждая треть по 4 месяца, с ценой товара более 100$ либо количество единиц товара более 20.
Так как явного поля с датой продажи не нашел за дату продажи считаю подтвержденную дату доставки*/

--a) без заданной даты забора
select StockItemName as [Товар], 
	   CustomerName as [Покупатель], 
	   Quantity as [Количество],
	   i2.ExtendedPrice as [Финальная цена],
	   ConfirmedDeliveryTime as [Дата продажи],
	   DATENAME(mm,ConfirmedDeliveryTime) as [Месяц продажи], 
	   DATEPART(QQ,ConfirmedDeliveryTime) as [Квартал продажи], 
	   IIF(MONTH(ConfirmedDeliveryTime) between 1 and 4, 'first third', 
				IIF(MONTH(ConfirmedDeliveryTime) between 5 and 8,'second third',
						IIF(MONTH(ConfirmedDeliveryTime) between 9 and 12,'third third',''))) as [Треть года]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID
where (ConfirmedDeliveryTime is not null) and (Quantity > 20 or ExtendedPrice > 100)
Order BY [Квартал продажи], [Треть года], [Дата продажи] 
 OFFSET 1000 ROWS
 FETCH NEXT 100 ROWS ONLY

--b) с заданной даты забора
select StockItemName as [Товар], 
	   CustomerName as [Покупатель], 
	   Quantity as [Количество],
	   i2.ExtendedPrice as [Финальная цена],
	   ConfirmedDeliveryTime as [Дата продажи],
	   PickingCompletedWhen as [Дата забора],
	   DATENAME(mm,ConfirmedDeliveryTime) as [Месяц продажи], 
	   DATEPART(QQ,ConfirmedDeliveryTime) as [Квартал продажи], 
	   IIF(MONTH(ConfirmedDeliveryTime) between 1 and 4, 'first third', 
				IIF(MONTH(mm,ConfirmedDeliveryTime) between 5 and 8,'second third',
						 IIF(MONTH(ConfirmedDeliveryTime) between 9 and 12,'third third',''))) as [Треть года]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID 
where (ConfirmedDeliveryTime is not null) and (Quantity > 20 or ExtendedPrice > 100) 
and (DAY(PickingCompletedWhen) between 1 and 10 
and MONTH(PickingCompletedWhen) between 2 and 3 
and YEAR(PickingCompletedWhen) = 2013)
Order BY [Квартал продажи], [Треть года], [Дата продажи] 
 OFFSET 1000 ROWS
 FETCH NEXT 100 ROWS ONLY

 -- №4 Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ.

 select StockItemName as [Название товара], 
	    OrderID as [Номер заказа], 
		DeliveryMethodName as [Метод доставки], 
		SupplierName as [Имя поставщика], 
		ConfirmedReceivedBy as [Контактное лицо, принявшее заказ]
from Purchasing.PurchaseOrders as p1
INNER JOIN Purchasing.Suppliers as s1 ON s1.SupplierID = p1.SupplierID
INNER JOIN Purchasing.PurchaseOrderLines as p2 ON p1.PurchaseOrderID = p2.PurchaseOrderID
INNER JOIN Sales.Invoices as i1 ON i1.OrderID = p2.OrderedOuters
INNER JOIN Application.DeliveryMethods as d1 ON d1.DeliveryMethodID = p1.DeliveryMethodID
INNER JOIN Warehouse.StockItems as ws ON ws.StockItemID = p2.StockItemID
where IsOrderFinalized = 1 
and YEAR(LastReceiptDate) = 2014  
and (DeliveryMethodName like 'Post' or DeliveryMethodName like 'Road Freight')

--№5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
select TOP(10) StockItemName as [Товар], 
	   CustomerName as [Покупатель], 
	   FullName as [Продавец],
	   Quantity as [Количество],
	   i2.ExtendedPrice as [Финальная цена],
	   ConfirmedDeliveryTime as [Дата продажи]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID
INNER JOIN [Application].People as ap1 on ap1.PersonID = i1.SalespersonPersonID
where (ConfirmedDeliveryTime is not null)
Order BY [Дата продажи] desc

 --№6 Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g.
select c1.CustomerID as [ID покупателя], 
	   CustomerName as [Покупатель], 
	   c1.PhoneNumber as [Телефонный номер], 
	   StockItemName as [Название товара], 
	   i2.Quantity as [Количество], 
	   i2.ExtendedPrice as [Финальная цена]
from Sales.Customers as c1 
INNER JOIN Sales.Orders as o1 ON o1.CustomerID = c1.CustomerID
INNER JOIN Sales.OrderLines as o2 ON o2.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as s1 ON s1.StockItemID = o2.StockItemID
INNER JOIN Sales.Invoices as i1 ON i1.OrderID = o1.OrderID
INNER JOIN Sales.InvoiceLines as i2 ON i2.InvoiceID = i1.InvoiceID
where StockItemName like '%Chocolate frogs 250g%'