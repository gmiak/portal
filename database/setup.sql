-- Tables

CREATE TABLE  Departments(
	name TEXT NOT NULL,
	abbr TEXT UNIQUE,
	PRIMARY KEY (name)
);
CREATE TABLE  Programs(
	name TEXT NOT NULL,
	abbr TEXT NOT NULL,
	PRIMARY KEY (name)
);
CREATE TABLE Branches (
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY(name,program),
	FOREIGN KEY (program) REFERENCES Programs

);
CREATE TABLE Students (
	idnr VARCHAR(10) check (idnr SIMILAR TO '[0-9]{10}'),
	name TEXT NOT NULL,
	login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL,
	PRIMARY KEY (idnr),
	FOREIGN KEY (program) REFERENCES Programs,
	UNIQUE (idnr,program)
);
CREATE TABLE Courses(
	code VARCHAR(6) check (length(code) = 6),
	name TEXT NOT NULL,
	credits FLOAT NOT NULL check(credits>=0),
	department	TEXT NOT NULL,
	PRIMARY KEY (code),
	FOREIGN KEY (department) REFERENCES Departments
);
CREATE TABLE Classifications(
	 name TEXT PRIMARY KEY
	 );
CREATE TABLE ProgramDepartment(
	 department TEXT NOT NULL,
	 program TEXT NOT NULL,
	 PRIMARY KEY (department, program),
	 FOREIGN KEY (department) REFERENCES Departments,
	 FOREIGN KEY (program) REFERENCES Programs
	 );

CREATE TABLE StudentBranches(
	 student VARCHAR(10) ,
	 branch TEXT NOT NULL,
	 program TEXT NOT Null,
	 PRIMARY KEY (student),
	 FOREIGN KEY (student, program) REFERENCES Students(idnr,program),
	 FOREIGN KEY (branch,program) REFERENCES Branches
	 );
CREATE TABLE LimitedCourses(
	 course VARCHAR(6) PRIMARY KEY,
	 capacity INT NOT NULL check(capacity>=0),
	 FOREIGN KEY (course) REFERENCES Courses
	 );

CREATE TABLE PreRequisities(
	 course VARCHAR(6),
	 requisities VARCHAR(6),
	 PRIMARY KEY(course,requisities),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (requisities) REFERENCES Courses
	 );
CREATE TABLE Classified(
	 course VARCHAR(6),
	 classification TEXT,
	 PRIMARY KEY (course,classification),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (classification) REFERENCES Classifications
	 );
CREATE TABLE MandatoryProgram(
	 course VARCHAR(6),
	 program TEXT NOT NULL,
	 PRIMARY KEY (course,program),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (program) REFERENCES Programs
	 );
CREATE TABLE MandatoryBranch(
	 course VARCHAR(6),
	 branch TEXT NOT NULL,
	 program TEXT NOT NULL,
	 PRIMARY KEY (course,branch, program),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (branch, program) REFERENCES Branches
	 --FOREIGN KEY (program) REFERENCES Branches
	 );
CREATE TABLE RecommendedBranch(
	 course VARCHAR(6),
	 branch TEXT NOT NULL,
	 program TEXT NOT NULL,
	 PRIMARY KEY (course,branch,program),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (branch,program) REFERENCES Branches
	 --FOREIGN KEY (program) REFERENCES Branches
	 );
CREATE TABLE Taken(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 grade CHAR(1)	NOT NULL check ( grade IN ('U','3','4','5')),
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses
	 );
CREATE TABLE Registered(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses
	 );
CREATE TABLE WaitingList(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 position INT CHECK (position>0),
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses,
    UNIQUE (course,position)
	 );

--- Functions

CREATE OR REPLACE FUNCTION nextPos (CHAR(6)) RETURNS INT AS $$ DECLARE
	 position INT;
	 BEGIN
	 position := (SELECT COUNT(*) FROM WaitingList WHERE course = $1);
	 RETURN (position+1);
	 END $$ LANGUAGE plpgsql;


---- Views

------------------- view BasicInformation ----------------------------------
CREATE OR REPLACE VIEW BasicInformation AS
SELECT idnr, name, login, Students.program, branch FROM Students FULL OUTER JOIN StudentBranches ON idnr=student;
--SELECT* FROM BasicInformation;

------------------- view FinishedCourses ----------------------------------
CREATE OR REPLACE VIEW FinishedCourses AS
SELECT student, course, grade, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course;
--SELECT* FROM FinishedCourses;

------------------- view PassedCourses ----------------------------------
CREATE OR REPLACE VIEW PassedCourses AS
SELECT student, course, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course
WHERE grade != 'U';
--SELECT* FROM PassedCourses;

------------------- view Registrations ----------------------------------
CREATE OR REPLACE VIEW Registrations AS
SELECT student, course, 'registered' AS status FROM Registered
UNION ALL
SELECT student,course, 'waiting' AS status FROM WaitingList;
--SELECT* FROM Registrations;

------------------- view UnreadMandatory ----------------------------------
CREATE OR REPLACE VIEW UnreadMandatory AS
(SELECT idnr AS student, course  FROM BasicInformation RIGHT OUTER JOIN MandatoryProgram ON
MandatoryProgram.program = BasicInformation.program
UNION
SELECT idnr AS student, course  FROM BasicInformation RIGHT OUTER JOIN MandatoryBranch ON
MandatoryBranch.program = BasicInformation.program AND MandatoryBranch.branch = BasicInformation.branch)
EXCEPT
SELECT student, course FROM PassedCourses;
--SELECT* FROM UnreadMandatory;

------------------- view PathToGraduation ----------------------------------
CREATE OR REPLACE VIEW PathToGraduation AS
-- Total credits
WITH totalCredit AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(credits)), 0) AS totalCredits
  FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  GROUP BY BasicInformation.idnr
),

-- Mandatory courses left
mandatoryLefts AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(UnreadMandatory.course)), 0) AS mandatoryLeft
  FROM BasicInformation
  LEFT OUTER JOIN UnreadMandatory ON BasicInformation.idnr=UnreadMandatory.student
  GROUP BY BasicInformation.idnr
),

-- Math credits
studentMathCredit AS (
  SELECT DISTINCT  student, SUM(PassedCourses.credits) as mathCredit FROM PassedCourses
  LEFT OUTER JOIN Classified ON PassedCourses.course=Classified.course
  WHERE Classified.classification='math'
  GROUP BY student
), mathCredit AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(mathCredit)), 0) AS mathCredits FROM BasicInformation
  LEFT OUTER JOIN studentMathCredit ON BasicInformation.idnr=studentMathCredit.student
  GROUP BY BasicInformation.idnr
),

-- Research credits
studentResearchCredit AS (
  SELECT DISTINCT  student, SUM(PassedCourses.credits) as researchCredit FROM PassedCourses
  LEFT OUTER JOIN Classified ON PassedCourses.course=Classified.course
  WHERE Classified.classification='research'
  GROUP BY student
), researchCredit AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(researchCredit)), 0) AS researchCredits FROM BasicInformation
  LEFT OUTER JOIN studentResearchCredit ON BasicInformation.idnr=studentResearchCredit.student
  GROUP BY BasicInformation.idnr
),

-- Seminar courses
studentSeminarCredit AS (
  SELECT DISTINCT  student, COUNT(PassedCourses.course) AS seminarCredit FROM PassedCourses
  LEFT OUTER JOIN Classified ON PassedCourses.course=Classified.course
  WHERE Classified.classification='seminar'
  GROUP BY student
), seminarCours AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(seminarCredit)), 0) AS seminarCourses FROM BasicInformation
  LEFT OUTER JOIN studentSeminarCredit ON BasicInformation.idnr=studentSeminarCredit.student
  GROUP BY BasicInformation.idnr
),

-- Get recommended courses
studentRecommendedCourse AS (
  SELECT idnr AS student, SUM(PassedCourses.credits) AS recommendedCredit FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  WHERE PassedCourses.course IN (SELECT course FROM RecommendedBranch WHERE (RecommendedBranch.program=BasicInformation.program AND RecommendedBranch.branch=BasicInformation.branch))
  GROUP BY BasicInformation.idnr
), recommendedCourse AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(recommendedCredit)), 0) AS recommendedCourses FROM BasicInformation
  LEFT OUTER JOIN studentRecommendedCourse ON BasicInformation.idnr=studentRecommendedCourse.student
  GROUP BY BasicInformation.idnr
), qualified AS (
  SELECT idnr AS student, (mandatoryLeft=0 and recommendedCourses>=10 and mathCredits >=20 and researchCredits >=10 and seminarCourses >=1) AS qualified
  FROM BasicInformation
  LEFT OUTER JOIN mandatoryLefts ON BasicInformation.idnr=mandatoryLefts.student
  LEFT OUTER JOIN recommendedCourse ON BasicInformation.idnr=recommendedCourse.student
  LEFT OUTER JOIN mathCredit ON BasicInformation.idnr=mathCredit.student
  LEFT OUTER JOIN researchCredit ON BasicInformation.idnr=researchCredit.student
  LEFT OUTER JOIN seminarCours ON BasicInformation.idnr=seminarCours.student
)
SELECT* FROM totalCredit
NATURAL LEFT JOIN mandatoryLefts
NATURAL LEFT JOIN mathCredit
NATURAL FULL JOIN researchCredit
NATURAL FULL JOIN seminarCours
NATURAL LEFT JOIN qualified;
---CourseQueuePositions
CREATE OR REPLACE VIEW CourseQueuePositions AS
SELECT course, student, position AS place FROM WaitingList;

---- TRIGGERS

-------------------- VIEW : CourseQueuePositions --------------------------
CREATE OR REPLACE VIEW CourseQueuePositions AS
SELECT course, student, position AS place FROM WaitingList;


------------------- Functions and Triggers for Registrations --------------

---- First Trigger
CREATE OR REPLACE FUNCTION checkRegistrations() RETURNS TRIGGER AS $$
DECLARE
  studentIsRegistered BOOLEAN;
  courseIsAlreadyTaken BOOLEAN;
  studentIsInWaitingList BOOLEAN;
  courseCapacity INT;
  totalRegistered INT;
  totalprerequisites INT;
  preRequisitiesTaken INT;

BEGIN
  SELECT
    (EXISTS (SELECT* FROM Registrations
             WHERE student=NEW.student AND course=NEW.course)
    ) INTO studentIsRegistered;

  SELECT
    (EXISTS (SELECT* FROM PassedCourses
             WHERE student=NEW.student AND course=NEW.course)
    ) INTO courseIsAlreadyTaken;

  SELECT
      (EXISTS (SELECT* FROM WaitingList
               WHERE student=NEW.student AND course=NEW.course)
      ) INTO studentIsInWaitingList;

  courseCapacity := (SELECT COALESCE((capacity), -1) FROM LimitedCourses
            WHERE course=NEW.course);

  totalRegistered := (SELECT COUNT(*) FROM Registrations
            WHERE course=NEW.course AND status='registered');

  totalprerequisites := (SELECT COUNT(requisities) FROM PreRequisities
            WHERE course=NEW.course);

  preRequisitiesTaken := (SELECT COUNT(course) FROM (SELECT requisities AS course FROM PreRequisities
            WHERE course=NEW.course INTERSECT SELECT course FROM PassedCourses WHERE student=NEW.student) AS Taken);


  IF (studentIsRegistered OR courseIsAlreadyTaken) THEN
    RAISE EXCEPTION 'Registration failed!
    Alt1: The Student % may already be registered or passed the course.
    Alt2: She/He is may be on the waiting list for the course %.', NEW.student, NEW.course;
  END IF;
  IF (preRequisitiesTaken < totalprerequisites) THEN
    RAISE EXCEPTION 'The student %, missing prerequisites for %!', NEW.student, NEW.course;
  END IF;
  IF (totalRegistered>=courseCapacity) THEN
    --RAISE NOTICE 'The Course % is full for registration!
    --The student % is now on the waitinglist.' , NEW.course, NEW.student;
    INSERT INTO WaitingList VALUES (NEW.student, NEW.course, nextPos(NEW.course));
  ELSE
    INSERT INTO Registered VALUES (NEW.student, NEW.course);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--DROP TRIGGER IF EXISTS checkRegistered ON Registrations;

CREATE TRIGGER checkRegistered
  INSTEAD OF INSERT ON Registrations
  FOR EACH ROW
  EXECUTE FUNCTION checkRegistrations();

---- Second Trigger
CREATE OR REPLACE FUNCTION checkUnRegistrations() RETURNS TRIGGER AS $$
DECLARE
    studentPos INT;
    newStudent VARCHAR;
BEGIN
  studentPos:= (SELECT position FROM WaitingList
            WHERE course =OLD.course AND student= OLD.student);
  newStudent := (SELECT student FROM WaitingList
            WHERE course= OLD.course AND position=1);

   IF (OLD.status='waiting') THEN
        DELETE FROM WaitingList WHERE (student=OLD.student AND course=OLD.course);
        UPDATE WaitingList
        SET position = position-1
        WHERE (course = OLD.course) AND WaitingList.position>studentPos;
   ELSE
        DELETE FROM Registered WHERE (student= OLD.student AND course= OLD.course);
        IF(newStudent IS NOT NULL) THEN
            DELETE FROM WaitingList WHERE(newStudent= student AND course=OLD.course);
            INSERT INTO Registrations VALUES(newStudent,OLD.course);
            UPDATE WaitingList
            SET position = position-1
            WHERE (course = OLD.course AND studentPos>1) ;
        END IF;

   END IF;
   RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER checkUnregistered
    INSTEAD OF DELETE OR UPDATE ON Registrations
    FOR EACH ROW
    EXECUTE FUNCTION checkUnRegistrations();
