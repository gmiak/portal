CREATE VIEW BasicInformation AS
SELECT idnr, name, login, program FROM Students -- hitta koppling mellan program och namn på branchen.
UNION 
SELECT name FROM Branches
;


SELECT* FROM BasicInformation;