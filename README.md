# Day 1: Membuat Tools Buat Momi Rere PDF Auto Compressor Speedrun

Script Python otomatis untuk mengkompres file PDF massal. Program ini dirancang khusus untuk memangkas ukuran dokumen yang melebihi batas pengunggahan (misal: batas maksimum 2 MB) secara efisien tanpa mengurangi kualitas secara drastis.

\---

##  🛠️ Persyaratan Sistem & Instalasi

Pastikan perangkat kamu telah terpasang perangkat lunak berikut sebelum menjalankan script:

**1\. Python 3.x**    
    Download: \[python.org/downloads\](https://www.python.org/downloads/)    
    Catatan: Pastikan mencentang opsi "Add python.exe to PATH" pada tahap awal instalasi.

**2\. Visual Studio Code (VS Code) (Direkomendasikan)**    
    Download: \[code.visualstudio.com\](https://code.visualstudio.com/)    
    Pasang ekstensi Python melalui tab Extensions (\`Ctrl \+ Shift \+ X\`).

**3\. Library PyMuPDF**    
   Buka Terminal di VS Code (\`Ctrl \+ \~\`) atau Command Prompt, lalu jalankan perintah:  
   \`\`\`bash  
   **pip install pymupdf**

## ✨ Fitur Utama

* Filter Ukuran Otomatis: Hanya memproses file PDF yang berukuran di atas 2 MB. File yang sudah berukuran kecil diabaikan untuk menjaga kualitas dokumen tetap optimal.  
* Pemrosesan Paralel (Multi-Core): Menggunakan ProcessPoolExecutor untuk memproses banyak file secara bersamaan sehingga menghemat waktu.


Kompresi 2 Tahap:

1. Lossless Clean: Membersihkan struktur dan objek PDF yang tidak terpakai tanpa merubah visual.  
   2. Raster JPG (Fallback): Jika Tahap 1 masih melebihi 2 MB, dokumen akan di-render ulang dengan tingkat DPI dan kualitas gambar yang disesuaikan secara bertahap.  
   3. Laporan Hasil: Menampilkan ringkasan jumlah file yang diproses, total ukuran sebelum-sesudah, serta efisiensi ruang yang dihemat.

## 🚀 Cara Penggunaan

### 1\. Mode Interaktif

Jalankan script tanpa argumen:

Bash atau terminal  
**python index.py**

Masukkan path folder atau file PDF saat diminta. Jika langsung menekan Enter, program akan menggunakan TARGET\_PATH default.

### 2\. Mode Argumen CLI

Jalankan script langsung dengan menyertakan path folder/file:

Bash atau terminal  
**python index.py "C:\\Path\\Ke\\Folder\\PDF"**

## ⚙️ Konfigurasi Default

Lokasi folder default dan batas ukuran file dapat disesuaikan langsung pada variabel di dalam berkas index.py:

Python  
**TARGET\_PATH \= r"C:\\Users\\Public\\Documents"**   
**BATAS\_MAKSIMAL\_MB \= 2.0**

Pojok Tanda Tangan  
Dibuat dengan kasih sayang oleh:  
✨ karlin cantiq,, istrinya winter ✨
