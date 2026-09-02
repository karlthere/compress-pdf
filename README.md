# 🚀 PDF Squeezer Desktop (Flutter Native Windows & macOS)

Aplikasi Desktop Native modern berdesain **Apple Minimalist & Bento Box** untuk pengompresan file PDF secara otomatis, menggantikan script Python `index.py`.

---

## 💎 Fitur Utama
1. **Asynchronous 100% Full Scan**: Memindai seluruh berkas dan direktori sub-folder tanpa batas kuota/limit file, tanpa membekukan antarmuka UI.
2. **Apple Bento Box Grid Layout**: Tampilan visual berbasis Bento Cards dengan efek **Glassmorphic Gloss** (`BackdropFilter` blur + pearl white surface + rounded corners 22px).
3. **Pilihan Input Fleksibel**:
   - `[ 📄 Pilih File ]`: Membuka File Explorer / Finder untuk memilih 1 atau banyak file `.pdf` spesifik.
   - `[ 📁 Pilih Folder ]`: Membuka File Explorer / Finder untuk memilih seluruh struktur direktori folder.
4. **Skema Warna Modern**: Pure White / Light Pearl Gloss dipadukan dengan aksen **Electric Blue** (`#0066FF`) & **Royal Blue** (`#1E3A8A`).
5. **Algoritma Multi-Stage Compression**:
   - File $\le$ 2MB: Disalin langsung otomatis (*Direct Copy*).
   - File > 2MB: Dikompresi bertahap (Tier 1 Lossless Clean & Tier 2 Raster JPG Optimization).

---

## 🛠️ Panduan Menjalankan Project

### Requirements:
- Flutter SDK `^3.0.0`
- Windows 10/11 atau macOS

### Command Jalankan Aplikasi:
```bash
# 1. Install Dependencies
flutter pub get

# 2. Jalankan di Windows
flutter run -d windows

# 3. Jalankan di macOS
flutter run -d macos
```

### Structure Code:
- [`lib/main.dart`](file:///d:/Coder/Project/compress-pdf/lib/main.dart) - Entry point utama
- [`lib/models/pdf_item.dart`](file:///d:/Coder/Project/compress-pdf/lib/models/pdf_item.dart) - Data model file PDF
- [`lib/models/scan_stats.dart`](file:///d:/Coder/Project/compress-pdf/lib/models/scan_stats.dart) - Data model statistik
- [`lib/services/file_scanner_service.dart`](file:///d:/Coder/Project/compress-pdf/lib/services/file_scanner_service.dart) - Engine pemindai file 100% async
- [`lib/services/pdf_compressor_service.dart`](file:///d:/Coder/Project/compress-pdf/lib/services/pdf_compressor_service.dart) - Engine pengompres PDF
- [`lib/ui/views/home_screen.dart`](file:///d:/Coder/Project/compress-pdf/lib/ui/views/home_screen.dart) - Dashboard Bento Box UI
