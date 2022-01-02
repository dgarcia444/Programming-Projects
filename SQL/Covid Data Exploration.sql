SELECT * FROM .[covid_deaths]
ORDER BY 3,4;

SELECT * FROM covid_vaccinations;
SELECT * FROM ['Covid Vaccinations$'];

SELECT 
	location,
	CAST(date AS DATE) AS date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM .['Covid Deaths$']
ORDER BY 1,2
;

-- Looking at total cases vs. total deaths

-- Shows the likelihood of dying from Covid-19 in the United States
SELECT 
	location,
	CAST(date AS DATE) AS date,
	total_cases,
	total_deaths,
    CONCAT((total_deaths/total_cases)*100,'%') AS 'Death Percentage'
FROM covid_deaths
WHERE location like '%states%'
	AND total_deaths IS NOT NULL
ORDER BY 2
;


-- Shows the likelihood of dying from Covid-19 in each country in a given day
SELECT 
	location,
	CAST(date AS DATE) AS date,
	total_cases,
	total_deaths,
    CONCAT((total_deaths/total_cases)*100,'%') AS 'Death Percentage'
FROM covid_deaths
WHERE total_deaths IS NOT NULL
	 AND continent != ''
ORDER BY 2
;

-- Show the likelihood of dying of Covid-19 in a given country
SELECT
	location,
	SUM(total_cases) AS 'Total cases until 7/11',
	SUM(total_deaths) AS 'Total Deaths until 7/11',
	CONCAT(SUM(total_deaths)/SUM(total_cases)*100,'%') AS 'Likelihood of Conctraction and Death'
FROM covid_deaths
WHERE continent != ''
	AND total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY 4 DESC
;


-- Looking at Total Cases vs Population 
-- Illustrating what percentage of the population contracted Covid-19 up until July 11th 2021

SELECT  
	location,
	CAST(date AS DATE) AS date,
	total_cases,
	population,
    (total_cases/population)*100 AS 'Population Infected'
FROM covid_deaths
WHERE total_cases IS NOT NULL
	AND continent != ''
ORDER BY 2,3
;


-- Countries with the higest infection rates
SELECT 
	location,
	population,
	MAX(total_cases) AS 'Highest Infection Count',
    CONCAT((MAX(total_cases)/population)*100,'%') AS 'Population Infected'
FROM .['Covid Deaths$']
WHERE population IS NOT NULL
	AND 'Highest Infection Count' IS NOT NULL
	AND continent IS NOT NULL 
	-- AND location NOT IN ('World','International','North America','South America','Europe','European Union','Asia','Africa')
GROUP BY location, population
ORDER BY 4 DESC
;

-- Countries with the higest infection rates (check)
SELECT 
	location,
	population,
	MAX(total_cases) AS 'Highest Infection Count',
    CONCAT(ROUND((MAX(total_cases)/population)*100,2),'%') AS 'Population Infected'
FROM covid_deaths
WHERE population IS NOT NULL
	AND 'Highest Infection Count' IS NOT NULL
	AND continent != ''
GROUP BY location, population
ORDER BY 4 DESC
;

-- Showing Countries with highest death count per population

SELECT 
	location,
	MAX(total_deaths) AS 'Highest Death Count'
FROM covid_deaths
WHERE continent != ''
	-- AND location NOT IN ('World','International','North America','South America','Europe','European Union','Asia','Africa')
GROUP BY location
ORDER BY 2 DESC
;


-- Showing continents with highest death count

-- subquery, highest deaths in each country by continent
SELECT 
	continent,
	location,
	MAX(total_deaths) AS 'Highest Death Count'
FROM covid_deaths
WHERE continent != ''
GROUP BY continent,location
;

-- adding up the highest deaths in each country and grouping by continent
SELECT 
	continent,
	SUM(highest_deaths) as 'Highest Death Total'
FROM(
SELECT 
	continent,
	location,
	MAX(total_deaths) AS highest_deaths
FROM covid_deaths
WHERE continent != ''
GROUP BY continent,location
) AS highest_deaths
GROUP BY continent
ORDER BY 2 DESC
;

-- Showing the lethal effect of Covid-19 on a global scale per day
SELECT 
	CAST(date AS DATE) AS date,
	SUM(new_cases) AS 'Total Cases',
	SUM(new_deaths) AS 'Total Deaths',
    CONCAT((SUM(new_deaths)/SUM(new_cases))*100,'%') AS 'Death Percentage'
FROM covid_deaths
WHERE continent != ''
	AND new_cases IS NOT NULL
	AND new_deaths IS NOT NULL
GROUP BY date
ORDER BY 1
;

-- Total cases, total deaths, death percentage up until 7/11/21
SELECT 
	-- CAST(date AS DATE) AS date,
	SUM(new_cases) AS 'Total Cases',
	SUM(new_deaths) AS 'Total Deaths',
    ROUND(SUM(new_deaths)/SUM(new_cases)*100,2) AS 'Death Percentage'
FROM covid_deaths
WHERE continent != ''
	AND new_cases IS NOT NULL
	AND new_deaths IS NOT NULL
-- GROUP BY date
ORDER BY 1
;

SELECT * FROM covid_vaccinations;

-- looking at total population vs Vaccinations
-- total amount of people in the world that have been vaccinated

-- Subquery (returns vaccionation rates for each country by continent)
SELECT 
	continent,
	location,
	CAST(date AS DATE) as date,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	CONCAT((people_vaccinated/population)*100,'%') AS '% Of One Dose',
	CONCAT((people_fully_vaccinated/population)*100,'%') AS '% Of Two Dose'
FROM covid_vaccinations
WHERE continent != ''
	 AND people_vaccinated IS NOT NULL
	 AND people_fully_vaccinated IS NOT NULL
ORDER BY 1,2,3
;

-- Return a list of countries with the highest vaccionation rates

-- Using CTE
WITH 
	VaccRates (continent,location,date,population,people_vaccinated,people_fully_vaccinated,one_dose,two_doses)
AS(
SELECT 
	continent,
	location,
	CAST(date AS DATE) as date,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	(people_vaccinated/population)*100 AS one_dose,
	(people_fully_vaccinated/population)*100 AS two_doses
FROM covid_vaccinations
WHERE continent != ''
	 AND people_vaccinated IS NOT NULL
	 AND people_fully_vaccinated IS NOT NULL
)
SELECT
	location,
	CONCAT(one_dose,'%') AS 'Highest % of population with at least one Dose'
	-- two_doses AS 'Highest % of population fully vaccinated'
FROM VaccRates
WHERE date = '2021-07-11'
ORDER BY one_dose DESC
;

-- Using Temporary Table
DROP TABLE IF EXISTS vaccination_rates
CREATE TABLE vaccination_rates
(continent nvarchar(255),
location nvarchar(255),
date Datetime,
population numeric,
people_vaccinated numeric,
people_fully_vaccinated numeric,
one_dose float,
two_doses float)

INSERT INTO vaccination_rates
SELECT 
	continent,
	location,
	CAST(date AS DATE) as date,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	(people_vaccinated/population)*100 AS one_dose,
	(people_fully_vaccinated/population)*100 AS two_doses
FROM covid_vaccinations
WHERE continent != ''
	 AND people_vaccinated IS NOT NULL
	 AND people_fully_vaccinated IS NOT NULL
;

-- QA
SELECT * FROM vaccination_rates;

SELECT DISTINCT * 
FROM vaccination_rates
WHERE location = 'Gibraltar';


-- Make the following queries more modular

-- Look at countries with highest % of population with at least one dose
-- Up to 7/11/21

SELECT 
	location,
	CONCAT(one_dose,'%') AS 'Highest % of population with at least one Dose'
FROM vaccination_rates
WHERE date = '2021-07-11'
ORDER BY one_dose DESC
;

SELECT 
	location,
	-- CONCAT(one_dose,'%') AS 'Highest % of population with at least one Dose'
	MAX(one_dose) AS 'Highest % of population with at least one Dose'
FROM vaccination_rates
GROUP BY location
ORDER BY 2 DESC
;

-- Look at countries with highest % of fully vaccinated population
-- Up to 7/11/21
SELECT 
	location,
	CONCAT(two_doses,'%') AS 'Highest % of population fully vaccinated'
FROM vaccination_rates
WHERE date = '2021-07-11'
ORDER BY two_doses DESC
;

SELECT 
	location,
    -- CONCAT(MAX(two_doses), '%') AS 'Highest % of population fully vaccinated'
	MAX(two_doses) AS 'Highest % of population fully vaccinated'
FROM vaccination_rates
WHERE population > 100000
GROUP BY location
ORDER BY 2 DESC
;



-- Countries with Highest population with at least one dose as of July 11th 2021
-- Only countries with a population of at least 10,000,000 people
SELECT 
	location,
	CONCAT(one_dose,'%') AS 'Highest % of population with at least one dose'
FROM vaccination_rates
WHERE date = '2021-07-11'
	AND population > 10000000
ORDER BY one_dose DESC
;

SELECT 
	location,
	-- CONCAT(one_dose,'%') AS 'Highest % of population with at least one dose'
	MAX(one_dose) AS 'Highest % of population with at least one dose'
FROM vaccination_rates
WHERE population > 10000000
GROUP BY location
ORDER BY 2 DESC
;

-- Countries with Highest fully vaccinated population as of July 11th 2021
-- Only countries with a population of at least 10,000,000 people
SELECT 
	location,
	CONCAT(two_doses,'%') AS 'Highest % of population fully vaccinated'
FROM vaccination_rates
WHERE date = '2021-07-11'
	AND population > 10000000
ORDER BY two_doses DESC
;

SELECT 
	location,
	-- CONCAT(two_doses,'%') AS 'Highest % of population fully vaccinated'
	MAX(two_doses) AS 'Highest % of population fully vaccinated'
FROM vaccination_rates
WHERE population > 10000000
GROUP BY location
ORDER BY 2 DESC
;

-- Continents with at least one dose

-- EDIT (made more modular to fit with any iteration of covid statistics)
SELECT 
	continent,
	location,
	MAX(population) AS 'population',
	MAX(people_vaccinated) AS 'people_vaccinated',
	MAX(people_fully_vaccinated) AS 'people_fully_vaccinated',
	MAX(one_dose) AS higest_one_dose,
	MAX(two_doses) AS highest_two_dose
FROM vaccination_rates
WHERE continent != ''
GROUP BY continent, location
;


-- EDIT
SELECT 
	continent,
	CAST(ROUND(SUM(people_vaccinated)/SUM(population)*100,2) AS DECIMAL(8,2)) AS '% of One dose'
	--CONCAT(SUM(people_fully_vaccinated)/SUM(population)*100,'%') AS '% Fully Vaccinated'
FROM(
SELECT 
	continent,
	location,
	MAX(population) AS 'population',
	MAX(people_vaccinated) AS 'people_vaccinated',
	MAX(people_fully_vaccinated) AS 'people_fully_vaccinated',
	MAX(one_dose) AS higest_one_dose,
	MAX(two_doses) AS highest_two_dose
FROM vaccination_rates
WHERE continent != ''
GROUP BY continent, location
) AS vacc_list
GROUP BY continent
ORDER BY 2 DESC
;
-- looking at the vaccination rates for continents
SELECT 
	continent,
    CAST(ROUND(SUM(people_fully_vaccinated)/SUM(population)*100,2) AS DECIMAL(8,2)) AS '% Fully Vaccinated'
FROM(
SELECT 
	continent,
	location,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	one_dose AS higest_one_dose,
	two_doses AS highest_two_dose
FROM vaccionation_rates
WHERE date = '2021-07-11'
	AND continent != ''
) AS vacc_list
GROUP BY continent
ORDER BY 2 DESC
;

-- EDIT 
SELECT 
	continent,
    CAST(ROUND(SUM(people_fully_vaccinated)/SUM(population)*100,2) AS DECIMAL(8,2)) AS '% Fully Vaccinated'
FROM(
SELECT 
	continent,
	location,
	MAX(population) AS 'population',
	MAX(people_vaccinated) AS 'people_vaccinated',
	MAX(people_fully_vaccinated) AS 'people_fully_vaccinated',
	MAX(one_dose) AS higest_one_dose,
	MAX(two_doses) AS highest_two_dose
FROM vaccination_rates
WHERE continent != ''
GROUP BY continent, location
) AS vacc_list
GROUP BY continent
ORDER BY 2 DESC
;

-- looking at covid deaths along with stringency score
-- stringency score rates the responses a coutnry took against the spread of covid
-- looking at when countries started responding seriously to Covid

-- subquery to create the data that we're going to query off of
SELECT
	covid_deaths.continent,
	covid_deaths.location,
	CAST(covid_deaths.date AS DATE) AS date,
	covid_deaths.new_cases,

	SUM(covid_deaths.new_cases) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS rolling_total_cases,
	covid_deaths.new_deaths,
	SUM(covid_deaths.new_deaths) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS rolling_total_deaths,
	covid_vaccinations.stringency_index
FROM covid_deaths
JOIN covid_vaccinations	
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent != ''
ORDER BY continent,location,date
;




-- looking at poverty rates and Covid

SELECT 
	DISTINCT extreme_poverty,
	human_development_index,
	life_expectancy
FROM covid_vaccinations
WHERE extreme_poverty IS NOT NULL
ORDER BY 1,3 DESC;

-- Subquery that creates the table we're going to query off of
SELECT 
	covid_deaths.continent,
	covid_deaths.location,
	CAST(covid_deaths.date AS DATE) AS date,
	SUM(covid_deaths.new_cases) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS rolling_total_cases,
	covid_deaths.new_deaths,
	SUM(covid_deaths.new_deaths) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS rolling_total_deaths,
	covid_vaccinations.total_vaccinations,
	covid_vaccinations.extreme_poverty,
	covid_vaccinations.human_development_index,
	covid_vaccinations.life_expectancy
FROM covid_deaths
JOIN covid_vaccinations	
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent != ''
	AND covid_vaccinations.extreme_poverty IS NOT NULL
ORDER BY 1,2,3
;


DROP TABLE IF EXISTS death_and_poverty;
CREATE TABLE death_and_poverty
(continent nvarchar(255),
location nvarchar(255),
date Date,
population numeric,
new_cases numeric,
total_cases numeric,
new_deaths numeric,
total_deaths float,
extreme_poverty float,
human_development_index float,
life_expectancy float)

INSERT INTO death_and_poverty
SELECT 
	covid_deaths.continent,
	covid_deaths.location,
	CAST(covid_deaths.date AS DATE) AS date,
	covid_deaths.population,
	covid_deaths.new_cases,
	SUM(covid_deaths.new_cases) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS total_cases,
	covid_deaths.new_deaths,
	SUM(covid_deaths.new_deaths) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS total_deaths,
	covid_vaccinations.extreme_poverty,
	covid_vaccinations.human_development_index,
	covid_vaccinations.life_expectancy
FROM covid_deaths
JOIN covid_vaccinations	
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent != ''
	AND covid_vaccinations.extreme_poverty IS NOT NULL
;

SELECT * FROM death_and_poverty;

-- looking at death rates for the most impoverished countries
SELECT 
	location,
	extreme_poverty,
	CONCAT(ROUND(SUM(total_deaths)/SUM(total_cases)*100,2),'%') AS death_rate
FROM death_and_poverty
GROUP BY location,extreme_poverty
ORDER BY 2 DESC
;

-- looking at infection rates for the most impoverished countries
SELECT 
	location,
	extreme_poverty,
	CONCAT(CAST(ROUND(MAX(total_cases)/population*100,2) AS DECIMAL(8,2)),'%') AS infection_rate
FROM death_and_poverty
GROUP BY location,extreme_poverty,population
ORDER BY 2 DESC
;

-- looking at death rate for countries with the lowest life expectancy
SELECT
	location,
	life_expectancy,
	CONCAT(ROUND(SUM(total_deaths)/SUM(total_cases)*100,2),'%') AS death_rate
FROM death_and_poverty
WHERE life_expectancy IS NOT NULL
GROUP BY location,life_expectancy
ORDER BY life_expectancy
;

-- looking at infection rates of countries with the lowest life expectancy
SELECT 
	location,
	life_expectancy,
	CONCAT(CAST(ROUND(MAX(total_cases)/population*100,2) AS DECIMAL(8,2)),'%') AS infection_rate
FROM death_and_poverty
WHERE life_expectancy IS NOT NULL
GROUP BY location,life_expectancy,population
ORDER BY 2 
;

SELECT * FROM vaccionation_rates;

-- looking at vaccination rates for the most impoverished countries
SELECT
	death_and_poverty.location,
	death_and_poverty.extreme_poverty,
	CONCAT(CAST(ROUND(MAX(vaccination_rates.one_dose),2) AS DECIMAL(8,2)),'%') AS population_with_one_dose,
	CONCAT(CAST(ROUND(MAX(vaccination_rates.two_doses),2) AS DECIMAL(8,2)),'%') AS population_fully_vaccinated
FROM death_and_poverty
JOIN vaccination_rates
	ON death_and_poverty.location = vaccination_rates.location
	AND death_and_poverty.date = vaccination_rates.date
GROUP BY death_and_poverty.location, death_and_poverty.extreme_poverty
ORDER BY 2 DESC
;

-- Creating views to store data for future visualizations
CREATE VIEW vacc_rates_population AS
SELECT 
	continent,
	location,
	CAST(date AS DATE) as date,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	(people_vaccinated/population)*100 AS one_dose,
	(people_fully_vaccinated/population)*100 AS two_doses
FROM covid_vaccinations
WHERE continent != ''
	 AND people_vaccinated IS NOT NULL
	 AND people_fully_vaccinated IS NOT NULL

;


CREATE VIEW vacc_rates_poverty AS
SELECT
	death_and_poverty.location,
	death_and_poverty.extreme_poverty,
	CAST(ROUND(MAX(vaccination_rates.one_dose),2) AS DECIMAL(8,2)) AS population_with_one_dose,
	CAST(ROUND(MAX(vaccination_rates.two_doses),2) AS DECIMAL(8,2)) AS population_fully_vaccinated
FROM death_and_poverty
JOIN vaccination_rates
	ON death_and_poverty.location = vaccination_rates.location
	AND death_and_poverty.date = vaccination_rates.date
GROUP BY death_and_poverty.location, death_and_poverty.extreme_poverty
--ORDER BY 2 DESC
;

CREATE VIEW death_rates_poverty AS
SELECT 
	covid_deaths.continent,
	covid_deaths.location,
	CAST(covid_deaths.date AS DATE) AS date,
	covid_deaths.population,
	covid_deaths.new_cases,
	SUM(covid_deaths.new_cases) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS total_cases,
	covid_deaths.new_deaths,
	SUM(covid_deaths.new_deaths) 
		OVER(PARTITION BY covid_deaths.location
			ORDER BY covid_deaths.date) AS total_deaths,
	covid_vaccinations.extreme_poverty,
	covid_vaccinations.human_development_index,
	covid_vaccinations.life_expectancy
FROM covid_deaths
JOIN covid_vaccinations	
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent != ''
	AND covid_vaccinations.extreme_poverty IS NOT NULL


CREATE VIEW vacc_rates_continents AS 
SELECT
	continent,
	MAX(one_dose) AS '% of Population with One Dose',
	MAX(two_doses) AS '% of population Fully Vaccinated'
FROM(
SELECT 
	continent,
	date,
	CAST(ROUND(SUM(people_vaccinated)/SUM(population)*100,2) AS DECIMAL(8,2)) AS one_dose,
    CAST(ROUND(SUM(people_fully_vaccinated)/SUM(population)*100,2) AS DECIMAL(8,2)) AS two_doses
FROM(
SELECT 
	continent,
	location,
	date,
	population,
	people_vaccinated,
	people_fully_vaccinated,
	one_dose AS higest_one_dose,
	two_doses AS highest_two_dose
FROM vaccionation_rates
WHERE  continent != ''
) AS vacc_list_daily
GROUP BY continent,date
)AS vacc_list_total
GROUP BY continent
;


CREATE VIEW country_infection_rates AS
SELECT 
	location,
	population,
	MAX(total_cases) AS 'Highest Infection Count',
    ROUND((MAX(total_cases)/population)*100,2) AS ' % Population Infected'
FROM covid_deaths
WHERE population IS NOT NULL
	AND 'Highest Infection Count' IS NOT NULL
	AND continent != ''
GROUP BY location, population
;


CREATE VIEW population_infected_over_time_by_country AS
SELECT 
	location,
	CAST(date AS DATE) as date,
	population,
	MAX(total_cases) AS 'Highest Infection Count',
    ROUND((MAX(total_cases)/population)*100,2) AS 'Population Infected'
FROM covid_deaths
WHERE population IS NOT NULL
	AND 'Highest Infection Count' IS NOT NULL
	AND continent != ''
GROUP BY location, population,date
;

CREATE VIEW global_cases_deaths AS
SELECT 
	-- CAST(date AS DATE) AS date,
	SUM(new_cases) AS 'Total Cases',
	SUM(new_deaths) AS 'Total Deaths',
    ROUND(SUM(new_deaths)/SUM(new_cases)*100,2) AS 'Death Percentage'
FROM covid_deaths
WHERE continent != ''
	AND new_cases IS NOT NULL
	AND new_deaths IS NOT NULL

;

CREATE VIEW daily_infection_rates AS 
SELECT  
	location,
	CAST(date AS DATE) AS date,
	total_cases,
	population,
    (total_cases/population)*100 AS 'Population Infected'
FROM covid_deaths
WHERE total_cases IS NOT NULL
	AND continent != ''
;


CREATE VIEW highest_covid_deaths_by_country AS
SELECT 
	location,
	MAX(total_deaths) AS 'Highest Death Count'
FROM covid_deaths
WHERE continent != ''
	-- AND location NOT IN ('World','International','North America','South America','Europe','European Union','Asia','Africa')
GROUP BY location
;

CREATE VIEW continental_death_rate AS
SELECT 
	continent,
	SUM(highest_deaths) as 'Highest Death Total'
FROM(
SELECT 
	continent,
	location,
	MAX(total_deaths) AS highest_deaths
FROM covid_deaths
WHERE continent != ''
GROUP BY continent,location
) AS highest_deaths
GROUP BY continent
;