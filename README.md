# Marketing Campaign Analysis & Visualization

## 📌 Project Overview
This project analyzes the effectiveness of marketing email campaigns across different countries. The goal was to build a conversion funnel (Sent → Open → Visit) and identify the top-performing regions based on user engagement.

**[👉 CLICK HERE TO VIEW INTERACTIVE DASHBOARD](https://lookerstudio.google.com/reporting/b57d352e-f879-4fe1-bfbd-8d93d63d31c0/page/tEnnC)**

**Tools used:**
* **SQL (Google BigQuery dialect):** Data extraction, transformation, and aggregation.
* **Looker Studio:** Data visualization and dashboarding.

## 📊 Dashboard Preview
![Dashboard Preview](dashboard_preview.png)
*Visualizing the correlation between sent messages and user activity.*

## 🛠 Technical Details
The analysis involves complex SQL querying techniques to prepare data for the BI tool.

### Key SQL Concepts Applied:
1.  **CTEs (Common Table Expressions):** Used `WITH` clauses (`account_cnt_1`, `email_cnt`) to break down the logic into readable modular blocks.
2.  **Joins & Unions:**
    * `JOIN`: Connected 5+ tables (`account`, `session`, `email_sent`, etc.) to link user actions with session parameters.
    * `UNION ALL`: Combined metrics from account creation and email interaction into a single dataset.
3.  **Window Functions:**
    * `SUM(...) OVER (PARTITION BY ...)`: Calculated totals per country to determine the weight of each region.
    * `DENSE_RANK()`: Ranked countries by account count and sent messages to filter the Top-10.

## 💡 Results
The SQL script generates a dataset that allows for:
* Tracking the volume of sent, opened, and visited emails.
* Comparing user verification and unsubscription rates.
* Identifying the top 10 countries by user base and activity level.
