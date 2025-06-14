--TOPIC 2: ECONOMIC GROWTH VS ENVIRONMENTAL IMPACT:
-- Research Question: Do economically growing countries have higher environmental costs?

WITH economic_environmental_impact AS (
    SELECT 
        c.country_name,
        c.region,
        c.income_level,
        -- Aggregate all years 2010+ into one
        AVG(CASE WHEN i.indicator_code = 'NY.ADJ.NNTY.CD' THEN f.indicator_value END) AS adjusted_net_income,
        AVG(CASE WHEN i.indicator_code = 'NV.AGR.TOTL.KD.ZS' THEN f.indicator_value END) AS agriculture_percent_growth,
        AVG(CASE WHEN i.indicator_code = 'NY.ADJ.NNTY.KD.ZG' THEN f.indicator_value END) AS adjusted_income_growth,
        AVG(CASE WHEN i.indicator_code = 'EN.GHG.CO2.PC.CE.AR5' THEN f.indicator_value END) AS co2_per_capita,
        AVG(CASE WHEN i.indicator_code = 'EN.GHG.ALL.PC.CE.AR5' THEN f.indicator_value END) AS total_ghg_per_capita,
        AVG(CASE WHEN i.indicator_code = 'ER.H2O.FWTL.ZS' THEN f.indicator_value END) AS water_withdrawal_percent
    FROM fact_sustainability f
    JOIN dim_country c ON f.country_code = c.country_code
    JOIN dim_time t ON f.year = t.year
    JOIN dim_indicator i ON f.indicator_code = i.indicator_code
    WHERE f.year >= 2010
      AND i.indicator_code IN (
          'NY.ADJ.NNTY.CD', 'NV.AGR.TOTL.KD.ZS', 'NY.ADJ.NNTY.KD.ZG',
          'EN.GHG.CO2.PC.CE.AR5', 'EN.GHG.ALL.PC.CE.AR5', 'ER.H2O.FWTL.ZS'
      )
    GROUP BY c.country_name, c.region, c.income_level
)
SELECT *,
    CASE 
        WHEN adjusted_income_growth > 4 AND (
            co2_per_capita > 10 OR total_ghg_per_capita > 10 OR water_withdrawal_percent > 25
        ) THEN 'High Growth, High Impact'
        WHEN adjusted_income_growth > 4 THEN 'High Growth, Low Impact'
        WHEN co2_per_capita > 10 OR total_ghg_per_capita > 10 OR water_withdrawal_percent > 25 THEN 'Low Growth, High Impact'
        ELSE 'Low Growth, Low Impact'
    END AS growth_impact_category
FROM economic_environmental_impact
WHERE adjusted_income_growth IS NOT NULL
ORDER BY adjusted_income_growth DESC, co2_per_capita DESC;
