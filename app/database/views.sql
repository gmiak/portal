CREATE OR REPLACE VIEW BasicInformation AS
SELECT idnr, name, login, Students.program, COALESCE(branch,'No yet') AS branch FROM Students FULL OUTER JOIN StudentBranches ON idnr=student;
SELECT* FROM BasicInformation;


CREATE OR REPLACE VIEW FinishedCourses AS
SELECT student, course, grade, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course;
SELECT* FROM FinishedCourses;

/*CREATE VIEW StudentCourses AS
SELECT idnr AS student, COALESCE(course,'No course') AS course , COALESCE(grade,'No grade') AS grade ,  COALESCE(credits,0) AS
credits  FROM Students LEFT OUTER JOIN Taken ON idnr= student LEFT OUTER JOIN Courses ON course =code;
SELECT* FROM StudentCourses;
DROP VIEW StudentCourses;*/


CREATE OR REPLACE VIEW PassedCourses AS
SELECT student, course, Courses.credits FROM Taken LEFT OUTER JOIN Courses ON code= course
WHERE grade != 'U';
SELECT* FROM PassedCourses;


CREATE OR REPLACE VIEW Registrations AS
SELECT student, course, 'registered' AS status FROM Registered
UNION ALL
SELECT student,course, 'Waiting' AS status FROM WaitingList;
SELECT* FROM Registrations;

/*CREATE VIEW UnreadMandatory AS
SELECT student, Taken.course FROM Taken FULL OUTER JOIN MandatoryProgram ON Taken.course= MandatoryProgram.course
WHERE grade = 'U'
UNION
SELECT student, Taken.course FROM Taken FULL OUTER JOIN MandatoryBranch ON Taken.course= MandatoryBranch.course
WHERE grade = 'U';
SELECT* FROM UnreadMandatory;
DROP VIEW UnreadMandatory;*/

/*CREATE VIEW UnreadMandatory AS
SELECT idnr AS student, BasicInformation.program, BasicInformation.branch, course AS mandatoryCourse FROM BasicInformation FULL OUTER JOIN MandatoryProgram ON
MandatoryProgram.program= BasicInformation.program
UNION
SELECT idnr AS student, BasicInformation.program, BasicInformation.branch, course AS mandatoryCourse FROM BasicInformation FULL OUTER JOIN MandatoryBranch ON
MandatoryBranch.branch= BasicInformation.branch;
SELECT* FROM UnreadMandatory;
DROP VIEW UnreadMandatory;*/


CREATE OR REPLACE VIEW UnreadMandatory AS
(SELECT idnr AS student, course  FROM BasicInformation RIGHT OUTER JOIN MandatoryProgram ON
MandatoryProgram.program = BasicInformation.program
UNION
SELECT idnr AS student, course  FROM BasicInformation RIGHT OUTER JOIN MandatoryBranch ON
MandatoryBranch.branch = BasicInformation.branch)
EXCEPT
SELECT student, course FROM PassedCourses;
SELECT* FROM UnreadMandatory;
SELECT student, COUNT(course) FROM UnreadMandatory GROUP BY student;


CREATE VIEW PathToGraduation AS
SELECT idnr AS student, COALESCE(SUM(credits), 0) AS totalCredits, COALESCE(COUNT(DISTINCT(UnreadMandatory.course)), 0) AS mandatoryLeft
FROM BasicInformation
LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
LEFT OUTER JOIN UnreadMandatory ON BasicInformation.idnr=UnreadMandatory.student
GROUP BY BasicInformation.idnr;

SELECT* FROM PathToGraduation;
DROP VIEW PathToGraduation;
