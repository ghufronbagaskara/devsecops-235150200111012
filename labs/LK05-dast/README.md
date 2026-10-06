# LK05 — DAST dengan OWASP ZAP

- Nama / NIM  : Ghufron Bagaskara (235150200111012)
- Watermark   : ds-235150200111012
- Minggu      : 5
- OWASP       : Primary A03 · Secondary A02

---

## 1. Cara Menjalankan

Target: Juice Shop yang sama dari LK02, dijalankan via `docker compose up -d`. ZAP jalan di container terpisah (image ringan `zaproxy/zap-bare`), jadi langkah pertama yang wajib dicek adalah apakah container ZAP bisa menjangkau container Juice Shop sama sekali.

```bash
docker compose up -d

# cek ZAP bisa jangkau target (harus 200)
docker run --rm zaproxy/zap-bare \
  bash -c "curl -s -o /dev/null -w '%{http_code}' http://host.docker.internal:3000"
```

Di Windows/macOS (Docker Desktop), `host.docker.internal` memang resolve ke host. Begitu konfirmasi 200, jalankan rencana automation (`labs/LK05-dast/plan.yaml`):

```bash
docker run --rm -v "$PWD/labs/LK05-dast:/zap/wrk:rw" zaproxy/zap-bare \
  zap.sh -cmd -autorun /zap/wrk/plan.yaml
```

Isi `plan.yaml`: spider dengan batas 2 menit ke `http://host.docker.internal:3000`, lalu `passiveScan-wait`, lalu dua job report (HTML dan JSON). `reportTitle` di dalamnya memuat `ds-235150200111012` sebagai watermark.

Hasil run: spider menemukan 101 URL, scan selesai sekitar 20 detik (jauh lebih cepat dari patokan 1-3 menit di soal, karena Juice Shop-nya sudah "panas" dan tidak perlu nunggu cold start). Dua file keluar: `zap-baseline.html` dan `zap-baseline.json`.

---

## 2. Ringkasan Alert

Baseline scan (spider + passive, tanpa active scan) menghasilkan 4 jenis alert, total 19 instance:

| Risk | Instance | CWE | Alert |
|---|---|---|---|
| Medium | 5 | 693 | Content Security Policy (CSP) Header Not Set |
| Medium | 4 | 264 | Cross-Domain Misconfiguration |
| Low | 5 | 497 | Timestamp Disclosure - Unix |
| Info | 5 | - | Modern Web Application |

Angka ini persis cocok dengan patokan di soal LK05 (CSP Not Set: 3 vs 5, Cross-Domain: 1 vs 4, beda dikit karena jumlah instance tergantung berapa banyak URL kena, tapi jenis alertnya identik). Tidak ada satu pun alert High. Itu wajar untuk passive scan: dia cuma mengamati, tidak menyuntik apa pun, jadi dia nangkep masalah konfigurasi dan header, bukan celah injeksi.

---

## 3. Tabel Triage

| ID | Alert | Risk | CWE | OWASP 2021 | Nyata/Noise | Catatan |
|---|---|---|---|---|---|---|
| ZAP-01 | CSP Header Not Set | Medium | 693 | A05 | Nyata | Muncul di root (`/`) dan juga di `/ftp/coupons_2013.md.bak`, file yang sama yang ketemu waktu recon LK02. Tanpa CSP, XSS yang akan dibuktikan di LK06 jauh lebih mudah tereksekusi di browser. |
| ZAP-02 | Cross-Domain Misconfiguration | Medium | 264 | A05 | Nyata | CORS mengizinkan origin manapun baca response (`Access-Control-Allow-Origin: *`, sudah kelihatan juga di `headers.txt` LK02). Risikonya naik kalau endpoint itu balikin data sensitif, bukan cuma asset statis. |
| ZAP-03 | Timestamp Disclosure - Unix | Low | 497 | A01 | Nyata, dampak kecil | Server membocorkan timestamp Unix mentah di beberapa response. Sendirian nggak bahaya, tapi bisa dipakai buat fingerprinting versi/uptime server. |
| ZAP-04 | Modern Web Application | Info | - | - | Noise | Ini bukan kerentanan, cuma catatan ZAP bahwa target pakai arsitektur SPA sehingga spider klasik kurang efektif. Informasional murni, tidak perlu masuk hitungan risiko. |

Dari 4 alert di atas, 3 nyata (masuk hitungan risiko) dan 1 murni informasional.

---

## 4. Alert Kandidat Verifikasi Aktif/Manual

Baseline pasif ini sama sekali tidak menyentuh parameter input (`email`, `password`, `q` di search). Dua entry point yang sudah ditandai berisiko tinggi dari SAST (LK04) dan attack-surface mapping (LK02), `/rest/user/login` dan `/rest/products/search?q=`, tidak muncul sebagai alert di sini, bukan karena aman, tapi karena passive scan memang tidak pernah mengirim payload ke sana. Dua titik ini jadi kandidat utama untuk dibuktikan manual di LK06.

CSP yang hilang (ZAP-01) juga langsung jadi konteks pendukung buat LK06: kalau CSP ada dan dikonfigurasi benar, XSS yang nanti dibuktikan di LK06 seharusnya tertahan sebagian oleh browser. Karena headernya tidak ada, jalan untuk payload XSS jadi lebih terbuka.

---

## 5. Refleksi

Hal yang paling penting dipahami dari LK05: baseline scan ZAP sama sekali tidak menemukan SQL injection atau XSS, padahal semua orang tahu Juice Shop didesain penuh dengan dua kerentanan itu. Awalnya kedengaran aneh, tapi begitu paham cara kerja passive scan, jadi masuk akal. Passive scan hanya mengamati traffic yang lewat pas spider menjelajah halaman demi halaman. Dia tidak pernah mengetik apa pun ke kolom email atau search, jadi dia tidak punya kesempatan memicu query yang rentan. Yang dia tangkap cuma hal yang bisa dilihat tanpa menyentuh satu pun form: header response yang hilang, konfigurasi CORS, timestamp yang kebocor.

Ini mengubah cara saya melihat hasil scan negatif. "Tidak ada alert SQLi" di laporan ZAP baseline bukan berarti aplikasinya aman dari SQLi, melainkan berarti scan jenis ini memang tidak dirancang untuk mendeteksinya. Kalau saya cuma baca angka tanpa paham metodenya, saya bisa salah simpulkan Juice Shop "lolos" padahal justru dua entry point paling rentan (login dan search) tidak pernah diuji sama sekali di scan ini.

Temuan yang paling nyambung ke LK sebelumnya adalah CSP Header Not Set muncul tepat di `/ftp/coupons_2013.md.bak`, file yang sama persis yang saya temukan waktu recon di LK02. Tiga LK berturut-turut (recon, SAST, DAST) sama-sama menyinggung direktori `/ftp` dari sudut berbeda, dan itu memperkuat kalau ini memang titik lemah yang konsisten, bukan kebetulan satu tool saja yang nangkep.

---

## 6. Checklist Submit

- [x] Container ZAP menjangkau target (uji `curl` = 200)
- [x] `plan.yaml` dengan `reportTitle` memuat `ds-235150200111012`
- [x] Baseline scan menghasilkan `zap-baseline.html` + `zap-baseline.json`
- [x] Alert diringkas dan di-triage (nyata vs noise)
- [x] Setiap alert dipetakan ke OWASP 2021
- [x] Alert kandidat verifikasi aktif/manual ditandai (jembatan ke LK06)
- [x] Refleksi ditulis sendiri
- [ ] `git push` (belum, menunggu review manual sebelum commit)

---

*Dikerjakan oleh Ghufron Bagaskara (235150200111012) — WM ds-235150200111012*
