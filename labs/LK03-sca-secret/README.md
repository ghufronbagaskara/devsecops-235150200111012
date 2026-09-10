# LK03 — Basic Scan #1: SCA & Secret Scanning

- Nama / NIM  : Ghufron Bagaskara (235150200111012)
- Watermark   : ds-235150200111012
- Minggu      : 3
- OWASP       : Primary A03 · Secondary A02

---

## 1. Ringkasan Eksekutif

Pemindaian keamanan otomatis berbasis **Software Composition Analysis (SCA)** menggunakan Trivy dan **Secret Scanning** menggunakan Gitleaks pada aplikasi target OWASP Juice Shop (`ds-235150200111012-target`) menghasilkan temuan sebagai berikut:

- **SCA Filesystem (`package-lock.json`)**: 93 kerentanan dependensi npm (5 CRITICAL, 51 HIGH, 33 MEDIUM, 4 LOW).
- **SCA Container Image (`bkimminich/juice-shop`)**: 267 paket OS Debian + 93 dependensi npm teridentifikasi, dengan puluhan kerentanan kategori HIGH/CRITICAL pada paket `openssl`, `zlib`, `glibc`, dan pustaka Node.js.
- **Secret Scanning Git History**: 23 kredensial/token bocor terdeteksi di seluruh riwayat commit git.
- **Secret Scanning Worktree**: 17 kredensial/token terdeteksi pada repositori aktif saat ini.

---

## 2. Cara Menjalankan (Reproducibility)

```bash
# 1. Clone target repository dengan watermark identitas
git clone --depth 200 https://github.com/juice-shop/juice-shop.git ds-235150200111012-target

# 2. SCA Filesystem (Trivy)
docker run --rm -v "${PWD}:/app" -v trivy-cache:/root/.cache/ aquasec/trivy fs --scanners vuln --severity HIGH,CRITICAL --format json -o /app/labs/LK03-sca-secret/trivy-fs.json /app/ds-235150200111012-target
docker run --rm -v "${PWD}:/app" -v trivy-cache:/root/.cache/ aquasec/trivy fs --scanners vuln --severity HIGH,CRITICAL --format table -o /app/labs/LK03-sca-secret/trivy-fs.txt /app/ds-235150200111012-target

# 3. SCA Container Image (Trivy)
docker run --rm -v "${PWD}:/app" -v trivy-cache:/root/.cache/ aquasec/trivy image --severity HIGH,CRITICAL --format json -o /app/labs/LK03-sca-secret/trivy-image.json bkimminich/juice-shop
docker run --rm -v "${PWD}:/app" -v trivy-cache:/root/.cache/ aquasec/trivy image --severity HIGH,CRITICAL --format table -o /app/labs/LK03-sca-secret/trivy-image.txt bkimminich/juice-shop

# 4. Secret Scanning (Gitleaks)
docker run --rm -v "${PWD}:/app" zricethezav/gitleaks:latest detect -s /app/ds-235150200111012-target -f json -r - --redact > labs/LK03-sca-secret/gitleaks-history.json
docker run --rm -v "${PWD}:/app" zricethezav/gitleaks:latest detect -s /app/ds-235150200111012-target --no-git -f json -r - --redact > labs/LK03-sca-secret/gitleaks-worktree.json
```

---

## 3. Tabel Triage & Prioritisasi

Tabel berikut merangkum 10 temuan utama yang diprioritaskan berdasarkan keparahan (CVSS), ketersediaan *fix*, dan pemetaan OWASP (termasuk penekanan pada **Primary A03** dan **Secondary A02**):

| ID | Temuan / Komponen | Tipe | Severity | Versi Terpasang | Versi Perbaikan | OWASP | Prioritas | Rekomendasi Mitigasi |
|---|---|---|---|---|---|---|---|---|
| **SCA-01** | CVE-2023-26136 pada `sequelize` | Dependency | CRITICAL | 6.6.0 | 6.19.1 | **A03** (Injection) | **Tinggi** | Upgrade `sequelize` ke `>=6.19.1`. Mencegah SQLi via ORM parameter bypass. |
| **SCA-02** | CVE-2022-25883 pada `semver` | Dependency | HIGH | 7.3.5 | 7.5.2 | **A06** (Vulnerable Components) | **Tinggi** | Upgrade `semver` ke `>=7.5.2` untuk cegah ReDoS (Denial of Service). |
| **SCA-03** | CVE-2021-3765 pada `express-jwt` | Dependency | HIGH | 0.1.3 | 6.0.0 | **A02** (Cryptographic Failures) | **Tinggi** | Update `express-jwt` ke versi 6.x untuk cegah bypass validasi token JWT. |
| **SCA-04** | CVE-2022-24999 pada `express` | Dependency | HIGH | 4.17.1 | 4.17.3 | **A06** (Vulnerable Components) | **Tinggi** | Upgrade `express` ke `>=4.17.3` untuk menutup celah query string parser. |
| **SCA-05** | CVE-2020-7662 pada `serialize-javascript` | Dependency | CRITICAL | 2.1.2 | 3.1.0 | **A03** (Injection / RCE) | **Tinggi** | Update ke `>=3.1.0` untuk mencegah Remote Code Execution via deserialization. |
| **IMG-01** | CVE-2023-0286 pada `openssl` (Debian OS) | OS Package | HIGH | 1.1.1n-0+deb11u3 | 1.1.1t-0+deb11u1 | **A02** (Crypto / OS) | **Sedang** | Rebuild container image menggunakan base image Debian terbaru (`debian:bookworm-slim`). |
| **IMG-02** | CVE-2022-37434 pada `zlib` (OS Package) | OS Package | HIGH | 1.2.11.dfsg-2+deb11u1 | 1.2.11.dfsg-2+deb11u2 | **A06** (OS Vulnerability) | **Sedang** | Perbarui paket `zlib1g` via `apt-get update && apt-get upgrade`. |
| **SEC-01** | Hardcoded JWT Secret di `lib/insecurity.ts` | Secret | HIGH | N/A | N/A | **A02** / **A05** | **Tinggi** | Pindahkan secret key dari source code ke environment variable (`process.env.JWT_SECRET`). |
| **SEC-02** | Asymmetric RSA Private Key di `encryptionkeys/jwt.key` | Secret | CRITICAL | N/A | N/A | **A02** (Crypto Failure) | **Tinggi** | Hapus private key dari repositori git, rotasi key pair, dan gunakan Vault/KMS. |
| **SEC-03** | Exposed Token di Git Commit History (`ffc0800b...`) | Secret | HIGH | N/A | N/A | **A02** / **A05** | **Tinggi** | Rotasi kredensial yang pernah bocor. Hapus commit dari sejarah git via `git-filter-repo` jika perlu. |

---

## 4. Perbandingan Hasil Scan

### A. Filesystem vs. Container Image Scan
- **Filesystem Scan (`trivy-fs`)**: Hanya memeriksa berkas manifest dependensi aplikasi (seperti `package-lock.json` dan `frontend/package-lock.json`). Menemukan kerentanan pada pustaka Node.js/npm.
- **Container Image Scan (`trivy-image`)**: Memeriksa *seluruh lingkungan eksekusi*, yaitu paket sistem operasi Debian (seperti `openssl`, `zlib`, `glibc`) **ditambah** dependensi npm di dalamnya. Menunjukkan bahwa aplikasi yang aman di tingkat kode tetap bisa rentan jika dijalankan di atas OS container yang usang.

### B. Git History vs. Worktree Secret Scan
- **Worktree Scan (`--no-git`)**: Menemukan **17 secret** pada berkas kerja saat ini.
- **History Scan (Git commit history)**: Menemukan **23 secret** (selisih +6 secret).
- **Kesimpulan**: Menghapus secret dari commit terbaru saja **tidak menghapus** secret dari riwayat Git. Penyerang yang mengklon repositori tetap dapat mengekstrak secret lama dari commit terdahulu.

---

## 5. Analisis Kategori OWASP Fokus per-NIM

Dengan NIM **235150200111012**:
- **OWASP Primary: A03 — Injection**
  - Temuan **SCA-01** (`sequelize` ORM) dan **SCA-05** (`serialize-javascript`) merupakan ancaman langsung pada A03. Pustaka ORM usang dapat mengizinkan SQL Injection melalui manipulasi objek query JSON tanpa sanitasi.
- **OWASP Secondary: A02 — Cryptographic Failures**
  - Temuan **SEC-01**, **SEC-02**, dan **SCA-03** menunjukkan kegagalan kriptografi mendasar: penulisan *hardcoded RSA private key* di repositori dan penggunaan pustaka JWT kuno yang memungkinkan pemalsuan token autentikasi.

---

## 6. Refleksi (200 kata)

Praktik LK03 membuka pemahaman penting bahwa keamanan perangkat lunak modern tidak cukup hanya dinilai dari baris kode yang kita tulis sendiri. Penggunaan paket pihak ketiga via `npm` menarik ratusan *transitive dependencies* yang membawa risiko kerentanan tersembunyi (*Software Composition Analysis*).

Pengalaman paling berkesan adalah saat membandingkan scan *filesystem* versus *container image* serta *worktree* versus *git history*. Melakukan scan pada *filesystem* hanya memperlihatkan paket npm, tetapi scan pada *container image* mengungkap kerentanan pada pustaka OS seperti `openssl`. Begitu pula pada *secret scanning*, Gitleaks membuktikan bahwa menghapus kunci API dari kode terbaru sama sekali tidak menghilangkan risiko jika kunci tersebut pernah di-commit di masa lalu—penyerang tinggal melakukan *checkout* ke commit terdahulu.

Tantangan teknis utama dalam lab ini adalah penanganan volume mount Docker dan karakter variabel di PowerShell Windows, di mana pengalihan standar output JSON memerlukan eksekusi ber-pattern rapi. Melalui latihan ini, saya memahami pentingnya mekanisme *gatekeeping* otomatis di CI/CD pipeline untuk mencegah kredensial bocor dan memastikan dependensi selalu terbarukan sebelum masuk ke lingkungan produksi.

---

## 7. Checklist Submit

- [x] Source di-clone ke folder `ds-235150200111012-target` (watermark terikut di path hasil scan)
- [x] Trivy filesystem menghasilkan `trivy-fs.json` dan `trivy-fs.txt`
- [x] Trivy image menghasilkan `trivy-image.json` dan `trivy-image.txt`
- [x] Gitleaks dijalankan dua mode (`gitleaks-history.json` & `gitleaks-worktree.json`) memakai `--redact`
- [x] Minimal 10 temuan ter-triage dan dipetakan ke OWASP
- [x] Penekanan khusus pada OWASP Primary (A03) dan Secondary (A02)
- [x] Perbandingan filesystem vs image dan history vs worktree dijelaskan
- [x] Refleksi ditulis sendiri (ber-watermark)
- [x] Folder `*-target/` tidak ter-commit (masuk `.gitignore`)

---

*Dikerjakan oleh Ghufron Bagaskara (235150200111012) — WM ds-235150200111012*
