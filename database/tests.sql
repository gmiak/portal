---------------------------------------------
/**
-registered to an unlimited course;
-registered to a limited course;
waiting for a limited course;
unregistered from an unlimited course;
unregistered from a limited course without a waiting list;
unregistered from a limited course with a waiting list, when the student is registered;
unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
unregistered from an overfull course with a waiting list.
**/
-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
insert into Registrations values ('4444444444', 'CCC555');

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
insert into Registrations values ('1111111111', 'CCC111');

-- TEST #3: Unregister from an unlimited course.
-- EXPECTED OUTCOME: Pass
delete from Registrations where student = '1111111111' and course = 'CCC111';

-- TEST #4: waiting for a limited course.
-- EXPECTED OUTCOME: Pass
insert into Registrations values ('5555555555', 'CCC222');


-- TEST #5: unregistered from a limited course without a waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE  student='1111111111' AND course = 'CCC444';


-- TEST #6: unregistered from a limited course with a waiting list,
 --when the student is registered;
-- EXPECTED OUTCOME: Pass
delete from Registrations WHERE  student= '2222222222' AND course='CCC222';

-- TEST #7: unregistered from an overfull course with a waiting list.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('6666666666', 'CCC222');
delete from Registrations WHERE  student='2222222222' AND course= 'CCC222';

