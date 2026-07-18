# Stripe Production-Setup für shredMembers

Diese Anleitung beschreibt die Stripe-Live-Konfiguration. Für Tests steht weiterhin `supabase/migrations/add_stripe_price_ids.sql` (Test-Price-IDs) und die Verwendung von `sk_test_...` Secrets zur Verfügung.

## 1. Stripe-Konto im Livemodus

1. Auf [stripe.com](https://stripe.com) ein Konto erstellen bzw. ein bestehendes Konto öffnen.
2. Im Dashboard oben rechts den **Test mode**-Schalter deaktivieren, damit Live-Daten angezeigt werden.
3. Links unter **Developers → API keys** findest du:
   - **Publishable key** (`pk_live_...`) – nur für direkte Stripe-UI nötig, hier nicht zwingend.
   - **Secret key** (`sk_live_...`) – wird in Supabase benötigt.

> **Wichtig:** Bewahre den `sk_live_...` sicher auf. Er ermöglicht echte Zahlungen.

## 2. Produkte & Preise anlegen

1. Im Stripe-Dashboard zu **Products** gehen.
2. **Add product** → Name z. B. `ShredMembers Pro`.
3. Zwei Live-Preise anlegen:
   - **Monthly** → `9.99 EUR`, recurring monthly.
   - **Yearly** → `89.99 EUR`, recurring yearly.
4. Die **Price IDs** (beginnen mit `price_...`) kopieren.

## 3. Preise in Supabase eintragen

Führe in der Supabase SQL-Editor folgendes aus:

- Entweder du nutzt die bereitgestellte Migration `supabase/migrations/add_stripe_price_ids_live.sql`.
- Oder du führst folgendes SQL manuell aus (ersetze die `price_...` Werte durch deine echten Live-Price IDs):

```sql
update public.subscription_plans
set stripe_monthly_price_id = 'price_...',
    stripe_yearly_price_id  = 'price_...'
where name = 'ShredMembers Pro';
```

## 4. Supabase Edge Function Secrets setzen

In der Supabase-CLI oder im Dashboard unter **Project Settings → Edge Functions → Secrets** folgende Secrets anlegen:

| Secret | Wert | Zwingend |
|--------|------|----------|
| `STRIPE_SECRET_KEY` | `sk_live_...` | Ja |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Nur für Webhook (optional) |

Falls du die Supabase CLI nutzt:

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

## 5. Edge Functions deployen

```bash
supabase functions deploy stripe-checkout
supabase functions deploy stripe-confirm-payment
supabase functions deploy stripe-webhook
```

## 6. App / Web testen

1. App starten und einen Test-User anmelden.
2. Paywall öffnen (`/subscription/paywall`) bzw. `shredmember.app/billing` im Browser.
3. Auf **Upgrade now** tippen / klicken.
4. Der Browser öffnet Stripe Checkout.
5. Für den Live-Test verwende eine echte Zahlungsmethode mit einem kleinen Betrag oder Stripe-Testkarten **nur im Testmodus**.

## 7. Bezahlung erfolgreich bestätigen

Nach erfolgreicher Zahlung leitet Stripe zu `shredmembers://payment/success?session_id=...` zurück in die App. Die App ruft automatisch die Edge Function `stripe-confirm-payment` auf, die die Checkout-Session prüft und die Subscription in Supabase auf `active` setzt.

## 8. Stripe Webhook für serverseitige Events (empfohlen)

Für Production empfiehlt sich ein Stripe Webhook, der Events verarbeitet, wenn die App nicht geöffnet ist (z. B. Subscription-Erneuerung, Kündigung).

1. Im Stripe-Dashboard unter **Developers → Webhooks** einen neuen **Live-Webhook-Endpunkt** anlegen.
2. URL der Supabase Edge Function `stripe-webhook` eintragen.
3. Mindestens diese Events abonnieren:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `customer.subscription.deleted`
   - `customer.subscription.updated`
4. Das **Signing secret** (`whsec_...`) kopieren und in Supabase als `STRIPE_WEBHOOK_SECRET` hinterlegen.
5. Supabase Edge Functions verlangen einen `Authorization`-Header. Konfiguriere im Stripe Webhook Endpoint den Header `Authorization: Bearer <supabase-anon-key>`.
