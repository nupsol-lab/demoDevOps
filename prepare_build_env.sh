#!/bin/bash

# ==============================
# 🚀 Script: prepare_build_env.sh
# Objectif: Builder le projet complet depuis WSL
#            sans casser les ACL Windows.
# ==============================

# === CONFIGURATION ===
SOURCE_DIR="/mnt/c/DevProjects/demoDevOps"
BUILD_DIR="$HOME/dev_build/demoDevOps"
DOCKER_COMPOSE_FILE="docker-compose.yml"
APP_HEALTH_URL="http://localhost:8081/actuator/health"

# === ÉTAPE 1: Nettoyage ancien build ===
echo "🧹 Nettoyage de l'ancien environnement..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# === ÉTAPE 2: Copie du projet vers WSL ===
echo "📁 Copie du projet depuis $SOURCE_DIR vers $BUILD_DIR..."
cp -r --no-preserve=mode,ownership "$SOURCE_DIR/"* "$BUILD_DIR"/

# === ÉTAPE 3: Déplacement dans le dossier du build ===
cd "$BUILD_DIR" || { echo "❌ Impossible d'accéder à $BUILD_DIR"; exit 1; }

# === ÉTAPE 4: Nettoyage Docker et Maven ===
echo "🐳 Nettoyage Docker & Maven..."
docker system prune -f >/dev/null 2>&1
./mvnw clean -q || echo "ℹ️ Maven clean ignoré si wrapper absent."

# === ÉTAPE 5: Build Docker Compose ===
echo "🏗️ Lancement du build Docker..."
docker compose -f "$DOCKER_COMPOSE_FILE" up --build -d

# === ÉTAPE 6: Vérification de la santé de l'application ===
echo "🩺 Vérification du health-check..."
sleep 10  # Attente du démarrage de l'application

if curl -fs "$APP_HEALTH_URL" >/dev/null 2>&1; then
  echo "✅ Application en ligne : $APP_HEALTH_URL"
else
  echo "⚠️ Health-check échoué. Vérifie les logs avec : docker compose logs"
fi

echo "🎯 Build complet terminé avec succès."
