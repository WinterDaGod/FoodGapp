# Implementation Plan - iOS "Sideload & Demo" Cloud Build

Enable the generation of an iOS `.ipa` file using GitHub Actions and implement a **"Demo Mode"** for Health features. This bypasses Apple's strict hardware restrictions for free accounts while still allowing you to demo the app's full capabilities.

## Proposed Changes

### [Services]

#### [MODIFY] [health_sync_service.dart](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/lib/services/health_sync_service.dart)
- **Demo Override**: Since HealthKit is physically blocked for free Apple IDs, I will implement a "Simulated Data" fallback for iOS.
- **Logic**: If running on iOS and native sync fails, the app will return **realistic mock data** (e.g., 5,420 steps and 210 cal burned).
- **Result**: You can still demo the **Activity Card**, **Streak Badge**, and **Gamification** logic on your iPhone without a paid account.

### [DevOps]

#### [NEW] [ios_sideload_build.yml](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/.github/workflows/ios_sideload_build.yml)
- **Zero-Secret Build**: Create a workflow to build an unsigned `.ipa` for sideloading.
- **Auto-Artifact**: Upload the build to your GitHub repository for download.

### [Documentation]

#### [NEW] [IOS_SIDELOADING_GUIDE.md](file:///C:/Users/FSOS/Downloads/Compressed/MPEMAIL/MealPlannerEmail/IOS_SIDELOADING_GUIDE.md)
- Step-by-step guide to installing the `.ipa` using **Sideloadly** on Windows.

## User Review Required

> [!CAUTION]
> **Apple Restriction**: My research confirms that Apple **strictly blocks** real HealthKit access for free accounts. The "Simulated Data" is the only way to show these features working on a real iPhone without paying the $99/year fee.

> [!NOTE]
> **Android is Full**: The health sync will remain 100% real and native on Android via Health Connect.

## Verification Plan

### Technical Audit
1.  **Demo Logic**: Verify that calling the health sync on iOS triggers the simulated data instead of returning an error.
2.  **Sideload build**: Verify that the GitHub Action produces a valid `.ipa` file structure.
3.  **UI Feedback**: Ensure the Activity Card appears on the iOS dashboard once the "Simulated Sync" is triggered.
