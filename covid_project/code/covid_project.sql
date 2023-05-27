-- Database: covid
-- DATA FROM https://ourworldindata.org/covid-deaths
--Check and change data types of columns
ALTER TABLE covid_death
ALTER COLUMN date TYPE date USING to_date(date, 'dd-mm-yyyy'),
ALTER COLUMN total_cases TYPE double precision,
ALTER COLUMN total_deaths TYPE double precision;

ALTER TABLE covid_vaccination
ALTER COLUMN date TYPE date USING to_date(date, 'dd-mm-yyyy'),
ALTER COLUMN people_vaccinated TYPE double precision,
ALTER COLUMN people_fully_vaccinated TYPE double precision,
ALTER COLUMN total_boosters TYPE double precision;

--Look at data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_death
ORDER BY location, date;

--Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS pct_death
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY date;

--Total Cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS pct_cases
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY date;

--Countries with highest infection rate
--Includes reinfection, thus inflated numbers
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS max_pct_cases
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_pct_cases DESC;

--Max deaths by countries
SELECT location, MAX(total_deaths) AS max_deaths
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_deaths DESC;


--Countries with highest death count per population
SELECT location, population, MAX(total_deaths) AS highest_death_count, MAX(total_deaths/population)*100 AS max_pct_deaths
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_pct_deaths DESC; 

--Continents with highest death count per population
SELECT location, MAX(total_deaths/population)*100 AS pct_death
FROM covid_death
WHERE continent IS NULL AND location NOT LIKE '%income%' AND location NOT LIKE 'World' AND location NOT LIKE '%Union%'
GROUP BY location
ORDER BY pct_death DESC;


--Deaths by continent
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_death
WHERE continent IS NULL AND location NOT LIKE '%income%' AND location NOT LIKE 'World' AND location NOT LIKE '%Union%'
GROUP BY location
ORDER BY total_death_count DESC;

--Global cases and deaths
SELECT date, SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, (SUM(total_deaths)/SUM(total_cases))*100 AS pct_death
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY date;

--Rolling vaccination count vs population
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM covid_death AS dea
JOIN covid_vaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


--CTE to get percentage of vac count vs population
WITH vac_vs_pop AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
	FROM covid_death AS dea
	JOIN covid_vaccination AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)

SELECT continent, location, date, population, new_vaccinations,
	rolling_ppl_vac, (rolling_ppl_vac/population)*100 AS pct_vac
FROM vac_vs_pop


--Create view tableau
CREATE VIEW pct_pop_vac AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM covid_death AS dea
JOIN covid_vaccination AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
