#!/bin/bash
# =====================================
# IviDoc AI-Profil Setup
# Aktiviert Ollama LLM + Paperless-AI
# =====================================

set -e

echo "🤖 IviDoc AI-Profil Setup"
echo "=========================="
echo ""

# -------------------
# Check Docker
# -------------------
if ! command -v docker &> /dev/null; then
    echo "❌ Docker nicht gefunden!"
    echo "   Bitte erst: ./setup.sh --ai"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo "❌ Docker läuft nicht!"
    if command -v colima &> /dev/null; then
        echo "🚀 Starte Colima..."
        colima start --arch aarch64 --cpu 4 --memory 8
    else
        echo "   Bitte Docker Desktop starten."
        exit 1
    fi
fi

echo "✅ Docker läuft"
echo ""

# Prüfen ob Basis-System läuft
if ! docker compose ps | grep -q "paperless.*running"; then
    echo "❌ Paperless läuft nicht!"
    echo "   Bitte erst Basis-System starten: docker compose up -d"
    exit 1
fi

echo "✓ Basis-System läuft"
echo ""

# AI-Profil starten
echo "🚀 Starte AI-Services (Ollama + Paperless-AI)..."
docker compose --profile ai up -d

echo ""
echo "⏳ Warte auf Ollama-Start (15 Sek)..."
sleep 15

# Modell-Empfehlungen
echo ""
echo "📚 LLM-Modell installieren:"
echo ""
echo "Empfohlene Modelle für M4 MacBook Air:"
echo ""
echo "1. LeoLM 13B (DEUTSCH) - Beste Wahl für deutsche Dokumente"
echo "   ./install-leolm.sh"
echo "   Größe: ~7.5 GB"
echo ""
echo "2. Llama 3.2 (3B) - Schnell, Deutsch OK"
echo "   docker compose exec ollama ollama pull llama3.2"
echo "   Größe: ~2.8 GB"
echo ""
echo "3. Qwen2.5 (14B) - Sehr gut für Dokumente"
echo "   docker compose exec ollama ollama pull qwen2.5:14b"
echo "   Größe: ~9 GB"
echo ""
read -p "Möchten Sie jetzt LeoLM 13B (Deutsch) installieren? (j/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo ""
    echo "📥 Starte LeoLM Installation..."
    cd "$(dirname "$0")"
    chmod +x install-leolm.sh
    ./install-leolm.sh
fi

echo ""
echo "================================================"
echo "✅ AI-Profil ist aktiv!"
echo "================================================"
echo ""
echo "🌐 Paperless-NGX: http://localhost:8000"
echo "🤖 Ollama API:    http://localhost:11434"
echo ""
echo "📊 Status prüfen:"
echo "   docker compose ps"
echo ""
echo "💡 Modell wechseln:"
echo "   docker compose exec ollama ollama list"
echo "   docker compose exec ollama ollama pull <model>"
echo ""
echo "🛑 AI-Services stoppen:"
echo "   docker compose stop ollama paperless-ai"
echo ""
echo "================================================"
