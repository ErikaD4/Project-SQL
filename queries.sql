/* Otázka č.1 - 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? */

/* tento príkaz vypíše top 5 perc. poklesov - konkrétny rok a odvetvie*/
SELECT DISTINCT `year`, industry_branch_code, IB_name, AVG_wage, AVG_wage_prev, YoY_change_wage
FROM t_erika_dankova_project_sql_primary_final
WHERE YoY_change_wage < 0
ORDER BY YoY_change_wage
LIMIT 5; 

/* príkaz vypíše počet odvetví v ktorých došlo k medziročným poklesom a nárastom za jednotlivé roky a taktiež celkovú hodnotu zmeny za rok*/
WITH tab_1 AS (
	SELECT DISTINCT `year`, industry_branch_code, IB_name, AVG_wage, AVG_wage_prev, YoY_change_wage, AVG_wage - AVG_wage_prev AS difference
	FROM t_erika_dankova_project_sql_primary_final
	ORDER BY YoY_change_wage)

SELECT `year`, 
	SUM(CASE
			WHEN difference < 0 THEN 1 
			ELSE 0
		END) AS count_decrease,
	SUM(CASE
			WHEN difference > 0 THEN 1 
			ELSE 0
		END) AS count_increase, 
		sum(difference) AS difference
FROM tab_1
WHERE difference IS NOT NULL 
GROUP BY `year`
ORDER BY `year` ;

/* Otázka č.2 - 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd? */

SELECT `year`, category_code, name, AVG_price, FLOOR(avg(AVG_wage)) AS AVG_wage, FLOOR(avg(AVG_wage)/AVG_price) AS quantity_available
FROM t_erika_dankova_project_sql_primary_final
WHERE `year` IN (2006,2018)
	AND category_code IN (111301,114201)
GROUP BY `year`, category_code
ORDER BY category_code, `year`;


/* Otázka č.3 - 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? */

/* TOP 5 - najnižšia medziročná zmena */
SELECT DISTINCT `year`, category_code, name, AVG_price, AVG_price_prev, YoY_change_price
FROM t_erika_dankova_project_sql_primary_final
WHERE YoY_change_price IS NOT NULL
ORDER BY YoY_change_price
LIMIT 5;

/* TOP 5 - najnižšia KLADNÁ medziročná zmena */
SELECT DISTINCT `year`, category_code, name, AVG_price, AVG_price_prev, YoY_change_price
FROM t_erika_dankova_project_sql_primary_final
WHERE YoY_change_price > 0
ORDER BY YoY_change_price
LIMIT 5;


/* porovnanie roku 2018 a 2006 */
SELECT DISTINCT t1.`year` AS first_year, t2.`year` AS last_year, t1.category_code, t1.name, t1.AVG_price AS AVG_price_2006, t2.AVG_price AS AVG_price_2018, round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2) AS price_change
FROM t_erika_dankova_project_sql_primary_final AS t1
LEFT JOIN t_erika_dankova_project_sql_primary_final AS t2
	ON t1.`year` = t2.`year` - 12
		AND t1.category_code = t2.category_code
WHERE t1.`year` = 2006
ORDER BY round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2);

/* TOP 5 - najnižšia zmena 2006 vs 2018 */
SELECT DISTINCT t1.`year` AS first_year, t2.`year` AS last_year, t1.category_code, t1.name, t1.AVG_price AS AVG_price_2006, t2.AVG_price AS AVG_price_2018, round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2) AS price_change
FROM t_erika_dankova_project_sql_primary_final AS t1
LEFT JOIN t_erika_dankova_project_sql_primary_final AS t2
	ON t1.`year` = t2.`year` - 12
		AND t1.category_code = t2.category_code
WHERE t1.`year` = 2006
ORDER BY round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2)
LIMIT 5;

/* TOP 5 - najnižšia KLLADNÁ zmena 2006 vs 2018 */

SELECT DISTINCT t1.`year` AS first_year, t2.`year` AS last_year, t1.category_code, t1.name, t1.AVG_price AS AVG_price_2006, t2.AVG_price AS AVG_price_2018, round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2) AS price_change
FROM t_erika_dankova_project_sql_primary_final AS t1
LEFT JOIN t_erika_dankova_project_sql_primary_final AS t2
	ON t1.`year` = t2.`year` - 12
		AND t1.category_code = t2.category_code
WHERE t1.`year` = 2006 
	AND round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2) > 0
ORDER BY round((t2.AVG_price-t1.AVG_price)/t1.AVG_price*100,2)
LIMIT 5;

/* Otázka č.4 - 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? */

WITH t1 AS (
	WITH t2 AS (
		SELECT `year`, round(avg(AVG_wage),2) AS AVG_wage, round(avg(AVG_price),2) AS AVG_price
		FROM t_erika_dankova_project_sql_primary_final
		GROUP BY `year`
		)
		SELECT `year`, AVG_wage, 
			LAG(AVG_wage,1) OVER (ORDER BY `year` ASC) AS AVG_wage_prev,
			AVG_price,
			LAG(AVG_price,1) OVER (ORDER BY `year` ASC) AS AVG_price_prev
		FROM t2
		)
		SELECT `year`, AVG_wage_prev, AVG_wage, 
			round((AVG_wage - AVG_wage_prev)/AVG_wage_prev*100,2) AS YoY_change_wage,
			AVG_price_prev, AVG_price,
			round((AVG_price - AVG_price_prev)/AVG_price_prev*100,2) AS YoY_change_price,
			round((AVG_price - AVG_price_prev)/AVG_price_prev*100,2) - round((AVG_wage - AVG_wage_prev)/AVG_wage_prev*100,2) AS diff_YoY_change
		FROM t1
		WHERE AVG_wage_prev IS NOT NULL
		ORDER BY round((AVG_price - AVG_price_prev)/AVG_price_prev*100,2) - round((AVG_wage - AVG_wage_prev)/AVG_wage_prev*100,2) DESC
		;
	

/* Otázka č.5 - 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? */
	

WITH t1 AS (
	WITH t2 AS (
		SELECT `year`, round(avg(AVG_wage),2) AS AVG_wage, round(avg(AVG_price),2) AS AVG_price, GDP_per_capita_prev, GDP_per_capita_act, YoY_change_GDP 
		FROM t_erika_dankova_project_sql_primary_final
		GROUP BY `year`
		)
		SELECT `year`, 
			LAG(AVG_wage,1) OVER (ORDER BY `year` ASC) AS AVG_wage_prev,
			AVG_wage,
			LAG(AVG_price,1) OVER (ORDER BY `year` ASC) AS AVG_price_prev,
			AVG_price, GDP_per_capita_prev, GDP_per_capita_act, YoY_change_GDP
		FROM t2
		)
		SELECT `year`, AVG_wage_prev, AVG_wage,
		round((AVG_wage - AVG_wage_prev)/AVG_wage_prev*100,2) AS YoY_change_wage,
		AVG_price_prev, AVG_price,
		round((AVG_price - AVG_price_prev)/AVG_price_prev*100,2) AS YoY_change_price,
		GDP_per_capita_prev, GDP_per_capita_act, YoY_change_GDP
		FROM t1
		WHERE `year` != 2006;