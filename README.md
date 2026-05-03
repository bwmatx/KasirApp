# KasirApp

KasirApp adalah aplikasi kasir (Point of Sale) berbasis **Flutter** dengan penyimpanan data lokal menggunakan **SQLite**. Aplikasi ini mendukung pemindaian barcode, manajemen produk, keranjang belanja, pembayaran, hingga pembuatan struk dalam bentuk PDF yang dapat dibagikan ke pelanggan.

---

## Daftar Isi

- [Gambaran Umum](#gambaran-umum)
- [Fitur Utama](#fitur-utama)
- [Teknologi](#teknologi)
- [Prasyarat](#prasyarat)
- [Instalasi & Menjalankan Aplikasi](#instalasi--menjalankan-aplikasi)
- [Struktur Proyek](#struktur-proyek)
- [Catatan Pengembangan](#catatan-pengembangan)
- [Kontribusi](#kontribusi)
- [Lisensi](#lisensi)

---

## Gambaran Umum

KasirApp ditujukan untuk mendukung kebutuhan kasir pada usaha kecil hingga menengah tanpa ketergantungan pada koneksi internet maupun server backend.  
Seluruh data (produk, pengguna, dan transaksi) disimpan secara lokal di perangkat menggunakan SQLite melalui package `sqflite` [code_file:1].

Aplikasi ini dikembangkan dengan Flutter SDK (Dart `^3.11.0`) dan dapat dijalankan pada Android, iOS, serta platform lain yang didukung Flutter seperti web dan desktop [code_file:1].

---

## Fitur Utama

- Pemindaian barcode menggunakan kamera perangkat (package `mobile_scanner`) [code_file:1].
- Manajemen produk: tambah, ubah, dan hapus produk lengkap dengan barcode, harga, kategori, dan stok [code_file:1].
- Keranjang belanja dengan perhitungan total otomatis [code_file:1].
- Layar pembayaran dengan kalkulasi nominal bayar dan kembalian [code_file:1].
- Autentikasi lokal: registrasi dan login pengguna yang disimpan di SQLite [code_file:1].
- Pembuatan struk transaksi dalam bentuk PDF menggunakan package `pdf` dan `printing` [code_file:1].
- Berbagi struk ke aplikasi lain, termasuk WhatsApp, melalui `share_plus` dan `whatsapp_share2` [code_file:1].
- Visualisasi data penjualan menggunakan grafik (package `fl_chart`) [code_file:1].
- Umpan balik berupa suara dan getaran pada aksi tertentu (misalnya saat scan) dengan `audioplayers` dan `flutter_vibrate` [code_file:1].

---

## Teknologi

### Bahasa & Framework

- **Framework:** Flutter
- **Bahasa:** Dart

### Paket Utama (pubspec.yaml)

- `sqflite` – database lokal SQLite [code_file:1].
- `mobile_scanner` – pemindaian barcode via kamera [code_file:1].
- `intl` – format tanggal dan mata uang [code_file:1].
- `audioplayers` – efek suara [code_file:1].
- `flutter_vibrate` – efek getar [code_file:1].
- `fl_chart` – grafik dan visualisasi data [code_file:1].
- `pdf`, `printing` – pembuatan dan pencetakan PDF [code_file:1].
- `share_plus` – berbagi file dan konten [code_file:1].
- `path`, `path_provider` – manajemen path file lokal [code_file:1].
- `flutter_contacts` – akses kontak (jika digunakan) [code_file:1].
- `permission_handler` – manajemen perizinan aplikasi [code_file:1].
- `whatsapp_share2` – integrasi berbagi ke WhatsApp [code_file:1].

---

## Prasyarat

Sebelum menjalankan proyek ini, pastikan:

- Flutter SDK telah terpasang (disarankan versi 3.x dengan dukungan Dart `^3.11.0`) [code_file:1].
- Android Studio atau VS Code terpasang dengan plugin Flutter & Dart.
- Tersedia perangkat Android atau emulator dengan minimal Android 5.0 (API 21) [code_file:1].
- Git terpasang untuk proses cloning repository.

---

## Instalasi & Menjalankan Aplikasi

### 1. Klon Repository

```bash
git clone https://github.com/bwmatx/KasirApp.git
cd KasirApp
```

### 2. Unduh Dependensi

```bash
flutter pub get
```

### 3. Menjalankan Aplikasi (Debug)

```bash
flutter run
```

Perintah di atas akan menjalankan aplikasi pada emulator atau perangkat fisik yang terhubung [code_file:1].

### 4. Build Release (Opsional)

Untuk membangun file APK release:

```bash
flutter build apk --release
```

Output APK akan berada di direktori `build/app/outputs/apk/release/` [code_file:1].

---

## Struktur Proyek

Struktur direktori utama proyek ini adalah sebagai berikut [code_file:1]:

```text
KasirApp/
├── assets/
│   ├── icon/
│   │   └── logo.png              # Ikon aplikasi
│   └── sounds/
│       └── beep.mp3              # Suara saat pemindaian
├── lib/
│   ├── main.dart                 # Entry point aplikasi
│   ├── models/
│   │   ├── product.dart          # Model data produk
│   │   ├── cart_item.dart        # Model item keranjang
│   │   └── user.dart             # Model data pengguna
│   ├── screens/
│   │   ├── login_screen.dart     # Halaman login
│   │   ├── signup_screen.dart    # Halaman registrasi
│   │   ├── home_screen.dart      # Halaman kasir + pemindaian barcode
│   │   ├── home_menu.dart        # Menu utama / navigasi
│   │   ├── cart_screen.dart      # Halaman keranjang belanja
│   │   ├── payment_screen.dart   # Halaman pembayaran
│   │   ├── product_list_screen.dart  # Daftar produk
│   │   ├── add_product_screen.dart   # Tambah / ubah produk
│   │   └── profile_screen.dart       # Profil pengguna
│   └── services/
│       ├── db_service.dart       # Inisialisasi database & operasi CRUD
│       ├── auth_service.dart     # Logika autentikasi pengguna
│       ├── cart_service.dart     # Manajemen keranjang belanja
│       └── transaction_service.dart  # Pengelolaan transaksi
├── android/                      # Konfigurasi native Android
├── ios/                          # Konfigurasi native iOS
├── web/, linux/, macos/, windows/ # Dukungan platform lain Flutter
├── pubspec.yaml                  # Konfigurasi paket & aset
└── README.md
```

---

## Catatan Pengembangan

- Entry point aplikasi berada pada `lib/main.dart` dan memulai aplikasi dari `LoginScreen` [code_file:1].
- Database utama berada pada file `db_service.dart` dengan nama file SQLite `kasir.db` dan versi database saat ini adalah `4` [code_file:1].
- Saat melakukan perubahan skema tabel, pastikan untuk menyesuaikan logika pada `onUpgrade` di `DBService` dan memperbarui nomor versi database [code_file:1].

---

## Kontribusi

Kontribusi terhadap pengembangan KasirApp sangat terbuka.  
Langkah umum untuk berkontribusi:

1. Lakukan *fork* pada repository ini.
2. Buat branch baru untuk perubahan Anda:
   ```bash
   git checkout -b feature/nama-fitur
   ```
3. Lakukan commit perubahan dengan pesan yang jelas:
   ```bash
   git commit -m "feat: deskripsi singkat fitur"
   ```
4. Push ke repository Anda:
   ```bash
   git push origin feature/nama-fitur
   ```
5. Ajukan *Pull Request* melalui GitHub.

---

## Lisensi

Proyek ini direncanakan untuk dirilis dengan lisensi **MIT** atau lisensi lain sesuai kebutuhan pemilik repository.  
Silakan tambahkan file `LICENSE` dan sesuaikan bagian ini apabila lisensi telah ditentukan.

---
