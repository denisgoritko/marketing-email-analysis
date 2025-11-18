/*
  Модульна робота: Аналіз ефективності email-розсилок та географії користувачів.
  Інструменти: Google BigQuery SQL (Standard Dialect).
  Основні техніки: CTE, Window Functions, JOINs, UNION ALL.
*/

WITH account_cnt_1 AS (
  -- CTE 1: Збір статистики по створенню акаунтів.
  -- Прив'язуємо акаунти до сесій та країн користувачів.
  SELECT
    s.date,
    sp.country,
    ac.send_interval,
    ac.is_verified,
    ac.is_unsubscribed,
    COUNT(DISTINCT ac.id) AS account_cnt, -- Кількість унікальних акаунтів
    0 AS sent_msg, -- Заглушки (нулі) для метрик листів, щоб потім зробити UNION
    0 AS open_msg,
    0 AS visit_msg
  FROM `DA.account` ac
  JOIN `DA.account_session` acs ON ac.id = acs.account_id
  JOIN `DA.session_params` sp ON sp.ga_session_id = acs.ga_session_id
  JOIN `DA.session` s ON s.ga_session_id = sp.ga_session_id
  GROUP BY 1,2,3,4,5
),

email_cnt AS (
  -- CTE 2: Розрахунок метрик по email-кампаніям (воронка: Sent -> Open -> Visit).
  -- Дані прив'язуються до дати відправки листа.
  SELECT
    DATE_ADD(s.date, INTERVAL es.sent_date  DAY) AS date, -- Корегування дати події
    sp.country,
    ac.send_interval,
    ac.is_verified,
    ac.is_unsubscribed,
    0 AS account_cnt, -- Заглушка для кількості акаунтів
    COUNT(DISTINCT es.id_message) AS sent_msg, -- Відправлено листів
    COUNT(DISTINCT eo.id_message) AS open_msg, -- Відкрито листів
    COUNT(DISTINCT ev.id_message) AS visit_msg  -- Переходів з листів
  FROM `DA.email_sent` es
  LEFT JOIN `DA.email_open` eo ON es.id_message = eo.id_message
  LEFT JOIN `DA.email_visit` ev ON ev.id_message = es.id_message
  JOIN `DA.account` ac ON ac.id = es.id_account
  JOIN `DA.account_session` acs ON acs.account_id = es.id_account
  JOIN `DA.session` s ON s.ga_session_id = acs.ga_session_id
  JOIN `DA.session_params` sp ON sp.ga_session_id = acs.ga_session_id
  GROUP BY 1,2,3,4,5
),

unioncnt AS (
  -- CTE 3: Об'єднання двох наборів даних (акаунти та листи) в одну таблицю.
  SELECT * FROM account_cnt_1
  UNION ALL
  SELECT * FROM email_cnt
),

groupcnt AS (
  -- CTE 4: Фінальна агрегація об'єднаних даних.
  -- Сумуємо показники по днях, країнах та типах підписки.
  SELECT
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    SUM(account_cnt) AS account_cnt,
    SUM(sent_msg) AS sent_msg,
    SUM(open_msg) AS open_msg,
    SUM(visit_msg) AS visit_msg
  FROM unioncnt
  GROUP BY 1,2,3,4,5
),

with_totals AS (
  -- CTE 5: Використання віконних функцій для розрахунку загальних сум по країні.
  -- Це потрібно для визначення частки кожної країни перед ранжуванням.
  SELECT
    *,
    SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt, -- Всього акаунтів у країні
    SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt        -- Всього листів у країні
  FROM groupcnt
),

ranked AS (
  -- CTE 6: Ранжування країн (DENSE_RANK) за спаданням активності.
  -- Дозволяє відфільтрувати ТОП країн без втрати даних при однакових значеннях.
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt
  FROM with_totals
)

-- Фінальна вибірка: залишаємо дані тільки для ТОП-10 країн
-- (або по кількості акаунтів, або по кількості відправлених листів).
SELECT *
FROM ranked
WHERE rank_total_country_account_cnt <= 10 OR rank_total_country_sent_cnt <= 10;