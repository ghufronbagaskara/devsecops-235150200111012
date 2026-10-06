# LK05 — DAST dengan OWASP ZAP

> **Minggu 5 · Sub-CPMK-5 · Bobot 2% · Durasi 2×50 menit (2 SKS kelas hands-on; dilanjutkan mandiri) · Individu**

## Tujuan
Melakukan **Dynamic Application Security Testing (DAST)** terhadap aplikasi rentan yang sedang
**berjalan**, menggunakan **OWASP ZAP**, lalu membaca dan men-triage alert yang dihasilkan serta
memetakannya ke **OWASP Top 10**.

## Prasyarat
- LK02 selesai: Juice Shop bisa dijalankan via `docker compose up -d`.
- Image ZAP sudah ada: `docker pull zaproxy/zap-bare` (varian ringan, ±680 MB).
- `project/IDENTITY.md` terisi (NIM, watermark, fokus OWASP).

---

## Bagian A — Konsep dulu (untuk yang belum pernah)

### A.1 Apa bedanya dengan LK03/LK04
LK03 (SCA) dan LK04 (SAST) membaca **berkas** — dependensi dan kode sumber — tanpa menjalankan
aplikasi. DAST kebalikannya: ia **menyerang aplikasi yang hidup** dari luar, persis seperti yang
dilakukan penyerang, tanpa melihat kode sama sekali (**black-box**).

| | SAST (LK04) | DAST (LK05) |
|---|---|---|
| Sudut pandang | white-box (lihat kode) | black-box (dari luar) |
| Aplikasi | tidak perlu jalan | **harus berjalan** |
| Menemukan | pola kode berbahaya | perilaku aktual: header, config, respons |
| Kelebihan | tahu lokasi baris kode | tahu yang benar-benar terekspos ke jaringan |
| Kekurangan | tak tahu konteks runtime | tak tahu lokasi kode; butuh cakupan crawl |

Keduanya saling melengkapi — itulah kenapa dipakai berdua.

### A.2 Cara kerja ZAP
ZAP bekerja dalam beberapa tahap:

```
Spider   -> menjelajah aplikasi, menemukan URL & form (membangun peta)
Passive  -> mengamati tiap request/response yang lewat (header, cookie, info bocor)
Active   -> MENYERANG: menyuntik payload (XSS, SQLi, dll.) lalu menilai respons
Report   -> merangkum semua alert ke HTML/JSON
```

Perbedaan penting yang harus dipahami:

- **Passive scan** hanya *mengamati*. Aman, cepat, tidak mengubah data. Menemukan masalah
  **header dan konfigurasi**. Inilah yang kita sebut **baseline**.
- **Active scan** benar-benar *menyerang* dengan payload. Lebih lambat, bisa mengubah/merusak data,
  dan hanya boleh dijalankan pada lab milik sendiri. Ini yang menemukan injeksi/XSS.

Di LK05 fokus utamanya **baseline (passive)**. Active scan disediakan sebagai langkah opsional
(Bagian F) dan diperdalam di LK06 (eksploitasi manual) serta LK08 (DAST di pipeline).

### A.3 Kenapa lewat Automation Framework, bukan `zap-baseline.py`
Banyak tutorial memakai skrip `zap-baseline.py`. Skrip itu **hanya ada di image penuh**
(`zaproxy/zaproxy`), **tidak ada di `zap-bare`**. Karena kita memakai `zap-bare` yang ringan, kita
pakai **ZAP Automation Framework**: sebuah berkas rencana `plan.yaml` yang dijalankan dengan
`zap.sh -cmd -autorun`. Cara ini lebih modern, lebih fleksibel, dan tetap headless (tanpa GUI).

### A.4 Tingkat risiko ZAP
ZAP memberi peringkat pada tiap alert:

| Risiko | Kode di JSON | Arti |
|---|---|---|
| High | 3 | dampak tinggi, perlu segera |
| Medium | 2 | perlu ditinjau |
| Low | 1 | dampak kecil / hardening |
| Informational | 0 | catatan, bukan kerentanan langsung |

Tiap alert juga membawa **CWE** (`cweid`) dan **WASC** (`wascid`) — berguna untuk pemetaan.

---

## Bagian B — Menjalankan aplikasi target

ZAP berjalan di dalam container, target juga di container. Persoalan utamanya: **bagaimana container
ZAP menjangkau Juice Shop.** Solusinya berbeda per sistem operasi.

Jalankan Juice Shop:
```bash
docker compose up -d              # dari LK02, atau:
docker run -d --rm -p 3000:3000 --name juice-shop bkimminich/juice-shop
```

Tentukan **URL target** sesuai lingkungan Anda:

| Lingkungan | URL target untuk ZAP | Cara jalankan container ZAP |
|---|---|---|
| macOS / Windows (Docker Desktop, OrbStack) | `http://host.docker.internal:3000` | biasa |
| Linux | `http://localhost:3000` | tambahkan `--network host` |

Uji dulu bahwa container ZAP benar-benar bisa menjangkau target (harus `200`):
```bash
docker run --rm zaproxy/zap-bare \
  bash -c "curl -s -o /dev/null -w '%{http_code}' http://host.docker.internal:3000"
```

Sepanjang panduan ini dipakai `http://host.docker.internal:3000`. Ganti sesuai tabel di atas.

---

## Bagian C — Baseline scan (spider + passive)

### C.1 Buat rencana automation
Siapkan folder luaran dan berkas `plan.yaml`. ZAP membaca/menulis di `/zap/wrk` di dalam container,
yang kita mount ke `labs/LK05-dast`.

```bash
cd devsecops-<nim>
mkdir -p labs/LK05-dast
```

Buat `labs/LK05-dast/plan.yaml` — ganti `<NIM>` pada `reportTitle` dengan NIM Anda (ini watermark
Anda, dan terbukti ikut tercetak di laporan):

```yaml
env:
  contexts:
    - name: juice
      urls: [ "http://host.docker.internal:3000" ]
  parameters:
    failOnError: false
    progressToStdout: true
jobs:
  - type: spider
    parameters:
      url: "http://host.docker.internal:3000"
      maxDuration: 2            # menit; batasi agar tidak terlalu lama
  - type: passiveScan-wait
  - type: report
    parameters:
      template: traditional-html
      reportDir: /zap/wrk
      reportFile: zap-baseline
      reportTitle: "DAST Baseline Juice Shop - ds-<NIM>"
  - type: report
    parameters:
      template: traditional-json
      reportDir: /zap/wrk
      reportFile: zap-baseline
```

### C.2 Jalankan
```bash
docker run --rm -v "$PWD/labs/LK05-dast:/zap/wrk:rw" zaproxy/zap-bare \
  zap.sh -cmd -autorun /zap/wrk/plan.yaml
```

Yang terjadi (dan patokan hasilnya pada Juice Shop):

```
Job spider found 101 URLs           <- spider memetakan aplikasi
Job passiveScan-wait finished
Job report generated report /zap/wrk/zap-baseline.html
Job report generated report /zap/wrk/zap-baseline.json
Automation plan succeeded!
```

Prosesnya ±1–3 menit. Hasilnya dua berkas: `zap-baseline.html` (untuk dibaca manusia) dan
`zap-baseline.json` (untuk triage terprogram).

> Kalau spider hanya menemukan sedikit URL (mis. < 10), kemungkinan target tidak terjangkau —
> periksa lagi URL/`--network` di Bagian B.

---

## Bagian D — Membaca hasil

### D.1 Ringkas alert dari JSON
```bash
python3 - <<'PY'
import json, pathlib, collections
d = json.loads(pathlib.Path('labs/LK05-dast/zap-baseline.json').read_text())
site = d['site'][0]
risk = {'3':'High','2':'Medium','1':'Low','0':'Info'}
print('target    :', site['@name'])
print('jml alert :', len(site['alerts']))
print()
print(f"{'Risk':7} {'#inst':5}  CWE   Alert")
c = collections.Counter()
for a in sorted(site['alerts'], key=lambda x:-int(x['riskcode'])):
    c[risk[a['riskcode']]] += 1
    print(f"{risk[a['riskcode']]:7} {a['count']:>5}  {a.get('cweid','-'):>4}  {a['alert']}")
print('\nper risiko:', dict(c))
PY
```

### D.2 Patokan hasil baseline pada Juice Shop
Karena ini scan **pasif**, temuannya berupa masalah header/konfigurasi — bukan injeksi. Angka yang
wajar:

| Risk | Alert | Instance |
|---|---|---|
| Medium | Content Security Policy (CSP) Header Not Set | 3 |
| Medium | Cross-Domain Misconfiguration | 1 |
| Low | Timestamp Disclosure - Unix | 5 |
| Info | Modern Web Application | 5 |

Kalau hasil Anda mirip ini, scan berjalan benar. Inilah pelajaran inti LK05:
**baseline pasif menemukan kelemahan konfigurasi (OWASP A05), bukan SQLi/XSS.** Untuk yang terakhir
butuh active scan (Bagian F) atau eksploitasi manual (LK06).

### D.3 Struktur satu alert
Tiap alert pada JSON memuat: `alert`, `riskcode`, `confidence`, `count`, `cweid`, `wascid`, `desc`,
`solution`, `reference`, dan daftar `instances` (URL yang terdampak). Semua ini bahan laporan Anda.

---

## Bagian E — Triage dan pemetaan OWASP

Untuk tiap alert, tentukan di laporan:

1. **Nyata atau noise?** Contoh: "Timestamp Disclosure" sering berdampak rendah; "CSP Header Not Set"
   nyata dan relevan untuk pertahanan XSS.
2. **Kategori OWASP 2021.** Petakan dari `cweid` dan sifat masalahnya. Panduan cepat:

| Alert ZAP | CWE | OWASP 2021 |
|---|---|---|
| CSP Header Not Set | 693 | A05 Security Misconfiguration |
| Cross-Domain Misconfiguration | 264 | A05 Security Misconfiguration |
| Timestamp Disclosure | 497 | A01/A04 (Information Exposure) |
| Missing Anti-clickjacking Header | 1021 | A05 |
| Server Leaks Version Info | 200 | A05 |

3. **Alert pasif vs (kandidat) aktif.** Tandai alert yang butuh verifikasi dengan active scan atau
   manual (mis. dugaan injeksi pada parameter tertentu) untuk ditindaklanjuti di LK06.

Susun tabel triage:

| ID | Alert | Risk | CWE | OWASP | Nyata/Noise | Catatan |
|---|---|---|---|---|---|---|
| ZAP-01 | CSP Header Not Set | Medium | 693 | A05 | Nyata | pertahanan XSS lemah |
| ZAP-02 | Cross-Domain Misconfig | Medium | 264 | A05 | Nyata | tinjau kebijakan CORS |
| … | … | … | … | … | … | … |

---

## Bagian F — Active scan (opsional, nilai plus)

> **Peringatan etika:** active scan benar-benar menyuntik payload dan bisa mengubah data. **Hanya**
> pada Juice Shop lab milik Anda sendiri. Prinsip: authorized, scoped, documented. Prosesnya jauh
> lebih lama (bisa 10–30 menit).

Tambahkan job `activeScan` sebelum job report, pada `plan.yaml` baru (`plan-active.yaml`):

```yaml
env:
  contexts:
    - name: juice
      urls: [ "http://host.docker.internal:3000" ]
  parameters: { failOnError: false, progressToStdout: true }
jobs:
  - type: spider
    parameters: { url: "http://host.docker.internal:3000", maxDuration: 3 }
  - type: passiveScan-wait
  - type: activeScan
    parameters: { maxRuleDurationInMins: 2, maxScanDurationInMins: 20 }
  - type: report
    parameters:
      template: traditional-html
      reportDir: /zap/wrk
      reportFile: zap-active
      reportTitle: "DAST Active Juice Shop - ds-<NIM>"
```

Jalankan sama seperti C.2 (ganti nama plan). Bandingkan jumlah dan jenis temuan aktif vs baseline —
active scan biasanya memunculkan alert berisiko lebih tinggi (injeksi, XSS). Tulis perbandingannya.

---

## Bagian G — Laporan dan refleksi

Tulis `labs/LK05-dast/README.md`:

1. **Cara menjalankan** — perintah dan isi `plan.yaml`, agar dapat direproduksi.
2. **Ringkasan alert** (Bagian D.1) + tabel per risiko.
3. **Tabel triage** (Bagian E) dengan pemetaan OWASP.
4. **Alert kandidat untuk verifikasi aktif/manual** — jembatan ke LK06.
5. **Refleksi 150–300 kata** dengan kata-kata sendiri: mengapa baseline pasif tidak menemukan SQLi/XSS
   padahal Juice Shop penuh kerentanan itu; apa arti temuan yang Anda dapat.
6. **Footer**: `Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>`.

---

## Bagian H — Commit

```bash
git add labs/LK05-dast
git commit -m "LK05: DAST ZAP baseline + triage alert + pemetaan OWASP"
git push
```
Jangan commit `zap.log` atau berkas sesi besar bila ada; cukup `plan.yaml`, laporan HTML/JSON, dan
`README.md`.

---

## Luaran
- `labs/LK05-dast/plan.yaml`
- `labs/LK05-dast/zap-baseline.html` dan `zap-baseline.json`
- opsional: `zap-active.html` (Bagian F)
- `labs/LK05-dast/README.md` (ringkasan, triage, refleksi)

## Kriteria penilaian
Rubrik lengkap ada di KEBIJAKAN §4. Ringkasnya:

| Aspek | Bobot |
|---|---|
| Refleksi dan pemahaman (kata sendiri) | 30% |
| Keberhasilan scan + bukti (laporan ber-watermark) | 30% |
| Demo/viva bila diminta | 20% |
| Triage dan ketepatan pemetaan OWASP | 15% |
| Kerapian repo dan commit | 5% |

## Checklist submit
- [ ] Container ZAP menjangkau target (uji `curl` = 200)
- [ ] `plan.yaml` dengan `reportTitle` memuat `ds-<NIM>`
- [ ] Baseline scan menghasilkan `zap-baseline.html` + `zap-baseline.json`
- [ ] Alert diringkas dan di-triage (nyata vs noise)
- [ ] Setiap alert dipetakan ke OWASP 2021
- [ ] Alert kandidat verifikasi aktif/manual ditandai (jembatan ke LK06)
- [ ] Refleksi 150–300 kata menjelaskan kenapa pasif ≠ menemukan injeksi
- [ ] Sudah `git push`

## Troubleshooting
- **`zap-baseline.py: not found`.** Itu karena memakai `zap-bare`. Jangan pakai skrip itu — pakai
  Automation Framework (`zap.sh -cmd -autorun`) seperti panduan ini.
- **Spider hanya menemukan sedikit URL / laporan kosong.** Target tidak terjangkau. Di macOS/Windows
  pakai `http://host.docker.internal:3000`; di Linux pakai `--network host` dan `http://localhost:3000`.
- **`Permission denied` menulis laporan.** Pastikan mount `-v "$PWD/labs/LK05-dast:/zap/wrk:rw"` dan
  `reportDir: /zap/wrk`.
- **Peringatan `platform (linux/amd64) does not match ... arm64`.** Hanya peringatan di Mac Apple
  Silicon; ZAP tetap jalan lewat emulasi. Bila terlalu lambat, biarkan saja untuk latihan.
- **Baseline "cuma" 4 temuan.** Itu benar — pasif memang begitu. Untuk temuan injeksi jalankan
  Bagian F (active) atau lanjut ke LK06.
- **Windows PowerShell.** Ganti `"$PWD"` dengan `${PWD}`, atau jalankan lewat Git Bash / WSL.