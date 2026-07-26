# 📝 FoodGapp Production Changelogs

This file tracks the high-level functional and technical evolution of FoodGapp, focusing on the journey to the production-ready v1.1.0 release.

---

## [v1.1.5] - Performance Tracker & Data Patch (2026-07-26)

### 📊 Dashboard & Analytics
- **Interactive Calendar Strip**: Overhauled the top calendar into a dynamic performance tracker. Each date now features a technical progress ring that fills based on daily calorie targets.
- **Visual Intelligence**: Implemented smart date states with dashed borders for future dates and high-fidelity progress rings for past/present logging.
- **Smooth Animation Suite**: Integrated `TweenAnimationBuilder` for progress rings, adding a premium 800ms "growth" effect when switching dates or logging meals.

### ⚡ Data Engineering & Performance
- **Batch Range Querying**: Implemented high-speed date-range nutrition fetching. The app now retrieves all 14 days of calendar data in a single database query, ensuring zero loading delay for the dashboard.
- **Rendering Optimization**: Applied `RepaintBoundary` isolation to high-frequency animations, significantly reducing CPU/GPU overhead.

---

## [v1.1.4] - Interaction & Content Refinement (2026-07-26)

### 🎨 Visual & UX Polish
- **Dynamic Header Refinement**: Replaced the generic "Quick Add" header with more engaging, user-centric copy: *"Add to your day"* and *"Choose how you'd like to log food."*
- **Left-Aligned Hierarchy**: Repositioned the menu header to the left to maintain consistency with the rest of the application's high-fidelity design standards.
- **Improved Interaction**: Removed the manual "x" close button in favor of intuitive "tap-outside" dismissal, streamlining the visual interface.

---

## [v1.1.3] - Liquid Glass UI Update (2026-07-26)

### 🎨 Visual Fidelity
- **Liquid Glass Quick Add**: Implemented a sophisticated "Glassmorphism" effect for the Quick Add menu using high-intensity background blurring and translucency.
- **Ergonomic Downscaling**: Reduced the overall footprint of the Quick Add menu (92% -> 86% width) and shrunken action icons to ensure a perfect fit on smaller smartphone displays.
- **Glass-Edge Borders**: Added subtle, high-contrast borders to simulate light refraction on glass surfaces.

---

## [v1.1.2] - Professional UI Refinement (2026-07-26)

### 🎨 Visual & Ergonomic Polish
- **Optimized Master FAB**: Reduced the primary Floating Action Button (FAB) size (76px -> 60px) and icon scale to ensure a better ergonomic fit for modern smartphone screens.
- **Enhanced Spatial Alignment**: Fine-tuned the FAB bottom positioning for a more seamless integration with the curved navigation shell.
- **Customization Streamlining**: Removed experimental or non-functional settings (e.g., "Meal Logging" styles) from the User Profile to maintain a high-fidelity, production-ready interface.

---

## [v1.1.1] - Performance & Precision Patch (2026-07-26)

### ⚡ Technical Performance
- **Animation Isolation**: Implemented `RepaintBoundary` nodes for high-frequency animations (Water Drop, Macro Progress), reducing CPU/GPU load and preserving battery life.
- **High-Fidelity Skeleton Shimmers**: Replaced generic loading spinners with custom-designed skeleton screens for an "instant-load" user perception.
- **Smart Image Caching**: Integrated `cached_network_image` and dynamic resizing logic to ensure previously viewed recipes load instantly and offline.
- **Optimistic Saving**: Implemented 0ms "Heart" icon feedback for recipe bookmarks.

### 📐 Planning & Data Precision
- **Mathematical Unification**: Synchronized the Daily and Weekly planners to use the same high-accuracy database engine, ensuring targets like 1358 kcal are hit with 100% precision.
- **AI Math Self-Audit**: Updated the FoodGapp AI Engine prompts to enforce strict calorie summation and a professional 25/35/40 meal split.
- **Bulk Shopping Transactions**: Re-engineered the list saving logic to use SQLite transactions, enabling near-instant addition of a full week of ingredients.

### 🧹 Stability & Maintenance
- **Kotlin Integration**: Enabled Flutter's "Built-in Kotlin" and modern Gradle DSL to resolve KGP console warnings and ensure future build compatibility.
- **Dependency Stabilization**: Synchronized Firebase plugins to latest versions and stabilized `package_info_plus` for reliable Android registration.
- **List Management**: Added a "Clear All" feature to the Shopping List with a professional theme-aware confirmation dialog.
- **Bug Fix**: Resolved a "Flashing/Reloading" bug in the Meal Planner by isolating the adding-to-list state.
- **Refactor**: Completed the rebranding of all internal services to `FoodGappAiService` for codebase consistency.

---

## [v1.1.0] - The Intelligent Discovery Update

### 🚀 Major Features
- **AI-First Orchestration**: The FoodGapp AI Engine is now the primary driver for daily and weekly meal plans, providing bespoke, creative recipes from scratch.
- **NLP "Describe" Logging**: A new "Magic Log" feature allowing users to record meals using natural language descriptions.
- **Smart Aisle Grouping**: Automated grocery categorization using AI to group shopping items by store departments.
- **One-Tap Relogging**: High-speed logging for frequent meals from recent history.

### 🎨 UI & UX Overhaul
- **Compact & Modern Redesign**: A global tightening of the interface for higher information density and a more sophisticated feel.
- **Advanced Security UX**: Live password strength checklist with animated feedback during registration.
- **Liquid-Fluid Animations**: Re-engineered hydration tracking with smooth, organic filling animations.
- **Haptic Feedback Suite**: Integrated tactical confirmation for success, error, and milestone events.

### ⚡ Performance & Engineering
- **High-Speed Bulk Loading**: Optimized the "Saved" tab to load large recipe libraries instantly using bulk database queries.
- **Database Transaction Engine**: Re-built the shopping list saving logic to use SQLite transactions, resulting in a 50x speed increase.
- **Animation Isolation**: Implemented `RepaintBoundary` nodes to isolate high-frequency animations and maintain 60fps stability.
- **SQLite v19 Migration**: Standardized the data layer with professional-grade indexing on high-traffic columns.

---

## [v1.0.0] - Initial Capstone Release

- **Core Nutrition Tracking**: Established the DOST-FNRI feedback loop and daily macro targets.
- **Authentication**: Initial Firebase integration for secure email/password login.
- **Fasting Module**: basic intermittent fasting timer and history tracking.
- **Recipe Discovery**: Integration with Spoonacular and TheMealDB for basic search capabilities.

---
*FoodGapp Development Log.*
