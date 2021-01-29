-- OBS: Deletes everything!
\c portal
\set QUIT true
SET client_min_messages TO WARNING;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false

-- Tables
CREATE TABLE Students (
	idnr VARCHAR(10) check (length(idnr) = 10), -- check NUMBERS
	name TEXT NOT NULL,
	login TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY (idnr)
);
CREATE TABLE Branches (
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY(name, program)

);


CREATE TABLE Courses(
	code VARCHAR(6) check (length(code) = 6),
	name TEXT NOT NULL,
	credits FLOAT NOT NULL,
	department	TEXT NOT NULL,
	PRIMARY KEY (code)

);

CREATE TABLE LimitedCourses(
	 code VARCHAR(6) PRIMARY KEY,
	 capacity INT NOT NULL,
	 FOREIGN KEY (code) REFERENCES Courses
	 );

CREATE TABLE StudentBranches(
	 student VARCHAR(10) PRIMARY KEY,
	 branch TEXT NOT NULL,
	 program TEXT NOT NULL,
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (branch,program) REFERENCES Branches
	 );

CREATE TABLE Classifications(
	 name TEXT PRIMARY KEY

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
	 program TEXT,
	 PRIMARY KEY (course,program),
	 FOREIGN KEY (course) REFERENCES Courses
	 );


CREATE TABLE MandatoryBranch(
	 course VARCHAR(6),
	 branch TEXT NOT NULL,
	 program TEXT NOT NULL,
	 PRIMARY KEY (course,branch,program),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (branch,program) REFERENCES Branches
	 );

CREATE TABLE RecommendedBranch(
	 course VARCHAR(6),
	 branch TEXT NOT NULL,
	 program TEXT NOT NULL,
	 PRIMARY KEY (course,branch,program),
	 FOREIGN KEY (course) REFERENCES Courses,
	 FOREIGN KEY (branch,program) REFERENCES Branches
	 );


CREATE TABLE Registered(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses
	 );


CREATE TABLE Taken(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 grade CHAR(1)	NOT NULL, 				-- kolla om den
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses
	 );

CREATE TABLE WaitingList(
	 student VARCHAR(10),
	 course VARCHAR(6),
	 position SERIAL NOT NULL, 				-- kolla om den
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES LimitedCourses
	 );
