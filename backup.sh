#!/bin/bash

BACKUP_DIR="/var/backups/postgres"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="basebackup_$TIMESTAMP.tar.gz"
TARGET_DIR="$BACKUP_DIR/$BACKUP_NAME"

mkdir -p "$BACKUP_DIR"

LEADER=$(curl -s http://localhost:8008 | grep '"role": "leader"')
if [[ $LEADER != "" ]]; then
  sudo -u postgres pg_basebackup -F tar -X fetch -z -P \
    -D "$BACKUP_DIR/basebackup_$TIMESTAMP" > "$BACKUP_DIR/backup_$TIMESTAMP.log" 2>&1
  cd "$BACKUP_DIR" || exit
  tar -czf "$BACKUP_NAME" "basebackup_$TIMESTAMP"
  rm -rf "basebackup_$TIMESTAMP"
  ls -tp "$BACKUP_DIR"/basebackup_*.tar.gz | grep -v '/$' | tail -n +4 | xargs -I {} rm -- {}