-- Create the database
CREATE DATABASE LSBU_SmartHome;
GO

USE LSBU_SmartHome;
GO

-- Clients table: Stores information about clients
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber NVARCHAR(20),
    Address NVARCHAR(255)
);

-- Buildings table: Stores information about buildings owned by clients
CREATE TABLE Buildings (
    BuildingID INT PRIMARY KEY,
    Address NVARCHAR(255) NOT NULL,
    BuildingType NVARCHAR(50),
    CONSTRAINT UQ_Building_Address UNIQUE (Address)
);

-- ClientBuildings table: Junction table for many-to-many relationship between Clients and Buildings
CREATE TABLE ClientBuildings (
    ClientID INT,
    BuildingID INT,
    OwnershipPercentage DECIMAL(5,2),
    PRIMARY KEY (ClientID, BuildingID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE CASCADE,
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID) ON DELETE CASCADE,
    CONSTRAINT CHK_OwnershipPercentage CHECK (OwnershipPercentage BETWEEN 0 AND 100)
);

-- Designs table: Stores unique smart home designs
CREATE TABLE Designs (
    DesignID INT PRIMARY KEY,
    BuildingID INT NOT NULL,
    DesignName NVARCHAR(100) NOT NULL,
    DesignDate DATE NOT NULL,
    Description NVARCHAR(255),
    IsLSBUInstalled BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
    CONSTRAINT UQ_Design_Building UNIQUE (BuildingID, DesignName)
);

-- IoTSensors table: Stores types of IoT sensors available
CREATE TABLE IoTSensors (
    SensorID NVARCHAR(10) PRIMARY KEY,
    SensorType NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255),
    CONSTRAINT UQ_SensorType UNIQUE (SensorType)
);

-- SpecialistEquipment table: Stores types of specialist equipment (e.g., HD-CCTV)
CREATE TABLE SpecialistEquipment (
    EquipmentID NVARCHAR(10) PRIMARY KEY,
    EquipmentType NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255),
    CONSTRAINT UQ_EquipmentType UNIQUE (EquipmentType)
);

-- Controllers table: Stores controller devices in each building
CREATE TABLE Controllers (
    ControllerID NVARCHAR(10) PRIMARY KEY,
    BuildingID INT NOT NULL,
    ControllerName NVARCHAR(50) NOT NULL,
    Protocol NVARCHAR(50) NOT NULL DEFAULT 'ZigBee',
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
    CONSTRAINT UQ_Controller_Building UNIQUE (BuildingID, ControllerName)
);

-- SensorControllerCompatibility table: Tracks compatibility between sensors and controllers
CREATE TABLE SensorControllerCompatibility (
    SensorID NVARCHAR(10),
    ControllerID NVARCHAR(10),
    CompatibilityNotes NVARCHAR(255),
    PRIMARY KEY (SensorID, ControllerID),
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID)
);

-- DesignSensors table: Junction table for many-to-many relationship between Designs and IoTSensors
CREATE TABLE DesignSensors (
    DesignID INT,
    SensorID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (DesignID, SensorID),
    FOREIGN KEY (DesignID) REFERENCES Designs(DesignID) ON DELETE CASCADE,
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    CONSTRAINT CHK_Quantity CHECK (Quantity > 0)
);

-- DesignEquipment table: Junction table for many-to-many relationship between Designs and SpecialistEquipment
CREATE TABLE DesignEquipment (
    DesignID INT,
    EquipmentID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (DesignID, EquipmentID),
    FOREIGN KEY (DesignID) REFERENCES Designs(DesignID) ON DELETE CASCADE,
    FOREIGN KEY (EquipmentID) REFERENCES SpecialistEquipment(EquipmentID),
    CONSTRAINT CHK_EquipmentQuantity CHECK (Quantity > 0)
);

-- DesignControllers table: Junction table for many-to-many relationship between Designs and Controllers
CREATE TABLE DesignControllers (
    DesignID INT,
    ControllerID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (DesignID, ControllerID),
    FOREIGN KEY (DesignID) REFERENCES Designs(DesignID) ON DELETE CASCADE,
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID),
    CONSTRAINT CHK_ControllerQuantity CHECK (Quantity > 0)
);

-- Suppliers table: Stores supplier information
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(100),
    ContactPhone NVARCHAR(20),
    Website NVARCHAR(255),
    CONSTRAINT UQ_SupplierName UNIQUE (SupplierName)
);

-- SupplierInventory table: Tracks items supplied by suppliers with separate columns for each type
CREATE TABLE SupplierInventory (
    SupplierInventoryID INT PRIMARY KEY,
    SupplierID INT NOT NULL,
    SensorID NVARCHAR(10) NULL,
    EquipmentID NVARCHAR(10) NULL,
    ControllerID NVARCHAR(10) NULL,
    StockLevel INT NOT NULL DEFAULT 0,
    UnitPrice DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE CASCADE,
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    FOREIGN KEY (EquipmentID) REFERENCES SpecialistEquipment(EquipmentID),
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID),
    CONSTRAINT CHK_StockLevel CHECK (StockLevel >= 0),
    CONSTRAINT CHK_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CHK_OneItemType CHECK (
        (SensorID IS NOT NULL AND EquipmentID IS NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NOT NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NULL AND ControllerID IS NOT NULL)
    )
);

-- SupplierOrders table: Tracks orders from suppliers
CREATE TABLE SupplierOrders (
    OrderID INT PRIMARY KEY,
    SupplierID INT NOT NULL,
    SensorID NVARCHAR(10) NULL,
    EquipmentID NVARCHAR(10) NULL,
    ControllerID NVARCHAR(10) NULL,
    OrderDate DATE NOT NULL DEFAULT GETDATE(),
    QuantityOrdered INT NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    IsWiFi BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    FOREIGN KEY (EquipmentID) REFERENCES SpecialistEquipment(EquipmentID),
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID),
    CONSTRAINT CHK_OneProduct CHECK (
        (SensorID IS NOT NULL AND EquipmentID IS NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NOT NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NULL AND ControllerID IS NOT NULL)
    ),
    CONSTRAINT CHK_QuantityOrdered CHECK (QuantityOrdered > 0),
    CONSTRAINT CHK_Status CHECK (Status IN ('Complete', 'Incomplete', 'Cancelled'))
);

-- Staff table: Stores staff information
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Expertise NVARCHAR(100),
    MobileNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    IsAvailable BIT NOT NULL DEFAULT 1 
);

-- Teams table: Stores team information
CREATE TABLE Teams (
    TeamID INT PRIMARY KEY,
    TeamName NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_TeamName UNIQUE (TeamName)
);

-- TeamMembers table: Junction table for many-to-many relationship between Teams and Staff
CREATE TABLE TeamMembers (
    TeamID INT,
    StaffID INT,
    PRIMARY KEY (TeamID, StaffID),
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID) ON DELETE CASCADE,
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID) ON DELETE CASCADE
);

-- Installations table: Tracks installation events
CREATE TABLE Installations (
    InstallationID INT PRIMARY KEY,
    DesignID INT NOT NULL,
    BuildingID INT NOT NULL,
    TeamID INT NOT NULL,
    InstallationDate DATE NOT NULL,
    TotalInstallationCost DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (DesignID) REFERENCES Designs(DesignID),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID)
);

-- InstallationSensors table: Tracks sensors installed in each installation
CREATE TABLE InstallationSensors (
    InstallationID INT,
    SensorID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (InstallationID, SensorID),
    FOREIGN KEY (InstallationID) REFERENCES Installations(InstallationID) ON DELETE CASCADE,
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    CONSTRAINT CHK_SensorQuantity CHECK (Quantity > 0)
);

-- InstallationEquipment table: Tracks equipment installed in each installation
CREATE TABLE InstallationEquipment (
    InstallationID INT,
    EquipmentID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (InstallationID, EquipmentID),
    FOREIGN KEY (InstallationID) REFERENCES Installations(InstallationID) ON DELETE CASCADE,
    FOREIGN KEY (EquipmentID) REFERENCES SpecialistEquipment(EquipmentID),
    CONSTRAINT CHK_EquipmentOfQuantity CHECK (Quantity > 0)
);

-- InstallationControllers table: Tracks controllers installed in each installation
CREATE TABLE InstallationControllers (
    InstallationID INT,
    ControllerID NVARCHAR(10),
    Quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (InstallationID, ControllerID),
    FOREIGN KEY (InstallationID) REFERENCES Installations(InstallationID) ON DELETE CASCADE,
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID),
    CONSTRAINT CHK_Controller_Quantity CHECK (Quantity > 0)
);

-- InstallationStaff table: Tracks which staff installed each component
CREATE TABLE InstallationStaff (
    InstallationStaffID INT PRIMARY KEY,
    InstallationID INT NOT NULL,
    StaffID INT NOT NULL,
    SensorID NVARCHAR(10) NULL,
    EquipmentID NVARCHAR(10) NULL,
    ControllerID NVARCHAR(10) NULL,
    QuantityInstalled INT NOT NULL DEFAULT 1,
    FOREIGN KEY (InstallationID) REFERENCES Installations(InstallationID) ON DELETE CASCADE,
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID),
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    FOREIGN KEY (EquipmentID) REFERENCES SpecialistEquipment(EquipmentID),
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID),
    CONSTRAINT CHK_OneComponent CHECK (
        (SensorID IS NOT NULL AND EquipmentID IS NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NOT NULL AND ControllerID IS NULL) OR
        (SensorID IS NULL AND EquipmentID IS NULL AND ControllerID IS NOT NULL)
    ),
    CONSTRAINT CHK_QuantityInstalled CHECK (QuantityInstalled > 0)
);

-- SensorReadings table: Stores sensor data locally in the controller
CREATE TABLE SensorReadings (
    ReadingID BIGINT PRIMARY KEY,
    SensorID NVARCHAR(10) NOT NULL,
    ControllerID NVARCHAR(10) NOT NULL,
    ReadingValue NVARCHAR(50),
    ReadingTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (SensorID) REFERENCES IoTSensors(SensorID),
    FOREIGN KEY (ControllerID) REFERENCES Controllers(ControllerID)
);

-- Invoices table: Stores billing information
CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY,
    ClientID INT NOT NULL,
    DesignID INT,
    InvoiceDate DATE NOT NULL DEFAULT GETDATE(),
    Amount DECIMAL(10,2) NOT NULL,
    DueDate DATE NOT NULL DEFAULT DATEADD(DAY, 28, GETDATE()), 
    PaymentMethod NVARCHAR(50),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (DesignID) REFERENCES Designs(DesignID),
    CONSTRAINT CHK_Amount CHECK (Amount > 0),
    CONSTRAINT CHK_DueDate CHECK (DueDate >= InvoiceDate AND DueDate <= DATEADD(DAY, 28, InvoiceDate))
);


-- Data Insertion

INSERT INTO Clients (ClientID, FirstName, LastName, Email, PhoneNumber, Address)
VALUES
    (1, 'James', 'Carter', 'james.carter84@gmail.com', '07712 345678', '14 Oakwood Lane, Leeds, LS7 2PX'),
    (2, 'Sophie', 'Harrington', 'sophie.harrington@outlook.com', '07983 901234', '27 Elm Grove, Bristol, BS8 1TL'),
    (3, 'Liam', 'Patel', 'liam.patel92@yahoo.co.uk', '07850 567890', '5 Birch Road, Manchester, M20 4AN'),
    (4, 'Emma', 'Thompson', 'emma.t.work@gmail.com', '07496 123456', '42 Willow Crescent, London, SW9 0EY'),
    (5, 'Noah', 'Bennett', 'noah.bennett1980@hotmail.com', '07789 234567', '19 Maple Avenue, Birmingham, B15 2UG'),
    (6, 'Olivia', 'Nguyen', 'olivia.n@icloud.com', '07912 678901', '33 Cedar Close, Edinburgh, EH12 7QD'),
    (7, 'Ethan', 'Mitchell', 'e.mitchell73@gmail.com', '07834 890123', '8 Pine Street, Cardiff, CF24 3HL'),
    (8, 'Ava', 'Rodriguez', 'ava.rodriguez.art@yahoo.com', '07701 345890', '61 Ashwood Drive, Glasgow, G12 0PJ'),
    (9, 'William', 'Hughes', 'will.hughes@live.co.uk', '07458 901234', '12 Chestnut Way, Sheffield, S3 7BX'),
    (10, 'Isabella', 'Walker', 'isabella.walker99@outlook.com', '07967 123456', '25 Sycamore Road, Nottingham, NG7 6HF'),
    (11, 'Mason', 'Khan', 'mason.khan.work@gmail.com', '07823 567890', '3 Laurel Gardens, Liverpool, L17 8QP'),
    (12, 'Mia', 'Fleming', 'mia.fleming88@yahoo.com', '07745 678901', '47 Hazel Lane, Newcastle upon Tyne, NE4 9YU'),
    (13, 'Jacob', 'O’Connor', 'jacob.oconnor@icloud.com', '07412 234567', '9 Spruce Terrace, Brighton, BN1 5RT'),
    (14, 'Charlotte', 'Ellis', 'charlotte.ellis21@hotmail.com', '07989 345678', '38 Poplar Avenue, Oxford, OX4 2LP'),
    (15, 'Logan', 'Stewart', 'logan.stewart.pro@gmail.com', '07867 890123', '22 Acacia Road, Cambridge, CB5 8PY'),
    (16, 'Amelia', 'Morales', 'amelia.morales@outlook.com', '07723 901234', '56 Birchfield Drive, Southampton, SO15 4DX'),
    (17, 'Lucas', 'Pearson', 'lucas.pearson77@yahoo.co.uk', '07489 123456', '17 Elmwood Crescent, York, YO31 9LJ'),
    (18, 'Harper', 'Jensen', 'harper.jensen.art@gmail.com', '07901 567890', '31 Oakfield Road, Exeter, EX4 1BA'),
    (19, 'Elijah', 'Brooks', 'elijah.brooks@live.com', '07812 678901', '4 Willowbank Close, Belfast, BT5 6JN'),
    (20, 'Grace', 'Dixon', 'grace.dixon1995@icloud.com', '07756 234567', '50 Cedarwood Lane, Norwich, NR2 3TF');

INSERT INTO Buildings (BuildingID, Address, BuildingType)
VALUES
    (1, '14 Oakwood Lane, Leeds, LS7 2PX', 'House'),
    (2, '27 Elm Grove, Bristol, BS8 1TL', 'House'),
    (3, '5 Birch Road, Manchester, M20 4AN', 'Apartment'),
    (4, '42 Willow Crescent, London, SW9 0EY', 'Apartment'),
    (5, '19 Maple Avenue, Birmingham, B15 2UG', 'House'),
    (6, '33 Cedar Close, Edinburgh, EH12 7QD', 'House'),
    (7, '8 Pine Street, Cardiff, CF24 3HL', 'Apartment'),
    (8, '61 Ashwood Drive, Glasgow, G12 0PJ', 'House'),
    (9, '12 Chestnut Way, Sheffield, S3 7BX', 'Office'),
    (10, '25 Sycamore Road, Nottingham, NG7 6HF', 'House'),
    (11, '3 Laurel Gardens, Liverpool, L17 8QP', 'Apartment'),
    (12, '47 Hazel Lane, Newcastle upon Tyne, NE4 9YU', 'Mixed-Use'),
    (13, '9 Spruce Terrace, Brighton, BN1 5RT', 'House'),
    (14, '38 Poplar Avenue, Oxford, OX4 2LP', 'Office'),
    (15, '22 Acacia Road, Cambridge, CB5 8PY', 'House'),
    (16, '56 Birchfield Drive, Southampton, SO15 4DX', 'Warehouse'),
    (17, '17 Elmwood Crescent, York, YO31 9LJ', 'Apartment'),
    (18, '31 Oakfield Road, Exeter, EX4 1BA', 'Retail'),
    (19, '4 Willowbank Close, Belfast, BT5 6JN', 'House'),
    (20, '50 Cedarwood Lane, Norwich, NR2 3TF', 'Mixed-Use');

INSERT INTO ClientBuildings (ClientID, BuildingID, OwnershipPercentage)
VALUES
    (1, 1, 100.00),
    (2, 2, 100.00),
    (3, 3, 75.00),
    (4, 4, 100.00),
    (5, 5, 100.00),
    (6, 6, 50.00),
    (7, 7, 100.00),
    (8, 8, 100.00),
    (9, 9, 100.00),
    (10, 10, 80.00),
    (11, 11, 100.00),
    (12, 12, 60.00),
    (13, 13, 100.00),
    (14, 14, 100.00),
    (15, 15, 100.00),
    (16, 16, 25.00),
    (17, 17, 100.00),
    (18, 18, 100.00),
    (19, 19, 90.00),
    (20, 20, 70.00);

INSERT INTO Designs (DesignID, BuildingID, DesignName, DesignDate, Description, IsLSBUInstalled)
VALUES
    (1, 1, 'Smart Leeds Home', '2023-05-12', 'Energy-efficient home setup', 1),
    (2, 2, 'Bristol Eco Flat', '2023-07-19', 'Sustainable living design', 0),
    (3, 3, 'Manchester Urban', '2023-09-25', 'Compact smart apartment', 1),
    (4, 4, 'London Modern', '2023-11-03', 'High-tech urban living', 1),
    (5, 5, 'Birmingham Family', '2024-01-15', 'Family-oriented smart home', 0),
    (6, 6, 'Edinburgh Classic', '2024-03-22', 'Traditional with smart upgrades', 1),
    (7, 7, 'Cardiff Studio', '2024-04-10', 'Minimalist smart design', 0),
    (8, 8, 'Glasgow Retreat', '2024-05-18', 'Cozy smart home layout', 1),
    (9, 9, 'Sheffield Workspace', '2024-06-01', 'Smart office solution', 1),
    (10, 10, 'Nottingham Green', '2024-07-07', 'Eco-friendly home design', 0),
    (11, 11, 'Liverpool Compact', '2024-08-14', 'Small apartment automation', 1),
    (12, 12, 'Newcastle Hybrid', '2024-09-20', 'Mixed-use smart setup', 0),
    (13, 13, 'Brighton Coastal', '2024-10-05', 'Seaside smart home', 1),
    (14, 14, 'Oxford Business', '2024-11-12', 'Office automation design', 1),
    (15, 15, 'Cambridge Scholar', '2024-12-01', 'Academic home setup', 0),
    (16, 16, 'Southampton Storage', '2025-01-09', 'Smart warehouse system', 1),
    (17, 17, 'York Heritage', '2025-02-15', 'Historical home with tech', 0),
    (18, 18, 'Exeter Retail', '2025-03-03', 'Smart shop layout', 1),
    (19, 19, 'Belfast Cosy', '2025-03-20', 'Warm smart home design', 0),
    (20, 20, 'Norwich Blend', '2025-03-27', 'Mixed-use modern design', 1);

INSERT INTO IoTSensors (SensorID, SensorType, Description)
VALUES
    ('S001', 'Temperature', 'Measures room temperature'),
    ('S002', 'Humidity', 'Tracks moisture levels'),
    ('S003', 'Motion', 'Detects movement in area'),
    ('S004', 'Smoke', 'Alerts for smoke detection'),
    ('S005', 'CO2', 'Monitors carbon dioxide levels'),
    ('S006', 'Light', 'Measures ambient light intensity'),
    ('S007', 'Door', 'Detects door open/close'),
    ('S008', 'Window', 'Monitors window status'),
    ('S009', 'Pressure', 'Measures air pressure'),
    ('S010', 'Water Leak', 'Detects water leaks'),
    ('S011', 'Noise', 'Records sound levels'),
    ('S012', 'Gas', 'Detects gas leaks'),
    ('S013', 'Vibration', 'Senses structural vibrations'),
    ('S014', 'Occupancy', 'Tracks room occupancy'),
    ('S015', 'Air Quality', 'Monitors pollutants'),
    ('S016', 'Heat', 'Detects high temperatures'),
    ('S017', 'Flood', 'Alerts for flooding'),
    ('S018', 'Proximity', 'Detects nearby objects'),
    ('S019', 'Energy', 'Measures power consumption'),
    ('S020', 'Tilt', 'Detects angle changes');

INSERT INTO SpecialistEquipment (EquipmentID, EquipmentType, Description)
VALUES
    ('E001', 'HD CCTV', 'High-definition security camera'),
    ('E002', 'Smart Lock', 'Keyless entry system'),
    ('E003', 'Thermostat', 'Programmable temperature control'),
    ('E004', 'Doorbell Cam', 'Video-enabled doorbell'),
    ('E005', 'Floodlight', 'Motion-activated outdoor light'),
    ('E006', 'Speaker', 'Smart audio system'),
    ('E007', 'Smoke Alarm', 'Connected smoke detector'),
    ('E008', 'Window Lock', 'Automated window security'),
    ('E009', 'Motion Light', 'Indoor motion-sensing light'),
    ('E010', 'Air Purifier', 'Smart air quality device'),
    ('E011', 'IP Camera', 'Internet protocol surveillance'),
    ('E012', 'Smart Plug', 'Remote power control'),
    ('E013', 'Heat Pump', 'Efficient heating system'),
    ('E014', 'Blinds', 'Automated window blinds'),
    ('E015', 'Leak Detector', 'Water leak alert system'),
    ('E016', 'Garage Opener', 'Smart garage door control'),
    ('E017', 'Video Monitor', 'Indoor video display'),
    ('E018', 'Alarm Panel', 'Central security control'),
    ('E019', 'Solar Panel', 'Energy generation unit'),
    ('E020', 'Fan', 'Smart ventilation device');

INSERT INTO Controllers (ControllerID, BuildingID, ControllerName, Protocol)
VALUES
    ('C001', 1, 'Leeds Hub', 'ZigBee'),
    ('C002', 2, 'Bristol Core', 'WiFi'),
    ('C003', 3, 'Manchester Link', 'ZigBee'),
    ('C004', 4, 'London Node', 'WiFi'),
    ('C005', 5, 'Birmingham Base', 'ZigBee'),
    ('C006', 6, 'Edinburgh Control', 'ZigBee'),
    ('C007', 7, 'Cardiff Unit', 'WiFi'),
    ('C008', 8, 'Glasgow Gateway', 'ZigBee'),
    ('C009', 9, 'Sheffield Station', 'WiFi'),
    ('C010', 10, 'Nottingham Hub', 'ZigBee'),
    ('C011', 11, 'Liverpool Core', 'WiFi'),
    ('C012', 12, 'Newcastle Link', 'ZigBee'),
    ('C013', 13, 'Brighton Node', 'WiFi'),
    ('C014', 14, 'Oxford Base', 'ZigBee'),
    ('C015', 15, 'Cambridge Control', 'WiFi'),
    ('C016', 16, 'Southampton Unit', 'ZigBee'),
    ('C017', 17, 'York Gateway', 'WiFi'),
    ('C018', 18, 'Exeter Station', 'ZigBee'),
    ('C019', 19, 'Belfast Hub', 'WiFi'),
    ('C020', 20, 'Norwich Core', 'ZigBee');

INSERT INTO SensorControllerCompatibility (SensorID, ControllerID, CompatibilityNotes)
VALUES
    ('S001', 'C001', 'Stable with ZigBee v3.0'),
    ('S002', 'C002', 'WiFi requires firmware 2.1'),
    ('S003', 'C003', 'Optimized for ZigBee range'),
    ('S004', 'C004', 'WiFi pairing tested'),
    ('S005', 'C005', 'ZigBee low latency'),
    ('S006', 'C006', 'Supports ZigBee mesh'),
    ('S007', 'C007', 'WiFi signal strength verified'),
    ('S008', 'C008', 'ZigBee reliable in multi-room'),
    ('S009', 'C009', 'WiFi needs strong signal'),
    ('S010', 'C010', 'ZigBee water detection compatible'),
    ('S011', 'C011', 'WiFi audio sync confirmed'),
    ('S012', 'C012', 'ZigBee gas alert tested'),
    ('S013', 'C013', 'WiFi vibration range limited'),
    ('S014', 'C014', 'ZigBee occupancy precise'),
    ('S015', 'C015', 'WiFi air quality stable'),
    ('S016', 'C016', 'ZigBee heat threshold set'),
    ('S017', 'C017', 'WiFi flood alert functional'),
    ('S018', 'C018', 'ZigBee proximity accurate'),
    ('S019', 'C019', 'WiFi energy data smooth'),
    ('S020', 'C020', 'ZigBee tilt detection reliable');

INSERT INTO DesignSensors (DesignID, SensorID, Quantity)
VALUES
    (1, 'S001', 2),
    (2, 'S002', 1),
    (3, 'S003', 3),
    (4, 'S004', 1),
    (5, 'S005', 2),
    (6, 'S006', 1),
    (7, 'S007', 2),
    (8, 'S008', 1),
    (9, 'S009', 1),
    (10, 'S010', 2),
    (11, 'S011', 1),
    (12, 'S012', 3),
    (13, 'S013', 1),
    (14, 'S014', 2),
    (15, 'S015', 1),
    (16, 'S016', 2),
    (17, 'S017', 1),
    (18, 'S018', 1),
    (19, 'S019', 2),
    (20, 'S020', 1);

INSERT INTO DesignEquipment (DesignID, EquipmentID, Quantity)
VALUES
    (1, 'E001', 2),
    (2, 'E002', 1),
    (3, 'E003', 1),
    (4, 'E004', 1),
    (5, 'E005', 2),
    (6, 'E006', 1),
    (7, 'E007', 1),
    (8, 'E008', 2),
    (9, 'E009', 1),
    (10, 'E010', 1),
    (11, 'E011', 2),
    (12, 'E012', 1),
    (13, 'E013', 1),
    (14, 'E014', 2),
    (15, 'E015', 1),
    (16, 'E016', 1),
    (17, 'E017', 1),
    (18, 'E018', 1),
    (19, 'E019', 2),
    (20, 'E020', 1);

INSERT INTO DesignControllers (DesignID, ControllerID, Quantity)
VALUES
    (1, 'C001', 1),
    (2, 'C002', 1),
    (3, 'C003', 1),
    (4, 'C004', 1),
    (5, 'C005', 1),
    (6, 'C006', 1),
    (7, 'C007', 1),
    (8, 'C008', 1),
    (9, 'C009', 1),
    (10, 'C010', 1),
    (11, 'C011', 1),
    (12, 'C012', 1),
    (13, 'C013', 1),
    (14, 'C014', 1),
    (15, 'C015', 1),
    (16, 'C016', 1),
    (17, 'C017', 1),
    (18, 'C018', 1),
    (19, 'C019', 1),
    (20, 'C020', 1);

INSERT INTO Suppliers (SupplierID, SupplierName, ContactEmail, ContactPhone, Website)
VALUES
    (1, 'TechTrend Innovations', 'sales@techtrend.co.uk', '020 7946 0123', 'www.techtrend.co.uk'),
    (2, 'SmartHome Solutions', 'info@smarthomesol.co.uk', '0161 234 5678', 'www.smarthomesol.co.uk'),
    (3, 'EcoTech Supplies', 'contact@ecotechsupplies.com', '0113 456 7890', 'www.ecotechsupplies.com'),
    (4, 'SecureSys Ltd', 'support@securesys.co.uk', '029 2087 6543', 'www.securesys.co.uk'),
    (5, 'BrightFuture Tech', 'enquiries@brightfuturetech.co.uk', '0131 555 1234', 'www.brightfuturetech.co.uk'),
    (6, 'GreenWave Systems', 'sales@greenwavesystems.com', '0141 332 9988', 'www.greenwavesystems.com'),
    (7, 'IoT Dynamics', 'info@iotdynamics.co.uk', '0191 487 3210', 'www.iotdynamics.co.uk'),
    (8, 'HomeGuard Innovations', 'contact@homeguard.co.uk', '0115 987 6543', 'www.homeguard.co.uk'),
    (9, 'UrbanTech Distributors', 'orders@urbantechdist.co.uk', '0151 345 6789', 'www.urbantechdist.co.uk'),
    (10, 'NexGen Supplies', 'support@nexgensupplies.co.uk', '0121 555 4321', 'www.nexgensupplies.co.uk'),
    (11, 'SafeZone Tech', 'sales@safezonetech.com', '020 8123 4567', 'www.safezonetech.com'),
    (12, 'SmartLink Providers', 'info@smartlinkprov.co.uk', '023 8076 5432', 'www.smartlinkprov.co.uk'),
    (13, 'EcoLiving Systems', 'enquiries@ecolivingsys.co.uk', '01865 123 987', 'www.ecolivingsys.co.uk'),
    (14, 'CitySmart Solutions', 'contact@citysmartsol.co.uk', '01223 456 789', 'www.citysmartsol.co.uk'),
    (15, 'TechSafe Supplies', 'orders@techsafe.co.uk', '028 9045 6789', 'www.techsafe.co.uk'),
    (16, 'FutureProof Tech', 'sales@futureprooftech.co.uk', '01603 234 567', 'www.futureprooftech.co.uk'),
    (17, 'HomeSync Distributors', 'info@homesyncdist.co.uk', '01392 876 543', 'www.homesyncdist.co.uk'),
    (18, 'GreenTech Partners', 'support@greentechpartners.co.uk', '01904 321 987', 'www.greentechpartners.co.uk'),
    (19, 'SmartCore Systems', 'enquiries@smartcoresys.co.uk', '0114 567 8901', 'www.smartcoresys.co.uk'),
    (20, 'VitalTech Ltd', 'contact@vitaltech.co.uk', '01752 123 456', 'www.vitaltech.co.uk');

INSERT INTO SupplierInventory (SupplierInventoryID, SupplierID, SensorID, EquipmentID, ControllerID, StockLevel, UnitPrice)
VALUES
    (1, 1, 'S001', NULL, NULL, 50, 25.99),
    (2, 2, 'S002', NULL, NULL, 40, 19.75),
    (3, 3, 'S003', NULL, NULL, 60, 15.50),
    (4, 4, 'S004', NULL, NULL, 45, 22.00),
    (5, 5, 'S005', NULL, NULL, 55, 29.95),
    (6, 6, 'S006', NULL, NULL, 38, 18.50),
    (7, 7, 'S007', NULL, NULL, 42, 21.75),
    (8, 8, 'S008', NULL, NULL, 35, 17.25),
    (9, 9, 'S009', NULL, NULL, 48, 23.50),
    (10, 10, 'S010', NULL, NULL, 30, 26.00),
    (11, 11, 'S011', NULL, NULL, 25, 19.00),
    (12, 12, 'S012', NULL, NULL, 50, 28.75),
    (13, 13, 'S013', NULL, NULL, 40, 16.50),
    (14, 14, 'S014', NULL, NULL, 45, 24.99),
    (15, 15, 'S015', NULL, NULL, 55, 27.50),
    (16, 16, 'S016', NULL, NULL, 32, 20.25),
    (17, 17, 'S017', NULL, NULL, 38, 22.75),
    (18, 18, 'S018', NULL, NULL, 44, 18.99),
    (19, 19, 'S019', NULL, NULL, 50, 29.00),
    (20, 20, 'S020', NULL, NULL, 36, 21.50),
    (21, 1, NULL, 'E001', NULL, 30, 149.50),
    (22, 2, NULL, 'E002', NULL, 25, 79.00),
    (23, 3, NULL, 'E003', NULL, 20, 65.25),
    (24, 4, NULL, 'E004', NULL, 35, 99.99),
    (25, 5, NULL, 'E005', NULL, 28, 120.00),
    (26, 6, NULL, 'E006', NULL, 22, 55.00),
    (27, 7, NULL, 'E007', NULL, 33, 69.99),
    (28, 8, NULL, 'E008', NULL, 18, 85.50),
    (29, 9, NULL, 'E009', NULL, 26, 45.75),
    (30, 10, NULL, 'E010', NULL, 40, 110.00),
    (31, 11, NULL, 'E011', NULL, 15, 130.25),
    (32, 12, NULL, 'E012', NULL, 30, 39.99),
    (33, 13, NULL, 'E013', NULL, 25, 95.00),
    (34, 14, NULL, 'E014', NULL, 20, 75.50),
    (35, 15, NULL, 'E015', NULL, 35, 89.75),
    (36, 16, NULL, 'E016', NULL, 28, 105.00),
    (37, 17, NULL, 'E017', NULL, 22, 115.50),
    (38, 18, NULL, 'E018', NULL, 18, 125.00),
    (39, 19, NULL, 'E019', NULL, 30, 199.99),
    (40, 20, NULL, 'E020', NULL, 25, 59.50),
    (41, 1, NULL, NULL, 'C001', 15, 89.99),
    (42, 2, NULL, NULL, 'C002', 10, 95.00),
    (43, 3, NULL, NULL, 'C003', 12, 87.50),
    (44, 4, NULL, NULL, 'C004', 18, 92.75),
    (45, 5, NULL, NULL, 'C005', 14, 85.00),
    (46, 6, NULL, NULL, 'C006', 16, 90.25),
    (47, 7, NULL, NULL, 'C007', 20, 94.50),
    (48, 8, NULL, NULL, 'C008', 13, 88.75),
    (49, 9, NULL, NULL, 'C009', 17, 93.00),
    (50, 10, NULL, NULL, 'C010', 11, 86.50),
    (51, 11, NULL, NULL, 'C011', 19, 91.25),
    (52, 12, NULL, NULL, 'C012', 15, 89.00),
    (53, 13, NULL, NULL, 'C013', 12, 94.75),
    (54, 14, NULL, NULL, 'C014', 18, 87.99),
    (55, 15, NULL, NULL, 'C015', 14, 92.50),
    (56, 16, NULL, NULL, 'C016', 16, 90.00),
    (57, 17, NULL, NULL, 'C017', 20, 93.25),
    (58, 18, NULL, NULL, 'C018', 13, 88.50),
    (59, 19, NULL, NULL, 'C019', 17, 91.75),
    (60, 20, NULL, NULL, 'C020', 11, 86.25);

INSERT INTO SupplierOrders (OrderID, SupplierID, SensorID, EquipmentID, ControllerID, OrderDate, QuantityOrdered, Status, IsWiFi)
VALUES
    (1, 1, 'S001', NULL, NULL, '2025-03-01', 30, 'Complete', 0),
    (2, 2, NULL, 'E001', NULL, '2025-03-02', 15, 'Complete', 1),
    (3, 3, NULL, NULL, 'C001', '2025-03-03', 10, 'Complete', 0),
    (4, 4, 'S002', NULL, NULL, '2025-03-04', 25, 'Complete', 0),
    (5, 5, NULL, 'E002', NULL, '2025-03-05', 20, 'Cancelled', 1),
    (6, 6, NULL, NULL, 'C002', '2025-03-06', 12, 'Complete', 1),
    (7, 7, 'S003', NULL, NULL, '2025-03-07', 35, 'Complete', 0),
    (8, 8, NULL, 'E003', NULL, '2025-03-08', 18, 'Complete', 0),
    (9, 9, NULL, NULL, 'C003', '2025-03-09', 15, 'Incomplete', 0),
    (10, 10, 'S004', NULL, NULL, '2025-03-10', 40, 'Complete', 0),
    (11, 11, NULL, 'E004', NULL, '2025-03-11', 22, 'Complete', 1),
    (12, 12, NULL, NULL, 'C004', '2025-03-12', 14, 'Cancelled', 1),
    (13, 13, 'S005', NULL, NULL, '2025-03-13', 28, 'Complete', 0),
    (14, 14, NULL, 'E005', NULL, '2025-03-14', 25, 'Complete', 0),
    (15, 15, NULL, NULL, 'C005', '2025-03-15', 16, 'Complete', 0),
    (16, 16, 'S006', NULL, NULL, '2025-03-16', 32, 'Incomplete', 0),
    (17, 17, NULL, 'E006', NULL, '2025-03-17', 20, 'Complete', 0),
    (18, 18, NULL, NULL, 'C006', '2025-03-18', 13, 'Complete', 0),
    (19, 19, 'S007', NULL, NULL, '2025-03-19', 45, 'Cancelled', 0),
    (20, 20, NULL, 'E007', NULL, '2025-03-20', 17, 'Incomplete', 0);

INSERT INTO Staff (StaffID, FirstName, LastName, Expertise, MobileNumber, Email, IsAvailable)
VALUES
    (1, 'Thomas', 'Wright', 'IoT Installation', '07712 345678', 'thomas.wright@lsbu.co.uk', 1),
    (2, 'Rachel', 'Evans', 'Smart Home Design', '07983 901234', 'rachel.evans@lsbu.co.uk', 1),
    (3, 'Amit', 'Sharma', 'Network Setup', '07850 567890', 'amit.sharma@lsbu.co.uk', 0),
    (4, 'Clare', 'Taylor', 'Security Systems', '07496 123456', 'clare.taylor@lsbu.co.uk', 0),
    (5, 'David', 'Murray', 'Electrical Wiring', '07789 234567', 'david.murray@lsbu.co.uk', 0),
    (6, 'Priya', 'Singh', 'Sensor Calibration', '07912 678901', 'priya.singh@lsbu.co.uk', 0),
    (7, 'Mark', 'Jenkins', 'Controller Config', '07834 890123', 'mark.jenkins@lsbu.co.uk', 0),
    (8, 'Laura', 'Campbell', 'Customer Support', '07701 345890', 'laura.campbell@lsbu.co.uk', 1),
    (9, 'Gareth', 'Lloyd', 'Smart Lighting', '07458 901234', 'gareth.lloyd@lsbu.co.uk', 0),
    (10, 'Sophie', 'Baxter', 'HVAC Systems', '07967 123456', 'sophie.baxter@lsbu.co.uk', 0),
    (11, 'Hassan', 'Ali', 'WiFi Optimization', '07823 567890', 'hassan.ali@lsbu.co.uk', 0),
    (12, 'Emily', 'Ford', 'Data Analysis', '07745 678901', 'emily.ford@lsbu.co.uk', 0),
    (13, 'Sean', 'Kelly', 'Installation Lead', '07412 234567', 'sean.kelly@lsbu.co.uk', 0),
    (14, 'Nina', 'Patel', 'Tech Support', '07989 345678', 'nina.patel@lsbu.co.uk', 0),
    (15, 'Peter', 'Gordon', 'Equipment Testing', '07867 890123', 'peter.gordon@lsbu.co.uk', 0),
    (16, 'Kirsty', 'Reid', 'Project Management', '07723 901234', 'kirsty.reid@lsbu.co.uk', 0),
    (17, 'Jack', 'Turner', 'Smart Locks', '07489 123456', 'jack.turner@lsbu.co.uk', 0),
    (18, 'Fiona', 'Grant', 'Energy Systems', '07901 567890', 'fiona.grant@lsbu.co.uk', 0),
    (19, 'Ryan', 'Hughes', 'CCTV Setup', '07812 678901', 'ryan.hughes@lsbu.co.uk', 0),
    (20, 'Leah', 'Morgan', 'Software Integration', '07756 234567', 'leah.morgan@lsbu.co.uk', 0),
    (21, 'Omar', 'Khan', 'Network Security', '07423 567890', 'omar.khan@lsbu.co.uk', 0),
    (22, 'Holly', 'White', 'Sensor Deployment', '07934 678901', 'holly.white@lsbu.co.uk', 0),
    (23, 'Chris', 'Doyle', 'Maintenance', '07845 890123', 'chris.doyle@lsbu.co.uk', 0),
    (24, 'Sara', 'Bennett', 'Customer Training', '07767 901234', 'sara.bennett@lsbu.co.uk', 0),
    (25, 'Neil', 'Fraser', 'Controller Setup', '07478 123456', 'neil.fraser@lsbu.co.uk', 0),
    (26, 'Anita', 'Chopra', 'Quality Assurance', '07989 567890', 'anita.chopra@lsbu.co.uk', 0),
    (27, 'Luke', 'Pearson', 'Field Technician', '07890 678901', 'luke.pearson@lsbu.co.uk', 0),
    (28, 'Megan', 'Lawson', 'Design Consultant', '07701 234567', 'megan.lawson@lsbu.co.uk', 0),
    (29, 'Ben', 'Wallace', 'Installation Support', '07412 345678', 'ben.wallace@lsbu.co.uk', 0),
    (30, 'Zoe', 'Hamilton', 'Tech Trainer', '07923 456789', 'zoe.hamilton@lsbu.co.uk', 0);

INSERT INTO Teams (TeamID, TeamName)
VALUES
    (1, 'Alpha Installers'),
    (2, 'Beta Tech Crew'),
    (3, 'Gamma Smart Squad'),
    (4, 'Delta Wiring Team'),
    (5, 'Epsilon Security'),
    (6, 'Zeta Home Tech'),
    (7, 'Eta Sensor Group'),
    (8, 'Theta Networkers'),
    (9, 'Iota Control Unit'),
    (10, 'Kappa Eco Team'),
    (11, 'Lambda Support'),
    (12, 'Mu Design Force'),
    (13, 'Nu Maintenance'),
    (14, 'Xi Energy Crew'),
    (15, 'Omicron Field Techs'),
    (16, 'Pi Smart Systems'),
    (17, 'Rho Installation'),
    (18, 'Sigma Tech Pioneers'),
    (19, 'Tau Connect Team'),
    (20, 'Upsilon Home Crew');

INSERT INTO TeamMembers (TeamID, StaffID)
VALUES
    (1, 1),  (1, 2),
    (2, 3),  (2, 4),  (2, 5),
    (3, 6),  (3, 7),
    (4, 8),  (4, 9),  (4, 10),
    (5, 11), (5, 12),
    (6, 13), (6, 14), (6, 15),
    (7, 16), (7, 17),
    (8, 18), (8, 19), (8, 20),
    (9, 21), (9, 22),
    (10, 23), (10, 24), (10, 25),
    (11, 26), (11, 27),
    (12, 28), (12, 29), (12, 30),
    (13, 1),  (13, 3),
    (14, 4),  (14, 6),
    (15, 7),  (15, 8),
    (16, 9),  (16, 10),
    (17, 11), (17, 12),
    (18, 13), (18, 14),
    (19, 15), (19, 16),
    (20, 17), (20, 18);

INSERT INTO Installations (InstallationID, DesignID, BuildingID, TeamID, InstallationDate, TotalInstallationCost)
VALUES
    (1, 1, 1, 1, '2024-01-15', 1500.00),
    (2, 2, 2, 2, '2024-03-22', 2200.50),
    (3, 3, 3, 3, '2024-05-07', 900.75),
    (4, 4, 4, 4, '2024-07-19', 1800.00),
    (5, 5, 5, 5, '2024-09-03', 2500.00),
    (6, 6, 6, 6, '2024-10-28', 3200.25),
    (7, 7, 7, 7, '2024-02-14', 1100.00),
    (8, 8, 8, 8, '2024-06-11', 1750.80),
    (9, 9, 9, 9, '2024-08-25', 2800.00),
    (10, 10, 10, 10, '2024-11-09', 1300.50),
    (11, 11, 11, 11, '2025-01-17', 2000.00),
    (12, 12, 12, 12, '2024-04-30', 3500.00),
    (13, 13, 13, 13, '2024-12-05', 1600.75),
    (14, 14, 14, 14, '2025-02-12', 2900.00),
    (15, 15, 15, 15, '2024-03-08', 1450.25),
    (16, 16, 16, 16, '2025-03-20', 4000.00),
    (17, 17, 17, 17, '2024-07-02', 950.00),
    (18, 18, 18, 18, '2025-01-29', 2700.50),
    (19, 19, 19, 19, '2024-10-14', 1850.00),
    (20, 20, 20, 20, '2024-12-23', 3100.75);

INSERT INTO InstallationSensors (InstallationID, SensorID, Quantity)
VALUES
    (1, 'S001', 2),
    (2, 'S002', 1),
    (3, 'S003', 3),
    (4, 'S004', 1),
    (5, 'S005', 2),
    (6, 'S006', 1),
    (7, 'S007', 2),
    (8, 'S008', 1),
    (9, 'S009', 1),
    (10, 'S010', 2),
    (11, 'S011', 1),
    (12, 'S012', 3),
    (13, 'S013', 1),
    (14, 'S014', 2),
    (15, 'S015', 1),
    (16, 'S016', 2),
    (17, 'S017', 1),
    (18, 'S018', 1),
    (19, 'S019', 2),
    (20, 'S020', 1);

INSERT INTO InstallationEquipment (InstallationID, EquipmentID, Quantity)
VALUES
    (1, 'E001', 2),
    (2, 'E002', 1),
    (3, 'E003', 1),
    (4, 'E004', 1),
    (5, 'E005', 2),
    (6, 'E006', 1),
    (7, 'E007', 1),
    (8, 'E008', 2),
    (9, 'E009', 1),
    (10, 'E010', 1),
    (11, 'E011', 2),
    (12, 'E012', 1),
    (13, 'E013', 1),
    (14, 'E014', 2),
    (15, 'E015', 1),
    (16, 'E016', 1),
    (17, 'E017', 1),
    (18, 'E018', 1),
    (19, 'E019', 2),
    (20, 'E020', 1);

INSERT INTO InstallationControllers (InstallationID, ControllerID, Quantity)
VALUES
    (1, 'C001', 1),
    (2, 'C002', 1),
    (3, 'C003', 1),
    (4, 'C004', 1),
    (5, 'C005', 1),
    (6, 'C006', 1),
    (7, 'C007', 1),
    (8, 'C008', 1),
    (9, 'C009', 1),
    (10, 'C010', 1),
    (11, 'C011', 1),
    (12, 'C012', 1),
    (13, 'C013', 1),
    (14, 'C014', 1),
    (15, 'C015', 1),
    (16, 'C016', 1),
    (17, 'C017', 1),
    (18, 'C018', 1),
    (19, 'C019', 1),
    (20, 'C020', 1);

INSERT INTO InstallationStaff (InstallationStaffID, InstallationID, StaffID, SensorID, EquipmentID, ControllerID, QuantityInstalled)
VALUES
-- Sensors
(1, 1, 1, 'S001', NULL, NULL, 1),
(2, 2, 2, 'S002', NULL, NULL, 1),
(3, 3, 3, 'S003', NULL, NULL, 2),
(4, 4, 4, 'S004', NULL, NULL, 1),
(5, 5, 5, 'S005', NULL, NULL, 2),
(6, 6, 6, 'S006', NULL, NULL, 1),
(7, 7, 7, 'S007', NULL, NULL, 2),
(8, 8, 8, 'S008', NULL, NULL, 1),
(9, 9, 9, 'S009', NULL, NULL, 1),
(10, 10, 10, 'S010', NULL, NULL, 2),
(11, 11, 11, 'S011', NULL, NULL, 1),
(12, 12, 12, 'S012', NULL, NULL, 3),
(13, 13, 13, 'S013', NULL, NULL, 1),
(14, 14, 14, 'S014', NULL, NULL, 2),
(15, 15, 15, 'S015', NULL, NULL, 1),
(16, 16, 16, 'S016', NULL, NULL, 2),
(17, 17, 17, 'S017', NULL, NULL, 1),
(18, 18, 18, 'S018', NULL, NULL, 1),
(19, 19, 19, 'S019', NULL, NULL, 2),
(20, 20, 20, 'S020', NULL, NULL, 1),

-- Equipment
(21, 1, 2, NULL, 'E001', NULL, 1),
(22, 2, 3, NULL, 'E002', NULL, 1),
(23, 3, 4, NULL, 'E003', NULL, 1),
(24, 4, 5, NULL, 'E004', NULL, 1),
(25, 5, 6, NULL, 'E005', NULL, 2),
(26, 6, 7, NULL, 'E006', NULL, 1),
(27, 7, 8, NULL, 'E007', NULL, 1),
(28, 8, 9, NULL, 'E008', NULL, 2),
(29, 9, 10, NULL, 'E009', NULL, 1),
(30, 10, 11, NULL, 'E010', NULL, 1),
(31, 11, 12, NULL, 'E011', NULL, 2),
(32, 12, 13, NULL, 'E012', NULL, 1),
(33, 13, 14, NULL, 'E013', NULL, 1),
(34, 14, 15, NULL, 'E014', NULL, 2),
(35, 15, 16, NULL, 'E015', NULL, 1),
(36, 16, 17, NULL, 'E016', NULL, 1),
(37, 17, 18, NULL, 'E017', NULL, 1),
(38, 18, 19, NULL, 'E018', NULL, 1),
(39, 19, 20, NULL, 'E019', NULL, 2),
(40, 20, 1, NULL, 'E020', NULL, 1),

-- Controllers
(41, 1, 3, NULL, NULL, 'C001', 1),
(42, 2, 4, NULL, NULL, 'C002', 1),
(43, 3, 5, NULL, NULL, 'C003', 1),
(44, 4, 6, NULL, NULL, 'C004', 1),
(45, 5, 7, NULL, NULL, 'C005', 1),
(46, 6, 8, NULL, NULL, 'C006', 1),
(47, 7, 9, NULL, NULL, 'C007', 1),
(48, 8, 10, NULL, NULL, 'C008', 1),
(49, 9, 11, NULL, NULL, 'C009', 1),
(50, 10, 12, NULL, NULL, 'C010', 1),
(51, 11, 13, NULL, NULL, 'C011', 1),
(52, 12, 14, NULL, NULL, 'C012', 1),
(53, 13, 15, NULL, NULL, 'C013', 1),
(54, 14, 16, NULL, NULL, 'C014', 1),
(55, 15, 17, NULL, NULL, 'C015', 1),
(56, 16, 18, NULL, NULL, 'C016', 1),
(57, 17, 19, NULL, NULL, 'C017', 1),
(58, 18, 20, NULL, NULL, 'C018', 1),
(59, 19, 1, NULL, NULL, 'C019', 1),
(60, 20, 2, NULL, NULL, 'C020', 1);

INSERT INTO SensorReadings (ReadingID, SensorID, ControllerID, ReadingValue, ReadingTimestamp)
VALUES
(1, 'S001', 'C001', '21.5°C', '2025-03-26 09:00:00'),
(2, 'S002', 'C002', '48%', '2025-03-26 09:05:00'),
(3, 'S003', 'C003', 'Motion Detected', '2025-03-26 09:10:00'),
(4, 'S004', 'C004', 'No Smoke', '2025-03-26 09:15:00'),
(5, 'S005', 'C005', '600 ppm', '2025-03-26 09:20:00'),
(6, 'S006', 'C006', '350 lx', '2025-03-26 09:25:00'),
(7, 'S007', 'C007', 'Closed', '2025-03-26 09:30:00'),
(8, 'S008', 'C008', 'Open', '2025-03-26 09:35:00'),
(9, 'S009', 'C009', '1013 hPa', '2025-03-26 09:40:00'),
(10, 'S010', 'C010', 'Dry', '2025-03-26 09:45:00'),
(11, 'S011', 'C011', '35 dB', '2025-03-26 09:50:00'),
(12, 'S012', 'C012', 'No Leak', '2025-03-26 09:55:00'),
(13, 'S013', 'C013', '0.05g', '2025-03-26 10:00:00'),
(14, 'S014', 'C014', 'Occupied', '2025-03-26 10:05:00'),
(15, 'S015', 'C015', 'Good', '2025-03-26 10:10:00'),
(16, 'S016', 'C016', 'High Temp Alert', '2025-03-26 10:15:00'),
(17, 'S017', 'C017', 'Dry', '2025-03-26 10:20:00'),
(18, 'S018', 'C018', 'Object Detected', '2025-03-26 10:25:00'),
(19, 'S019', 'C019', '420W', '2025-03-26 10:30:00'),
(20, 'S020', 'C020', '15° Tilt', '2025-03-26 10:35:00');

INSERT INTO Invoices (InvoiceID, ClientID, DesignID, InvoiceDate, Amount, DueDate, PaymentMethod)
VALUES
(1, 1, 1, '2024-01-15', 1500.00, '2024-02-12', 'Credit Card'),
(2, 2, 2, '2024-03-22', 2200.50, '2024-04-19', 'Debit Card'),
(3, 3, 3, '2024-05-07', 900.75, '2024-06-04', 'PayPal'),
(4, 4, 4, '2024-07-19', 1800.00, '2024-08-16', 'Credit Card'),
(5, 5, 5, '2024-09-03', 2500.00, '2024-10-01', 'Google Pay'),
(6, 6, 6, '2024-10-28', 3200.25, '2024-11-25', 'Debit Card'),
(7, 7, 7, '2024-02-14', 1100.00, '2024-03-13', 'Credit Card'),
(8, 8, 8, '2024-06-11', 1750.80, '2024-07-09', 'PayPal'),
(9, 9, 9, '2024-08-25', 2800.00, '2024-09-22', 'Google Pay'),
(10, 10, 10, '2024-11-09', 1300.50, '2024-12-07', 'Debit Card'),
(11, 11, 11, '2025-01-17', 2000.00, '2025-02-14', 'Credit Card'),
(12, 12, 12, '2024-04-30', 3500.00, '2024-05-28', 'Google Pay'),
(13, 13, 13, '2024-12-05', 1600.75, '2025-01-02', 'PayPal'),
(14, 14, 14, '2025-02-12', 2900.00, '2025-03-12', 'Debit Card'),
(15, 15, 15, '2024-03-08', 1450.25, '2024-04-05', 'Credit Card'),
(16, 16, 16, '2025-03-20', 4000.00, '2025-04-17', 'Google Pay'),
(17, 17, 17, '2024-07-02', 950.00, '2024-07-30', 'PayPal'),
(18, 18, 18, '2025-01-29', 2700.50, '2025-02-26', 'Credit Card'),
(19, 19, 19, '2024-10-14', 1850.00, '2024-11-11', 'Debit Card'),
(20, 20, 20, '2024-12-23', 3100.75, '2025-01-20', 'PayPal');
