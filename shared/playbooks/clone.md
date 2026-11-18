# PLAYBOOK: CLONE (meniru aplikasi yang sudah ada)

Pekerjaan per **modul**. Heru memilih urutan modul bersama Naufal di Fase 0.

**Fase 0 — Survei**: Heru → Naufal membuat peta modul (`workspace/00-survey/peta-modul.md`: modul, ketergantungan, urutan saran). Heru menyusun `spec/MODULES.md`. (Brief dan definisi kemiripan sudah disetujui di Gate 0.)

| Fase | Pelaku | Hasil |
|---|---|---|
| F1 Perintah | Heru → Naufal | tugas riset modul (`templates/perintah-ke-ba.md`) |
| F2 Riset & spec | Naufal (mode reverse-engineering) | `spec/<modul>/spec.md`, bukti, plan UI |
| F2b Konfirmasi | Heru | konfirmasi atau revisi |
| F3 Review spec | Denis | review spec + acceptance criteria |
| **Gate A** | Pengguna | persetujuan spec (Heru BLOCKED) |
| F4 Desain & audit | Priyo | desain per `SCR-`, audit vs backend |
| **Gate B** | Pengguna | persetujuan desain |
| F5a Code plan | Rajif → Heru | rencana kode disetujui |
| F5b Coding | Rajif | kode + tes |
| F6a QA | Denis | matriks kesesuaian, tes, review, keamanan |
| F6b Uji banding | Naufal | selisih perilaku sistem asli vs hasil (`workspace/07-parity/<modul>/`); Denis memasukkan selisih valid sebagai temuan |
| F7 Perbaikan | Rajif ⇄ Denis | maks. 3 putaran, lalu eskalasi |
| F8 Tutup | Denis → Heru | sign-off, STATE.md, tag `<modul>/qa-pass` |

F6a dan F6b berjalan bersamaan.
