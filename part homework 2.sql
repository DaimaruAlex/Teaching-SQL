--�1. ��� ������, � ������� � �������� ���� ������� urgent ��� �������� ���������� � Animal
use WideWorldImporters
go
select *
from WideWorldImporters.Warehouse.StockItems
where StockItemName like 'Animal%' or StockItemName like '%urgent%'

--�2. ����������, � ������� �� ���� ������� �� ������ ������
use WideWorldImporters
go
select PS.SupplierName
from Purchasing.Suppliers AS PS LEFT OUTER JOIN Purchasing.PurchaseOrders as PPO on PS.SupplierID = PPO.SupplierID
where PPO.SupplierID is null


/* �3. ������� � ��������� ������, � ������� ���� �������, ������� ��������, � �������� ��������� �������, 
�������� ����� � ����� ����� ���� ��������� ���� - ������ ����� �� 4 ������, � ����� ������ ����� 100$ ���� ���������� ������ ������ ����� 20.
��� ��� ������ ���� � ����� ������� �� ����� �� ���� ������� ������ �������������� ���� ��������*/

--a) ��� �������� ���� ������
select StockItemName as [�����], 
	   CustomerName as [����������], 
	   Quantity as [����������],
	   i2.ExtendedPrice as [��������� ����],
	   ConfirmedDeliveryTime as [���� �������],
	   DATENAME(mm,ConfirmedDeliveryTime) as [����� �������], 
	   DATEPART(QQ,ConfirmedDeliveryTime) as [������� �������], 
	   IIF(DATEPART(mm,ConfirmedDeliveryTime) between 1 and 4, 'first third', IIF(DATEPART(mm,ConfirmedDeliveryTime) between 5 and 8,'second third',IIF(DATEPART(mm,ConfirmedDeliveryTime) between 9 and 12,'third third',''))) as [����� ����]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID
where (ConfirmedDeliveryTime is not null) and (Quantity > 20 or ExtendedPrice > 100)
Order BY [������� �������], [����� ����], [���� �������] 
 OFFSET 1000 ROWS
 FETCH NEXT 100 ROWS ONLY

--b) � �������� ���� ������
select StockItemName as [�����], 
	   CustomerName as [����������], 
	   Quantity as [����������],
	   i2.ExtendedPrice as [��������� ����],
	   ConfirmedDeliveryTime as [���� �������],
	   PickingCompletedWhen as [���� ������],
	   DATENAME(mm,ConfirmedDeliveryTime) as [����� �������], 
	   DATEPART(QQ,ConfirmedDeliveryTime) as [������� �������], 
	   IIF(DATEPART(mm,ConfirmedDeliveryTime) between 1 and 4, 'first third', IIF(DATEPART(mm,ConfirmedDeliveryTime) between 5 and 8,'second third',IIF(DATEPART(mm,ConfirmedDeliveryTime) between 9 and 12,'third third',''))) as [����� ����]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID 
where (ConfirmedDeliveryTime is not null) and (Quantity > 20 or ExtendedPrice > 100) and (DATEPART(dd,PickingCompletedWhen) between 1 and 10 and DATEPART(mm,PickingCompletedWhen) between 2 and 3 and DATEPART(yyyy, PickingCompletedWhen) = 2013)
Order BY [������� �������], [����� ����], [���� �������] 
 OFFSET 1000 ROWS
 FETCH NEXT 100 ROWS ONLY

 -- �4 ������ �����������, ������� ���� ��������� �� 2014� ��� � ��������� Road Freight ��� Post, �������� �������� ����������, ��� ����������� ���� ������������ �����.

 select StockItemName as [�������� ������], OrderID as [����� ������], DeliveryMethodName as [����� ��������], SupplierName as [��� ����������], ConfirmedReceivedBy as [���������� ����, ��������� �����]
from Purchasing.PurchaseOrders as p1
INNER JOIN Purchasing.Suppliers as s1 ON s1.SupplierID = p1.SupplierID
INNER JOIN Purchasing.PurchaseOrderLines as p2 ON p1.PurchaseOrderID = p2.PurchaseOrderID
INNER JOIN Sales.Invoices as i1 ON i1.OrderID = p2.OrderedOuters
INNER JOIN Application.DeliveryMethods as d1 ON d1.DeliveryMethodID = p1.DeliveryMethodID
INNER JOIN Warehouse.StockItems as ws ON ws.StockItemID = p2.StockItemID
where IsOrderFinalized = 1 and DATEPART(YYYY,LastReceiptDate) = 2014  and (DeliveryMethodName like 'Post' or DeliveryMethodName like 'Road Freight')

--�5. 10 ��������� �� ���� ������ � ������ ������� � ������ ����������, ������� ������� �����.
select StockItemName as [�����], 
	   CustomerName as [����������], 
	   FullName as [��������],
	   Quantity as [����������],
	   i2.ExtendedPrice as [��������� ����],
	   ConfirmedDeliveryTime as [���� �������]
from Sales.Invoices as i1 Inner JOIN Sales.InvoiceLines as i2 ON i1.InvoiceID = i2.InvoiceID
INNER JOIN Sales.Orders as o1 ON i1.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as w1 on w1.StockItemID = i2.StockItemID
INNER JOIN Sales.Customers as c1 ON c1.CustomerID = i1.CustomerID
INNER JOIN [Application].People as ap1 on ap1.PersonID = i1.SalespersonPersonID
where (ConfirmedDeliveryTime is not null)
Order BY [���� �������] desc
 OFFSET 0 ROWS
 FETCH NEXT 10 ROWS ONLY

 --�6 ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g.
select c1.CustomerID as [ID ����������], CustomerName as [����������], c1.PhoneNumber as [���������� �����], StockItemName as [�������� ������], i2.Quantity as [����������], i2.ExtendedPrice as [��������� ����]
from Sales.Customers as c1 
INNER JOIN Sales.Orders as o1 ON o1.CustomerID = c1.CustomerID
INNER JOIN Sales.OrderLines as o2 ON o2.OrderID = o1.OrderID
INNER JOIN Warehouse.StockItems as s1 ON s1.StockItemID = o2.StockItemID
INNER JOIN Sales.Invoices as i1 ON i1.OrderID = o1.OrderID
INNER JOIN Sales.InvoiceLines as i2 ON i2.InvoiceID = i1.InvoiceID
where StockItemName like '%Chocolate frogs 250g%'