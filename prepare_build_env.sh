#!/bin/bash
set -euo pipefail

# ==============================
# 🚀 Script: prepare_build_env.sh
# Build full project from WSL (keeps Windows ACL isolation)
# ==============================

# === CONFIG ===
GIT_URL="${GIT_URL:-https://github.com/nupsol-lab/demoDevOps.git}"   # << set this once
GIT_BRANCH="${GIT_BRANCH:-main}"
BUILD_DIR="$HOME/dev_build/demoDevOps"
APP_HEALTH_URL="http://localhost:8081/actuator/health"

echo "🧹 Cleaning build dir..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "⬇️ Cloning $GIT_URL#$GIT_BRANCH ..."
git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_URL" "$BUILD_DIR"

cd "$BUILD_DIR" || { echo "❌ Cannot cd to $BUILD_DIR"; exit 1; }

# Ensure .env exists (create default if missing)
if [[ ! -f .env ]]; then
  cat > .env <<EOF
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=demoDevOps
EOF
  echo "ℹ️ Created default .env"
fi

# --- Pre-check: ensure both modules are present ---
echo "🔎 Pré-check source visibility..."
need=("smp" "ccp")
for module in "${need[@]}"; do
  base="src/main/java/com/example/demodevops/$module"
  if [[ ! -d "$base" ]]; then
    echo "❌ Dossier manquant: $base" ; exit 1
  fi
  # ⚠️ Vérifie qu'il y a au moins 1 .java
  if ! find "$base" -type f -name '*.java' | head -n1 >/dev/null; then
    echo "❌ Aucun .java dans: $base (branche/commit incomplet ?)" ; exit 1
  fi
done
echo "✅ Pré-check OK (smp + ccp avec des .java)."


echo "🐳 Docker prune (safe)…"
docker system prune -f >/dev/null 2>&1 || true

echo "🐳 choosing mode and run docker compose…"
MODE="${MODE:-prod}"   # prod | dev

if [[ "$MODE" == "dev" ]]; then
  docker compose -f docker-compose.dev.yml up --build -d
else
  docker compose up --build -d
fi


echo "⏳ Waiting for app health..."
for i in {1..20}; do
  if curl -fsS "$APP_HEALTH_URL" >/dev/null; then
    echo "✅ App is UP at $APP_HEALTH_URL"
    exit 0
  fi
  sleep 2
done

echo "⚠️ Health-check failed. Last app logs:"
docker compose logs --no-log-prefix app | tail -n 200
exit 1