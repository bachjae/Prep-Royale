# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Flutter (Mobile App)
```bash
flutter pub get                        # Install dependencies
flutter run                            # Run on connected device/emulator
flutter build apk --release            # Build Android APK
flutter build ios --release            # Build iOS release
flutter test                           # Run tests
flutter test test/widget_test.dart     # Run single test file
flutter test --coverage                # Run with coverage report
dart analyze                           # Run static analysis
dart format .                          # Format all Dart code
dart run build_runner build            # Regenerate Riverpod/JSON code (after model changes)
dart run build_runner watch            # Watch mode for code generation
```

### Cloud Functions
```bash
cd functions
npm install                            # Install dependencies
npm run build                          # Compile TypeScript
npm run build:watch                    # Watch mode for TypeScript
npm run serve                          # Build + run emulators locally
npm run logs                           # View function logs (shortcut)
firebase deploy --only functions       # Deploy functions
```

**Requirements:** Node.js 18

### Firebase
```bash
firebase deploy                        # Deploy all (functions, rules, indexes)
firebase deploy --only firestore:rules # Deploy Firestore rules only
firebase deploy --only database        # Deploy Realtime DB rules only
firebase emulators:start               # Run local emulators
```

## Architecture

### Stack
- **Flutter** (Dart SDK >=3.2.0) with Riverpod state management and go_router navigation
- **Firebase**: Auth, Firestore (persistent data), Realtime Database (live battles), Storage, Cloud Functions
- **AI**: Google Gemini (Vertex AI) for question generation (server-side only, in Cloud Functions)
- **Monetization**: Google Mobile Ads (`google_mobile_ads` package)

### Project Layout
- `lib/` — Flutter app source
  - `config/` — Firebase options, GoRouter, AppTheme
  - `models/` — Data models with Firestore serialization
  - `providers/` — Riverpod providers and controllers
  - `services/` — Firebase service wrappers (including `ad_service.dart` for ads)
  - `screens/` — UI organized by feature (`auth/`, `home/`, `study/`, `battle/`, `profile/`, `leaderboard/`, `onboarding/`, `settings/`)
  - `widgets/common/` — Reusable UI components
- `assets/avatars/` — Preset avatar images
- `functions/src/` — Cloud Functions (TypeScript)
  - `index.ts` — Entry point, exports all functions
  - `batch/dailyGenerator.ts` — Scheduled question generation logic
  - `config/questionConfig.ts` — Canonical skill definitions for SAT/ACT
  - `utils/geminiHelper.ts` — Gemini API integration for question generation
  - `utils/validation.ts` — Question deduplication and Firestore writes
- `firestore.rules`, `database.rules.json` — Security rules

### State Management Pattern
Riverpod is used throughout. The pattern is:
- `StreamProvider` for real-time Firebase listeners (user data, auth state)
- `StateNotifierProvider` / `NotifierProvider` for controllers with business logic
- Controllers (e.g., `AuthController`) encapsulate write operations; providers expose read streams

### Data Flow
- **Firestore**: Users, questions, achievements, leaderboard entries, battle results (persistent)
- **Realtime Database**: Active battle state (`/battles/{battleId}`) and matchmaking queue (`/matchmaking/{userId}`) — used for low-latency live updates
- **Cloud Functions**: All writes to questions, leaderboard, battle results, and XP/level updates go through functions to enforce server-side logic

### Key Models
- `UserModel` — Profile, progress (level/xp), stats (section accuracy), streaks (daily + accuracy), battle stats, achievements. Must include `usernameLower` field (lowercase username) for search functionality.
- `QuestionModel` — SAT/ACT questions with `examType`, `section`, `skill`, `difficulty` (1–5), 4 choices, `correctAnswer` index (0–3), `explanation`, and `contentHash` (deduplication)
- Battle state lives in Realtime DB; `battleResults` collection in Firestore stores final outcomes

### Question Configuration
Skills are defined in `functions/src/config/questionConfig.ts`. Each exam type (SAT/ACT) has sections with specific skills and target question counts per skill. The daily generator uses these to maintain question inventory.

### XP & Leveling
XP threshold for level N: `100 * N * N` (quadratic). `addXp()` in `firebase_service.dart` uses a Firestore transaction.

### Battle System
- **Health-based**: Players start with 100 HP; correct answers deal damage to opponent, wrong answers deal self-damage
- **20 questions** per battle with 30-second time limit per question
- **Matchmaking**: Players matched within ±3 levels and same test type (SAT/ACT)
- Battle ends when either player's health reaches 0 or all questions answered
- **Damage calculation** (server-side in `submitBattleAnswer`):
  - Correct answer: 15 damage (≤15s), 12 damage (≤30s), 10 damage (>30s)
  - Wrong answer: 8 self-damage
  - Timeout: 15 self-damage

### Cloud Functions Overview (`functions/src/index.ts`)

**Question Generation:**
- `dailyQuestionGeneration` — Scheduled (3 AM UTC), batch generates questions for low-inventory skills via Gemini
- `manualGenerateQuestions` / `manualDailyGeneration` — Admin callables for on-demand generation
- `getQuestionStats` — Returns question counts by exam type and section

**Battle & Matchmaking:**
- `joinMatchmaking` / `leaveMatchmaking` — Realtime DB queue; creates battle doc on match
- `submitBattleAnswer` — Server-side answer validation and damage calculation; auto-completes battle when health depleted or 20 questions done
- `cleanupStaleMatchmaking` — Scheduled (every 5 min), removes users in queue > 5 minutes
- `cleanupOldBattles` — Scheduled (4 AM UTC), removes completed/abandoned battles > 24 hours old

**Friends System:**
- `sendFriendRequest` — Creates pending friendship (normalized by alphabetically-sorted user IDs)
- `respondToFriendRequest` — Accept or decline pending request
- `removeFriend` — Delete friendship
- `searchUsers` — Prefix search on `usernameLower` field (requires users to have this field)
- `getFriendsLeaderboard` — Returns leaderboard filtered to user's friends

**Leaderboard & Data:**
- `updateLeaderboard` — Firestore trigger on user XP change
- `getRandomTip` — Returns random widget tip
- `seedWidgetTips` / `seedAchievements` — HTTP endpoints to populate initial data

### Friends System
Friendships are stored in the `friendships` collection with normalized user IDs (alphabetically sorted to prevent duplicates). Status can be `pending`, `accepted`, or `blocked`. The `requesterId` field tracks who initiated the request.

### Router Guards
`lib/config/router.dart` redirects unauthenticated users to `/login`. After signup, users go through `/profile-picture` before reaching `/` (home).

### Firebase Project
Project ID: `sat-act-battle-royale` (see `.firebaserc` and `lib/config/firebase_config.dart`)

### Testing
Test infrastructure includes mocking libraries: `mocktail`, `fake_cloud_firestore`, `firebase_auth_mocks`. Run unit/widget tests with `flutter test`. For emulator testing, start Firebase emulators first with `firebase emulators:start`.

## Security & Production Readiness

### Security Fixes Applied (Pre-Launch)

**Critical Fixes Completed:**
1. ✅ Firestore questions collection is read-only for clients (`firestore.rules:49`)
2. ✅ Server-side XP/level validation prevents manipulation (`firestore.rules:27-30`)
3. ✅ Realtime Database battle creation restricted to participants (`database.rules.json:12-15`)
4. ✅ Account deletion function for GDPR compliance (`functions/src/index.ts:2194-2342`)
5. ✅ Password reset flow in login screen
6. ✅ Matchmaking rate limiting (20 requests/5 min)
7. ✅ Battle answer timing validation (30-second limit enforced)
8. ✅ Battle timeout handling (auto-abandon after 1 hour)
9. ✅ Firestore rules for matchmakingLogs and notificationLogs

**Protected Server-Side Fields:**
Users cannot modify: `totalXp`, `level`, `battleStats`, `unlockedAchievements`, `friendCode`

**Rate Limits:**
- Friend requests: 10 per hour
- Matchmaking joins: 20 per 5 minutes
- Battle answers: 30-second time limit enforced server-side

**Account Management:**
- Delete account: Call `deleteUserAccount` Cloud Function
- Password reset: Available on login screen
- Deletion removes: profile, friendships, battles, answers, leaderboard, notifications, auth account

### Pre-Launch Checklist

**Must Complete Before Launch:**
- [ ] Create Privacy Policy (host at your domain)
- [ ] Create Terms of Service (host at your domain)
- [ ] Add legal links to login/signup screens
- [ ] Create settings screen with "Delete Account" option
- [ ] Deploy security rules: `firebase deploy --only firestore:rules,database`
- [ ] Deploy Cloud Functions: `firebase deploy --only functions`
- [ ] Test account deletion flow
- [ ] Test rate limiting on matchmaking
- [ ] Replace AdMob test App ID (when implementing ads)

**Recommended Before Launch:**
- [ ] Add offline mode handling with connectivity checks
- [ ] Initialize notifications in auth flow
- [ ] Add loading states to critical flows
- [ ] Add back button confirmation for active battles
- [ ] Set up error tracking (Firebase Crashlytics)
- [ ] Test on multiple Android devices/versions

**Legal Requirements:**
- Privacy Policy must include: data collection, usage, third-parties (Firebase/AdMob), user rights
- Terms of Service must include: age requirements, prohibited conduct, liability limits
- Both must be accessible from app (links in auth screens and settings)

### Known Limitations & Future Improvements

1. **Email Privacy**: User emails stored in public Firestore documents (don't display in UI)
2. **Time Zones**: Daily reminders use simplified UTC approach
3. **Data Export**: Not yet implemented (GDPR requirement for some regions)
4. **Offline Mode**: Limited offline functionality
5. **iOS Notifications**: Not yet implemented (Android-only currently)

See `SECURITY_FIXES_APPLIED.md` for detailed security audit and remaining non-critical tasks.

## Notifications System

### Overview
The app uses **Firebase Cloud Messaging (FCM)** for push notifications. Notifications are push-only (no in-app notification inbox) and support Android.

### Notification Types

**Priority 1 (Implemented):**
- **Friend Request** — When someone sends you a friend request
- **Friend Request Accepted** — When someone accepts your friend request
- **Friend Battle Invite** — When a friend challenges you to a battle
- **Streak Warning** — Daily reminder if you haven't studied and have an active streak
- **Daily Study Reminder** — Daily reminder at user's preferred time (default 2 PM UTC)

**Priority 2 (Future):**
- **Achievement Unlocked** — When you earn a new achievement
- **Leaderboard Position Change** — When your ranking improves significantly

**Priority 3 (Future):**
- **Battle Result** — Win/loss summary after battle completion
- **XP/Level Up** — When you level up

### Architecture

#### Client-Side (Flutter)
- **Package**: `firebase_messaging: ^15.0.0`
- **Service**: `lib/services/notification_service.dart`
  - Handles FCM token registration and refresh
  - Requests Android notification permissions
  - Saves FCM token to Firestore (`users/{userId}/fcmToken`)
  - Processes foreground, background, and terminated state messages
  - Navigation routing based on notification type
- **Initialization**: FCM background handler registered in `main.dart`
- **Permissions**: `POST_NOTIFICATIONS` permission in `AndroidManifest.xml` (Android 13+)

#### Server-Side (Cloud Functions)
- **Helper**: `functions/src/utils/notificationHelper.ts`
  - `sendNotification()` — Core function to send FCM messages
  - Type-specific helpers: `sendFriendRequestNotification()`, `sendBattleInviteNotification()`, etc.
  - Checks user FCM token and notification preferences before sending
  - Logs sent notifications to `notificationLogs` collection
  - Handles invalid token cleanup
- **Triggers**:
  - `sendFriendRequest` → Sends notification to recipient
  - `respondToFriendRequest` → Sends acceptance notification to requester
  - `createFriendBattle` → Sends battle invite to friend
  - `sendStreakWarnings` — Scheduled (11 PM UTC daily), checks users with active streaks who haven't studied
  - `sendDailyReminders` — Scheduled (2 PM UTC daily), sends reminders to users who haven't received one today

#### Data Models
**NotificationPreferences** (embedded in UserModel):
```dart
{
  dailyReminder: bool (default: true),
  friendRequests: bool (default: true),
  friendBattleInvites: bool (default: true),
  friendRequestAccepted: bool (default: true),
  streakWarnings: bool (default: true),
  achievementUnlocks: bool (default: true),
  leaderboardChanges: bool (default: true),
  dailyReminderTime: int (0-23, default: 14)
}
```

**Additional UserModel Fields**:
- `fcmToken: string?` — Firebase Cloud Messaging token
- `lastDailyReminderSent: Timestamp?` — Tracks when last daily reminder was sent

**NotificationLog** (Firestore collection):
```typescript
{
  userId: string,
  type: 'friend_request' | 'battle_invite' | 'friend_request_accepted' | 'streak_warning' | 'daily_reminder' | 'achievement' | 'leaderboard',
  title: string,
  body: string,
  metadata: object,
  sentAt: Timestamp
}
```

### User Flow

1. **On Login/Signup**:
   - App requests notification permissions (Android 13+)
   - FCM token is generated and saved to Firestore
   - Token auto-refreshes and updates in Firestore

2. **Receiving Notifications**:
   - **Foreground**: Notification shows in system tray (no custom handling)
   - **Background**: Notification shows in system tray; tapping opens app and routes to relevant screen
   - **Terminated**: Same as background

3. **Managing Preferences**:
   - Users can configure notification preferences in Settings > Notifications
   - Changes sync to Firestore immediately
   - Server checks preferences before sending each notification

### Settings UI
- **Screen**: `lib/screens/settings/notification_settings_screen.dart`
- Accessible from main settings screen
- Toggle switches for each notification type
- Time picker for daily reminder (hour selection)
- Real-time updates to Firestore

### Time Zone Handling
**Current Implementation**: Simplified approach for daily reminders
- Scheduled function runs at 2 PM UTC
- Sends to all users with `dailyReminderTime == 14` (UTC hour)
- Tracks `lastDailyReminderSent` to prevent duplicates

**Future Enhancement**: Store user time zone and calculate local reminder time

### Developer Guide: Working with Notifications

#### Adding a New Notification Type

1. **Define Type** in `functions/src/utils/notificationHelper.ts`:
   ```typescript
   export type NotificationType = "friend_request" | "new_type" | ...;
   ```

2. **Add Preference** to `NotificationPreferences` class in `lib/models/user_model.dart`:
   ```dart
   final bool newTypeEnabled;
   ```

3. **Create Helper Function** in `notificationHelper.ts`:
   ```typescript
   export async function sendNewTypeNotification(userId: string, ...params) {
     await sendNotification(userId, "Title", "Body", "new_type", { ...data });
   }
   ```

4. **Update Preference Check** in `isNotificationEnabled()` function

5. **Add UI Toggle** in `notification_settings_screen.dart`

6. **Trigger Notification** from appropriate Cloud Function

#### Testing Notifications Locally

1. **Start Firebase Emulators**:
   ```bash
   firebase emulators:start
   ```

2. **Run Flutter App** on physical Android device or emulator

3. **Trigger Notification** via Cloud Function call or scheduled trigger

4. **Check Logs**:
   ```bash
   cd functions
   npm run logs
   ```

5. **Verify FCM Token** is saved in Firestore `users/{userId}/fcmToken`

#### Common Issues

**No notifications received:**
- Check FCM token exists in Firestore
- Verify notification preferences are enabled for that type
- Check Cloud Functions logs for errors
- Ensure Android permissions granted (Settings > Apps > Prep Royale > Permissions > Notifications)

**Invalid token errors:**
- Tokens auto-refresh; old tokens are automatically cleared from Firestore
- User may need to re-login to generate new token

**Notifications not routing correctly:**
- Check `_handleNotificationTap()` in `notification_service.dart`
- Ensure `data.type` matches expected notification type
- Add TODO comments indicate navigation endpoints need implementation

### Firestore Security Rules
Notification preferences are part of user document; standard user rules apply:
- Users can read/write their own `notificationPreferences`
- `fcmToken` is write-only by authenticated user, read by server

### Future Enhancements
- iOS support (requires APNs configuration and iOS-specific setup)
- In-app notification inbox/history
- Notification batching (e.g., "3 new friend requests")
- Rich notifications with images and action buttons
- User-specific time zone support for daily reminders
- Notification delivery analytics
