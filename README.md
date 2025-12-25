# child_track

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Cloud Messaging Setup

This project uses Firebase Cloud Messaging (FCM) for push notifications. Follow these steps to set up Firebase:

### Setup Steps (Using Firebase Console - Recommended)

1. **Create a Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" or select an existing project
   - Follow the setup wizard

2. **Add Android App to Firebase**:
   - In your Firebase project, click the Android icon (or "Add app")
   - Package name: `com.example.child_track` (must match your `applicationId` in `android/app/build.gradle.kts`)
   - App nickname: `Child Track Android` (optional)
   - Register app
   - Download `google-services.json`
   - Place the file in `android/app/` directory

3. **Add iOS App to Firebase**:
   - In your Firebase project, click the iOS icon (or "Add app")
   - Bundle ID: `com.example.child_track` (must match your bundle identifier)
   - App nickname: `Child Track iOS` (optional)
   - Register app
   - Download `GoogleService-Info.plist`
   - Place the file in `ios/Runner/` directory

4. **Enable Cloud Messaging**:
   - In Firebase Console, go to **Project Settings** > **Cloud Messaging**
   - Ensure Cloud Messaging API is enabled

5. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

6. **For iOS, install pods**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Alternative: Using Firebase CLI (Optional)

If you prefer using CLI, first install Node.js and npm:
- **macOS**: `brew install node` or download from [nodejs.org](https://nodejs.org/)
- Then install Firebase CLI: `npm install -g firebase-tools`
- Login: `firebase login`

### Using Firebase Notification Service

The `FirebaseNotificationService` is already initialized in `main.dart`. You can access it anywhere in your app:

```dart
final notificationService = injector<FirebaseNotificationService>();

// Get FCM token
String? token = notificationService.fcmToken;

// Listen to foreground messages
notificationService.messageStream.listen((message) {
  print('Foreground message: ${message.notification?.title}');
});

// Listen to notification taps
notificationService.notificationTapStream.listen((message) {
  // Handle navigation or other actions
  print('Notification tapped: ${message.data}');
});

// Subscribe to a topic
await notificationService.subscribeToTopic('all_users');

// Unsubscribe from a topic
await notificationService.unsubscribeFromTopic('all_users');
```

### Notification Handling

- **Foreground**: Messages are handled automatically and added to `messageStream`
- **Background**: Messages are handled by `firebaseMessagingBackgroundHandler` (top-level function)
- **Terminated**: Messages are handled when app is opened from notification tap

### Testing Notifications

You can test notifications using:
1. **Firebase Console** (Recommended):
   - Go to Firebase Console > **Cloud Messaging** > **Send test message**
   - Enter your FCM token (get it from the app logs or `notificationService.fcmToken`)
   - Send a test notification

2. **Using cURL** (Alternative):
   ```bash
   curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "message": {
         "token": "FCM_TOKEN",
         "notification": {
           "title": "Test Notification",
           "body": "This is a test message"
         }
       }
     }'
   ```

### Important Notes

- Make sure `google-services.json` is in `android/app/` (not `android/`)
- Make sure `GoogleService-Info.plist` is in `ios/Runner/` (not `ios/`)
- The package name/bundle ID must match exactly between Firebase and your app
- For iOS, you may need to configure APNs certificates in Firebase Console if you want to send notifications to production builds
