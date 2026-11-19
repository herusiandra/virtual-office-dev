#!/usr/bin/env bash
# Menyalin AGENT.md tiap agent ke .agents/AGENTS.md (format aturan Antigravity; verifikasi di instalasi Anda).
set -euo pipefail
cd "$(dirname "$0")/.."
for d in agent-main agent-sub-dev agent-sub-dev-2 agent-sub-ba agent-sub-uiux agent-sub-qa; do
  mkdir -p "$d/.agents"
  cp "$d/AGENT.md" "$d/.agents/AGENTS.md"
  echo "sinkron: $d/.agents/AGENTS.md"
done
