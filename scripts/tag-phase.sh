#!/usr/bin/env bash
# Pemakaian: tag-phase.sh <modul> <fase> [pesan]   (bekerja di proyek aktif)
set -euo pipefail
[ $# -ge 2 ] || { echo "Pemakaian: $0 <modul> <fase> [pesan]"; exit 1; }
OFFICE="$(cd "$(dirname "$0")/.." && pwd)"
P="${PROJECT_DIR:-$(cat "$OFFICE/ACTIVE_PROJECT")}"
[ -d "$P/.git" ] || { echo "Proyek aktif tidak valid: $P"; exit 1; }
cd "$P"
git add -A
ID=()
git config user.email >/dev/null 2>&1 || ID=(-c user.name=office -c user.email=office@local)
git "${ID[@]}" commit -m "${1}/${2}: ${3:-serah-terima fase}" 2>/dev/null || true
git tag -f "${1}/${2}"
echo "Tag dibuat: ${1}/${2}"
