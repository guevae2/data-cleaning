/****** Data Cleaning & Exploratoty Query

column details
-- hire date - shows the hiring date of the employee
-- emp_email - email address of the employee, with the emp number on the username.
-- sup_email - email address of the supervisors, with the initials of th supervisor on the username.
-- Org_Name -- Organization where the emp is included
-- Org_Code -- Code for each Organization 

-- Data Cleaning Task
 1. Get the date standard SQL date
 2. Create a column for emp_numner and supervisor
 3. Fill in values in the NULL values in the Org_Name column, using Org_Code
 4. Remove duplicate values
 5. Remove unecessary columns

 -- Query Tasks
 1. How many employees where hired each hire date
 2. How many employees per supervisor
 3. How many employees per Org_Name
*******/

-- Overview of the data
SELECT
	*
FROM
	roster;
-- hire date shows date and time, we need to extract just the date of the column
SELECT
	hire_date,
	CONVERT(DATE,hire_date) -- SQL date format should work on our query later yyyy-mm-dd
FROM
	roster;
-- Replacing the date values on hire_date with the converted date
ALTER TABLE roster
	ADD HireDate DATE BEFORE hire_date;
UPDATE roster
	SET HireDate = CONVERT(DATE,hire_date);

-- Validating the table
SELECT
	*
FROM
	roster;

-- Next we will create a new column for emp_number by extracting the username in emp_email

SELECT
	emp_email,
	SUBSTRING(emp_email,1,CHARINDEX('@',emp_email)-1) as emp_number
FROM
	roster;

-- Creating a new table for emp_number
ALTER TABLE roster
	ADD emp_number NVARCHAR(255);
UPDATE roster
	SET emp_number = SUBSTRING(emp_email,1,CHARINDEX('@',emp_email)-1);

-- Creating a new table for sup_initial using PARSENAME
-- Exploring code for PARSENAME
SELECT
	sup_email,
	UPPER(REVERSE(PARSENAME(REPLACE(REVERSE(sup_email),'@','.'),1))) as sup_initial
FROM
	roster
/*** UPPER to capitalize the result, 
	 REVERSE to read the string on a reversed order, 
	 REPLACE to replace '@' to . since PARSENAME identifies only .
***/

-- Adding a new column for sup_initial
ALTER TABLE roster
	ADD sup_initial NVARCHAR(5);

UPDATE roster
	SET sup_initial = UPPER(REVERSE(PARSENAME(REPLACE(REVERSE(sup_email),'@','.'),1)));

-- Filling in NULL valies in Org_Name using Org_Code
-- Checking NULL Values on Org_Name
SELECT
	Org_Name,
	SUM(CASE WHEN Org_Name IS NULL THEN 1 ELSE 0 END) as Org_Name_null_count
	
FROM
	roster

GROUP BY
	Org_Name
HAVING 
	SUM(CASE WHEN Org_Name IS NULL THEN 1 ELSE 0 END) >0
-- We have 116 NULL values in Org_Name

-- Let see what are the Org_Codes of that NULL values.

SELECT
	Org_Code,
	SUM(CASE WHEN Org_Name IS NULL THEN 1 ELSE 0 END) as Org_Name_null_count
	
FROM
	roster

GROUP BY
	Org_Code
HAVING 
	SUM(CASE WHEN Org_Name IS NULL THEN 1 ELSE 0 END) >0
-- Filling in NULL values in Org_Name
-- We can use the equivalent Org_Code to fill in the NULL values in Org_Name
-- Let's create a subquery for the equivalence of the Org_Code and the Org_Name

SELECT
	CASE WHEN r.Org_Name IS NULL THEN a.Org_Name ELSE r.Org_Name END 

FROM

(SELECT
	Org_Code,
	Org_Name

FROM
	roster
WHERE Org_Name IS NOT NULL

GROUP BY
	Org_Code,
	Org_Name ) as a

RIGHT JOIN roster as r
	ON a.Org_Code = r.Org_Code;


-- Updating the Org_Name column to fill the NULL values

UPDATE roster
	SET Org_Name = 

		CASE WHEN r.Org_Name IS NULL THEN a.Org_Name ELSE r.Org_Name END 
		FROM
			(SELECT
				Org_Code,
				Org_Name

			FROM
				roster
			WHERE Org_Name IS NOT NULL

			GROUP BY
				Org_Code,
				Org_Name ) as a

			RIGHT JOIN roster as r
				ON a.Org_Code = r.Org_Code;


-- Removing duplicates
-- currently we have 1453 observations on the table

SELECT
	*
FROM
	roster;


-- Let's check the table for emp_number duplicates
-- We used ROW_NUMBER() to create a row number on every PARTITION BY value which in this case is emp_number.
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY emp_number ORDER BY emp_number) dupe_row
FROM
	roster;

-- Now, we will remove the duplicate rows on the table, rememer we have 1453 rows on the table

-- We will use WITH function works like a temp table, to get the dupe_row filtered and deleted

WITH dupe AS(
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY emp_number ORDER BY emp_number) dupe_row
FROM
	roster
	)
DELETE
FROM dupe
WHERE dupe_row >1;

-- Let's validate the step we did by counting how many rows left

SELECT
	*
FROM
	roster;

-- Now we have 1229 rows left on the table
-- you can validate if there's any duplicated values by running the followng code :
WITH dupe AS(
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY emp_number ORDER BY emp_number) dupe_row
FROM
	roster
	)
SELECT
	*
FROM dupe
WHERE dupe_row >1;
-- If the query does not show any values, means that there are no duplicates on the table.


-- ## Removing Unecessary Columns
-- ## F6, F7 and F8 columns are our unecessary columns on the table


ALTER TABLE roster
DROP COLUMN
	hire_date;

SELECT
	*
FROM
	roster;

/* Query Tasks, data exploration
 1. How many employees where hired each Month
 2. How many employees per supervisor
 3. How many employees per Org_Name */


 --  1. How many employees where hired each Month
 SELECT
	CONCAT(MONTH(HireDate) , '-' , YEAR(HireDate)) as Month_Year, -- CONCAT() to combine the 2 formulas for Month and Year
	COUNT(emp_number) as count_of_employees -- we used count to specify the how many

FROM
	roster
GROUP BY
	CONCAT(MONTH(HireDate) , '-' , YEAR(HireDate))
	
ORDER BY
	CONCAT(MONTH(HireDate) , '-' , YEAR(HireDate));


-- 2. A Supervisor resigned and left 3 employees without a supervisor, let's assign them to a new supervisor

-- Let's find out what Org_Name was the resigened supervisor working to.
SELECT
	sup_initial,
	Org_Name,
	COUNT(emp_number)
	
FROM
	roster
WHERE sup_initial IS NULL

GROUP BY
	sup_initial,
	Org_Name
-- The Supervisor was with Sales Organization

-- Now, we will identify the employees that was reported to the supervisor that resigned
SELECT
	emp_number,
	sup_initial,
	Org_Name
FROM
	roster
WHERE sup_initial IS NULL;

-- We will be looking for a Supervisor in Sales to assign the 3 employees.

SELECT
	sup_initial,
	Org_Name,
	COUNT(emp_number)
	
FROM
	roster
WHERE Org_Name = 'Sales'

GROUP BY
	sup_initial,
	Org_Name


