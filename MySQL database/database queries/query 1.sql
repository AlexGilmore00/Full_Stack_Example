-- create a new record for a correction notice
use traffic_violations;

-- set collation connection in accordance to db to ensure no errors occure when inserting values using variables
set collation_connection = 'utf8_unicode_ci';

-- set up variables for easy input into the system
set @OfficerNumber = 78445;
set @VehicleVIN = 'fbn48uifjeu49h7sf';
set @Violation = 'Speeding';
set @ViolationDateTime = '2025-4-17 23:33:56';
set @VAction = 'Warning';
set @District = '1st';
set @Location = '2 mile NE of place11 on road11';

--  insert tha values inot the relevant tables
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = @VehicleVIN),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = @OfficerNumber));
        
insert into `Cited_Violations`
values ((select max(`ID`) from `Potential_Violation_incidents`),
		@Violation, @ViolationDateTime,
        (select `Action` from `Actions` where `Action` = @VAction),
        @District, @Location);