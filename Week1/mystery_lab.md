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
-- output: CREATE TABLE crime_scene_report ( date integer, type text, description text, city text )

```

## Find murder information
Date: January 15, 2018
City: SQL City

```sql

-- View entire crime scene report table
select * from crime_scene_report;


```