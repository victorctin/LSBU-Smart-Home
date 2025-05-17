-- Query(a): Clients with most and least expresive installations

--- Write a query to show details of clients, their property location(s) and the total value of 
--- Smart Home designs installed, specifically for those clients who have made the most expensive and the least expensive total values.

WITH ClientDesignCosts AS ( SELECT 
c.ClientID, 
c.FirstName, 
c.LastName, 
c.Email, 
b.Address AS PropertyLocation, 
SUM(i.Amount) AS TotalInstallationValue 
FROM Clients c 
INNER JOIN ClientBuildings cb ON c.ClientID = cb.ClientID 
INNER JOIN Buildings b ON cb.BuildingID = b.BuildingID 
INNER JOIN Designs d ON b.BuildingID = d.BuildingID 
INNER JOIN Invoices i ON c.ClientID = i.ClientID AND d.DesignID = i.DesignID 
GROUP BY c.ClientID, c.FirstName, c.LastName, c.Email, b.Address 
), 
ClientTotals AS ( 
SELECT ClientID, FirstName, LastName, 
Email, SUM(TotalInstallationValue) AS OverallTotal 
FROM ClientDesignCosts GROUP BY ClientID, FirstName, LastName, Email 
), 
Extremes AS ( 
SELECT MIN(OverallTotal) AS MinTotal, MAX(OverallTotal) AS MaxTotal 
FROM ClientTotals 
) 
SELECT 
cdc.ClientID, 
cdc.FirstName, 
cdc.LastName, 
cdc.Email, 
cdc.PropertyLocation, 
cdc.TotalInstallationValue 
FROM ClientDesignCosts cdc  
INNER JOIN ClientTotals ct ON cdc.ClientID = ct.ClientID 
INNER JOIN Extremes e ON ct.OverallTotal = e.MinTotal OR ct.OverallTotal = e.MaxTotal 
ORDER BY ct.OverallTotal DESC, cdc.ClientID; 


--- This is important for LSBU sales and customers relationship team as it helps them identify who their premium clients are and who might be less engaged, requiring 
-- marketing attention


-- Query(b) Wifi product order status by supplier

--- Query to calculate individual totals for the number of complete, incomplete and cancelled WiFi product orders from each of its suppliers. 


SELECT 
s.SupplierID, 
s.SupplierName, 
SUM(CASE WHEN o.Status = 'Complete' THEN 1 ELSE 0 END) AS Total_Complete, 
SUM(CASE WHEN o.Status = 'Incomplete' THEN 1 ELSE 0 END) AS Total_Incomplete, 
SUM(CASE WHEN o.Status = 'Cancelled' THEN 1 ELSE 0 END) AS Total_Cancelled 
FROM Suppliers s 
INNER JOIN SupplierOrders o ON s.SupplierID = o.SupplierID 
WHERE o.IsWiFi = 1 
GROUP BY s.SupplierID, s.SupplierName 
ORDER BY s.SupplierID; 

--  this is valuable for procurement managers to evaluate supplier reliability and take corrective actions


--- Query(c) Available specialist staff for booking

----- Query to find the details of specialist staff who are available for booking onto installation jobs this week. 

SELECT StaffID, FirstName, LastName, Expertise, MobileNumber, Email 
FROM Staff 
WHERE IsAvailable = 1 ORDER BY StaffID;

-- this helps LSBU planners quickly identify who is available without manually going through schedules


--- Query(d) Trigger to prevent double booking 

----Implement using triggers and/or stored procedures automatic prevention of double booking of specialist staff during the installation booking process. 

--- In this part of the project, I will demonstrate the implementation of a business rule through a trigger. 
--- The rule I want to enforce is that a specialist staff member should not be booked for more than one installation at the same time. 
--- This will help the company prevent double-booking of staff members, which is essential for smooth installation scheduling and resource management

--- I have created a trigger called trg_Prevent_DoubleBooking on the InstallationStaff table. 
--- This trigger automatically checks whether the staff being booked is currently available.
--- If they are marked as unavailable, the trigger will reject the booking and raise an error message.

CREATE TRIGGER trg_Prevent_DoubleBooking 
ON InstallationStaff 
INSTEAD OF INSERT 
AS 
BEGIN 
IF EXISTS ( 
SELECT 1 
FROM inserted i 
JOIN Staff s ON i.StaffID = s.StaffID 
WHERE s.IsAvailable = 0 
) 
BEGIN 
RAISERROR('Staff member is currently unavailable and cannot be booked.', 16, 1); 
ROLLBACK; 
END 
ELSE 
BEGIN 
INSERT INTO InstallationStaff (InstallationStaffID, InstallationID, StaffID, SensorID, EquipmentID, ControllerID, 
QuantityInstalled) 
SELECT InstallationStaffID, InstallationID, StaffID, SensorID, EquipmentID, ControllerID, QuantityInstalled 
FROM inserted; 
UPDATE Staff 
SET IsAvailable = 0 
WHERE StaffID IN (SELECT StaffID FROM inserted); 
END 
END; 


---- Testing the Trigger: Currently we have 3 staff available for booking, let’s take StaffID “2” for further steps.

SELECT * FROM STAFF WHERE IsAvailable=1;

----- Next I will make a booking for StaffID “2” and try to book him again to check if it’s booked again or trigger prevent it to happen.

INSERT INTO InstallationStaff (InstallationStaffID, InstallationID, StaffID, SensorID, EquipmentID, ControllerID, QuantityInstalled)
VALUES (61, 1, 2, 'S001', NULL, NULL, 1);


----- Let’s See if the Available Status of Staff is Updated of Not:

SELECT * FROM STAFF WHERE IsAvailable=1;

----- Now you can see StaffID 2 is no more available for Booking!

----- Let’s See if We Can Book StaffID 2 Again?

INSERT INTO InstallationStaff (InstallationStaffID, InstallationID, StaffID, SensorID, EquipmentID, ControllerID, QuantityInstalled)
VALUES (62, 1, 2, 'S001', NULL, NULL, 1);


---- Trigger preventing double booking of staff, hence it is evident that trigger is working perfectly.!!!!



--- Query(e) Stored procedure for costed device list

-----Stored Procedure that can generate a complete costed device list and total cost for any installation (s) in a specified time related period. 
-----The output must also include client and device details. 
-----The procedure should be able to accept appropriate parameter values to enable dynamic search by week, month or quarter (3 months) 
-----Include appropriate attributes and totals in your report.

CREATE PROCEDURE sp_GetInstallationCostReport
@StartDate DATE,
@EndDate DATE
AS
BEGIN
SET NOCOUNT ON;
SELECT
i.InstallationID,
c.ClientID,
c.FirstName + ' ' + c.LastName AS ClientName,
b.Address AS PropertyAddress,
d.DesignName,
i.InstallationDate,
-- Sensors
s.SensorID,
s.SensorType,
isens.Quantity AS SensorQuantity,
si.UnitPrice AS SensorUnitPrice,
(isens.Quantity * si.UnitPrice) AS SensorTotalCost,
-- Equipment
e.EquipmentID,
e.EquipmentType,
iequip.Quantity AS EquipmentQuantity,
ei.UnitPrice AS EquipmentUnitPrice,
(iequip.Quantity * ei.UnitPrice) AS EquipmentTotalCost,
-- Controllers
ctrl.ControllerID,
ctrl.ControllerName,
ictrl.Quantity AS ControllerQuantity,
ci.UnitPrice AS ControllerUnitPrice,
(ictrl.Quantity * ci.UnitPrice) AS ControllerTotalCost,
-- Total Cost per Installation
COALESCE((isens.Quantity * si.UnitPrice), 0) +
COALESCE((iequip.Quantity * ei.UnitPrice), 0) +
COALESCE((ictrl.Quantity * ci.UnitPrice), 0) AS TotalDeviceCost
FROM Installations i
INNER JOIN Designs d ON i.DesignID = d.DesignID
INNER JOIN Buildings b ON i.BuildingID = b.BuildingID
INNER JOIN ClientBuildings cb ON b.BuildingID = cb.BuildingID
INNER JOIN Clients c ON cb.ClientID = c.ClientID
-- Sensors
LEFT JOIN InstallationSensors isens ON i.InstallationID = isens.InstallationID
LEFT JOIN IoTSensors s ON isens.SensorID = s.SensorID
LEFT JOIN SupplierInventory si ON si.SensorID = isens.SensorID
-- Equipment
LEFT JOIN InstallationEquipment iequip ON i.InstallationID = iequip.InstallationID
LEFT JOIN SpecialistEquipment e ON iequip.EquipmentID = e.EquipmentID
LEFT JOIN SupplierInventory ei ON ei.EquipmentID = iequip.EquipmentID
-- Controllers
LEFT JOIN InstallationControllers ictrl ON i.InstallationID = ictrl.InstallationID
LEFT JOIN Controllers ctrl ON ictrl.ControllerID = ctrl.ControllerID
LEFT JOIN SupplierInventory ci ON ci.ControllerID = ictrl.ControllerID
WHERE i.InstallationDate BETWEEN @StartDate AND @EndDate
ORDER BY i.InstallationDate, c.ClientID, i.InstallationID;
END;

--- Executing the Stored Procedure: Getting report between 2024-01-01 to 2024-03-07 (Quarterly Basis), 
--- however this stored procedure is fully dynamic for week, month, quarter, or custom range cost report.

EXEC sp_GetInstallationCostReport '2024-01-01', '2024-03-07';

--- Total Device Cost is the sum of s/e/c costs combined, automatically calculated by the stored procedure.









