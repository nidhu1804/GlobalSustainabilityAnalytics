-- QUERY: Peak Population and Resource Use Analysis (One Row per Country)
-- Research Question: How does peak population growth correlate with max resource use since 2010?

WITH population_resource_analysis AS (
    SELECT 
        c.country_name,
        c.region,
        c.income_level,
        -- Peak population indicators
        MAX(CASE WHEN i.indicator_code = 'SP.POP.GROW' THEN f.indicator_value END) AS max_pop_growth_rate,
        MAX(CASE WHEN i.indicator_code = 'SP.POP.TOTL' THEN f.indicator_value END) AS max_total_population,
        -- Peak resource usage indicators
        MAX(CASE WHEN i.indicator_code = 'ER.H2O.FWTL.K3' THEN f.indicator_value END) AS max_freshwater_withdrawals_bcm,
        MAX(CASE WHEN i.indicator_code = 'EG.FEC.RNEW.ZS' THEN f.indicator_value END) AS max_renewable_energy_percent,
        MAX(CASE WHEN i.indicator_code = 'EG.USE.COMM.FO.ZS' THEN f.indicator_value END) AS max_fossil_fuel_energy_percent
    FROM fact_sustainability f
        JOIN dim_country c ON f.country_code = c.country_code
        JOIN dim_time t ON f.year = t.year
        JOIN dim_indicator i ON f.indicator_code = i.indicator_code
    WHERE f.year >= 2010
        AND i.indicator_code IN (
            'SP.POP.GROW', 'SP.POP.TOTL',
            'ER.H2O.FWTL.K3', 'EG.FEC.RNEW.ZS', 'EG.USE.COMM.FO.ZS'
        )
    GROUP BY c.country_name, c.region, c.income_level
    HAVING COUNT(CASE WHEN f.indicator_value IS NOT NULL THEN 1 END) >= 3
)

SELECT *,
    -- Classify population pressure
    CASE 
        WHEN max_pop_growth_rate > 2 AND max_total_population > 100000000 THEN 'High Pressure'
        WHEN max_pop_growth_rate > 1 AND max_total_population > 50000000 THEN 'Medium Pressure'
        ELSE 'Low Pressure'
    END AS population_pressure_level,

    -- Classify energy stress
    CASE 
        WHEN max_fossil_fuel_energy_percent > 70 AND max_renewable_energy_percent < 20 THEN 'High Stress'
        WHEN max_fossil_fuel_energy_percent > 50 AND max_renewable_energy_percent < 30 THEN 'Medium Stress'
        ELSE 'Low Stress'
    END AS energy_use_stress
FROM population_resource_analysis
WHERE max_pop_growth_rate IS NOT NULL 
    AND (max_freshwater_withdrawals_bcm IS NOT NULL OR max_fossil_fuel_energy_percent IS NOT NULL)
ORDER BY max_pop_growth_rate DESC, max_total_population DESC;
