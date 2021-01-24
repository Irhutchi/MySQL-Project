-- -----------------------------------------------------
-- Drop the 'MetCal' database/schema
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS MetCal;

-- -----------------------------------------------------
-- Create 'MetCal' database/schema and use this database
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS MetCal;

USE MetCal;

SHOW TRIGGERS;

DROP TABLE IF EXISTS staffMember;
-- -----------------------------------------------------
-- Create table staffMember
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS staffMember(
	staff_id int NOT NULL AUTO_INCREMENT,
	supervisor_id INT, -- implementation of recursive relationship
	fName VARCHAR(20) NOT NULL,
	lName VARCHAR(20) NOT NULL,
	DOB DATE NOT NULL,
	position varchar(25) NOT NULL,
	salary INT NOT NULL,
	INDEX (supervisor_id), 
	PRIMARY KEY(staff_id),
	FOREIGN KEY(supervisor_id) REFERENCES staffMember(staff_id)
);

CREATE INDEX staff_id_ind on staffMember(fName,lName);
SHOW INDEX FROM staffMember;


/* Populate the tables with our data */
INSERT INTO staffMember VALUES
(001,NULL,'Dave','Nolan','1979-10-20','CEO','75000'), # Dave is the CEO (as Supervisor Id is NULL)
(102,NULL,'Robert','Gubbins','1984-02-02','Project Engineer','35000'), # Rob is employee 102 and reports to 001 (Dave Nolan)
(101,102,'Ian','Hutchinson','1990-08-12','Cal Technician','25000'), # Ian is employee 101 and reports to 102 (Robert Gubbins)
(103,102,'Tommy','Garvey','1984-02-02','Project Engineer','35000'),
(104,001,'John','Meenan','1980-10-07','Sales','35000'),
(105,102,'Ed','Jones','1988-04-26','Project Engineer','30000'),
(106,102,'Francy','Bohan','1993-08-19','Project Engineer','28000'),
(107,001,'Caleb','Ajay','1988-04-13','Cal Technician','25000'),
(109,001,'Helen','Lynham','1971-05-08','Administrator','38000'),
(110,001,'Paula','Davis','1978-05-08','Network Engineer','40000');


DROP TABLE IF EXISTS Customer;
-- -----------------------------------------------------
-- Create table Customer
-- -----------------------------------------------------
CREATE TABLE Customer( 
	customer_id int(3) ZEROFILL NOT NULL AUTO_INCREMENT,
	company_name VARCHAR(25) NOT NULL,
	fName VARCHAR(20) NOT NULL,
	lName VARCHAR(20) NOT NULL,
-- 	street VARCHAR(60) NOT NULL,
-- 	town VARCHAR(25) ,
-- 	county VARCHAR(15) NOT NULL,
	PRIMARY KEY(customer_id)
);

CREATE INDEX customerid_ind on customer(company_name);
SHOW INDEX FROM customer;

INSERT INTO Customer VALUES
(001, 'Sanofi Genzyme', 'David', 'Jackson'),
(002, 'West Pharma', 'John', 'Doe'),
(003, 'Bausch and Lomb', 'Tony', 'Nugent'),
(004, 'Eirgen Pharma Limited', 'Jim', 'Brown'),
(005, 'Eurofins BioPharma', 'Paul', 'Morrisey'),
(006, 'Carten Control Ltd', 'Adam', 'Power'),
(007, 'GlaxoSmithKline', 'Declan', 'Bailey'),
(008, 'Teva Ireland', 'Robert', 'Downey'),
(009, 'Boston Scientific', 'Shane', 'Freeman'),
(010, 'Suir Pharma Ireland', 'Shane', 'Guiry'),
(011, 'BioTipp', 'Alan', 'Cooney'),
(012, 'MSD', 'Patrick', 'Domican'),
(013, 'Eli Lilly Pharmaceutical', 'Thomas', 'O\'Gorman'),
(014, 'Lake Region Manufacturing', 'Janet', 'O\'Shea'),
(015, 'Servier Industries', 'Eamonn', 'Butler'),
(016, 'Stryker', 'James', 'O\'Keefe'),
(017, 'GE Healthcare', 'Audrie', 'Kelleher');

-- DROP VIEW Company_pointOfContact;
-- Query DB to view POC for each company on record
CREATE VIEW Company_pointOfContact AS
SELECT company_name, concat(fName,' ',lName)  Name
	FROM Customer
 	WITH CHECK OPTION;


SELECT * FROM Company_pointOfContact;

SELECT customer_id, company_name FROM Customer;


-- -----------------------------------------------------
-- Create table customerSites
-- -----------------------------------------------------

DROP TABLE IF EXISTS customerSites;
create table customerSites( 
	customer_id INT(3) ZEROFILL NOT NULL,
	street VARCHAR(60) NOT NULL,
	town VARCHAR(25) ,
	county VARCHAR(15) NOT NULL,
    tel_no VARCHAR(18) NOT NULL,
    PRIMARY KEY (tel_no),
	-- CHECK(tel_no < 3),  -- perform a check on the number of tel_no's against a customer id just entered and flag if more than 3.
	CONSTRAINT fk_Customer FOREIGN KEY(customer_id) references Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- stored procedure tracks the values in the tel_no and Customer_id columns
DELIMITER $
CREATE PROCEDURE `check_CustomerSites`(IN tel_no VARCHAR(14), IN customer_id VARCHAR(60))
BEGIN
    IF tel_no AND customer_id  = 3 THEN
        SIGNAL SQLSTATE '45000'  -- raise error if three customer sites already exist for a particulare customer in the DB
           SET MESSAGE_TEXT = 'check constraint on Customer Site. Limit exceeded';
    END IF;
END$
DELIMITER ;


-- before insert call the check_CustomerSites procdure() stored above
-- 
DELIMITER $
CREATE TRIGGER `Customer_before_insert` BEFORE INSERT ON `customerSites`
FOR EACH ROW
BEGIN
    CALL check_CustomerSites(new.customer_id,new.tel_no);
END$   
DELIMITER ; 
-- before update call the check_CustomerSites procdure().
DELIMITER $
CREATE TRIGGER `Customer_before_update` BEFORE UPDATE ON `customerSites`
FOR EACH ROW
BEGIN
    CALL check_CustomerSites(new.customer_id,new.tel_no);
END$   
DELIMITER ;


INSERT INTO customerSites VALUES
(001, 'Old Kilmeaden Rd', NULL, 'Waterford', '051594100'), # using zerofill to allow zero at the start of contact number.
(001, '18 Riverwalk,', 'Citywest Business Campus','Dublin 24', "014035600"),
(002, 'Carrickpherish Road', NULL, 'Waterford', '051378768'),
(003, 'Unit 424 Industrial Est', NULL, 'Waterford', '051355001'),
(004, 'Westside Business Park', 'Old Kilmeaden Rd', 'Waterford', '051591944'),
(005, 'IDA Industrial Estate Clogherane', 'Dungarvan', 'Waterford', '0515848300'),
(005, 'Units 2 & 3 Dungarvan Business Park Shandon', 'Dungarvan', 'Waterford', '0143311306'),
(006, 'Unit 609 Waterford Industrial Park', NULL, 'Waterford', '051355436'),
(007, 'IDA Industrial Estate Clogherane', 'Dungarvan', 'Waterford', '051842833'),
(008, 'Unit 301, Waterford Industrial Estate', NULL, 'Waterford', '051331331'),
(009, 'Cashel Road', 'Clonmel', 'Tipperary', '0526181000'),
(009, 'Cork Business & Technology Park', 'Model Farm Road', 'Cork', '0214531000'),
(010, 'Waterford Road', 'Clonmel', 'Tipperary', '052617777'),
(011, '4/5 The Square', 'Cahir', 'Tipperary', '0527442896'),
(012, 'Ballydine', 'Kilsheelan', 'Tipperary', '051601001'),
(012, 'Brinny', 'Innishannon', 'Cork', '051601000'),
(013, 'Dunderrow', 'Kinsale', 'Cork', '0214772699'),
(014, 'Buttersland', 'New Ross', 'Wexford', '051440500'),
(015, 'Money Little', 'Arklow', 'Wicklow', '040220800'),
(016, 'Anngrove', 'Carrigtwohill', 'Cork', '0214532800'),
(016, 'Cork Business and Technology Park', 'Model Farm Road', 'Cork', '0212448900'),
(016, 'Raheen Business Park', 'Raheen ', 'Limerick', '061498200'),
(017, 'Tullagreen', 'Carrigtwohill', 'Cork', '0217300645');

-- retrieve total number of customer sites (Not Customers)
SELECT count(*) from CustomerSites;

DROP VIEW IF EXISTS Ind_Customers;
-- Left Join parent (customer) with child (customerSites) to create view that displays address of all sites.
CREATE VIEW Ind_Customers AS
	Select company_name, customer_id, street, town, county
		FROM
			customer
		LEFT JOIN CustomerSites USING (customer_id) -- both tables have 'customer_id' column hence its use here.
		ORDER BY 
			county;

SELECT * from Ind_Customers;
-- Insert statement invokes befor insert trigger and throws error if 3 customer sites already exists for a customer.
DROP TRIGGER IF EXISTS tr_phoneNumber_check;
DELIMITER $$
CREATE TRIGGER tr_phoneNumber_check 
 BEFORE INSERT ON CustomerSites 
	FOR EACH ROW 
 BEGIN
	DECLARE msg VARCHAR(140);
	IF customer_id = 3 THEN
		set msg = concat('Error: Max entries per customer: 3. Cannot add customer to DB.');
    END IF;
END$$
DELIMITER ;



DROP TABLE IF EXISTS Booking;
-- -----------------------------------------------------
-- Create table Booking
-- -----------------------------------------------------
CREATE TABLE Booking(
	purchase_order_no VARCHAR(20) NOT NULL,
	booking_date DATE NOT NULL,
	customer_id INT(3) ZEROFILL NOT NULL,
	PRIMARY KEY(purchase_order_no),
	FOREIGN KEY(customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO Booking VALUES
('SG123456', '2020-11-11', 001),
('SG012545', '2020-11-09', 001),
('WP123456', '2020-10-30', 002),
('BL123456', '2020-10-31', 003),
('ERGN456', '2020-11-01', 004),
('BS978645', '2020-11-01', 009),
('SPI321456', '2020-11-04', 010),
('BS369147', '2020-11-04', 009),
('BS649752', '2020-11-08', 009),
('ELY884156', '2020-11-08', 013),
('SVR123999', '2020-11-02', 015),
('GSK166542', '2020-11-02', 007),
('SPI5546546', '2020-11-02', 010),
('CC1239966', '2020-11-10', 006),
('ERGN65486', '2020-11-10', 004),
('GE3253456', '2020-11-11', 017),
('SYK123321', '2020-11-12', 016),
('SYk123456', '2020-11-13', 016),
('WP223456', '2020-11-11', 002),
('MSD123456', '2020-11-09', 012);


-- drop view bookingsPerCustomer;
-- Query returns data from the bookingsPerCustomer view
CREATE VIEW bookingsPerCustomer(
	Comapny_name,  -- table header
    No_of_Bookings -- table header
)
AS
	SELECT
		company_name,
        count(purchase_order_no)
	FROM
		Customer
			INNER JOIN Booking USING (customer_id) -- Comparing each row from Cust table with booking table
	GROUP BY customer_id;

SELECT * FROM bookingsPerCustomer;

SHOW FULL TABLES;
DROP TABLE IF EXISTS calibrationRepairJob;
-- -----------------------------------------------------
-- Create table CalibrationRepairJob
-- -----------------------------------------------------
CREATE TABLE CalibrationRepairJob(
	job_no INT AUTO_INCREMENT NOT NULL, 
	purchase_order_no VARCHAR(20) NOT NULL,
	customer_id INT(3) ZEROFILL NOT NULL,
	serial_no VARCHAR(25) NOT NULL, 
	modelType VARCHAR(25) NOT NULL,
	Manufacturer VARCHAR(20) NOT NULL,
	dateIn DATE NOT NULL,
	dateOut DATE NOT NULL,
	calDueDate DATE,
	PRIMARY KEY(job_no),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE,
	foreign key (purchase_order_no) REFERENCES Booking(purchase_order_no) ON UPDATE CASCADE ON DELETE CASCADE
);


INSERT INTO CalibrationRepairJob VALUES
(1000, 'SG123456', 001, '36036', 'Lasair II URI', 'PMS', '2020-11-12', '2020-11-22', '2021-05-22');
INSERT INTO CalibrationRepairJob VALUES
(1001, 'SG123456', 001, '84664', 'Airnet II 510', 'PMS', '2020-11-12', '2020-11-22', '2021-05-22');
INSERT INTO CalibrationRepairJob VALUES
(1002, 'GSK166542', 007, '65109', 'Airnet II 510', 'PMS', '2020-11-04', '2020-11-07', '2021-05-07');
INSERT INTO CalibrationRepairJob VALUES
(1003, 'BL123456', 003, '112885', 'Lasair III 310C', 'PMS', '2020-11-01', '2020-11-05', '2021-05-05');
INSERT INTO CalibrationRepairJob VALUES
(1004, 'WP223456', 002, '110586', 'IsoAir 310P', 'PMS', '2020-11-15', '2020-11-20', '2021-05-20');
INSERT INTO CalibrationRepairJob VALUES
(1005, 'SYk123456', 016, '40431231003', 'Flowmeter', 'TSI', '2020-11-12', '2020-11-22', '2021-05-22');
INSERT INTO CalibrationRepairJob VALUES
(1006, 'SYk123456', 016, '40451235004', 'Flowmeter', 'TSI', '2020-11-12', '2020-11-22', '2021-05-22');
INSERT INTO CalibrationRepairJob VALUES
(1007, 'ERGN65486', 004, '83654123', 'Multimeter', 'Fluke', '2020-11-11', '2020-11-15', '2021-11-15');
INSERT INTO CalibrationRepairJob VALUES
(1008, 'ERGN65486', 004, '35964582', 'Multimeter', 'Fluke', '2020-11-11', '2020-11-15', '2021-11-15');
insert into CalibrationRepairJob VALUES
(1009, 'ERGN456', 004, 'SW\-01', 'Stopwatch', 'RS', '2020-11-04', '2020-11-06', '2021-11-06');
INSERT INTO CalibrationRepairJob VALUES
(1010, 'SG012545', 001, 'SW\-02', 'Stopwatch', 'RS', '2020-11-12', '2020-11-22', '2021-11-22');
INSERT INTO CalibrationRepairJob VALUES
(1011, 'WP123456', 002, '1084', 'PHA', 'AMTEK', '2020-11-01', '2020-11-05', '2021-11-04');
INSERT INTO CalibrationRepairJob VALUES
(1012, 'BS978645', 009, '1082', 'PHA', 'AMTEK', '2020-11-01', '2020-11-05', '2021-11-04');

CREATE VIEW calibration_due_details AS
	SELECT concat(fname,' ',lname)  Name, serial_no, modelType, calDueDate
	FROM CalibrationRepairJob JOIN Customer;

DROP TABLE IF EXISTS Supplier;
-- -----------------------------------------------------
-- Create table Supplier
-- -----------------------------------------------------
CREATE TABLE Supplier( 
	supplier_id VARCHAR(9) NOT NULL,
	supplier_name VARCHAR(50) NOT NULL,
	email VARCHAR(80) NOT NULL,
	street VARCHAR(40) NOT NULL,
	town VARCHAR(30),
	county VARCHAR(30) NOT NULL,
	province VARCHAR(30),
	country VARCHAR(30) NOT NULL,
	PRIMARY KEY(supplier_id)
);

INSERT INTO Supplier VALUES
('PMS\ US', 'Particle Measuring Systems', 'info@pmeasuring.com', '5475 Airport Blvd', 'Boulder', 'Colorado', null, 'USA'),
('PMS\ Au', 'Particle Measuring Systems', 'pmsaustria@pmeasuring.com', 'Euro Plaza ', NULL, 'Am Euro Platz 2', 'Vienna', 'Austria');

SELECT * FROM Supplier;
DROP TABLE IF EXISTS supplierPhone;
-- -----------------------------------------------------
-- Create table supplierPhone
-- -----------------------------------------------------
CREATE TABLE supplierPhone( 
	tel_no VARCHAR(18) NOT NULL,
	supplier_name VARCHAR(35) NOT NULL,
	supplier_id VARCHAR(9) NOT NULL,
	FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- One supplier headquarted in U.S.A with a base in Europe also.
INSERT INTO supplierPhone VALUES
('011 3034 437100', 'Particle Measuring Systems', 'PMS\ US'),
('011 8002 381801', 'Particle Measuring Systems', 'PMS\ US'),
('004 3512 390500', 'Particle Measuring Systems', 'PMS\ Au');




DROP TABLE IF EXISTS Part;
-- -----------------------------------------------------
-- Create table Part
-- -----------------------------------------------------
CREATE TABLE Part(
	part_number INT NOT NULL, 
	part_desc TINYTEXT NOT NULL, 
	stock_quantity SMALLINT NOT NULL DEFAULT 0, 
	price DECIMAL(5,2),
	supplier_id VARCHAR(9) NOT NULL,
	PRIMARY KEY(part_number),
	FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Create table inventory_tracker
-- -----------------------------------------------------

INSERT INTO Part VALUES
(1000022558, 'Main PCB 4 Channel', 10, 560.00, 'PMS\ US'),
(1000013720, 'Top Cover', 6, 295.00, 'PMS\ US'),
(1000013700, 'Laser Diode', 10, 768.00, 'PMS\ US'),
(1000013723, 'Top Cover', 40, 295.00, 'PMS\ US'),
(1000003314, 'Laser Dump Spot', 6, 95.00, 'PMS\ US'),
(1000009079, 'Mirror', 50, 275.00, 'PMS\ US'),
(1000016543, 'Test Leads', 12, 44.95, 'PMS\ Au');

SELECT * FROM part;


DROP TABLE IF EXISTS inventory_count;

CREATE TABLE inventory_count(
	id INT AUTO_INCREMENT PRIMARY KEY,
	part_number INT NOT NULL,
    stock_quantity SMALLINT NOT NULL,
    changedate DATETIME DEFAULT NULL,  # timestanp for when the change occurred
    ACTION VARCHAR(50) DEFAULT NULL
);

-- drop trigger tr_upd_inventory_tracker;
# Trigger to log changes in the Part(price and quantity) table
# Changing defualt trigger to '$$' ensures the trigger is not ended prematurely 
DELIMITER $$ 
CREATE TRIGGER tr_update_inventory
    AFTER UPDATE ON Part
    FOR EACH ROW  
BEGIN
    INSERT INTO inventory_count
    SET action = 'update',
        stock_quantity = NEW.stock_quantity,
        part_number= OLD.part_number,
        changedate = NOW(); 
END$$
DELIMITER ;


create table part_audit(
	id INT AUTO_INCREMENT PRIMARY KEY,
	part_desc tinytext not null,
    price decimal(5,2),
    changedate DATETIME DEFAULT NULL,  # timestanp for when the change occurred
    action VARCHAR(50) DEFAULT NULL
    );
    
    
-- update trigger # Changing defualt trigger delimiter to '$$' ensures the trigger is not ended prematurely
DELIMITER $$  
CREATE TRIGGER tr_upd_part_audit
    BEFORE UPDATE ON Part
    FOR EACH ROW 
BEGIN
    INSERT INTO part_audit
    SET action = 'update',
        price = OLD.price, # reocrd which price is being changed
        part_desc=OLD.part_desc,
        changedate = NOW(); # store the current date and time
END $$
DELIMITER ;
 # set delimiter back to semi-colon


-- -----------------------------------------------------
-- Create Entity Relationship Tables
-- -----------------------------------------------------
DROP TABLE IF EXISTS Queries;

create table Queries(
	customer_id int(3) ZEROFILL NOT NULL AUTO_INCREMENT,
	staff_id INT NOT NULL,
	queryDate DATE NOT NULL,
	queryType VARCHAR(20),
	PRIMARY KEY(customer_id, staff_id),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
	FOREIGN KEY (staff_id) REFERENCES staffMember(staff_id) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO Queries VALUES
(003, 104, '2020-10-18', 'Service Quote'),
(008, 101, '2020-10-10', 'Repair Query'),
(013, 104, '2020-09-28', 'Sales'),
(007, 101, '2020-11-10', 'Callout'),
(006, 109, '2020-10-16', 'Booking'),
(017, 109, '2020-10-23', 'Booking'),
(015, 104, '2020-11-03', 'Service Quote'),
(011, 101, '2020-11-09', 'Callout');

select * from Queries; 


DROP TABLE IF EXISTS carriesOut;

create table carriesOut(
	staff_id INT NOT NULL,
	job_no INT NOT NULL, 
	timeTaken TIME,
	PRIMARY KEY(staff_id, job_no),
	CONSTRAINT fk_staffmember FOREIGN KEY(staff_id) REFERENCES staffMember(staff_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_calibrationrepairjob FOREIGN KEY(job_no) REFERENCES CalibrationRepairJob(job_no) ON UPDATE CASCADE ON DELETE CASCADE
);
DELETE FROM carriesOut;
INSERT INTO carriesOut VALUES
(101, 1000,'02:30:00'),
(101, 1001,'01:45:00'),
(104, 1002,'02:00:00'),
(104, 1003,'02:30:00'),
(107, 1004,'01:15:00'),
(107, 1005,'03:10:00'),
(104, 1006,'01:50:00'),
(107, 1007,'01:10:00'),
(101, 1008,'02:25:00'),
(104, 1009,'24:30:00'),
(101, 1010,'24:30:00'),
(107, 1011,'01:55:00'),
(107, 1012,'01:30:00');

SELECT * FROM carriesOut;

DROP TABLE IF EXISTS Uses;
CREATE TABLE Uses(
	job_no INT AUTO_INCREMENT NOT NULL, 
	part_number INT NOT NULL, 
	quantity SMALLINT NOT NULL, 
	PRIMARY KEY(job_no, part_number),
	FOREIGN KEY (job_no) REFERENCES calibrationRepairJob(job_no) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (part_number) REFERENCES Part(part_number) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO Uses VALUES
(1000, 1000009079, 1),
(1003, 1000013700, 1),
(1003, 1000009079, 2),
(1007, 1000016543, 1);

COMMIT;
