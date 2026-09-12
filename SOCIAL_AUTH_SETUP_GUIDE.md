# Complete Social Authentication Setup Guide (Google & Apple Sign-In)

This document provides step-by-step instructions to register and configure **Google Sign-In** (for Android & iOS) and **Apple Sign-In** (for iOS and Backend) for the **Foam** mobile application.

---

## 1. App Identifiers & Keystore Fingerprints

Keep these exact values handy when registering apps in Firebase, Google Cloud, and Apple Developer portals:

| Platform | Property | Configured Value |
| :--- | :--- | :--- |
| **Android** | Package Name / Application ID | `com.foam.foam_mobile` |
| **Android** | Debug SHA-1 Fingerprint | `C8:3B:C3:60:36:79:F4:7E:36:8B:0D:D6:A8:09:07:10:97:52:49:88` |
| **Android** | Debug SHA-256 Fingerprint | `60:EF:DF:F2:3A:44:1D:A6:4D:EB:B5:93:26:86:D9:ED:F9:7D:9B:23:CD:8C:52:43:61:7A:B3:73:BD:BD:3D:21` |
| **Android** | Production Upload SHA-1 | `1C:67:C2:E9:48:5E:5B:70:8D:5F:DF:9D:65:03:FD:38:6C:C6:55:40` |
| **Android** | Production Upload SHA-256 | `A9:A1:FF:08:AC:BE:FA:CA:14:3C:C8:5B:1C:56:DE:F0:99:4C:F4:CE:F0:E4:70:A1:7C:CC:57:40:6E:A7:43:7D` |
| **iOS** | `iOS client 1` (`googleIosClientId`) | `791114743359-2oschsrqbca3agqbihvqjvg0r95hrk51.apps.googleusercontent.com` |
| **Android** | `foam` / Android Client 1 (`googleAndroidClient1`) | `791114743359-5kjubqe1nids9feo84fhqkn4acaaa9c3.apps.googleusercontent.com` |
| **Android** | `Android client 2` (`googleAndroidClient2`) | `791114743359-cdm609nek1mfg3g06a40etihs1cebetg.apps.googleusercontent.com` |
| **Backend/Web** | `Web client` (`googleWebClientId` / `serverClientId`) | `791114743359-8b6vbiairi8q619vcovm3h8dg5re9u9a.apps.googleusercontent.com` |
| **iOS** | Bundle Identifier | `com.foam.foamMobile` (or your registered Apple Bundle ID) |

---

## 2. Google Sign-In Setup

### Part A: Android Setup

#### Step 1: Add Android App to Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com/) and select your project (e.g. `foam-78cf4`).
2. Go to **Project Settings** (gear icon) > **General** tab.
3. Under **Your apps**, click **Add app** > **Android**.
4. Enter the Package Name: `com.foam.foam_mobile`.
5. Enter App Nickname: `Foam Android`.
6. Add the SHA-1 fingerprints:
   - Paste **Debug SHA-1**: `C8:3B:C3:60:36:79:F4:7E:36:8B:0D:D6:A8:09:07:10:97:52:49:88`
   - Paste **Production Upload SHA-1**: `1C:67:C2:E9:48:5E:5B:70:8D:5F:DF:9D:65:03:FD:38:6C:C6:55:40`
7. Click **Register App**.
8. Download the `google-services.json` file and place it in:
   ```
   foam_mobile-main/android/app/google-services.json
   ```
9. Also add the SHA-256 fingerprints under **Add fingerprint** for both Debug and Production Upload.

#### Step 2: Google Play Console (For Production Releases)
If you use **Google Play App Signing**:
1. Open the [Google Play Console](https://play.google.com/console).
2. Navigate to **Release** > **Setup** > **App Integrity**.
3. Under **App signing key certificate**, copy the **SHA-1** and **SHA-256** fingerprints.
4. Add these Play Store SHA fingerprints to your Firebase Console under the Android app settings as well.

---

### Part B: iOS Setup

#### Step 1: Add iOS App to Firebase Console
1. In the [Firebase Console](https://console.firebase.google.com/), click **Add app** > **iOS**.
2. Enter the iOS Bundle ID: `com.foam.foamMobile` (matching Xcode target).
3. Enter App Nickname: `Foam iOS`.
4. Click **Register App**.
5. Download `GoogleService-Info.plist` and place it in:
   ```
   foam_mobile-main/ios/Runner/GoogleService-Info.plist
   ```
   *(Ensure it is added via Xcode to the `Runner` target).*

#### Step 2: Configure URL Schemes in `Info.plist`
1. Open `ios/Runner/GoogleService-Info.plist` and copy the value of `REVERSED_CLIENT_ID` (e.g. `com.googleusercontent.apps.123456789-abcdef...`).
2. Open `foam_mobile-main/ios/Runner/Info.plist` and add the URL Scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <!-- Paste your REVERSED_CLIENT_ID from GoogleService-Info.plist here -->
               <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

---

### Part C: Google Cloud OAuth 2.0 Web Client ID (For Backend Verification)

1. Open the [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2. Select the Firebase project.
3. Under **OAuth 2.0 Client IDs**, locate the **Web client (auto created by Google Service)** or create a **Web application** client.
4. Copy the **Client ID** (e.g. `104085449221-xxxxxx.apps.googleusercontent.com`).
5. In your Backend `.env` file (`backend/.env`), configure:
   ```env
   GOOGLE_CLIENT_ID=104085449221-xxxxxx.apps.googleusercontent.com
   ```

---

## 3. Apple Sign-In Setup

### Part A: Apple Developer Portal Configuration

#### Step 1: Register App ID & Enable Capability
1. Log in to the [Apple Developer Account](https://developer.apple.com/account/).
2. Navigate to **Certificates, Identifiers & Profiles** > **Identifiers**.
3. Click the **+** icon to create a new **App ID** (type: *App*).
4. Enter Description: `Foam Laundry Mobile`.
5. Enter Bundle ID (Explicit): `com.foam.foamMobile`.
6. Scroll down to **Capabilities** and check **Sign In with Apple**.
7. Click **Edit** next to Sign In with Apple and select **Enable as a primary App ID**.
8. Click **Continue** and then **Register**.

#### Step 2: Create a Service ID (For Backend & Web Verification)
1. In **Identifiers**, click **+** and select **Services IDs**.
2. Description: `Foam Apple Auth Service`.
3. Identifier: `com.foam.foamMobile.service` (or `com.foam.auth`).
4. Enable **Sign In with Apple** and click **Configure**:
   - **Primary App ID**: Select `com.foam.foamMobile`.
   - **Website URLs**:
     - *Domains and Subdomains*: Your domain (e.g. `api.foamlaundry.com` or `foamlaundry.com`).
     - *Return URLs*: `https://api.foamlaundry.com/api/auth/apple/callback`.
5. Save and Register.

#### Step 3: Create Private Key (`.p8` file)
1. Go to **Keys** in the Apple Developer portal.
2. Click **+** to create a new key named `Foam Sign In With Apple Key`.
3. Check **Sign In with Apple** and click **Configure** > select your Primary App ID.
4. Click **Continue** > **Register**.
5. Download the `.p8` key file (Note: You can only download it once!).
6. Note down:
   - **Key ID** (10-character string, e.g. `ABC123DEFG`).
   - **Apple Team ID** (found at top-right of your Developer Account, e.g. `XYZ9876543`).

---

### Part B: iOS Project (Xcode) Setup

1. Open `foam_mobile-main/ios/Runner.xcworkspace` in **Xcode**.
2. Select the **Runner** project in the left sidebar, then select the **Runner** target.
3. Click on the **Signing & Capabilities** tab.
4. Click **+ Capability** and double-click **Sign in with Apple**.
5. This automatically adds `Runner.entitlements` with the Apple Sign-In entitlement:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.developer.applesignin</key>
       <array>
           <string>Default</string>
       </array>
   </dict>
   </plist>
   ```

---

## 4. Backend Environment Variables Checklist

Ensure the following environment variables are set in your `backend/.env` file:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Firebase Admin Service Account (used to verify mobile Google ID tokens)
FIREBASE_PROJECT_ID=foam-78cf4
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@foam-78cf4.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"

# Apple Sign-In Configuration (if verifying tokens via Apple private key)
APPLE_TEAM_ID=XYZ9876543
APPLE_KEY_ID=ABC123DEFG
APPLE_CLIENT_ID=com.foam.foamMobile
```

---

## 5. Summary Flow of How Authentication Works

```
[Flutter Mobile App]
   ├── User taps "Google"
   │     └── Obtains Google idToken from Google SDK
   │     └── POST /api/auth/google/callback/login (Authorization: Bearer <idToken>)
   │
   └── User taps "Apple" (iOS only)
         └── Obtains Apple identityToken from Apple SDK
         └── POST /api/auth/apple/callback/login (Authorization: Bearer <identityToken>)
                │
                ▼
      [Backend Server]
         ├── Verifies Google token using Firebase Admin SDK
         ├── Verifies Apple token using Apple public keys / JWT verification
         ├── Returns JWT token & user profile
         └── If user not registered -> Returns 404 -> Mobile prompts for phone number -> POST /register
```

---

## 6. Common Issues & Troubleshooting

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `ApiException: 10` on Android | SHA-1 fingerprint mismatch or package name mismatch | Ensure both Debug SHA-1 (`C8:3B:C3:60:36:79:F4:7E:36:8B:0D:D6:A8:09:07:10:97:52:49:88`) and Release SHA-1 (`1C:67:C2:E9:48:5E:5B:70:8D:5F:DF:9D:65:03:FD:38:6C:C6:55:40`) are added to Firebase Console under `com.foam.foam_mobile`. |
| `Apple Sign-In is only available on iOS devices` | Expected behavior on Android | Native Apple Sign-In requires Apple operating system capabilities. On Android, users are cleanly instructed to use Google or Email. |
| `Unable to load asset: "AssetManifest.json"` | Google Fonts network fallback issue | Resolved by bundling local DM Sans TTF fonts in `assets/fonts/` and `assets/google_fonts/`. |
