# 🚀 Quick Start Guide - Firebase Setup

## 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

## 2. Configure Firebase
```bash
cd "g:\Sites e Apps\poker"
flutterfire configure
```

Follow the prompts:
- Select existing Firebase project or create new one
- Choose platforms (Android, iOS, Web, etc.)
- CLI will generate `firebase_options.dart` automatically

## 3. Initialize Firebase in main.dart

Update your [main.dart](lib/main.dart) file:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## 4. Configure Firestore Security Rules

In Firebase Console (https://console.firebase.google.com):

1. Go to **Firestore Database** > **Rules**
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Game sessions - all authenticated users can read/write
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }
    
    // User achievements subcollection
    match /users/{userId}/achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish**

## 5. Enable Email/Password Authentication

In Firebase Console:
1. Go to **Authentication** > **Sign-in method**
2. Click **Email/Password**
3. Toggle **Enable**
4. Click **Save**

## 6. Test the App

```bash
flutter run
```

### Test Scenarios:

1. **Sign Up**
   - Create new account with email/password
   - User document should be created in Firestore

2. **Sign In**
   - Login with created credentials
   - Should navigate to home screen

3. **Auto-Login**
   - Close and reopen app
   - Should stay logged in

4. **Profile Update**
   - Go to profile screen
   - Update name
   - Changes should sync to Firestore

5. **Rankings**
   - Check ranking screen
   - Should show real-time data from Firestore

## 7. Verify Firestore Data

In Firebase Console:
1. Go to **Firestore Database** > **Data**
2. You should see:
   - `users` collection with your user document
   - `sessions` collection (after creating a game)

## 🔍 Troubleshooting

### Error: "No Firebase App"
- Make sure `Firebase.initializeApp()` is called in `main()`
- Check `firebase_options.dart` exists

### Error: "PERMISSION_DENIED"
- Check Firestore security rules are configured
- Verify user is authenticated

### Error: "Email already in use"
- Normal behavior when trying to register with existing email
- Try different email or sign in instead

## 📱 Platform-Specific Setup

### Android
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Already configured in `android/app/build.gradle`

### iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/` directory
3. Open Xcode and add to project

### Web
1. Firebase config is in `firebase_options.dart`
2. Already configured automatically by FlutterFire CLI

## 🎯 What Works Now

✅ User registration with email/password  
✅ User login with Firebase Auth  
✅ Auto-login on app restart  
✅ Password reset email  
✅ Profile updates synced to Firestore  
✅ XP distribution after games  
✅ Real-time rankings  
✅ Game session creation in Firestore  
✅ Real-time game updates via Firestore streams  

## ⚠️ Known Limitations

- Email verification not enforced (can be added)
- No profile picture upload yet (can add Firebase Storage)
- No push notifications (can add FCM)

## 🆘 Need Help?

Check these resources:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)

## ✅ You're All Set!

Your poker app is now running on Firebase! 🎉

Test the authentication flow, create some games, and watch the real-time updates in action.
