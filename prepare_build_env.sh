#!/bin/bash
set -euo pipefail

# ==============================
# 🚀 Script: prepare_build_env.sh
# Build full project from WSL (keeps Windows ACL isolation)
# ==============================

# === CONFIG ===
#!/bin/bash
set -euo pipefail

# === PARAMÈTRES GLOBAUX ===
GIT_URL="${GIT_URL:-https://github.com/nupsol-lab/demoDevOps.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"
BUILD_DIR="$HOME/dev_build/demoDevOps"
OVERLAY_DIR="${OVERLAY_DIR:-/mnt/c/DevProjects/demoDevOps}"
APP_HEALTH_URL="http://localhost:8081/actuator/health"

echo "🧹 Cleaning build dir..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "⬇️ Cloning $GIT_URL#$GIT_BRANCH ..."
git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_URL" "$BUILD_DIR"
cd "$BUILD_DIR" || { echo "❌ Cannot cd to $BUILD_DIR"; exit 1; }

# === Overlay local optionnel ===
if [ -d "$OVERLAY_DIR" ]; then
  echo "🔁 Applying local overlay from: $OVERLAY_DIR"

  RSYNC_EXCLUDE=()
  if [ -f "$OVERLAY_DIR/.overlayignore" ]; then
    RSYNC_EXCLUDE+=(--exclude-from="$OVERLAY_DIR/.overlayignore")
    echo "📄 Using .overlayignore from overlay"
  fi

  echo "⚙️  Syncing overlay files..."
  rsync -a --checksum "${RSYNC_EXCLUDE[@]}" "$OVERLAY_DIR"/ "$BUILD_DIR"/

  echo "📋 Diff vs clean repo (non commité) :"
  git --no-pager diff --stat || true
else
  echo "ℹ️ No overlay directory found at $OVERLAY_DIR (skipping)"
fi

# === Génération du .env si absent ===
if [[ ! -f .env ]]; then
  cat > .env <<EOF
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=demoDevOps
EOF
  echo "ℹ️ Created default .env"
fi

# === Pré-check sources obligatoires ===
echo "🔎 Checking core modules (smp / ccp)..."
need=("smp" "ccp")
for module in "${need[@]}"; do
  base="src/main/java/com/example/demodevops/$module"
  [[ -d "$base" ]] || { echo "❌ Missing folder: $base"; exit 1; }
  find "$base" -type f -name '*.java' | head -n1 >/dev/null \
    || { echo "❌ No .java found in: $base"; exit 1; }
done
echo "✅ Pre-check OK."

# === Docker build & run ===
echo "🐳 Docker prune (safe)…"
docker system prune -f >/dev/null 2>&1 || true

echo "🛠️ Building and starting containers..."
docker compose up --build -d

# === Health-check ===
echo "⏳ Waiting for app health..."
for i in {1..20}; do
  if curl -fsS "$APP_HEALTH_URL" >/dev/null; then
    echo "✅ App is UP at $APP_HEALTH_URL"
    exit 0
  fi
  sleep 2
done

echo "⚠️ Health-check failed. Showing last app logs:"
docker compose logs --no-log-prefix app | tail -n 200
exit 1
