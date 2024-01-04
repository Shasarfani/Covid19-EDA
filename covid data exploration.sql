--This projects aims to explore the covid infection and vaccination data using sql functions.

--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


Use PortfolioProjects

Select *
From PortfolioProjects..['covid-data-death$']
order by 3,4 --selecting the data to view ordered by col 3 & 4


--Replacing the null observations in the continent col & updating it with the value in the location field. Also altering the table to create a new col named 'continent_updated'


ALTER TABLE dbo.['covid-data-death$']
ADD continent_updated1 VARCHAR(50); 

UPDATE dbo.['covid-data-death$']
SET continent_updated1=
    CASE 
        WHEN location = 'Asia' AND continent IS NULL THEN 'Asia'
        WHEN location = 'Africa' AND continent IS NULL THEN 'Africa'
        WHEN location = 'South America' AND continent IS NULL THEN 'South America'
		WHEN location = 'North America' AND continent IS NULL THEN 'North America'
		WHEN location = 'Europe' AND continent IS NULL THEN 'Europe'
		WHEN location = 'Oceania' AND continent IS NULL THEN 'Oceania'
        ELSE continent
    END;

select location, continent, continent_updated1
From PortfolioProjects..['covid-data-death$'] --reviweing the cols

--Looking at Total Cases vs the Total deaths

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From PortfolioProjects..['covid-data-death$']
order by 1,2


ALTER TABLE dbo.['covid-data-death$']
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE dbo.['covid-data-death$']
ALTER COLUMN total_cases FLOAT;

--Looking at Total Cases vs the Total deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From PortfolioProjects..['covid-data-death$']
where total_deaths IS NOT NULL
AND total_cases IS NOT NULL --death percentage gives us the % of infected people who died


--Looking at Total deaths vs the Population grouped by location

select
	location,
	MAX(population) AS population,
	MAX(total_deaths) AS total_deaths,
	(MAX(total_deaths)/population)*100 as death_percentage_population
From PortfolioProjects..['covid-data-death$']
where total_deaths IS NOT NULL
group by location, population
order by population;


--trying to create a new col with the total cases data

ALTER TABLE dbo.['covid-data-death$']
ADD overall_total_cases int

UPDATE dbo.['covid-data-death$']
SET overall_total_cases= (
select sum(cast(new_cases as float))
from dbo.['covid-data-death$'] --however, the total value is too big for the int datatype
--i tried bigint and float, i get the same error for arthematic overflow. surpring i guess that teh total cases of all the loctions is so huge.
)

--total deaths by location
select location, max(total_deaths) as total_death_count
from dbo.['covid-data-death$']
group by location
order by total_death_count desc


--total deaths by continent
select continent, max(total_deaths) as total_death_count
from dbo.['covid-data-death$']
group by continent
order by total_death_count desc

--total cases by continent & percentage
select continent, (max(new_cases)) / (sum(new_cases)) *1000  as percentage_case_count, sum(new_cases) as total_case_count
from dbo.['covid-data-death$']
group by continent
order by total_case_count desc


--Locations with highest infection rates compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as infection_percent
from PortfolioProjects..['covid-data-death$']
group by location, population
order by infection_percent desc

--Locations with highest death counts compared to population
select location, population, MAX(total_deaths) as HighestDeathCount, MAX(total_deaths/population)*100 as death_percent
from PortfolioProjects..['covid-data-death$']
where continent is not null
group by location, population
order by death_percent desc


--Continent with highest death counts compared to population
select continent_updated1, MAX(total_deaths) as HighestDeathCount
from PortfolioProjects..['covid-data-death$']
where continent_updated1 is not null
group by continent_updated1
order by HighestDeathCount desc


-- Global Numbers
--total death percentage
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProjects..['covid-data-death$']
order by 1,2

--total infected percentage
select sum(new_cases) as total_cases, SUM( DISTINCT population) as total_population, SUM(cast(new_cases as float))/SUM(DISTINCT population)*100 as infected_percentage
from PortfolioProjects..['covid-data-death$']
order by 1,2

select sum(new_cases) as total_cases
from PortfolioProjects..['covid-data-death$']
where new_cases is not null

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProjects..['covid-data-death$']
--Where location like '%states%'
order by 1,2

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
from PortfolioProjects..['covid-data-death$']

--joining the vaccination table

USE PortfolioProjects

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3


--addding rolling addition/count for the new vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where vac.new_vaccinations is not null
order by 1,2,3

--% of people that are vaccinated per population of the location
select dea.location, dea.population, SUM(vac.new_vaccinations / population)*100 as percent_population_vaccinated
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where vac.new_vaccinations is not null
group by dea.location, dea.population
order by 1,2,3


--Using CTE to get vaccination percentage
With pop_vac (continent, location, date, population, new_vaccinations, rolling_count_vaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
--, (rolling_count_vaccinations/population)*100
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3
)
select*, (rolling_count_vaccinations/population)*100
from pop_vac

--TEMP table

Create Table #Percentage_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count_vaccinations numeric
)

Insert into #Percentage_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
--, (rolling_count_vaccinations/population)*100
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 1,2,3

select*, (rolling_count_vaccinations/population)*100
from #Percentage_population_vaccinated


--Total infected per year/month grouped by location

select location, YEAR(date) as year, MONTH(date) as month, SUM(new_cases) as infectedcount
from PortfolioProjects..['covid-data-death$']
group by YEAR(date), MONTH(date), location
order by YEAR(date), MONTH(date)

--Total infected per year/month

select YEAR(date) as year, MONTH(date) as month, SUM(new_cases) as infectedcount
from PortfolioProjects..['covid-data-death$']
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

--Total infected per year/month
select YEAR(date) as year, MONTH(date) as month, SUM(new_cases) as infectedcount
from PortfolioProjects..['covid-data-death$']
where location like '%india%'
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

--Total death per year/month

select YEAR(date) as year, MONTH(date) as month, SUM(new_deaths) as death_count
from PortfolioProjects..['covid-data-death$']
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)


--Total vaccinated per year/month
select YEAR(date) as year, SUM(CAST(new_vaccinations as numeric)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
group by YEAR(date)

select YEAR(date) as year, MONTH(date) as month, SUM(CAST(new_vaccinations as numeric)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
where new_vaccinations is not null
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

select new_vaccinations, date, total_vaccinations
from PortfolioProjects..['covid-data-vaccination$']


Select YEAR(date) as year, MONTH(date) as month, MAX(CAST(new_vaccinations as numeric)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

Select YEAR(date) as year, MONTH(date) as month, MAX(CAST(total_vaccinations as numeric)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

--Lets take a look at vaccinated count in india
select YEAR(date) as year, MONTH(date) as month, SUM(CAST(new_vaccinations as int)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
where location like '%india%'
group by YEAR(date), MONTH(date)
order by YEAR(date), MONTH(date)

--total population vaccianted
select dea.location, dea.population, SUM(vac.new_vaccinations / population)*100 as percent_population_vaccinated
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where vac.new_vaccinations is not null
group by dea.location, dea.population

--creating view to store data for later visualizations

Create view total_vaccinated_india as
select YEAR(date) as year, MONTH(date) as month, SUM(CAST(new_vaccinations as int)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
where location like '%india%'
group by YEAR(date), MONTH(date)
--order by YEAR(date), MONTH(date)

create view total_vaccinated as
select YEAR(date) as year, MONTH(date) as month, SUM(CAST(new_vaccinations as float)) as vaccinated_count
from PortfolioProjects..['covid-data-vaccination$']
group by YEAR(date), MONTH(date)
--order by YEAR(date), MONTH(date)

create view total_infected1 as
select YEAR(date) as year, MONTH(date) as month, SUM(new_cases) as infectedcount
from PortfolioProjects..['covid-data-death$']
group by YEAR(date), MONTH(date)
--order by YEAR(date), MONTH(date)

create view total_infected_india as
select YEAR(date) as year, MONTH(date) as month, SUM(new_cases) as infectedcount
from PortfolioProjects..['covid-data-death$']
where location like '%india%'
group by YEAR(date), MONTH(date)
--order by YEAR(date), MONTH(date)

create view percent_population_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
--, (rolling_count_vaccinations/population)*100
from PortfolioProjects..['covid-data-death$'] dea
join PortfolioProjects..['covid-data-vaccination$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3

create view gloabl_death_count as
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProjects..['covid-data-death$']
where continent is not null
--order by 1,2

create view golbal_infected_percentage as
select sum(new_cases) as total_cases, SUM( DISTINCT population) as total_population, SUM(cast(new_cases as int))/SUM(DISTINCT population)*100 as infected_percentage
from PortfolioProjects..['covid-data-death$']
where continent is not null
--order by 1,2

create view highest_death_count_continent as
select continent_updated1, MAX(total_deaths) as HighestDeathCount
from PortfolioProjects..['covid-data-death$']
where continent_updated1 is not null
group by continent_updated1
--order by HighestDeathCount desc

create view high_death_count_location as
select location, population, MAX(total_deaths) as HighestDeathCount, MAX(total_deaths/population)*100 as death_percent
from PortfolioProjects..['covid-data-death$']
where continent is not null
group by location, population
--order by death_percent desc

create view infection_rate_location as
select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as infection_percent
from PortfolioProjects..['covid-data-death$']
group by location, population
--order by infection_percent desc

create view death_rate as
select YEAR(date) as year, MONTH(date) as month, SUM(new_deaths) as death_count
from PortfolioProjects..['covid-data-death$']
group by YEAR(date), MONTH(date)
--order by YEAR(date), MONTH(date)