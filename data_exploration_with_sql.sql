--TITLE: DATA EXPLORATION WITH SQL USING COVID19 DATASET

--Let's create our first table
CREATE TABLE covid19_deaths
(iso_code text,
 continent text,
 location text,
 date date,
 population_density text,
 total_cases text,
 new_cases text,
 new_cases_smoothed text,
 total_deaths text,
 new_deaths text,
 new_deaths_smoothed text,
 total_cases_per_million text,
 new_cases_per_million text,
 new_cases_smoothed_per_million text,
 total_deaths_per_million text,
 new_deaths_per_million text,
 new_deaths_smoothed_per_million text,
 reproduction_rate text,
 icu_patients text,
 icu_patients_per_million text,
 hosp_patients text,
 hosp_patients_per_million text,
 weekly_icu_admissions text,
 weekly_icu_admissions_per_million text,
 weekly_hosp_admissions text,
 weekly_hosp_admissions_per_million text)
 
 --Let's load the corresponding csv file into our first table
 COPY PUBLIC."covid19_deaths"
 FROM 'C:\Users\HP\Desktop\CSV Files\Covid_deaths.csv'
 DELIMITER ','
 CSV HEADER;
 
 --Let's see the first 10 rows of our first table
 SELECT *
 FROM covid19_deaths
 LIMIT 10;
 
 --Let's create our second table
 CREATE TABLE covid19_vaccinations
 (iso_code text,
  continent text,
  location text,
  date text,
  total_tests text,
  new_tests text,
  total_tests_per_thousand text,
  new_tests_per_thousand text,
  new_tests_smoothed text,
  new_tests_smoothed_per_thousand text,
  positive_rate text,
  tests_per_case text,
  tests_units text,
  total_vaccinations text,
  people_vaccinated text,
  people_fully_vaccinated text,
  total_boosters text,
  new_vaccinations text,
  new_vaccinations_smoothed text,
  total_vaccinations_per_hundred text,
  people_vaccinated_per_hundred text,
  people_fully_vaccinated_per_hundred text,
  total_boosters_per_hundred text,
  new_vaccinations_smoothed_per_million text,
  new_people_vaccinated_smoothed text,
  new_people_vaccinated_smoothed_per_hundred text
 )
 
  --Let's load the corresponding csv file into our second table
 COPY PUBLIC."covid19_deaths"
 FROM 'C:\Users\HP\Desktop\CSV Files\CovidVacinations.csv'
 DELIMITER ','
 CSV HEADER;
 
 --Let's the first 10 rows of our second table
 SELECT *
 FROM covid19_vaccinations
 LIMIT 10;
 
 --Let's create a temporary table comprising of the columns we shall be mostly using
CREATE TEMP TABLE covid_death_cols AS
SELECT
  continent,
  location,
  date::date,
  population_density::numeric,
  total_cases::numeric,
  new_cases::numeric,
  total_deaths::numeric,
  new_deaths::numeric
FROM covid19_deaths 
WHERE continent IS NOT NULL;
 
 --Let's see the percentage population of infected with covid in Nigeria
SELECT 
  location,
  date,
  population_density,
  total_cases,
  ROUND((total_cases/population_density),2)*100 AS NG_pop_infected
FROM covid_death_cols
WHERE location = 'Nigeria'
  AND total_cases IS NOT NULL
ORDER BY date DESC;

--Let's check the chances of dying on contracting covid in Canada
SELECT 
  location,
  date,
  total_cases
  total_deaths,
  (total_deaths/total_cases)*100 AS percentage_death
FROM covid_death_cols
WHERE location LIKE '%Canada%'
  AND total_deaths IS NOT NULL
  AND total_cases IS NOT NULL
ORDER BY date DESC, percentage_death DESC; 

--Let's check for top-10 countries with highest covid cases per population
SELECT 
  location,
  MAX(total_cases) AS highest_nunmber_of_case,
  MAX((total_cases/population_density))*100 AS percent_cases_per_pop
FROM covid_death_cols
WHERE total_cases IS NOT NULL
  AND population_density IS NOT NULL
GROUP BY location
ORDER BY percent_cases_per_pop DESC
LIMIT 10;

--Let's check for top-10 countries with highest covid death
SELECT
  location,
  MAX(total_deaths) AS highest_number_of_death
FROM covid_death_cols
WHERE total_deaths IS NOT NULL
GROUP BY location
ORDER BY highest_number_of_death DESC
LIMIT 10;

--Let's check for sum-total cases of covid across continents
SELECT
  continent,
  SUM(total_cases) AS sum_total_cases
FROM covid_death_cols
WHERE total_cases IS NOT NULL
GROUP BY continent
ORDER BY sum_total_cases DESC;

--Let's check for sum-total death across continents
SELECT
  continent,
  SUM(total_deaths) AS sum_total_deaths
FROM covid_death_cols
WHERE total_deaths IS NOT NULL
GROUP BY continent
ORDER BY sum_total_deaths DESC;

--Let's calculate the average of covid death across the continents for each year
WITH CTE AS(
  SELECT
	continent,
	EXTRACT(year FROM date) AS year,
	total_deaths
	FROM covid_death_cols
	WHERE total_deaths IS NOT NULL
)

SELECT
  continent,
  year,
  AVG(total_deaths) OVER(
    PARTITION BY continent, year) AS avg_death
FROM CTE
GROUP BY continent, total_deaths, year
ORDER BY avg_death DESC, year DESC;

--Let's check the percentage of people that have recieved at least one vaccination in each country
WITH CTE AS(
  SELECT
	d.location,
	d.date,
	d.population_density,
	v.new_vaccinations,
	SUM(new_vaccinations::numeric/population_density)
	   OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rollin_pop_vacc
  FROM covid_death_cols AS d
  LEFT JOIN covid19_vaccinations AS V
  ON d.location = v.location
    AND d.date = v.date::date)
	
SELECT *,
  (rollin_pop_vacc/population_density)*100 AS percent_pop_vacc
FROM CTE

--Let's create a view with our previous query for easy references
CREATE VIEW percentage_of_pop_vaccinated AS
WITH CTE AS(
  SELECT
	d.location,
	d.date,
	d.population_density,
	v.new_vaccinations,
	SUM(new_vaccinations::numeric/population_density)
	   OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rollin_pop_vacc
  FROM covid_death_cols AS d
  LEFT JOIN covid19_vaccinations AS V
  ON d.location = v.location
    AND d.date = v.date::date)
	
SELECT *,
  (rollin_pop_vacc/population_density)*100 AS percent_pop_vacc
FROM CTE;
