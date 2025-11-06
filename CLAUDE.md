# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Z is a Flutter-based messaging application with real-time communication features including chat, audio/video calls, status updates, groups, and broadcasts. The app uses Firebase as its backend infrastructure (Firestore, Cloud Functions, Storage, Auth, Messaging) and integrates Agora for audio/video calling capabilities.

## Development Commands

### Flutter Commands
- **Install dependencies**: `flutter pub get`
- **Run app**: `flutter run`
- **Build for Android**: `flutter build apk`
- **Build for iOS**: `flutter build ios`
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`

### Firebase Functions
- **Install dependencies**: `cd functions && npm install`
- **Lint functions**: `cd functions && npm run lint`
- **Serve locally**: `cd functions && npm run serve`
- **Deploy functions**: `cd functions && npm run deploy`
- **View logs**: `cd functions && npm run logs`

## Architecture

### State Management
- **GetX**: Primary state management solution using `Get.put()` and `Get.find()` pattern
- **Provider**: Used for specific features like `RecentChatController` and `ContactProvider`
- **Controllers**: Organized in `lib/controllers/` with subdirectories:
  - `app_pages_controllers/`: Feature-specific controllers
  - `auth_controllers/`: Authentication flow controllers
  - `bottom_controllers/`: Bottom navigation controllers
  - `common_controllers/`: Shared controllers (`AppController`, `FirebaseCommonController`, `NotificationController`)

### Core Configuration
- **Global Controllers**: `appCtrl` and `firebaseCtrl` are initialized in `lib/config.dart` and available throughout the app
- **Storage**: Uses `get_storage` for local persistence via `appCtrl.storage`
- **Session**: Session keys defined in `lib/common/session.dart`
- **Collections**: Firebase collection names centralized in `lib/common/collection_name.dart`

### Navigation & Routing
- Uses GetX navigation with routes defined in `lib/routes/`:
  - `route_name.dart`: Route string constants
  - `screen_list.dart`: Maps routes to screens
  - `route_method.dart`: Navigation helper methods
- Access routes via `appRoute.getPages`

### Project Structure
```
lib/
├── common/              # Shared resources
│   ├── assets/          # Asset paths (images, SVGs, GIFs)
│   ├── extension/       # Dart extensions (text, widget, spacing)
│   ├── languages/       # 30+ language translations
│   └── theme/           # Theme configuration (light/dark modes)
├── controllers/         # Business logic
├── models/             # Data models
├── routes/             # Navigation configuration
├── screens/            # UI screens
│   ├── app_screens/    # Main app features
│   ├── auth_screens/   # Authentication flows
│   └── bottom_screens/ # Bottom nav screens
├── utils/              # Utility functions
├── widgets/            # Reusable UI components
├── config.dart         # Global configuration
└── main.dart           # App entry point
```

### Firebase Integration
- **Authentication**: Firebase Auth with phone number verification
- **Database**: Cloud Firestore for real-time data sync
- **Storage**: Firebase Storage for media files
- **Messaging**: FCM for push notifications with custom notification sounds
- **Functions**: Node.js Cloud Functions (generates Agora tokens for calls)
- **Remote Config**: Feature flags and configuration

### Key Features
- **Messaging**: One-on-one chats, groups, broadcasts with media support (images, videos, audio, documents)
- **Calls**: Audio/video calls via Agora RTC Engine
- **Status**: Stories/status updates
- **Media**: Image cropping, video compression, audio recording
- **Localization**: 30+ languages with GetX translations
- **Theme**: Light/dark mode with custom theme system
- **Security**: Encryption key stored in `main.dart` for message encryption
- **Permissions**: Camera, microphone, storage, location, contacts handling
- **Offline**: Local storage with GetStorage

## Important Notes

### Firebase Configuration
- Firebase options are duplicated in `main.dart` for Android/iOS and in `_firebaseMessagingBackgroundHandler` for background messaging
- Project ID: `z-messenger-bc7fd`
- When modifying Firebase config, update both locations

### Agora Integration
- Agora credentials are stored in `functions/index.js`
- The `generateTokenV2` Cloud Function creates channels and tokens for calls
- Agora RTC Engine initialized via `agora_rtc_engine` package

### Notification Handling
- Custom notification sounds: `message.mp3` for messages, `callsound.mp3` for calls
- Notification channel: "Astrologically Partner local notifications"
- Background handler requires Firebase initialization

### Orientation Lock
- App is locked to portrait mode only (`DeviceOrientation.portraitUp/portraitDown`)

### Assets Organization
- Images: `assets/images/`
- SVGs: `assets/svg/`
- GIFs: `assets/gif/`
- Asset paths centralized in `lib/common/assets/`

### Testing Changes
- Always test with both light and dark themes
- Verify localization across multiple languages (at minimum: English, Arabic for RTL)
- Test with different text scale factors (app enforces 1.0 scale factor)
- Verify Firebase realtime updates for chat/status features
- Test notification behavior in foreground/background/terminated states
