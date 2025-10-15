#!/bin/bash
set -euo pipefail

# ==============================
# 🚀 Script: prepare_build_env.sh
# Build full project from WSL (keeps Windows ACL isolation)
# ==============================

# === PARAMÈTRES GLOBAUX ===
GIT_URL="${GIT_URL:-https://github.com/nupsol-lab/demoDevOps.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"
BUILD_DIR="$HOME/dev_build/demoDevOps"
#OVERLAY_DIR="${OVERLAY_DIR:-/mnt/c/DevProjects/demoDevOps}"
APP_HEALTH_URL="http://localhost:8081/actuator/health"

echo "🧹 Cleaning build dir..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "⬇️ Cloning $GIT_URL#$GIT_BRANCH ..."
git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_URL" "$BUILD_DIR"
cd "$BUILD_DIR" || { echo "❌ Cannot cd to $BUILD_DIR"; exit 1; }

# === NEW: Clone full project from Git + overlay local changes ===
WSL_COPY_DIR="/home/ser/projects/demoDevOps"
SRC_WIN="/mnt/c/DevProjects/demoDevOps"

echo "🌐 Cloning fresh project from Git..."
sudo rm -rf "$WSL_COPY_DIR"
git clone --depth 1 --branch main https://github.com/nupsol-lab/demoDevOps.git "$WSL_COPY_DIR"

# === Apply local overlay (optional, only what Windows can read) ===
if [ -d "$SRC_WIN" ]; then
  echo "🔁 Applying local overlay from $SRC_WIN..."
  rsync -a \
    --exclude 'build/' \
    --exclude '.gradle/' \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    --exclude 'src/main/java/com/example/demodevops/ccp/' \
    "$SRC_WIN"/ "$WSL_COPY_DIR"/ || true

else
  echo "⚠️ No local overlay found at $SRC_WIN"
fi

echo "✅ Project ready in $WSL_COPY_DIR"
cd "$WSL_COPY_DIR"


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
echo "🔎 Checking core modules..."
CURRENT_USER=$(whoami)

if [[ "$CURRENT_USER" == "smp_user" ]]; then
  need=("smp")
elif [[ "$CURRENT_USER" == "ccp_user" ]]; then
  need=("ccp")
else
  need=("smp" "ccp")
fi

for module in "${need[@]}"; do
  base="src/main/java/com/example/demodevops/$module"
  if [[ -d "$base" ]]; then
    find "$base" -type f -name '*.java' | head -n1 >/dev/null \
      || { echo "❌ No .java found in: $base"; exit 1; }
  else
    echo "⚠️ Folder missing: $base (ignored for $CURRENT_USER)"
  fi
done

echo "✅ Pre-check OK for user: $CURRENT_USER"


# === Docker build & run ===
echo "🐳 Docker prune (safe)…"
docker system prune -f >/dev/null 2>&1 || true

echo "🛠️ Building and starting containers..."
docker compose -f docker-compose.dev.yml up --build -d


exit 1
