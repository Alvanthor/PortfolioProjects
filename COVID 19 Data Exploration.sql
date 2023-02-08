/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL 
order by 3,4;

-- Select Data to be start with
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Countries with Highest Death Count per Population
SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if get infected with covid in Indonesia
SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location IS 'Indonesia'
AND continent IS NOT NULL 
ORDER BY 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in Indonesia
SELECT location, date, population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE location IS 'Indonesia'
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population in Indonesia
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location IS 'Indonesia'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- GLOBAL CASES DAILY
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CONVERT(int,CV.new_vaccinations)) OVER (Partition by CD.Location Order by CD.location, CD.Date) as NumPeopleVaccinated
FROM CovidDeaths AS CD
LEFT JOIN CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query
WITH VacVSPop (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CONVERT(int,CV.new_vaccinations)) OVER (Partition by CD.Location Order by CD.location, CD.Date) as NumPeopleVaccinated
FROM CovidDeaths AS CD
LEFT JOIN CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccination
FROM VacVSPop;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CONVERT(int,CV.new_vaccinations)) OVER (Partition by CD.Location Order by CD.location, CD.Date) as NumPeopleVaccinated
FROM CovidDeaths AS CD
LEFT JOIN CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
Select *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccination
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CONVERT(int,CV.new_vaccinations)) OVER (Partition by CD.Location Order by CD.location, CD.Date) as NumPeopleVaccinated
FROM CovidDeaths AS CD
LEFT JOIN CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;
