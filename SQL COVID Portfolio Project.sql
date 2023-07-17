Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

--Select Data to be used

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

--Total Cases vs. Total Deaths
--Shows the likelihood of dying if you contract covid for a specific country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'Germany' 
and continent is not null
order by 1,2

-- Total Cases vs. Population
--Shows the percentage of the population that got Covid
Select Location, date, population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
--Where location = 'Germany'
and continent is not null
order by 1,2


--Countries with highest infection rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
--Where location = 'Germany'
Where continent is not null
Group by Location, population
Order by PercentPopulationInfected desc


--Showing countries with highest death count 
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

--Showing continents with highest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by TotalDeathCount desc


--Global numbers

Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
--group by date
order by 1,2

--Total population vs vaccinations
-- window function and CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(Convert(int, cv.new_vaccinations)) 
	OVER (Partition by cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/ cd.population)*100
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null
--order by 2, 3
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac

--Temp table
Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(Convert(int, cv.new_vaccinations)) 
	OVER (Partition by cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/ cd.population)*100
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null
Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(Convert(int, cv.new_vaccinations)) 
	OVER (Partition by cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/ cd.population)*100
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null

Select * 
From PercentPopulationVaccinated
