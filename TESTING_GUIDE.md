# 🧪 FoodGapp Quality Assurance (QA) & Feature Guide

This document provides a comprehensive overview of the FoodGapp application features and the professional testing protocols required to verify functional reliability, AI accuracy, and high-fidelity UX standards.

---

## 📱 Core Application Features

### 🧠 FoodGapp AI Engine (Generative Intelligence)
*   **Bespoke Daily/Weekly Planner**: Generates complete, calorie-balanced meal schedules from scratch using **FoodGapp AI**.
*   **NLP "Describe" Modal**: Parses natural language meal descriptions into structured nutritional data (Magic Log).
*   **AI Pantry Chef**: Invents creative recipes based on user-provided ingredients to reduce food waste.
*   **Heuristic Aisle Sorter**: Automatically categorizes shopping items into grocery departments (Produce, Dairy, etc.).
*   **AI Reasoning Engine**: Provides a "Health Coach" explanation for every AI-generated meal.

### 🥗 Precision Nutrition & Tracking
*   **DOST-FNRI Feedback Loop**: Real-time analysis of daily intake against official Philippine nutritional standards.
*   **Hydration Tracker**: High-fidelity water intake logging with liquid-fluid animations.
*   **Biological Fasting Timer**: Stage-aware intermittent fasting orchestration with history visualization.
*   **Weight Journey & BMI**: Dynamic progress charts and BMI gauge with Metric/Imperial support.

### 🍱 Discovery & Resource Management
*   **Titan Offline Library**: A massive 50,000-item pre-indexed local database for instant discovery.
*   **4-Layer Data Gateway**: Resilient search architecture (Titan Local -> AI primary -> Spoonacular -> Local Snapshot).
*   **Saved Recipe Library**: High-performance personal bookmark system with instant bulk loading.
*   **Smart Shopping List**: Transactions-optimized list with quantity merging and aisle grouping.
*   **Quick Add Interface**: Modern 3x3 Liquid Glass menu for high-speed logging and navigation.

---

## 🔑 1. Identity, Security & Onboarding
*   **Birthdate Selector**: During onboarding, tap the Birthday field. Verify the professional **Wheel-based Selector** (Cupertino-style) appears. Test rapid year scrolling to ensure kinetic smoothness.
*   **Password UX**: During registration, type a password. Verify the **Live Strength Checklist** turns green as requirements are met. Test the **Visibility Toggle** and verify **Precision Alignment** of icons and text.
*   **Onboarding**: Complete the biometric setup. Verify that **DOST-FNRI** targets are accurately calculated and persisted to the profile.
*   **Compliance**: Verify that the "Create Account" action is locked until the **Terms & Privacy** checkbox is engaged.
*   **Error Haptics**: intentionally mismatch passwords. Verify the device triggers a **"Heavy" vibration** alert.

## 🧠 2. AI Intelligence & Mathematical Accuracy
*   **Bespoke Planning (The 1358 kcal Test)**:
    *   Generate a **Daily Plan** for exactly **1358 kcal**.
    *   **Audit**: Sum the calories of the 3 meals. Verify the total is within +/- 50kcal of the target.
    *   **Split Check**: Verify the distribution follows the **25/35/40** clinical split (Breakfast/Lunch/Dinner).
*   **NLP "Describe" (Magic Log)**:
    *   Input: *"I had two medium eggs and a bowl of garlic rice."*
    *   Verify the AI correctly identifies both items and pre-fills the logging screen with estimated weights and macros.
*   **Aisle Categorization**: 
    *   Add "Calamansi" to the shopping list. Verify it is automatically categorized under **"Produce"**.

## 📊 Dashboard, Analytics & Visuals
*   **Interactive Calendar Strip**:
    *   Log a meal for "Today." Verify the progress ring in the top calendar strip fills dynamically.
    *   Check future dates. Verify they display a **Dashed Border** (Pending state).
    *   Date travel: Tap a previous date. Verify the dashboard updates to show that day's specific intake.
*   **Liquid-Fluid Hydration**:
    *   Increment water. Verify the droplet fills with a smooth shader animation and the progress bar glides (not snaps).
*   **Surplus Detection**:
    *   Exceed your calorie goal. Verify the dashboard label switches to **"Calories over"** in Red with a **"+"** prefix.

## 👤 Profile & Technical Integrity
*   **App Version Verification**: Navigate to Profile. Scroll to the bottom and verify the **App Version** (e.g., 1.1.8+1) is visible and matches the official release.
*   **Self-Healing Database Test**:
    *   (Advanced) Trigger a structural audit by restarting the app.
    *   **Verification**: Ensure no `no such table` errors occur when adding items to the Shopping List or logging weight, confirming the app successfully validated its schema on startup.
*   **Functional Cleanup**: Verify that only active, functional settings are visible in the **Customizations** section (Theme, Surplus, Macro Presets).
*   **Logout Lifecycle**: Sign out and sign back in. Verify all data (Saved recipes, meal logs, water) persists correctly from the local SQLite database.

## ⚡ Performance & Resilience
*   **Titan Offline Search Test**:
    *   Put the device in **Airplane Mode**.
    *   Search for "Chickenjoy" or "Ala King" in the Manual Entry screen.
    *   **Verification**: results must appear in **<10ms** with accurate **PH Branded** or **PhilFCT** badges.
*   **Instant-Load Test**: Save 20+ recipes. Navigate to the "Saved" tab. Verify the list loads in **sub-200ms** without a spinner.
*   **Bulk Shopping Test**: Add a 7-day plan (21 meals) to the list. Verify the "Adding to List" state appears on the button and the process completes in **under 1 second**.
*   **Offline Discovery**: Enable Airplane Mode. Open the Recipes tab. Verify **"Featured Recipes from Local Library"** are displayed instead of an empty state.

## 🎨 Visual & Haptic Fidelity
*   **Universal Themes**: Switch between **Cream Light** and **Premium Dark**. Audit all modals (Describe, Add Ingredient) for high-contrast legibility and **High-Density Compact Layouts**.
*   **Splash Screen Audit**:
    *   Restart the app on an Android 12+ device.
    *   **Verification**: Ensure the logo appears as a clean, solid circle with **no white rings** or jaggy edges, confirming the Adaptive Inset fix.
*   **Liquid Glass Menu**: Open the Quick Add menu. Verify the **Frosted Glass** background blurs the underlying dashboard content at 60fps.
*   **Dismissal Logic**: Tap the blurred area outside the Quick Add menu. Verify it closes intuitively without needing a close button.

## 🍎 iOS-Specific Verification
*   **Cloud Build Download**: Push code to GitHub. Verify the **`FoodGapp-iOS-IPA`** artifact is generated and downloadable.
*   **Sideloading Audit**: Install the IPA on iPhone using Sideloadly or AltStore. Verify the app opens and passes the Apple "Trust" verification.
*   **iPhone 16e Layout**: Verify that the "Liquid Glass" menu and "Interactive Calendar" are perfectly aligned on the iPhone 16e display (iOS 18+).

---
*FoodGapp QA Protocol v1.2.0 — Production Release Certified*
