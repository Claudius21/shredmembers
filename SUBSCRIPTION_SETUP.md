# Subscription System Setup Guide

## Übersicht
Das Subscription System bietet:
- **30-Tage kostenlosen Testzugang** für neue User
- **App ist kostenlos** in Google Play & App Store eingereicht
- **Stripe-Zahlung** ausschließlich über `shredmember.app/billing` (Web, außerhalb der App)
- **Rabattcode-System** für Promotions (nur Web-Checkout)
- **Info-Paywall** in der App ohne externe Bezahlungslinks

---

## 1. Supabase Setup

### Datenbank-Migration ausführen

```sql
-- In Supabase Dashboard → SQL Editor
-- Datei: supabase/migrations/add_subscription_system.sql
```

Dies erstellt:
- `subscription_plans` - Preispläne
- `discount_codes` - Rabattcodes
- `subscriptions` - User-Abonnements mit Trial-Logik
- Trigger für automatische Subscription-Erstellung
- RPC-Funktion `check_trial_status()`

---

## 2. Stripe Setup

### 2.1 Stripe Account & Produkte

1. Erstelle Produkte in Stripe:
   - **Monatlich**: z.B. 9.99€
   - **Jährlich**: z.B. 89.99€ (2 Monate geschenkt)

2. Kopiere die **Price IDs** (`price_xxx`) nach Supabase:

```sql
UPDATE subscription_plans 
SET 
  stripe_monthly_price_id = 'price_monthly_xxx',
  stripe_yearly_price_id = 'price_yearly_xxx';
```

### 2.2 Webhook einrichten

1. In Stripe Dashboard → Developers → Webhooks
2. Endpoint URL: `https://<project>.supabase.co/functions/v1/stripe-webhook`
3. Events auswählen:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

4. **Webhook Secret** kopieren für Edge Function

### 2.3 Edge Functions Secrets

```bash
# Supabase CLI
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set APP_URL=https://deine-domain.com
```

### 2.4 Edge Functions deployen

```bash
# Checkout Function
supabase functions deploy stripe-checkout

# Webhook Function
supabase functions deploy stripe-webhook
```

---

## 3. Flutter App

### Konfiguration
- Die App ist für den Store-Einreichungsprozess als **kostenlose App** vorgesehen
- `PaywallScreen` zeigt Features und Trial-Status, **keine Preise oder Bezahl-Buttons**
- `SubscriptionManagementScreen` zeigt Abo-Status, **keine Upgrade-Buttons**
- Bezahlung/Upgrade nur über `shredmember.app/billing` im Browser außerhalb der App

### Dependencies
```yaml
# pubspec.yaml - bereits hinzugefügt
dependencies:
  url_launcher: ^6.2.5
```

```bash
flutter pub get
```

---

## 4. Rabattcodes erstellen

### Option A: Direkt in Supabase

```sql
INSERT INTO discount_codes (code, discount_percent, valid_from, valid_until, max_uses)
VALUES ('SUMMER30', 30, NOW(), NOW() + INTERVAL '30 days', 100);
```

### Option B: Mit Stripe Coupon verknüpfen

Für automatische Stripe-Rabatte:

1. Erstelle Coupon in Stripe Dashboard
2. Kopiere Coupon ID (`coupon_xxx`)
3. In Supabase speichern:

```sql
INSERT INTO discount_codes (code, discount_percent, stripe_coupon_id)
VALUES ('VIP50', 50, 'coupon_xxx');
```

---

## 5. Testen

### 5.1 Test-Modus (Stripe)

- Stripe Test API Key verwenden (`sk_test_...`)
- Test-Kreditkarten: https://stripe.com/docs/testing#cards

### 5.2 Testablauf Web

1. **Registrierung** → Automatisch 30 Tage Trial
2. **Landing Page** `shredmember.app` → E-Mail eingeben, Magic Link erhalten
3. **shredmember.app/billing** → Plan wählen und Stripe Checkout
4. **Zugriff** automatisch freigeschaltet

### 5.3 Testablauf App

1. **App installieren** (kostenlos im Store)
2. **Magic Link** in App anfordern
3. **App nutzen** (Trial oder aktives Abo wird erkannt)
4. Für Upgrade: E-Mail mit Hinweis auf `shredmember.app/billing` nutzen

### 5.3 Trial manuell verkürzen (Testing)

```sql
-- Trial auf morgen setzen
UPDATE subscriptions 
SET trial_ends_at = NOW() + INTERVAL '1 minute'
WHERE user_id = '...';
```

---

## 6. Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/src/models/subscription.dart` | Datenmodelle |
| `lib/src/services/subscription_repository.dart` | API-Zugriff |
| `lib/src/providers/subscription_provider.dart` | State Management |
| `lib/src/screens/subscription/paywall_screen.dart` | Info-Paywall (keine Zahlung) |
| `lib/src/screens/subscription/subscription_management_screen.dart` | Abo-Verwaltung (keine Upgrades) |
| `landing/billing.html` | Web-Checkout für Upgrades |
| `supabase/templates/magic-link-multilingual.html` | Mehrsprachige Magic Link E-Mail |
| `supabase/migrations/add_subscription_system.sql` | Datenbank-Schema |
| `supabase/functions/stripe-checkout/index.ts` | Checkout API |
| `supabase/functions/stripe-webhook/index.ts` | Webhook Handler |

---

## 7. Zugriffsschutz

Die Info-Paywall wird automatisch angezeigt wenn:
- Trial abgelaufen (`trial_ends_at < NOW()`)
- Kein aktives Abonnement

### Routes-Schutz
```dart
// In app_router.dart - bereits implementiert
if (!subState.hasAccess && !isPaywallRoute) {
  return AppRoutes.paywall;
}
```

Hinweis: `PaywallScreen` enthält keine Bezahl-Buttons. User müssen über `shredmember.app/billing` upgraden.

---

## 8. Kündigung & Reaktivierung

User können in `SubscriptionManagementScreen`:
- Abonnement kündigen (läuft bis Period-Ende)
- Kündigung reaktivieren (vor Period-Ende)

**Upgrade** ist nur über `shredmember.app/billing` möglich, nicht in der App.

---

## Hinweise

- **App ist kostenlos**: Die App wird als Free App in Google Play & App Store eingereicht
- **Web-Zahlung**: Bezahlung läuft ausschließlich über `shredmember.app/billing`
- **E-Mail Marketing**: Magic Link E-Mail verweist auf `shredmember.app/billing` (erlaubt, weil außerhalb der App)
- **Store-Richtlinien**: App enthält keine externen Bezahlungslinks, keine Preisvergleiche, keine "hier günstiger"-Hinweise
