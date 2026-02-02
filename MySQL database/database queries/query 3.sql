-- list all the officers who cited a violation at every incident they attended
use traffic_violations;

-- create a view of all officers with entries in potential violation incedents that do not appear in cited violations
drop view if exists `Excluded_Officers`;
create view `Excluded_Officers` as
select PVI.`CitingOfficer`
from `Cited_Violations` CV
right outer join `Potential_Violation_Incidents` PVI
on CV.`ID` = PVI.`ID`
where CV.`ID` is null;

-- get the info of every officer whose personal number is not in Excludede_officers
select O.`PersonalNumber`, O.`FirstName`, O.`LastName`
from `Cited_Violations` CV
inner join `Potential_violation_Incidents` PVI
on CV.`ID` = PVI.`ID`
inner join `Officers` O
on PVI.`CitingOfficer` = O.`PersonalNumber`
where not exists (select 1 from `Excluded_Officers` where `Excluded_Officers`.`CitingOfficer` = O.`PersonalNumber`);

drop view if exists `Excluded_Officers`;