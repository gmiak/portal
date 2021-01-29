CREATE VIEW BasicInformation AS
SELECT idnr, name, login, program FROM Students -- hitta koppling mellan program och namn på branchen.
UNION
SELECT name FROM Branches; -- lägga till branches om student xxx existerar i StudentBranches annars skriv not yet.

SELECT* FROM BasicInformation;
