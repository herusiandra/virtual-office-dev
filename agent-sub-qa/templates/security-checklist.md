# Checklist Keamanan — <modul>
| # | Pemeriksaan | Hasil | Bukti |
|---|---|---|---|
| 1 | Tidak ada secret (API key, password, token) di kode/repo | | |
| 2 | Semua input divalidasi di server | | |
| 3 | Setiap endpoint memeriksa autentikasi sesuai spec | | |
| 4 | Setiap endpoint memeriksa otorisasi (akses data milik pengguna lain ditolak) | | |
| 5 | Query aman dari injeksi (parameterized) | | |
| 6 | Output di-escape (XSS) | | |
| 7 | Data sensitif tidak tercatat di log | | |
| 8 | Pesan error tidak membocorkan detail internal | | |
| 9 | Session/token punya kedaluwarsa sesuai spec | | |
| 10 | Dependensi tidak memiliki kerentanan yang diketahui | | |
