#!/bin/bash
# =====================================
# LeoLM 13B Installation für IviDoc
# Deutsches LLM optimiert für Dokumenten-Analyse
# =====================================

set -e

echo "🇩🇪 LeoLM 13B GGUF Installation"
echo "==============================="
echo ""

# Check Docker/Ollama
if ! docker compose ps | grep -q ollama; then
    echo "❌ Ollama läuft nicht!"
    echo "   Bitte erst starten: docker compose --profile ai up -d"
    exit 1
fi

echo "✅ Ollama läuft"
echo ""

# Download-Verzeichnis
MODELS_DIR="$HOME/.ollama/models"
mkdir -p "$MODELS_DIR"

# LeoLM 13B GGUF URL (HuggingFace)
MODEL_URL="https://huggingface.co/TheBloke/leo-hessianai-13B-chat-GGUF/resolve/main/leo-hessianai-13b-chat.Q4_K_M.gguf"
MODEL_FILE="$MODELS_DIR/leo-hessianai-13b-chat.Q4_K_M.gguf"

# Download falls nicht vorhanden
if [ ! -f "$MODEL_FILE" ]; then
    echo "📥 Lade LeoLM 13B GGUF herunter (~7.4 GB)..."
    echo "   Dies kann 5-20 Min dauern..."
    curl -L --progress-bar "$MODEL_URL" -o "$MODEL_FILE"
    echo ""
    echo "✅ Download abgeschlossen"
else
    echo "✅ Modell bereits heruntergeladen"
fi

echo ""

# Modelfile erstellen
MODELFILE_PATH="$MODELS_DIR/Modelfile-leolm"
cat > "$MODELFILE_PATH" << 'EOF'
FROM /root/.ollama/models/leo-hessianai-13b-chat.Q4_K_M.gguf

TEMPLATE """{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
{{ end }}<|im_start|>assistant
"""

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
PARAMETER stop "<|im_start|>"
PARAMETER stop "<|im_end|>"

SYSTEM """Du bist ein hilfreicher deutscher Assistent, spezialisiert auf die Analyse von Dokumenten wie Rechnungen, Verträgen und Briefen. Du extrahierst präzise Informationen und antwortest immer auf Deutsch."""
EOF

echo "📋 Erstelle Modelfile..."

# In Docker-Container kopieren und importieren
echo "📦 Kopiere Modell in Ollama-Container..."
docker cp "$MODEL_FILE" ividoc-ollama-1:/root/.ollama/models/
docker cp "$MODELFILE_PATH" ividoc-ollama-1:/root/.ollama/models/Modelfile

echo ""
echo "🔧 Importiere in Ollama..."
docker compose exec ollama bash -c "cd /root/.ollama/models && ollama create leolm-german:13b -f Modelfile"

echo ""
echo "✅ LeoLM 13B erfolgreich installiert!"
echo ""

# Test
echo "🧪 Teste Modell..."
echo ""
TEST_PROMPT="Analysiere diesen Text und extrahiere das Datum: 'Rechnung vom 15.03.2024 über 199,99 EUR'"

echo "Prompt: $TEST_PROMPT"
echo ""
echo "Antwort:"
docker compose exec ollama ollama run leolm-german:13b "$TEST_PROMPT"

echo ""
echo "================================================"
echo "✅ Installation abgeschlossen!"
echo "================================================"
echo ""
echo "📚 Verwendung:"
echo "   docker compose exec ollama ollama run leolm-german:13b"
echo ""
echo "💡 Für Paperless-AI:"
echo "   1. Web-UI → Settings → AI"
echo "   2. Model: leolm-german:13b"
echo "   3. Endpoint: http://ollama:11434"
echo ""
echo "🗑️  Modell löschen:"
echo "   docker compose exec ollama ollama rm leolm-german:13b"
echo ""
echo "================================================"

# =====================================
# LeoLM 13B GGUF Installation für IviDoc
# Deutsches LLM speziell für Dokumenten-Analyse
# =====================================

set -e

echo "🇩🇪 LeoLM 13B Installation"
echo "=========================="
echo ""

# Check Docker läuft
if ! docker compose ps | grep -q ollama; then
    echo "❌ Ollama läuft nicht!"
    echo "   Starte zuerst: docker compose --profile ai up -d"
    exit 1
fi

echo "✅ Ollama läuft"
echo ""

# Download directory
MODELS_DIR="$HOME/.ollama/models"
mkdir -p "$MODELS_DIR"

# LeoLM GGUF herunterladen
echo "📥 Lade LeoLM 13B GGUF herunter (~7.5 GB)..."
echo "   Quelle: HuggingFace - LeoLM/leo-hessianai-13b-chat"
echo ""

cd "$MODELS_DIR"

# Download mit curl (mit Progress)
if [ ! -f "leo-hessianai-13b-chat.Q4_K_M.gguf" ]; then
    curl -L --progress-bar \
        -o leo-hessianai-13b-chat.Q4_K_M.gguf \
        "https://huggingface.co/TheBloke/leo-hessianai-13B-chat-GGUF/resolve/main/leo-hessianai-13b-chat.Q4_K_M.gguf"
    echo ""
    echo "✅ Download abgeschlossen"
else
    echo "✅ GGUF bereits vorhanden"
fi

# Modelfile erstellen
echo ""
echo "📝 Erstelle Modelfile..."

cat > Modelfile << 'EOF'
FROM leo-hessianai-13b-chat.Q4_K_M.gguf

TEMPLATE """{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
{{ end }}<|im_start|>assistant
"""

PARAMETER stop "<|im_start|>"
PARAMETER stop "<|im_end|>"
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40

SYSTEM """Du bist ein KI-Assistent, spezialisiert auf die Analyse deutscher Dokumente. Du hilfst bei:
- OCR-Nachbearbeitung und Fehlerkorrektur
- Extraktion von strukturierten Daten (Rechnungsnummern, Daten, Beträge)
- Zusammenfassungen von Dokumenten
- Kategorisierung und Verschlagwortung

Antworte präzise und auf Deutsch."""
EOF

echo "✅ Modelfile erstellt"

# In Docker-Container kopieren
echo ""
echo "📦 Importiere Modell in Ollama..."

# Dateien in Container kopieren
docker compose cp "$MODELS_DIR/leo-hessianai-13b-chat.Q4_K_M.gguf" ollama:/tmp/
docker compose cp "$MODELS_DIR/Modelfile" ollama:/tmp/

# Modell erstellen
docker compose exec ollama sh -c "cd /tmp && ollama create leolm:13b -f Modelfile"

echo ""
echo "✅ LeoLM 13B erfolgreich installiert!"

# Aufräumen
rm -f "$MODELS_DIR/Modelfile"

# Test
echo ""
echo "🧪 Teste Modell..."
docker compose exec ollama ollama run leolm:13b "Analysiere folgenden Text und extrahiere die Rechnungsnummer: Rechnung Nr. 2024-12345 vom 15.01.2024, Gesamtbetrag: 1.234,56 EUR"

echo ""
echo "================================================"
echo "✅ LeoLM 13B ist bereit!"
echo "================================================"
echo ""
echo "📊 Verwendung:"
echo "   docker compose exec ollama ollama run leolm:13b \"<prompt>\""
echo ""
echo "🔧 Paperless-AI Konfiguration:"
echo "   In Web-UI: Settings → Paperless-AI"
echo "   Model: leolm:13b"
echo ""
echo "📝 Verfügbare Modelle:"
echo "   docker compose exec ollama ollama list"
echo ""
echo "💾 Speicherort: $MODELS_DIR"
echo "   Größe: ~7.5 GB"
echo ""
echo "================================================"
