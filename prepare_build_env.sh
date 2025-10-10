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
echo "🔎 Pre-check source visibility..."
for p in \
  "src/main/java/com/example/demodevops/smp" \
  "src/main/java/com/example/demodevops/ccp"
do
  if [[ ! -d "$p" ]]; then
    echo "❌ Missing path in build dir: $p"
    echo "   Aborting to avoid building an incomplete JAR."
    exit 1
  fi
done
echo "✅ Pre-check OK (smp + ccp present)."

echo "🐳 Docker prune (safe)…"
docker system prune -f >/dev/null 2>&1 || true

echo "🏗️ docker compose up --build -d"
docker compose up --build -d

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