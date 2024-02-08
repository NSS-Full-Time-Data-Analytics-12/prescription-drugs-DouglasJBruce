SELECT *
FROM prescriber;

--1 How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT count(npi)
FROM (
SELECT npi
FROM prescriber 
EXCEPT
SELECT npi
FROM prescription )

--4458

--2a Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT specialty_description, 
count(drug_name)
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY specialty_description
--92 specialties

SELECT
specialty_description,
generic_name,
sum(total_claim_count) AS sum_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
GROUP BY specialty_description,
generic_name
ORDER BY sum_claims DESC
limit 5;
-- Family and Internal - Levo Sodium, 
--Nurse Prac - Hydrocodone,
--Internal - Amplodipine, 
--Internal - Atorvastatin,

SELECT
specialty_description,
generic_name,
sum(total_claim_count) AS sum_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description =
'Family Practice'
GROUP BY specialty_description,
generic_name
ORDER BY sum_claims DESC
limit 5;

--Levothyroxine, Lisinopril, Atorvastatin, Amlodipine, Omeprazole

--2b Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT
specialty_description,
generic_name,
sum(total_claim_count) AS sum_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description =
'Cardiology'
GROUP BY specialty_description,
generic_name
ORDER BY sum_claims DESC
limit 5;

--Atorvastatin, Carvedilol, Metoprolol, Clopidogrel, Amlodipine

--2c Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

( SELECT
specialty_description,
generic_name,
sum(total_claim_count) AS sum_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description =
'Family Practice'
GROUP BY specialty_description,
generic_name
ORDER BY sum_claims DESC
limit 5 )
UNION
( SELECT
specialty_description,
generic_name,
sum(total_claim_count) AS sum_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description =
'Cardiology'
GROUP BY specialty_description,
generic_name
ORDER BY sum_claims DESC
limit 5 )

--3 Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

--3a First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi, 
nppes_provider_city,
sum(total_claim_count) As sum_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city =
'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY sum_claims DESC
limit 5

--I have a total 20,592 rows of npi and sum claims

( SELECT npi, 
nppes_provider_city,
sum(total_claim_count) As sum_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city =
'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY sum_claims DESC
limit 5)
UNION 
( SELECT npi, 
nppes_provider_city,
sum(total_claim_count) As sum_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city =
'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY sum_claims DESC
limit 5)
UNION
( SELECT npi, 
nppes_provider_city,
sum(total_claim_count) As sum_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city =
'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY sum_claims DESC
limit 5)
UNION
( SELECT npi, 
nppes_provider_city,
sum(total_claim_count) As sum_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city =
'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY sum_claims DESC
limit 5)

--4 Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT AVG(overdose_deaths)
FROM overdose_deaths
--average overdose deaths is 12.6

SELECT county, year, overdose_deaths
FROM overdose_deaths
INNER JOIN fips_county
ON overdose_deaths.fipscounty = fips_county.fipscounty::int
WHERE overdose_deaths >
	(SELECT
	 AVG(overdose_deaths)
	 FROM overdose_deaths)
	 
--5a Write a query that finds the total population of Tennessee

SELECT SUM (population) AS state_pop
FROM population

--5b Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, 
	population,
	ROUND(population / 
	(SELECT SUM (population) AS state_pop
	FROM population),3)*100 AS percent_of_TN
FROM fips_county
INNER JOIN population
USING (fipscounty)
ORDER BY percent_of_TN DESC