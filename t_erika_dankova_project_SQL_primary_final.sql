/* Autor: Erika Danková */
/* Discord: Erika D.#1312 */

/* Tvorba finálnej tabuľky - pro data mezd a cen potravin za Českou republiku sjednocených na totožné porovnatelné období – společné roky */ */

CREATE OR REPLACE TABLE t_erika_dankova_project_SQL_primary_final AS (
	WITH tab_payroll_final AS ( /* tab. miezd */
			WITH tab_payroll AS (
				SELECT t1.payroll_year, t1.industry_branch_code, t2.name AS IB_name, round(avg(t1.value),2) AS AVG_wage  
				FROM czechia_payroll AS t1
				LEFT JOIN czechia_payroll_industry_branch AS t2
					ON t1.industry_branch_code = t2.code
				WHERE t1.value_type_code = 5958 /* Průměrná hrubá mzda na zaměstnance */
					AND t1.calculation_code = 200 /* přepočtené počty */
					AND t1.payroll_year BETWEEN 2006 AND 2018 /* v primárnej tabuľke czechia_price sú záznamy dostupné len pre tieto roky */
					AND t1.industry_branch_code IS NOT NULL /* nulové hodnoty predstavujú priemer za všetky odvedvia */
				GROUP BY t1.payroll_year, t1.industry_branch_code
				)
			
				SELECT t1.*, t2.AVG_wage AS AVG_wage_prev, round((t1.AVG_wage - t2.AVG_wage)/t2.AVG_wage *100,2) AS YoY_change_wage
				FROM tab_payroll AS t1
				LEFT JOIN tab_payroll AS t2
					ON t1.payroll_year = t2.payroll_year + 1 /* pridávam medziročnú zmenu miezd na úrovni ekon. činností (industry branch) */
						AND t1.industry_branch_code = t2.industry_branch_code
			),
		
		tab_price_final AS ( /* tab. cien potravín */
			WITH tab_price AS(
				SELECT YEAR(t1.date_from) AS `year`, t1.category_code, t2.name, round(avg(t1.value),2) AS AVG_price
				FROM czechia_price AS t1
				LEFT JOIN czechia_price_category AS t2
					ON t1.category_code = t2.code
				WHERE t1.region_code IS NULL /* priemerná hodnota za všetky kraje */
					AND t1.category_code != 212101 /* vylúčenie - Jakostní víno bílé, údaje dostupné len za 2015-2018 */
				GROUP BY YEAR(t1.date_from), t1.category_code
				)
				
				SELECT t1.*, t2.AVG_price AS AVG_price_prev, round((t1.AVG_price - t2.AVG_price)/t2.AVG_price *100,2) AS YoY_change_price
				FROM tab_price AS t1
				LEFT JOIN tab_price AS t2
				ON t1.`year` = t2.`year`+ 1 /* pridávam medziročnú zmenu cien na úrovni produktu */
					AND t1.category_code = t2.category_code
			),
		
		GDPPP_CZ AS ( /* do primárnej tab. pripájam aj tab. economies z dovodu zodpovedania Otázky č.5 */
			
			SELECT t1.`year`, round(t2.GDP/t2.population,2) AS GDP_per_capita_prev, round(t1.GDP/t1.population,2) AS GDP_per_capita_act,
				round((round(t1.GDP/t1.population,2) - round(t2.GDP/t2.population,2))/round(t2.GDP/t2.population,2)*100,2) AS YoY_change_GDP
			FROM economies AS t1
			LEFT JOIN economies AS t2
				ON t1.country = t2.country 
					AND t1.`year` = t2.`year` + 1 /* pridávam medziročnú zmenu GDP na obyvateľa */
			WHERE t1.country = "Czech Republic"
				AND t1.`year` BETWEEN 2006 AND 2018 /* zjednotenie obdobia s tab. cien a miezd */
			ORDER BY t1.`year` ASC
			)
		/* finálne spojenie 3 tabuliek - miezd, cien potravín a economies */
		SELECT t1.*, t2.industry_branch_code, t2.IB_name, t2.AVG_wage, t2.AVG_wage_prev, t2.YoY_change_wage, t3.GDP_per_capita_prev, t3.GDP_per_capita_act, t3.YoY_change_GDP  
		FROM tab_price_final AS t1
		JOIN tab_payroll_final AS t2 
			ON t1.`year`= t2.payroll_year
		JOIN GDPPP_CZ AS t3
			ON t1.`year` = t3.`year`
		ORDER BY t1.`year`, t1.category_code, t2.industry_branch_code
		);
		
	SELECT *
	FROM t_erika_dankova_project_sql_primary_final;
