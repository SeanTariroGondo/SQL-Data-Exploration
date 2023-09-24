/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables (Global and Local), Windows Functions, 
Aggregate Functions, Creating Views, 
Converting Data Types, Group functions

*/

select * from [Covid19].[dbo].[Tbl_Covid_Deaths]
select * from [Covid19].[dbo].[Tbl_Covid_Vaccinations]

Select *
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, isnull(total_deaths,0) as total_deaths, population
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in my country

Select Location, date, isnull(total_cases,0) as total_cases,isnull(total_deaths,0) as total_deaths, 
(isnull(total_deaths,0)/isnull(total_cases,0))*100 as DeathPercentage
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where location like '%Zimba%'
and continent is not null 
order by 1,2

-- Group Functions  AVG, COUNT, MAX, MIN and SUM

Select AVG(TOTAL_CASES) AS AVG_TotalCases,COUNT(TOTAL_CASES) AS COUNT_TotalCases,MAX(TOTAL_CASES) AS MAX_TotalCases,
MIN(TOTAL_CASES) AS MIN_TotalCases,SUM(TOTAL_CASES) AS SUM_TotalCases
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where location like '%Zimba%'
and continent is not null 

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, isnull(total_cases,0) as total_cases,  (isnull(total_cases,0)/population)*100 as PercentPopulationInfected
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where location like '%Zimba%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(isnull(total_cases,0)) as HighestInfectionCount,  Max((isnull(total_cases,0)/population))*100 as PercentPopulationInfected
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(isnull(total_cases,0) as int)) as TotalDeathCount
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(isnull(total_cases,0) as int)) as TotalDeathCount
From [Covid19].[dbo].[Tbl_Covid_Deaths]
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Covid19].[dbo].[Tbl_Covid_Deaths]
where continent is not null 
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select a.continent, a.location, a.date, a.population, isnull(b.new_vaccinations,0) as new_vaccinations
, SUM(CONVERT(int,isnull(b.new_vaccinations,0))) OVER (Partition by a.Location Order by b.location, a.Date) as RollingPeopleVaccinated
From [Covid19].[dbo].[Tbl_Covid_Deaths] a
Join [Covid19].[dbo].[Tbl_Covid_Vaccinations] b
	On a.location = b.location
	and a.date = b.date
where a.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select a.continent, a.location, a.date, a.population, isnull(b.new_vaccinations,0)
, SUM(CONVERT(int,isnull(b.new_vaccinations,0))) OVER (Partition by a.Location Order by a.location, a.Date) as RollingPeopleVaccinated
From [Covid19].[dbo].[Tbl_Covid_Deaths] a
Join [Covid19].[dbo].[Tbl_Covid_Vaccinations] b
	On a.location = b.location
	and a.date = b.date
where a.continent is not null 

)
Select *, (isnull(RollingPeopleVaccinated,0)/Population)*100 as VaccinatedoverPopulation
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query
--Local
DROP Table if exists #Tmp_PercentPopulationVaccinated
Create Table #Tmp_PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #Tmp_PercentPopulationVaccinated
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(int,b.new_vaccinations)) OVER (Partition by a.Location Order by a.location, a.Date) as RollingPeopleVaccinated
From [Covid19].[dbo].[Tbl_Covid_Deaths] a
Join [Covid19].[dbo].[Tbl_Covid_Vaccinations] b
	On a.location = b.location
	and a.date = b.date


Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedoverPopulation
From #Tmp_PercentPopulationVaccinated

--Global

DROP Table if exists ##Tmp_PercentPopulationVaccinated
Create Table ##Tmp_PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into ##Tmp_PercentPopulationVaccinated
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(int,b.new_vaccinations)) OVER (Partition by a.Location Order by a.location, a.Date) as RollingPeopleVaccinated
From [Covid19].[dbo].[Tbl_Covid_Deaths] a
Join [Covid19].[dbo].[Tbl_Covid_Vaccinations] b
	On a.location = b.location
	and a.date = b.date


Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedoverPopulation
From ##Tmp_PercentPopulationVaccinated


-- Creating View to store data for later visualizations

IF EXISTS ( SELECT * FROM sys.objects where name = 'VW_PercentPopulationVaccinated' and type = 'V')
BEGIN
PRINT 'VW_PercentPopulationVaccinated, already exists within database, Dropping View and recreating New View'
DROP View if exists VW_PercentPopulationVaccinated
END
ELSE
BEGIN
EXECUTE(
'Create View VW_PercentPopulationVaccinated as
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(int,b.new_vaccinations)) OVER (Partition by a.Location Order by a.location, a.Date) as RollingPeopleVaccinated
From [Covid19].[dbo].[Tbl_Covid_Deaths] a
Join [Covid19].[dbo].[Tbl_Covid_Vaccinations] b
	On a.location = b.location
	and a.date = b.date
where a.continent is not null '
)
END

Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedoverPopulation
From VW_PercentPopulationVaccinated