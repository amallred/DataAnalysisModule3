# [SQL Murder Mystery](https://mystery.knightlab.com/)

## Exploring the Database Structure

``` sql

-- code provided to explore available tables in SQLite database
SELECT name 
  FROM sqlite_master
 where type = 'table'
 
-- code provided to find structure of crime_scene_report table in SQLite
SELECT sql 
  FROM sqlite_master
 where name = 'crime_scene_report'
-- OUTPUT: CREATE TABLE crime_scene_report ( date integer, type text, description text, city text )

```

## Find murder information
Date: January 15, 2018
City: SQL City

```sql

-- View entire crime scene report table
select * from crime_scene_report;

-- Isolate rows where date and city match the crime
select * from crime_scene_report
	where date = 20180115
		and city = 'SQL City';

    -- Could also refine to include type = 'murder' but I can see that clearly

-- OUTPUT: description: Security footage shows that there were 2 witnesses. The first witness lives at the last house on "Northwestern Dr". The second witness, named Annabel, lives somewhere on "Franklin Ave".

```

## Investigate witnesses
Name ___, Address ___ Northwestern Dr
Name Annabel, Address ___ Franklin Ave.
```sql

-- View person table
select * from person;

-- Filter by northwestern dr; figure out what 'last house' is
select * from person
where address_street_name = 'Northwestern Dr'
order by address_number desc;
    -- OUTPUT: This witness is either Kinsey Erickson at 309 or Morty Schapiro at 4919. Likely Morty based on a general understanding of addresses.

-- Filter Annabel
select * from person
where address_street_name = 'Franklin Ave'
and name like '%Annabel%';
    -- OUTPUT: name: Annabel Miller, license_id 490173, 

```
|id     | name            | license_id | address_number | address_street_name    | ssn       |
| ---   | ---             | ---        | ---            | ---                    | ---       |
| 14887 | Morty Schapiro  | 118009     |  4919          | Northwestern Dr        | 111564949 |
| 16371 | Annabel Miller  | 490173     | 103            | Franklin Ave           | 318771143 |
| 89906 | Kinsey Erickson | 510019     | 309            | Northwestern Dr        | 635287661 |

## Review interview information

```sql

-- Morty's interview
select * from interview
where person_id = 14887;
    --- OUTPUT: I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. The membership number on the bag started with "48Z". Only gold members have those bags. The man got into a car with a plate that included "H42W".

-- Annabel's interview
select * from interview
where person_id = 16371;
    -- OUTPUT: I saw the murder happen, and I recognized the killer from my gym when I was working out last week on January the 9th.

-- Kinsey's interview
select * from interview
where person_id = 89906;
    -- OUTPUT: Nothing

```
### Key interview takeaways:
- [x] 'Get Fit Now Gym' mem number started with 48Z (gold member status)
  - [x]  gold member
- [x] Car plate included H42W
- [x] Annabel at gym on Jan 9 

## Check Gym member list

```sql

-- search members that match the bag number and mem status
select * from get_fit_now_member
where id like '48Z%'
and membership_status = 'gold';

```
OUTPUT:
|id     | person_id | name            | membership_start_date | membership_status | 
| ---   | ---       | ---             | ---                   | ---               |
| 48Z7A |  28819    | Joe Germuska    |  20160305             | gold              |
| 48Z55 |  67318    | Jeremy Bowers   |  20160101             | gold              |

## Investigate Annabel's 1/9 gym visit
- [x] Confirm she checked in
- [x] Compare other check ins with above names

```sql

-- See who checked in on Jan 9, 2018
select * from get_fit_now_check_in
where check_in_date = 20180109;

-- find Annabel's membership_id
select * from get_fit_now_member
where name like '%Annabel%';
    --OUTPUT: id: 90081, person_id: 16371

-- confirm Annabel was there on Jan 9
select * from get_fit_now_check_in
where membership_id = 90081;
    -- OUTPUT: confirmed check in from 1600-1700 on Jan 9

-- look up suspects' check ins for that date

    -- Joe Germuska id 48Z7A
select * from get_fit_now_check_in
where membership_id = '48Z7A';
    -- OUTPUT: confirmed check in 1600-1730 on Jan 9

    -- Jeremy Bowers id 48Z55
select * from get_fit_now_check_in
where membership_id = '48Z55';
    -- OUTPUT: confirmed check in 1530-1700


```
All 3 were at the gym at the same time
- Annabel: 1600-1700
- Joe Germuska: 1600-1730
- Jeremy Bowers: 1530-1700

## Check plate number

- Find plate number from drivers_license table
- Compare to Joe and Jeremy's licence_id from person table

```sql

-- check for licenses that match the description of "includes H42W"
select * from drivers_license
where plate_number like '%H42W%'
and id = "118009" or id = "490173";
    -- OUTPUT: license exists



select * 
from person p
left join drivers_license dl
on dl.id = p.license_id
where plate_number like '%H42W%'
and dl.id = "118009" or dl.id = "490173";
    -- OUTPUT: Annabel Miller

-- RERUNNING (UPON REVIEW) the above without the id restrictions
    -- OUTPUT: Tushar Chandra, Jeremy Bowers, Maxine Whitely. Suspect is male, so eliminating Maxine as sus for now.

```
Currently, Jeremy Bowers is my primary suspect.

## Check facebook_event_checkin for additional information for each suspect

```sql

select p.name,
        fb.event_name,
        fb.date
from facebook_event_checkin fb
left join person p
    on p.id = fb.person_id
where date = 20180109
    and p.name like 'Annabel' OR
	p.name like 'Joe'OR
	p.name like 'Jeremy';
    -- No data returned

```

## Review notes
Morty said he saw a man run out. Need to check if Annabel goes to the gym with someone and was potentially an accomplice.

```sql

-- Who may have checked in at the same time as Annabel on Jan 9?
select * 
from get_fit_now_check_in ci
left join get_fit_now_member mem
    on mem.id = ci.membership_id
left join person p 
    on p.person_id on mem.person_id
where check_in_date = 20180109
and check_in_time = 1600;
    -- OUTPUT: membership_id	check_in_date	check_in_time	check_out_time
            -- 48Z7A	        20180109	    1600	        1730
            -- 90081	        20180109	    1600	        1700

-- Expand upon the above
select ci.membership_id,
		ci.check_in_date,
		ci.check_in_time,
		ci.check_out_time,
		mem.membership_status,
		p.name
from get_fit_now_check_in ci
left join get_fit_now_member mem
    on mem.id = ci.membership_id
left join person p 
    on p.id = mem.person_id
where check_in_date = 20180109
and check_in_time = 1600;
    -- OUTPUT: Joe Germuska 28819, Annabel Miller 16371

```

### Look into Joe Germuska

```sql

-- Check Joe's income
select p.name,
		i.annual_income
from person p
left join income i
	on i.ssn = p.ssn
where p.name like '%Germuska%';
    -- OUTPUT: null (Same for %Annabel%)
    
```
Potential motive?

### What we know:
- Crime scene report:
  - Security footage shows that there were 2 witnesses. The first witness lives at the last house on "Northwestern Dr". The second witness, named Annabel, lives somewhere on "Franklin Ave".
- Witnesses:
  - Morty Schapiro: I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. The membership number on the bag started with "48Z". Only gold members have those bags. The man got into a car with a plate that included "H42W".
  - Annabel Miller: I saw the murder happen, and I recognized the killer from my gym when I was working out last week on January the 9th.
- Gym members that match the number (both were at the gym at the same time as Annabel on 1/9):
  - Joe Germuska
  - Jeremy Bowers
- Jeremy Bowers has a license that matches the description.

Our suspect:
- Gold gym member
- Gym mem number starts with 48Z
- License with H42W
- Male
- At gym on 1/9 when Annabel was

Jeremy Bowers checks all of those boxes and is most likely the murderer.

--------------

## Who was behind Jeremy's actions?

```sql

-- View Jeremy's interview
select i.transcript,
		p.name
from interview i
left join person p
	on p.id = i.person_id
where p.name = "Jeremy Bowers";
    -- OUTPUT: I was hired by a woman with a lot of money. I don't know her name but I know she's around 5'5" (65") or 5'7" (67"). She has red hair and she drives a Tesla Model S. I know that she attended the SQL Symphony Concert 3 times in December 2017.

-- Search drivers_license table for physical description
select dl.height,
		dl.gender,
		dl.hair_color,
		dl.car_make,
		dl.car_model,
		p.name
from drivers_license dl
left join person p
on p.license_id = dl.id
where (dl.height between 65 and 67)
	and (dl.gender = "female")
	and (dl.hair_color = "red")
	and (dl.car_make = "Tesla")
	and (dl.car_model = "Model S");

    -- OUTPUT
    -- height	gender	hair_color	car_make	car_model	name
    -- 66	    female	red	        Tesla	    Model S	    Miranda Priestly
    -- 66	    female	red	        Tesla	    Model S	    Regina George
    -- 65	    female	red	        Tesla	    Model S	    Red Korb

-- Query further, cross-reference with facebook check in table
with suspect as (select dl.height,
		dl.gender,
		dl.hair_color,
		dl.car_make,
		dl.car_model,
		p.name,
		p.id
from drivers_license dl
left join person p
on p.license_id = dl.id
where (dl.height between 65 and 67)
	and (dl.gender = "female")
	and (dl.hair_color = "red")
	and (dl.car_make = "Tesla")
	and (dl.car_model = "Model S"))

select s.name,
		 fb.date,
		 fb.event_name
from suspect s
left join facebook_event_checkin fb
	on fb.person_id = s.id;

    -- OUTPUT:
    -- name	            date	    event_name
    -- Miranda Priestly	20171206	SQL Symphony Concert
    -- Miranda Priestly	20171212	SQL Symphony Concert
    -- Miranda Priestly	20171229	SQL Symphony Concert
    -- Regina George	null	    null
    -- Red Korb	        null	    null

```
Miranda Priestly has been implicated in this murder.