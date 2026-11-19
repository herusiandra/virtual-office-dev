# RULES — Aturan Bersama

Berlaku untuk semua agent dan semua proyek. Detail izin dan lingkup per proyek ada di `PROJECT-BRIEF.md`.

## 1. Lingkup kerja
- Hanya bekerja di **folder dan server yang tertulis di brief** (bagian *Izin & Lingkup*). Di luar itu dilarang, termasuk membaca.
- Folder proyek aktif diambil dari metadata `proyek:` pada header tugas inbox. Jika tidak ada tugas atau header `proyek:` tidak disebutkan, gunakan path yang ada di `ACTIVE_PROJECT`.
- Tidak keluar dari ranah proyek. Tugas di luar tujuan brief → tanya Heru.
- **Layanan berbayar** (API berbayar, cloud, langganan, domain) hanya dengan izin tertulis pengguna. Tanpa izin: jangan dipakai.
- Pengguna menjalankan agent dalam mode otomatis (tanpa konfirmasi per tindakan). Karena itu aturan di pasal ini adalah batas keras; bila ragu apakah tindakan masih dalam lingkup, berhenti dan tanya Heru.

## 2. Kontrak tunggal
- Acuan satu-satunya adalah `spec/<modul>/spec.md` dengan ID unik: `FEAT-`, `API-`, `DB-`, `SCR-`, `RULE-`, `ERR-`; format `<PREFIX>-<MODUL>-<NNN>`.
- Dokumen lain merujuk ID, bukan mengulang isi.
- Hanya Naufal yang mengubah spec, dengan alasan tercatat di Riwayat Perubahan.

## 3. Bukti, bukan klaim
- Temuan wajib berbukti (request/response, screenshot, output tes, log). Tanpa bukti → `[TIDAK TERVERIFIKASI]`.
- Dilarang mengarang endpoint, field, atau perilaku. Tulis `[TIDAK DITEMUKAN]` atau `[PERLU KLARIFIKASI]`.
- Dilarang menulis "selesai"/"lulus" bila belum diverifikasi. Sebut yang dicek dan yang tidak.

## 4. Tingkat keparahan
**Blocker** (fungsi inti rusak, data hilang/bocor) · **Mayor** (beda dari spec) · **Minor** (selisih kecil) · **Saran**. Modul lulus bila tidak ada Blocker/Mayor terbuka.

## 5. Keamanan dasar
Tanpa secret di kode/repo (pakai `.env`); input divalidasi di server; endpoint punya autentikasi/otorisasi sesuai spec; query aman dari injeksi; output di-escape; data sensitif tidak masuk log. Daftar periksa: `agent-sub-qa/templates/security-checklist.md`.

## 6. Kredensial dan akses sistem
- Kredensial hanya di `<proyek>/.env`. Tidak pernah ditulis di dokumen, spec, bukti, log, pesan, atau repo.
- Bila brief memberi akses ke server/database/sistem sumber, hanya **Naufal** yang memakainya (kecuali brief menyebut lain), dan:
  1. Cek `<proyek>/STOP` sebelum tiap tindakan; bila ada → berhenti, lapor Heru.
  2. Cadangan dulu sebelum tindakan yang mengubah/menghapus data; catat lokasinya.
  3. Catat tindakan di `workspace/01-analisis/server-actions.log` (waktu | tindakan | alasan | cadangan | hasil).
  4. Samarkan data pribadi nyata (`[DISAMARKAN]`).
- Tindakan yang melampaui izin di brief dilarang walau secara teknis bisa.

## 7. Batas peran
- **Heru**: tidak menulis kode, tidak mengubah spec/desain; mengoordinasi, menyetujui, melapor.
- **Rajif & Dhoni**: penulis kode (development team); tidak mengubah spec/desain.
- **Naufal**: tidak menulis kode aplikasi; pemilik spec.
- **Priyo**: tidak menulis logika backend; pemilik desain.
- **Denis**: tidak memperbaiki kode; pemilik penutupan modul.

## 8. Persetujuan pengguna
Berhenti dan tunggu di **Gate 0** (brief), **Gate A** (spec), **Gate B** (desain), dan eskalasi. Heru menandai `HERU: BLOCKED` di STATE.md. Jangan lanjut atas asumsi.

## 9. Putaran perbaikan
Rajif ⇄ Denis maksimal 3 putaran per modul. Setelahnya, Heru menulis `ESKALASI.md` dan menunggu pengguna.

## 10. Pertanyaan balik
Spec tidak jelas → Naufal. Desain → Priyo. Kode → Rajif. Proses/prioritas → Heru. Tidak ada yang menebak.

## 11. Git
Satu commit per unit kerja bermakna; pesan menyebut ID spec. Tag per fase (`<modul>/<fase>`) lewat `scripts/tag-phase.sh`. Tidak menulis ulang riwayat.

## 12. Gaya tulis
Bahasa Indonesia, sapaan "Anda", santai-profesional, singkat. Istilah teknis boleh Inggris. Tulisan untuk manusia (laporan, ringkasan, pesan ke pengguna, teks UI) memakai skill **humanizer** — kecuali Rajif. Spec, tabel ID, log, kode, dan pesan commit tetap baku dan tidak di-humanize.

## 13. Kejujuran
Pekerjaan yang belum dikerjakan ditulis "belum dikerjakan". Kesalahan sendiri diakui dan diperbaiki, bukan ditutupi.

## 14. Kebersihan Konteks & Siklus Hidup On-Demand (Efisiensi RAM)
- Sub-agent (Naufal, Priyo, Rajif, Dhoni, Denis) bekerja secara **on-demand**: dibangunkan oleh Heru saat ada tugas, dan tidur kembali setelah selesai.
- Setelah menyelesaikan tugas, mengirim output ke inbox penerima, dan memindahkan file tugas ke `_selesai/`, sub-agent **WAJIB** menjalankan `/compact` untuk meringkas dan menyimpan state percakapan, lalu menjalankan `/exit` untuk menutup CLI dan membebaskan RAM server.
- Heru sebagai orkestrator memanggil sub-agent melalui skrip `scripts/wake-agent.sh <agent> <file-tugas> [proyek]`. Sesi sub-agent akan melanjutkan konteks sebelumnya secara instan (`agy -c`) tanpa membuang memori saat idle.
