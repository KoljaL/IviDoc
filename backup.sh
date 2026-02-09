#!/bin/bash
# =====================================
# IviDoc Backup-Script
# Speichert auf externe Festplatte
# =====================================

set -e

# Check Docker
if ! docker compose ps | grep -q paperless; then
    echo "❌ Paperless läuft nicht!"
    exit 1
fi

# Konfiguration
BACKUP_DIR="/Volumes/ExterneFestplatte/IviDoc-Backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup-$TIMESTAMP"

echo "🔄 IviDoc Backup gestartet..."
echo "📅 Zeitstempel: $TIMESTAMP"

# Prüfen ob externe Festplatte gemountet ist
if [ ! -d "/Volumes/ExterneFestplatte" ]; then
    echo "❌ Externe Festplatte nicht gefunden!"
    echo "   Bitte anschließen: /Volumes/ExterneFestplatte"
    exit 1
fi

# Backup-Verzeichnis erstellen
mkdir -p "$BACKUP_PATH"

# Paperless Export (inkl. Dokumente & Metadaten)
echo "📦 Exportiere Paperless-Daten..."
docker compose exec -T paperless document_exporter /usr/src/paperless/export/backup-$TIMESTAMP

# Vollständiges Backup aller Ordner
echo "💾 Kopiere alle Daten..."
rsync -av --progress \
    ./data \
    ./media \
    ./export \
    "$BACKUP_PATH/"

# Zusätzlich: docker-compose.yml sichern
cp docker-compose.yml "$BACKUP_PATH/"

# Backup-Info erstellen
cat > "$BACKUP_PATH/backup-info.txt" << EOF
IviDoc Backup
=============
Datum: $(date)
Timestamp: $TIMESTAMP
Host: $(hostname)
Paperless Version: $(docker compose exec -T paperless cat /usr/src/paperless/src/paperless/version.py | grep "__version__" || echo "unknown")

Inhalt:
- data/   - Datenbank & Konfiguration
- media/  - Verarbeitete Dokumente
- export/ - Paperless-Export mit Metadaten
- docker-compose.yml

Wiederherstellung:
1. IviDoc-Ordner neu erstellen
2. docker-compose.yml kopieren
3. data/ und media/ zurückkopieren
4. docker compose up -d
EOF

# Alte Backups aufräumen (älter als 30 Tage)
echo "🧹 Räume alte Backups auf..."
find "$BACKUP_DIR" -type d -name "backup-*" -mtime +30 -exec rm -rf {} + 2>/dev/null || true

# Backup-Größe anzeigen
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)

echo ""
echo "✅ Backup erfolgreich!"
echo "📁 Speicherort: $BACKUP_PATH"
echo "💾 Größe: $BACKUP_SIZE"
echo ""
echo "Vorhandene Backups:"
ls -lth "$BACKUP_DIR" | head -5
