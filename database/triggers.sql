---CourseQueuePositions
CREATE OR REPLACE VIEW CourseQueuePositions AS
SELECT course, student, position AS place FROM WaitingList;
--- Functions and Triggers for Registrations
CREATE OR REPLACE FUNCTION checkRegistrations() RETURNS TRIGGER AS $$

BEGIN

  IF EXISTS (SELECT 1 FROM Registrations WHERE student=NEW.student AND course=NEW.course) THEN
    RAISE EXCEPTION 'The student %, is already  registered in %', NEW.student, NEW.course;

  END IF;
 -- IF NEW.student= (SELECT student FROM WaitingList ) THEN
  --RAISE EXCEPTION 'The student %, is in both %', NEW.student, NEW.course;
  --END IF ;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkRegistered ON Registered;

CREATE TRIGGER checkRegistered
  BEFORE UPDATE OR INSERT ON Registered
  FOR EACH STATEMENT
  EXECUTE FUNCTION checkRegistrations();
