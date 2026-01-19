# 📘 SpendSense

SpendSense is a mobile expense tracking application built with Flutter. It allows users to log and categorize their income and expenses, view summaries, and manage personal finances with a clean, intuitive interface and Firebase backend.

This README gives you a complete overview, setup instructions, feature list, and how others can contribute.

## 🚀 Features

SpendSense includes the following key features:

User Authentication
Sign up and login with secure Firebase Authentication.

Add Transactions
Record income and expenses with amount, title, category, date, and notes.

Categorical Tracking
Transactions can be categorized and filtered.

User-Editable Categories
Users can customize which categories are enabled for tracking.

Firestore Integration
Transactions are synced with Cloud Firestore for persistence and cross-device access.

Summary & Insights
(Optional in future versions) Chart/summary views of spending over time.

## 🧱 Architecture Overview

This project follows a modular pattern using Flutter’s widget tree and Firebase for backend services:

* State Management → Provider

* Backend → Firebase (Authentication + Firestore)

* UI Framework → Flutter

## 📱 App Screenshots

### Splash & Authentication
<p align="center">
  <img src="images/splash_screen_img.png" width="250">
  <img src="images/login_page_img.png" width="250">
  <img src="images/signup_page_img.png" width="250">
</p>

### Add Transactions
<p align="center">
  <img src="images/add_transactions_expense_page_img.png" width="250">
  <img src="images/add_transactions__income_page_img.png" width="250">
</p>

### Insights & Summaries
<p align="center">
  <img src="images/expense_summary_page_img.png" width="250">
  <img src="images/spending_summary__monthly_page_img.png" width="250">
  <img src="images/category_breakdown_page_img.png" width="250">
</p>

### Profile & Settings
<p align="center">
  <img src="images/profile_page_top_img.png" width="250">
</p>
