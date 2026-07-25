# 🍱 FoodGapp

A premium Android meal-planning and nutrition application (school capstone) designed for the Philippine context. FoodGapp leverages the **FoodGapp AI Engine** to provide highly personalized nutrition tracking, intelligent meal generation, and creative pantry-based cooking.

## ✨ Premium Features

### 🧠 FoodGapp AI Engine
The core "Brain" of the app, providing several high-fidelity features:
- **Smart AI Meal Planner**: Generates complete 3-meal daily plans (Breakfast, Lunch, Dinner) that are intelligently balanced to hit your specific macro targets (Protein/Carbs/Fats) with support for "Special Requests".
- **AI Pantry Chef**: Invent creative and delicious recipes using only the ingredients you currently have in your kitchen.
- **Natural Language Quick Paste**: Log entire meals by simply describing them (e.g., *"A large bowl of oatmeal with blueberries and a drizzle of honey"*).
- **AI-First Discovery**: Search for recipes using complex semantic queries like *"High protein post-workout snack under 300 kcal."*
- **Smart Aisle Grouping**: Automatically organizes shopping lists into store aisles (Produce, Meat, Dairy) with local intelligent caching to minimize API usage.

### 🥗 High-Fidelity Nutrition Tracking
- **DOST-FNRI Targets**: Compares your daily intake against official Philippine nutritional guidelines.
- **Verification System**: Differentiates between clinical **"USDA Verified"** data and high-accuracy **"Verified"** FoodGapp AI estimates.
- **Dynamic Dashboard**: Real-time tracking of calories, macros, hydration (water), and fasting sessions with liquid-fluid animations and haptic feedback.
- **One-Tap Relogging**: Quickly log frequent meals from your recent history with a single tap.

### 🛡️ 4-Layer Reliability Architecture
FoodGapp is built to be stable even when APIs are busy or the device is offline:
1. **Primary**: FoodGapp AI for creativity and personalization.
2. **Verified Database**: Spoonacular (USDA data) for established recipes.
3. **Backup Source**: TheMealDB for basic results when primary quotas are hit.
4. **Local Library**: A random selection of previously discovered recipes preloaded from your local cache for instant, offline browsing.

## ✅ Current Status

The application is currently in a **high-fidelity production-ready state** for its capstone scope:

- **Authentication**: Fully implemented Firebase Email/Password flow with custom onboarding and biometric profile setup.
- **AI Integration**: The **FoodGapp AI Engine** is fully wired for Natural Language meal logging, Smart Daily Planning, and the AI Pantry Chef.
- **Data Layer**: 10 SQLite tables are functional with built-in caching, local snapshots, and v17 schema migrations (including Aisle Caching and Quantity support).
- **Nutrition Logic**: Dynamic **DOST-FNRI** target calculation and real-time intake feedback are 100% complete and synchronized across the dashboard.
- **UX/UI**: Premium Android experience featuring liquid-fluid animations for hydration, haptic feedback for logging, and multi-select filtering for discovery.
- **Reliability**: 4-layer source fallback is active (AI -> Verified DB -> Backup -> Local Cache), ensuring zero downtime and offline functionality.

## 🛠️ Technical Stack

- **Framework:** Flutter (Dart), Android-native design.
- **AI Engine:** FoodGapp AI (Natural Language Processing).
- **Database:** Local SQLite (`sqflite`) for all personal data, macro history, and recipe caching.
- **Authentication:** Firebase Auth (Email/Password).
- **APIs:** Spoonacular (Primary DB), USDA FoodData Food Central (Verification), TheMealDB (Emergency Backup).

## 🗄️ Database Schema (SQLite)

FoodGapp uses a local SQLite database (`sqflite`) with the following core tables to ensure data privacy and offline functionality:

- **`user_profile`**: Stores user biometric data (age, height, weight), nutritional targets (DOST-FNRI), and app preferences (theme, units).
- **`meal_log`**: Records daily food intake, including names, serving sizes, and detailed macronutrient breakdowns.
- **`saved_meals`**: Persists bookmarked recipes and AI-generated meals for quick reference.
- **`nutrition_cache`**: A high-performance cache that stores recipe data from APIs and AI generations to reduce network calls and enable offline browsing.
- **`weight_log`**: Tracks the user's weight history over time to visualize progress on the journey chart.
- **`fasting_log`**: Manages intermittent fasting sessions, including start times, targets, and completion status.
- **`water_log`**: Logs daily water consumption in milliliters.
- **`shopping_list`**: Tracks ingredients required for planned meals, with support for quantities, servings, and recipe-to-list imports.
- **`aisle_cache`**: Locally persists AI-categorized ingredients to store aisles, enabling 0-cost retrieval for frequent items.
- **`active_meal_plan`**: Persists the current state of generated daily and weekly plans.

## 📁 Project Structure

```text
.
├── lib/
│   ├── config/
│   │   ├── api_config.dart           # Real API keys (gitignored)
│   │   └── api_config.example.dart   # Template for local setup
│   ├── models/
│   │   ├── daily_nutrition.dart      # Aggregated daily intake data
│   │   ├── fasting_session.dart      # Fasting tracking data
│   │   ├── fasting_stage.dart        # Definition of biological fasting stages
│   │   ├── ingredient.dart           # Nutritional ingredient model
│   │   ├── meal_log.dart             # Logged meal entries
│   │   ├── nutrition_feedback.dart   # Feedback data structure
│   │   ├── nutrition_target.dart     # Personalised targets (DOST-FNRI)
│   │   ├── recipe.dart               # Normalised recipe data
│   │   ├── saved_meal.dart           # User bookmarks
│   │   ├── shopping_item.dart        # Checklist items with quantities
│   │   ├── user_profile.dart         # User biometrics and preferences
│   │   ├── water_log.dart            # Persisted hydration data
│   │   ├── weekly_plan.dart          # 7-day meal plan structure
│   │   └── weight_log.dart           # Weight history data
│   ├── screens/
│   │   ├── widgets/                  # Reusable UI components
│   │   │   ├── add_ingredient_modal.dart # AI & Search selection modal
│   │   │   ├── app_loading.dart      # Premium loading states
│   │   │   ├── app_logo.dart         # Official FoodGapp branding widget
│   │   │   ├── app_toast.dart        # Custom notification system
│   │   │   ├── dashboard_widgets.dart# Calorie and macro visualisations
│   │   │   ├── expandable_fab.dart   # Interactive action button
│   │   │   ├── quick_add_menu.dart   # 9-action high-speed menu
│   │   │   ├── recipe_widgets.dart   # Discovery and detail card components
│   │   │   └── water_tracker_widget.dart # Animated hydration tracker
│   │   ├── add_meal_screen.dart      # Manual and ingredient entry
│   │   ├── fasting_calendar_screen.dart # Historical fasting logs
│   │   ├── fasting_timer_screen.dart # Real-time fasting tracker
│   │   ├── feedback_screen.dart      # Detailed nutritional analysis
│   │   ├── home_screen.dart          # Main dashboard (Calories/Water)
│   │   ├── login_screen.dart         # Firebase authentication login
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
│   │   ├── api/
│   │   │   ├── api_exceptions.dart   # Custom error handling
│   │   │   ├── gemini_service.dart   # Core AI Engine (FoodGapp)
│   │   │   ├── spoonacular_service.dart # Primary recipe database
│   │   │   ├── the_meal_db_service.dart # Emergency backup database
│   │   │   └── usda_service.dart     # Official nutritional verification
│   │   ├── app_events.dart           # Global state change notifications
│   │   ├── auth_service.dart         # Firebase authentication wrapper
│   │   ├── database_helper.dart      # SQLite setup and core persistence
│   │   ├── fasting_service.dart      # Fasting logic and stage management
│   │   ├── meal_generation_service.dart # AI-orchestrated planning
│   │   ├── nutrition_cache_store.dart# Fast local recipe storage
│   │   ├── nutrition_feedback_service.dart # DOST-FNRI target logic
│   │   ├── recipe_repository.dart    # Unified 4-layer data gateway
│   │   ├── shopping_list_service.dart# Smart categorization and merging
│   │   ├── sound_service.dart        # Premium audio and haptic feedback
│   │   └── unit_converter.dart       # Metric/Imperial math logic
│   └── main.dart                     # App entry point
├── assets/                           # Image and branding assets
├── android/                          # Native Android configurations
├── test/                             # Unit and widget test suite
├── pubspec.yaml                      # Project dependencies and configuration
├── README.md                         # Main documentation
├── SETUP.md                          # Detailed environment setup
└── changelog.md                      # History of premium upgrades
```

## 🚀 Getting Started

1.  **Dependencies**: Run `flutter pub get`.
2.  **API Keys**: Add your keys to `lib/config/api_config.dart`.
    - `geminiApiKey`: Get a free key from the official AI Studio.
    - `spoonacularApiKey`: Get a key from [spoonacular.com](https://spoonacular.com/food-api).
3.  **Firebase**: Run `flutterfire configure` to link your project.
4.  **Launch**: Run `flutter run`.

---
*Developed as a high-fidelity capstone project focusing on AI integration and modern Android UX.*
