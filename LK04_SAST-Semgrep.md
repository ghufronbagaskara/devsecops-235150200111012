# LK04 — Basic Scan #2: SAST dengan Semgrep

> **Minggu 4 · Sub-CPMK-4 · Bobot 2% · Durasi 2×50 menit (2 SKS kelas hands-on; dilanjutkan mandiri) · Individu**

## Tujuan
Menjalankan **SAST** (analisis kode statis) dengan Semgrep terhadap kode aplikasi rentan, membaca
hasilnya, memisahkan temuan nyata dari alarm palsu (**triage TP/FP**), dan memetakannya ke
**OWASP Top 10**.

## Prasyarat
- LK03 selesai (Docker jalan, sudah terbiasa dengan pola mount `/out`).
- `project/IDENTITY.md` terisi (NIM, watermark, fokus OWASP).

---

## Bagian A — Konsep dulu (untuk yang belum pernah)

### A.1 Apa bedanya dengan LK03
LK03 memindai **dependensi** — kode buatan orang lain. LK04 memindai **kode aplikasi itu sendiri**.
Keduanya menemukan hal yang sama sekali berbeda.

| | LK03 (SCA) | LK04 (SAST) |
|---|---|---|
| Sasaran | pustaka pihak ketiga | kode sumber aplikasi |
| Cara kerja | cocokkan versi ke basis data CVE | cari **pola kode** yang berbahaya |
| Contoh temuan | `lodash 4.17.15` kena CVE | query SQL dirakit dari input pengguna |
| Perbaikan | naikkan versi paket | ubah cara menulis kodenya |

### A.2 Bagaimana SAST bekerja
SAST membaca kode **tanpa menjalankannya**. Semgrep tidak memakai pencarian teks biasa, melainkan
memahami **struktur** kode (AST), sehingga tahan terhadap perbedaan penulisan. Contoh: satu aturan
yang mencari penggabungan string ke dalam query SQL akan tetap cocok walau nama variabelnya berbeda,
spasinya berbeda, atau dipecah ke beberapa baris.

```
kode sumber  ->  diurai jadi struktur (AST)
             ->  dicocokkan dengan pola aturan (ruleset)
             ->  daftar temuan + lokasi file:baris + metadata OWASP/CWE
```

Karena tidak menjalankan aplikasi, SAST bisa dipakai sangat awal — bahkan sebelum aplikasi bisa
dijalankan. Itulah inti **shift-left**. Konsekuensinya, SAST tidak tahu konteks runtime, sehingga
wajar menghasilkan sebagian alarm palsu. Menyaringnya adalah pekerjaan Anda di LK ini.

### A.3 Ruleset
Aturan Semgrep dikelompokkan dalam *ruleset* yang diambil dari registry publik:

| Ruleset | Isi |
|---|---|
| `p/owasp-top-ten` | aturan yang dipetakan ke kategori OWASP Top 10 |
| `p/javascript` | pola tidak aman khas JavaScript/TypeScript |
| `p/secrets` | kredensial ter-hardcode |
| `p/ci` | keamanan konfigurasi CI/CD |

Kita pakai dua yang pertama. Tidak perlu akun atau token — cukup koneksi internet.

### A.4 Severity dan istilah triage

| Istilah | Arti |
|---|---|
| ERROR | dugaan masalah serius (Semgrep juga memakai istilah HIGH/CRITICAL pada aturan baru) |
| WARNING | perlu ditinjau, dampaknya bergantung konteks |
| INFO | informasional |
| **True Positive (TP)** | pola cocok **dan** memang masalah nyata pada aplikasi ini |
| **False Positive (FP)** | pola cocok tetapi bukan risiko nyata dalam konteks ini |

---

## Bagian B — Persiapan

Seperti LK03, folder sumber diberi nama ber-NIM lalu di-mount dengan nama yang sama, supaya path di
dalam hasil scan membawa jejak identitas Anda.

```bash
cd devsecops-<nim>
mkdir -p labs/LK04-sast

# Kalau folder dari LK03 masih ada, pakai saja. Kalau belum:
git clone --depth 1 https://github.com/juice-shop/juice-shop.git ds-<NIM>-target
```

Berbeda dari LK03, **SAST tidak memerlukan lock file** — Semgrep membaca kode sumbernya langsung.

Pastikan folder target tetap tidak ikut ter-commit:
```bash
grep -q '\-target/' .gitignore || printf '*-target/\n' >> .gitignore
```

---

## Bagian C — Menjalankan Semgrep

### C.1 Keluaran SARIF (untuk GitHub dan CB2 nanti)
```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/ds-<NIM>-target" \
  -v "$PWD/labs/LK04-sast:/out" \
  semgrep/semgrep semgrep scan \
  --config p/owasp-top-ten --config p/javascript \
  --sarif -o /out/semgrep.sarif \
  /ds-<NIM>-target
```

### C.2 Keluaran JSON (untuk triage)
```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/ds-<NIM>-target" \
  -v "$PWD/labs/LK04-sast:/out" \
  semgrep/semgrep semgrep scan \
  --config p/owasp-top-ten --config p/javascript \
  --json -o /out/semgrep.json \
  /ds-<NIM>-target
```

Arti opsinya:

| Opsi | Arti |
|---|---|
| `scan` | subperintah pemindaian |
| `--config p/...` | ruleset yang dipakai; boleh lebih dari satu |
| `--sarif` / `--json` | format keluaran |
| `-o /out/...` | simpan ke folder yang di-mount, bukan ke dalam container |
| argumen terakhir | folder yang dipindai |

**Patokan hasil.** Sekali jalan memakan waktu sekitar 30–60 detik. Angka yang wajar:

| Ukuran | Perkiraan |
|---|---|
| Aturan dijalankan | ±180 |
| Berkas dipindai | ±1.000 |
| Temuan | **±40** (ERROR ±13, WARNING ±28) |

Kalau temuan Anda **nol**, kemungkinan besar argumen folder salah atau ruleset gagal diunduh —
periksa pesan di terminal.

> Semgrep keluar dengan kode 0 walau menemukan masalah. Untuk memakainya sebagai *gate* di CI/CD
> nanti (CB2), tambahkan `--error` agar keluar dengan kode bukan nol saat ada temuan.

---

## Bagian D — Membaca hasilnya

Yang membuat Semgrep enak dipakai: **setiap temuan sudah membawa pemetaan OWASP dan CWE**, jadi Anda
tidak perlu menebak. Informasi itu ada di `extra.metadata`.

Struktur satu temuan pada JSON:

```
check_id          -> nama aturan
path              -> berkas
start.line        -> nomor baris
extra.severity    -> ERROR / WARNING / INFO
extra.message     -> penjelasan masalah
extra.metadata.owasp -> kategori OWASP
extra.metadata.cwe   -> kategori CWE
extra.lines       -> potongan kode yang memicu
```

### D.1 Ringkas temuan
```bash
python3 - <<'PY'
import json, collections, pathlib
d = json.loads(pathlib.Path('labs/LK04-sast/semgrep.json').read_text())
res = d.get('results', [])
print('total temuan :', len(res))
print('per severity :', dict(collections.Counter(r['extra']['severity'] for r in res)))
print('\naturan terbanyak:')
for k, v in collections.Counter(r['check_id'].split('.')[-1] for r in res).most_common(10):
    print(f'  {v:3d}  {k}')
print('\nkategori OWASP:')
ow = collections.Counter()
for r in res:
    for o in (r['extra'].get('metadata', {}).get('owasp') or ['(tanpa label)']):
        ow[o if isinstance(o, str) else str(o)] += 1
for k, v in ow.most_common(10):
    print(f'  {v:3d}  {k}')
PY
```

### D.2 Hasilkan draf tabel triage otomatis
Supaya tidak menyalin manual satu per satu, buat kerangka tabelnya dulu lalu tinggal diisi kolom
TP/FP dan alasannya:

```bash
python3 - <<'PY'
import json, pathlib
d = json.loads(pathlib.Path('labs/LK04-sast/semgrep.json').read_text())
print('| ID | Aturan | Lokasi | Severity | OWASP | TP/FP | Alasan |')
print('|---|---|---|---|---|---|---|')
for i, r in enumerate(sorted(d['results'], key=lambda x: x['path']), 1):
    rid = r['check_id'].split('.')[-1]
    path = r['path'].split('-target/', 1)[-1]
    ow = (r['extra'].get('metadata', {}).get('owasp') or ['-'])
    ow = ow[0] if isinstance(ow, list) else ow
    ow = str(ow).split(' - ')[0]
    print(f"| SAST-{i:02d} | `{rid}` | `{path}:{r['start']['line']}` | "
          f"{r['extra']['severity']} | {ow} |  |  |")
PY
```

Salin keluarannya ke laporan Anda, lalu isi dua kolom terakhir sendiri. **Kolom TP/FP dan alasan
itulah yang dinilai** — bukan tabel hasil salinannya.

### D.3 Hati-hati: label OWASP bercampur beberapa edisi
Anda akan melihat label seperti `A01:2017 - Injection`, `A03:2021 - Injection`, dan
`A05:2025 - Injection` pada temuan yang sebenarnya sekelas. Itu karena aturan Semgrep ditulis pada
waktu berbeda dan memakai penomoran edisi OWASP yang berbeda pula.

Contoh yang paling sering membingungkan: **Injection** adalah **A01 pada edisi 2017**, tetapi
**A03 pada edisi 2021** — edisi yang dipakai mata kuliah ini.

Jadi jangan menyalin angkanya mentah-mentah. **Petakan ulang ke OWASP Top 10:2021** di tabel triage
Anda, dan sebutkan di laporan kalau Anda menemukan ketidakcocokan seperti ini. Justru menyadari hal
ini menunjukkan Anda membaca hasilnya, bukan sekadar menempel.

---

## Bagian E — Triage: memisahkan temuan nyata dari alarm palsu

Ini bagian terpenting. Untuk setiap temuan, tanyakan tiga hal:

1. **Apakah polanya memang berbahaya?** Baca `extra.message` dan potongan kode di `extra.lines`.
2. **Apakah kode ini benar-benar dipakai?** Kode contoh, berkas uji, atau dokumentasi berbeda
   bobotnya dengan kode yang melayani permintaan pengguna.
3. **Bisakah input pengguna mencapai titik itu?** Kalau nilainya konstan atau berasal dari sumber
   tepercaya, risikonya jauh lebih kecil.

### E.1 Contoh nyata yang akan Anda temui

Beberapa temuan pada Juice Shop yang layak dibahas di laporan:

| Temuan | Lokasi | Penilaian |
|---|---|---|
| `express-sequelize-injection` | `routes/login.ts` | **TP kuat.** Query login dirakit dari input. Inilah celah yang akan Anda eksploitasi di LK06. |
| `express-sequelize-injection` | `routes/search.ts` | **TP kuat.** SQL injection pada fitur pencarian. |
| `hardcoded-jwt-secret` | `lib/insecurity.ts` | **TP.** Kunci JWT ditulis langsung di kode (A07). |
| `express-check-directory-listing` | `server.ts` | **TP — dan menarik.** Inilah sumber direktori `/ftp` yang bisa Anda telusuri saat recon di LK02. SAST menemukan *penyebabnya di kode*, recon menemukan *akibatnya di aplikasi berjalan*. |
| `express-sequelize-injection` | `data/static/codefixes/*.ts` | **Perlu nuansa.** Polanya benar, tetapi berkas ini adalah contoh soal/jawaban Juice Shop, bukan kode yang melayani aplikasi. |
| `aws-subnet-has-public-ip-address` | berkas `*.tf` | **Konteks berbeda.** Aturan Terraform ikut jalan pada berkas IaC, bukan pada aplikasi web-nya. |
| `run-shell-injection` | `.github/workflows/*.yml` | **TP, tapi sasarannya CI/CD.** Ini kelas kerentanan rantai pasok — relevan nanti di CB2, bukan pada aplikasi web. |

Perhatikan pelajaran pentingnya: **temuan yang sama bisa TP atau FP tergantung di mana ia muncul.**
Itu sebabnya triage tidak bisa diserahkan sepenuhnya ke alat.

### E.2 Menandai false positive dengan benar
Kalau Anda yakin sebuah temuan adalah FP, tandai di kode dengan **alasan tertulis**:

```javascript
// nosemgrep: express-sequelize-injection -- nilai berasal dari konstanta internal, bukan input user
```

Jangan pernah mematikan aturan secara diam-diam tanpa alasan. Di laporan, FP yang tidak disertai
argumen dianggap belum di-triage.

---

## Bagian F — Ringkasan dan prioritisasi

Tulis di laporan:

- Total temuan, jumlah **TP** vs **FP**, dan sebaran severity.
- Kategori OWASP yang paling sering muncul.
- **Lima temuan prioritas** untuk diperbaiki nanti di CB3, beserta alasan pemilihannya.
- Sesuai KEBIJAKAN: sertakan analisis lebih dalam pada **OWASP Primary** Anda (minimal 2 temuan) dan
  **Secondary** (minimal 1). Bila kategori fokus Anda tidak muncul di hasil scan, jelaskan mengapa —
  itu pun temuan yang sah.

---

## Bagian G — Menulis aturan sendiri (opsional, nilai plus)

Semgrep memakai berkas YAML sederhana. Buat `labs/LK04-sast/aturan-saya.yml`:

```yaml
rules:
  - id: hindari-eval
    pattern: eval(...)
    message: Pemakaian eval() memungkinkan eksekusi kode dari input tak tepercaya.
    languages: [javascript, typescript]
    severity: ERROR
    metadata:
      owasp: "A03:2021 - Injection"
      cwe: "CWE-95"
```

Jalankan dengan aturan Anda sendiri:
```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/ds-<NIM>-target" \
  -v "$PWD/labs/LK04-sast:/out" \
  semgrep/semgrep semgrep scan \
  --config /out/aturan-saya.yml \
  /ds-<NIM>-target
```

Jelaskan di laporan: apa yang dicari aturan itu dan berapa temuan yang dihasilkan.

---

## Bagian H — Laporan dan refleksi

Tulis `labs/LK04-sast/README.md` berisi:

1. **Ringkasan** — total temuan, TP vs FP, sebaran severity dan OWASP.
2. **Cara menjalankan** — perintah yang dipakai, agar dapat direproduksi.
3. **Tabel triage** (Bagian D.2 yang sudah diisi kolom TP/FP dan alasan).
4. **Pembahasan 5 temuan prioritas** beserta alasannya.
5. **Perbandingan dengan LK03** — jenis masalah apa yang ditemukan SAST tetapi luput dari SCA, dan
   sebaliknya. Ini menunjukkan mengapa keduanya diperlukan.
6. **Refleksi 150–300 kata** dengan kata-kata sendiri.
7. **Footer**: `Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>`.

---

## Bagian I — Commit

```bash
git add labs/LK04-sast .gitignore
git commit -m "LK04: SAST Semgrep + triage TP/FP + pemetaan OWASP"
git push
```

---

## Luaran
- `labs/LK04-sast/semgrep.sarif`
- `labs/LK04-sast/semgrep.json`
- `labs/LK04-sast/README.md` (triage, prioritas, perbandingan, refleksi)
- opsional: `labs/LK04-sast/aturan-saya.yml`

## Kriteria penilaian
Rubrik lengkap ada di KEBIJAKAN §4. Ringkasnya:

| Aspek | Bobot |
|---|---|
| Refleksi dan pemahaman (kata sendiri) | 30% |
| Kualitas triage TP/FP beserta alasannya | 30% |
| Demo/viva bila diminta | 20% |
| Dokumentasi dan ketepatan pemetaan OWASP | 15% |
| Kerapian repo dan commit bertahap | 5% |

## Checklist submit
- [ ] Semgrep menghasilkan SARIF dan JSON, keduanya tersimpan di `labs/LK04-sast/`
- [ ] Jumlah temuan masuk akal (bukan nol)
- [ ] Minimal **15 temuan** ter-triage TP/FP **dengan alasan**
- [ ] Minimal 2 temuan pada OWASP Primary dan 1 pada Secondary
- [ ] 5 temuan prioritas ditetapkan dan dijelaskan
- [ ] Perbandingan SAST vs SCA (LK03) ditulis
- [ ] Refleksi 150–300 kata
- [ ] Folder `*-target/` tidak ikut ter-commit

## Troubleshooting
- **Temuan nol / berkas hasil kosong.** Cek argumen folder yang dipindai sudah benar
  (`/ds-<NIM>-target`, sama persis dengan nama mount). Cek juga terminal: bila ruleset gagal diunduh,
  Semgrep memberi tahu.
- **Berkas hasil tidak muncul di laptop.** Sama seperti LK03: `-o` harus mengarah ke `/out/...` dan
  `/out` sudah di-mount ke `labs/LK04-sast`.
- **`unknown config` atau gagal mengambil ruleset.** Butuh koneksi internet; nama ruleset diawali
  `p/`. Periksa ejaannya.
- **Scan terasa lama.** Wajar: ±1.000 berkas dengan ±180 aturan memakan 30–60 detik. Untuk mencoba
  cepat, pindai satu folder saja, mis. `/ds-<NIM>-target/routes`.
- **Banyak temuan pada `.tf` atau `.github/workflows`.** Itu bukan galat — ruleset OWASP mencakup IaC
  dan CI/CD. Justru jadikan bahan pembahasan triage Anda.
- **Windows PowerShell.** Ganti `"$PWD"` dengan `${PWD}`, atau jalankan lewat Git Bash / WSL.
