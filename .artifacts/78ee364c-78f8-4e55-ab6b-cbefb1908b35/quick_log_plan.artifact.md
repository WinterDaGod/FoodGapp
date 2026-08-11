# Implementation Plan - One-Tap Memory (Frictionless Logging)

This plan details the implementation of a "Smart Memory" feature that allows users to log their most frequent meals with a single tap. The system will intelligently suggest meals based on the current time of day and the user's logging history.

## User Review Required

> [!IMPORTANT]
> **Placement**: Suggestions will appear as a horizontally scrolling list on the Home screen, titled "Log Again?".
> **Ranking Logic**: Suggestions are ranked by frequency + recency + time-of-day alignment (e.g., at 8 AM, prioritize items previously logged as 'Breakfast').

## Proposed Changes

### [Database & Logic]

#### [MODIFY] [database_helper.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/services/database_helper.dart)
- **[NEW] `getQuickLogSuggestions(String userId, String mealType)`**:
  - A sophisticated SQL query that:
    1. Finds the top 5 most frequently logged items for a specific `mealType`.
    2. Groups them by `food_name`.
    3. Returns `MealLog` skeletons (name, calories, macros, image) for instant logging.

### [UI Components]

#### [NEW] [quick_log_carousel.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/widgets/quick_log_carousel.dart)
- A horizontally scrolling carousel of circular "One-Tap" buttons.
- Each button shows a high-fidelity image of the meal and its name.
- Tapping a button performs an **Instant Log**:
  - Automatically creates a new `MealLog` entry for today.
  - Copies all clinical markers (Sodium, Fiber, etc.) from the history item.
  - Shows a success toast with an "Undo" option.

### [Home Screen Integration]

#### [MODIFY] [home_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/home_screen.dart)
- Inject the `QuickLogCarousel` right above the "Meals" timeline.
- Dynamic Title: Changes based on time (e.g., "Typical Breakfast?" at 8 AM, "Usual Snack?" at 3 PM).

## Verification Plan

### Manual Verification
1. **Frequency Check**: Log "Egg & Rice" 3 times for Breakfast. Verify it appears at the top of the "Log Again?" list the next morning.
2. **Time Sensitivity**: Change system time to 12:00 PM. Verify that Breakfast suggestions are replaced by Lunch suggestions.
3. **One-Tap Execution**: Tap a suggestion. Verify that a new entry appears in the Today's Meals list with identical clinical data (Sodium, Fiber, etc.).
4. **Friction Check**: Measure the time to log. Goal: Under 2 seconds.
