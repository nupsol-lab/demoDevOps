#!/bin/bash
set -euo pipefail

# ==============================
# 🚀 Script: prepare_build_env.sh
# Build full project from WSL (keeps Windows ACL isolation)
# ==============================

# === CONFIG ===
GIT_URL="${GIT_URL:-https://github.com/<org>/<repo>.git}"   # << set this once
GIT_BRANCH="${GIT_BRANCH:-main}"
BUILD_DIR="$HOME/dev_build/demoDevOps"
DOCKER_COMPOSE_FILE="docker-compose.yml"
APP_HEALTH_URL="http://localhost:8081/actuator/health"

echo "🧹 Cleaning previous build dir..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "⬇️ Cloning $GIT_URL#$GIT_BRANCH into $BUILD_DIR ..."
git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_URL" "$BUILD_DIR"

cd "$BUILD_DIR" || { echo "❌ Cannot cd to $BUILD_DIR"; exit 1; }

# Ensure .env exists (create default if missing)
if [[ ! -f .env ]]; then
  echo "DB_USER=postgres"     > .env
  echo "DB_PASSWORD=postgres" >> .env
  echo "DB_NAME=demoDevOps"   >> .env
  echo "ℹ️ Created default .env"
fi

echo "🐳 Pruning old Docker stuff (safe)..."
docker system prune -f >/dev/null 2>&1 || true

echo "🏗️ Building & starting with Docker Compose..."
docker compose up --build -d

echo "⏳ Waiting for app to boot..."
# tiny wait + profile check + health
sleep 5
echo "🔎 Active profiles:"
docker logs demo_app 2>&1 | grep -i "profile" || echo "⚠️ No profile line (may be normal)"
echo "🩺 Health check:"
for i in {1..12}; do
  if curl -fsS "$APP_HEALTH_URL" >/dev/null; then
    echo "✅ App is UP at $APP_HEALTH_URL"
    exit 0
  fi
  sleep 2
done

echo "⚠️ Health-check failed. Check logs:"
docker compose logs --no-log-prefix app | tail -n 200
exit 1
