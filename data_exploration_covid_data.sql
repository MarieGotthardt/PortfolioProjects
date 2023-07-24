/*
Data Exploration in SQL (inspired by Alex the Analyst)
*/

-- take a look at the data
SELECT *
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL --continent not null implies that we select countries
ORDER BY location, date

---------------------------------------------------------------------------------------------------------
-- Covid infections and deaths 

-- total cases vs. population: shows the percentage of Covid infections in the population for each country
SELECT date, population, CAST(total_cases AS int), (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeathsMod
WHERE location = 'Sweden'
AND continent IS NOT NULL
ORDER BY 1,2


-- countries with highest infection rate compared to population 
SELECT location, population, MAX(CAST(total_cases AS int)) as HighestInfectionCount,  MAX((CAST(total_cases AS int)/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- countries with highest infection rate compared to population (with time course) 
SELECT location, population, date, MAX(CAST(total_cases AS int)) as HighestInfectionCount,  MAX((CAST(total_cases AS int)/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC


-- total cases vs. total deaths: likelihood of dying if infected with covid (globally) 
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL


-- likelihood of dying if infected with covid (for a specific country)
SELECT location, date, total_cases, total_deaths, (total_deaths/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMod
WHERE location = 'Sweden'
	AND continent IS NOT NULL
ORDER BY 1,2


-- total covid death count per continent 
SELECT location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- countries with highest covid death count 
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- total Covid infections, covid related deaths and percentage of deaths in Covid infections, globally 
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
ORDER BY 1,2


-- percentage of covid deaths and smoker percentage, age_70_older percentage, diabetes prevalence
WITH FilterExistingDeathEntries (location, DeathPercentage) 
AS (
SELECT location, SUM(CAST(new_deaths AS INT)/population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMod 
WHERE continent IS NOT NULL
	AND new_deaths IS NOT NULL
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, population
)
SELECT DISTINCT fede.location, fede.DeathPercentage, cv.female_smokers, cv.male_smokers, cv.aged_70_older, cv.diabetes_prevalence
FROM FilterExistingDeathEntries fede
JOIN PortfolioProject..CovidVaccinationsMod cv
ON fede.location = cv.location
--GROUP BY location, cv.male_smokers, cv.female_smokers
ORDER BY fede.DeathPercentage DESC


---------------------------------------------------------------------------------------------------------
-- Covid vaccinations

-- total population vs vaccinations (window function and CTE)
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(cv.new_vaccinations AS BIGINT)) 
	OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsMod cd
JOIN PortfolioProject..CovidVaccinationsMod cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercentage
FROM PopvsVac


-- total population vs vaccinations (temp table)
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) 
	OVER (Partition by cd.location Order by cd.location, cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsMod cd
JOIN PortfolioProject..CovidVaccinationsMod cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated


-- percentage of fully vaccinated persons
SELECT cd.location, (MAX(CAST(cv.people_fully_vaccinated AS BIGINT))/cd.population)*100 AS PercentageFullyVaccinated
FROM PortfolioProject..CovidDeathsMod cd
JOIN PortfolioProject..CovidVaccinationsMod cv
ON cd.location = cv.location
AND cd.date = cv.date
GROUP BY cd.location, cd.population
ORDER BY PercentageFullyVaccinated DESC

---------------------------------------------------------------------------------------------------------
-- views for visualization

Create View GlobalCovidInfectionsAndDeaths AS
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL


CREATE VIEW DeathCountPerContinent 
AS
SELECT location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location


CREATE VIEW CountriesWithHighestInfectionRates
AS 
SELECT location, population, MAX(CAST(total_cases AS int)) as HighestInfectionCount,  MAX((CAST(total_cases AS int)/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, population


CREATE VIEW InfectionRatesOverTime
AS
SELECT location, population, date, MAX(CAST(total_cases AS int)) as HighestInfectionCount,  MAX((CAST(total_cases AS int)/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsMod
WHERE continent IS NOT NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, population, date


CREATE VIEW  PercentPopulationVaccinated 
AS 
SELECT cd.continent, cd.location, cd.date, cd.population, CAST(cv.new_vaccinations AS bigint) AS new_vaccinations, 
SUM(CONVERT(BIGINT, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location 
		  ORDER BY cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsMod cd
JOIN PortfolioProject..CovidVaccinationsMod cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
AND cd.location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')


CREATE VIEW PercentFullyVaccinated
AS
SELECT cd.location, (MAX(CAST(cv.people_fully_vaccinated AS BIGINT))/cd.population)*100 AS PercentageFullyVaccinated
FROM PortfolioProject..CovidDeathsMod cd
JOIN PortfolioProject..CovidVaccinationsMod cv
ON cd.location = cv.location
AND cd.date = cv.date
GROUP BY cd.location, cd.population



