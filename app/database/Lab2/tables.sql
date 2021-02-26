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
	login TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY (idnr),
	FOREIGN KEY (program) REFERENCES Programs
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
	 PRIMARY KEY (student, branch),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (branch, program) REFERENCES Branches
	 );
CREATE TABLE LimitedCourses(
	 course VARCHAR(6) PRIMARY KEY,
	 capacity INT NOT NULL check(capacity>=0),
	 FOREIGN KEY (course) REFERENCES Courses
	 );
CREATE TABLE PreRequisities(
	 course VARCHAR(6),
	 requisities VARCHAR(6),
	 PRIMARY KEY(course),
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
	 position SERIAL UNIQUE,
	 PRIMARY KEY (student,course),
	 FOREIGN KEY (student) REFERENCES Students,
	 FOREIGN KEY (course) REFERENCES Courses
	 );
