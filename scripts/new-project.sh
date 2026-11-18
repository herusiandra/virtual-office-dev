#!/usr/bin/env bash
# Pemakaian: new-project.sh <nama-proyek> <playbook>
# playbook: clone | build-baru | dokumentasi | perbaikan
set -euo pipefail
NAME="${1:-}"; PB="${2:-}"
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "Nama proyek: huruf kecil, angka, tanda hubung."; exit 1; }
case "$PB" in clone|build-baru|dokumentasi|perbaikan) ;; *) echo "Playbook harus: clone | build-baru | dokumentasi | perbaikan"; exit 1;; esac

OFFICE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS="$(dirname "$OFFICE")/projects"
P="$PROJECTS/$NAME"
[ ! -e "$P" ] || { echo "Proyek sudah ada: $P"; exit 1; }

mkdir -p "$P"
cp "$OFFICE/shared/templates/PROJECT-BRIEF.md" "$P/PROJECT-BRIEF.md"
cp "$OFFICE/shared/templates/STATE.md" "$P/STATE.md"
sed -i "s/<nama-proyek>/$NAME/g; s/^Playbook:.*/Playbook: $PB/; s/^- Playbook:.*/- Playbook: $PB/" "$P/PROJECT-BRIEF.md" "$P/STATE.md"
mkdir -p "$P/spec"
cp "$OFFICE/shared/templates/MODULES.md" "$P/spec/MODULES.md"
for d in 00-survey 01-analisis 02-ui-plan 03-ui-design 04-code-plan 05-acceptance 06-qa-feedback 07-parity 08-dokumentasi; do
  mkdir -p "$P/workspace/$d"; touch "$P/workspace/$d/.gitkeep"
done
touch "$P/workspace/01-analisis/server-actions.log"
for a in heru rajif naufal priyo denis; do
  mkdir -p "$P/inbox/$a/_selesai"; touch "$P/inbox/$a/.gitkeep"
done
cat > "$P/.env.example" <<'ENV'
# Salin menjadi .env lalu isi sendiri. JANGAN commit .env.
SOURCE_HOST=
SOURCE_USER=
SOURCE_PASSWORD=
SOURCE_DB_HOST=
SOURCE_DB_USER=
SOURCE_DB_PASSWORD=
SOURCE_APP_URL=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
ENV
printf '.env\nSTOP\n*.bak\n' > "$P/.gitignore"
( cd "$P" && git init -q && git add -A && git -c user.name="office" -c user.email="office@local" commit -qm "init proyek $NAME ($PB)" )
echo "$P" > "$OFFICE/ACTIVE_PROJECT"
echo "Proyek dibuat: $P"
echo "ACTIVE_PROJECT -> $P"
echo "Langkah berikut: tempel brief yang disetujui ke PROJECT-BRIEF.md; salin .env.example ke .env bila ada akses."
