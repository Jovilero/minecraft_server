#!/bin/bash

# Configuración
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="backup-$TIMESTAMP.tar.gz"
BACKUP_DIR="./backups"
DATA_DIR="./data"
CHECKSUM_FILE="./.last-backup.md5"
TMP_CHECKSUM="./.current.md5"

# Crear carpeta de backups si no existe
mkdir -p "$BACKUP_DIR"

# Calcular checksum actual del contenido del mundo
find "$DATA_DIR" -type f -exec md5sum {} \; | sort -k 2 > "$TMP_CHECKSUM"

# Si no hay cambios, salir
if cmp -s "$TMP_CHECKSUM" "$CHECKSUM_FILE"; then
  echo "[✔] No hay cambios en los archivos del mundo. No se realiza backup."
  rm -f "$TMP_CHECKSUM"
  exit 0
fi

# Guardar nuevo checksum
mv "$TMP_CHECKSUM" "$CHECKSUM_FILE"

# Crear backup .tar.gz
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$DATA_DIR" .
echo "[⬆] Backup creado: $BACKUP_NAME"

# Mantener solo los últimos 10 backups
cd "$BACKUP_DIR"
ls -tp | grep -v '/$' | tail -n +11 | xargs -I {} rm -- {}
cd ..

# Subir a Git
cd "$BACKUP_DIR"
git add .
git commit -m "Backup automático: $BACKUP_NAME" || echo "[ℹ️] No hay cambios para commit."
git push origin main
cd ..

echo "[✅] Backup subido a Git correctamente."
