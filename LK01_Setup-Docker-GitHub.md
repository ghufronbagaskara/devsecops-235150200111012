# LK01 — Setup Toolchain: Docker & GitHub

> **Minggu 1 · Sub-CPMK-2 · Bobot 1% · Durasi 2×50 menit (2 SKS kelas hands-on; dilanjutkan mandiri) · Individu**

## Tujuan
Menyiapkan lingkungan kerja DevSecOps: memahami dasar Docker, memasangnya, menjalankan container,
menjalankan kode PHP di dalam container, serta menyiapkan repositori GitHub sebagai fondasi seluruh
sesi hands-on.

## Prasyarat
- Laptop dengan virtualisasi aktif (minimal 8 GB RAM).
- Akun GitHub (yang sudah diundang ke organisasi kelas).

## Bagian A — Kenalan dengan Docker (untuk yang belum pernah)

Kalau Anda belum pernah memakai Docker, baca dulu bagian ini. Docker membuat kita bisa menjalankan
aplikasi lengkap dengan semua kebutuhannya tanpa harus memasang apa pun di laptop. Jadi tidak perlu
"pasang PHP", "pasang Node", "pasang database" satu per satu — semuanya dibungkus dalam wadah yang
disebut container.

Istilah yang perlu dipahami:

| Istilah | Analogi sederhana | Penjelasan |
|---|---|---|
| Image | resep + bahan siap pakai | paket berisi aplikasi dan seluruh kebutuhannya, misalnya `php`, `nginx` |
| Container | masakan jadi dari resep | image yang sedang berjalan; bisa dibuat dan dibuang kapan saja |
| Registry | pasar/toko image | tempat mengambil image, defaultnya Docker Hub |
| Port mapping | menyambung pintu | menghubungkan port di container ke port di laptop, misalnya `-p 8080:80` |
| Volume (mount) | rak bersama | menautkan folder laptop ke folder di dalam container, misalnya `-v "$PWD":/app` |

Anatomi perintah yang sering dipakai:
```
docker run [opsi] <image> [perintah]
  --rm            hapus container otomatis setelah selesai
  -d              jalankan di latar belakang (detached)
  -p 8080:80      port 8080 di laptop -> port 80 di container
  -v "$PWD":/app  tautkan folder saat ini ke /app di dalam container
  -w /app         jadikan /app sebagai folder kerja
  --name web      beri nama container "web"
```
Beberapa perintah pengelola container: `docker ps` (melihat yang berjalan), `docker stop <nama>`
(menghentikan), `docker images` (daftar image), `docker logs <nama>` (melihat log).

## Bagian B — Pasang Docker

Pilih sesuai sistem operasi Anda:

- Windows: pasang Docker Desktop. Aktifkan WSL2 saat diminta (Docker Desktop biasanya memandu ini).
  Setelah terpasang, buka Docker Desktop sampai statusnya "running".
- macOS: pasang Docker Desktop (pilih versi Apple Silicon atau Intel sesuai chip), lalu buka
  aplikasinya.
- Linux: pasang Docker Engine mengikuti panduan resmi `https://docs.docker.com/engine/install/`.

Verifikasi lewat terminal:
```bash
docker --version
docker compose version
docker run --rm hello-world
```
Bila muncul pesan "Hello from Docker!", instalasi sudah benar.

Kalau macet: pastikan Docker Desktop sudah terbuka dan berstatus running, dan (di Windows) fitur
virtualisasi aktif di BIOS. Di Linux, bila muncul "permission denied", jalankan
`sudo usermod -aG docker $USER` lalu logout-login lagi.

## Bagian C — Container pertama

Jalankan sebuah web server sederhana untuk melihat konsep port mapping bekerja:
```bash
docker run --rm -d -p 8080:80 --name web nginx
curl -I http://localhost:8080     # harus menampilkan 200 OK
```
Buka `http://localhost:8080` di browser, ambil tangkapan layar, simpan ke
`labs/LK01-setup/bukti-nginx.png`. Setelah itu hentikan:
```bash
docker stop web
```

## Bagian D — Menjalankan kode PHP dengan Docker

Di sini Anda menjalankan kode PHP milik sendiri tanpa memasang PHP di laptop. Semua lewat container.

Siapkan folder kerja:
```bash
mkdir -p labs/LK01-setup/php-demo
cd labs/LK01-setup/php-demo
```

### D1) Menjalankan satu skrip PHP (mode CLI)
Buat `hello.php`:
```php
<?php
echo "Halo dari PHP di dalam Docker\n";
echo "Versi PHP: " . PHP_VERSION . "\n";
echo "Watermark: ds-<NIM>\n";
```
Jalankan dengan image `php` (opsi `-v` menautkan folder ini ke `/app` di container, `-w` menjadikannya
folder kerja):
```bash
docker run --rm -v "$PWD":/app -w /app php:8.3-cli php hello.php
```
Anda akan melihat output PHP di terminal, padahal PHP tidak terpasang di laptop — itu berjalan di dalam
container. Ganti `<NIM>` dengan NIM Anda.

### D2) Menyajikan halaman PHP lewat web server
Buat `index.php` (isi identitas Anda; watermark wajib sesuai kebijakan):
```php
<?php
echo "<h1>DevSecOps — PHP di Docker</h1>";
echo "<p>Nama: <NAMA> (NIM: <NIM>)</p>";
echo "<p>Watermark: ds-<NIM></p>";
echo "<p>PHP " . PHP_VERSION . " — waktu server: " . date('Y-m-d H:i:s') . "</p>";
```
Jalankan dengan image `php:8.3-apache` yang sudah membawa web server Apache:
```bash
docker run --rm -d -p 8081:80 -v "$PWD":/var/www/html --name php-web php:8.3-apache
curl -s http://localhost:8081 | head        # cek isi halaman
```
Buka `http://localhost:8081` di browser, ambil tangkapan layar (harus terlihat nama dan watermark
Anda), simpan ke `labs/LK01-setup/bukti-php.png`. Lihat juga log server bila perlu:
```bash
docker logs php-web
docker stop php-web
```

Catatan: bila muncul pesan port sudah dipakai ("port is already allocated"), ganti angka port kiri,
misalnya `-p 8082:80`, lalu sesuaikan URL-nya.

## Bagian E — Git & repositori kelas

Konfigurasi Git sekali saja:
```bash
git --version
git config --global user.name  "Nama Anda"
git config --global user.email "<nim>@student.ub.ac.id"
```

Repo `devsecops-<nim>` (private) sudah disediakan dosen di organisasi
[Devsecops-Filkom-2026](https://github.com/Devsecops-Filkom-2026). Terima undangan yang masuk ke akun
GitHub Anda (cek email atau buka `https://github.com/Devsecops-Filkom-2026/devsecops-<nim>/invitations`),
lalu clone dan masuk ke foldernya:
```bash
git clone https://github.com/Devsecops-Filkom-2026/devsecops-<nim>.git
cd devsecops-<nim>
```
Karena dosen adalah owner organisasi, tidak perlu menambahkan siapa pun sebagai collaborator. Pindahkan
folder `labs/LK01-setup/` yang tadi Anda buat ke dalam repo ini bila belum berada di dalamnya.

## Bagian F — Rapikan, laporkan, dan kumpulkan

Repo hasil provisioning sudah memuat struktur folder dan `IDENTITY.md`. Isi dulu `project/IDENTITY.md`
(NIM, watermark `ds-<NIM>`, fokus OWASP) sesuai KEBIJAKAN.

Tulis laporan singkat di `labs/LK01-setup/README.md`: versi Docker dan Git, ringkasan langkah,
serta sisipkan kedua bukti (`bukti-nginx.png` dan `bukti-php.png`). Beri footer identitas:
`Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>`.

Commit bertahap lalu push:
```bash
git add .
git commit -m "LK01: setup docker, menjalankan PHP di container, dan bukti"
git push origin main
```

## Luaran
- `project/IDENTITY.md` terisi.
- `labs/LK01-setup/` berisi: `README.md`, `bukti-nginx.png`, `bukti-php.png`, dan folder
  `php-demo/` (`hello.php`, `index.php`).

## Kriteria penilaian
| Aspek | Bobot |
|---|---|
| Docker & Compose berjalan; container jalan | 25% |
| Kode PHP berjalan di container (CLI dan web) dengan bukti ber-watermark | 35% |
| Repo tertata, `IDENTITY.md` terisi, README jelas | 25% |
| Bukti reproducible dan commit rapi | 15% |

## Checklist submit
- [ ] `docker run hello-world` berhasil
- [ ] Container nginx jalan + `bukti-nginx.png`
- [ ] `hello.php` berjalan via `php:8.3-cli`
- [ ] `index.php` tampil di browser via `php:8.3-apache` + `bukti-php.png` (memuat watermark)
- [ ] Repo `devsecops-<nim>` bisa diakses & `IDENTITY.md` terisi
- [ ] `git push` berhasil

## Troubleshooting singkat
- "Cannot connect to the Docker daemon": Docker Desktop belum terbuka/running.
- "port is already allocated": port dipakai proses lain — ganti angka port kiri (`8081` → `8082`).
- Perubahan pada `index.php` tidak muncul: pastikan opsi `-v "$PWD":/var/www/html` benar dan Anda
  mengedit file di folder yang sama; segarkan browser.
- Di Windows PowerShell, `"$PWD"` bisa diganti `${PWD}`; bila bermasalah, jalankan lewat Git Bash/WSL.
