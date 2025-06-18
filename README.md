# SQL-Data-Analysis
Sammlung von SQL-Skripten mit Fokus auf Datenanalyse

# SQL Datenanalyse mit MySQL Workbench

Dieses Repository enthält verschiedene SQL-Analysen mit **MySQL Workbench**, die sich an dem Buch  
**„SQL for Data Analysis“ von Cathy Tanimura** orientieren.

Jede Analyse ist in einem separaten Ordner organisiert und besteht aus:
- 📄 der zugehörigen **CSV-Datei** (Datengrundlage)
- 🧠 einem **SQL-Skript** mit analytischen Auswertungen

---

## 🔍 Struktur & Inhalte

| Analyse | Beschreibung | Fokus | Link |
|--------|--------------|------|------|
| 🚗 Handelsbilanz Deutschland | Auswertung deutscher Außenhandelsdaten 2008–2024 auf Monatsbasis| Zeitreihenanalyse | [Zum Ordner](./01_Zeitreihenanalysen) |

> Weitere Analysen werden **laufend ergänzt**.

---

## 🛠️ Tools & Grundlagen

- **Datenbank:** MySQL 8.042
- **GUI:** MySQL Workbench
- **Datenquellen:** Siehe jeweiliger Ordner
- **Buchreferenz:** [SQL for Data Analysis – Cathy Tanimura](https://www.oreilly.com/library/view/sql-for-data/9781492088787/)

---

## 📌 Hinweise

- Die CSV-Dateien wurden **vor der Analyse importiert**.
- Alle Skripte sind so aufgebaut, dass sie auf eine **lokal importierte Tabelle** verweisen.
- Anpassungen an Tabellennamen oder Datentypen sind je nach Setup ggf. erforderlich.
