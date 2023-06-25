/* Autor: Erika Danková */
/*  Tvorba sekundárnej tabuľky - pro dodatečná data o dalších evropských státech s HDP, GINI koeficientem a populací dalších evropských států ve stejném období, jako primární přehled pro ČR*/

CREATE OR REPLACE TABLE t_erika_dankova_project_SQL_secondary_final AS
	SELECT `year`, country, GDP, population, GDP/population AS GDP_per_capita, gini
	FROM economies
	WHERE country IN (
			SELECT country
			FROM countries
			WHERE continent = "Europe"
			)
		AND `year` BETWEEN 2006 AND 2018
	ORDER BY `year`, country;
	
SELECT *
FROM t_erika_dankova_project_SQL_secondary_final;