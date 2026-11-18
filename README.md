# Virtual Office — Tim Agent

Tim 5 agent yang bisa mengerjakan berbagai proyek. **Office** (folder ini) berisi tim dan aturan; **proyek** hidup terpisah di `../projects/<nama>/`.

| Agent | Persona | Folder | Peran |
|---|---|---|---|
| Main | **Heru** | `agent-main/` | Project manager & orkestrator |
| Dev | **Rajif** | `agent-sub-dev/` | Developer |
| BA | **Naufal** | `agent-sub-ba/` | Business analyst (reverse-engineering, riset kebutuhan, dokumentasi) |
| UI/UX | **Priyo** | `agent-sub-uiux/` | Desain & audit tampilan |
| QA | **Denis** | `agent-sub-qa/` | QA, audit, code review |

## Pasang
```bash
# komputer Anda
scp virtual-office.zip safewatch@vensys:/home/safewatch/agent/

# server
cd /home/safewatch/agent
unzip virtual-office.zip            # membuat office/ dan projects/
cd office
git init && git add -A && git commit -m "init office"     # repo lokal
./scripts/sync-agents.sh            # salin AGENT.md -> .agents/AGENTS.md tiap agent
```
Folder lama `project-screening` boleh dihapus setelah pindah.

## Menjalankan (herdr + Antigravity) — Mode On-Demand
- Setiap agent memiliki workspace/pane tersendiri di herdr:
  - `wX:p1` -> Heru (`agent-main`)
  - `wY:p1` -> Naufal (`agent-sub-ba`)
  - `w11:p1` -> Priyo (`agent-sub-uiux`)
  - `wZ:p1` -> Rajif (`agent-sub-dev`)
  - `w0:p1` -> Denis (`agent-sub-qa`)
- **Efisiensi RAM (On-Demand Worker)**:
  - Sub-agent tidak perlu dibiarkan terus berjalan di memory server (menghemat ~3.5-4 GB RAM).
  - Sub-agent berada dalam kondisi shell idle. Saat Heru mendelegasikan tugas, Heru memanggil:
    `./scripts/wake-agent.sh <agent> <path-file-tugas> [proyek]`
  - Skrip otomatis mengaktifkan agent (`agy -c -i`), memberikan instruksi tugas.
  - Setelah selesai, sub-agent memindahkan tugas ke `_selesai/`, mengirim hasil ke inbox tujuan, lalu menjalankan `/compact` dan `/exit` untuk melepaskan RAM kembali ke shell idle.
- **Dukungan Multi-Proyek Paralel**:
  - Format serah-terima (`shared/HANDOFF-FORMAT.md`) mewajibkan metadata `proyek: <path-folder-proyek>`, sehingga agent dapat menangani beberapa proyek berbeda tanpa bergantung pada `ACTIVE_PROJECT` global.

## Memulai proyek
1. Buka pane Heru, ceritakan proyek yang diinginkan.
2. Heru mewawancarai Anda (`shared/playbooks/kickoff.md`), mengisi `PROJECT-BRIEF.md`, memilih playbook, lalu **berhenti (BLOCKED)** menunggu persetujuan Anda (Gate 0).
3. Setelah Anda setuju, Heru menjalankan `scripts/new-project.sh <nama> <playbook>` dan mulai mendelegasikan.

Playbook: `clone`, `build-baru`, `dokumentasi` (siap pakai awal), `perbaikan` (draf).

## Keamanan
- Kata sandi hanya di `projects/<nama>/.env` (di `.gitignore`). Jangan menuliskannya di brief atau dokumen.
- Izin akses ke server/sistem ditulis per proyek di brief (*Izin & Lingkup*), bukan di prompt agent.
- Interupsi darurat: `touch projects/<nama>/STOP`.
- Mode otomatis berarti agent bertindak tanpa konfirmasi; batas keras ada di `shared/RULES.md` pasal 1 dan 6, tetapi itu berbasis instruksi. Untuk pembatasan yang benar-benar ditegakkan, gunakan pembatasan workspace Antigravity atau izin OS bila tersedia.

## Catatan
- `SKILLS.md` ditulis dari nama dan peran skill; cocokkan dengan dokumentasi skill asli.
- Skill Heru: humanizer, find-skill, herdr. Tambah lewat find-skill bila perlu.
- Telegram: dibuat setelah setup selesai (`shared/NOTIFIKASI.md`).
