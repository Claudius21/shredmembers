# Stripe Test-Setup für shredMembers

Damit der Kauf-Flow im Paywall-Screen funktioniert, müssen Stripe-Produkte, Preise und Supabase Edge Function Secrets konfiguriert werden.

## 1. Stripe-Konto im Testmodus

1. Auf [stripe.com](https://stripe.com) ein Konto erstellen.
2. Im Dashboard oben rechts auf **Test mode** stellen.
3. Links unter **Developers → API keys** findest du:
   - **Publishable key** (z. B. `pk_test_...`) – nur für direkte Stripe-UI nötig, hier nicht zwingend.
   - **Secret key** (z. B. `sk_test_...`) – wird in Supabase benötigt.

## 2. Produkte & Preise anlegen

1. Im Stripe-Dashboard zu **Products** gehen.
2. **Add product** → Name z. B. `ShredMembers Pro`.
3. Zwei Preise anlegen:
   - **Monthly** → `9.99 EUR`, recurring monthly.
   - **Yearly** → `89.99 EUR`, recurring yearly.
4. Die **Price IDs** (beginnen mit `price_...`) kopieren.

## 3. Preise in Supabase eintragen

Führe in der Supabase SQL-Editor folgendes aus:

- Entweder du nutzt die bereitgestellte Migration `supabase/migrations/add_stripe_price_ids.sql`.
- Oder du führst folgendes SQL manuell aus (ersetze die `price_...` Werte durch deine echten Test-Price IDs):

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
| `STRIPE_SECRET_KEY` | `sk_test_...` | Ja |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Nur für Webhook (optional) |

Falls du die Supabase CLI nutzt:

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
```

## 5. Edge Functions deployen

```bash
supabase functions deploy stripe-checkout
supabase functions deploy stripe-confirm-payment
```

## 6. App testen

1. App starten und einen Test-User anmelden.
2. Paywall öffnen (`/subscription/paywall`).
3. Auf **Upgrade now** tippen.
4. Der Browser öffnet Stripe Checkout.
5. Für Test-Zahlungen kannst du Stripe-Testkarten verwenden, z. B.:

| Karte | Nummer | CVC | Datum |
|-------|--------|-----|-------|
| Visa (Erfolg) | `4242 4242 4242 4242` | beliebig | beliebig in Zukunft |
| Visa (Ablehnung) | `4000 0000 0000 0002` | beliebig | beliebig in Zukunft |

Weitere Testkarten: [Stripe Test Cards](https://stripe.com/docs/testing#cards)

## 7. Bezahlung erfolgreich simulieren

Nach erfolgreicher Test-Zahlung leitet Stripe zu `shredmembers://payment/success?session_id=...` zurück in die App. Die App ruft automatisch die Edge Function `stripe-confirm-payment` auf, die die Checkout-Session prüft und die Subscription in Supabase auf `active` setzt.

Falls du die App-Weiterleitung nicht nutzen willst, kannst du die Subscription auch manuell auf aktiv setzen (nur für Tests):

```sql
update public.subscriptions
set status = 'active',
    subscribed_at = now(),
    current_period_start = now(),
    current_period_end = now() + interval '1 year'
where user_id = '<user-id>';
```

## 8. (Optional) Stripe Webhook für serverseitige Events

Für Production empfiehlt sich ein Stripe Webhook, der auch Events verarbeitet, wenn die App nicht geöffnet ist (z. B. Subscription-Erneuerung, Kündigung). Dieser ist aber nicht zwingend für den Basis-Flow.

Wenn du einen Webhook verwenden willst, deploye die Edge Function `stripe-webhook` und setze `STRIPE_WEBHOOK_SECRET`. Beachte, dass Supabase Edge Functions einen `Authorization` Header verlangen, den Stripe Webhook Endpoints nicht standardmäßig mitliefern. Eine Möglichkeit ist, im Stripe Webhook Endpoint den Header `Authorization: Bearer <supabase-anon-key>` zu konfigurieren.
