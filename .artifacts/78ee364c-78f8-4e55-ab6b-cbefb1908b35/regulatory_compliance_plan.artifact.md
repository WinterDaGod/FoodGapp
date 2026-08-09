# Implementation Plan - Play Store Regulatory & UX Polish

This plan ensures FoodGapp meets the strictest Google Play Store requirements for Health and Medical apps, focusing on Data Safety, Prominent Disclosure, and Age Protection.

## User Review Required

> [!IMPORTANT]
> **Health Connect Policy**: Google requires a "Prominent Disclosure" that explains what data is accessed *before* the system permission dialog appears.
> **COPPA/Age Gate**: Apps must verify that users are at least 13 years old if they collect personal data or use clinical features.

## Proposed Changes

### [Onboarding & Identity]

#### [MODIFY] [onboarding_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/onboarding_screen.dart)
- Implement a **Hard Age Gate**: If the user selects a birthday that makes them under 13, show a blocking dialog and prevent account creation.
- Add a **Clinical Disclaimer Acceptance**: On the final step, require the user to acknowledge that the app provides estimates and is not a replacement for professional medical advice.

### [Data Safety & Permissions]

#### [NEW] [health_disclosure_modal.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/widgets/health_disclosure_modal.dart)
- Create a beautiful, branded modal that explains **exactly** why we need Health Connect data (Steps & Calories) to provide accurate clinical feedback.
- This modal will have "Accept" and "Not Now" buttons. The system permission will ONLY be requested if the user taps "Accept."

#### [MODIFY] [home_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/home_screen.dart)
- Integrate the `HealthDisclosureModal`.
- Show it the first time a user lands on the dashboard if permissions haven't been previously addressed.

### [UX Resilience]

#### [MODIFY] [foodgapp_ai_service.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/services/api/foodgapp_ai_service.dart)
- Add **Connectivity Checks**: Before calling Gemini API, check if the device is online.
- Show a user-friendly error toast instead of a generic "Exception" if the network is down.

## Verification Plan

### Manual Verification
1. **Age Gate**: Set birthday to 2020. Verify that "Continue" is blocked with a professional message.
2. **Prominent Disclosure**: Reinstall the app. Verify the "Data Safety" modal appears before the Android system health permission prompt.
3. **Offline AI**: Turn off Wi-Fi/Data. Try to use "AI Description." Verify that a "No Internet" message appears instead of a crash.
4. **Clinical Disclaimer**: Verify the disclaimer is clearly visible and requires an interaction during onboarding.
