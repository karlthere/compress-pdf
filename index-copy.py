import os
import sys
import time
import pymupdf
from concurrent.futures import ProcessPoolExecutor, as_completed

# ==============================================================================
# KONFIGURASI DEFAULT
# ==============================================================================
# Ganti dengan path default yang diinginkan, cara copy path: Shift + klik kanan pada folder/file > Copy as path
TARGET_PATH = r"C:\Users\Public\Documents" 
BATAS_MAKSIMAL_MB = 2.0
BATAS_BYTES = BATAS_MAKSIMAL_MB * 1024 * 1024


def kompresi_biasa(input_path, output_path):
    doc = pymupdf.open(input_path)
    doc.save(
        output_path,
        garbage=4,
        deflate=True,
        clean=True
    )
    doc.close()


def kompresi_paksa_jpg(input_path, output_path, dpi=100, quality=50):
    doc = pymupdf.open(input_path)
    pdf_baru = pymupdf.open()

    for halaman in doc:
        foto = halaman.get_pixmap(dpi=dpi)
        bytes_foto = foto.tobytes("jpeg", jpg_quality=quality)

        halaman_baru = pdf_baru.new_page(
            width=halaman.rect.width, 
            height=halaman.rect.height
        )
        halaman_baru.insert_image(halaman.rect, stream=bytes_foto)
        foto = None

    pdf_baru.save(output_path, deflate=True, garbage=4)
    pdf_baru.close()
    doc.close()


def proses_satu_file(alamat_file):
    ukuran_awal = os.path.getsize(alamat_file)
    if ukuran_awal <= BATAS_BYTES:
        return False, 0, 0, alamat_file

    ukuran_mb = ukuran_awal / (1024 * 1024)
    file_sementara = alamat_file + ".temp"

    try:
        # TAHAP 1: Lossless Clean
        kompresi_biasa(alamat_file, file_sementara)
        ukuran_baru = os.path.getsize(file_sementara)

        if ukuran_baru <= BATAS_BYTES:
            os.replace(file_sementara, alamat_file)
            print(f"[OK - Lossless] {os.path.basename(alamat_file)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
            return True, ukuran_awal, ukuran_baru, alamat_file

        # TAHAP 2: Raster JPG
        pengaturan_gambar = [
            (100, 50),
            (75, 35),
            (50, 20)
        ]

        for dpi, kualitas in pengaturan_gambar:
            kompresi_paksa_jpg(alamat_file, file_sementara, dpi=dpi, quality=kualitas)
            ukuran_baru = os.path.getsize(file_sementara)

            if ukuran_baru <= BATAS_BYTES:
                os.replace(file_sementara, alamat_file)
                print(f"[OK - JPG DPI {dpi}] {os.path.basename(alamat_file)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
                return True, ukuran_awal, ukuran_baru, alamat_file

        if ukuran_baru < ukuran_awal:
            os.replace(file_sementara, alamat_file)
            print(f"[OK - Maksimal] {os.path.basename(alamat_file)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
            return True, ukuran_awal, ukuran_baru, alamat_file
        else:
            if os.path.exists(file_sementara):
                os.remove(file_sementara)
            return False, 0, 0, alamat_file

    except Exception:
        if os.path.exists(file_sementara):
            os.remove(file_sementara)
        return False, 0, 0, alamat_file


def jalankan_program(alamat_target):
    alamat_target = alamat_target.strip('"\'')
    if not os.path.exists(alamat_target):
        print(f"Error: Path '{alamat_target}' tidak ditemukan!")
        return

    semua_pdf = []
    pdf_perlu_kompresi = []

    # Pindai file atau folder
    if os.path.isfile(alamat_target):
        if alamat_target.lower().endswith(".pdf") and not alamat_target.endswith(".temp"):
            semua_pdf.append(alamat_target)
            if os.path.getsize(alamat_target) > BATAS_BYTES:
                pdf_perlu_kompresi.append(alamat_target)
    elif os.path.isdir(alamat_target):
        for akar, _, files in os.walk(alamat_target):
            for f in files:
                if f.lower().endswith(".pdf") and not f.endswith(".temp"):
                    path_lengkap = os.path.join(akar, f)
                    semua_pdf.append(path_lengkap)
                    if os.path.getsize(path_lengkap) > BATAS_BYTES:
                        pdf_perlu_kompresi.append(path_lengkap)

    total_semua_pdf = len(semua_pdf)
    total_target_kompresi = len(pdf_perlu_kompresi)
    total_diabaikan = total_semua_pdf - total_target_kompresi

    if total_semua_pdf == 0:
        print("Tidak ada file PDF yang ditemukan.")
        return

    if total_target_kompresi == 0:
        print(f"Ditemukan {total_semua_pdf} file PDF, tetapi semua ukurannya sudah di bawah 2 MB.")
        return

    print(f"Menemukan {total_semua_pdf} file PDF. Memproses {total_target_kompresi} file (> 2 MB)...\n")
    waktu_mulai = time.time()

    total_pdf_dikompres = 0
    total_bytes_sebelum = 0
    total_bytes_sesudah = 0

    with ProcessPoolExecutor() as executor:
        futures = [executor.submit(proses_satu_file, pdf_path) for pdf_path in pdf_perlu_kompresi]
        for future in as_completed(futures):
            sukses, awal, akhir, path = future.result()
            if sukses:
                total_pdf_dikompres += 1
                total_bytes_sebelum += awal
                total_bytes_sesudah += akhir

    durasi = time.time() - waktu_mulai

    mb_sebelum = total_bytes_sebelum / (1024 * 1024)
    mb_sesudah = total_bytes_sesudah / (1024 * 1024)
    hemat_mb = mb_sebelum - mb_sesudah
    persentase_hemat = (hemat_mb / mb_sebelum * 100) if mb_sebelum > 0 else 0

    print("\n" + "=" * 55)
    print("              RINGKASAN HASIL KOMPRESI              ")
    print("=" * 55)
    print(f" Total Semua PDF Ditemukan  : {total_semua_pdf} file")
    print(f" Total PDF Diabaikan (<2MB)  : {total_diabaikan} file")
    print(f" Total PDF Diproses (>2MB)   : {total_target_kompresi} file")
    print(f" Total PDF Berhasil Kompres : {total_pdf_dikompres} file")
    print("-" * 55)
    print(f" Ukuran Sebelum Kompresi    : {mb_sebelum:.2f} MB")
    print(f" Ukuran Setelah Kompresi    : {mb_sesudah:.2f} MB")
    print(f" Total Ruang Dihemat        : {hemat_mb:.2f} MB ({persentase_hemat:.1f}%)")
    print(f" Waktu Eksekusi             : {durasi:.2f} detik")
    print("=" * 55)
    print(" Catatan: File yang sudah di bawah 2 MB dilewati otomatis")
    print(" agar tidak merusak kualitas dokumen yang sudah aman.")
    print("=" * 55)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        input_user = input("Masukkan Path Folder/File (Enter untuk default): ").strip()
        target = input_user if input_user else TARGET_PATH

    jalankan_program(target)