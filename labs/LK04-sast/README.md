# LK04 — Basic Scan #2: SAST dengan Semgrep

- Nama / NIM  : Ghufron Bagaskara (235150200111012)
- Watermark   : ds-235150200111012
- Minggu      : 4
- OWASP       : Primary A03 · Secondary A02

---

## 1. Ringkasan

Semgrep dijalankan terhadap `ds-235150200111012-target` (folder yang sama dengan LK03, jadi watermark path tetap konsisten) memakai dua ruleset publik: `p/owasp-top-ten` dan `p/javascript`. Total 183 aturan jalan pada 1.027 berkas, menghasilkan **43 temuan**: 13 berlevel ERROR, 28 WARNING, 2 MEDIUM.

Sebaran kategori OWASP yang dilaporkan Semgrep didominasi Injection dan Broken Access Control, tapi labelnya campur beberapa edisi (ada yang ditulis `A01:2017`, ada `A03:2021`, ada bahkan `A03:2025`) untuk kelas kerentanan yang sama. Di tabel triage bawah, semua saya petakan ulang ke OWASP Top 10:2021 supaya konsisten dengan LK03.

Temuan paling serius yang ditemukan bukan yang paling sering muncul, justru satu baris di `routes/userProfile.ts:65` yang memanggil `eval()` langsung terhadap input username. Itu jalur Server-Side Template Injection menuju eksekusi kode, dan akan jadi salah satu target utama saya di LK06.

---

## 2. Cara Menjalankan

```bash
# Folder sumber sama dengan LK03, tidak perlu clone ulang
mkdir -p labs/LK04-sast

# Keluaran JSON (untuk triage)
docker run --rm \
  -v "$PWD/ds-235150200111012-target:/ds-235150200111012-target" \
  -v "$PWD/labs/LK04-sast:/out" \
  semgrep/semgrep semgrep scan \
  --config p/owasp-top-ten --config p/javascript \
  --json -o /out/semgrep.json \
  /ds-235150200111012-target

# Keluaran SARIF (untuk GitHub code scanning / CB2 nanti)
docker run --rm \
  -v "$PWD/ds-235150200111012-target:/ds-235150200111012-target" \
  -v "$PWD/labs/LK04-sast:/out" \
  semgrep/semgrep semgrep scan \
  --config p/owasp-top-ten --config p/javascript \
  --sarif -o /out/semgrep.sarif \
  /ds-235150200111012-target
```

Berbeda dari LK03, Semgrep tidak butuh lock file. Dia baca kode sumbernya langsung, jadi tidak ada langkah `npm install` di sini. Di Git Bash / MSYS, kalau Docker menolak mount volume dengan pesan path aneh, tambahkan `MSYS_NO_PATHCONV=1` di depan perintah `docker run` (masalah ini juga muncul waktu saya jalankan Trivy di LK03).

---

## 3. Tabel Triage

Total 43 temuan mentah, 16 di antaranya ditriage di bawah, mewakili tiap rule yang muncul dan sudah mencakup fokus Primary A03 (3 temuan) serta Secondary A02 (2 temuan). Label OWASP sudah dipetakan ulang ke edisi 2021.

| ID | Aturan | Lokasi | Severity | OWASP (2021) | TP/FP | Alasan |
|---|---|---|---|---|---|---|
| SAST-01 | `code-string-concat` | `routes/userProfile.ts:65` | ERROR | A03 | **TP** | Baris ini literal memanggil `eval(code)` terhadap substring dari `username`, yang datang dari input pengguna. Ini jalur SSTI ke RCE, bukan cuma pola string concat biasa. |
| SAST-02 | `express-sequelize-injection` | `routes/login.ts:34` | ERROR | A03 | **TP** | Query login dirakit dari body request tanpa parameterisasi penuh. Titik ini yang nanti dieksploitasi di LK06. |
| SAST-03 | `express-sequelize-injection` | `routes/search.ts:23` | ERROR | A03 | **TP** | SQL injection pada fitur pencarian produk, pola serupa dengan login.ts. |
| SAST-04 | `express-sequelize-injection` | `data/static/codefixes/unionSqlInjectionChallenge_1.ts:6` | ERROR | A03 | **FP** | Polanya cocok, tapi berkas ini contoh soal/jawaban untuk latihan "fix the code" bawaan Juice Shop, tidak dipanggil endpoint aplikasi manapun. |
| SAST-05 | `express-sequelize-injection` | `data/static/codefixes/dbSchemaChallenge_1.ts:5` | ERROR | A03 | **FP** | Sama seperti SAST-04, berkas latihan bukan kode yang melayani pengguna. |
| SAST-06 | `hardcoded-jwt-secret` | `lib/insecurity.ts:54` | WARNING | A02 | **TP** | Ini pemakaian dari private key yang sama yang saya temukan Gitleaks di LK03 (`lib/insecurity.ts:21`), RSA key hardcoded dipakai langsung untuk sign JWT. |
| SAST-07 | `insecure-load-balancer-tls-version` | `infrastructure/terraform/networking.tf:160` | WARNING | A02 | **TP** | Load balancer di konfigurasi Terraform mengizinkan versi TLS lawas. Ini IaC, bukan runtime aplikasi, tapi tetap konfigurasi nyata yang akan di-deploy kalau file ini dipakai. |
| SAST-08 | `express-check-directory-listing` | `server.ts:268` | WARNING | A05 | **TP** | Inilah sumber kode dari direktori `/ftp` yang saya temukan bisa dijelajahi waktu recon LK02. SAST menunjukkan penyebabnya di kode, recon menunjukkan akibatnya di aplikasi yang berjalan. |
| SAST-09 | `express-res-sendfile` | `routes/keyServer.ts:14` | WARNING | A01 | **TP** | Endpoint ini melayani file dari folder `encryptionkeys/` berdasarkan parameter `file`, cuma dicek tidak boleh mengandung `/`, tidak ada allowlist ekstensi seperti di `fileServer.ts`. Path traversal encoded masih mungkin lolos. |
| SAST-10 | `express-res-sendfile` | `routes/fileServer.ts:32` | WARNING | A01 | **TP, dengan mitigasi parsial** | Ada pengecekan ekstensi file dan penanganan poison null byte, tapi filter `!file.includes('/')` masih bisa dilewati kalau karakter slash-nya di-encode. |
| SAST-11 | `express-open-redirect` | `routes/redirect.ts:18` | WARNING | A01 | **TP, sesuai desain challenge** | Ada fungsi `isRedirectAllowed` yang memfilter URL tujuan, tapi Juice Shop memang sengaja menyediakan celah untuk challenge redirect. Bukan bug tak disengaja, tapi tetap risiko nyata kalau allowlist-nya bisa dilewati. |
| SAST-12 | `run-shell-injection` | `.github/workflows/update-challenges-www.yml:27` | ERROR | A08 | **TP, sasaran CI/CD** | Variabel dari konteks GitHub Actions dipakai langsung di step `run:` tanpa escaping. Relevan untuk rantai pasok software, bukan pada aplikasi web yang jalan di server. |
| SAST-13 | `gha-curl-pipe-shell` | `.github/workflows/ci.yml:359` | ERROR | A08 | **TP, sasaran CI/CD** | Pola `curl ... \| sh` di workflow. Kalau sumber curl-nya diretas, script apapun bisa jalan di runner CI. |
| SAST-14 | `github-actions-mutable-action-tag` | `.github/workflows/ci.yml:188` | WARNING | A08 | **TP, severity rendah** | Action dipanggil pakai tag seperti `@v3`, bukan SHA commit. Tag bisa dipindah pemiliknya kapan saja, jadi ini risiko rantai pasok, tapi levelnya jauh di bawah SAST-01 sampai SAST-03. |
| SAST-15 | `aws-subnet-has-public-ip-address` | `infrastructure/terraform/networking.tf:18` | WARNING | A05 | **TP, konteks IaC** | Subnet AWS di-set `map_public_ip_on_launch = true`. Nyata sebagai kesalahan konfigurasi kalau file Terraform ini benar dipakai deploy, tapi di luar jalur kode aplikasi Juice Shop sendiri. |
| SAST-16 | `npm-missing-minimum-release-age` | `.npmrc:1` | MEDIUM | A08 | **FP** | Aturan ini menyarankan pengaturan `minimum-release-age` npm untuk menunda instalasi paket yang baru dipublikasikan (mitigasi supply-chain terkini). Bukan kerentanan yang sudah dieksploitasi, cuma saran pengerasan konfigurasi yang belum relevan untuk struktur project ini. |

---

## 4. Pembahasan 5 Temuan Prioritas

1. **`eval()` pada username, `routes/userProfile.ts:65` (SAST-01).** Ini prioritas tertinggi karena bukan cuma injection biasa, tapi eksekusi kode langsung di server kalau attacker bisa mengontrol string yang diproses. Perbaikannya jelas: hapus `eval()`, ganti logika templating username dengan cara yang tidak mengeksekusi string sebagai kode.

2. **SQL injection di `routes/login.ts:34` (SAST-02).** Jalur otentikasi adalah target paling berharga buat attacker. Kalau titik ini tembus, dampaknya bisa bypass login tanpa kredensial valid.

3. **SQL injection di `routes/search.ts:23` (SAST-03).** Sama kelasnya dengan SAST-02, tapi dampaknya lebih ke pembocoran data lewat fitur pencarian yang bisa dimanipulasi query-nya.

4. **RSA private key hardcoded, `lib/insecurity.ts:21` & `:54` (LK03 SEC-01, SAST-06).** Saya masukkan ini sebagai prioritas karena dua tool berbeda (Gitleaks di LK03, Semgrep di LK04) sama-sama menunjuk baris yang persis sama. Itu sinyal kuat kalau ini bukan alarm palsu satu tool, tapi masalah nyata yang konsisten dari dua sudut pandang berbeda.

5. **Path traversal lemah di `routes/keyServer.ts:14` (SAST-09).** Endpoint ini melayani isi folder `encryptionkeys/`, folder yang sama tempat RSA key di atas kemungkinan disimpan sebagai file. Kombinasi kunci hardcoded plus endpoint yang lemah validasinya untuk mengakses folder itu adalah rantai risiko yang saling memperkuat, bukan dua temuan yang berdiri sendiri-sendiri.

---

## 5. Perbandingan dengan LK03

SCA di LK03 memeriksa pustaka pihak ketiga: hasilnya 48 kerentanan di dependensi npm dan 1 di paket OS, semuanya soal versi yang sudah dipatch oleh maintainer upstream tapi belum di-upgrade di project ini. SAST di LK04 memeriksa kode yang ditulis sendiri oleh tim Juice Shop, dan hasilnya sama sekali berbeda kelas masalahnya: SQL injection yang dirakit manual, `eval()` terhadap input pengguna, endpoint yang melayani file tanpa validasi path yang memadai.

Yang paling jelas kelihatan luput dari SCA tapi ketangkap SAST: semua soal *cara developer menulis kode*-nya sendiri, karena scanner dependensi memang tidak pernah melihat isi `routes/` atau `server.ts`, dia cuma melihat `package-lock.json`. Sebaliknya, yang luput dari SAST tapi ketangkap SCA: kerentanan yang sudah dikenal publik pada versi pustaka tertentu (nomor CVE), karena SAST cuma mencari pola kode berbahaya secara umum, bukan mencocokkan versi pustaka ke database kerentanan.

Satu titik pertemuan yang menarik justru soal RSA private key di `lib/insecurity.ts`: Gitleaks menemukannya sebagai secret yang ter-commit, Semgrep menemukannya sebagai pemakaian hardcoded credential dalam kode. Dua tool, dua metode deteksi berbeda, satu akar masalah yang sama. Ini menunjukkan kenapa SCA, secret scanning, dan SAST tidak saling menggantikan, ketiganya perlu dipakai bersamaan.

---

## 6. Refleksi

Yang paling menarik dari LK04 adalah menyadari kalau nomor OWASP di metadata Semgrep tidak bisa langsung disalin ke laporan. Temuan `express-sequelize-injection` yang sama persis muncul dengan label `A01:2017`, `A03:2021`, dan bahkan `A03:2025` tergantung aturan mana yang menandainya. Ternyata itu karena tim Semgrep menulis rule pada waktu berbeda dan tidak semuanya diperbarui mengikuti edisi terbaru OWASP. Kalau saya asal salin angkanya, laporan saya bisa memetakan Injection sebagai A01 padahal mata kuliah ini pakai OWASP Top 10:2021 di mana Injection itu A03. Butuh langkah ekstra memetakan ulang manual satu per satu ke edisi 2021 supaya konsisten dengan LK03.

Temuan yang paling bikin saya berhenti sejenak adalah baris `eval(code)` di `userProfile.ts`. Rule Semgrep yang menandainya cuma bernama `code-string-concat`, kedengarannya sepele, tapi begitu saya baca konteks kodenya, ternyata itu jalur eksekusi kode dari input username yang sudah melewati regex match sebelumnya. Nama aturan yang generik ternyata bisa menyembunyikan temuan paling serius di seluruh hasil scan. Pelajaran buat saya supaya tidak menilai keparahan cuma dari nama rule atau level severity yang ditempel otomatis, tapi harus baca isi kode di baliknya.

Triage antara data/static/codefixes dengan routes/ asli juga jadi latihan penting: pola SQL injection yang sama bisa jadi TP kuat atau FP tergantung apakah kodenya benar melayani request pengguna atau cuma jadi contoh soal latihan yang tidak pernah dipanggil endpoint manapun. Kalau saya asal hitung semua match sebagai TP tanpa cek konteks, hasil triage saya akan menghitung risiko yang sebenarnya tidak ada di jalur produksi.

---

## 7. Checklist Submit

- [x] Semgrep menghasilkan SARIF dan JSON, keduanya tersimpan di `labs/LK04-sast/`
- [x] Jumlah temuan masuk akal (43, sesuai kisaran ±40 dari soal)
- [x] Minimal 15 temuan ter-triage TP/FP dengan alasan (16 temuan)
- [x] Minimal 2 temuan pada OWASP Primary (A03) dan 1 pada Secondary (A02)
- [x] 5 temuan prioritas ditetapkan dan dijelaskan
- [x] Perbandingan SAST vs SCA (LK03) ditulis
- [x] Refleksi ditulis sendiri
- [x] Folder `*-target/` tidak ikut ter-commit

---

*Dikerjakan oleh Ghufron Bagaskara (235150200111012) — WM ds-235150200111012*
