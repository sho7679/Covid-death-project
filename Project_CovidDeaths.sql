SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT [location],[date],total_cases,new_cases,total_deaths,population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs. Total Deaths
-- Likelikhood of dying given you have COVID in the UK

SELECT [location],[date],total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2

-- Total Cases vs Population 
-- What percent of population got COVID in UK?

SELECT [location],[date],total_cases,population, (total_cases/population)*100 AS CasePercent
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2

-- What country has the highest infection rate per population?

SELECT [location],MAX(total_cases) AS HighestInfection,population, (MAX(total_cases)/population)*100 AS InfectionPercent
FROM CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercent DESC

-- What country has the highest death count per pop?

SELECT [location],MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Total death by continent 

SELECT location,MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS not NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continents with highest death count per pop

SELECT location,MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS not NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Lets look at the whole world
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercent
FROM CovidDeaths
WHERE continent IS not NULL 
ORDER BY 1,2

-- Total Pop vs Vaccinations
-- Percent of Population that got at least 1 vaccine 

SELECT dea.continent, dea.[location], dea.[date],dea.population,vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea 
JOIN CovidVaccinations vac 
    ON dea.location = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- CTE to perform calculation on partition in last query 

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Temp table to perform calculation on partition in last query

-- 1. make the table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

-- 2. query the table
INSERT INTO  #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Store data for Tableau later
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL