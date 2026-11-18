# FORMAT SERAH-TERIMA

Setiap dokumen antar agent diawali header:

```
---
dari: <heru|rajif|naufal|priyo|denis>
ke: <heru|rajif|naufal|priyo|denis|pengguna>
proyek: <path-folder-proyek>
modul: <nama-modul>
fase: <sesuai playbook>
versi: <1,2,3...>
tanggal: <YYYY-MM-DD HH:MM>
status: <draft|siap-ditinjau|dikonfirmasi|ditolak|lulus>
rujukan-id: <FEAT-..., API-..., SCR-...>
lampiran: <path bukti>
---
```

Isi: 1) Ringkasan (maks. 5 baris) 2) Isi utama (merujuk ID) 3) Bukti 4) Belum dikerjakan / tidak terverifikasi 5) Pertanyaan terbuka (ditujukan ke siapa) 6) Langkah yang diminta dari penerima.

Satu dokumen untuk satu modul dan satu fase. Revisi menaikkan `versi`; versi lama disimpan sebagai `<nama>.v1.md`.

## Inbox & Penanganan Multi-Proyek
Pesan dan tugas antar agent ditulis sebagai file `<proyek>/inbox/<penerima>/NNN-<judul>.md` (NNN berurutan) dengan header di atas.
Header `proyek:` bersifat WAJIB dan menjadi acuan utama folder kerja agent penerima (mengabaikan `ACTIVE_PROJECT` global bila keduanya berbeda). Hal ini memungkinkan beberapa proyek berjalan tanpa bentrok status.

Setelah tugas selesai ditangani:
1. Pindahkan file tugas dari `<proyek>/inbox/<penerima>/NNN-<judul>.md` ke `<proyek>/inbox/<penerima>/_selesai/`.
2. Kirim serah-terima balasan ke inbox penerima berikutnya atau Heru.
3. Jalankan `/compact` dan `/exit` untuk melepaskan alokasi memori RAM server.

Nama folder inbox mengikuti persona: heru, rajif, naufal (BA), priyo, denis.
