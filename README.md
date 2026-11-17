# RavenStack SaaS: MRR Waterfall, Cohort Retention & Churn Risk Analytics

> **Project Objective:** Diagnose Net Revenue Retention (NRR) leakage, analyze subscription lifecycle movements (New, Expansion, Contraction, Churn), and build an early-warning risk scorecard using PostgreSQL and Power BI.

---

## 📋 Table of Contents
1. [Business Context & Problem Statement](#-business-context--problem-statement)
2. [Data Architecture & Relational Grain](#-data-architecture--relational-grain)
3. [Key SaaS Metrics & Definitions](#-key-saas-metrics--definitions)
4. [Analytical Methodology (The 5 Stages)](#-analytical-methodology-the-5-stages)
5. [Power BI Dashboard Blueprint](#-power-bi-dashboard-blueprint)
6. [Actionable Business Recommendations (Preview)](#-actionable-business-recommendations-preview)

---

## 🎯 1. Business Context & Problem Statement
* **The Challenge:** RavenStack is scaling its B2B software platform but struggling with hidden revenue leakage. While new signups look strong, customer cancellations and plan downgrades are eating into profitability.
* **The Goal:** Provide executive leadership with a clear view of Monthly Recurring Revenue (MRR) movement, customer survival curves, and behavioral red flags so the Customer Success team can intervene *before* clients cancel.

---

## 🗄️ 2. Data Architecture & Relational Grain
The project relies on 5 core relational tables simulating a real production B2B SaaS environment:
* **`accounts` (Grain: 1 row per company):** Firmographic details, industry segment, and signup dates.
* **`subscriptions` (Grain: 1 row per plan change/billing cycle):** Plan tiers, start/end dates, and MRR values.
* **`feature_usage` (Grain: 1 row per account per day):** Product telemetry tracking core feature engagement.
* **`support_tickets` (Grain: 1 row per support request):** Ticket category, resolution time, and satisfaction (CSAT) scores.
* **`churn_events` (Grain: 1 row per cancellation):** Exact cancellation dates, final refund status, and exit survey reasons.

---

## 📊 3. Key SaaS Metrics & Definitions
* **MRR (Monthly Recurring Revenue):** Normalized monthly value of active subscriptions.
* **MRR Waterfall Components:**
  * *New MRR:* Revenue from brand-new accounts this month.
  * *Expansion MRR:* Revenue gained from existing accounts upgrading their plans.
  * *Contraction MRR:* Revenue lost from existing accounts downgrading their plans.
  * *Churned MRR:* Revenue lost from accounts completely canceling their subscriptions.
* **Net Revenue Retention (NRR):** Percentage of recurring revenue retained from existing customers over time (including upgrades and churn).
* **SaaS Quick Ratio:** $(\text{New} + \text{Expansion}) / (\text{Contraction} + \text{Churn})$ — measuring growth efficiency.
* **Logo Churn vs. Revenue Churn:** Tracking both the percentage of companies leaving and the actual dollar value lost.

---

## 🛠️ 4. Analytical Methodology (The 5 Stages)
1. **Data Discovery & Grain Audit:** Inspecting trial periods, free accounts, and annual contract conversions.
2. **Star Schema Modeling:** Structuring staging data into clean dimension tables (`dim_accounts`, `dim_date`) and fact tables (`fact_mrr_monthly`, `fact_usage_summary`).
3. **Reconstructing the MRR Waterfall:** Comparing monthly account snapshots using SQL window functions to classify every dollar into its correct movement bucket.
4. **Behavioral & Friction Analysis:** Investigating the 30-day pre-churn window to see how support ticket spikes and flatlining feature usage correlate with cancellations.
5. **Executive BI Storytelling:** Translating the analytical findings into an interactive Power BI report.

---

## 📈 5. Power BI Dashboard Blueprint
* **Page 1: Executive MRR & Revenue Health**
  * *KPI Cards:* Total MRR, NRR %, SaaS Quick Ratio, Logo Churn %.
  * *Visuals:* Monthly MRR Waterfall column chart & Revenue breakdown by tier.
* **Page 2: Customer Survival & Cohort Retention**
  * *Visuals:* Cohort retention heatmap tracking signup months across Month 1 to Month 12.
* **Page 3: Early-Warning Churn Risk Scorecard**
  * *Visuals:* Scatter plot linking support ticket volume and feature engagement drop-offs to predicted cancellation risk.

---

## 💡 6. Actionable Business Recommendations (To Be Completed)
* *Placeholder for final insights once analysis is run (e.g., targeting Customer Success interventions when weekly feature clicks drop below X threshold).*