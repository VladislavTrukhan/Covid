
-- All Covid Deaths data

select *
from [Covid Project]..CovidDeaths
order by [Covid Project]..CovidDeaths.location


-- Altering Date column type from datetime to date

alter table [Covid Project]..CovidDeaths alter column date date


-- Looking at Total cases vs Total deaths

select location, date, total_cases, total_deaths, round((total_deaths / total_cases)*100, 2) as death_percentage
from [Covid Project]..CovidDeaths
where location = 'Algeria'
order by 1, 2


-- Creating Procedure for Looking at Total cases vs Total deaths for a specific Country

drop procedure if exists Covid_Country

create procedure Covid_Country
@location nvarchar(255)
as
select location, date, total_cases, total_deaths, round((total_deaths / total_cases)*100, 2) as death_percentage
from [Covid Project]..CovidDeaths
where location = @location
order by 1, 2

exec Covid_Country @location = 'Belgium'


-- Total cases vs Total deaths by Country

alter table [Covid Project]..CovidDeaths alter column total_deaths bigint

select location, max(total_cases) as Cases, max(total_deaths) as Deaths, max(total_deaths) / max(total_cases)*100 as DeathPercentage
from [Covid Project]..CovidDeaths
group by location
order by 1


-- DeathPercentage by Country compared with Worlwide DeathPercentage using Subqueries

select location, max(total_cases) as Cases, max(total_deaths) as Deaths, max(total_deaths) / max(total_cases)*100 as DeathPercentage,
(select max(total_deaths) / max(total_cases)*100 from [Covid Project]..CovidDeaths 
where location = 'World') as WW_DeathPercentage
from [Covid Project]..CovidDeaths
group by location
order by 1


-- Top-10 Countries with highest Death count per Population

select top 10 location, max(total_deaths) as TotalDeathCount
from [Covid Project]..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


-- Death count by Continent

select location, max(total_deaths) as TotalDeathCount
from [Covid Project]..CovidDeaths
where location not like '%income%' and location not like 'European Union' and continent is null and location not like 'World' and location not like 'International'
group by location
order by TotalDeathCount desc


-- Total cases vs Population by Date

select location, date, total_cases, population, total_deaths, (total_cases/population)*100 as PercentPopulationInfected
from [Covid Project]..CovidDeaths
order by 1, 2


-- Countries with highest infection rates per Population

select location, population, max(total_cases) as InfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from [Covid Project]..CovidDeaths
group by location, population
order by PercentPopulationInfected desc


-- % of Population Vaccinated over time

alter table [Covid Project]..CovidVaccinations alter column new_vaccinations bigint

select d.location, d.date, d.population, v.new_vaccinations,
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as PeopleVaccinated,
(sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date))/d.population*100 as PercentPeopleVaccinated
from [Covid Project]..CovidDeaths d
join [Covid Project]..CovidVaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null
order by 1,2


-- The same (% of Population Vaccinated over time) using CTE

with PeopVacc (location, date, population, new_vaccinations, PeopleVaccinated)
as
(
select d.location, d.date, d.population, v.new_vaccinations,
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
from [Covid Project]..CovidDeaths d
join [Covid Project]..CovidVaccinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null
)
select *, (PeopleVaccinated/population)*100 as PercentPeopleVaccinated
from PeopVacc
