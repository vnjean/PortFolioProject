select *
From [PortfolioProject ]..CovidDeaths
where continent is not null
order by 3,4 

--select *
--From [PortfolioProject ]..CovidVaccinations
--order by 3,4 

-- Select Data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject ]..CovidDeaths
order by 1,2

-- Getting more info about my tables

EXEC sp_help '[PortfolioProject ]..CovidVaccinations';

EXEC sp_help '[PortfolioProject ]..CovidDeaths';

-- Change data type of total_cases and total_deaths to float
ALTER TABLE [PortfolioProject]..CovidDeaths
ALTER COLUMN total_cases float;

ALTER TABLE [PortfolioProject]..CovidDeaths
ALTER COLUMN total_deaths float;

ALTER TABLE [PortfolioProject]..CovidDeaths
ALTER COLUMN new_deaths float;

ALTER TABLE [PortfolioProject]..CovidVaccinations
ALTER COLUMN new_vaccinations float;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country 

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [PortfolioProject ]..CovidDeaths
Where location like '%tswana%'
and continent is not null
order by 1,2

-- Looking at Total Cases vs population
-- shows what percentage of population got Covid
Select Location, date, population,  total_cases,(total_cases/population)*100 as PercentPopulationInfected
From [PortfolioProject ]..CovidDeaths
-- Where location like '%tswana%'
where continent is not null
order by 1,2


-- Looking at Countries with Highest Infection Rate compared to population 
Select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From [PortfolioProject ]..CovidDeaths 
-- Where location like '%tswana%'
Group by location, population
where continent is not null
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population

Select location,  MAX(total_deaths) as TotalDeathCount
From [PortfolioProject ]..CovidDeaths 
-- Where location like '%tswana%'
where continent is not null
Group by location
order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- On the Fly
Select location, MAX(total_deaths) as TotalDeathCount
From [PortfolioProject ]..CovidDeaths 
-- Where location like '%tswana%'
where continent is null
Group by location
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continent with the highest death count per population

Select continent,  MAX(total_deaths) as TotalDeathCount
From [PortfolioProject ]..CovidDeaths 
-- Where location like '%tswana%'
where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentages
From [PortfolioProject ]..CovidDeaths
-- Where location like '%tswana%'
WHERE continent is not null
group by date
order by 1,2


SELECT
   -- date,
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) / SUM(new_cases) * 100
    END AS DeathPercentages
FROM
    [PortfolioProject ]..CovidDeaths
-- WHERE location LIKE '%tswana%'
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2


/*Join our Data together*/
select *
From [PortfolioProject ]..CovidDeaths as dea
Join [PortfolioProject ]..CovidVaccinations as vac
    On dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From [PortfolioProject ]..CovidDeaths as dea
Join [PortfolioProject ]..CovidVaccinations as vac
    On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Use CTE
with PopvsVac (Continent, Location, Date, Population, new_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location,
dea.date) as RollingPeopleVaccinated
From [PortfolioProject ]..CovidDeaths as dea
Join [PortfolioProject ]..CovidVaccinations as vac
    On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255), 
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location,
dea.date) as RollingPeopleVaccinated
From [PortfolioProject ]..CovidDeaths as dea
Join [PortfolioProject ]..CovidVaccinations as vac
    On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

Create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location,
dea.date) as RollingPeopleVaccinated
From [PortfolioProject ]..CovidDeaths as dea
Join [PortfolioProject ]..CovidVaccinations as vac
    On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select *
From PercentPopulationVaccinated