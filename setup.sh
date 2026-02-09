#!/bin/bash
# =====================================
# IviDoc Setup - M4 MacBook Air
# Paperless-NGX + optional AI
# CLI-only, no Docker Desktop required
# =====================================

set -e

# Parse arguments
WITH_AI=false
for arg in "$@"; do
  [[ "$arg" == "--ai" ]] && WITH_AI=true
done

echo "🚀 IviDoc Setup"
if $WITH_AI; then
    echo "   🤖 Mit AI-Profil (Ollama + Paperless-AI)"
else
    echo "   📦 Standard (ohne AI)"
fi
echo ""

# -------------------
# Check/Install Docker CLI
# -------------------
if ! command -v docker &> /dev/null; then
    echo "📦 Installiere Docker CLI..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -LO https://download.docker.com/mac/static/stable/aarch64/docker-24.0.5.tgz
    tar xzf docker-24.0.5.tgz
    sudo mv docker/* /usr/local/bin/
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Docker CLI installiert"
else
    echo "✅ Docker CLI: $(docker --version)"
fi

# -------------------
# Check/Install Docker Compose
# -------------------
if ! docker compose version &> /dev/null; then
    echo "📦 Installiere Docker Compose..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -L https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-darwin-aarch64 -o docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin/
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Docker Compose installiert"
else
    echo "✅ Docker Compose: $(docker compose version)"
fi

# -------------------
# Check/Install Colima
# -------------------
if ! command -v colima &> /dev/null; then
    echo "📦 Installiere Colima (Docker VM)..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1
    curl -LO https://github.com/abiosoft/colima/releases/download/v0.6.14/colima-darwin-arm64
    chmod +x colima-darwin-arm64
    sudo mv colima-darwin-arm64 /usr/local/bin/colima
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    echo "✅ Colima installiert"
else
    echo "✅ Colima: $(colima version 2>/dev/null || echo 'installed')"
fi

# -------------------
# Start Colima VM
# -------------------
if ! docker ps &> /dev/null; then
    echo "🚀 Starte Colima VM (4 CPU, 8 GB RAM)..."
    colima start --arch aarch64 --cpu 4 --memory 8 2>/dev/null || colima start
    echo "✅ Colima läuft"
else
    echo "✅ Docker Engine läuft"
fi

# Ordner erstellen
echo ""
echo "📁 Erstelle Ordnerstruktur..."
mkdir -p consume data media export

echo "✓ consume/  - Für Smartphone-Scans"
echo "✓ data/     - Paperless Datenbank"
echo "✓ media/    - Verarbeitete Dokumente"
echo "✓ export/   - Für Backups"

# Scripts ausführbar machen (wenn vorhanden)
[ -f backup.sh ] && chmod +x backup.sh
[ -f ai-setup.sh ] && chmod +x ai-setup.sh

# Docker-Images herunterladen
echo ""
if $WITH_AI; then
    echo "📥 Lade Docker-Images herunter (7 Container inkl. AI, dauert 5-10 Min)..."
    docker compose --profile ai pull
else
    echo "📥 Lade Docker-Images herunter (5 Container, dauert 3-8 Min)..."
    docker compose pull
fi

# System starten
echo ""
if $WITH_AI; then
    echo "🏁 Starte Paperless-NGX mit AI-Profil..."
    docker compose --profile ai up -d
else
    echo "🏁 Starte Paperless-NGX..."
    docker compose up -d
fi

# Warten bis System bereit ist
echo ""
echo "⏳ Warte auf System-Start (60-90 Sek, Tika braucht Zeit)..."
sleep 15

for i in {1..18}; do
    if docker compose exec -T paperless python manage.py showmigrations &> /dev/null 2>&1; then
        echo ""
        echo "✅ System ist bereit!"
        break
    fi
    echo -n "."
    sleep 5
done

echo ""
echo ""
echo "================================================"
echo "✅ IviDoc ist fertig eingerichtet!"
echo "================================================"
echo ""
echo "🌐 Web-Interface: http://localhost:8000"
echo ""
echo "🔐 Login:"
echo "   Benutzername: admin"
echo "   Passwort:     admin"
echo "   ⚠️  BITTE SOFORT ÄNDERN!"
echo ""
echo "📱 Smartphone-Scans:"
echo "   PDFs in diesen Ordner kopieren:"
echo "   $(pwd)/consume/"
echo ""
echo "💡 Nächste Schritte:"
echo "   1. http://localhost:8000 öffnen"
echo "   2. Einloggen & Passwort ändern"
echo "   3. Settings → OCR → Sprache prüfen (Deutsch)"
echo "   4. Test-PDF in consume/ Ordner kopieren"

if $WITH_AI; then
    echo ""
    echo "🤖 AI-Features aktiviert:"
    echo "   • Ollama läuft auf Port 11434"
    echo "   • Paperless-AI ist aktiv"
    echo ""
    echo "📚 LLM-Modell installieren:"
    echo "   docker compose exec ollama ollama pull llama3.2"
    echo "   docker compose exec ollama ollama pull mistral"
else
    echo ""
    echo "💡 AI später aktivieren:"
    echo "   ./ai-setup.sh"
    echo "   # oder:"
    echo "   docker compose --profile ai up -d"
fi

echo ""
echo "📊 Status:"
echo "   docker compose ps"
echo ""
echo "🛑 Stoppen:"
echo "   docker compose stop"
echo ""
echo "================================================"
