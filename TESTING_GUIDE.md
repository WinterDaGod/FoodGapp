# 🧪 FoodGapp Quality Assurance (QA) Guide

This document outlines the professional testing procedures for the FoodGapp application. Testers should follow these steps to verify functional reliability, AI mathematical accuracy, and high-fidelity UX standards.

---

## 🔑 1. Identity & Security
*   **Password UX**: During registration, type a password. Verify the **Live Strength Checklist** turns green as you meet requirements. Test the **Visibility Toggle** (eye icon).
*   **Onboarding**: Complete the biometric setup. Verify that **DOST-FNRI** targets are calculated and saved to the Profile.
*   **Compliance**: Verify you cannot click "Create Account" until the **Terms & Privacy** checkbox is checked.
*   **Error Haptics**: Intentionally mismatch passwords and tap Register. Verify the device triggers a **"Heavy" vibration** alert.

## 🧠 2. FoodGapp AI Engine (Primary)
*   **AI-First Planning**:
    *   Generate a **Daily Plan**. Verify the source label on cards says **"FoodGapp AI"**.
    *   **Math Test**: Request a plan for **1358 kcal**. Sum the calories of the 3 meals. Verify the total is within +/- 50kcal and follows the **25/35/40 split**.
    *   **Weekly Test**: Generate a 7-day plan. Verify all 21 meals are unique and diet-compliant.
*   **Natural Language Logging (Describe)**:
    *   Tap "Describe" in the Add menu. Type: *"I had 2 cups of white rice and a large chicken breast."*
    *   Verify the AI correctly identifies items and pre-fills the manual entry screen.
*   **Pantry Chef**:
    *   Add random ingredients (e.g., *"Egg, Tomato, Bread"*). Verify the AI invents a creative, logical recipe.

## 🍱 Discovery & Saved Library
*   **Multi-Select Filters**: Select "Vegetarian" + "High Protein". Verify results contain **zero meat** and prioritize high-protein plant options.
*   **Saved Tab Performance**: Save 10+ recipes. Switch between "Discover" and "Saved". Verify the Saved tab **loads instantly** (sub-100ms) with full macro data.
*   **AI Reasoning**: Open any AI recipe. Verify the **Health Coach Reasoning** box explains why the meal fits your specific goals.

## 📊 Dashboard & Tracking
*   **Surplus Labels**: Log a meal exceeding your goal. Verify the label switches to **"Calories over"** in Red with a **"+"** sign.
*   **Hydration Animation**: Tap [+] in the water tracker. Verify the water drop icon **fills up** with a smooth liquid animation.
*   **BMI Gauge**: Update your weight. Verify the BMI needle moves and the **Journey Chart** marker updates accurately.

## 🛒 Shopping List Management
*   **Multi-Serving Add**: Generate a meal plan. Tap **"Add all to List"**.
    *   Verify the Meal Planner **does not reload/flash** (loading should be inside the button).
    *   Tap it again. Verify ingredients in the list **increment quantity (x2)** instead of duplicating.
*   **Aisle Grouping**: Verify ingredients are automatically categorized (e.g., Apple -> Produce).
*   **Clear All**: Tap the trash icon in the header. Verify the **Confirmation Dialog** appears before the list is wiped.

## 🛡️ Resilience & Offline
*   **Offline Mode**: Turn off data/Wi-Fi. Open Recipes. Verify **"Featured Recipes from Local Library"** are displayed.
*   **API Fail-over**: Simulate a database limit. Verify the app automatically uses **FoodGapp AI** to generate your plan without erroring.

## 🎨 Visual Audit
*   **Universal Themes**: Audit every screen in both **Cream Light** and **Premium Dark** modes for high-contrast legibility.
*   **Meal Type Badges**: Verify that logged meals on the dashboard show color-coded badges (Breakfast: Orange, Lunch: Green, Dinner: Blue).

---
*FoodGapp QA Protocol v1.1.0 — Production Release Ready*
