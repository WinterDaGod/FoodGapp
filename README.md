<div align="center">
  <img src="assets/icon.png" width="128" height="128" alt="FoodGapp Logo">
  <h1>FoodGapp</h1>
  <p><strong>Eat Better, Track Smarter/strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-v3.4+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://www.android.com)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

---

## 📖 Overview

FoodGapp is a high-fidelity Android application engineered for the Philippine context, integrating the **FoodGapp AI Engine** to deliver a personalized, resilient, and data-driven nutrition experience. By combining official **DOST-FNRI** standards with modern Generative AI, FoodGapp transforms complex nutritional data into actionable daily habits.

---

## 💎 Core Pillars

### 🧠 1. Intelligent Orchestration
Powered by advanced **Natural Language Processing (NLP)**, the app acts as a 24/7 personal dietitian:
*   **Smart AI Planner**: Automatically generates calorie-matched daily and weekly schedules.
*   **AI Pantry Chef**: Invent creative recipes using only the ingredients currently in your kitchen.
*   **Natural Language Logging**: Log entire meals by simply describing them in plain English.
*   **AI-First Discovery**: Semantic search capabilities for goal-specific discovery (e.g., *"Quick post-workout high-protein snack"*).

### 🥗 2. Precision Nutrition
A commitment to data accuracy and local relevance:
*   **DOST-FNRI Alignment**: Dynamic feedback loops based on Philippine national nutritional targets.
*   **Differentiated Verification**: High-trust labeling distinguishing between **USDA Verified** clinical data and high-accuracy **AI Estimates**.
*   **Fluid Bio-Tracking**: Premium interactive tracking for hydration, intermittent fasting stages, and weight journey milestones.

### 🛡️ 3. Architectural Resilience
Engineered for "Zero-Downtime" discovery through a proprietary 4-layer data gateway:
1.  **Primary**: FoodGapp AI for bespoke creativity.
2.  **Verified Database**: Spoonacular (USDA-linked) for clinical standards.
3.  **Backup Source**: TheMealDB for rapid, basic discovery.
4.  **Local Snapshot**: Personal on-device library for instant offline access.

---

## ✅ Current Development Velocity

FoodGapp is currently in a **Feature-Complete, High-Fidelity state** for its initial capstone release.

| Module | Status | Highlights |
| :--- | :---: | :--- |
| **Authentication** | 🟢 | Firebase Auth, Custom Onboarding, Biometric Profiles. |
| **AI Engine** | 🟢 | Smart Planning, Pantry Chef, NLP Meal Logging. |
| **Data Layer** | 🟢 | v17 SQLite Schema, Aisle Caching, Nutritional Snapshotting. |
| **Analytics** | 🟢 | DOST-FNRI Feedback, Weight Journey, BMI Gauge. |
| **UX/UI** | 🟢 | Liquid-Fluid Animations, Haptic Feedback, Multi-select Filtering. |
| **Reliability** | 🟢 | 4-Tier Fallback Gateway, Offline Local Library. |

---

## 🛠️ Technical Blueprint

### The Stack
| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter (Android-Native Optimized) |
| **Language** | Dart 3.4+ |
| **AI Services** | FoodGapp AI Engine (NLP & Computer Vision ready) |
| **Persistence** | SQLite (`sqflite`) - v17 Schema |
| **Identity** | Firebase Authentication |
| **API Sources** | Spoonacular, USDA FoodData Central, TheMealDB |

### Database Schema (SQLite)
| Table | Description |
| :--- | :--- |
| `user_profile` | Biometrics, DOST-FNRI targets, and premium preferences. |
| `meal_log` | Detailed intake history with macronutrient breakdowns. |
| `saved_meals` | Personal recipe library and AI-generated snapshots. |
| `nutrition_cache` | High-speed local mirror for cloud-based recipe data. |
| `aisle_cache` | Locally persistent AI-categorized grocery aisle mapping. |
| `weight_log` | Historical data for journey visualization and BMI tracking. |
| `fasting_log` | Session management and biological stage tracking. |
| `water_log` | Persistent daily hydration metrics. |
| `shopping_list` | Dynamic checklist with quantity support and recipe merging. |

---

## 📁 Project Atlas

```text
.
├── lib/
│   ├── config/
│   │   ├── api_config.dart           # Real API keys (gitignored)
│   │   └── api_config.example.dart   # Template for local setup
│   ├── models/
│   │   ├── daily_nutrition.dart      # Aggregated daily intake data
│   │   ├── fasting_session.dart      # Fasting tracking data
│   │   ├── fasting_stage.dart        # Biological fasting stage definitions
│   │   ├── ingredient.dart           # Nutritional ingredient model
│   │   ├── meal_log.dart             # Logged meal entries
│   │   ├── nutrition_feedback.dart   # Formatted feedback data
│   │   ├── nutrition_target.dart     # Personalised targets (DOST-FNRI)
│   │   ├── recipe.dart               # Normalised recipe data structure
│   │   ├── saved_meal.dart           # User bookmarks and snapshots
│   │   ├── shopping_item.dart        # Checklist items with quantities
│   │   ├── user_profile.dart         # User biometrics and preferences
│   │   ├── water_log.dart            # Persisted hydration metrics
│   │   ├── weekly_plan.dart          # 7-day meal plan orchestration
│   │   └── weight_log.dart           # Weight history data points
│   ├── screens/
│   │   ├── widgets/                  # Reusable Premium UI components
│   │   │   ├── add_ingredient_modal.dart # AI & Search selection modal
│   │   │   ├── app_loading.dart      # High-fidelity loading states
│   │   │   ├── app_logo.dart         # Official FoodGapp branding widget
│   │   │   ├── app_toast.dart        # Custom notification system
│   │   │   ├── dashboard_widgets.dart# Macro and calorie visualisations
│   │   │   ├── expandable_fab.dart   # Interactive global action button
│   │   │   ├── quick_add_menu.dart   # 9-action high-speed menu
│   │   │   ├── recipe_widgets.dart   # Discovery and detail card views
│   │   │   └── water_tracker_widget.dart # Animated hydration tracker
│   │   ├── add_meal_screen.dart      # Manual and ingredient entry
│   │   ├── fasting_calendar_screen.dart # Historical fasting session logs
│   │   ├── fasting_timer_screen.dart # Real-time fasting orchestration
│   │   ├── feedback_screen.dart      # Detailed nutritional analysis
│   │   ├── home_screen.dart          # Main dashboard (Calories/Water)
│   │   ├── login_screen.dart         # Firebase authentication entrance
│   │   ├── main_navigation_shell.dart# Global bottom nav with blur
│   │   ├── meal_log_screen.dart      # Chronological recent meals
│   │   ├── meal_plan_screen.dart     # AI-powered meal generation
│   │   ├── onboarding_screen.dart    # Profile setup walkthrough
│   │   ├── profile_screen.dart       # Biometric settings and units
│   │   ├── progress_screen.dart      # Data visualisations and BMI
│   │   ├── recipe_detail_screen.dart # Nutritional deep-dives and AI reasoning
│   │   ├── recipe_search_screen.dart # AI-First discovery and Pantry Chef
│   │   ├── register_screen.dart      # New user account creation
│   │   ├── saved_meals_screen.dart   # Bookmarked recipe library
│   │   ├── shopping_list_screen.dart # Grocery management with aisles
│   │   └── welcome_screen.dart       # App entrance and logo animation
│   ├── services/
│   │   ├── api/                      # REST & AI Implementations
│   │   │   ├── api_exceptions.dart   # Centralised error handling
│   │   │   ├── gemini_service.dart   # Core FoodGapp AI Engine
│   │   │   ├── spoonacular_service.dart # Primary recipe database
│   │   │   ├── the_meal_db_service.dart # Emergency backup database
│   │   │   └── usda_service.dart     # Official nutritional verification
│   │   ├── app_events.dart           # Global state change notifications
│   │   ├── auth_service.dart         # Firebase authentication wrapper
│   │   ├── database_helper.dart      # SQLite setup and core persistence
│   │   ├── fasting_service.dart      # Fasting logic and stage management
│   │   ├── meal_generation_service.dart # AI-orchestrated planning
│   │   ├── nutrition_cache_store.dart# High-performance local storage
│   │   ├── nutrition_feedback_service.dart # DOST-FNRI target logic
│   │   ├── recipe_repository.dart    # Unified 4-layer data gateway
│   │   ├── shopping_list_service.dart# Smart categorization and merging
│   │   ├── sound_service.dart        # Premium audio and haptic feedback
│   │   └── unit_converter.dart       # Metric/Imperial math engine
│   └── main.dart                     # Application bootstrap
├── assets/                           # High-resolution media and branding
├── android/                          # Native Gradle and Android Manifest
├── test/                             # Comprehensive unit/widget test suite
├── pubspec.yaml                      # Dependencies and configuration
├── README.md                         # This documentation
├── SETUP.md                          # Environment setup instructions
└── changelog.md                      # History of premium upgrades
```

---

## 🚀 Getting Started

### 1. Requirements
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Firebase Project (configured via `flutterfire`)

### 2. Deployment
1.  **Install**: Run `flutter pub get`.
2.  **Configuration**: 
    - Copy `lib/config/api_config.example.dart` to `lib/config/api_config.dart`.
    - Populate `geminiApiKey` (from AI Studio) and `spoonacularApiKey`.
3.  **Identity**: Run `flutterfire configure` to link your Firebase project.
4.  **Launch**: Run `flutter run`.

---

## 🚀 Deployment

FoodGapp is optimized for Android production. To generate a signed APK or App Bundle:
1.  Review the [Production Release Guide](RELEASE.md).
2.  Configure your local `key.properties`.
3.  Execute `flutter build apk --release`.

---
*FoodGapp: Elevating Filipino health through Intelligent Nutrition.*
