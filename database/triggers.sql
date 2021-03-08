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
