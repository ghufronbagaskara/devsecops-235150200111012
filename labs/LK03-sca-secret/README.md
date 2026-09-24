# LK03 — Basic Scan #1: SCA & Secret Scanning

- Nama / NIM  : Ghufron Bagaskara (235150200111012)
- Watermark   : ds-235150200111012
- Minggu      : 3
- OWASP       : Primary A03 · Secondary A02

---

## 1. Ringkasan Eksekutif

Target scan adalah OWASP Juice Shop yang di-clone ke `ds-235150200111012-target` (depth 50 commit, cukup untuk melihat pola secret di histori). Empat pemindaian dijalankan: Trivy pada filesystem dependensi, Trivy pada image container, dan Gitleaks pada dua mode (histori git dan worktree saja).

Hasilnya:

- **Trivy filesystem** (`package-lock.json`): 48 kerentanan HIGH/CRITICAL (40 HIGH, 8 CRITICAL).
- **Trivy image** (`bkimminich/juice-shop`): 53 kerentanan HIGH/CRITICAL, 52 di antaranya pada paket Node.js yang dibundel di image dan 1 pada paket OS Debian (`libssl3t64`).
- **Gitleaks histori git**: 1.276 secret terdeteksi di seluruh commit yang ter-clone.
- **Gitleaks worktree** (tanpa histori): 69 secret pada kondisi kode saat ini.

Catatan jujur soal proses: percobaan pertama scan filesystem gagal total, hasilnya `Not scanned` karena `package-lock.json` belum dibuat (baru ada `package.json` yang isinya rentang versi, bukan versi pasti). Setelah lock file dibuat lewat `npm install --package-lock-only` di dalam container Node, scan berikutnya baru menangkap 48 temuan di atas. Ini persis skenario yang disebut di bagian troubleshooting LK03, dan saya mengalaminya sendiri sebelum ketemu solusinya.

---

## 2. Cara Menjalankan (Reproducibility)

```bash
# 1. Clone target repository dengan watermark identitas
git clone --depth 200 https://github.com/juice-shop/juice-shop.git ds-235150200111012-target

# 2. Wajib: buat lock file dulu, package.json saja tidak cukup untuk Trivy
docker run --rm -v "$PWD/ds-235150200111012-target:/app" -w /app node:20-alpine \
  npm install --package-lock-only --ignore-scripts --no-audit --no-fund

# 3. SCA Filesystem (Trivy)
docker run --rm \
  -v "$PWD/ds-235150200111012-target:/ds-235150200111012-target" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy fs --scanners vuln --severity HIGH,CRITICAL \
  --format json -o /out/trivy-fs.json /ds-235150200111012-target

# (ulangi dengan --format table -o /out/trivy-fs.txt untuk versi yang enak dibaca)

# 4. SCA Container Image (Trivy)
docker run --rm \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy image --severity HIGH,CRITICAL \
  --format json -o /out/trivy-image.json bkimminich/juice-shop

# 5. Secret Scanning (Gitleaks), dua mode
docker run --rm \
  -v "$PWD/ds-235150200111012-target:/repo" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  zricethezav/gitleaks:latest detect --source=/repo \
  --report-format json --report-path=/out/gitleaks-history.json --redact

docker run --rm \
  -v "$PWD/ds-235150200111012-target:/repo" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  zricethezav/gitleaks:latest detect --source=/repo --no-git \
  --report-format json --report-path=/out/gitleaks-worktree.json --redact
```

Di Windows, perintah di atas dijalankan lewat Git Bash. Kalau memakai PowerShell murni, ganti `$PWD` dengan `${PWD}` seperti disebut di bagian troubleshooting LK03.

---

## 3. Tabel Triage & Prioritisasi

10 temuan berikut dipilih dari total kerentanan dan secret di atas, mewakili tiga sumber (dependensi, image, secret) dan mencakup fokus Primary A03 serta Secondary A02.

| ID | Temuan / Komponen | Tipe | Severity | Versi Terpasang | Versi Perbaikan | OWASP | Prioritas | Rekomendasi Mitigasi |
|---|---|---|---|---|---|---|---|---|
| SCA-01 | `marsdb` (GHSA-5mrr-rgp6-x4gr), command injection | Dependency | CRITICAL | 0.6.11 | belum ada fix resmi | **A03** | Tinggi | Ganti `marsdb` dengan alternatif yang masih dirawat, atau hapus kalau tidak dipakai jalur produksi. |
| SCA-02 | `lodash` (CVE-2021-23337), command injection lewat template | Dependency | HIGH | 2.4.2 | 4.17.21 | **A03** | Tinggi | Upgrade `lodash` ke `>=4.17.21`. Versi 2.x memang sangat lawas untuk aplikasi 2026. |
| SCA-03 | `crypto-js` (CVE-2023-46233), PBKDF2 lemah dan mudah dibrute-force | Dependency | CRITICAL | 3.3.0 | 4.2.0 | **A02** | Tinggi | Upgrade `crypto-js` ke `>=4.2.0` agar derivasi kunci memakai iterasi yang sesuai standar. |
| SCA-04 | `jsonwebtoken` (CVE-2015-9235), bypass verifikasi token dengan token yang dimodifikasi | Dependency | CRITICAL | 0.1.0 / 0.4.0 | 4.2.2 | **A02** | Tinggi | Upgrade `jsonwebtoken`, jangan pakai versi di bawah 4.2.2 sama sekali. |
| SCA-05 | `tar` (CVE-2026-59873), DoS lewat gzip bomb | Dependency | CRITICAL | 6.2.1 | 7.5.19 | A06 | Sedang | Upgrade `tar`. Dependensi ini sering dipakai transitif, cek dulu siapa yang menariknya. |
| SCA-06 | `decompress` (CVE-2026-53486), baca/tulis file sembarangan saat ekstraksi arsip | Dependency | CRITICAL | 4.2.1 | belum ada fix | A01 | Tinggi | Belum ada patch resmi. Mitigasi sementara: jangan proses arsip dari sumber tak tepercaya, atau ganti paket. |
| IMG-01 | `libssl3t64` (CVE-2026-14456) pada base image Debian | OS Package | HIGH | 3.5.6-1~deb13u2 | 3.5.7-1~deb13u2 | A06 | Sedang | Rebuild image dari base yang sudah dipatch, atau tunggu image resmi Juice Shop update base-nya. |
| SEC-01 | Hardcoded RSA private key untuk signing JWT, `lib/insecurity.ts:21` | Secret | CRITICAL | tidak berlaku | tidak berlaku | **A02** | Tinggi | Pindahkan private key ke secret manager / env var, rotasi key setelah dipindah, jangan generate ulang di tempat yang sama. |
| SEC-02 | 1.276 secret di histori commit vs 69 di worktree saat ini | Secret | HIGH | tidak berlaku | tidak berlaku | **A02** | Tinggi | Selisih sekitar 1.200 secret membuktikan penghapusan di commit terbaru tidak cukup. Perlu rotasi kredensial yang pernah bocor, bukan sekadar bersihkan kode saat ini. |
| EXP-01 | `express-jwt` (CVE-2020-15084), bypass otorisasi | Dependency | HIGH | 0.1.3 | 6.0.0 | A07 | Sedang | Upgrade `express-jwt` ke versi 6.x, cek ulang middleware yang memakainya. |

Catatan penomoran CVE: sebagian ID di atas (mis. `CVE-2026-xxxx`) memang berpenanggalan 2026. Basis data Trivy per tanggal scan ini, 22 September 2026, sudah memuat kerentanan yang baru diberi nomor tahun ini, bukan salah ketik.

---

## 4. Perbandingan Hasil Scan

### A. Filesystem vs. Container Image Scan

Filesystem scan cuma melihat `package-lock.json`: 48 temuan, semua dari paket npm. Image scan melihat lebih luas, 695 paket Node.js yang benar-benar dibundel ke dalam image plus 13 paket OS Debian, dan menghasilkan 53 temuan: 52 dari sisi Node.js (angka yang mirip dengan filesystem scan, wajar karena sumbernya sama-sama `package.json`), ditambah 1 dari OS (`libssl3t64`). Jadi walau angkanya berdekatan, image scan tetap penting karena menangkap lapisan yang sama sekali tidak terlihat dari sisi kode: sistem operasi tempat aplikasi berjalan.

### B. Git History vs. Worktree Secret Scan

Worktree scan (`--no-git`) menemukan 69 secret pada kondisi kode sekarang. Scan histori menemukan 1.276, dua puluh kali lipat lebih banyak. Selisih sebesar itu bukan berarti ada ribuan credential aktif tersebar; sebagian besar adalah token dummy/test yang diulang di banyak commit karena file test seperti `erasureRequestApiSpec.ts` dan `verifySpec.ts` sering di-edit ulang sepanjang histori proyek. Tapi polanya tetap jadi bukti konkret: kalau di antara ratusan token test itu ada satu yang nyata dan pernah ter-commit, menghapusnya di commit terbaru sama sekali tidak menghilangkannya dari repo. Siapa pun yang clone repo masih bisa `git log -p` ke commit lama dan menemukannya.

---

## 5. Analisis Kategori OWASP Fokus per-NIM

NIM 235150200111012 dapat fokus **Primary A03 (Injection)** dan **Secondary A02 (Cryptographic Failures)**.

Untuk A03, dua temuan paling jelas adalah `marsdb` dan `lodash`, keduanya berlabel command injection oleh basis data kerentanan Trivy. `lodash` versi 2.4.2 khususnya menarik karena versi itu sudah dipakai sejak lama di ekosistem npm, dan lubang command-injection-nya ada di fungsi template yang gampang dipanggil dengan input dari luar kalau developer tidak hati-hati memvalidasi apa yang masuk.

Untuk A02, tiga temuan saling menguatkan: `crypto-js` dengan derivasi kunci yang lemah, `jsonwebtoken` versi lawas yang verifikasi tanda tangannya bisa dilewati, dan yang paling gamblang, RSA private key yang ditulis langsung sebagai string di `lib/insecurity.ts`. Ketiganya sama-sama soal kegagalan menjaga rahasia kriptografis, entah karena algoritmanya lemah, implementasinya cacat, atau kuncinya memang taruh sembarangan di kode.

---

## 6. Refleksi

Bagian paling berharga dari LK03 justru bukan pas scan-nya jalan mulus, tapi pas scan pertama gagal. Trivy filesystem sempat mengembalikan hasil kosong sama sekali, tabelnya cuma berisi tanda `-`. Awalnya saya kira ada yang salah dengan cara mount volume Docker, sampai akhirnya sadar penyebabnya jauh lebih sederhana: `package.json` Juice Shop cuma menyimpan rentang versi macam `^1.2.3`, dan Trivy tidak bisa mencocokkan rentang ke basis data CVE. Begitu `package-lock.json` dibuat lewat container Node terpisah, scan langsung menangkap 48 temuan. Kesalahan kecil seperti ini justru mengajarkan lebih banyak dibanding kalau semua langsung berhasil di percobaan pertama.

Perbandingan git history vs worktree pada Gitleaks juga jadi titik yang paling nempel. Angkanya jomplang jauh, 1.276 berbanding 69, dan begitu saya cek satu-satu file mana yang paling banyak menyumbang temuan, ternyata memang file test yang berulang kali diedit sepanjang commit, bukan berarti ribuan kredensial aktif bocor. Tapi itu justru bikin saya paham kenapa dosen menekankan pentingnya rotasi, bukan sekadar hapus baris kode: yang tersimpan di histori git tetap bisa diambil siapa pun yang punya akses clone, terlepas dari berapa persen di antaranya "cuma" data dummy.

Kendala teknis lain ada di sisi Windows: variabel `$PWD` di Git Bash kadang diterjemahkan jadi path Windows yang bikin Docker menolak mount, harus ditambah `MSYS_NO_PATHCONV=1` supaya path-nya tetap dalam format Linux yang diharapkan container. Detail kecil begini yang tidak kelihatan di dokumentasi tapi baru ketemu pas benar-benar dicoba sendiri.

---

## 7. Checklist Submit

- [x] Source di-clone ke folder `ds-235150200111012-target` (watermark terikut di path hasil scan)
- [x] `package-lock.json` berhasil dibuat sebelum scan filesystem (bukan Not scanned)
- [x] Trivy filesystem menghasilkan `trivy-fs.json` dan `trivy-fs.txt`, targetnya benar-benar terpindai
- [x] Trivy image menghasilkan `trivy-image.json` dan `trivy-image.txt`
- [x] Gitleaks dijalankan dua mode (`gitleaks-history.json` & `gitleaks-worktree.json`) memakai `--redact`
- [x] Minimal 10 temuan ter-triage dan dipetakan ke OWASP
- [x] Minimal 2 temuan pada OWASP Primary (A03) dan 1 pada Secondary (A02)
- [x] Perbandingan filesystem vs image dan history vs worktree dijelaskan
- [x] Refleksi ditulis sendiri
- [x] Folder `*-target/` tidak ter-commit (masuk `.gitignore`)

---

*Dikerjakan oleh Ghufron Bagaskara (235150200111012) — WM ds-235150200111012*
