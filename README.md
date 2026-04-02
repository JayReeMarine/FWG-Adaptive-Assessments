# FWG Adaptive Assessments

> FIT4702 — Adaptive Assessment Platform comparing Rule-based vs LLM-based health questionnaires, built with Flutter & Supabase.

## Links

| Resource | URL |
|----------|-----|
| Team's Folder | https://drive.google.com/drive/u/1/folders/1g20YC3A-IQ8-JM6LBUzlJKDUFKCSX0sM |
| DB Diagram | https://dbdiagram.io/d/FWG-ADAPTIVE-Schema-68df3c08d2b621e422107095 |
| Supabase Dashboard | https://aqyrpgcssvczmzsojzpm.supabase.co |

## Getting Started

### 1. Set up environment variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

The `.env` file is gitignored — never commit it. Get the values from a team member or the shared team folder.

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_PASSWORD=...
GEMINI_API_KEY=...       # Get a free key at https://aistudio.google.com/apikey
```

### 2. Run locally

```bash
cd flutter_mockup
flutter clean
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

> On macOS/zsh you can load the `.env` first:
> ```bash
> source ../.env && flutter run -d chrome \
>   --dart-define=SUPABASE_URL=$SUPABASE_URL \
>   --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
>   --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
> ```

### 3. Deploy

Pushing to `main` triggers the GitHub Actions workflow which builds and deploys to Vercel automatically. Secrets are stored in GitHub repository settings (not in this file).

## Flow Diagram

```bash
cd docs/flow-diagram
npm install   # first time only
npm run dev   # opens at http://localhost:5173
```
