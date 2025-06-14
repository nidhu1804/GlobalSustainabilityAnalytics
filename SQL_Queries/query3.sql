--TOPIC 3: RENEWABLE ENERGY TRANSITION ANALYSIS
-- Research Question: Which countries are making the fastest progress in renewable energy adoption?

WITH energy_transition AS (
    SELECT 
        c.country_name,
        c.region,
        c.income_level,
        f.year,
        CASE WHEN i.indicator_code = 'EG.FEC.RNEW.ZS' THEN f.indicator_value END AS renewable_energy_pct,
        CASE WHEN i.indicator_code = 'EG.USE.COMM.FO.ZS' THEN f.indicator_value END AS fossil_fuel_pct,
        CASE WHEN i.indicator_code = 'EG.ELC.RNWX.ZS' THEN f.indicator_value END AS renewable_electricity_pct,
        CASE WHEN i.indicator_code = 'EG.ELC.FOSL.ZS' THEN f.indicator_value END AS fossil_electricity_pct
    FROM fact_sustainability f
    JOIN dim_country c ON f.country_code = c.country_code
    JOIN dim_time t ON f.year = t.year
    JOIN dim_indicator i ON f.indicator_code = i.indicator_code
    WHERE f.year >= 2010
    AND i.indicator_code IN ('EG.FEC.RNEW.ZS', 'EG.USE.COMM.FO.ZS', 'EG.ELC.RNWX.ZS', 'EG.ELC.FOSL.ZS')
),

energy_trends AS (
    SELECT 
        country_name,
        region,
        income_level,
        -- Latest values
        MAX(CASE WHEN year >= 2018 THEN renewable_energy_pct END) AS recent_renewable_pct,
        MAX(CASE WHEN year >= 2018 THEN fossil_fuel_pct END) AS recent_fossil_pct,
        MAX(CASE WHEN year >= 2018 THEN renewable_electricity_pct END) AS recent_renewable_elec_pct,
        -- Earlier values for trend calculation
        MAX(CASE WHEN year BETWEEN 2010 AND 2015 THEN renewable_energy_pct END) AS early_renewable_pct,
        MAX(CASE WHEN year BETWEEN 2010 AND 2015 THEN fossil_fuel_pct END) AS early_fossil_pct,
        MAX(CASE WHEN year BETWEEN 2010 AND 2015 THEN renewable_electricity_pct END) AS early_renewable_elec_pct
    FROM energy_transition
    GROUP BY country_name, region, income_level
    HAVING COUNT(CASE WHEN renewable_energy_pct IS NOT NULL OR fossil_fuel_pct IS NOT NULL THEN 1 END) >= 3
)

SELECT 
    *,
    -- Calculate transition trends (with proper type casting)
    ROUND((recent_renewable_pct - early_renewable_pct)::NUMERIC, 2) AS renewable_energy_change,
    ROUND((recent_fossil_pct - early_fossil_pct)::NUMERIC, 2) AS fossil_fuel_change,
    ROUND((recent_renewable_elec_pct - early_renewable_elec_pct)::NUMERIC, 2) AS renewable_electricity_change,
    
    -- Classify transition progress
    CASE 
        WHEN (recent_renewable_pct - early_renewable_pct) > 10 THEN 'Rapid Transition'
        WHEN (recent_renewable_pct - early_renewable_pct) > 5 THEN 'Fast Transition'
        WHEN (recent_renewable_pct - early_renewable_pct) > 2 THEN 'Moderate Transition'
        WHEN (recent_renewable_pct - early_renewable_pct) > 0 THEN 'Slow Transition'
        ELSE 'No Progress/Decline'
    END AS transition_category,
    
    -- Current renewable energy status
    CASE 
        WHEN recent_renewable_pct > 50 THEN 'Renewable Leader'
        WHEN recent_renewable_pct > 25 THEN 'Renewable Adopter'
        WHEN recent_renewable_pct > 10 THEN 'Renewable Starter'
        ELSE 'Fossil Dependent'
    END AS current_energy_status

FROM energy_trends
WHERE recent_renewable_pct IS NOT NULL 
AND early_renewable_pct IS NOT NULL
ORDER BY renewable_energy_change DESC;
