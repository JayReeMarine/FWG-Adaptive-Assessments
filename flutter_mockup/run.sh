#!/bin/bash
# Load environment variables from ../.env and run the Flutter app on Chrome.
# Usage: ./run.sh

ENV_FILE="$(dirname "$0")/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Copy .env.example to .env and fill in your credentials."
  exit 1
fi

source "$ENV_FILE"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: Missing required variables in .env (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY)"
  exit 1
fi

echo "Starting Navigator on Chrome..."

flutter run -d chrome \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
