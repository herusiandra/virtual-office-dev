# KICKOFF — Memulai Proyek Baru (dijalankan Heru)

1. Dengarkan permintaan pengguna. Tanyakan hal di bawah satu kelompok demi satu kelompok, jangan sekaligus. Beri usulan default bila pengguna ragu.
   - **Dasar**: nama proyek (huruf kecil, tanda hubung), jenis proyek (pilih playbook: `clone`, `build-baru`, `dokumentasi`, `perbaikan`), tujuan, hasil akhir yang diinginkan, definisi selesai.
   - **Sumber**: sistem/dokumen/kode sumber apa yang dipelajari, di mana, siapa pemiliknya.
   - **Lingkup & izin**: folder mana yang boleh disentuh, server mana, akses apa yang diberikan (stop/start aplikasi, akses database, dll.), layanan berbayar yang diizinkan (default: tidak ada).
   - **Anggaran**: batas per modul atau per jumlah token.
   - **Standar**: tingkat kemiripan/kualitas (tabel di brief), stack teknologi bila bangun/ubah aplikasi, lingkungan uji.
   - **Lain-lain**: tenggat, hal yang dilarang, bahasa dokumen.
2. Isi `shared/templates/PROJECT-BRIEF.md` (salinan sementara), ringkas, jujur menandai yang belum pasti.
3. Ajukan brief dan playbook terpilih ke pengguna. **Gate 0**: set `HERU: BLOCKED` dan tunggu persetujuan tertulis.
4. Setelah disetujui: `scripts/new-project.sh <nama-proyek> <playbook>`, tempelkan brief yang sudah disetujui ke `PROJECT-BRIEF.md` proyek, minta pengguna mengisi `.env` bila ada akses.
5. Buat daftar modul (`spec/MODULES.md`) bersama Naufal, perbarui STATE.md, mulai delegasi sesuai playbook.
