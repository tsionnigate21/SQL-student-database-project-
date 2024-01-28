-- 1)
ALTER TABLE NewStudent
ADD CONSTRAINT FK_Student_FacultyAdvisor
FOREIGN KEY (ADVISOR_ID) REFERENCES NewFaculty(FACULTY_ID);

ALTER TABLE NewCourseOffering
ADD CONSTRAINT FK_Courses_CourseOffering
FOREIGN KEY (Course_ID) REFERENCES NewCourses([Course_ID]);

ALTER TABLE NewEnrollment
ADD FOREIGN KEY ([Student_ID]) REFERENCES NewStudent([Student_ID]);

ALTER TABLE NewEnrollment
ADD FOREIGN KEY ([Course_Offering_ID]) REFERENCES NewCourseOffering([Course_Offering_ID]);

ALTER TABLE NewCourseOffering
ADD FOREIGN KEY ([Instructor_ID]) REFERENCES NewFaculty([Faculty_ID]);

ALTER TABLE NewGrade
ADD FOREIGN KEY ([Student_ID]) REFERENCES NewStudent([Student_ID]);

ALTER TABLE NewDepartment
ADD FOREIGN KEY ([Chair_ID]) REFERENCES NewFaculty([Faculty_ID]);

ALTER TABLE NewMajor
ADD FOREIGN KEY ([Department_ID]) REFERENCES NewDepartment([Department_ID]);



-- 2)
IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'NewGrade'
    AND COLUMN_NAME = 'GradePoints'
)
BEGIN
    ALTER TABLE dbo.NewGrade
    ADD GradePoints FLOAT;
END

-- Update statements for grade points
UPDATE NewGrade SET GradePoints = 4.33 WHERE [FINAL_LETTER_GRADE] = 'A+';
UPDATE NewGrade SET gradePoints = 4.00 WHERE [FINAL_LETTER_GRADE] = 'A';
UPDATE NewGrade SET gradePoints = 3.67 WHERE [FINAL_LETTER_GRADE] = 'A-';
UPDATE NewGrade SET gradePoints = 3.33 WHERE [FINAL_LETTER_GRADE] = 'B+';
UPDATE NewGrade SET gradePoints = 3.00 WHERE [FINAL_LETTER_GRADE] = 'B';
UPDATE NewGrade SET gradePoints = 2.67 WHERE [FINAL_LETTER_GRADE] = 'B-';
UPDATE NewGrade SET gradePoints = 2.33 WHERE [FINAL_LETTER_GRADE] = 'C+';
UPDATE NewGrade SET gradePoints = 2.00 WHERE [FINAL_LETTER_GRADE] = 'C';
UPDATE NewGrade SET gradePoints = 1.67 WHERE [FINAL_LETTER_GRADE] = 'C-';
UPDATE NewGrade SET gradePoints = 1.33 WHERE [FINAL_LETTER_GRADE] = 'D+';
UPDATE NewGrade SET gradePoints = 1.00 WHERE [FINAL_LETTER_GRADE] = 'D';
UPDATE NewGrade SET gradePoints = 0.67 WHERE [FINAL_LETTER_GRADE] = 'D-';
UPDATE NewGrade SET gradePoints = 0.00 WHERE [FINAL_LETTER_GRADE] = 'F';

select * from NewGrade

-- 3)
ALTER TABLE NewStudent
ADD CumulativeGPA decimal(3,2);

UPDATE NewStudent
SET CumulativeGPA = (
    SELECT
        SUM(NewGrade.gradePoints * NCO.CREDIT_HOURS) / SUM(NCO.CREDIT_HOURS) AS CurrentGPA
    FROM
        NewGrade
	JOIN NewCourseOffering NCO on NewGrade.COURSE_OFFERING_ID = NCO.COURSE_OFFERING_ID
    WHERE
        NewGrade.STUDENT_ID = NewStudent.STUDENT_ID
);


-- 4)

CREATE VIEW AverageGPAPerClassLevel AS
SELECT
    CLASS_LEVEL,
    AVG(cumulativeGPA) AS AverageGPA
FROM
    dbo.NewStudent
GROUP BY
    CLASS_LEVEL;


-- 5)
CREATE VIEW AverageGPAPerMajor AS
SELECT
    major,
    AVG(cumulativeGPA) AS AverageGPA
FROM
    dbo.NewStudent
GROUP BY
    major;



-- 6)

CREATE VIEW TotalStudentsEnrolledPerDeptAndPerTerm AS
SELECT
    NCO.term AS Term,
    NC.Department AS DepartmentID,
    COUNT(DISTINCT G.STUDENT_ID) AS TotalStudents
FROM
    dbo.NewCourseOffering NCO
INNER JOIN
    dbo.NewGrade G ON NCO.[COURSE_OFFERING_ID] = G.[Course_Offering_ID]
INNER JOIN
    dbo.NewCourses NC ON NCO.[Course_ID] = NC.[Course_ID]  
GROUP BY
    NCO.term,
    NC.[Department];


-- 7)
CREATE VIEW StudentsPerMajor AS
SELECT
    Major,
    COUNT(DISTINCT Student_ID) AS NumberOfStudents
FROM
    NewStudent 
GROUP BY
    Major

SELECT
    Major,
    NumberOfStudents
FROM
    StudentsPerMajor
ORDER BY
    NumberOfStudents desc;


--8)


CREATE VIEW EnrollmentsByStateView AS
SELECT
    CO.term AS Term,
    NS.State AS State,
    COUNT(NE.Student_id) AS EnrollmentCount
FROM
    NewEnrollment NE
JOIN
    NewStudent NS ON NE.Student_id = NS.Student_id
JOIN
    NewCourseOffering CO ON NE.Course_offering_id = CO.Course_offering_id
GROUP BY
    CO.term, NS.State

select * 
from EnrollmentsByStateView
ORDER BY term, EnrollmentCount DESC;



--9)
CREATE VIEW FacultySalariesView AS
SELECT
    Department,
    COUNT(*) AS FacultyCount,
    SUM(Salary) AS TotalSalary,
    AVG(Salary) AS AverageSalary
FROM
    NewFaculty
WHERE
    Status = 'Active'
    AND IS_FULL_TIME = 'Yes'
GROUP BY
    Department;



-- 10)

ALTER TABLE NewStudent
ADD CONSTRAINT UC_Student_Email UNIQUE (email_adress);


-- 11)
ALTER TABLE NewGrade
ADD CONSTRAINT CK_Grades_ValidValue
CHECK (final_letter_grade IN ('A+','A','A-','B+','B', 'B-', 'C+','C','C-', 'D+', 'D','D-', 'F', 'I'));


-- 12)
ALTER TABLE NewStudent
ADD CONSTRAINT CK_Students_GradeLevel
CHECK (class_level IN ('Freshman', 'Sophomore', 'Junior', 'Senior'));


-- 13)
ALTER TABLE NewStudent
ADD CONSTRAINT CK_Students_Status
CHECK (status IN ('Active', 'Inactive', 'Alumni'));


-- 14)
UPDATE NewCourses SET COURSE_NAME = 'ACCT Directed Study' WHERE COURSE_ID = 6;
UPDATE NewCourses SET COURSE_NAME = 'BUSN Directed Study' WHERE COURSE_ID = 36;
UPDATE NewCourses SET COURSE_NAME = 'ACCT Independent Study' WHERE COURSE_ID = 12;
UPDATE NewCourses SET COURSE_NAME = 'BUSN Independent Study' WHERE COURSE_ID = 37;

ALTER TABLE NewCourses
ADD CONSTRAINT UC_Courses_CourseName UNIQUE (Course_Name);


-- 15)
ALTER TABLE NewFaculty
ADD CONSTRAINT UC_Faculty_Email UNIQUE (email_address);


-- 16) 
UPDATE NewFaculty set Status = 'Terminated' where Status = 'Inactive' 
ALTER TABLE NewFaculty 
ADD CONSTRAINT chk_faculty_status 
CHECK (status IN ('Active', 'Terminated', 'Emeritus'));


-- 17) 
CREATE PROCEDURE InsertStudentRecord
    @student_id float,
    @first_name NVARCHAR(255),
    @middle_name NVARCHAR(255),
    @last_name NVARCHAR(255),
    @Email_address NVARCHAR(255),
    @Major NVARCHAR(255),
    @class_level NVARCHAR(255),
    @advisor_id float,
    @first_enrolled_date float,
    @address NVARCHAR(255),
    @birth_date datetime,
    @CumulativeGPA DECIMAL(3, 2),
    @State NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM NewMajor WHERE Major_name = @Major) OR
       NOT EXISTS (SELECT 1 FROM NewFaculty WHERE FACULTY_ID = @advisor_id)
    BEGIN
        RETURN;
    END

    INSERT INTO NewStudent (
        student_id,
        first_name,
        middle_name,
        last_name,
        Email_adress,
        Major,
        class_level,
        advisor_id,
        status,
        first_enrolled_date,
        address,
        birth_date,
        CumulativeGPA,
        State
    )
    VALUES (
        @student_id,
        @first_name,
        @middle_name,
        @last_name,
        @Email_address,
        @Major,
        @class_level,
        @advisor_id,
        'Active',
        @first_enrolled_date,
        @address,
        @birth_date,
        @CumulativeGPA,
        @State
    );
END;

-- 18) 
CREATE PROCEDURE UpdateStudentRecord
    @student_id float,
    @first_name NVARCHAR(255),
    @middle_name NVARCHAR(255),
    @last_name NVARCHAR(255),
    @Email_address NVARCHAR(255),
    @Major NVARCHAR(255),
    @class_level NVARCHAR(255),
    @advisor_id float,
    @first_enrolled_date float,
    @address NVARCHAR(255),
    @birth_date datetime,
    @CumulativeGPA DECIMAL(3, 2),
    @State NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM NewMajor WHERE Major_name = @Major) OR
       NOT EXISTS (SELECT 1 FROM NewFaculty WHERE FACULTY_ID = @advisor_id)
    BEGIN
        RETURN;
    END
UPDATE NewStudent
    SET
        first_name = @first_name,
        middle_name = @middle_name,
        last_name = @last_name,
        Email_adress = @Email_address,
        Major = @Major,
        class_level = @class_level,
        advisor_id = @advisor_id,
        first_enrolled_date = @first_enrolled_date,
        address = @address,
        birth_date = @birth_date,
        CumulativeGPA = @CumulativeGPA,
        State = @State
    WHERE
        student_id = @student_id;
END;


-- 19) 
CREATE PROCEDURE InsertFacultyRecord
    @faculty_id float,
    @first_name NVARCHAR(255),
    @middle_name NVARCHAR(255),
    @last_name NVARCHAR(255),
    @email_address NVARCHAR(255),
    @is_an_advisor NVARCHAR(255),
    @is_department NVARCHAR(255),
    @is_an_instructor NVARCHAR(255),
    @is_tenured NVARCHAR(255),
    @is_full_time NVARCHAR(255),
    @status NVARCHAR(255),
    @hire_date NVARCHAR(255),
    @termination_date DATEtime,
    @salary float
AS
BEGIN
    SET NOCOUNT ON;

    
    IF (@is_an_advisor = 'Yes' OR @is_department = 'Yes' OR @is_tenured = 'Yes') AND @is_full_time = 'No'
    BEGIN
        RETURN;
    END

    INSERT INTO NewFaculty (
        faculty_id,
        first_name,
        middle_name,
        last_name,
        email_address,
        is_an_advisor,
        is_department_chair,
        is_an_instructor,
        is_tenured,
        is_full_time,
        Status,
        hire_date,
        termination_date,
        salary
    )
    VALUES (
        @faculty_id,
        @first_name,
        @middle_name,
        @last_name,
        @email_address,
        @is_an_advisor,
        @is_department,
        @is_an_instructor,
        @is_tenured,
        @is_full_time,
        @status,
        @hire_date,
        @termination_date,
        @salary
    );
END;


-- 20)
CREATE PROCEDURE UpdateFacultyRecord
    @faculty_id float,
    @first_name NVARCHAR(255),
    @middle_name NVARCHAR(255),
    @last_name NVARCHAR(255),
    @email_address NVARCHAR(255),
    @is_an_advisor NVARCHAR(255),
    @is_department NVARCHAR(255),
    @is_an_instructor NVARCHAR(255),
    @is_tenured NVARCHAR(255),
    @is_full_time NVARCHAR(255),
    @status NVARCHAR(255),
    @hire_date NVARCHAR(255),
    @termination_date DATEtime,
    @salary float
AS
BEGIN
    SET NOCOUNT ON;
    IF (
     
        (@is_an_advisor = 'Yes' OR @is_department = 'Yes' OR @is_tenured = 'Yes') AND @is_full_time = 'No'
        OR
      
        (@status = 'Inactive' AND (@is_an_advisor = 'Yes' OR @is_department = 'Yes' OR @is_an_instructor = 'Yes' OR @is_full_time = 'Yes' OR @is_tenured = 'Yes'))
    )
    BEGIN
        RETURN;
    END

    UPDATE NewFaculty
    SET
        first_name = @first_name,
        middle_name = @middle_name,
        last_name = @last_name,
        email_address = @email_address,
        is_an_advisor = @is_an_advisor,
        IS_DEPARTMENT_CHAIR = @is_department,
        is_an_instructor = @is_an_instructor,
        is_tenured = @is_tenured,
        is_full_time = @is_full_time,
        status = @status,
        hire_date = @hire_date,
        termination_date = @termination_date,
        salary = @salary
    WHERE
        faculty_id = @faculty_id;
END;


-- 21)
CREATE PROCEDURE InsertCourseRecord
    @course_id float,
    @course_number NVARCHAR(255),
    @course_name NVARCHAR(255),
    @course_description NVARCHAR(255),
    @department NVARCHAR(255),
    @status NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF (
        EXISTS (SELECT 1 FROM NewCourses WHERE course_number = @course_number AND status = 'Active')
    )
    BEGIN
        RETURN;
    END

    INSERT INTO NewCourses (
        course_id,
        course_number,
        course_name,
        course_description,
        department,
        status
    )
    VALUES (
        @course_id,
        @course_number,
        @course_name,
        @course_description,
        @department,
        @status
    );
END;


-- 22)
CREATE PROCEDURE UpdateCourseRecord
    @course_id float,
    @course_number NVARCHAR(255),
    @course_name NVARCHAR(255),
    @course_description NVARCHAR(255),
    @department NVARCHAR(255),
    @status NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF (
        EXISTS (SELECT 1 FROM NewCourses WHERE course_number = @course_number AND status = 'Active')
    )
    BEGIN
        RETURN;
    END
	UPDATE NewCourses
    SET
        course_number = @course_number,
        course_name = @course_name,
        course_description = @course_description,
        department = @department,
        status = @status
    WHERE
        course_id = @course_id;
END;



-- 23)
CREATE PROCEDURE InsertCourseOfferingRecord
	@course_offering_id float,
    @course_name NVARCHAR(255),
    @instructor_id float,
    @academic_year float,
    @term NVARCHAR(255),
    @section NVARCHAR(255),
    @credit_hours float,
    @course_id float
AS
BEGIN
    SET NOCOUNT ON;
    IF (
        EXISTS (
            SELECT 1
            FROM NewCourseOffering
            WHERE
                course_id = @course_id
                AND academic_year = @academic_year
                AND term = @term
                AND section = @section
        )
    )
    BEGIN
        RETURN;
    END

    INSERT INTO NewCourseOffering (
	    COURSE_OFFERING_ID,
        course_name,
        instructor_id,
        academic_year,
        term,
        section,
        credit_hours,
        course_id
    )
    VALUES (
		@course_offering_id,
        @course_name,
        @instructor_id,
        @academic_year,
        @term,
        @section,
        @credit_hours,
        @course_id
    );
END;


-- 24)
CREATE PROCEDURE UpdateCourseOfferingRecord
	@course_offering_id float,
    @course_name NVARCHAR(255),
    @instructor_id float,
    @academic_year float,
    @term NVARCHAR(255),
    @section NVARCHAR(255),
    @credit_hours float,
    @course_id float
AS
BEGIN
    SET NOCOUNT ON;
    IF (
        EXISTS (
            SELECT 1
            FROM NewCourseOffering
            WHERE
                course_id = @course_id
                AND academic_year = @academic_year
                AND term = @term
                AND section = @section
        )
    )
    BEGIN
        RETURN;
    END
	UPDATE NewCourseOffering
    SET
		COURSE_OFFERING_ID = @course_offering_id,
        course_name = @course_name,
        instructor_id = @instructor_id,
        academic_year = @academic_year,
        term = @term,
        section = @section,
        credit_hours = @credit_hours,
        course_id = @course_id
    WHERE
        course_offering_id = @course_offering_id;
END;


-- 25)
CREATE PROCEDURE UpdateEnrollmentStatusToComplete
    @academic_term NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM NewCourseOffering
        WHERE Term = @academic_term
    )
    BEGIN
        RETURN;
    END
    UPDATE NewEnrollment
    SET
        status = 'Complete'
    FROM
        NewEnrollment NE
    INNER JOIN
        NewCourseOffering NCO ON NE.course_offering_id = NCO.course_offering_id
    WHERE
        NCO.term = @academic_term
        AND NE.status = 'Enrolled';
END;


-- 26)
CREATE PROCEDURE UpdateGradeStatusToFinal
    @student_id float,
    @course_offering_id float
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE NewGrade
    SET
        status = 'Final'
    WHERE
        student_id = @student_id
        AND course_offering_id = @course_offering_id
        AND final_letter_grade != 'I';
END;