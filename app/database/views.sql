CREATE VIEW BasicInformation AS
SELECT idnr, name, login, Students.program,branch FROM Students FULL OUTER JOIN StudentBranches ON idnr=student;
 -- hitta koppling mellan program och namn på branchen.
SELECT* FROM BasicInformation;
DROP VIEW BasicInformation;

CREATE VIEW FinishedCourses AS
SELECT student, course, grade, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course;
SELECT* FROM FinishedCourses;
DROP VIEW FinishedCourses;

CREATE VIEW StudentCourses AS

SELECT idnr AS student, COALESCE(course,'No course') AS course , COALESCE(grade,'No grade') AS grade ,  COALESCE(credits,0) AS credits  FROM Students LEFT OUTER JOIN Taken ON idnr= student LEFT OUTER JOIN Courses ON course =code;


SELECT* FROM StudentCourses;
--DROP VIEW StudentCourses;

CREATE VIEW PassedCourses AS
SELECT student, course, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course
WHERE grade != 'U';
SELECT* FROM PassedCourses;
DROP VIEW PassedCourses;

CREATE VIEW Registrations AS
SELECT student, course, 'registered' AS status FROM Registered
UNION ALL
SELECT student,course, 'Waiting' AS status FROM WaitingList;

SELECT* FROM Registrations;
DROP VIEW Registrations;

CREATE VIEW UnreadMandatory AS
SELECT student, Taken.course FROM Taken RIGHT OUTER JOIN MandatoryProgram ON Taken.course= MandatoryProgram.course
WHERE grade = 'U'
UNION
SELECT student, Taken.course FROM Taken RIGHT OUTER JOIN MandatoryBranch ON Taken.course= MandatoryBranch.course
WHERE grade = 'U';
SELECT* FROM UnreadMandatory;
DROP VIEW UnreadMandatory;
