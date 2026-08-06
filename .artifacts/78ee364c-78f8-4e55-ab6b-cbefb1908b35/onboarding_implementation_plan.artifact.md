# Implementation Plan - High-Fidelity Onboarding Experience

This plan details the creation of a premium 3-page onboarding carousel that highlights FoodGapp's unique selling points: Clinical Micronutrients, AI Vision Logging, and RPG Gamification. This flow will be presented to first-time users before the account creation/login screen to drive engagement and retention.

## User Review Required

> [!IMPORTANT]
> **Assets**: We will use high-quality Material icons and Lottie-style animations (using standard Flutter animations) to represent the features.
> **Placement**: This screen will replace the current `WelcomeScreen` as the primary entry point for new users.

## Proposed Changes

### [Dependencies]

#### [MODIFY] [pubspec.yaml](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/pubspec.yaml)
- Add `shared_preferences: ^2.3.2` to track if the onboarding has been completed.
- Add `smooth_page_indicator: ^1.2.0+3` for the premium carousel dots.

### [Screens]

#### [NEW] [intro_carousel_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/intro_carousel_screen.dart)
- **High-Fidelity UI**: A `PageView` with 3 immersive slides.
  - **Slide 1: Clinical Depth**: Highlights the 8-nutrient tracking (Fiber, Sodium, etc.) with a "Microscope" icon and clinical colors.
  - **Slide 2: Magic Logging**: Demonstrates AI Vision with a "Camera/Lens" animation and a "Magic" feel.
  - **Slide 3: Your Health Journey**: Sells the RPG/XP system with a "Shield" icon and a leveling-up visual.
- **Glassmorphism Design**: Use blurred background elements and rounded "cards" for a modern production look.
- **CTA**: A "Start Your Journey" button that leads to the data-collection onboarding.

#### [MODIFY] [welcome_screen.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/screens/welcome_screen.dart)
- Update the "Get Started" button to navigate to the new `IntroCarouselScreen`.
- Refine the design to match the high-fidelity aesthetic of the new onboarding.

#### [MODIFY] [main.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/main.dart)
- Update the `AuthGate` to check `SharedPreferences`.
- If the user is not logged in AND has not seen the intro, show `IntroCarouselScreen`.
- Otherwise, show `WelcomeScreen`.

## Verification Plan

### Manual Verification
1. **First Launch**: Uninstall and reinstall the app. Verify the 3-page carousel appears first.
2. **Carousel UX**: Swipe through all 3 pages. Verify the `smooth_page_indicator` animates correctly.
3. **Skip/Finish**: Tap the CTA on the last page. Verify it leads to the profile setup screen.
4. **Subsequent Launch**: Close the app and reopen. Verify the carousel is skipped and the login/welcome screen appears directly.
