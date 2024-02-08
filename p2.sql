SELECT *
FROM prescriber;

SELECT *
FROM prescription;

--sum of all claims 36 million

SELECT *
FROM drug;

SELECT *
FROM zip_fips;

SELECT *
FROM population;

SELECT *
FROM overdose_deaths;

--1a Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, 
	SUM ( total_claim_count) AS sum_of_claims
FROM prescription
GROUP BY npi
ORDER BY sum_of_claims DESC
limit 1;

--npi 1881634483 claims 99707

--1b Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT  nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description,
	sum_of_claims
FROM prescriber
INNER JOIN 
	(SELECT npi, 
	SUM ( total_claim_count) AS sum_of_claims
	FROM prescription
	GROUP BY npi)
USING (npi)
ORDER BY sum_of_claims DESC
limit 1;

--Bruce Pendley Family Practice

--2a Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description,
	SUM(total_claim_count) AS all_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY specialty_description
ORDER BY all_claims DESC;

--Family Practice 9752347 claims

--2b Which specialty had the most total number of claims for opioids

SELECT specialty_description,
	sum(total_claim_count) AS sum_of_claims
FROM drug
	INNER JOIN prescription
	USING (drug_name)
	INNER JOIN prescriber
	USING (npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum_of_claims DESC;

--Nurse Practitioner 900845 claims

--**Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description,
	SUM (total_claim_count) AS sum_claims
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY specialty_description
HAVING SUM(TOTAL_CLAIM_COUNT) is null;

--There are 15 specialties

--**Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--3a Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, sum(total_drug_cost)
FROM prescription
	INNER JOIN drug
	USING (drug_name)
--WHERE generic_name ILIKE '%insulin%'
GROUP BY generic_name
ORDER BY sum DESC;

--Insulin Glargine, HUM REC ANLOG

--3b Which drug (generic_name) has the hightest total cost per day? 
--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name,
ROUND(total_drug_cost / total_day_supply, 2) AS cost_per_day
FROM prescription
	INNER JOIN drug
	USING (drug_name)
ORDER BY cost_per_day DESC;

--IMMUN GLOB GIGG GLY IGA OV50 cost 6 or 7 thousand per day

--4a For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
CASE 
WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither' END AS drug_type
FROM drug;

--4b Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, 
SUM(total_drug_cost)::money AS sum_of_cost
FROM prescription
INNER JOIN
	(SELECT drug_name,
	CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
	FROM drug)
USING (drug_name)
GROUP BY drug_type;

--More on opioid. 105 million

--5a How many CBSAs are in Tennessee? 
--**Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT DISTINCT(cbsa), state
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';

--Ten Core Based Statistical Areas

--5b Which cbsa has the largest combined population? 
--Which has the smallest? 
--Report the CBSA name and total population.

SELECT cbsaname, 
SUM(population) AS sum_of_pop
FROM cbsa
	INNER JOIN fips_county
	USING (fipscounty)
	INNER JOIN population
	USING (fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY sum_of_pop DESC;

--Nashville Statistical Area has largest population with 1.8 million
--Morristown Statistical Area has the smallest population  with 116 thousand

--Federal Information Processing Standard
--Each fips county code represents one county
--One CBSA can include more than one county

--5c What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
FROM population
INNER JOIN fips_county
USING (fipscounty)
EXCEPT 
SELECT county,
SUM(population) AS population
FROM cbsa
	INNER JOIN fips_county
	USING (fipscounty)
	INNER JOIN population
	USING (fipscounty)
WHERE state = 'TN'
GROUP BY county
ORDER BY population DESC;

--Sevier County

--53 TN counties not in a statistical area

--6a Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, SUM(total_claim_count) AS sum_claims
FROM prescription
GROUP BY drug_name
HAVING SUM(total_claim_count) >= 3000;

-- grand total per drug is 507 rows

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

--total_claim_count over 3000 is 9 rows

--6b For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

WITH claims_over_3000 AS (SELECT drug_name, 
						  SUM(total_claim_count) 
						  AS sum_claims
						  FROM prescription
						  GROUP BY drug_name
						  HAVING
						  SUM(total_claim_count)
						  >= 3000)
SELECT drug_name, sum_claims, opioid_drug_flag
FROM drug
INNER JOIN claims_over_3000
USING(drug_name);

--grand total -- 507 rows

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count > 3000;

--9 rows with 2 opioid -- Oxy and Hydrocodone

--6c Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name,
drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count > 3000;

--David Coffey and Bruce Pendley
--David Coffey in Oneida TN

--https://www.wbir.com/article/news/crime/dr-david-bruce-coffey-drug-crisis-sentenced-40-months-prison-scott-county/51-cb499b02-9780-4b9f-9056-1946251c10fe

--7 The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
RIGHT JOIN prescription
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';
--THIS has 35 rows so it must be not right

WITH nashville_pain AS (SELECT npi, nppes_provider_city, specialty_description
FROM prescriber
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'),

opioid_drugs AS (SELECT drug_name, opioid_drug_flag
FROM drug
WHERE opioid_drug_flag = 'Y')

SELECT npi, drug_name
FROM nashville_pain
CROSS JOIN opioid_drugs
ORDER BY npi;
--Two CTE cross joined to make 637 rows

--7b Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

	WITH nashville_pain AS (SELECT npi, nppes_provider_city, specialty_description
FROM prescriber
WHERE nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'),
opioid_drugs AS (SELECT drug_name, opioid_drug_flag
FROM drug
WHERE opioid_drug_flag = 'Y')
	SELECT npi, drug_name, total_claim_count
FROM nashville_pain
CROSS JOIN opioid_drugs
LEFT JOIN prescription
USING(npi, drug_name)
ORDER BY npi;
--637 rows, total_claim_count has nulls and numeric

--7c Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

	WITH nashville_pain AS (SELECT npi, nppes_provider_city, specialty_description
FROM prescriber
WHERE nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'),
opioid_drugs AS (SELECT drug_name, opioid_drug_flag
FROM drug
WHERE opioid_drug_flag = 'Y')
	SELECT npi, 
	drug_name, 
	COALESCE(total_claim_count,0)AS total_claims
FROM nashville_pain
CROSS JOIN opioid_drugs
LEFT JOIN prescription
USING(npi, drug_name)
ORDER BY total_claims DESC;

SELECT nppes_provider_first_name,
nppes_provider_last_org_name,
specialty_description
FROM prescriber
WHERE npi = 1457685976;

SELECT nppes_provider_city,
nppes_provider_state
FROM prescriber
WHERE npi = 1912011792;