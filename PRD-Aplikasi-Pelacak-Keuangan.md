# PRD: Aplikasi Pelacak Keuangan Pribadi (FinTrack)

**Nama Kerja:** FinTrack
**Jenis Dokumen:** Product Requirements Document (PRD) untuk Capstone
**Disusun untuk:** Bos — Informatika, Universitas Adzkia
**Platform:** Mobile App (Flutter)

> **Keputusan revisi:** aplikasi **pribadi saja** (single-user). Penyimpanan **100% lokal di perangkat** (local storage HP) — tanpa server, tanpa cloud, tanpa sinkronisasi. Oleh karena itu **data ikut terhapus saat aplikasi di-uninstall** atau data aplikasi dibersihkan (clear data). Satu-satunya pegangan data adalah file backup JSON yang diekspor manual pengguna.

---

## 1. Latar Belakang & Rumusan Masalah

### 1.1 Latar Belakang
Pengelolaan keuangan pribadi (pengeluaran harian, sisa uang bulanan, pemasukan) sering dilakukan secara manual melalui catatan kertas atau spreadsheet yang terpisah-pisah. Hal ini menyebabkan:
- Sulitnya melacak arus kas masuk dan keluar secara real-time
- Tidak ada laporan keuangan yang terstruktur dan mudah dipahami
- Rawan kehilangan data atau kesalahan pencatatan

### 1.2 Rumusan Masalah
1. Bagaimana merancang aplikasi mobile yang dapat mencatat transaksi keuangan pribadi secara mudah dan cepat?
2. Bagaimana menyajikan laporan keuangan (ringkasan, grafik, kategori) yang informatif bagi pengguna?

### 1.3 Tujuan
- Menghasilkan aplikasi pencatatan keuangan pribadi yang sederhana, cepat digunakan, dan visual
- Menyediakan laporan dan analisis pengeluaran/pemasukan otomatis
- Data tersimpan sepenuhnya lokal di perangkat (tanpa server/cloud)

### 1.4 Batasan Masalah (Scope)
- Fokus pada pencatatan manual transaksi (bukan integrasi otomatis ke rekening bank/e-wallet)
- **Mode pribadi saja** (single-user) — tidak ada mode organisasi/multi-user, tanpa backend/server
- **Penyimpanan 100% lokal di perangkat.** Tidak ada cloud/sync. **Uninstall aplikasi / clear data = semua data terhapus** (ini disengaja)
- Tidak mencakup: pajak/akuntansi formal, investasi, anggaran (budget), multi-anggota, dan ekspor laporan PDF/Excel

---

## 2. Target Pengguna & Persona

| Persona | Kebutuhan Utama |
|---|---|
| **Mahasiswa/individu** | Mencatat pengeluaran harian, tahu sisa uang bulanan, kategori pengeluaran (makan, transport, dll) |
| **Pelaku UMKM kecil** | Mencatat pemasukan penjualan dan pengeluaran operasional, tahu untung/rugi sederhana |

---

## 3. User Stories
1. Sebagai pengguna, saya ingin **mendaftar/login** agar data keuangan saya tersimpan terpisah antar pengguna di perangkat.
2. Sebagai pengguna, saya ingin **menambah transaksi** (pemasukan/pengeluaran) dengan cepat (nominal, kategori, tanggal, catatan).
3. Sebagai pengguna, saya ingin **melihat ringkasan saldo** (total masuk, keluar, saldo akhir) di halaman utama.
4. Sebagai pengguna, saya ingin **melihat riwayat transaksi** yang bisa difilter berdasarkan tanggal/kategori.
5. Sebagai pengguna, saya ingin **melihat grafik pengeluaran per kategori** agar tahu ke mana uang saya habis.
6. Sebagai pengguna, saya ingin **mengekspor/meng-import backup JSON** sebagai pegangan jika data di perangkat hilang (misal ganti HP atau uninstall).
7. Sebagai pengguna, saya ingin **mengekspor laporan keuangan ke PDF/CSV** untuk arsip atau berbagi.

---

## 4. Fitur

### 4.1 Ruang Lingkup (Wajib, mode pribadi, local-only)
- [x] Autentikasi (register, login, logout) — email/password, akun tersimpan lokal di perangkat
- [x] CRUD transaksi (tambah, edit, hapus, lihat detail)
- [x] Kategori transaksi (seed default 9 + custom: makan, transport, gaji, dll)
- [x] Dashboard ringkasan (saldo, total masuk, total keluar — periode bulan berjalan)
- [x] Riwayat transaksi dengan filter (tanggal, kategori, jenis) + pencarian
- [x] Grafik: pie per kategori + bar per bulan — **periode default 6 bulan terakhir**
- [x] Dompet pribadi (1 pengguna bisa punya beberapa dompet; tanpa multi-anggota)
- [x] **Backup & restore JSON** (ekspor/import manual) — opsional tapi disarankan, karena data *hanya* ada di perangkat dan hilang saat uninstall
- [x] **Ekspor laporan CSV & PDF** (ringkasan saldo/masuk/keluar + transaksi) — bisa difilter periode (semua / bulan ini / 6 bulan terakhir / rentang tanggal khusus); di PDF pemasukan bertanda `+` hijau, pengeluaran bertanda `-` merah

### 4.2 Di Luar Scope (Tidak Dikerjakan — dihapus dari rencana awal)
- Mode organisasi/multi-user, undang anggota via kode, role admin/member
- Backend/server (Laravel API), cloud, sinkronisasi antar perangkat
- Anggaran (budget) per kategori + notifikasi
- Ekspor laporan Excel/xlsx, kuitansi atau bukti otomatis
- Reminder push notification, foto struk, transaksi berulang, dark mode
- Integrasi bank/e-wallet, akuntansi double-entry, investasi/portofolio

---

## 5. Alur Pengguna (User Flow) Utama

```
[Splash] → [Login/Register] → [Pilih/Buat Dompet]
                                     ↓
                            [Dashboard Dompet Aktif]
                            ├─ Ringkasan saldo + grafik
                            ├─ Tombol (+) Tambah Transaksi
                            ├─ Riwayat Transaksi → Filter/Detail
                            └─ Pengaturan (backup/restore, logout)
```

**Alur tambah transaksi:**
1. Tekan tombol (+) di dashboard
2. Pilih jenis (Pemasukan / Pengeluaran)
3. Isi nominal, kategori, tanggal (default: hari ini), catatan opsional
4. Simpan → kembali ke dashboard, saldo & grafik ter-update otomatis

---

## 6. Struktur Layar (Screens) — untuk Vibe Coding

Daftar layar berikut bisa langsung dipakai sebagai prompt per-layar ke AI coding assistant:

1. **Splash Screen** — logo + loading
2. **Onboarding** (opsional, 2-3 slide penjelasan fitur)
3. **Login Screen** — email, password, tombol login, link ke register
4. **Register Screen** — nama, email, password, konfirmasi password
5. **Pilih Dompet Screen** — list dompet milik user, tombol "Buat Dompet Baru"
6. **Buat/Edit Dompet Screen** — nama dompet (selalu tipe pribadi)
7. **Dashboard Screen (Home)** — card saldo, grafik ringkas, list transaksi terbaru (5 terakhir), FAB tombol tambah
8. **Tambah/Edit Transaksi Screen** — form (jenis, nominal, kategori dropdown, tanggal picker, catatan)
9. **Riwayat Transaksi Screen** — list transaksi full + filter bar (tanggal, kategori, jenis) + search
10. **Detail Transaksi Screen** — semua detail 1 transaksi, tombol edit/hapus
11. **Laporan/Statistik Screen** — pie chart per kategori, bar chart per bulan, toggle periode (bulan ini / 6 bulan); default menampilkan **6 bulan terakhir**
12. **Pengaturan Screen** — data akun, logout, **backup/restore JSON** (ekspor ke clipboard aksi lain / import), **ekspor laporan CSV & PDF**

---

## 7. Desain Pokok (Design System) — untuk Vibe Coding

### 7.1 Prinsip Desain
- **Clarity first**: angka saldo dan status keuangan harus langsung terbaca dalam 1 detik
- **Minim friksi**: menambah transaksi harus bisa selesai dalam ≤4 tap
- **Konsisten**: 1 pola kartu (card) dan 1 pola tombol dipakai berulang di semua layar

### 7.2 Palet Warna
| Token | Hex | Kegunaan |
|---|---|---|
| Primary | `#0F766E` (teal gelap) | Tombol utama, header, aksen |
| Success/Income | `#16A34A` (hijau) | Pemasukan, saldo positif |
| Danger/Expense | `#DC2626` (merah) | Pengeluaran |
| Background | `#F8FAFC` | Latar layar |
| Surface/Card | `#FFFFFF` | Kartu, form |
| Text Primary | `#0F172A` | Judul, angka utama |
| Text Secondary | `#64748B` | Label, keterangan |
| Border/Divider | `#E2E8F0` | Garis pemisah |

*(Mode gelap: background `#0F172A`, surface `#1E293B`, text primary `#F8FAFC`)*

### 7.3 Tipografi
- Font: **Inter** atau **Poppins** (tersedia gratis di Google Fonts, cocok untuk angka finansial)
- Heading (saldo utama): 28-32px, bold
- Subheading: 16-18px, semi-bold
- Body: 14px, regular
- Caption/label: 12px, medium

### 7.4 Komponen Reusable
- **Balance Card**: kartu besar di atas dashboard menampilkan saldo total, dengan sub-baris "Masuk" (hijau) dan "Keluar" (merah)
- **Transaction List Item**: ikon kategori (kiri) + nama kategori & catatan (tengah) + nominal berwarna (kanan, hijau/merah) + tanggal kecil
- **Category Chip/Avatar**: setiap kategori punya ikon Material konsisten (setiap kategori menyimpan *nama* ikon; data lama peta emoji-nya dipetakan otomatis)
- **Floating Action Button (FAB)**: tombol (+) mengambang di kanan-bawah dashboard, warna primary
- **Currency Input**: kolom nominal memformat titik ribuan otomatis saat mengetik (misal `1.500.000`), disimpan sebagai integer Rupiah

### 7.5 Ikonografi
Gunakan icon set konsisten seperti **Lucide** atau **Material Icons** — jangan campur beberapa gaya ikon.

---

## 8. Struktur Data (Data Model)

```
User
- id, name, email, password_hash, created_at

Wallet (Dompet, selalu pribadi)
- id, name, owner_id, created_at

Category
- id, wallet_id (nullable jika default/global), name, icon (nama ikon Material), type (income/expense)

Transaction
- id, wallet_id, category_id, amount, type (income/expense), note, date, created_at
```

**Relasi kunci:**
- 1 User → banyak Wallet
- 1 Wallet → banyak Transaction, banyak Category (custom)
- 1 Transaction → 1 Category, 1 Wallet

**Konstrain & aturan (unique/validasi):**
- `User.email` UNIQUE
- `Transaction.type` HARUS sama dengan `Category.type` (income/expense) — 1 kategori hanya untuk 1 jenis; kategori income tidak boleh dipakai transaksi expense dan sebaliknya
- Kategori default (seed) — expense: makan, transport, tagihan, kesehatan, pendidikan, hiburan; income: gaji, jualan, iuran. Default bisa disembunyikan user, tidak dihapus permanen
- Nominal disimpan sebagai **integer Rupiah** (bukan float) untuk menghindari error pembulatan

---

## 9. Rekomendasi Tech Stack (untuk Vibe Coding)

| Layer | Rekomendasi | Alasan |
|---|---|---|
| Frontend Mobile | **Flutter** | 1 codebase Android+iOS, sudah dikuasai |
| State Management | **ChangeNotifier (tanpa package)** | Cukup untuk aplikasi single-user skala kecil (implementasi `AppState`) |
| Database Lokal | **sembast** (NoSQL JSON, bukan sqflite) | Berjalan di web **dan** Android tanpa ganti kode, dan data berbentuk JSON jadi backup/restore gratis. sqflite (SQLite) bisa dipakai jika target Android-native murni |
| Chart Library (Flutter) | **fl_chart** | Populer, mudah untuk pie/bar chart |
| Server/Cloud | **TIDAK ADA** | 100% lokal di perangkat; uninstall = data terhapus |

> **Strategi (local-only, single fase):**
> 1. **MVP = seluruh aplikasi.** Flutter + sembast, mode pribadi, tanpa server. Fokus ke nilai inti: catat transaksi + laporan.
> 2. Data tidak pernah dipindah ke cloud. Jika pengguna pindah perangkat, data dipindah manual lewat **backup/restore JSON** (fitur Pengaturan).
> 3. Skema perubahan di masa depan: sesuaikan model + beri jalur import backup (data lama tetap bisa diimport).

---

## 10. Kebutuhan Non-Fungsional
- **Performa**: dashboard harus load < 2 detik dengan data hingga 1000 transaksi
- **Keamanan**: password di-hash (SHA-256 + salt acak) sebelum disimpan ke database lokal
- **Usability**: alur tambah transaksi maksimal 4 tap dari dashboard
- **Data lokal**: seluruh data tersimpan di storage aplikasi. **Uninstall / clear data menghapus semua data** — pengguna diarahkan membuat backup JSON di Pengaturan agar punya salinan

---

## 11. Metrik Keberhasilan (untuk Laporan Capstone)
- Waktu rata-rata menambah 1 transaksi (target < 15 detik)
- Tingkat kepuasan pengguna uji coba (kuesioner skala Likert, target rata-rata ≥ 4/5)
- Akurasi laporan (total transaksi tercatat = total yang ditampilkan di ringkasan, 100% konsisten)

---

## 12. Catatan untuk Prompting AI (Vibe Coding)

Saat membangun dengan bantuan AI coding assistant, urutan yang disarankan:
1. **Mode pribadi saja, tidak ada layar/anggota organisasi**
2. **Setup project & struktur folder** (Flutter: `lib/screens`, `lib/models`, `lib/services`, `lib/widgets`)
3. **Buat data model + database lokal (sembast)** dulu sebelum UI
4. **Bangun 1 komponen reusable dulu** (Transaction List Item, Balance Card) sebelum menyusun layar penuh
5. **Bangun screen per screen** sesuai urutan di Bagian 6, mulai dari Dashboard → Tambah Transaksi → Riwayat
6. Setiap prompt ke AI, sertakan: **screen tujuan, komponen yang dipakai, dan data model terkait** dari dokumen ini — supaya konsisten
