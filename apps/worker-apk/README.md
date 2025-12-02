# SewaMitr Worker App 🚀

A Flutter mobile and web application for field workers to update civic issue progress in real-time.

## ✨ Features

- 📋 **Issue Management** - View assigned civic issues with detailed information
- 📸 **Progress Photos** - Upload before/after photos with automatic compression
- 📍 **Location Mapping** - View issue locations on interactive maps
- 📊 **Progress Tracking** - Update progress from 0-100% with status changes
- 🔄 **Real-time Updates** - Instant synchronization with Supabase backend
- 🌐 **Multi-language** - Support for English and Hindi
- 📱 **Cross-platform** - Works on Android, iOS, and web browsers

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Supabase (PostgreSQL)
- **State Management**: Provider
- **Maps**: OpenStreetMap
- **UI**: Google Fonts, Material Design
- **Image Processing**: Built-in compression

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Supabase account
- Android Studio / VS Code

### 1. Clone Repository

```bash
git clone https://github.com/Sewamitr/worker-apk.git
cd worker-apk
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Supabase

1. **Create a Supabase Project**: Go to [Supabase](https://supabase.com/) and create a new project.
2. **Run Main Database Setup**:
   - Open the SQL Editor in Supabase.
   - Copy and paste the content of `db.sql` (from the root or main app directory) and run it. This creates the core tables (`users`, `issues`, etc.).
3. **Run Worker App Setup**:
   - Open `database/setup.sql` from this project.
   - Copy and paste its content into the Supabase SQL Editor and run it.
   - This script adds worker-specific columns (`role`, `assigned_to`), functions, and policies.
   - See `database/DATABASE_SETUP.md` for detailed documentation.
4. **Create Storage Bucket**:
   - Go to Storage in Supabase.
   - Create a new public bucket named `sewamitr`.
5. **Configure Environment Variables**:
   - Copy `.env.example` to `.env`.
   - Get your Project URL and Anon Key from Supabase Project Settings > API.
   - Update `.env`:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Run the App

```bash
# Mobile (Android/iOS)
flutter run

# Web Browser
flutter run -d chrome

# Release Build
flutter build apk --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── issue_model.dart      # Issue data model
├── services/
│   ├── auth_service.dart     # Authentication service
│   ├── issue_service.dart    # Issue management
│   └── language_service.dart # Localization
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   └── login_screen.dart
│   └── dashboard/
│       ├── worker_dashboard.dart
│       ├── assigned_issues_screen.dart
│       └── update_issue_screen.dart
├── theme/
│   └── app_theme.dart        # App styling
└── utils/
    ├── animations.dart       # UI animations
    ├── category_helper.dart  # Category utilities
    └── image_optimizer.dart  # Image compression
```

## 🗄️ Database Schema

The app uses the following main tables in Supabase:

- **`issues`** - Main issues table with worker assignments
- **`users`** - Worker authentication and profiles
- **`categories`** - Issue categories and types

See `database/setup.sql` for complete schema and test data.

## 📱 App Permissions

- **Camera** - For capturing progress photos
- **Storage** - Read/write images
- **Location** - View issue locations on map
- **Internet** - Supabase connection

## 🔧 Configuration

### Environment Variables

```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
```

### Build Configuration

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: Minimum iOS 11.0
- **Web**: Modern browsers with JavaScript enabled

## 🚀 Deployment

### Android APK

```bash
flutter build apk --release
```

### Web Deployment

```bash
flutter build web --release
```

Deploy the `build/web` folder to any static hosting service.

## 🧪 Testing

The app includes test data in `database/setup.sql`:
- Sample worker accounts
- Test civic issues
- Various issue categories

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request


Made with ❤️ by the SewaMitr Team