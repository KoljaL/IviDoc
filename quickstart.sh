#!/bin/bash
# =====================================
# IviDoc Quick-Start mit AI
# Automatische Installation, keine Fragen
# =====================================

set -e

echo "🚀 IviDoc Quick-Start (mit AI)"
echo "==============================="
echo ""

# -------------------
# Auto-Install Docker CLI
# -------------------
if ! command -v docker &> /dev/null; then
    echo "📦 Installiere Docker CLI..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -LO https://download.docker.com/mac/static/stable/aarch64/docker-24.0.5.tgz 2>/dev/null
    tar xzf docker-24.0.5.tgz 2>/dev/null
    sudo mv docker/* /usr/local/bin/
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Docker CLI"
fi

# -------------------
# Auto-Install Docker Compose
# -------------------
if ! docker compose version &> /dev/null; then
    echo "📦 Installiere Docker Compose..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -L https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-darwin-aarch64 -o docker-compose 2>/dev/null
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin/
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Docker Compose"
fi

# -------------------
# Auto-Install Colima
# -------------------
if ! command -v colima &> /dev/null; then
    echo "📦 Installiere Colima..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -LO https://github.com/abiosoft/colima/releases/download/v0.6.14/colima-darwin-arm64 2>/dev/null
    chmod +x colima-darwin-arm64
    sudo mv colima-darwin-arm64 /usr/local/bin/colima
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Colima"
fi

# -------------------
# Start Colima
# -------------------
if ! docker ps &> /dev/null; then
    echo "🚀 Starte Colima..."
    colima start --arch aarch64 --cpu 4 --memory 8 2>/dev/null || colima start
    echo "✅ Docker läuft"
fi

# Ordner erstellen
mkdir -p consume data media export

# Scripts ausführbar machen
chmod +x setup.sh backup.sh ai-setup.sh 2>/dev/null || true

# Starten
echo "📦 Starte System mit AI-Profil..."
docker compose --profile ai up -d

echo ""
echo "✅ System läuft!"
echo ""
echo "🌐 http://localhost:8000"
echo "👤 admin / admin (sofort ändern!)"
echo ""
echo "📱 PDFs hierhin: ./consume/"
echo ""
echo "🤖 LLM installieren:"
echo "   docker compose exec ollama ollama pull llama3.2"
echo ""
