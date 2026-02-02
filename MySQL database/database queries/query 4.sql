-- list all issued violations against people under a certain age
use traffic_violations;

-- define the age in which, citations issued to poeple this age or younger will be shown
set @AgeCutoff = 29;

-- create function to detetmine age from date of birth
drop function if exists AgeCalc;
create function AgeCalc (dob date)
	returns int deterministic
    return timestampdiff(year, dob, current_date());

select P.`ID`, P.`FirstName`, P.`LastName`, AgeCalc(P.`BirthDate`) as Age, 
	VO.`Vehicle`, CV.`ID`, CV.`Violation`, CV.`Action`
from `Cited_Violations` CV
inner join `Potential_Violation_Incidents` PVI
on CV.`ID` = PVI.`ID`
inner join `Vehicle_Ownership` VO
on PVI.`Vehicle` = VO.`Vehicle`
inner join `People` P
on VO.`RegisteredOwner` = P.`ID`
where AgeCalc(P.`BirthDate`) <= @AgeCutoff;