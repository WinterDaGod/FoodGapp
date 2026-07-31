# Guide: Sideloading FoodGapp on iOS (Windows/No-Mac)

This guide explains how to install the cloud-generated iOS build onto your iPhone for free using a Windows computer.

## 🛠️ Requirements
- A Windows PC with **iTunes** and **iCloud** (non-Microsoft Store versions) installed.
- Your iPhone and a USB lightning/USB-C cable.
- A free Apple ID.

## 📦 Step 1: Download the App
1. Go to your GitHub repository.
2. Click on the **Actions** tab.
3. Select the latest **"iOS Sideload Build"** run.
4. Download the **FoodGapp_iOS_Sideload** artifact (it will be a zip file containing the `.ipa`).

## 📲 Step 2: Install via Sideloadly
1. Download and install **Sideloadly** from [sideloadly.io](https://sideloadly.io/).
2. Connect your iPhone to your PC.
3. Open Sideloadly:
   - **IPA**: Drag the `FoodGapp_Sideload.ipa` into the IPA icon.
   - **Apple Account**: Enter your Apple ID email.
   - **Start**: Click the "Start" button.
4. Enter your Apple ID password if prompted (this goes directly to Apple's servers).

## 🛡️ Step 3: Trust the App on iPhone
Once the installation finishes, you need to allow it to run:
1. On your iPhone, go to **Settings > General > VPN & Device Management**.
2. Tap on your **Apple ID** under "Developer App."
3. Tap **"Trust [Your Email]"**.

## 🚀 Step 4: Demo Health (iOS Override)
Since you are using a free Apple ID, real HealthKit is blocked by Apple. 
- In FoodGapp, the app will detect it's on iOS and automatically switch to **"Demo Mode."**
- It will show **5,420 steps** and **215 cal burned** so you can still demo the Activity Dashboard and Streaks!

---
> [!NOTE]
> **The 7-Day Limit**: Apps sideloaded with a free account expire after **7 days**. To refresh it, simply plug your phone back into your PC and hit "Start" again in Sideloadly.
