--№1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers
Insert into Sales.Customers (CustomerID,
 CustomerName,
 BillToCustomerID,
 CustomerCategoryID,
 BuyingGroupID,
 PrimaryContactPersonID,
 AlternateContactPersonID,
 DeliveryMethodID,
 DeliveryCityID,
 PostalCityID,
 CreditLimit,
 AccountOpenedDate,
 StandardDiscountPercentage,
 IsStatementSent,
 IsOnCreditHold,
 PaymentDays,
 PhoneNumber,
 FaxNumber,
 DeliveryRun,
 RunPosition,
 WebsiteURL,
 DeliveryAddressLine1,
 DeliveryAddressLine2,
 DeliveryPostalCode,
 DeliveryLocation,
 PostalAddressLine1,
 PostalAddressLine2,
 PostalPostalCode,
 LastEditedBy)
 Values 
 (9995,'Test1',9995,5,Null,3261,Null,3,19881,19881,2000,'2019-05-07',0.000,0,0,7,'(206) 555-0195','(206) 555-0195',NUll,NULL,'bla bla 95','Shop 95','655 Victoria Lane',90669,NULL,'PO Box 895','Ganeshville95',90669,1),
 (9996,'Test2',9996,5,Null,3261,Null,3,19881,19881,2000,'2019-05-07',0.000,0,0,7,'(206) 555-0196','(206) 555-0196',NUll,NULL,'bla bla 96','Shop 96','656 Victoria Lane',90669,NULL,'PO Box 896','Ganeshville96',90669,1),
 (9997,'Test3',9997,5,Null,3261,Null,3,19881,19881,2000,'2019-05-07',0.000,0,0,7,'(206) 555-0197','(206) 555-0197',NUll,NULL,'bla bla 97','Shop 97','657 Victoria Lane',90669,NULL,'PO Box 897','Ganeshville97',90669,1),
 (9998,'Test4',9998,5,Null,3261,Null,3,19881,19881,2000,'2019-05-07',0.000,0,0,7,'(206) 555-0198','(206) 555-0198',NUll,NULL,'bla bla 98','Shop 98','658 Victoria Lane',90669,NULL,'PO Box 898','Ganeshville98',90669,1),
 (9999,'Test5',9999,5,Null,3261,Null,3,19881,19881,2000,'2019-05-07',0.000,0,0,7,'(206) 555-0199','(206) 555-0199',NUll,NULL,'bla bla 99','Shop 99','659 Victoria Lane',90669,NULL,'PO Box 899','Ganeshville99',90669,1)

 --№2. удалите 1 запись из Customers, которая была вами добавлена
 delete from Sales.Customers
 where CustomerName = 'Test1'

 --№3. изменить одну запись, из добавленных через UPDATE
 update Sales.Customers 
 set CustomerName = 'Darth Vader' where CustomerName = 'Test5'

 --№4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
 use WideWorldImporters
go

MERGE Sales.Customers AS target 
	USING (select TOP(15) s1.SupplierName SNAME, 
	s1.PhoneNumber SPHONENUMBER, 
	s1.FaxNumber SFAXNUMBER, 
	s1.PrimaryContactPersonID SPRIMARYCONTACTPERSONID,
	IIF(s1.DeliveryMethodID IS NULL,3,s1.DeliveryMethodID) SDELIVERYMETHODID, 
	cast(9900 + s1.SupplierID as INT) SBILLTOCUSTOMER, 
	3 as SCUSTOMERCATEGORYID, 
	s1.DeliveryCityID SDELIVERYCITYID, 
	s1.PostalCityID SPOSTALCITYID, 
	getdate() as SACCOUNTOPENEDDATE,
	0.000 as SSTANDARTDISCOUNTPERSENAGE, 
	0 as SISSTATEMENTSENT, 
	0 as SISONCREDITHOLD, 
	7 as SPAYMENTSDAYS, 
	s1.WebsiteURL SWEBSYTEURL,
	s1.DeliveryAddressLine1 SDELIVERYADRESSLINE1, 
	s1.DeliveryPostalCode SDELIVERYPOSTALCODE, 
	s1.PostalAddressLine1 SPOSTALADRESSLINE1,
	s1.PostalPostalCode SPOSTALPOSTALCODE,
	s1.LastEditedBy SLASTEDITEDBY, 
	cast(9900 + s1.SupplierID as INT) SCUSTOMERID
from Purchasing.Suppliers as s1
FULL OUTER JOIN Sales.Customers  as c1 ON s1.SupplierName = c1.CustomerName
where c1.CustomerName is NULL
		) 
		AS source (SNAME, 
		SPHONENUMBER, 
		SFAXNUMBER, 
		SPRIMARYCONTACTPERSONID, 
		SDELIVERYMETHODID,
		SBILLTOCUSTOMER,
		SCUSTOMERCATEGORYID,
		SDELIVERYCITYID,
		SPOSTALCITYID,
		SACCOUNTOPENEDDATE,
		SSTANDARTDISCOUNTPERSENAGE,
		SISSTATEMENTSENT,
		SISONCREDITHOLD,
		SPAYMENTSDAYS,
		SWEBSYTEURL,
		SDELIVERYADRESSLINE1,
		SDELIVERYPOSTALCODE,
		SPOSTALADRESSLINE1,
		SPOSTALPOSTALCODE,
		SLASTEDITEDBY,
		SCUSTOMERID) 
		ON
	 (target.CustomerName = source.SNAME) 
	WHEN MATCHED 
		THEN UPDATE SET CustomerID = source.SCUSTOMERID,
						CustomerName = source.SNAME,
						PhoneNumber = source.SPHONENUMBER,
						FaxNumber = source.SFAXNUMBER,
						PrimaryContactPersonID = source.SPRIMARYCONTACTPERSONID,
						DeliveryMethodID = source.SDELIVERYMETHODID,
						BillToCustomerID = source.SBILLTOCUSTOMER,
						CustomerCategoryID = source.SCUSTOMERCATEGORYID,
						DeliveryCityID = source.SDELIVERYCITYID,
						PostalCityID = source.SPOSTALCITYID,
						AccountOpenedDate = source.SACCOUNTOPENEDDATE,
						StandardDiscountPercentage = source.SSTANDARTDISCOUNTPERSENAGE,
						IsStatementSent = source.SISSTATEMENTSENT,
						IsOnCreditHold = source.SISONCREDITHOLD,
						PaymentDays = source.SPAYMENTSDAYS,
						WebsiteURL = source.SWEBSYTEURL,
						DeliveryAddressLine1 = source.SDELIVERYADRESSLINE1,
						DeliveryPostalCode = source.SDELIVERYPOSTALCODE,
						PostalAddressLine1 = source.SPOSTALADRESSLINE1,
						PostalPostalCode = source.SPOSTALPOSTALCODE,
						LastEditedBy = source.SLASTEDITEDBY
	WHEN NOT MATCHED 
		THEN INSERT (CustomerID,
		CustomerName, 
		PhoneNumber, 
		FaxNumber, 
		PrimaryContactPersonID, 
		DeliveryMethodID,
		BillToCustomerID,
		CustomerCategoryID,
		DeliveryCityID,
		PostalCityID,
		AccountOpenedDate,
		StandardDiscountPercentage,
		IsStatementSent,
		IsOnCreditHold,
		PaymentDays,
		WebsiteURL,
		DeliveryAddressLine1, 
		DeliveryPostalCode,
		PostalAddressLine1,
		PostalPostalCode,
		LastEditedBy) 
			VALUES (source.SCUSTOMERID,
			source.SNAME, 
			source.SPHONENUMBER, 
			source.SFAXNUMBER, 
			source.SPRIMARYCONTACTPERSONID, 
			source.SDELIVERYMETHODID,
			source.SBILLTOCUSTOMER,
			source.SCUSTOMERCATEGORYID,
			source.SDELIVERYCITYID,
			source.SPOSTALCITYID,
			source.SACCOUNTOPENEDDATE,
			source.SSTANDARTDISCOUNTPERSENAGE,
			source.SISSTATEMENTSENT,
			source.SISONCREDITHOLD,
			source.SPAYMENTSDAYS,
			source.SWEBSYTEURL,
			source.SDELIVERYADRESSLINE1,
			source.SDELIVERYPOSTALCODE,
			source.SPOSTALADRESSLINE1,
			source.SPOSTALPOSTALCODE,
			source.SLASTEDITEDBY) 
	OUTPUT deleted.*, $action, inserted.*;


--№5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

use WideWorldImporters

exec sp_configure 'show advanced options', 1;
GO

RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;  
GO  


RECONFIGURE;  
GO  

select @@SERVERNAME


exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Orders" out "D:\Query\Orders_test.txt" -T -w -t"@nbsp&" -S DESKTOP-MTJP0O1\SQLEXPRESSTEACH'

drop table Sales.Orders_test

create table Sales.Orders_test(	
	OrderID int Not Null,
	CustomerID int Not Null,
	SalespersonPersonID int Not Null,
	PickedByPersonID int null,
	ContactPersonID int Not Null,
	BackorderOrderID int null,
	OrderDate date Not null,
	ExpectedDeliveryDate date not null,
	CustomerPurchaseOrderNumber nvarchar(20) null,
	IsUndersupplyBackordered bit not null,
	Comments nvarchar(max) null,
	DeliveryInstructions nvarchar(max) null,
	InternalComments nvarchar(max) null,
	PickingCompletedWhen datetime2(7) null,
	LastEditedBy int not null,
	LastEditedWhen datetime2(7) null
)

truncate table [WideWorldImporters].Sales.Orders_test

BULK INSERT [WideWorldImporters].Sales.Orders_test
				   FROM "D:\Query\Orders_test.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@nbsp&',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );


select count(*)
from Sales.Orders_test

select count(*)
from Sales.Orders