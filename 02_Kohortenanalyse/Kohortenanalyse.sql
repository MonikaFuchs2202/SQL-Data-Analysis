# MySQL: Analyse der Retention Rate bei Versicherungsverträgen mit Abschluss in den Jahren 2020 bis 2023
# Quelle des Datasets: Zufallsgenerierte Tabelle (via Excel)
# Analysen in Anlehnung an Kapitel 4 SQL for Data Analysis von Cathy Tanimura 

-- 1. Auswahl des Betrachtungszeitraums 
SELECT 
ROUND(AVG(DATEDIFF(contract_end, contract_start) / 12), 0) AS avg_duration
FROM versicherungsverträge;

-- 2. Kohortenerstellung und -berechnung
-- Fragestellung: Wie verhält sich die Retention bei den einzelnen Kohorten nach 0 - 30 Monaten? 
-- CTE 2.1. Generierung des Betrachtungszeitraums (auf Basis vorheriger Analyse: 30 Monate pro Kohorte)
WITH RECURSIVE months AS (
SELECT 0 AS month_number
UNION ALL
SELECT month_number + 1
FROM months
WHERE month_number + 1 < 31
),

-- CTE 2.2. Verträge mit Kohorten-Zuordnung nach Monat
kohortenbasis AS (
SELECT 
customer_id,
DATE_FORMAT(contract_start, '%Y-%m-01') AS cohort_month,
contract_start,
contract_end
FROM versicherungsverträge
),

-- CTE 2.3. Kohortengröße pro Monat (initial)
kohortengroesse AS (
SELECT 
cohort_month,
COUNT(*) AS kohorten_base
FROM kohortenbasis
GROUP BY cohort_month
),

-- CTE 2.4. Matrix aus Kohorte und Monat X mit aktiven Verträgen
kohortenmatrix AS (
SELECT 
k.cohort_month,
m.month_number,
COUNT(*) AS aktive_kunden
FROM kohortenbasis k
JOIN months m ON 
DATE_ADD(k.contract_start, INTERVAL m.month_number MONTH) <= COALESCE(k.contract_end, '2099-01-01')
GROUP BY k.cohort_month, m.month_number
)

-- Ergebnis zusammenführen
SELECT 
km.cohort_month,
km.month_number,
kg.kohorten_base,
km.aktive_kunden,
ROUND(km.aktive_kunden / kg.kohorten_base * 100, 2) AS retention_pct
FROM kohortenmatrix km
JOIN kohortengroesse kg ON km.cohort_month = kg.cohort_month
ORDER BY km.cohort_month, km.month_number;

-- 3. Kohortenerstellung und -berechnung - aggregierte Darstellung
-- Fragestellung: Wie hoch ist die Retetion über alle Kohorten hinweg durchschnittlich nach 0 - 30 Monaten? 
-- CTE 3.1. Generierung des Betrachtungszeitraums (auf Basis vorheriger Analyse: 30 Monate pro Kohorte) 
WITH RECURSIVE months AS (
SELECT 0 AS month_number
UNION ALL
SELECT month_number + 1
FROM months
WHERE month_number + 1 < 31
),

-- CTE 3.2. Verträge mit Kohorten-Zuordnung nach Monat
kohortenbasis AS (
SELECT 
customer_id,
DATE_FORMAT(contract_start, '%Y-%m-01') AS cohort_month,
contract_start,
contract_end
FROM versicherungsverträge
),

-- CTE 3.3. Kohortengröße pro Monat (initial)
kohortengroesse AS (
SELECT 
cohort_month,
COUNT(*) AS kohorten_base
FROM kohortenbasis
GROUP BY cohort_month
),

-- CTE 3.4. Matrix aus Kohorte und Monat X mit aktiven Verträgen
kohortenmatrix AS (
SELECT 
k.cohort_month,
m.month_number,
COUNT(*) AS aktive_kunden
FROM kohortenbasis k
JOIN months m ON 
DATE_ADD(k.contract_start, INTERVAL m.month_number MONTH) <= COALESCE(k.contract_end, '2099-01-01')
GROUP BY k.cohort_month, m.month_number
),

-- CTE 3.5. Ergebnis zusammenführen (auf Ebene der einzelnen Kohorten)
monatsergebnisse AS (
SELECT 
km.cohort_month,
km.month_number,
kg.kohorten_base,
km.aktive_kunden,
ROUND(km.aktive_kunden / kg.kohorten_base * 100, 2) AS retention_pct
FROM kohortenmatrix km
JOIN kohortengroesse kg ON km.cohort_month = kg.cohort_month
ORDER BY km.cohort_month, km.month_number) 

-- Zusammenführung Ergebnisse (aggregiert) 
SELECT 
cohort_month,
SUM(kohorten_base) AS total_kohorte,
SUM(aktive_kunden) AS total_aktive_kunden,
ROUND(SUM(aktive_kunden) / SUM(kohorten_base) * 100, 2) AS retention_pct
FROM monatsergebnisse
GROUP BY 1
ORDER BY 1;

