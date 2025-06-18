# MySQL: Analyse deutscher Außenhandel auf Monatsbasis (2008 - 2024)
# Quelle des Datasets: Statistisches Bundesamt 
# Analysen in Anlehnung an Kapitel 3 SQL for Data Analysis von Cathy Tanimura 

-- 1. Entwicklung Kfz und Landmaschinen auf Monatsbasis
SELECT 
Datum,
Export,
Import,
Handelsbilanz
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
ORDER BY Datum ASC;

-- 2. Entwicklung Handelsbilanz Kfz, Elektrotechnische Erzeugnisse und Maschinen auf Jahresbasis
SELECT 
YEAR(Datum) AS Jahr,
Warenbezeichnung,
SUM(Handelsbilanz) AS Handelsbilanz
FROM handelsbilanz
WHERE Warenbezeichnung IN ('Kraftfahrzeuge, Landfahrzeuge', 'Elektrotechnische Erzeugnisse', 'Maschinen, Apparate, mechanische Geräte')
GROUP BY 1,2 
ORDER BY 1,2;

-- 3. Pivotisierte Darstellung des vorherigen Querys mit Waren-ID als Spaltenbezeichnung
SELECT 
YEAR(Datum) AS JAHR,
SUM(CASE WHEN Warenbezeichnung = 'Elektrotechnische Erzeugnisse' THEN Handelsbilanz END) AS WA85,
SUM(CASE WHEN Warenbezeichnung = 'Maschinen, Apparate, mechanische Geräte' THEN Handelsbilanz END) AS WA84,
SUM(CASE WHEN Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge' THEN Handelsbilanz END) AS WA87
FROM handelsbilanz
WHERE Warenbezeichnung IN ('Elektrotechnische Erzeugnisse', 'Maschinen, Apparate, mechanische Geräte', 'Kraftfahrzeuge, Landfahrzeuge')
GROUP BY 1 
ORDER BY 1;

-- 4. Verhältnis zwischen Handelsbilanz Kfz und Elektrotechnische Erzeugnisse
WITH cte AS (
SELECT
YEAR(Datum) AS Jahr,
SUM(CASE WHEN Warenbezeichnung = 'Elektrotechnische Erzeugnisse' THEN Handelsbilanz END) AS WA85,
SUM(CASE WHEN Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge' THEN Handelsbilanz END) AS WA87
FROM handelsbilanz
WHERE Warenbezeichnung IN ('Elektrotechnische Erzeugnisse', 'Kraftfahrzeuge, Landfahrzeuge')
GROUP BY 1
) 
SELECT 
Jahr,
ROUND(WA87 / WA85,2) AS WA87_times_WA85, -- z. B. 2011: 15,77 * Handelsbilanz Elektrotechnische Erzeugnisse = Handelsbilanz Kfz
ROUND((WA87 / WA85 -1) * 100,2) AS WA87_pct_of_WA85 -- z. B. 2011: 1476,73% * Handelsbilanz Elektrotechnische Erzeugnisse = Handelsbilanz Kfz 
FROM cte;

-- 5. Anteil der Kfz Handelsbilanz an der gesamten Handelsbilanz in % je Jahr 
WITH cte AS (
SELECT 
YEAR(Datum) AS Jahr,
SUM(Handelsbilanz) AS Handelsbilanz
FROM handelsbilanz
GROUP BY 1),

kfz AS (
SELECT 
YEAR(Datum) AS Jahr,
SUM(Handelsbilanz) AS Kfz_Handelsbilanz
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
GROUP BY 1)

SELECT 
c.Jahr,
ROUND(k.Kfz_Handelsbilanz / c.Handelsbilanz * 100,2) AS pct_kfz
FROM cte c
JOIN kfz k ON c.Jahr = k.Jahr;

-- 6. Anteil der einzelnen Warenklassen an der monatlichen Handelsbilanz
SELECT 
Datum,
Warenbezeichnung,
Handelsbilanz,
SUM(Handelsbilanz) OVER (PARTITION BY Datum) AS Total_Handelsbilanz,
ROUND(Handelsbilanz / SUM(Handelsbilanz) OVER (PARTITION BY Datum) * 100,2) AS Pct_Total
FROM handelsbilanz;

-- 7. Saisonaler Anteil der Kfz Handelsbilanz an der jährlichen Handelsbilanz am Beispiel Kfz 2024
SELECT 
Datum,
Handelsbilanz,
SUM(Handelsbilanz) OVER (PARTITION BY YEAR(Datum)) AS Total_Handelsbilanz,
ROUND(Handelsbilanz / SUM(Handelsbilanz) OVER (PARTITION BY YEAR(Datum)) * 100,2) AS Pct_Total
FROM handelsbilanz
WHERE YEAR(Datum) = 2024
AND Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge';

-- 8. Entwicklung der Kfz Handelsbilanz auf Basis 2008 als Indexjahr
WITH cte AS (
SELECT 
YEAR(Datum) AS Jahr,
SUM(Handelsbilanz) AS Handelsbilanz
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
GROUP BY 1)
SELECT 
*,
ROUND((Handelsbilanz / FIRST_VALUE(Handelsbilanz) OVER (ORDER BY Jahr)-1) * 100, 2) AS index_change
FROM cte;

-- 9. Entwicklung der Kfz Handelsbilanz 2024 als geglätteter 12-Monats-Durchschnitt
-- z. B. Rollender Durchschnitt für Januar 2024: Durchschnitt Handelsbilanz Feb 2023 - Jan 2024 usw.
SELECT 
a.Datum,
a.Handelsbilanz,
ROUND(AVG(b.Handelsbilanz),0) AS Rollender_Durchschnitt,
COUNT(b.Handelsbilanz) AS Zähler -- Darstellung nur als Quercheck
FROM handelsbilanz a
JOIN handelsbilanz b ON a.Warenbezeichnung = b.Warenbezeichnung 
AND b.Datum BETWEEN a.Datum - INTERVAL 11 MONTH
AND a.Datum
AND b.Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
WHERE a.Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
AND a.Datum BETWEEN '2024-01-01' AND '2024-12-01'
GROUP BY 1,2
ORDER BY 1;

-- Alternativdarstellung über Window Function (hier für alle Jahre, wobei für 2008 noch kein Rollender Durchschnitt gebildet werden kann)
SELECT
Datum,
ROUND(AVG(Handelsbilanz) OVER (ORDER BY Datum ROWS BETWEEN 11 PRECEDING AND CURRENT ROW),0) AS Rollender_Durchschnitt,
count(Handelsbilanz) over (order by Datum rows between 11 preceding and current row) as Zähler
FROM Handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
ORDER BY Datum;

-- 10. Aufsummierte Handelsbilanz pro Jahr (jeweils mit Startpunkt Januar)
SELECT 
Datum, 
Handelsbilanz, 
SUM(Handelsbilanz) OVER (PARTITION BY YEAR(Datum) ORDER BY Datum) AS Handelsbilanz_YTD
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge';

-- 11. Berechnung der prozentualen Handelsbilanzveränderung im Vergleich zum Vormonat (Kfz)
WITH cte AS (
SELECT
Warenbezeichnung,
Datum,
Handelsbilanz,
LAG(Handelsbilanz) OVER (ORDER BY Datum) AS Handelsbilanz_prev
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge')
SELECT 
*, 
ROUND((Handelsbilanz / Handelsbilanz_prev - 1) * 100, 2) AS Pct_Change
FROM cte;

-- 12. Berechnung der prozentualen Handelsbilanzveränderung im Vergleich zum Vorjahresmonat (Kfz)
WITH cte AS (
SELECT
Warenbezeichnung,
Datum,
Handelsbilanz,
LAG(Handelsbilanz, 12) OVER (ORDER BY Datum) AS Handelsbilanz_prev
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge')
SELECT 
*, 
ROUND((Handelsbilanz / Handelsbilanz_prev - 1) * 100, 2) AS Pct_Change
FROM cte;

-- 13. Berechnung der prozentualen Handelsbilanzveränderung im Vergleich zum Vorjahr (Kfz)
WITH cte AS (
SELECT
Warenbezeichnung,
YEAR(Datum) AS Jahr,
SUM(Handelsbilanz) AS Handelsbilanz,
LAG(SUM(Handelsbilanz)) OVER (ORDER BY YEAR(Datum)) AS Handelsbilanz_prev
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
GROUP BY 1,2)
SELECT 
*, 
Handelsbilanz - Handelsbilanz_prev AS Abs_Differenz,
ROUND((Handelsbilanz / Handelsbilanz_prev - 1) * 100, 2) AS Pct_Change
FROM cte;

-- 14. Pivotitisierte Darstellung der Handelsbilanz 2008 bis 2010 auf Monatsbasis (Kfz)
SELECT 
MONTH(Datum) AS Monat,
MONTHNAME(Datum) AS Monat_Name,
SUM(CASE WHEN YEAR(Datum) = 2008 THEN Handelsbilanz ELSE 0 END) AS Handelsbilanz_2008,
SUM(CASE WHEN YEAR(Datum) = 2009 THEN Handelsbilanz ELSE 0 END) AS Handelsbilanz_2009,
SUM(CASE WHEN YEAR(Datum) = 2010 THEN Handelsbilanz ELSE 0 END) AS Handelsbilanz_2010
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge'
GROUP BY MONTH(Datum), MONTHNAME(Datum)
ORDER BY MONTH(Datum);

-- 15. Handelsbilanz im Verhältnis zum Durchschnitt der letzten 3 Jahre (Kfz)
WITH cte AS (
SELECT 
Datum,
Handelsbilanz,
LAG(Handelsbilanz, 12) OVER (ORDER BY Datum) AS Handelsbilanz_min1,
LAG(Handelsbilanz, 24) OVER (ORDER BY Datum) AS Handelsbilanz_min2,
LAG(Handelsbilanz, 36) OVER (ORDER BY Datum) AS Handelsbilanz_min3
FROM handelsbilanz
WHERE Warenbezeichnung = 'Kraftfahrzeuge, Landfahrzeuge')
SELECT 
*, 
ROUND((Handelsbilanz_min1 + Handelsbilanz_min2 + Handelsbilanz_min3) / 3, 0) AS Handelsbilanz_Avg3Y, 
ROUND((Handelsbilanz / ((Handelsbilanz_min1 + Handelsbilanz_min2 + Handelsbilanz_min3) / 3) * 100), 2) AS Pct_Handelsbilanz_Avg3Y
FROM cte;

