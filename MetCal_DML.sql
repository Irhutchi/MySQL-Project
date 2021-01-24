DROP SCHEMA IF EXISTS MetCal_DML;
CREATE SCHEMA IF NOT EXISTS MetCal_DML;

USE MetCal;

-- -----------------------------------------------------
-- Users and Security 
-- -----------------------------------------------------
DROP USER Management, LabStaff, Admininstrator;
CREATE USER Management IDENTIFIED BY 'password';
CREATE USER LabStaff IDENTIFIED BY 'labpass';
CREATE USER Admininstrator IDENTIFIED BY 'admin';

SELECT user, host FROM mysql.user;

-- User Privleges --
GRANT ALL ON MetCal.* TO Management WITH GRANT OPTION;
GRANT ALL ON MetCal.* TO Admininstrator;

-- LabStaff in MetCal database may only need SELECT, INSERT and UPDATE on the three main tables,
-- to carry out their main duties and read access only for the other tables.
GRANT INSERT, UPDATE ON  booking TO LabStaff;
GRANT INSERT, UPDATE ON  CalibrationRepairJob TO LabStaff;
GRANT INSERT, UPDATE ON  Queries TO LabStaff;
GRANT SELECT ON MetCal.* to LabStaff;



-- We can also specify privileges on a particular field e.g. only the stock_quantity field in the part table.
grant update(stock_quantity) on part to LabStaff;

-- Delete privileges from a user after they have been granted, specifically that no job is ever deleted.
-- revoke delete on CalibrationRepairJob from Admininstrator;
-- how all the privileges that have been assigned to a particular user
show grants for Admininstrator;


-- -----------------------------------------------------
-- Query/ Modify StaffMember Table 
-- -----------------------------------------------------
DESCRIBE staffMember;

SELECT * FROM staffMember;

SELECT COUNT(staff_id) -- Number of staff currently employed
	FROM staffMember;
    
-- Join staff table to itself using staffId and supervisor_id columns
SELECT
	-- table has two columns: Manager & Direct Report
	CONCAT(m.fName, ' ', m.lName) AS Manager,
    CONCAT(s.fName, ' ', s.lName) AS 'Direct Report'
FROM
	staffMember s
INNER JOIN staffMember m ON
	m.staff_id = s.supervisor_id
ORDER BY
	Manager;
    
-- Retrieve the min, max and avg employeee salary within the company.
-- Explain analyze     
SELECT 
	MAX(salary) AS 'Highest paid employee',
    MIN(salary) AS 'Lowest paid employee',
    FLOOR(AVG(salary)) AS 'Mean salary of employees'
	FROM staffMember;
    
-- Return the number of salary greater than xxx
SELECT concat(fName,' ',lName)  Name, salary
	FROM staffMember
    WHERE salary > 36000;


-- List employees from oldest to youngest
SELECT * FROM staffMember
	ORDER BY DOB;

-- -----------------------------------------------------
-- Query/ Modify Customer Table 
-- -----------------------------------------------------
DESCRIBE Customer; 

SELECT *
	FROM Company_pointOfContact;

SELECT customer_id, company_name, county
	FROM Customer;

SELECT count(*) 
	FROM customer;


SELECT count(*) 
	FROM customerSites;
    -- OR --
-- use 18 chars of the customer name attribute to find number of unique customers.
explain analyze
SELECT 
	count(Distinct left(company_name, 18)) No_of_Distinct_Customers
FROM
	customer;

-- Return company name based on laction filter
SELECT company_name, street, county
	FROM Customer
WHERE county LIKE '_aterford' OR county = 'Tipperary' -- using pattern matching to return companies located in Waterford
ORDER BY county, company_name, street;

-- Query checks for duplicate contact numbers in the customerPhone table.
SELECT tel_no AS Telephone, customer_id, COUNT(tel_no) AS Total
	FROM customerSites
    GROUP BY tel_no
    HAVING COUNT(tel_no) > 1;

-- Query references customer phones table twice, using table alias t1 & t2.
-- Delete duplicate telephone numbers and keep the cusotmer Id.
DELETE t1 FROM customerSites t1
	INNER JOIN customerSites t2
    WHERE 
		t1.customer_id < t2.customer_id AND
		t1.tel_no=t2.tel_no;
        
-- -----------------------------------------------------
-- Query/ Modify CalibrationRepairJob Table 
-- -----------------------------------------------------

DESCRIBE CalibrationRepairJob;

-- Modify the 'Manufacture' column to increase no. of characters permissable
ALTER TABLE CalibrationRepairJob
MODIFY Manufacturer VARCHAR(25) NOT NULL;

DESCRIBE CalibrationRepairJob;

-- Return the number of jobs carried out grouped by 
SELECT job_no, COUNT(customer_id)
	FROM CalibrationRepairJob
    GROUP BY customer_id;


-- -----------------------------------------------------
-- Query/ Modify Booking Table 
-- -----------------------------------------------------

-- sum the number of rows in booking table
SELECT count(*) from booking;
-- use 18 chars of the customer name attribute to find number of unique customers.
-- explain analyze

-- Use index to quickly find rows with specific column values.
SHOW INDEXES FROM BOOKING;

SELECT 
	count(Distinct left(purchase_order_no, 14)) No_of_Boookings
from
	booking;
    
-- Query to check which customers have not placed any bookings yet using 'NOT IN'.
SELECT company_name
	FROM
		Customer
	WHERE
		Customer_id NOT IN (SELECT distinct
				Customer_id
			FROM
				Booking);

-- -----------------------------------------------------
-- Query/ Modify Part Table 
-- -----------------------------------------------------

DESCRIBE Part;

-- Using trigger 'tr_update_inventory' to update stock quantity in the part table 
UPDATE part
SET stock_quantity= "14"
WHERe part_number= "1000013700";

SELECT * FROM inventory_count;

-- updating the part price
UPDATE part
SET price = 39.95
WHERE part_desc = "Test Leads";

SELECT * FROM part_audit;

-- Return the description and price of part whose price is greater than or equal to all prices returned from the Part table
SELECT part_desc, price
FROM Part
WHERE price >= ALL
	(SELECT price
	 FROM Customer);
     
ALTER Table Part
ADD Column costPrice decimal(5,2) after stock_quantity;

DELETE FROM Part;
insert into Part values
(1000022558, 'Main PCB 4 Channel', 10, 336.00, 560.00, 'PMS\ US'),
(1000013720, 'Top Cover', 6, 177.00, 295.00, 'PMS\ US'),
(1000013700, 'Laser Diode', 10, 460.80, 768.00, 'PMS\ US'),
(1000013723, 'Top Cover', 40, 177.00, 295.00, 'PMS\ US'),
(1000003314, 'Laser Dump Spot', 6, 57.00, 95.00, 'PMS\ US'),
(1000009079, 'Mirror', 50, 165.00, 275.00, 'PMS\ US'),
(1000016543, 'Test Leads', 12, 26.97, 44.95, 'PMS\ Au');

SELECT * from Part;

DESC Part;


-- -----------------------------------------------------
-- Query/ Modify Queries Table 
-- -----------------------------------------------------
SELECT * FROM queries;  -- verify insert operation
REPLACE INTO Queries(customer_id,staff_id,queryDate,queryType) -- update/change query type in Booking table from 'booking' to 'zoom meeting'
	VALUES(006, 109, '2020-10-16', 'Zoom Meeting');

SELECT * FROM queries; -- verify insert operation

-- Return query type and date containing the subject 'booking' or whatever you wish to search
SELECT queryType, queryDate
	FROM Customer JOIN Queries
    ON Customer.customer_id=Queries.customer_id
    WHERE queryType LIKE '%Booking';

-- -----------------------------------------------------
-- Query/ Modify carriesOut Table 
-- -----------------------------------------------------
DESC carriesOut;

SELECT * FROM carriesOut CROSS JOIN Uses;

-- Query the number of parts used and carried out by which employee. 
SELECT staff_id, part_number, quantity 
	FROM carriesOut INNER JOIN uses
    ON carriesOut.job_no=Uses.job_no;

-- Generate the sum (hours) labour by employee   
SELECT staff_id, SUM(timeTaken / 10000) AS Total_Hrs_Labour
	FROM carriesOut
	GROUP BY staff_id WITH ROLLUP; -- Ooutput subtotal and grand total of each employee labour hours on a job
    
COMMIT;
