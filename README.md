# FWG Adaptive Assessments

> FIT4702 - Adaptive Assessment Platform built with Flutter & Supabase

## Links

| Resource | URL |
|----------|-----|
| Team's Folder | https://drive.google.com/drive/u/1/folders/1g20YC3A-IQ8-JM6LBUzlJKDUFKCSX0sM |
| DB Diagram | https://dbdiagram.io/d/FWG-ADAPTIVE-Schema-68df3c08d2b621e422107095 |
| Supabase Dashboard | https://aqyrpgcssvczmzsojzpm.supabase.co |

## Supabase Credentials

| Key | Value |
|-----|-------|
| URL | `https://aqyrpgcssvczmzsojzpm.supabase.co` |
| Password | `apative123@` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxeXJwZ2Nzc3Zjem16c29qenBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNTQyMDQsImV4cCI6MjA4ODgzMDIwNH0.XsQVkjm43yJf8CVRr57QGTq0soFZEOnpD4S03QG7q8g` |

## Getting Started

```bash
# 1. Navigate to the Flutter project
cd flutter_mockup

# 2. Clean & install dependencies
flutter clean
flutter pub get

# 3. Run the app
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://aqyrpgcssvczmzsojzpm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxeXJwZ2Nzc3Zjem16c29qenBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNTQyMDQsImV4cCI6MjA4ODgzMDIwNH0.XsQVkjm43yJf8CVRr57QGTq0soFZEOnpD4S03QG7q8g \
  --dart-define=GEMINI_API_KEY=AIzaSyANvswtbiAfZrpch7rMY4HKv-YIPBMzR48
```

## Flow Diagram

View the adaptive assessment flow diagram locally.

```bash
cd docs/flow-diagram
npm install   # first time only
npm run dev   # opens at http://localhost:5173
```
