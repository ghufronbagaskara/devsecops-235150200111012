# LK01 — Setup Toolchain: Docker & GitHub

**Nama:** Ghufron Bagaskara  
**NIM:** 235150200111012  
**Watermark:** ds-235150200111012

---

## Versi Perkakas

| Perkakas | Versi |
|---|---|
| Docker Engine | 28.4.0 (build d8eb465) |
| Docker Compose | v2.39.4-desktop.1 |
| Git | 2.45.2.windows.1 |

---

## Ringkasan Langkah

### Bagian B: Instalasi Docker

Docker Desktop dipasang di Windows dengan WSL2 aktif. Verifikasi lewat terminal:

```
docker --version
docker compose version
docker run --rm hello-world
```

Muncul pesan "Hello from Docker!" sehingga instalasi dikonfirmasi berhasil.

### Bagian C: Container Pertama (nginx)

```bash
docker run --rm -d -p 8080:80 --name web nginx
curl -I http://localhost:8080
docker stop web
```

Port 8080 di laptop dipetakan ke port 80 di dalam container nginx. Browser membuka `http://localhost:8080` dan menampilkan halaman default nginx.

![Bukti nginx berjalan di browser](bukti-nginx.png)

### Bagian D: Kode PHP di Container

Folder kerja disiapkan di `labs/LK01-setup/php-demo/`. Dua file PHP dibuat.

**D1 — Mode CLI (`hello.php`):**

```bash
docker run --rm -v "${PWD}:/app" -w /app php:8.3-cli php hello.php
```

PHP dijalankan tanpa instalasi lokal. Output muncul di terminal, termasuk watermark `ds-235150200111012`.

**D2 — Mode web (`index.php`):**

```bash
docker run --rm -d -p 8081:80 -v "${PWD}:/var/www/html" --name php-web php:8.3-apache
```

Halaman `http://localhost:8081` menampilkan nama, NIM, watermark, dan timestamp server PHP.

![Bukti PHP berjalan via browser](bukti-php.png)

### Bagian E: Konfigurasi Git

```bash
git config --global user.name  "Ghufron Bagaskara"
git config --global user.email "235150200111012@student.ub.ac.id"
```

Repo `devsecops-235150200111012` di organisasi [Devsecops-Filkom-2026](https://github.com/Devsecops-Filkom-2026) sudah di-clone dan `project/IDENTITY.md` diisi sesuai formula NIM.

---

## Refleksi

Dua digit terakhir NIM saya 12, jadi Primary OWASP A03 dan Secondary A02. Formula ini sederhana tapi fungsional: kalau semua orang pakai langkah yang sama dan menghasilkan file identik, perbedaan fokus OWASP itulah yang membuat analisis tiap orang tidak bisa dipertukarkan.

Bagian yang paling perlu perhatian di LK ini adalah volume mount Docker di Windows PowerShell. Sintaks `"$PWD":/app` tidak selalu berjalan lurus; saya perlu menulis `"${PWD}:/app"` agar path terdeteksi benar. Ini bukan bug, tapi perbedaan cara PowerShell mengekspansi variabel dibanding Bash. Setelah paham pola ini, perintah langsung jalan tanpa modifikasi lain.

Konsep yang paling membantu dipahami lewat praktik langsung adalah port mapping. Membaca `-p 8081:80` di dokumentasi terasa abstrak sampai saya buka browser, ketik `localhost:8081`, dan halaman PHP muncul. Container menjalankan Apache di port 80 internal; laptop mengaksesnya lewat 8081. Tidak ada instalasi Apache atau PHP di mesin host sama sekali.

Untuk image `php:8.3-apache`, dokumen root default container ada di `/var/www/html`. Volume mount mengarahkan folder lokal ke sana, sehingga perubahan pada `index.php` langsung terlihat tanpa restart container. Ini yang membuat container berguna untuk development: tidak perlu rebuild image setiap kali file berubah.

Git sudah dikonfigurasi dengan email `235150200111012@student.ub.ac.id` sesuai kebijakan. Commit dilakukan bertahap, bukan satu unggahan besar di akhir.

---

## Checklist Submit

- [x] `docker run hello-world` berhasil
- [x] Container nginx jalan + `bukti-nginx.png`
- [x] `hello.php` berjalan via `php:8.3-cli`
- [x] `index.php` tampil di browser via `php:8.3-apache` + `bukti-php.png` (memuat watermark)
- [x] Repo `devsecops-235150200111012` bisa diakses & `IDENTITY.md` terisi
- [ ] `git push` berhasil

---

*Dikerjakan oleh Ghufron Bagaskara (235150200111012) — WM ds-235150200111012*