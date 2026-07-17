# Store Deploy Checklist

## ✅ Completed

### App Assets
- [x] Android app icons (all mipmap sizes)
- [x] iOS app icons (all required sizes)
- [x] App name and labels configured

### App Configuration
- [x] Android signing (keystore + key.properties)
- [x] Firebase Hosting setup (shredmember.app)
- [x] Privacy Policy page
- [x] Magic link authentication flow
- [x] Deep link handling (shredmembers://)
- [x] Resend SMTP für transaktionale E-Mails eingerichtet
- [x] Supabase signup trigger (free → trial + plan_id) gefixt
- [x] Web Checkout mit i18n (DE/EN/FR/IT/ES)
- [x] Landing Page auf "kostenlos starten" umgebaut (kein Checkout)
- [x] Separate `/billing` Seite für Upgrades
- [x] App Paywall/Upgrade-Buttons entfernt (Store-Richtlinien)
- [x] Mehrsprachiges Magic Link E-Mail Template (DE/EN/FR/IT/ES)

### Web Assets
- [x] Landing page (index.html) – kostenlos starten
- [x] Flutter Web App auf Firebase Hosting (`web-shredmembers.web.app`)
- [x] Billing page (billing.html) – Upgrade via Stripe
- [x] Privacy Policy (privacy-policy.html)
- [x] Auth callback handler (auth-callback.html)
- [x] firebase.json Multi-Site Config für Landing + Web App

## 🔲 Remaining Tasks

### 1. App als kostenlose App einreichen
**Wichtig:** App muss in beiden Stores als **Free App** deklariert werden. Premium-Features werden ausschließlich über `shredmember.app/billing` verwaltet.

### 2. iOS Signing (Apple Developer Program)
**Cost:** $99/year
**Requirements:**
- Apple Developer Program account
- Distribution certificate
- Provisioning profiles
- App Store Connect app setup
- App als kostenlose App (Free) mit externem Account-basiertem Abo

**Steps:**
1. Enroll in Apple Developer Program ($99/year)
2. Create App ID in Apple Developer Portal
3. Generate distribution certificate
4. Create provisioning profiles
5. Configure Xcode project settings
6. Create app in App Store Connect

### 3. Store Screenshots
**Requirements:**
- Android: Various device sizes (phone, tablet, foldable)
- iOS: iPhone and iPad sizes
- Minimum 3-5 screenshots per store

**Screenshot Sizes:**
- **Android:**
  - Phone: 1080×1920 (portrait), 1920×1080 (landscape)
  - Tablet: 1920×1200 (landscape), 1200×1920 (portrait)
  - 7-inch: 600×1024 (portrait), 1024×600 (landscape)
  - 10-inch: 1200×1920 (portrait), 1920×1200 (landscape)

- **iOS:**
  - iPhone: 1242×2208 (6.5"), 1242×2688 (6.7"), 1170×2532 (6.1")
  - iPad: 2048×2732 (12.9"), 1668×2388 (11")

### 4. Store Descriptions
**Required for both stores:**
- App title (30 characters max)
- Short description (80 characters max)
- Full description (up to 4000 characters)
- Keywords/Tags
- Category selection

**Content to prepare:**
- App title and subtitle
- Feature list
- Target audience description
- Key benefits and differentiators

### 5. Store Accounts Setup
**Google Play Console:**
- Cost: $25 (one-time)
- Account registration
- Developer identity verification
- Store listing setup

**App Store Connect:**
- Cost: $99/year (included in Apple Developer Program)
- App metadata setup
- Pricing and availability
- Review guidelines compliance

### 6. Custom Domain für Web App verknüpfen
**Schritte:**
1. Firebase Console → Hosting → Site `web-shredmembers`
2. **Custom Domain** → `web.shredmember.app` hinzufügen
3. DNS-Eintrag (A-Record / CNAME) beim Domain-Provider setzen
4. SSL-Zertifikat von Firebase ausstellen lassen (kann bis zu 24h dauern)

### 7. Store URLs in Web Checkout aktualisieren
Nach App Store Einreichung in `landing/app.js` → `STORE_URLS` eintragen:
- [ ] Google Play URL (`https://play.google.com/store/apps/details?id=...`)
- [ ] App Store URL (`https://apps.apple.com/app/shredmembers/id...`)

## 📋 Final Pre-Deploy Checklist

### Technical Requirements
- [ ] Test release build on physical devices
- [ ] Verify all deep links work correctly (Magic Link → App)
- [ ] Test subscription flow end-to-end (Web Checkout + App-Zugriff)
- [ ] Verify privacy policy is accessible
- [ ] Test on different screen sizes/orientations
- [ ] Bestätigen: App enthält keine externen Bezahl-Links

### Store Compliance
- [ ] Review store guidelines (Google Play + App Store)
- [ ] Ensure app rating is appropriate
- [ ] Verify no policy violations (keine externen Zahlungslinks, keine Preisvergleiche)
- [ ] Test all required permissions
- [ ] App als **Free** deklarieren (keine In-App-Käufe nötig)

### Marketing Materials
- [ ] Final app icon (512×512 for stores)
- [ ] Feature graphic (1024×500 for Google Play)
- [ ] App preview videos (optional but recommended)
- [ ] Store screenshots (all required sizes)

## 🚀 Deploy Process

### Android (Google Play)
1. Generate signed APK/AAB
2. Upload to Google Play Console
3. Complete store listing
4. Submit for review

### iOS (App Store)
1. Archive build in Xcode
2. Upload to App Store Connect
3. Complete app metadata
4. Submit for review

## 📞 Support Contacts

- **Privacy Policy:** support@shredmember.app
- **Website:** https://shredmember.app
- **Privacy Policy URL:** https://shredmember.app/privacy-policy

## 🔄 Post-Launch

- Monitor crash reports and analytics
- Respond to user reviews and feedback
- Plan for regular updates and feature additions
- Track subscription metrics and revenue

## 🗺️ Roadmap

### A – App in die Stores bringen
- [ ] iOS Developer Program kaufen ($99/Jahr)
- [ ] App Store Connect App erstellen
- [ ] Distribution Certificate + Provisioning Profile
- [ ] Xcode Archive + Upload
- [ ] Google Play Console Account ($25 einmalig)
- [ ] AAB Build erstellen und hochladen
- [ ] Screenshots für beide Stores (alle Größen)
- [ ] Store-Listings auf DE/EN/FR/IT schreiben
- [ ] Store-URLs in `landing/app.js` → `STORE_URLS` eintragen
- [ ] App in Google Play & App Store als **Free App** einreichen
- [ ] Einreichung und Review abwarten

### B – App weiterbauen
- [ ] Workout-Tracking verbessern
- [ ] Push-Notifications implementieren
- [ ] Apple HealthKit / Google Fit Integration
- [ ] Fortschritts-Charts und Statistiken
- [ ] Social Features (Challenges, Leaderboard)

### C – Erste zahlende Kunden gewinnen
- [ ] Onboarding-Flow verbessern (Tutorial, Willkommens-Screen)
- [ ] Referral/Invite-System
- [ ] Discount Codes für Beta-User
- [ ] E-Mail-Marketing Setup (Onboarding-Sequenz)
- [ ] Analytics einbauen (Mixpanel/PostHog)

### D – Technische Schulden abbauen
- [ ] `l10n.yaml` synthetic-package Warning entfernen
- [ ] `flutter_local_notifications` auf Swift Package Manager updaten
- [ ] Unit Tests für kritische Services (Auth, Subscription)
- [ ] Widget Tests für Info-PaywallScreen
- [ ] CI/CD Pipeline (GitHub Actions)
