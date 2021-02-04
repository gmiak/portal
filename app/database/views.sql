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


CREATE OR REPLACE VIEW PathToGraduation AS
WITH totalCredit AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(credits)), 0) AS totalCredits
  FROM BasicInformation
  LEFT OUTER JOIN FinishedCourses ON BasicInformation.idnr=FinishedCourses.student
  GROUP BY BasicInformation.idnr
), totalCreditPassed AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(credits)), 0) AS totalCreditPass
  FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  GROUP BY BasicInformation.idnr
), mandatoryLefts AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(UnreadMandatory.course)), 0) AS mandatoryLeft
  FROM BasicInformation
  LEFT OUTER JOIN UnreadMandatory ON BasicInformation.idnr=UnreadMandatory.student
  GROUP BY BasicInformation.idnr
), mathCredit AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(FinishedCourses.course)), 0) AS mathCredits FROM BasicInformation
  LEFT OUTER JOIN FinishedCourses ON BasicInformation.idnr=FinishedCourses.student
  WHERE FinishedCourses.course IN (SELECT course FROM Classified WHERE classification='math')
  GROUP BY BasicInformation.idnr
), mathCreditPassed AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(PassedCourses.credits)), 0) AS mathPassed FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  WHERE PassedCourses.course IN (SELECT course FROM Classified WHERE classification='math')
  GROUP BY BasicInformation.idnr
), researchCredit AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(FinishedCourses.course)), 0) AS researchCredits FROM BasicInformation
  LEFT OUTER JOIN FinishedCourses ON BasicInformation.idnr=FinishedCourses.student
  WHERE FinishedCourses.course IN (SELECT course FROM Classified WHERE classification='research')
  GROUP BY BasicInformation.idnr
), researchCreditPassed AS (
  SELECT idnr AS student, COALESCE(SUM(DISTINCT(PassedCourses.credits)), 0) AS researchCreditPass FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  WHERE PassedCourses.course IN (SELECT course FROM Classified WHERE classification='research')
  GROUP BY BasicInformation.idnr
), seminarCours AS (
  SELECT idnr AS student, COALESCE(COUNT(DISTINCT(PassedCourses.course)), 0) AS seminarCourses FROM BasicInformation
  LEFT OUTER JOIN PassedCourses ON BasicInformation.idnr=PassedCourses.student
  WHERE PassedCourses.course IN (SELECT course FROM Classified WHERE classification='seminar')
  GROUP BY BasicInformation.idnr
), qualified AS (
  SELECT idnr AS student, (mandatoryLeft=0 and totalCreditPass>=10 and mathPassed >=20 and researchCreditPass >=10 and seminarCourses >=1) AS qualified
  FROM BasicInformation
  LEFT OUTER JOIN mandatoryLefts ON BasicInformation.idnr=mandatoryLefts.student
  LEFT OUTER JOIN totalCreditPassed ON BasicInformation.idnr=totalCreditPassed.student
  LEFT OUTER JOIN mathCreditPassed ON BasicInformation.idnr=mathCreditPassed.student
  LEFT OUTER JOIN researchCreditPassed ON BasicInformation.idnr=researchCreditPassed.student
  LEFT OUTER JOIN seminarCours ON BasicInformation.idnr=seminarCours.student
)
SELECT* FROM totalCredit
JOIN mandatoryLefts USING (student)
NATURAL FULL JOIN mathCredit
NATURAL FULL JOIN researchCredit
NATURAL FULL JOIN seminarCours
NATURAL LEFT JOIN qualified;

SELECT DISTINCT* FROM PathToGraduation;
DROP VIEW PathToGraduation;
