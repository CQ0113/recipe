#!/usr/bin/env bash
set -euo pipefail

required_variables=(
  FIREBASE_API_KEY
  FIREBASE_WEB_APP_ID
  FIREBASE_MESSAGING_SENDER_ID
  FIREBASE_PROJECT_ID
  FIREBASE_AUTH_DOMAIN
  FIREBASE_STORAGE_BUCKET
)

missing_variables=()
for variable in "${required_variables[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    missing_variables+=("$variable")
  fi
done

if (( ${#missing_variables[@]} > 0 )); then
  printf 'Missing required Netlify environment variables:\n' >&2
  printf '  - %s\n' "${missing_variables[@]}" >&2
  printf 'Add them under Project configuration > Environment variables, then retry the deploy.\n' >&2
  exit 1
fi

flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define="FIREBASE_API_KEY=$FIREBASE_API_KEY" \
  --dart-define="FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID" \
  --dart-define="FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define="FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID" \
  --dart-define="FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN" \
  --dart-define="FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET" \
  --dart-define="RECAPTCHA_SITE_KEY=${RECAPTCHA_SITE_KEY:-}"
