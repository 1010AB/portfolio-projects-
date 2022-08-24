SELECT *
FROM [Covid_19 ].dbo.[owid-covid-data]

--SELECT *
--FROM [Covid_19 ].dbo.[owid-covid-data]
--ORDER by 3,4
-- Select the columns that you are going to be using fro the project.

SELECT 
location, date,total_cases,new_cases,total_deaths,population
FROM [Covid_19 ].dbo.[owid-covid-data]
ORDER BY 1
-- first change most of the datatypes to their approprate datatypes 
--ALTER TABLE [Covid_19].dbo.[owid-covid-data]
--ALTER COLUMN date DATE;
---- changing from chacter to number 
--ALTER TABLE [Covid_19].dbo.[owid-covid-data]
--ALTER COLUMN total_cases NUMERIC;

--ALTER COLUMN new_cases INT
--ALTER COLUMN population FLOAT; 
-- edit and converting the whole table using cast and try_cast
-- creating a temp table 
DROP TABLE IF EXISTS #change_datatypes
CREATE TABLE #change_datatypes(
location VARCHAR(100),
continent VARCHAR(100),
date DATE,
total_cases NUMERIC,
new_cases NUMERIC,
total_deaths NUMERIC,
new_deaths NUMERIC,
population NUMERIC
)
-- INSERT INTO 
INSERT INTO #change_datatypes 
SELECT 
location,
continent,
CONVERT(date,date) as cdate,
TRY_CAST(total_cases as numeric)  as total_cases,
TRY_CAST(new_cases as numeric) as new_cases,
TRY_CAST(total_deaths as numeric) as total_deaths,
TRY_CAST(new_deaths as numeric)as new_deaths,
TRY_CAST(population as numeric) as population
FROM [Covid_19 ].dbo.[owid-covid-data]

-- working on from the temp table that was created 
SELECT 
*
FROM #change_datatypes
WHERE continent IS NOT NULL
ORDER BY 1


-- total cases vs total deaths 
SELECT 
location,
total_cases,
total_deaths,
(total_deaths/total_cases)* 100 as deaths_percentage
FROM
#change_datatypes
ORDER BY 1

-- likehood of dying with covid_19 
SELECT 
location,
date,
total_cases,
total_deaths,
(total_deaths/total_cases)* 100 as deaths_percentage
FROM
#change_datatypes
WHERE location LIKE '%United%'
ORDER BY 1

-- percentage of population got covid 
SELECT 
location,
date,
total_cases,
population,
(total_cases / population)*100 as infection_rates 
FROM
#change_datatypes
WHERE location LIKE '%NIG%'
ORDER BY 1,2

-- Countries with the highest infection rates 
SELECT 
location,
population,
MAX(total_cases) as highestInfectionRates,
MAX((total_cases/population))*100 as percentage_porpulationinfected 
FROM
#change_datatypes
--WHERE location LIKE '%NIG%'
GROUP BY 
location,
population
ORDER BY
(4) DESC


---- Showing the country with the hightest deaths rate 
--SELECT 
--location,
--MAX(total_deaths) as totaldeathsRate
--MAX((total_deaths/population))*100 as PercentageTotalDeathRate
--FROM #change_datatypes
--GROUP BY 
--location
--ORDER BY 
--(3) DESC
 
 -- Breaking things down by Continent 
 SELECT 
 continent,
 MAX (total_deaths) as MaxdeathRate
 FROM 
 #change_datatypes
 WHERE continent IS NOT NULL
 GROUP BY 
 continent
 ORDER BY 
 (2) DESC 

 -- GLOBAL NUMBER 
 SELECT 
 date,
 SUM(new_cases) as TodaysCases,
 SUM(new_deaths) as Todaysdeaths,
 (SUM(new_deaths) /NULLIF (SUM(new_cases),0))*100 as deathspercentage 
-- note that in other to aviod the zero divisor i made use of the NULLIF function to nullthe amswer whenever the new case value is zer.
FROM 
#change_datatypes
--WHERE continent IS NOT NULL
GROUP BY 
date 
ORDER BY 
1

--creating a temp table for vaccination table 
DROP TABLE IF EXISTS #Vacc_changedatatypes
CREATE TABLE #Vacc_changedatatypes(
location VARCHAR(100),
continent VARCHAR(100),
date DATE,
total_cases NUMERIC,
new_cases NUMERIC,
total_deaths NUMERIC,
new_deaths NUMERIC,
new_vaccinations NUMERIC,
total_vaccinations numeric,
population NUMERIC
)
-- INSERT INTO 
INSERT INTO #Vacc_changedatatypes 
SELECT 
location,
continent,
CONVERT(date,date),
TRY_CAST(total_cases as numeric),
TRY_CAST(new_cases as numeric),
TRY_CAST(total_deaths as numeric),
TRY_CAST(new_deaths as numeric),
TRY_CAST(new_vaccinations as numeric),
TRY_CAST(total_vaccinations as numeric),
TRY_CAST(population as numeric)
FROM [Covid_19 ].dbo.[owid-covid-data]
-- joining the two temp tables in other to do other thing
-- looking at total population vs vaccination  
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) total_vaccination_ofTheDay
FROM 
#Vacc_changedatatypes as vac
join 
#change_datatypes as dea
on vac.location = dea.location AND
   vac.date = dea.date
   WHERE dea.continent IS NOT NULL
   ORDER BY 2, 3

   -- population vs vaccinated 

   -- using CTE 
   WITH popvsvac (continent, location , date,population, new_vaccination, rollingPeopleVaccinated)
   as 
   (SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM 
#Vacc_changedatatypes as vac
join 
#change_datatypes as dea
on vac.location = dea.location AND
   vac.date = dea.date
   WHERE dea.continent IS NOT NULL
   ) -- i didn"t get the required result for this query 
   -- its important to note that i


   -- temp table
   DROP TABLE IF EXISTS #populationvaccinatedpercentage 
   CREATE TABLE #populationvaccinatedpercentage (
   continent NVARCHAR(255),
   location NVARCHAR(255),
   Date_ DATE,
   population NUMERIC,
   new_vaccinated NUMERIC,
   rollingPeopleVaccinated NUMERIC 
   )
   INSERT INTO #populationvaccinatedpercentage
   SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) total_vaccination_ofTheDay
FROM 
#Vacc_changedatatypes as vac
join 
#change_datatypes as dea
on vac.location = dea.location AND
   vac.date = dea.date
   WHERE dea.continent IS NOT NULL
   ORDER BY 2, 3


   -- creating views for most of the queries 
   CREATE VIEW 
   percentagevaccinatedpopulation as
    SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) total_vaccination_ofTheDay
FROM 
#Vacc_changedatatypes as vac
join 
#change_datatypes as dea
on vac.location = dea.location AND
   vac.date = dea.date
   WHERE dea.continent IS NOT NULL
   --ORDER BY 2, 3
   -- it is important to note that views can not be created from temp tables 