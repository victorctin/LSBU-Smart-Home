# 📡 LSBU Smart Home Information System

This project is a prototype database and analytics solution developed for **LSBU Smart Home**, a company specializing in smart home technologies using Internet of Things (IoT) devices.

The solution simulates the company’s operational workflow including IoT sensor installations, building designs, inventory tracking, staff allocation, and client interactions. It covers full database lifecycle: from conceptual design to implementation and reporting.

## 📘 Case Study Summary

LSBU Smart Home designs, installs, and maintains IoT-based smart home systems. The company:
- Serves multiple clients, each possibly owning or sharing multiple buildings.
- Installs a range of sensors and controllers (e.g., motion, smoke, HD-CCTV).
- Keeps logs of device compatibility, supplier inventories, and staff deployment.
- Plans to expand into remote control apps and cloud-based data management.
- Wants automated invoicing, smart analytics, and flexible payment systems.

## ✅ Key Features

- **Entity Relationship Diagram (ERD):** Captures clients, buildings, designs, devices, suppliers, staff, and installations.
- **Normalization to 3NF/BCNF:** Ensures minimal redundancy and optimal structure.
- **SQL Implementation (MS SQL Server):** Creation of normalized tables and realistic test data (20+ records/table).
- **Advanced SQL Queries:**
  - Identify clients with highest/lowest design costs.
  - Analyze supplier order statuses (complete/incomplete/cancelled).
  - Check availability of specialist staff.
- **Stored Procedures & Triggers:**
  - Prevent double-bookings of staff.
  - Generate dynamic costed installation reports based on time filters (week/month/quarter).
- **Interactive Dashboard (Power BI):** Visualizes key metrics from the database (client activity, installation costs, staff assignments, etc.).

## 🧪 Technologies Used

- **MS SQL Server** – Relational database implementation
- **T-SQL** – Queries, triggers, and stored procedures
- **Power BI** – Business Intelligence dashboard


## 🧠 Tasks Breakdown

| Task | Description | Status |
|------|-------------|--------|
| ERD Design | Entity-relationship diagram with keys and attributes | ✅ Complete |
| Normalization | Functional dependencies to 3NF/BCNF | ✅ Complete |
| SQL Implementation | Tables + realistic data | ✅ Complete |
| SQL Queries | Custom queries + outputs | ✅ Complete |
| Stored Procedure & Trigger | Dynamic cost report, staff scheduling rules | ✅ Complete |
| Dashboard | BI dashboard using Power BI | ✅ Complete |


## 📊 Dashboard Preview

> *(Insert Power BI dashboard image here)*  
> `![Dashboard Screenshot](PowerBI/dashboard_sample.png)`


