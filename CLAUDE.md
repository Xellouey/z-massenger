# CLAUDE.md
# Debugging and Error Analysis Protocol

## CRITICAL RULE: Analysis-First Approach

When investigating bugs or errors, you MUST follow this strict sequence:

### Phase 1: Investigation (NO CODE CHANGES)
1. **Read, Don't Preview**: Always read files completely, never use `head` or partial reads
2. **Breadth-First Search**: Find ALL related files before diving deep
3. **Dependency Mapping**: Trace all imports, exports, and function calls
4. **Historical Context**: Check git history for recent changes in affected areas
5. **Test Coverage**: Review existing tests related to the error

### Phase 2: Hypothesis Generation
- Generate minimum 7-10 hypotheses about root causes
- Use "5 Whys" technique for each hypothesis
- Document evidence for and against each hypothesis
- Create a scratchpad document to track reasoning

### Phase 3: Root Cause Analysis
- Systematically evaluate each hypothesis
- Use process of elimination with evidence from code
- Distinguish between symptoms and actual root causes
- Identify patterns across multiple files

### Phase 4: Impact Assessment
- Map all affected components
- Identify potential side effects of changes
- Check for similar issues elsewhere in codebase
- Document edge cases and potential regressions

### Phase 5: Report Creation
Create a comprehensive analysis document before ANY code changes:
- ERROR_ANALYSIS.md with complete findings
- COMPONENT_MAP.md showing relationships
- ROOT_CAUSE.md with justification
- RECOMMENDATIONS.md with approach (not implementation)

## Workflow Commands
When I say "Analyze this error", follow the complete protocol above.
When I say "Now fix it", ONLY THEN proceed with implementation.

## Anti-Patterns to Avoid
- ❌ Don't jump to solutions after finding first issue
- ❌ Don't preview files - read them completely
- ❌ Don't assume one fix solves all problems
- ❌ Don't make changes without full impact assessment
- ❌ Don't skip documentation of findings

## Code Reading Strategy
When exploring codebase:
1. Start with the error stack trace
2. Read each file in the trace completely
3. Find all imports/dependencies
4. Read those files completely too
5. Build mental model before proposing changes

## Documentation Requirements
Every debugging session must produce:
- Detailed analysis document
- Component relationship diagram (text-based)
- List of all hypotheses considered
- Evidence for root cause determination
- Risk assessment for potential fixes

## Response Format for Bugs
When I report a bug, structure your response as:

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Z (Chatzy)** is a Flutter-based real-time messaging application with comprehensive communication features including:
- One-on-one and group chats
- Audio/video calls via Agora RTC Engine
- Status updates (stories)
- Broadcast messaging
- Media sharing (images, videos, audio, documents, location)
- 30+ language localization support
- Light/dark theme modes
- End-to-end encryption for messages

**Tech Stack:**
- **Frontend**: Flutter SDK 3.4.4+ (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage, Cloud Functions, Messaging, Remote Config, App Check)
- **Calls**: Agora RTC Engi'стойne
- **State Management**: GetX (primary) + Provider (specific features)
- **Local Storage**: GetStorage, SharedPreferences
- **In-App Purchases**: RevenueCat

## Development Commands

### Flutter Commands
```bash
flutter pub get              # Install dependencies
flutter run                  # Run app in debug mode
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
flutter test                 # Run tests
flutter analyze             # Analyze code for issues
```

### Firebase Functions
```bash
cd functions && npm install  # Install function dependencies
cd functions && npm run lint # Lint Cloud Functions code
cd functions && npm run serve # Serve functions locally
cd functions && npm run deploy # Deploy functions to Firebase
cd functions && npm run logs  # View function logs
```

## Architecture

### State Management
- **GetX**: Primary state management using `Get.put()` and `Get.find()` pattern
  - Global controllers: `appCtrl` (AppController) and `firebaseCtrl` (FirebaseCommonController)
  - Controllers auto-disposed when routes are popped
- **Provider**: Used for specific real-time features
  - `RecentChatController`: Manages chat list updates
  - `ContactProvider`: Handles contact synchronization
- **Controllers Organization** (`lib/controllers/`):
  ```
  controllers/
  ├── app_pages_controllers/    # Feature-specific controllers
  │   ├── audio_call_controller.dart
  │   ├── video_call_controller.dart
  │   ├── chat_controller.dart
  │   ├── group_chat_controller.dart
  │   ├── broadcast_chat_controller.dart
  │   └── ...
  ├── auth_controllers/          # Authentication flows
  │   ├── login_controller.dart
  │   ├── profile_setup_controller.dart
  │   └── ...
  ├── bottom_controllers/        # Bottom navigation tabs
  │   ├── dashboard_controller.dart
  │   ├── chat_controller.dart
  │   ├── status_controller.dart
  │   └── ...
  └── common_controllers/        # Shared global controllers
      ├── app_controller.dart
      ├── firebase_common_controller.dart
      ├── notification_controller.dart
      └── contact_controller.dart
  ```

### Core Configuration

#### Global Controllers (`lib/config.dart`)
- **appCtrl**: Main app controller with theme, storage, and app-wide state
- **firebaseCtrl**: Firebase operations, user data, Firestore listeners
- **Access Pattern**:
  ```dart
  appCtrl.storage.write('key', value);  // Local storage
  appCtrl.appTheme.primary;             // Theme colors
  firebaseCtrl.currentUser;             // Current user data
  ```

#### Session Management (`lib/common/session.dart`)
Centralized session keys for GetStorage:
- `id`, `user`, `isLogin`, `languageCode`, `isDarkMode`
- `contactList`, `agoraToken`, `isBiometric`, etc.

#### Firebase Collections (`lib/common/collection_name.dart`)
Centralized Firestore collection names:
- `users`, `chats`, `groups`, `broadcast`, `status`
- `calls`, `messages`, `groupMessage`, `broadcastMessage`
- `userContact`, `config`, `usageControls`, etc.

### Navigation & Routing

Uses GetX navigation with routes in `lib/routes/`:
- **route_name.dart**: Route string constants
- **screen_list.dart**: Maps routes to screen widgets
- **route_method.dart**: Navigation helper methods
- **Access**: `Get.toNamed(routeName.dashboard)`

### Project Structure

```
lib/
├── common/                    # Shared resources
│   ├── assets/                # Asset path constants (images, SVGs, GIFs)
│   ├── extension/             # Dart extensions
│   │   ├── text_style_extensions.dart
│   │   ├── widget_extension.dart
│   │   └── spacing.dart
│   ├── languages/             # 37 language files (en, ru, ar, hi, fr, etc.)
│   │   └── index.dart         # Language class with all translations
│   └── theme/                 # Theme configuration
│       ├── app_theme.dart     # Light/dark theme definitions
│       └── app_color.dart     # Color constants
├── controllers/               # Business logic (see State Management)
├── models/                    # Data models
│   ├── chat_model.dart
│   ├── message_model.dart
│   ├── contact_model.dart
│   ├── call_model.dart
│   ├── status_model.dart
│   ├── user_setting_model.dart
│   └── ...
├── routes/                    # Navigation configuration
├── screens/                   # UI screens
│   ├── app_screens/           # Main app features (42 screen directories)
│   │   ├── chat_message/
│   │   ├── group_message_screen/
│   │   ├── broadcast_chat/
│   │   ├── audio_call/
│   │   ├── video_call/
│   │   ├── pick_up_call/
│   │   ├── select_contact_screen/
│   │   ├── new_contact/
│   │   ├── language_screen/
│   │   ├── wallpaper_screen/
│   │   └── ...
│   ├── auth_screens/          # Authentication flows
│   │   ├── splash_screen/
│   │   ├── on_boarding_screen/
│   │   ├── login_screen/
│   │   ├── profile_setup_screen/
│   │   └── ...
│   └── bottom_screens/        # Bottom navigation tabs
│       ├── dashboard/
│       ├── chat/
│       ├── status/
│       └── ...
├── utils/                     # Utility functions
│   ├── alert_utils.dart       # Alert dialogs
│   ├── general_utils.dart     # General helpers
│   ├── snack_and_dialogs_utils.dart
│   ├── extensions.dart        # Utility extensions
│   ├── broadcast_class.dart   # Broadcast utilities
│   └── type_list.dart         # Message type constants
├── widgets/                   # Reusable UI components (41 widget files)
│   ├── button_common.dart
│   ├── text_field_common.dart
│   ├── alert_message_common.dart
│   ├── reaction_pop_up/       # Message reaction UI
│   └── ...
├── config.dart                # Global configuration & exports
└── main.dart                  # App entry point
```

### Firebase Integration

#### Authentication
- Firebase Auth with phone number verification
- SMS OTP verification flow
- Session persistence with GetStorage

#### Database (Firestore)
- Real-time data synchronization
- Collections organized by feature (see `collection_name.dart`)
- Compound queries for chat/message retrieval
- **Important**: Always check if listeners exist before adding new ones to avoid memory leaks

#### Storage
- Firebase Storage for media files
- Images, videos, audio messages, documents
- Automatic compression for images (flutter_luban) and videos (video_compress)

#### Cloud Functions (`functions/index.js`)
- **generateTokenV2**: Creates Agora RTC tokens and channel names for calls
  - App ID: `d7b6e7512bc4457cab529f7780ff0294`
  - Automatically generates random channel names
  - Returns token + channelName for call sessions

#### Firebase Messaging (FCM)
- Push notifications with custom sounds
  - `message.mp3` for new messages
  - `callsound.mp3` for incoming calls
- Notification channel: "Astrologically Partner local notifications"
- Background message handler: `_firebaseMessagingBackgroundHandler` in `main.dart`

#### Firebase App Check
- Security feature to prevent unauthorized API access
- Debug mode for development (logs debug token)
- Production uses Play Integrity (Android) / App Attest (iOS)
- Initialized in `main.dart` before other Firebase services

#### Remote Config
- Feature flags and dynamic configuration
- Usage controls and app settings fetched at startup

### Key Features & Implementation

#### Messaging System
- **One-on-one chats**: Real-time message sync via Firestore
- **Groups**: Multi-participant chats with admin controls
- **Broadcasts**: One-to-many messaging
- **Message Types**:
  - Text (with emoji support via `emoji_picker_flutter`)
  - Images (with cropping via `image_cropper`)
  - Videos (compressed via `video_compress`)
  - Audio (recorded via `flutter_sound`)
  - Documents (opened via `open_filex`)
  - Location (via `geolocator`)
  - GIFs (via `giphy_get`)
  - Contact cards
- **Features**:
  - Message reactions
  - Reply/Forward
  - Delete for me/everyone
  - Swipe to reply (via `swipe_to`)
  - Link previews (via `any_link_preview`)
  - Typing indicators
  - Message encryption (AES-256, key in `main.dart`)

#### Audio/Video Calls
- **Agora RTC Engine** (`agora_rtc_engine` v6.5.0)
- Token generated via Firebase Cloud Function
- Features:
  - Audio-only calls
  - Video calls with camera switching
  - Speaker/mute controls
  - Call history tracking
  - Wakelock during calls (via `wakelock_plus`)
- **Recent Optimization**: Call answer delay reduced from 15-20s to 5-8s
- **Controllers**:
  - `audio_call_controller.dart`: Manages audio call state
  - `video_call_controller.dart`: Manages video call state
  - Both handle Agora engine lifecycle, local/remote streams

#### Status/Stories
- 24-hour temporary status updates
- Image/video/text status
- View tracking
- Story viewer UI (via `story_view`)

#### Contacts
- Contact sync via `flutter_contacts` and `fast_contacts`
- Permission handling via `permission_handler`
- Registered/unregistered user detection
- Contact invite flow (share app link via `share_plus`)

#### Security
- **Encryption**: AES-256 encryption for messages
  - Key: `MyZ32lengthENCRYPTKEY12345678901` (in `main.dart:19`)
  - Uses `encrypt` package
- **Biometric Auth**: Local authentication via `local_auth`
- **Firebase App Check**: Prevents unauthorized API access
- **Permissions**: Granular permission requests (camera, mic, storage, contacts, location)

#### Localization
- **37 languages supported** via GetX translations
- Languages include: English, Russian, Arabic, Hindi, French, Spanish, German, Chinese, Japanese, and 28+ more
- RTL support for Arabic, Hebrew
- Default locale: Russian (`ru_RU`)
- Translation files in `lib/common/languages/`
- Change language: Updates persist via GetStorage

#### Theming
- Light and dark modes
- Theme toggle persists in GetStorage
- Custom color scheme via `app_theme.dart`
- Google Fonts integration

#### Media Handling
- **Images**:
  - Pick via `image_picker`
  - Crop via `image_cropper`
  - Compress via `flutter_luban`
  - Cache via `cached_network_image`
  - View via `photo_view`
  - Save to gallery via `saver_gallery`
- **Videos**:
  - Pick via `file_picker` or `image_picker`
  - Compress via `light_compressor` or `video_compress`
  - Play via `video_player`
  - Progress bar via `audio_video_progress_bar`
- **Audio**:
  - Record via `flutter_sound`
  - Play via `audioplayers`
  - Waveform visualization

## Recent Improvements & Bug Fixes

Based on recent commits, the following issues have been addressed:

### Memory Management (Critical Fix - Commit 43c8b10)
- **Fixed memory leaks** in Firebase listeners and event subscriptions
- Controllers now properly dispose of Firestore stream subscriptions
- **Best Practice**: Always store listener subscriptions and cancel them in `onClose()` or `dispose()`
  ```dart
  // Good pattern:
  StreamSubscription? _chatListener;

  void listenToChats() {
    _chatListener = FirebaseFirestore.instance
      .collection('chats')
      .snapshots()
      .listen((snapshot) { /* ... */ });
  }

  @override
  void onClose() {
    _chatListener?.cancel();
    super.onClose();
  }
  ```

### Call System Improvements
- **Optimized call answer delay**: Reduced from 15-20 seconds to 5-8 seconds
- **Fixed self-call bug**: Users can no longer call themselves
- **Fixed video call disconnect issue**: Remote user hang-up now properly handled
- **Fixed call end state handling**: Proper cleanup after call termination
- **Added vibration on incoming calls**: Better user feedback

### UI/UX Fixes
- **Fixed contact list display**: Contacts refresh properly after updates
- **Fixed bottom overflow in clear chat modals**: Layout issues resolved
- **Fixed black screen logo issue**: Splash screen rendering corrected
- **Fixed chat clear modal**: Modal properly displays and functions
- **Improved Russian translations**: "Призвание" → "Вызов", "Недавнее обновление" → "Истории"

### Feature Additions
- **Delete chat feature**: Single and group chats can now be deleted
- **Automatic contact refresh**: Contacts auto-update when opening selection screen
- **Real-time user status updates**: Online/offline status syncs properly

## Development Best Practices

### Memory Management
1. **Always dispose of listeners**: Cancel Firebase stream subscriptions, Agora engine listeners
2. **Use GetX lifecycle**: Override `onClose()` in GetX controllers for cleanup
3. **Check before adding listeners**: Avoid duplicate listeners on the same stream
4. **Dispose media players**: Audio/video players must be disposed when done

### Firebase Operations
1. **Batch operations**: Use Firestore batch writes for multiple updates
2. **Optimize queries**: Use `.limit()` and pagination for large datasets
3. **Handle offline mode**: Check connectivity via `connectivity_plus` before Firebase operations
4. **Error handling**: Always wrap Firebase calls in try-catch blocks
5. **Duplicate config**: Firebase options in `main.dart` must match in:
   - Platform initialization (lines 26-44)
   - Background message handler (requires separate init)

### Call System
1. **Token management**: Always fetch fresh Agora token from Cloud Function
2. **Engine lifecycle**: Initialize Agora engine before join, destroy after leave
3. **Permission checks**: Request camera/mic permissions before starting call
4. **Network handling**: Handle poor network conditions gracefully
5. **Cleanup**: Always leave channel and destroy engine on call end

### State Management
1. **Global controllers**: Use `appCtrl` and `firebaseCtrl` for app-wide state
2. **Local controllers**: Create dedicated controllers for complex features
3. **Avoid over-fetching**: Don't re-fetch data that's already in controller state
4. **Update UI reactively**: Use `.obs` and `Obx()` for reactive updates
5. **Controller scope**: Put controllers at appropriate scope (global vs route-scoped)

### UI Development
1. **Test both themes**: Always verify changes in light and dark modes
2. **Test RTL languages**: Verify layout with Arabic/Hebrew
3. **Text scaling**: App enforces 1.0 text scale factor (see `main.dart:120-125`)
4. **Responsive design**: Use `MediaQuery` for different screen sizes
5. **Asset organization**: Use centralized asset paths from `lib/common/assets/`

### Testing Checklist
Before committing changes, verify:
- [ ] Light and dark themes work correctly
- [ ] RTL languages (Arabic, Hebrew) display properly
- [ ] Firebase real-time updates function correctly
- [ ] Notifications work in foreground/background/terminated states
- [ ] No memory leaks (check listener disposal)
- [ ] Call system works (audio, video, disconnect)
- [ ] Offline mode handles gracefully
- [ ] Media files compress and upload correctly
- [ ] Permissions requested at appropriate times
- [ ] No hardcoded strings (use translations)

## Common Pitfalls to Avoid

### Firebase Listeners
❌ **Don't**: Create listeners without cleanup
```dart
FirebaseFirestore.instance.collection('chats').snapshots().listen((data) {
  // This listener never gets cancelled - MEMORY LEAK!
});
```

✅ **Do**: Store and cancel listeners
```dart
StreamSubscription? _subscription;

void init() {
  _subscription = FirebaseFirestore.instance
    .collection('chats').snapshots().listen((data) { /* ... */ });
}

@override
void onClose() {
  _subscription?.cancel();
  super.onClose();
}
```

### Agora Calls
❌ **Don't**: Reuse old tokens or channel names
❌ **Don't**: Forget to destroy engine after call ends
❌ **Don't**: Allow users to call themselves

✅ **Do**: Generate fresh token for each call
✅ **Do**: Properly cleanup Agora resources
✅ **Do**: Validate recipient before initiating call

### GetX Controllers
❌ **Don't**: Use `Get.put()` multiple times for the same controller
❌ **Don't**: Forget to use `.obs` for reactive variables

✅ **Do**: Check with `Get.isRegistered<Controller>()` before `Get.put()`
✅ **Do**: Use `.obs` for all reactive state variables

### File Operations
❌ **Don't**: Upload original large files (videos/images)
❌ **Don't**: Forget to request permissions before file access

✅ **Do**: Compress media before upload
✅ **Do**: Request permissions first, handle denials gracefully

## Important Notes

### Configuration Files
- **main.dart**:
  - Line 19: Encryption key for messages
  - Lines 26-44: Firebase options (duplicate for iOS/Android)
  - Lines 80: Background message handler registration
  - Line 129: Default locale set to Russian
- **config.dart**: Global controllers and exports
- **pubspec.yaml**: App name is "chatzy", version 1.0.0+1

### Permissions Required
- Camera (video calls, image capture)
- Microphone (audio/video calls, audio messages)
- Storage (media save/load)
- Contacts (contact sync)
- Location (location sharing)
- Notifications (FCM)

### Orientation Lock
App is locked to portrait mode only:
- `DeviceOrientation.portraitUp`
- `DeviceOrientation.portraitDown`

### Assets Organization
```
assets/
├── images/       # PNG, JPG images
├── svg/          # SVG vector graphics
└── gif/          # Animated GIFs
```
Asset paths centralized in `lib/common/assets/`

### Dependencies of Note
- **GetX** (v4.7.2): State management, routing, translations
- **Firebase** (v3.12.1+): Backend infrastructure
- **Agora RTC** (v6.5.0): Audio/video calling
- **Image Cropper** (v9.0.0): Image editing
- **Video Compress** (v3.1.4): Video compression
- **Flutter Sound** (v9.27.0): Audio recording
- **RevenueCat** (v8.6.1): In-app purchases/subscriptions
- **CameraX** (v0.6.14+1): Enhanced camera on Android

### Project Metadata
- **Package Name**: `chatzy`
- **Display Name**: `Z`
- **Firebase Project**: `z-messenger-bc7fd`
- **SDK**: Dart >=3.4.4 <4.0.0
- **Version**: 1.0.0+1
- **Platforms**: Android, iOS

## Troubleshooting

### Call Issues
1. **Long answer delay**: Ensure Cloud Function deploys properly, check Agora token generation
2. **Black screen**: Verify camera permissions, check Agora engine initialization
3. **No disconnect**: Ensure proper listener cleanup in call controllers

### Firebase Issues
1. **Data not syncing**: Check Firestore rules, verify network connectivity
2. **Auth failures**: Verify Firebase config matches console settings
3. **App Check errors**: Add debug token to Firebase console in debug mode

### Build Issues
1. **Android build fails**: Check Gradle versions, verify Firebase config
2. **iOS build fails**: Run `pod install`, check Info.plist permissions
3. **Dependency conflicts**: Check `dependency_overrides` in pubspec.yaml

### Memory Issues
1. **App crashes**: Check for uncancelled listeners, dispose media players
2. **Slow performance**: Profile app, look for memory leaks in DevTools
3. **Growing memory**: Audit Firebase listeners, check image caching

## Additional Resources

- **Flutter Docs**: https://docs.flutter.dev
- **GetX Docs**: https://pub.dev/packages/get
- **Firebase Docs**: https://firebase.google.com/docs
- **Agora Docs**: https://docs.agora.io/en/video-calling
- **RevenueCat Docs**: https://www.revenuecat.com/docs

---

**Last Updated**: November 2024
**Maintained By**: Development Team
**For Questions**: Review recent commits and PR history for context on changes
