# Change Over Time Analysis

## Objective

_Analyze the month-over-month evolution of RavenStack's key SaaS business metrics to identify growth trends, performance fluctuations, and potential business risks. Evaluate customer acquisition, recurring revenue (MRR and ARR), subscription activity, customer churn, product engagement, and customer support activity to understand business performance over time, detect emerging patterns, and generate actionable insights that support data-driven decisions._

## Analysis Scope & Business Questions

### 1. Monthly Subscription Acquisition

- **Business Question:** How many new subscriptions and accounts does RavenStack acquire each month, how much new MRR do they generate, and how does acquisition evolve over time?
- **SQL File:** [Monthly Subscription Acquisition](./01_Monthly_Subscription_acquisition.sql)

- **Key Metrics:**
    - New Subscriptions
    - New Accounts
    - New MRR
    - Month-over-Month Growth (%)
- **Status:** In Progress

### 2. Monthly Active Recurring Revenue

- **Business Question:** How do active accounts, Monthly Recurring Revenue (MRR), and Annual Recurring Revenue (ARR) evolve month over month?
- **SQL File:** [Monthly Active MRR & ARR](./02_Monthly_Active_MRR_ARR.sql)
- **Key Metrics:**
    - Active Accounts
    - Active Subscriptions
    - Active MRR
    - Active ARR
- **Status:** Not Started

### 3. Subscription Plan & Billing Mix

- **Business Question:** How does the distribution of new subscriptions and recurring revenue change across subscription plans (Basic, Pro, Enterprise) and billing frequencies (Monthly vs. Annual)?
- **SQL File:** [Subscription Plan & Billing Mix](./03_Monthly_Plan_Billing_Mix.sql)
- **Key Metrics:**
    - New Subscriptions by Plan
    - New MRR by Plan
    - Subscription Mix (%)
    - Billing Frequency Distribution
- **Status:** Not Started

### 4. Monthly Subscription Cancellations & Lost Revenue

- **Business Question:** How many subscriptions and accounts cancel each month, how much recurring revenue is lost, and how does the churn trend evolve?
- **SQL File:** `04_Monthly_Churn_Lost_Revenue.sql`
- **Key Metrics:**
    - Churned Subscriptions
    - Churned Accounts
    - Lost MRR
    - Lost ARR
    - Customer Churn Rate (%)
    - Month-over-Month Change in Lost MRR (%)
- **Status:** Not Started

### 5. Monthly Account Signups & Seat Footprint

- **Business Question:** How do new account registrations and their initial seat allocations evolve over time?
- **SQL File:** `05_Monthly_Account_Seat_Footprint.sql`
- **Key Metrics:**
    - New Account Signups
    - Total Initial Seats
    - Average Initial Seats per Account
- **Status:** Not Started

### 6. Monthly Product Feature Usage

- **Business Question:** How does product usage evolve over time, and which features generate the highest engagement across active subscriptions?
- **SQL File:** `06_Monthly_Feature_Usage.sql`
- **Key Metrics:**
    - Total Feature Usage
    - Active Subscriptions Using Features
    - Usage by Feature
    - Feature Adoption (%)
- **Status:** Not Started

### 7. Monthly Customer Support Activity

- **Business Question:** How does customer support demand evolve over time, particularly regarding total ticket volume and high-severity issues?
- **SQL File:** `07_Monthly_Support_Activity.sql`
- **Key Metrics:**
    - Total Support Tickets
    - High-Severity Tickets
    - Urgent Tickets
    - Ticket Severity Distribution (%)
- **Status:** Not Started

---

## Analysis Methodology

Each business question will follow the same analytical process:

1. **Business Understanding:** Define the business question and analytical objective.
2. **Data Investigation:** Identify relevant tables, columns, date fields, and relationships.
3. **Metric Definition:** Establish clear metric definitions and calculation logic.
4. **SQL Development:** Write queries to extract, aggregate, and analyze the required data.
5. **Validation:** Check results, data consistency, and calculation accuracy.
6. **Trend Analysis:** Examine month-over-month changes and identify significant patterns.
7. **Business Interpretation:** Translate findings into meaningful business insights.

## Key Findings

To be documented after completing the analyses.

## Business Implications

To be documented after interpreting the results and identifying potential business risks and opportunities.
