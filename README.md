# shredMembers 🏋️

A modern, minimalist fitness app for workout planning, tracking and progress monitoring.  
Built with **Flutter 3.44+** · **Riverpod** · **GoRouter** · **fl_chart**

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Frontend | Flutter 3.44 | Single codebase for Android, iOS, Web, macOS |
| State | Riverpod 2 | Null-safe, no BuildContext dependency, testable |
| Routing | GoRouter 13 | Declarative, deep-link ready, shell routes |
| Backend (prep) | Supabase-ready service layer | Simple REST + Auth, easy to wire up |
| Charts | fl_chart | Lightweight, customizable |

---

## Project Structure

```
lib/
└── src/
    ├── theme/          # AppColors, AppTheme, AppSpacing
    ├── models/         # AppUser, WorkoutPlan, Exercise, WorkoutSession
    ├── services/       # MockData (swap for Supabase/API service)
    ├── providers/      # Riverpod providers (auth, workout, session)
    ├── routing/        # GoRouter config + route constants
    ├── screens/
    │   ├── onboarding/
    │   ├── auth/       # Login + Signup
    │   ├── home/       # Dashboard
    │   ├── plans/      # Plan list
    │   ├── workout/    # Detail + Tracking flow
    │   ├── progress/   # Stats + history
    │   └── profile/    # Settings
    └── widgets/
        ├── common/     # AppButton, AppCard, StatChip, SectionHeader, GradientText
        └── layout/     # MainScaffold (responsive BottomNav / SideNav)
```

---

## Setup

```bash
# 1. Install Flutter (if not done)
brew install --cask flutter

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run -d macos          # macOS Desktop (requires Xcode)
flutter run -d web-server --web-port 8080   # Web (any browser)
flutter run -d chrome         # Web in Chrome
flutter run                   # iOS Simulator / Android Emulator
```

---

## MVP Screens

- **Onboarding** – 3-page swipe intro
- **Login / Signup** – form validation, mock auth
- **Home Dashboard** – greeting, stats, today's workout card, recent sessions
- **Plans** – grid/list of workout plans, activate plan
- **Workout Detail** – tabbed day view, exercise & set breakdown
- **Workout Tracking** – live set checking, progress bar, timer, completion sheet
- **Progress** – volume bar chart (fl_chart), session history
- **Profile** – goal selector, weekly target, sign out

---

## Live Deployments

| Service | URL | Status |
|---|---|---|
| Landing Page | https://shredmember.app | ✅ Live |
| Web App | https://web-shredmembers.web.app | ✅ Live |
| Billing / Upgrade | https://shredmember.app/billing | ✅ Live |
| Web App (Custom Domain) | https://web.shredmember.app | ⏳ Firebase Console pending |

## Next Steps

- [x] Wire up Supabase auth via Magic Link
- [ ] Replace `MockData` with Supabase/REST calls in service layer
- [ ] Add rest timer between sets
- [ ] Personal records tracking
- [ ] Push notifications for workout reminders
- [ ] iOS / Android release builds

Fitness App


## List Devices
flutter devices

## Start App
flutter run -d "iPhone 17"	
flutter run -d macos
flutter run -d web-server --web-port=8080  # Then open http://localhost:8080 in browser
flutter build web --release
flutter run -d 00048145N001861
flutter run -d "iPad von Claudio"

# Android App
flutter build apk --release && flutter install -d 00048145N001861

# Web App (local)
flutter build web --release

# Web App (deploy to Firebase)
flutter build web --release
firebase deploy --only hosting:web-shredmembers

# macOS App
flutter run -d macos