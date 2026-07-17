# Supabase Auth E-Mail Templates

Diese Templates werden in Supabase unter **Authentication → Templates** eingefügt.

## Magic Link einrichten

Supabase Auth erlaubt pro Ereignis (z. B. Magic Link) nur **ein E-Mail-Template**. Für mehrsprachige E-Mails bieten wir zwei Varianten an.

### Einfach: Mehrsprachiges Einzel-Template

1. Supabase Dashboard öffnen
2. Navigation: **Authentication → Templates → Magic Link**
3. Betreff: `shredMembers Magic Link`
4. Inhalt: Kopiere den gesamten Inhalt von `magic-link-multilingual.html`
5. Speichern

### Einsprachig: Pro Sprache ein Template (sauberere Lösung)

Falls du später je Sprache ein eigenes Template verschicken möchtest, benötigst du eine eigene Edge Function (z. B. `send-magic-link`), die die bevorzugte Sprache des Users ausliest und die E-Mail via Resend/SendGrid versendet. Bis dahin funktioniert `magic-link-multilingual.html`.

## Wichtige Variablen

- `{{ .ConfirmationURL }}` – der Magic Link, den Supabase generiert
- `https://shredmember.app/billing` – unsere separate Web-Seite für Abo-Management

## Hinweis zu Store-Richtlinien

Der Hinweis auf `shredmember.app/billing` ist in der E-Mail erlaubt, weil E-Mails nicht Teil der App sind. In der App selbst darf nicht direkt zu externen Bezahlungsseiten verlinkt werden.
