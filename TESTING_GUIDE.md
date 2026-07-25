# 🧪 FoodGapp Quality Assurance (QA) Guide

This document outlines the professional testing procedures for the FoodGapp application. Testers should follow these steps to ensure functional reliability, AI accuracy, and UI/UX fidelity.

---

## 🔑 1. Identity & Onboarding
*   **Registration**: Create a new account. Verify that the biometric onboarding (Age, Height, Weight, etc.) correctly calculates the initial **DOST-FNRI** targets.
*   **Persistence**: Close the app and reopen. Ensure you are automatically logged back into the dashboard.
*   **Logout**: Log out and verify that the local session is cleared.

## 🧠 2. FoodGapp AI Engine
*   **Smart Planner**:
    *   Select "Vegan" + "High Protein". Verify the AI generates a plant-based plan.
    *   Use "Special Requests" (e.g., *"Italian mood"*). Verify the recipes reflect the requested cuisine.
*   **Pantry Chef**:
    *   Add 3 random ingredients (e.g., *"Egg, Tomato, Bread"*). Verify the AI invents a logical recipe using them.
*   **Quick Paste**:
    *   Enter a natural description: *"I had 2 cups of white rice and a large chicken breast."*
    *   Verify the AI correctly identifies the ingredients and parses accurate macros.

## 🍱 Discovery & Logging
*   **Discovery Filters**:
    *   Test "Mix & Match": Select "Low Carb" + "Keto". Verify the results update.
    *   Test "Collapsible UI": Expand and collapse the filter grid using the icon in the search bar.
*   **Meal Logging**:
    *   Log a manual meal with multiple ingredients. Verify the "Total Weight" calculation.
    *   **One-Tap Relog**: Go to "Recent Meals" and tap **Relog** on a past entry. Verify it appears on today's dashboard with the current time.

## 📊 Dashboard & Metrics
*   **Surplus Tracking**:
    *   Intentionally log a high-calorie meal to exceed your goal.
    *   Verify the label switches to **"Calories over"** in Red with a **"+"** sign.
*   **Hydration Tracker**:
    *   Tap [+] multiple times. Verify the water drop icon **fills up** with a smooth liquid animation and the progress bar **glides** instead of snapping.
*   **Progress Hub**:
    *   Log a new weight. Verify the **Journey Chart** updates the "Current" marker and recalculates the **BMI Gauge**.

## 🛌 Intermittent Fasting
*   **Timer Logic**: Start a fast. Verify the "Time Remaining" countdown is accurate.
*   **Stage Transition**: Let the timer run (or simulate time change). Verify the widget correctly displays biological stages (e.g., *"Stage 1: Blood Sugar Rising"*).
*   **History**: End a fast manually. Verify it appears correctly in the Fasting Calendar.

## 🛡️ Reliability & Offline Resilience
*   **Offline Discovery**: Turn off Wi-Fi/Data and open the Recipes tab. Verify that the app displays **"Featured Recipes from Local Library"** instead of an empty screen.
*   **API Fail-over**: Verify that if a search fails, the blue/orange warning bar appears, explaining which backup source (Spoonacular or TheMealDB) is currently active.

## 🎨 Visual & Haptic Fidelity
*   **Dark Mode**: Switch the device to Dark Mode. Audit all screens for high-contrast legibility and premium aesthetic consistency.
*   **Haptic Audit**: Enable "Meal Log Sounds" in Profile. Log a meal and verify you feel a subtle vibration and hear a system click.
*   **Link Verification**: Click on a recipe detail. Verify that the **AI Reasoning** box matches the specific goals selected.

---
*FoodGapp QA Protocol v1.1.0*
