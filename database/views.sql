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

