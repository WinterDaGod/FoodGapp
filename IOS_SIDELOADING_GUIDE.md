# 🍎 FoodGapp iOS Sideloading Guide (No-Mac Workflow)

Follow these steps to install FoodGapp on your iPhone 16e without owning a Mac. This process uses GitHub for building the app and a sideloading tool for installation.

---

## 🏗️ 1. Build the App on GitHub
1.  **Push your code**: Ensure your latest code (including the `.github/` folder) is pushed to your GitHub repository.
2.  **Go to Actions**: On your GitHub repository page, click the **"Actions"** tab.
3.  **Find the Build**: You will see a workflow named **"iOS Cloud Build"**.
4.  **Download the IPA**: Once the build finishes (takes ~10-15 mins), click on the build run and download the **`FoodGapp-iOS-IPA`** artifact at the bottom.

---

## 🔑 2. Prepare Firebase for iOS
Before installing, you must link the iOS version to your Firebase project:
1.  Go to the **Firebase Console**.
2.  Click **"Add App"** and select **iOS**.
3.  Enter Bundle ID: `com.example.foodgapp`.
4.  Download **`GoogleService-Info.plist`**.
5.  **Action Required**: You must add this file to your project at `ios/Runner/GoogleService-Info.plist` and push it to GitHub **before** the cloud build starts.

---

## 📱 3. Install on iPhone 16e
Use one of these tools on your Windows PC to install the downloaded `.ipa` file:

### Option A: AltStore (Highly Recommended)
1.  Install **AltServer** on your Windows PC from [altstore.io](https://altstore.io/).
2.  Connect your iPhone via USB.
3.  Right-click AltServer in the taskbar -> **Install AltStore** -> Select your iPhone.
4.  Once AltStore is on your phone, open it.
5.  Go to the **"My Apps"** tab -> tap **[+]** -> Select the `FoodGapp.ipa` you downloaded from GitHub.
6.  Sign in with your Apple ID to "sign" the app.

### Option B: Sideloadly (Fastest)
1.  Download **Sideloadly** on Windows from [sideloadly.io](https://sideloadly.io/).
2.  Connect your iPhone via USB.
3.  Drag the `FoodGapp.ipa` into Sideloadly.
4.  Enter your Apple ID and click **Start**.

---

## 🛡️ 4. Trust the Developer
After installation, the app might not open immediately. You must trust your own certificate:
1.  On your iPhone, go to **Settings > General > VPN & Device Management**.
2.  Tap your **Apple ID** under "Developer App."
3.  Tap **"Trust [Your Email]"**.
4.  **Important**: You must also enable **Developer Mode** under *Settings > Privacy & Security > Developer Mode*.

---
> [!NOTE]
> If you are using a **Free Apple ID**, the app will expire every **7 days**. Simply repeat the sideloading process or use AltStore's "Refresh" feature over Wi-Fi to keep it active.
