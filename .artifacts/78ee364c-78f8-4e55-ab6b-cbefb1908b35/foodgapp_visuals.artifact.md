# 💎 FoodGapp Technical Visual Dossier (Professional Edition)

This dossier contains secondary technical visuals for the **FoodGapp Capstone Defense**, focusing on data relationships (ERD), system resilience (Gateway), and the master functional flowchart.

---

## 🗄️ 1. Entity-Relationship Diagram (ERD) - SQLite v25
An industry-standard technical map of the relational schema using **Crow's Foot notation**.

```mermaid
erDiagram
    USER_PROFILE ||--o{ MEAL_LOG : "persists intake"
    USER_PROFILE ||--o{ WEIGHT_LOG : "monitors journey"
    USER_PROFILE ||--o{ WATER_LOG : "tracks hydration"
    USER_PROFILE ||--o{ FASTING_LOG : "schedules fasting"
    USER_PROFILE ||--o{ SHOPPING_LIST : "manages inventory"
    USER_PROFILE ||--o{ SAVED_MEALS : "bookmarks"

    SAVED_MEALS }o--|| NUTRITION_CACHE : "references"

    USER_PROFILE {
        string user_id PK "UID (Firebase)"
        string name "Display Name"
        string email "Unique Identifier"
        integer age "calculated"
        string gender "M/F/O"
        real weight_kg "Current"
        real height_cm "Stature"
        string health_goal "Lose/Maintain/Gain"
        string macro_preset "Macro Strategy"
        integer auto_adjust "Boolean (0/1)"
        string birthday "ISO-8601"
        string created_at "Timestamp"
    }

    MEAL_LOG {
        integer id PK "Auto-Inc"
        string user_id FK "Owner"
        string meal_date "ISO Date"
        string meal_type "B/L/D/S"
        string food_name "Title"
        real calories "Energy"
        real protein "P (g)"
        real carbs "C (g)"
        real fat "F (g)"
        string ingredients_json "Components"
    }

    WEIGHT_LOG {
        integer id PK
        string user_id FK
        string date "ISO Date"
        real weight_kg "Mass"
    }

    WATER_LOG {
        string user_id PK, FK
        string date PK "ISO Date"
        integer amount_ml "Volume"
    }

    FASTING_LOG {
        integer id PK
        string user_id FK
        string start_time "ISO-8601"
        int target_hours "Duration"
        string end_time "ISO-8601"
        integer is_completed "Boolean"
    }

    SHOPPING_LIST {
        integer id PK
        string user_id FK
        string name "Item Name"
        string recipe_name "Origin"
        string category "Aisle Name"
        integer quantity "Count"
        integer is_checked "Boolean"
    }

    SAVED_MEALS {
        integer id PK
        string user_id FK
        string api_meal_id "Source Key"
        string meal_name "Label"
    }

    NUTRITION_CACHE {
        string api_meal_id PK "Global ID"
        string meal_name "Cached Label"
        real calories "kcal"
        string raw_json "Full Metadata"
    }

    FOOD_LIBRARY {
        integer id PK "Titan Index"
        string name "Clinical Title"
        string category "PH/Global"
        real calories "Verified kcal"
        string source "PhilFCT/USDA"
    }
```

---

## 🚀 2. System Functional Flowchart (Comprehensive Journey)
This flowchart illustrates the complete operational lifecycle of FoodGapp, from the initial authentication handshake to the specialized tracking "Journeys."

```mermaid
flowchart TD
    %% Styling
    classDef startEnd fill:#f5f5f5,stroke:#333,stroke-width:2px;
    classDef decision fill:#FFF2CC,stroke:#d6b656,stroke-width:2px;
    classDef process fill:#FFF2CC,stroke:#d6b656,stroke-width:2px;
    classDef journey fill:#e1f5fe,stroke:#01579b,stroke-width:2px;

    Start([App Launch]) --> Auth{User Authenticated?}

    Auth -- No --> Welcome([Welcome Screen])
    Welcome --> Onboarding([1.0 Biometric Onboarding])
    Onboarding --> Register([2.0 Firebase Registration])
    Register --> Login([3.0 Login Interface])
    Login --> Dash

    Auth -- Yes --> Audit([4.0 Self-Healing Audit])
    Audit --> Dash([5.0 Home Dashboard])

    subgraph "Primary Navigation"
        Dash --> Nav{Bottom Navigation}
        Nav --> Progress([6.0 Progress Analytics])
        Nav --> Profile([7.0 Profile & Settings])
        Nav --> Recipes([8.0 Recipe Discovery])
    end

    subgraph "Quick Actions (Master FAB)"
        QuickAdd([Quick Add Menu])
        Dash --> QuickAdd

        QuickAdd --> MealCap([Meal Capture])
        MealCap --> NLP(["AI NLP Description\n(Magic Log)"])
        MealCap --> Manual(["Manual Search\n(Titan Engine)"])
        MealCap --> Recent([Relog Recent Meals])

        QuickAdd --> Planner([AI Meal Planner])
        QuickAdd --> ShopList([Shopping List])
    end

    subgraph "Specialized Journeys"
        Recipes --> RecDetail([Recipe Details])
        RecDetail --> SaveRec([Save Favorite])
        RecDetail --> LogRec([Log Meal])

        Planner --> GenPlan([Generate AI Schedule])
        GenPlan --> AddShop([Bulk Add to List])

        Progress --> WeightLog([Weight Journey])
        Progress --> MacroAvg([Macro Trends])
        Progress --> Fasting([Fasting Timer])
        Fasting --> FastStage([Biological Stages])
    end

    class Start startEnd;
    class Auth,Nav decision;
    class Welcome,Onboarding,Register,Login,Audit,Dash,Progress,Profile,Recipes,QuickAdd,MealCap,NLP,Manual,Recent,Planner,ShopList process;
    class RecDetail,SaveRec,LogRec,GenPlan,AddShop,WeightLog,MacroAvg,Fasting,FastStage journey;
```

---

## 🛡️ 3. The 5-Layer Data Resilience Gateway
Visualizes the application's unique hierarchical fail-over logic, ensuring 100% operational uptime.

```mermaid
graph TD
    classDef primary fill:#FFF2CC,stroke:#d6b656,stroke-width:3px;
    classDef emergency fill:#FFF2CC,stroke:#d6b656,stroke-width:2px;
    classDef offline fill:#FFF2CC,stroke:#d6b656,stroke-width:3px;

    Req([User Data Request])

    T1(["Tier 1: FoodGapp AI\n(Semantic Intelligence)"])
    T2(["Tier 2: Clinical Database\n(Spoonacular/USDA)"])
    T3(["Tier 3: Backup Gateway\n(TheMealDB)"])
    T4(["Tier 4: Titan Encyclopedia\n(50k Local Items)"])
    T5(["Tier 5: Local Snapshot\n(Cached Memory)"])

    Req --> T1
    T1 -- "Quota Exceeded" --> T2
    T2 -- "Timeout / Busy" --> T3
    T3 -- "No Internet" --> T4
    T4 -- "Unknown Item" --> T5

    T1 & T2 & T3 & T4 & T5 --> Success([Verified Macro Output])

    class T1 primary;
    class T2,T3 emergency;
    class T4,T5 offline;
```

---
> [!IMPORTANT]
> **Defense Talking Point**: "By combining a centralized **Star Schema ERD** with a **5-Layer Resilience Gateway**, we ensure that the user journey remains uninterrupted even in offline environments, while maintaining clinical-grade data integrity."
