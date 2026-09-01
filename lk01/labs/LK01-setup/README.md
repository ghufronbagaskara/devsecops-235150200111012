LK01 - Setup Toolchain: Docker & GitHub

Nama: Ghufron Bagaskara
NIM: 235150200111012
Watermark: ds-235150200111012


Versi perkakas yang dipakai:
Docker Engine 28.4.0 (build d8eb465)
Docker Compose v2.39.4-desktop.1
Git 2.45.2.windows.1


---

Langkah B - Instalasi Docker

Docker Desktop dipasang di Windows dengan WSL2 aktif. Verifikasi lewat terminal dengan tiga perintah: docker --version, docker compose version, dan docker run --rm hello-world. Ketiganya berhasil dijalankan, dan pesan "Hello from Docker!" muncul di terminal.


Langkah C - Container pertama (nginx)

Perintah yang dijalankan:
docker run --rm -d -p 8080:80 --name web nginx
curl -I http://localhost:8080
docker stop web

Port 8080 di laptop dipetakan ke port 80 di dalam container nginx. Browser dibuka ke http://localhost:8080 dan halaman default nginx muncul. Screenshot disimpan di bukti-nginx.png.


Langkah D - Kode PHP di container

Folder kerja disiapkan di labs/LK01-setup/php-demo/.

D1 - Mode CLI (hello.php):
Perintah: docker run --rm -v "${PWD}:/app" -w /app php:8.3-cli php hello.php
Output muncul di terminal, termasuk watermark ds-235150200111012. PHP dijalankan sepenuhnya di dalam container, tidak ada PHP yang terpasang di laptop.

D2 - Mode web (index.php):
Perintah: docker run --rm -d -p 8081:80 -v "${PWD}:/var/www/html" --name php-web php:8.3-apache
Halaman http://localhost:8081 menampilkan nama, NIM, watermark, dan timestamp server PHP. Screenshot disimpan di bukti-php.png.


Langkah E - Konfigurasi Git

git config --global user.name "Ghufron Bagaskara"
git config --global user.email "235150200111012@student.ub.ac.id"

Repo devsecops-235150200111012 di organisasi Devsecops-Filkom-2026 sudah di-clone dan project/IDENTITY.md sudah diisi sesuai formula NIM.


---

Refleksi

Dua digit terakhir NIM saya 12, jadi Primary OWASP A03 dan Secondary A02. Pembagian fokus ini masuk akal karena kalau semua orang pakai langkah yang sama dan menghasilkan file identik, perbedaan fokus OWASP itulah yang bikin analisis tiap orang tidak bisa dipertukarkan.

Bagian yang paling perlu perhatian di LK ini adalah volume mount Docker di Windows PowerShell. Sintaks "$PWD":/app tidak selalu berjalan lurus; saya perlu menulis "${PWD}:/app" agar path terdeteksi benar. Ini bukan bug, tapi perbedaan cara PowerShell mengekspansi variabel dibanding Bash di Linux. Setelah paham pola ini, perintah langsung jalan.

Konsep yang paling membantu dipahami lewat praktik langsung adalah port mapping. Membaca -p 8081:80 di dokumentasi terasa abstrak sampai saya buka browser, ketik localhost:8081, dan halaman PHP muncul. Container menjalankan Apache di port 80 internal; laptop mengaksesnya lewat 8081. Tidak ada instalasi Apache atau PHP di mesin host sama sekali.

Untuk image php:8.3-apache, dokumen root default container ada di /var/www/html. Volume mount mengarahkan folder lokal ke sana, sehingga perubahan pada index.php langsung terlihat tanpa restart container. Ini yang membuat setup seperti ini nyaman untuk development: tidak perlu rebuild image setiap kali file berubah.

Watermark ds-235150200111012 sudah disertakan di hello.php, index.php, dan terlihat di halaman browser saat screenshot diambil.


---

Checklist submit:
- docker run hello-world berhasil
- Container nginx jalan + bukti-nginx.png tersedia
- hello.php berjalan via php:8.3-cli
- index.php tampil di browser via php:8.3-apache + bukti-php.png (memuat watermark)
- Repo devsecops-235150200111012 bisa diakses & IDENTITY.md terisi
- git push berhasil


Dikerjakan oleh Ghufron Bagaskara (235150200111012) - WM ds-235150200111012
