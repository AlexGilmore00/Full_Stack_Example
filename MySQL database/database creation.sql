-- create db
create database if not exists traffic_violations;
use traffic_violations;

-- ensure correct character set is used to allow for unobstructed use of variables when querying
alter database traffic_violations character set  utf8 collate utf8_unicode_ci;

-- MAKE TABLES --
-- person table
create table if not exists `People` (
	`ID` integer not null,
    `FirstName` varchar(32) not null,
    `LastName` varchar(32) not null,
	`Zipcode` integer not null,
    `State` varchar(32),
    `city` varchar(32),
    `DL_StateIssued` varchar(32) not null,  -- state in which their drivers lisence was issued
    `BirthDate` date not null,
    `Weight_KG` float,
    `Height_cm` float,
    `EyeColour` varchar(5),
    
    CONSTRAINT `PEOPLE_PK` 			primary key (`ID`),
    CONSTRAINT `VALID_ID` 			check (`ID` > 0),
    CONSTRAINT `VALID_WEIGHT` 		check (`Weight_KG` > 0),
    CONSTRAINT `VALID_HEIGHT`		check (`Height_cm` > 0),
    CONSTRAINT `VALID_EYECOLOUR`	check (`EyeColour` = 'Blue' or  `EyeColour` = 'Brown' or
										   `EyeColour` = 'Green' or `EyeColour` = 'Hazel' or
                                           `EyeColour` = 'Gray')
	);

-- create triggers to ensure any new or updated BirthDates added to People table is not in the future
drop trigger if exists `People_BirthDate_Validation_Insert`;
drop trigger if exists `People_BirthDate_Validation_Update`;

delimiter //

create trigger `People_BirthDate_Validation_Insert`
	before insert on `People`
	for each row
begin
	if(new.`BirthDate` > current_date())
    then
		signal sqlstate '45000' set message_text = 'date cannot be in the future';
	end if;
end; //

create trigger `People_BirthDate_Validation_Update`
	before update on `People`
	for each row
begin
	if(new.`BirthDate` > current_date())
    then
		signal sqlstate '45000' set message_text = 'date cannot be in the future';
	end if;
end; //

delimiter ;


-- vehicle table
create table if not exists `Vehicles` (
	`VIN` varchar(17) not null,
    `VL_StateIssued` varchar(32) not null, -- state in which the vehicle license was issued
    `Year` integer not null,
    `Make` varchar(32) not null,
    `Type` varchar(32) not null,
    `Colour` varchar(32) not null,
    `Zipcode` integer not null,
    `State` varchar(32),
    `city` varchar(32),
    
    CONSTRAINT `VEHICLES_PK`	primary key (`VIN`),
	CONSTRAINT `VALID_VIN`		check (length(`VIN`) = 17)
);


-- vehicle ownership table
create table if not exists `Vehicle_Ownership` (
	`Vehicle` varchar(17) not null,
	`RegisteredOwner` integer not null,
    
    CONSTRAINT `VEHICLE_OWNERSHIP_PK`	primary key (`Vehicle`, `RegisteredOwner`),
	CONSTRAINT `VEHIVLE_OWNERSHIP_FK0` 	foreign key (`Vehicle`) references `Vehicles`(`VIN`)
											on update cascade
                                            on delete cascade,
	CONSTRAINT `VEHIVLE_OWNERSHIP_FK1` 	foreign key (`RegisteredOwner`) references `People`(`ID`)
											on update cascade
                                            on delete cascade
);


-- officer table
create table if not exists `Officers` (
	`PersonalNumber` integer not null,
    `FirstName` varchar(32) not null,
    `LastName` varchar(32) not null,
    `Detatchment` varchar(32) not null,
    
    CONSTRAINT `OFFICERS_PK` 			primary key (`PersonalNumber`),
    CONSTRAINT `VALID_PERSONALNUMBER`	check (`PersonalNumber` > 0)
);


-- potential voilation incidents table. holds a record of all incidents where a correction notice could have
-- possibly been handed out, regardless of whether it was actually issued or not
create table if not exists `Potential_Violation_Incidents` (
	`ID` integer not null auto_increment,
    `Vehicle` varchar(17) not null,
    `CitingOfficer` integer not null,

	CONSTRAINT `POTENTIAL_VIOLATION_INCIDENTS_PK` 	primary key (`ID`),
	CONSTRAINT `POTENTIAL_VIOLATION_INCIDENTS_FK0`	foreign key (`Vehicle`) references `Vehicles`(`VIN`)
														on update no action
														on delete no action,
    CONSTRAINT `POTENTIAL_VIOLATION_INCIDENTS_FK1`	foreign key (`CitingOfficer`) references `Officers`(`PersonalNumber`)
														on update no action
														on delete no action
);


-- actions table. links the set of possible actions in a cited violation to the description of that action
create table if not exists `Actions` (
	`Action` varchar(27) not null,
    `ActionDescription` varchar(512) not null,
    
    CONSTRAINT `ACTIONS_PK`		primary key (`Action`),
    CONSTRAINT `VALID_ACTION`	check (`Action` = binary 'Warning' or
						                       `Action` = binary 'Repair Release' or
                                               `Action` = binary 'Immediate Correction Needed')
);


-- cited violations table. holds a record of all correction notices that have been issued
create table if not exists `Cited_Violations` (
	`ID` integer not null,
    `Violation` varchar(256) not null,
    `ViolationDateTime` DateTime not null,
    `Action` varchar(27) not null,
    `District` varchar(32) not null,
    `location` varchar(256) not null,
    
	CONSTRAINT `CITED_VIOLATIONS_PK`	primary key (`ID`),
    CONSTRAINT `CITED_VIOLATIONS_FK0` 	foreign key (`ID`) references `Potential_Violation_Incidents`(`ID`)
											on update cascade
                                            on delete cascade,
	CONSTRAINT `CITED_VIOLATIONS_FK1` 	foreign key (`Action`) references `Actions`(`Action`)
											on update cascade
                                            on delete cascade
);

-- create triggers to ensure any new or updated ViolationDateTimes added to Cited_Violations table is not in the future
drop trigger if exists `Cited_Violationd_ViolationDateTime_Validation_Insert`;
drop trigger if exists `Cited_Violationd_ViolationDateTime_Validation_Update`;

delimiter //

create trigger `Cited_Violationd_ViolationDateTime_Validation_Insert`
	before insert on `Cited_Violations`
	for each row
begin
	if(new.`ViolationDateTime` > now())
    then
		signal sqlstate '45000' set message_text = 'date cannot be in the future';
	end if;
end; //

create trigger `Cited_Violationd_ViolationDateTime_Validation_Update`
	before update on `Cited_Violations`
	for each row
begin
	if(new.`ViolationDateTime` > now())
    then
		signal sqlstate '45000' set message_text = 'date cannot be in the future';
	end if;
end; //

delimiter ;
    

-- SET UP USERS AND ROLES --
-- create and define roles
create role if not exists `Citizen`, `Officer`;

-- citizen permisions
grant select on `traffic_violations`.`Vehicles` to `Citizen`;
grant select on `traffic_violations`.`People` to `Citizen`;
grant select on `traffic_violations`.`Cited_Violations` to `Citizen`;

-- officer permissions
grant all on `traffic_violations`.* to `Officer`;

-- create citizen users
create user if not exists '475920437' identified by 'pass1' default role `Citizen`;
create user if not exists '673895473' identified by 'pass2' default role `Citizen`;
create user if not exists '674820456' identified by 'pass3' default role `Citizen`;
create user if not exists '476858485' identified by 'pass4' default role `Citizen`;
create user if not exists '143677456' identified by 'pass5' default role `Citizen`;
create user if not exists '868306838' identified by 'pass6' default role `Citizen`;
create user if not exists '033576833' identified by 'pass7' default role `Citizen`;
create user if not exists '586940409' identified by 'pass8' default role `Citizen`;
create user if not exists '548698349' identified by 'pass9' default role `Citizen`;
create user if not exists '965475674' identified by 'pass10' default role `Citizen`;

-- create officer users
create user if not exists '78445' identified by 'pass11' default role `Officer`;
create user if not exists '89663' identified by 'pass12' default role `Officer`;
create user if not exists '20945' identified by 'pass13' default role `Officer`;
create user if not exists '30573' identified by 'pass14' default role `Officer`;
create user if not exists '79463' identified by 'pass15' default role `Officer`;
create user if not exists '50923' identified by 'pass16' default role `Officer`;
create user if not exists '05083' identified by 'pass17' default role `Officer`;
create user if not exists '20467' identified by 'pass18' default role `Officer`;
create user if not exists '49456' identified by 'pass19' default role `Officer`;
create user if not exists '20465' identified by 'pass20' default role `Officer`;


-- INSERT VALUES INTO TABLES --
-- people
insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (475920437, 'Karl', 'Cameron', 13649, 'New York', 'New York', '1986-3-21', 85, 176, 'Green');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (673895473, 'Osian', 'Christian', 11654, 'New York', 'California', '2002-6-1', 68, 160, 'Brown');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (674820456, 'Leena', 'Tores', 12877, 'New York', 'Texas', '2000-10-30', 79, 165, 'Blue');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (476858485, 'Alessia', 'Valentine', 10975, 'New York', 'New York', '1996-3-12', 63, 157, 'Brown');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (143677456, 'Willard', 'Benton', 14905, 'New York', 'Florida', '1956-12-31', 75, 175, 'Blue');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (868306838, 'Imogen', 'Saunders', 11056, 'New York', 'New York', '2005-12-25', 79, 161, 'Hazel');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (033576833, 'Sofia', 'Walter', 10564, 'New York', 'New York', '1999-5-17', 71, 163, 'Green');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (586940409, 'Russel', 'Cartney', 14779, 'New York', 'Virginia', '1967-8-28', 90, 174, 'Gray');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (548698349, 'Colby', 'Evans', 13859, 'New York', 'Massachusetts', '1989-11-9', 89, 183, 'Brown');

insert into `People` (`ID`, `FirstName`, `LastName`, `Zipcode`, `State`, `DL_StateIssued`,
					  `BirthDate`, `Weight_KG`, `Height_cm`, `EyeColour`)
values (965475674, 'Alfie', 'Shaffer', 11446, 'New York', 'New York', '2001-2-26', 96, 170, 'Blue');


-- vehicles
insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('fbn48uifjeu49h7sf', 'New York', 2016, 'Hyundai', 'Ionic 6', 'Gray', 13649, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('fjeo949tjwifgngo9', 'New York', 2013, 'GMC', 'Hummer', 'Silver', 13649, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('85ugng9e4therdlee', 'California', 2003, 'Mini', 'Hardtop', 'Yellow', 11654, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('oihjerogneroiruer', 'Texas', 2001, 'Seat', 'Ibiza', 'Blue', 12877, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('ioiwjetoindolienr', 'New York', 1996, 'Nissan', 'Maxima', 'White', 10975, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('ro834htoirdngorn3', 'New York', 2012, 'Pergeot', '208', 'Yellow', 11056, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('598ge5o0943heroie', 'New York', 2017, 'Audi', 'A5', 'red', 10564, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('segoie4o8igebgodg', 'Massachusetts', 2006, 'Nissan', 'Frontier', 'White', 13859, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('dvoiweoerbgoi4erg', 'New York', 2006, 'Mitsubishi', 'Mirage G4', 'Gray', 11446, 'New York');

insert into `Vehicles` (`VIN`, `VL_StateIssued`, `Year`, `Make`, `Type`, `Colour`, `Zipcode`, `State`)
values ('w4984hgweroproigp', 'New York', 2012, 'Mercedes Benz', 'GLB SUV', 'Black', 11446, 'New York');


-- vehicle ownership
insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'fbn48uifjeu49h7sf'),
		(select `ID` from `People` where `ID` = 475920437));
        
insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'fjeo949tjwifgngo9'),
		(select `ID` from `People` where `ID` = 475920437));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = '85ugng9e4therdlee'),
		(select `ID` from `People` where `ID` = 673895473));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'oihjerogneroiruer'),
		(select `ID` from `People` where `ID` = 674820456));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'ioiwjetoindolienr'),
		(select `ID` from `People` where `ID` = 476858485));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'ro834htoirdngorn3'),
		(select `ID` from `People` where `ID` = 868306838));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = '598ge5o0943heroie'),
		(select `ID` from `People` where `ID` = 033576833));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'segoie4o8igebgodg'),
		(select `ID` from `People` where `ID` = 548698349));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'dvoiweoerbgoi4erg'),
		(select `ID` from `People` where `ID` = 965475674));
        
        insert into `Vehicle_Ownership`
values ((select `VIN` from `Vehicles` where `VIN` = 'w4984hgweroproigp'),
		(select `ID` from `People` where `ID` = 965475674));
        

-- officers
insert into `Officers` values (78445, 'Livia', 'Franco', 'NYPD');

insert into `Officers` values (89663, 'Sebastion', 'O-Doherty', 'NYPD');

insert into `Officers` values (20945, 'Ada', 'Tate', 'NYPD');

insert into `Officers` values (30573, 'Anthony', 'Casey', 'NYPD');

insert into `Officers` values (79463, 'Aiza', 'Douglas', 'NYPD');

insert into `Officers` values (50923, 'Gina', 'Dyer', 'NYPD');

insert into `Officers` values (05083, 'Kira', 'Warner', 'NYPD');

insert into `Officers` values (20467, 'Amber', 'Page', 'NYPD');

insert into `Officers` values (49456, 'Maja', 'Baxter', 'NYPD');

insert into `Officers` values (20465, 'Danyal', 'Gilbert', 'NYPD');


-- potential violation incidents
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'fbn48uifjeu49h7sf'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 78445));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'fbn48uifjeu49h7sf'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 20945));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'fjeo949tjwifgngo9'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 89663));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'oihjerogneroiruer'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 30573));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'ioiwjetoindolienr'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 30573));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'ro834htoirdngorn3'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 79463));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'ro834htoirdngorn3'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 50923));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = '598ge5o0943heroie'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 05083));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = '598ge5o0943heroie'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 05083));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'segoie4o8igebgodg'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 20467));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'dvoiweoerbgoi4erg'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 49456));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'w4984hgweroproigp'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 78445));
        
insert into `Potential_Violation_Incidents` (`Vehicle`, `CitingOfficer`)
values ((select `VIN` from `Vehicles` where `VIN` = 'w4984hgweroproigp'),
		(select `PersonalNumber` from `Officers` where `PersonalNumber` = 30573));


-- actions
insert into `Actions` (`Action`, `ActionDescription`)
values ('Warning', 'This is a warning, no further action required');

insert into `Actions` (`Action`, `ActionDescription`)
values ('Repair Release', 'You are released to take this vehicle to a place of repair. '
		'continued operation on the roadway is not authorised');

insert into `Actions` (`Action`, `ActionDescription`)
values ('Immediate Correction Needed', 'CORRETT VIOLATIONS IMMEDIATELY. return this signed '
		'card for proof of comppliance within 15/30 days');
        

-- cited violations
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 1),
		'speeding', '2015-6-12 18:54:24',
        (select `Action` from `Actions` where `Action` = 'Immediate Correction Needed'),
        '3rd', '17 miles E of place1 on road1');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 2),
		'speeding', '2016-12-13 13:34:35',
        (select `Action` from `Actions` where `Action` = 'Immediate Correction Needed'),
        '3rd', '14 miles N of place2 on road2');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 3),
		'broken headlight', '2018-4-21 07:23:38',
        (select `Action` from `Actions` where `Action` = 'Repair Release'),
        '2nd', '2 miles NE of place3 on road3');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 5),
		'on phone', '2018-6-30 11:17:37',
        (select `Action` from `Actions` where `Action` = 'Warning'),
        '5th', '13 miles S of place4 on road4');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 6),
		'speeding', '2019-1-31 02:54:22',
        (select `Action` from `Actions` where `Action` = 'Warning'),
        '7th', '4 miles SW of place5 on road5');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 7),
		'broken breaklights', '2020-11-18 20:24:57',
        (select `Action` from `Actions` where `Action` = 'Repair Release'),
        '1st', '7 miles W of place6 on road6');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 10),
		'on phone', '2020-12-25 16:37:53',
        (select `Action` from `Actions` where `Action` = 'Immediate Correction Needed'),
        '7th', '19 miles SE of place7 on road7');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 11),
		'running red light', '2023-6-12 09:35:27',
        (select `Action` from `Actions` where `Action` = 'Immediate Correction Needed'),
        '1st', '2 miles NW of place8 on road8');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 12),
		'speeding', '2024-8-19 21:51:29',
        (select `Action` from `Actions` where `Action` = 'Warning'),
        '1st', '4 miles E of place9 on road9');
        
insert into `Cited_Violations`
values ((select `ID` from `Potential_Violation_incidents` where `ID` = 13),
		'broken window', '2024-11-30 10:13:52',
        (select `Action` from `Actions` where `Action` = 'Repair Release'),
        '8th', '17 miles E of place1 on road1');