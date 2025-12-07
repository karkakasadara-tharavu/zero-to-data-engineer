/*
 * Lab 21: Database Normalization
 * Module 04: Database Administration
 * 
 * Objective: Transform an unnormalized database through normalization forms (1NF, 2NF, 3NF, BCNF)
 * Duration: 3-4 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

IF DB_ID('NormalizationLab') IS NOT NULL
BEGIN
    ALTER DATABASE NormalizationLab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NormalizationLab;
END;
GO

CREATE DATABASE NormalizationLab;
GO

USE NormalizationLab;
GO

/*
 * UNNORMALIZED DATA (0NF)
 * 
 * Problem: Single table with repeating groups, multiple values in columns,
 * calculated fields stored, redundant data
 */

PRINT 'Creating UNNORMALIZED table (0NF)...';
GO

CREATE TABLE StudentCourses_Unnormalized (
    StudentID INT,
    StudentName NVARCHAR(100),
    StudentEmail NVARCHAR(100),
    StudentPhone NVARCHAR(20),
    Address NVARCHAR(300),  -- Multiple parts in one field
    Courses NVARCHAR(MAX),  -- Multiple courses comma-separated
    Instructors NVARCHAR(MAX),  -- Multiple instructors comma-separated
    CourseCredits NVARCHAR(100),  -- Multiple credit values
    TotalCredits INT,  -- Calculated/derived field
    DeptName NVARCHAR(100),
    DeptPhone NVARCHAR(20),
    DeptBuilding NVARCHAR(50)
);
GO

-- Insert sample unnormalized data
INSERT INTO StudentCourses_Unnormalized VALUES
(1001, 'Alice Johnson', 'alice@email.com', '555-0101', '123 Main St, NY, 10001', 
 'CS101,CS102,MATH201', 'Dr. Smith,Dr. Jones,Prof. Davis', '3,3,4', 10,
 'Computer Science', '555-CS-DEPT', 'Building A'),
(1002, 'Bob Smith', 'bob@email.com', '555-0102', '456 Oak Ave, LA, 90001',
 'CS101,ENG101', 'Dr. Smith,Prof. Wilson', '3,3', 6,
 'Computer Science', '555-CS-DEPT', 'Building A'),
(1003, 'Carol White', 'carol@email.com', '555-0103', '789 Pine Rd, Chicago, 60601',
 'MATH201,PHYS101', 'Prof. Davis,Dr. Brown', '4,4', 8,
 'Mathematics', '555-MATH-DEPT', 'Building B');
GO

SELECT * FROM StudentCourses_Unnormalized;
GO

/*
 * FIRST NORMAL FORM (1NF)
 * 
 * Rules:
 * 1. Eliminate repeating groups
 * 2. Create separate row for each set of related data
 * 3. Each column must have atomic (indivisible) values
 * 4. Each row must be unique (add primary key)
 */

PRINT '';
PRINT 'Applying 1NF - Eliminating repeating groups...';
GO

-- TODO: Create Students_1NF table
CREATE TABLE Students_1NF (
    StudentID INT PRIMARY KEY,
    StudentName NVARCHAR(100) NOT NULL,
    StudentEmail NVARCHAR(100) NOT NULL UNIQUE,
    StudentPhone NVARCHAR(20),
    StreetAddress NVARCHAR(200),  -- Atomic now
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(10),
    DeptName NVARCHAR(100),
    DeptPhone NVARCHAR(20),
    DeptBuilding NVARCHAR(50)
);
GO

-- TODO: Create Enrollments_1NF table (breaking down the many-to-many)
CREATE TABLE Enrollments_1NF (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    CourseCode NVARCHAR(20) NOT NULL,
    InstructorName NVARCHAR(100),
    Credits INT NOT NULL,
    DeptName NVARCHAR(100),
    DeptPhone NVARCHAR(20),
    DeptBuilding NVARCHAR(50)
);
GO

-- Insert data into 1NF tables
INSERT INTO Students_1NF (StudentID, StudentName, StudentEmail, StudentPhone, 
                          StreetAddress, City, State, ZipCode,
                          DeptName, DeptPhone, DeptBuilding) VALUES
(1001, 'Alice Johnson', 'alice@email.com', '555-0101', 
 '123 Main St', 'NY', 'NY', '10001',
 'Computer Science', '555-CS-DEPT', 'Building A'),
(1002, 'Bob Smith', 'bob@email.com', '555-0102',
 '456 Oak Ave', 'LA', 'CA', '90001',
 'Computer Science', '555-CS-DEPT', 'Building A'),
(1003, 'Carol White', 'carol@email.com', '555-0103',
 '789 Pine Rd', 'Chicago', 'IL', '60601',
 'Mathematics', '555-MATH-DEPT', 'Building B');

INSERT INTO Enrollments_1NF (StudentID, CourseCode, InstructorName, Credits, DeptName, DeptPhone, DeptBuilding) VALUES
(1001, 'CS101', 'Dr. Smith', 3, 'Computer Science', '555-CS-DEPT', 'Building A'),
(1001, 'CS102', 'Dr. Jones', 3, 'Computer Science', '555-CS-DEPT', 'Building A'),
(1001, 'MATH201', 'Prof. Davis', 4, 'Mathematics', '555-MATH-DEPT', 'Building B'),
(1002, 'CS101', 'Dr. Smith', 3, 'Computer Science', '555-CS-DEPT', 'Building A'),
(1002, 'ENG101', 'Prof. Wilson', 3, 'English', '555-ENG-DEPT', 'Building C'),
(1003, 'MATH201', 'Prof. Davis', 4, 'Mathematics', '555-MATH-DEPT', 'Building B'),
(1003, 'PHYS101', 'Dr. Brown', 4, 'Physics', '555-PHYS-DEPT', 'Building D');
GO

PRINT '1NF Applied: Data is now atomic, no repeating groups';
SELECT * FROM Students_1NF;
SELECT * FROM Enrollments_1NF;
GO

/*
 * SECOND NORMAL FORM (2NF)
 * 
 * Rules:
 * 1. Must be in 1NF
 * 2. Remove partial dependencies (attributes dependent on part of composite key)
 * 3. All non-key attributes must depend on the entire primary key
 */

PRINT '';
PRINT 'Applying 2NF - Removing partial dependencies...';
GO

-- Students table is already good (single column PK)
-- But we need to split Enrollments further

CREATE TABLE Students_2NF (
    StudentID INT PRIMARY KEY,
    StudentName NVARCHAR(100) NOT NULL,
    StudentEmail NVARCHAR(100) NOT NULL UNIQUE,
    StudentPhone NVARCHAR(20),
    StreetAddress NVARCHAR(200),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(10),
    DeptName NVARCHAR(100)  -- Still some dependency issues here
);
GO

CREATE TABLE Courses_2NF (
    CourseCode NVARCHAR(20) PRIMARY KEY,
    CourseName NVARCHAR(200),
    Credits INT NOT NULL,
    DeptName NVARCHAR(100),
    InstructorName NVARCHAR(100)
);
GO

CREATE TABLE Enrollments_2NF (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    CourseCode NVARCHAR(20) NOT NULL,
    EnrollmentDate DATE DEFAULT GETDATE(),
    Grade CHAR(2),
    
    FOREIGN KEY (StudentID) REFERENCES Students_2NF(StudentID),
    FOREIGN KEY (CourseCode) REFERENCES Courses_2NF(CourseCode)
);
GO

-- Insert data
INSERT INTO Students_2NF SELECT StudentID, StudentName, StudentEmail, StudentPhone,
                                StreetAddress, City, State, ZipCode, DeptName
FROM Students_1NF;

INSERT INTO Courses_2NF (CourseCode, CourseName, Credits, DeptName, InstructorName) VALUES
('CS101', 'Introduction to Computer Science', 3, 'Computer Science', 'Dr. Smith'),
('CS102', 'Data Structures', 3, 'Computer Science', 'Dr. Jones'),
('MATH201', 'Calculus II', 4, 'Mathematics', 'Prof. Davis'),
('ENG101', 'English Composition', 3, 'English', 'Prof. Wilson'),
('PHYS101', 'Physics I', 4, 'Physics', 'Dr. Brown');

INSERT INTO Enrollments_2NF (StudentID, CourseCode) VALUES
(1001, 'CS101'), (1001, 'CS102'), (1001, 'MATH201'),
(1002, 'CS101'), (1002, 'ENG101'),
(1003, 'MATH201'), (1003, 'PHYS101');
GO

PRINT '2NF Applied: Removed partial dependencies';
GO

/*
 * THIRD NORMAL FORM (3NF)
 * 
 * Rules:
 * 1. Must be in 2NF
 * 2. Remove transitive dependencies (non-key attribute depends on another non-key attribute)
 * 3. All attributes must depend directly on primary key only
 */

PRINT '';
PRINT 'Applying 3NF - Removing transitive dependencies...';
GO

-- Create Departments table (DeptName determines DeptPhone, DeptBuilding)
CREATE TABLE Departments_3NF (
    DeptID INT PRIMARY KEY IDENTITY(1,1),
    DeptName NVARCHAR(100) NOT NULL UNIQUE,
    DeptPhone NVARCHAR(20),
    DeptBuilding NVARCHAR(50),
    DeptChair NVARCHAR(100)
);
GO

-- Create Instructors table
CREATE TABLE Instructors_3NF (
    InstructorID INT PRIMARY KEY IDENTITY(1,1),
    InstructorName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    DeptID INT,
    
    FOREIGN KEY (DeptID) REFERENCES Departments_3NF(DeptID)
);
GO

-- Students with DeptID reference
CREATE TABLE Students_3NF (
    StudentID INT PRIMARY KEY,
    StudentName NVARCHAR(100) NOT NULL,
    StudentEmail NVARCHAR(100) NOT NULL UNIQUE,
    StudentPhone NVARCHAR(20),
    StreetAddress NVARCHAR(200),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(10),
    DeptID INT,
    
    FOREIGN KEY (DeptID) REFERENCES Departments_3NF(DeptID)
);
GO

-- Courses with proper references
CREATE TABLE Courses_3NF (
    CourseCode NVARCHAR(20) PRIMARY KEY,
    CourseName NVARCHAR(200) NOT NULL,
    Credits INT NOT NULL CHECK (Credits > 0),
    DeptID INT,
    InstructorID INT,
    
    FOREIGN KEY (DeptID) REFERENCES Departments_3NF(DeptID),
    FOREIGN KEY (InstructorID) REFERENCES Instructors_3NF(InstructorID)
);
GO

-- Enrollments (clean)
CREATE TABLE Enrollments_3NF (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    CourseCode NVARCHAR(20) NOT NULL,
    EnrollmentDate DATE DEFAULT GETDATE(),
    Grade CHAR(2),
    
    FOREIGN KEY (StudentID) REFERENCES Students_3NF(StudentID),
    FOREIGN KEY (CourseCode) REFERENCES Courses_3NF(CourseCode),
    CONSTRAINT UQ_Enrollment UNIQUE (StudentID, CourseCode)
);
GO

-- Insert data into 3NF tables
INSERT INTO Departments_3NF (DeptName, DeptPhone, DeptBuilding, DeptChair) VALUES
('Computer Science', '555-CS-DEPT', 'Building A', 'Dr. Alan Turing'),
('Mathematics', '555-MATH-DEPT', 'Building B', 'Prof. Grace Hopper'),
('English', '555-ENG-DEPT', 'Building C', 'Prof. Margaret Atwood'),
('Physics', '555-PHYS-DEPT', 'Building D', 'Dr. Marie Curie');

INSERT INTO Instructors_3NF (InstructorName, Email, DeptID) VALUES
('Dr. Smith', 'smith@university.edu', 1),
('Dr. Jones', 'jones@university.edu', 1),
('Prof. Davis', 'davis@university.edu', 2),
('Prof. Wilson', 'wilson@university.edu', 3),
('Dr. Brown', 'brown@university.edu', 4);

INSERT INTO Students_3NF (StudentID, StudentName, StudentEmail, StudentPhone,
                          StreetAddress, City, State, ZipCode, DeptID) VALUES
(1001, 'Alice Johnson', 'alice@email.com', '555-0101', 
 '123 Main St', 'NY', 'NY', '10001', 1),
(1002, 'Bob Smith', 'bob@email.com', '555-0102',
 '456 Oak Ave', 'LA', 'CA', '90001', 1),
(1003, 'Carol White', 'carol@email.com', '555-0103',
 '789 Pine Rd', 'Chicago', 'IL', '60601', 2);

INSERT INTO Courses_3NF (CourseCode, CourseName, Credits, DeptID, InstructorID) VALUES
('CS101', 'Introduction to Computer Science', 3, 1, 1),
('CS102', 'Data Structures', 3, 1, 2),
('MATH201', 'Calculus II', 4, 2, 3),
('ENG101', 'English Composition', 3, 3, 4),
('PHYS101', 'Physics I', 4, 4, 5);

INSERT INTO Enrollments_3NF (StudentID, CourseCode, Grade) VALUES
(1001, 'CS101', 'A'),
(1001, 'CS102', 'A-'),
(1001, 'MATH201', 'B+'),
(1002, 'CS101', 'B'),
(1002, 'ENG101', 'A'),
(1003, 'MATH201', 'A'),
(1003, 'PHYS101', 'A-');
GO

PRINT '3NF Applied: All transitive dependencies removed';
PRINT '';
PRINT 'Final normalized schema:';
EXEC sp_help 'Departments_3NF';
EXEC sp_help 'Instructors_3NF';
EXEC sp_help 'Students_3NF';
EXEC sp_help 'Courses_3NF';
EXEC sp_help 'Enrollments_3NF';
GO

-- Verification query showing all relationships
PRINT 'Student Enrollment Report with all details:';
SELECT 
    s.StudentID,
    s.StudentName,
    s.StudentEmail,
    sd.DeptName AS StudentDept,
    c.CourseCode,
    c.CourseName,
    c.Credits,
    cd.DeptName AS CourseDept,
    i.InstructorName,
    e.Grade,
    e.EnrollmentDate
FROM Enrollments_3NF e
JOIN Students_3NF s ON e.StudentID = s.StudentID
JOIN Courses_3NF c ON e.CourseCode = c.CourseCode
JOIN Departments_3NF sd ON s.DeptID = sd.DeptID
JOIN Departments_3NF cd ON c.DeptID = cd.DeptID
JOIN Instructors_3NF i ON c.InstructorID = i.InstructorID
ORDER BY s.StudentName, c.CourseCode;
GO

/*
 * BOYCE-CODD NORMAL FORM (BCNF)
 * 
 * Rules:
 * 1. Must be in 3NF
 * 2. Every determinant must be a candidate key
 * 3. Eliminate any remaining anomalies from functional dependencies
 * 
 * In most cases, if your database is in 3NF and doesn't have
 * composite candidate keys, it's already in BCNF.
 * 
 * Our design above is already in BCNF!
 */

PRINT '';
PRINT '✓ Database is in BCNF (Boyce-Codd Normal Form)';
GO

/*
 * EXERCISES:
 * 
 * 1. Identify anomalies in the unnormalized table:
 *    - Insert anomaly: Can't add a department without a student
 *    - Update anomaly: Changing dept phone requires multiple updates
 *    - Delete anomaly: Deleting last student removes department info
 * 
 * 2. Add a CoursePrerequisites table (CourseCode, PrerequisiteCode)
 * 
 * 3. Create a view that shows:
 *    - Student name, total credits enrolled, GPA
 * 
 * 4. Write a query to find courses with no enrollments
 * 
 * 5. Calculate storage savings from normalization
 * 
 * CHALLENGE:
 * Design a table structure for a hospital database (patients, doctors, 
 * appointments, prescriptions) and normalize to 3NF/BCNF
 */
