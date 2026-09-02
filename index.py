import os
import sys
import time
import shutil
import pymupdf
from concurrent.futures import ProcessPoolExecutor, as_completed

# ==============================================================================
# KONFIGURASI DEFAULT
# ==============================================================================
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


def proses_satu_file(item):
    """
    item berupa tuple: (input_path, output_path)
    """
    input_path, output_path = item
    ukuran_awal = os.path.getsize(input_path)

    # Pastikan sub-folder tujuan sudah dibuat
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Jika ukuran sudah aman, cukup salin file asli ke folder baru
    if ukuran_awal <= BATAS_BYTES:
        shutil.copy2(input_path, output_path)
        return False, 0, 0, input_path

    ukuran_mb = ukuran_awal / (1024 * 1024)
    file_sementara = output_path + ".temp"

    try:
        # TAHAP 1: Lossless Clean
        kompresi_biasa(input_path, file_sementara)
        ukuran_baru = os.path.getsize(file_sementara)

        if ukuran_baru <= BATAS_BYTES:
            os.replace(file_sementara, output_path)
            print(f"[OK - Lossless] {os.path.basename(input_path)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
            return True, ukuran_awal, ukuran_baru, input_path

        # TAHAP 2: Raster JPG
        pengaturan_gambar = [
            (100, 50),
            (75, 35),
            (50, 20)
        ]

        for dpi, kualitas in pengaturan_gambar:
            kompresi_paksa_jpg(input_path, file_sementara, dpi=dpi, quality=kualitas)
            ukuran_baru = os.path.getsize(file_sementara)

            if ukuran_baru <= BATAS_BYTES:
                os.replace(file_sementara, output_path)
                print(f"[OK - JPG DPI {dpi}] {os.path.basename(input_path)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
                return True, ukuran_awal, ukuran_baru, input_path

        if ukuran_baru < ukuran_awal:
            os.replace(file_sementara, output_path)
            print(f"[OK - Maksimal] {os.path.basename(input_path)} ({ukuran_mb:.2f}MB -> {ukuran_baru/(1024*1024):.2f}MB)")
            return True, ukuran_awal, ukuran_baru, input_path
        else:
            # Jika kompresi gagal memperkecil, pakai file asli
            if os.path.exists(file_sementara):
                os.remove(file_sementara)
            shutil.copy2(input_path, output_path)
            return False, 0, 0, input_path

    except Exception:
        if os.path.exists(file_sementara):
            os.remove(file_sementara)
        # Jika error, tetap amankan file asli ke folder tujuan
        shutil.copy2(input_path, output_path)
        return False, 0, 0, input_path


def jalankan_program(alamat_target):
    alamat_target = alamat_target.strip('"\'')
    if not os.path.exists(alamat_target):
        print(f"Error: Path '{alamat_target}' tidak ditemukan!")
        return

    # Tentukan nama folder/file output
    if os.path.isfile(alamat_target):
        folder_parent = os.path.dirname(alamat_target)
        nama_file = os.path.basename(alamat_target)
        folder_output = os.path.join(folder_parent, "Compressed")
        daftar_tugas = [(alamat_target, os.path.join(folder_output, nama_file))]
    else:
        folder_output = os.path.join(alamat_target, "Compressed")
        daftar_tugas = []
        for akar, _, files in os.walk(alamat_target):
            # Abaikan folder output itu sendiri jika di-run berulang kali
            if os.path.commonpath([akar, folder_output]) == folder_output:
                continue

            for f in files:
                if f.lower().endswith(".pdf") and not f.endswith(".temp"):
                    path_asal = os.path.join(akar, f)
                    rel_path = os.path.relpath(path_asal, alamat_target)
                    path_tujuan = os.path.join(folder_output, rel_path)
                    daftar_tugas.append((path_asal, path_tujuan))

    total_semua_pdf = len(daftar_tugas)
    if total_semua_pdf == 0:
        print("Tidak ada file PDF yang ditemukan.")
        return

    pdf_perlu_kompresi = [tugas for tugas in daftar_tugas if os.path.getsize(tugas[0]) > BATAS_BYTES]
    pdf_langsung_salin = [tugas for tugas in daftar_tugas if os.path.getsize(tugas[0]) <= BATAS_BYTES]

    total_target_kompresi = len(pdf_perlu_kompresi)
    total_diabaikan = len(pdf_langsung_salin)

    # Salin dulu file yang sudah < 2MB ke folder baru
    for input_p, output_p in pdf_langsung_salin:
        os.makedirs(os.path.dirname(output_p), exist_ok=True)
        shutil.copy2(input_p, output_p)

    if total_target_kompresi == 0:
        print(f"Ditemukan {total_semua_pdf} file PDF, tetapi semua ukurannya sudah di bawah 2 MB.")
        print(f"Semua file telah disalin ke folder: {folder_output}")
        return

    print(f"Hasil akan disimpan di folder : {folder_output}")
    print(f"Menemukan {total_semua_pdf} file PDF. Memproses {total_target_kompresi} file (> 2 MB)...\n")
    waktu_mulai = time.time()

    total_pdf_dikompres = 0
    total_bytes_sebelum = 0
    total_bytes_sesudah = 0

    with ProcessPoolExecutor() as executor:
        futures = [executor.submit(proses_satu_file, item) for item in pdf_perlu_kompresi]
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
    print("               RINGKASAN HASIL KOMPRESI              ")
    print("=" * 55)
    print(f" Total Semua PDF Ditemukan  : {total_semua_pdf} file")
    print(f" Total PDF Diabaikan (<2MB)  : {total_diabaikan} file (Disalin otomatis)")
    print(f" Total PDF Diproses (>2MB)   : {total_target_kompresi} file")
    print(f" Total PDF Berhasil Kompres : {total_pdf_dikompres} file")
    print("-" * 55)
    print(f" Ukuran Sebelum Kompresi    : {mb_sebelum:.2f} MB")
    print(f" Ukuran Setelah Kompresi    : {mb_sesudah:.2f} MB")
    print(f" Total Ruang Dihemat        : {hemat_mb:.2f} MB ({persentase_hemat:.1f}%)")
    print(f" Waktu Eksekusi             : {durasi:.2f} detik")
    print("=" * 55)
    print(f" Lokasi Hasil: {folder_output}")
    print("=" * 55)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        input_user = input("Masukkan Path Folder/File (Enter untuk default): ").strip()
        target = input_user if input_user else TARGET_PATH

    jalankan_program(target)