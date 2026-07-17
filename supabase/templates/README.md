# Supabase Auth E-Mail Templates

Diese Templates werden in Supabase unter **Authentication → Templates** eingefügt.

## Magic Link einrichten

1. Supabase Dashboard öffnen
2. Navigation: **Authentication → Templates → Magic Link**
3. Betreff: `Dein Login-Link für shredMembers`
4. Inhalt: Kopiere den gesamten Inhalt von `magic-link.html`
5. Speichern

## Wichtige Variablen

- `{{ .ConfirmationURL }}` – der Magic Link, den Supabase generiert
- `https://shredmember.app/billing` – unsere separate Web-Seite für Abo-Management

## Hinweis zu Store-Richtlinien

Der Hinweis auf `shredmember.app/billing` ist in der E-Mail erlaubt, weil E-Mails nicht Teil der App sind. In der App selbst darf nicht direkt zu externen Bezahlungsseiten verlinkt werden.
