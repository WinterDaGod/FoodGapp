# Implementation Plan - Dynamic Progress Labels

Refine the Home screen labels to dynamically switch between "left" and "over" states when a user exceeds their calorie or macro targets, improving clarity and motivation.

## Proposed Changes

### [UI Components]

#### [MODIFY] [home_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/home_screen.dart)
- **Calorie Logic**:
    - Calculate `diff = goal - consumed`.
    - If `diff < 0`:
        - Label: **"Calories over"**
        - Value: Display `abs(diff)` (e.g., `1583` instead of `-1583`).
        - Prefix: Add a subtle **"+"** or keep it clean as a positive number.
    - Else:
        - Label: **"Calories left"**
        - Value: Display `diff`.

#### [MODIFY] [dashboard_widgets.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/widgets/dashboard_widgets.dart)
- **`MacroCardSmall` Refinement**:
    - Add logic to the `label` and `value` display:
        - If `value` is negative:
            - Change "Protein left" to **"Protein over"**.
            - Change "Carbs left" to **"Carbs over"**.
            - Change "Fats left" to **"Fats over"**.
            - Display the absolute value with a **"+"** prefix (e.g., `+71g`).

## Verification Plan

### Manual Verification
1. **Surplus Test**:
    - Log enough meals to exceed the calorie goal.
    - Verify the main card switches from "Calories left" to **"Calories over"** and shows a positive number.
2. **Macro Over-limit Test**:
    - Exceed the Protein goal specifically.
    - Verify the Protein card switches its label and shows the surplus with a **"+"** sign.
3. **ShowSurplus Preference**:
    - Verify that if "Show Surplus" is **Disabled** in the Profile, the app still shows `0` left (no negative, no over) as per current logic.
4. **Theme Audit**: Ensure the new labels maintain the premium typography in both Light and Dark modes.
