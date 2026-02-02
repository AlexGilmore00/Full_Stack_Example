-- list of all people with notices that need immediate correction
use traffic_violations;

select P.`ID`, P.`FirstName`, P.`LastName`,
	group_concat(VO.`Vehicle` order by VO.`Vehicle` asc) as `Vehicles that got citation`,
    count(CV.`ID`) as `Number of serious violations`
from `People` P
inner join `Vehicle_Ownership` VO
on P.`ID` = VO.`RegisteredOwner`
inner join `Potential_Violation_Incidents` PVI
on VO.`Vehicle` = PVI.`Vehicle`
inner join `Cited_Violations` CV
on PVI.`ID` = CV.`ID`
where CV.`Action` = 'Immediate Correction Needed'
group by P.`ID`
order by P.`ID` asc;
