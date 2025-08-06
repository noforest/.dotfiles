#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
SRC1="$HOME/Documents"                            # première source
SRC2="$HOME/Pictures/from_twitter"                # deuxième source
BASE_REMOTE="gdrive:_BackupsLinux"                # racine sur Drive
HOST="$(hostname)"                                # nom de la machine
DEST="$BASE_REMOTE/$HOST"                         # dossier principal distant

# === SYNCHRONISATION ===

# Documents
rclone sync \
    --verbose \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --copy-links \
    --fast-list \
    --exclude "*~" \
    --exclude "*.dot" \
    --exclude "*.gcda" \
    --exclude "*.gcno" \
    --exclude "*.o" \
    --exclude "*.out" \
    --exclude ".vscode*" \
    --exclude "dist/**" \
    --exclude "node_modules/**" \
    --exclude "coverage/**" \
    --exclude "package-lock.json" \
    --exclude ".git/**" \
    --exclude "*/.git/**" \
    --exclude "gsl-2.8/**" \
    "$SRC1" \
    "$DEST/Documents"

# Images Twitter
rclone sync \
    --verbose \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --copy-links \
    --fast-list \
    "$SRC2" \
    "$DEST/from_twitter"
