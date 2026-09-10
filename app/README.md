# app/ — Fork Aplikasi yang Anda Amankan

Kosong hingga **fase remediasi (Minggu 12+)**.

1. Fork aplikasi target di GitHub (mis. https://github.com/juice-shop/juice-shop).
2. Taruh di sini sebagai subfolder atau submodule:
   ```bash
   git clone https://github.com/<username>/juice-shop.git app
   ```
   atau tambahkan sebagai submodule bila diinginkan.
3. Perbaiki **subset kerentanan prioritas** (lihat CB3) — bukan seluruh aplikasi.
4. Pastikan `app/Dockerfile` ada agar `ci.yml` mem-build & menguji fork Anda.

> Bagian **yang Anda ubah/tulis** inilah yang dinilai & dibandingkan similarity-nya. Kode fork asli
> (belum diubah) dijadikan *base code* oleh dosen sehingga tidak dihitung sebagai plagiarisme.
