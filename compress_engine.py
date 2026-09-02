import os
import sys
import json
import shutil
import pymupdf

def compress_pdf_file(input_path, output_path, target_mb):
    target_bytes = int(float(target_mb) * 1024 * 1024)
    original_size = os.path.getsize(input_path)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # 1. Jika ukuran awal sudah <= target MB, cukup salin langsung
    if original_size <= target_bytes:
        shutil.copy2(input_path, output_path)
        actual_size = os.path.getsize(output_path)
        return {
            "success": True,
            "original_bytes": original_size,
            "compressed_bytes": actual_size,
            "tier": "Direct Copy (≤ Limit)",
            "message": f"Aman (≤ {target_mb} MB)"
        }

    temp_path = output_path + ".temp"

    # 2. PUTARAN 1: Kompresi Biasa (Lossless Clean Optimization)
    try:
        doc = pymupdf.open(input_path)
        doc.save(temp_path, garbage=4, deflate=True, clean=True)
        doc.close()

        lossless_size = os.path.getsize(temp_path)
        if lossless_size <= target_bytes:
            if os.path.exists(output_path):
                os.remove(output_path)
            os.replace(temp_path, output_path)
            actual_size = os.path.getsize(output_path)
            return {
                "success": True,
                "original_bytes": original_size,
                "compressed_bytes": actual_size,
                "tier": "Putaran 1: Lossless Clean",
                "message": "Sukses (Lossless Clean)"
            }
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    # 3. PUTARAN 2: Progressive Raster JPG (Looping Terus Hingga Ukuran <= Target MB)
    # Daftar preset bertahap dari kualitas tinggi ke paling hemat
    presets = [
        (120, 60),
        (100, 50),
        (85, 40),
        (70, 30),
        (55, 25),
        (40, 20),
        (30, 15),
        (25, 10),
    ]

    best_size = original_size
    best_temp = None

    for dpi, quality in presets:
        try:
            doc = pymupdf.open(input_path)
            new_doc = pymupdf.open()

            for page in doc:
                pix = page.get_pixmap(dpi=dpi)
                img_bytes = pix.tobytes("jpeg", jpg_quality=quality)
                new_page = new_doc.new_page(width=page.rect.width, height=page.rect.height)
                new_page.insert_image(page.rect, stream=img_bytes)
                pix = None

            new_doc.save(temp_path, deflate=True, garbage=4)
            new_doc.close()
            doc.close()

            current_size = os.path.getsize(temp_path)

            if current_size < best_size:
                best_size = current_size

            # JIKA SUDAH DI BAWAH TARGET MB, STOP LOOP DAN REPLACEMENT
            if current_size <= target_bytes:
                if os.path.exists(output_path):
                    os.remove(output_path)
                os.replace(temp_path, output_path)
                actual_size = os.path.getsize(output_path)
                return {
                    "success": True,
                    "original_bytes": original_size,
                    "compressed_bytes": actual_size,
                    "tier": f"JPG Raster (DPI {dpi} Q{quality})",
                    "message": f"Sukses (JPG DPI {dpi})"
                }
        except Exception as e:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    # 4. Jika setelah seluruh preset dicoba masih belum <= target MB, pakai hasil terbaik terkompresi
    if os.path.exists(temp_path) and os.path.getsize(temp_path) < original_size:
        if os.path.exists(output_path):
            os.remove(output_path)
        os.replace(temp_path, output_path)
    else:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        shutil.copy2(input_path, output_path)

    actual_size = os.path.getsize(output_path)
    return {
        "success": actual_size <= target_bytes,
        "original_bytes": original_size,
        "compressed_bytes": actual_size,
        "tier": "Maksimal Kompresi",
        "message": f"Hasil Maksimal ({actual_size / (1024*1024):.2f} MB)"
    }

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(json.dumps({"error": "Usage: compress_engine.py <input_path> <output_path> <target_mb>"}))
        sys.exit(1)

    in_path = sys.argv[1]
    out_path = sys.argv[2]
    target_mb_val = sys.argv[3]

    res = compress_pdf_file(in_path, out_path, target_mb_val)
    print(json.dumps(res))
