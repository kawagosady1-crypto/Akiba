# Akiba – Savings Tracker (Android)

Akiba turns one big saving goal into a daily target. Every shilling saved above the target goes to an Extra pot, and missed days are spread over the remaining days instead of counting as failure.

## Features (version 1)

- **Main goal** with amount, deadline and automatic daily target
- **Daily saving log** with quick amounts (500 – 10,000), savings location (M-Pesa, Mixx by Yas, Airtel Money, Bank, Cash, or your own) and logging up to 7 days back
- **Extra pot**: extra above the daily target either goes to the main goal (finish early) or to an emergency buffer
- **Shortfall recovery**: after a short or missed day the app shows the new target and lets you extend the deadline
- **Spending tracker** by category: food, transport, airtime & data, bills, family, other
- **Mini-goals** beside the main goal
- **History**: every day marked above / on target / short / missed, plus all entries (swipe left to delete)
- **Insights**: last 7 days saved vs spent, top spending category, 30-day spending by category, savings by location
- **Streak** and **projected finish date**
- **Kiswahili and English**, light and dark mode
- **Backup and restore** by copying your data as text
- All data stays on the phone; no internet needed

## Get the APK on your phone

The project builds itself on GitHub for free.

1. Create a free account at github.com.
2. Create a new repository, e.g. `akiba`.
3. Upload all the files in this folder, keeping the folders (`lib`, `.github/workflows`).
4. Open the **Actions** tab. The "Build Android APK" job starts by itself and takes about 5–10 minutes.
5. When it shows a green tick, open **Releases** on the repository page and download **Akiba.apk** on your phone.
6. Open the file and allow "Install unknown apps" for your browser when Android asks.

To build again later, open **Actions → Build Android APK → Run workflow**.

## Build on a computer instead

With Flutter installed:

```
flutter create --org com.akiba --project-name akiba --platforms android .
flutter pub get
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## Project layout

| File | What it holds |
| --- | --- |
| `lib/main.dart` | App start and theme |
| `lib/state.dart` | Data model, saving logic, daily target and extra calculations, storage |
| `lib/screens.dart` | Onboarding, Home, Goals, History, Insights, Settings |
| `lib/sheets.dart` | Log saving/spending and goal forms |
| `lib/widgets.dart` | Shared cards and list items |
| `lib/i18n.dart` | Kiswahili and English text |
| `lib/format.dart` | Money and date formatting |

Every transaction has a `source` field (`manual` for now), so mobile money or SMS entries can be added later without changing the rest of the app.
