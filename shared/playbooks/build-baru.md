# PLAYBOOK: BANGUN APLIKASI BARU

Tidak ada sistem sumber; kebutuhan datang dari pengguna.

| Fase | Pelaku | Hasil |
|---|---|---|
| F0 Pemetaan | Heru + Naufal (mode riset kebutuhan) | daftar modul, prioritas, urutan |
| F1 Kebutuhan | Naufal | per modul: spec ber-ID (fitur, aturan, data, layar, error) dari wawancara/dokumen pengguna; hal belum jelas ditulis sebagai pertanyaan ke pengguna lewat Heru |
| F2 Konfirmasi | Heru | konfirmasi spec |
| F3 Review spec | Denis | review + acceptance criteria |
| **Gate A** | Pengguna | persetujuan spec |
| F4 Desain & audit | Priyo | desain per `SCR-`, audit |
| **Gate B** | Pengguna | persetujuan desain |
| F5a/b Code plan & coding | Rajif (Heru menyetujui plan) | kode + tes |
| F6 QA | Denis | matriks kesesuaian, tes, review, keamanan |
| F7 Perbaikan | Rajif ⇄ Denis | maks. 3 putaran |
| F8 Tutup | Denis → Heru | sign-off, tag |

Tidak ada uji banding. Stack dan lingkungan uji mengikuti brief.
