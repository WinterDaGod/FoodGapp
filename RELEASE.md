# 🚀 Releasing FoodGapp for Android

Follow this professional guide to generate a signed production build of FoodGapp for distribution or Play Store upload.

---

## 🔐 1. Generate a Signing Key (Keystore)

Android requires all apps to be digitally signed with a certificate before they can be installed.

1.  Open your terminal.
2.  Run the following command to generate a `upload-keystore.jks` file:

    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
    ```
    *(Note: On Windows, you might need to run this in PowerShell or CMD as an administrator. If `keytool` is not found, it's located in your JDK `bin` folder.)*

3.  **IMPORTANT**: Keep this file safe and do not lose it. If you lose this key, you cannot update your app on the Play Store.

---

## ⚙️ 2. Configure Build Environment

Create a file named `android/key.properties` (this file is already in `.gitignore` to keep your secrets safe).

Add the following content, replacing the values with your keystore path and passwords:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=key
storeFile=/Users/YOUR_USER/upload-keystore.jks
```

---

## 🏗️ 3. Build the Production Files

Once configured, you can generate the final release files using the Flutter CLI.

### 📱 Generate APK (For direct installation)
Best for sharing the app with friends or side-loading on a device.
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

### 📦 Generate App Bundle (For Play Store)
The modern standard for publishing to Google Play.
```bash
flutter build appbundle --release
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*

---

## ✨ 4. Optimization & Security (Optional)

To make your app even smaller and protect your source code from reverse engineering, use **Obfuscation**:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

---
*FoodGapp Production Release Pipeline.*
