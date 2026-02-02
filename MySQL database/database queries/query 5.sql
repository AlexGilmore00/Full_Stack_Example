-- show the number of violations comitted against people with new york drivers licenses
-- vs thos agains people with licenses from elsewhere
use traffic_violations;

(select P.`DL_StateIssued` as StateLicense, CV.`Action` as PenaltySeverity, count(CV.`ID`) as `Count`
from `Cited_Violations` CV
inner join `Potential_Violation_Incidents` PVI
on CV.`ID` = PVI.`ID`
inner join `Vehicle_Ownership` VO
on PVI.`Vehicle` = VO.`Vehicle`
inner join `People` P
on VO.`RegisteredOwner` = P.`ID`
where P.`DL_StateIssued` = 'New York'
group by PenaltySeverity, StateLicense
order by PenaltySeverity)
union
(select group_concat(distinct P.`DL_StateIssued` order by P.`DL_StateIssued` asc) as StateLicense, 
	CV.`Action` as PenaltySeverity, count(CV.`ID`) as `Count`
from `Cited_Violations` CV
inner join `Potential_Violation_Incidents` PVI
on CV.`ID` = PVI.`ID`
inner join `Vehicle_Ownership` VO
on PVI.`Vehicle` = VO.`Vehicle`
inner join `People` P
on VO.`RegisteredOwner` = P.`ID`
where P.`DL_StateIssued` != 'New York'
group by PenaltySeverity
order by PenaltySeverity)