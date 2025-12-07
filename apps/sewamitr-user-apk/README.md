# SewaMitr - Civic Issue Reporting Platform

A Flutter mobile app for reporting and tracking civic issues with real-time updates, community engagement, and government integration.

## 🚀 Features

- 📧 Email/Password Authentication
- 🌍 Multi-language Support (English/Hindi)
- 📸 Issue Reporting with Photos & Audio
- 🗺️ OpenStreetMap Integration (No API Key Required)
- 📍 Location-based Issue Tracking
- 👥 Community Feed & One-Time Voting
- � Comment System with Real-time Updates
- 📤 Share Issues via Social Media
- �🔔 In-App Notifications for Progress Updates
- 🎯 Real-time Issue Status Updates
- 🏆 Gamification System
- 🔍 Multi-Filter Selection & Advanced Sorting

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Supabase (PostgreSQL, Storage, Auth)
- **Maps**: OpenStreetMap via flutter_map
- **State Management**: Provider
- **Security**: ProGuard, HTTPS enforcement, RLS policies

## 📋 Prerequisites

- Flutter SDK 3.0+
- Dart SDK
- Android Studio / VS Code
- Supabase Account 

## ⚡ Quick Setup

### 1. Clone & Install

```bash
git clone <repository-url>
cd sewamitr
flutter pub get
```

### 2. Setup Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Run SQL from `db.sql` file
3. Create storage bucket: "sewamitr" (public)
4. Copy Project URL and anon key

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 4. Run

```bash
flutter run
```

### 5. Build Optimized APK

```bash
flutter build apk --release --split-per-abi
```

APKs: `build/app/outputs/flutter-apk/`
- `app-armeabi-v7a-release.apk` (~18-22 MB)
- `app-arm64-v8a-release.apk` (~18-22 MB)
- `app-x86_64-release.apk` (~18-22 MB)

## 📁 Project Structure

```
lib/
├── models/              # Data models
│   ├── issue_model.dart
│   ├── user_model.dart
│   └── notification_model.dart
├── screens/             # UI screens
│   ├── auth/           # Login & Signup
│   ├── dashboard/      # Main app screens
│   └── profile/        # User profile
├── services/            # Business logic
│   ├── auth_service.dart
│   ├── issue_service.dart
│   ├── notification_service.dart
│   ├── location_service.dart
│   └── language_service.dart
├── widgets/             # Reusable components
├── theme/              # App theme
└── main.dart           # App entry point
```

## 🎯 Key Features

### 1. Issue Reporting & Tracking
- 📷 Multiple photo upload (camera/gallery)
- 🎤 Compressed audio descriptions (64kbps AAC)
- 📍 Map-based location pinning
- 🏷️ Category selection (road, water, electricity, etc.)
- 🗜️ Auto image compression (70% quality, 1024x1024)
- 📸 Issue-based storage organization
- 🗑️ Delete reported issues
- 🔄 Reopen completed issues with additional photos/description
- 🔄 Reopen completed issues (48-hour window)
- **📊 4-Stage milestone tracker** (Reported → Assigned → In Progress → Completed)
- **📄 Dedicated Report Details page** with full issue information
- **💬 Worker Updates section** showing all progress updates with photos and messages
- **📈 Visual progress tracking** with 4-stage milestones

### 2. Community Feed
- 🗺️ View nearby issues (5km radius)
- 🔥 Filter: Nearby, Trending, Highest Priority, New, All Issues
- 🎯 Multi-category filter selection
- 📊 Vote-based trending sort (highest upvotes first)
- 👍 One-time upvoting system
- � Comment on issues with real-time updates
- 📊 Comment counts displayed on cards
- 📤 Share issues via WhatsApp, SMS, Email, etc.
- �🗺️ Real-time map view with heatmap
- 👥 Accurate citizen count (only active reporters)
- 📱 20 most recent issues by default

### 3. Notifications
- 🔔 Progress milestone alerts (25%, 50%, 75%, 100%)
- 📬 Unread badge counter
- ✅ Mark as read functionality
- ⏰ Smart time formatting

### 4. Location Services
- 🗺️ OpenStreetMap (no API key)
- 📍 Tap-to-pin selection
- 🏠 Auto address lookup
- 📏 Distance calculation

### 5. Security
- 🔒 HTTPS enforcement
- 🛡️ ProGuard obfuscation
- 🔐 Row Level Security (RLS)
- 🚫 Backup disabled

## 🎨 Customization

### App Icon & Splash

1. Replace `assets/images/logo.png` (512x512)
2. Replace `assets/images/splash.mp4` (video animation)
3. Run:
```bash
flutter pub run flutter_launcher_icons
flutter build apk --release
```

### Theme Colors

Edit `lib/theme/app_theme.dart`:
```dart
static const primary = Color(0xFF8A7BF0); // Purple
static const accent = Color(0xFF9B8DF2);
```

## 🐛 Troubleshooting

### Audio Recording Issues
```bash
flutter clean && flutter pub get && flutter run
```

### Map Not Loading
- Check internet connection
- OSM tiles require internet
- Web: shows coordinates only

### Build Errors
```bash
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

### Video Not Playing
- Do full restart (not hot reload)
- Check `assets/images/splash.mp4` exists
- Verify `pubspec.yaml` includes assets

### RLS Policy Errors
- Verify all SQL from `db.sql` is executed
- Check user is authenticated
- Ensure `user_id` matches `auth.uid()`

## 📦 Key Dependencies

```yaml
supabase_flutter: ^2.3.4     # Backend
flutter_map: ^6.2.1          # Maps
provider: ^6.1.1             # State
geolocator: ^10.1.1          # Location
image_picker: ^1.0.7         # Photos
record: ^5.2.1               # Audio
video_player: ^2.8.2         # Splash video
flutter_dotenv: ^5.1.0       # Environment
share_plus: ^7.2.2           # Share functionality
```

## 🔒 Security Features

### Implemented
- ✅ HTTPS enforcement
- ✅ ProGuard code obfuscation
- ✅ Resource shrinking
- ✅ RLS policies on all tables
- ✅ Environment variables (.env)
- ✅ Backup disabled
- ✅ Error boundaries

### Before Production
- [ ] Change `applicationId` from `com.example.sewamitr`
- [ ] Generate release signing key
- [ ] Enable email verification
- [ ] Add rate limiting
- [ ] Security audit

## 📊 Performance

### APK Size
- Base: ~25-35 MB
- Split per ABI: ~18-22 MB each
- ProGuard: ~30% reduction
- Resource shrinking: ~15% reduction

### Optimizations
- Image compression before upload (70% quality, 1024x1024)
- Audio compression (64kbps AAC, 22kHz)
- Cached network images
- Lazy loading with Provider
- Const constructors
- Video optimization
- Issue-specific storage folders

## 🗄️ Database Schema

### Tables
- `users` - User profiles (UUID)
- `issues` - Reported issues (UUID)
- `votes` - One-time voting
- `notifications` - Progress alerts
- `comments` - Issue comments with RLS
- **`issue_updates`** - Worker progress history (NEW)

### Storage
```
sewamitr/
├── issues/{issue_id}/      # Photos
├── audio/{issue_id}/       # Audio
├── updates/{issue_id}/     # Worker progress photos (NEW)
└── profiles/{user_id}/     # Profile pics
```

## 🧪 Testing

### Test Upvoting
1. Open Community Feed
2. Tap upvote on any issue
3. Icon changes to filled
4. Restart app - still voted

### Test Notifications
1. Report an issue
2. Update progress in Supabase (25%, 50%, 75%, 100%)
3. Check notification bell
4. Tap to mark as read

### Test Issue Reopening
1. Complete an issue (set progress to 100%)
2. Go to My Reports
3. Tap "Reopen" button (available for 48 hours)
4. Add description and optional photos
5. Submit - issue resets to pending status

## 📝 Documentation Files

- `README.md` - This file (setup & features)
- `SUPABASE_CONFIG.md` - Detailed Supabase setup
- `db.sql` - Complete database schema

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push and open PR

## 🙏 Acknowledgments

- OpenStreetMap
- Supabase
- Flutter community

## 📞 Support

- GitHub Issues
- Check `SUPABASE_CONFIG.md`
- Review `db.sql`
