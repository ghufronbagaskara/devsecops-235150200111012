# LK03 — Basic Scan #1: SCA & Secret Scanning

> **Minggu 3 · Sub-CPMK-3, Sub-CPMK-4 · Bobot 2% · Durasi 2×50 menit (2 SKS kelas hands-on; dilanjutkan mandiri) · Individu**

## Tujuan

Memindai **dependensi** (Software Composition Analysis) dan **secret** pada aplikasi rentan,
membaca serta men-triage hasilnya, lalu memetakan temuan ke **OWASP Top 10** — terutama
A06 (komponen usang/rentan) dan A02/A05 (kredensial bocor & salah konfigurasi).

## Prasyarat

- LK01 dan LK02 selesai (Docker jalan, repo `devsecops-<nim>` sudah di-clone).
- `project/IDENTITY.md` sudah diisi (NIM, watermark, fokus OWASP).

---

## Bagian A — Konsep dulu (untuk yang belum pernah)

Aplikasi modern jarang ditulis dari nol. Sebagian besar barisnya datang dari **dependensi** —
pustaka pihak ketiga yang kita pasang lewat `npm install`, `pip install`, dan sejenisnya. Setiap
dependensi bisa membawa dependensi lain lagi (disebut **transitive dependency**), sehingga satu
perintah install bisa menarik ratusan paket yang tidak pernah kita baca kodenya.

### A.1 Apa itu SCA

**Software Composition Analysis** adalah proses mendata seluruh komponen yang dipakai aplikasi, lalu
mencocokkan nama dan versinya dengan basis data kerentanan publik. Kalau versi yang kita pakai masuk
rentang yang diketahui rentan, scanner melaporkannya.

Alurnya sederhana:

```
manifest (package.json / package-lock.json)  ->  daftar komponen + versi
                                             ->  cocokkan ke basis data CVE (NVD, GHSA)
                                             ->  laporan temuan + versi perbaikan
```

Istilah yang akan sering muncul:

| Istilah              | Arti                                                                 |
| -------------------- | -------------------------------------------------------------------- |
| CVE                  | Nomor identitas unik sebuah kerentanan publik, mis. `CVE-2021-44228` |
| CVSS                 | Skor keparahan 0.0–10.0; dipetakan ke LOW / MEDIUM / HIGH / CRITICAL |
| Fixed version        | Versi yang sudah menambal kerentanan tersebut                        |
| Unfixed              | Kerentanan yang belum ada perbaikannya dari pembuat pustaka          |
| Direct vs transitive | Dependensi yang kita pasang sendiri, vs yang ikut terbawa            |

### A.2 Dua sasaran SCA yang berbeda

Yang sering membingungkan pemula: satu aplikasi bisa dipindai dari **dua sudut**, dan hasilnya
memang berbeda. Keduanya diperlukan.

| Sasaran                 | Yang diperiksa                                            | Contoh temuan                           |
| ----------------------- | --------------------------------------------------------- | --------------------------------------- |
| **Filesystem / source** | dependensi aplikasi dari `package-lock.json`              | pustaka npm versi rentan                |
| **Container image**     | paket sistem operasi di dalam image + dependensi aplikasi | `openssl`, `zlib`, `busybox` versi lama |

### A.3 Apa itu secret scanning

**Secret** adalah kredensial: kunci API, token, password, private key. Secret yang ter-commit ke
repositori berbahaya karena siapa pun yang bisa membaca repo (atau histori-nya) bisa memakainya.

Yang penting dipahami: **menghapus secret di commit terbaru tidak menghapusnya dari histori git.**
Commit lama masih menyimpannya dan tetap bisa diambil. Karena itu scanner seperti Gitleaks memeriksa
bukan hanya berkas saat ini, tetapi juga seluruh riwayat commit. Dan kalau sebuah secret pernah bocor,
satu-satunya perbaikan yang benar adalah **merotasi** (mengganti) kredensial itu, bukan sekadar
menghapus barisnya.

### A.4 Perkakas yang dipakai

| Tool               | Fungsi                                 | Image Docker           |
| ------------------ | -------------------------------------- | ---------------------- |
| Trivy              | SCA dependensi + scan image container  | `aquasec/trivy`        |
| Grype (alternatif) | SCA dependensi                         | `anchore/grype`        |
| Gitleaks           | Secret scanning (berkas + histori git) | `zricethezav/gitleaks` |

---

## Bagian B — Persiapan

### B.1 Siapkan folder luaran dan folder target ber-watermark

Sesuai KEBIJAKAN, hasil scan harus membawa jejak identitas Anda. Caranya: clone source ke folder yang
namanya memuat NIM, sehingga path di dalam berkas hasil scan ikut ter-watermark.

```bash
cd devsecops-<nim>                      # repo tugas Anda
mkdir -p labs/LK03-sca-secret
git clone --depth 200 https://github.com/juice-shop/juice-shop.git ds-<NIM>-target
```

Kenapa `--depth 200` dan bukan `--depth 1`: Gitleaks perlu **riwayat commit** untuk mencari secret
yang pernah ada lalu dihapus. Dengan `--depth 1` histori-nya kosong dan bagian paling menarik dari
secret scanning jadi hilang. Kalau koneksi lambat, `--depth 50` masih cukup untuk latihan.

### B.2 Pastikan folder target tidak ikut ter-commit

Source pihak ketiga tidak boleh masuk repo tugas Anda.

```bash
grep -q '\-target/' .gitignore || printf '*-target/\n' >> .gitignore
```

### B.3 Siapkan cache Trivy (opsional tapi disarankan)

Trivy mengunduh basis data kerentanan (±700 MB) saat pertama kali jalan. Dengan volume cache,
unduhan itu dipakai ulang di scan berikutnya.

```bash
docker volume create trivy-cache
```

---

## Bagian C — SCA pada dependensi aplikasi (filesystem)

Kita pindai folder source. Perhatikan pola mount: satu volume untuk **input** (`/src`) dan satu lagi
untuk **output** (`/out`), supaya berkas hasil benar-benar tersimpan di laptop Anda.

```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/src" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy fs --scanners vuln \
  --severity HIGH,CRITICAL \
  --format json -o /out/trivy-fs.json /src
```

Arti opsinya:

| Opsi                        | Arti                                            |
| --------------------------- | ----------------------------------------------- |
| `fs`                        | mode pindai filesystem/direktori                |
| `--scanners vuln`           | hanya cari kerentanan (bukan misconfig/license) |
| `--severity HIGH,CRITICAL`  | saring agar fokus ke yang berdampak             |
| `--format json -o /out/...` | simpan hasil terstruktur untuk dilampirkan      |

Jalankan sekali lagi dengan format tabel supaya mudah dibaca manusia:

```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/src" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy fs --scanners vuln --severity HIGH,CRITICAL \
  --format table -o /out/trivy-fs.txt /src

head -40 labs/LK03-sca-secret/trivy-fs.txt
```

> Alternatif dengan Grype (boleh dipakai sebagai pembanding):
>
> ```bash
> docker run --rm -v "$PWD/ds-<NIM>-target:/src" anchore/grype dir:/src -o table
> ```
>
> Membandingkan dua scanner itu latihan bagus: hasilnya sering **tidak identik** karena basis data dan
> cara pencocokannya berbeda.

---

## Bagian D — SCA pada image container

Sekarang sudut pandang kedua: image yang dijalankan, termasuk paket sistem operasinya.

```bash
docker run --rm \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy image --severity HIGH,CRITICAL \
  --format json -o /out/trivy-image.json \
  bkimminich/juice-shop
```

Dan versi tabelnya:

```bash
docker run --rm \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy image --severity HIGH,CRITICAL \
  --format table -o /out/trivy-image.txt \
  bkimminich/juice-shop
```

Trivy akan menarik image langsung dari registry, jadi Anda **tidak perlu** memasang
`/var/run/docker.sock`. Bandingkan hasilnya dengan Bagian C: perhatikan munculnya paket OS yang tidak
ada di `package.json`. Catat perbedaan ini di laporan — inilah alasan kedua sudut pandang diperlukan.

---

## Bagian E — Secret scanning

### E.1 Pindai riwayat git

Ini mode terpenting: Gitleaks menelusuri seluruh commit yang tersedia.

```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/repo" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  zricethezav/gitleaks:latest detect \
  --source=/repo \
  --report-format json --report-path=/out/gitleaks-history.json \
  --redact
```

`--redact` menyamarkan nilai secret di laporan, sehingga laporan Anda aman di-commit. **Selalu pakai
opsi ini** — jangan sampai laporan tugas justru menjadi tempat bocornya kredensial.

### E.2 Pindai berkas saat ini saja

Sebagai pembanding, jalankan tanpa histori:

```bash
docker run --rm \
  -v "$PWD/ds-<NIM>-target:/repo" \
  -v "$PWD/labs/LK03-sca-secret:/out" \
  zricethezav/gitleaks:latest detect \
  --source=/repo --no-git \
  --report-format json --report-path=/out/gitleaks-worktree.json \
  --redact
```

Bandingkan jumlah temuan kedua mode itu dan jelaskan selisihnya di laporan. Kalau histori menghasilkan
lebih banyak temuan, itu bukti nyata bahwa menghapus secret saja tidak cukup.

> Catatan: Gitleaks mengembalikan **exit code bukan nol** ketika menemukan secret. Itu perilaku normal
> (dan justru berguna untuk gate CI/CD nanti di CB2), bukan tanda perintahnya gagal.
>
> Bila image `zricethezav/gitleaks` bermasalah, alternatif resminya `ghcr.io/gitleaks/gitleaks:latest`
> dengan argumen yang sama.

---

## Bagian F — Bonus: berkas yang terekspos di server (opsional, nilai plus)

Pada LK02 Anda menemukan direktori `/ftp` pada aplikasi yang berjalan menampilkan berkas cadangan.
Berkas seperti itu adalah kasus nyata kebocoran lewat salah konfigurasi. Ambil salah satunya lalu
pindai:

```bash
cd labs/LK03-sca-secret
curl -sO http://<IP-SERVER>:3000/ftp/package.json.bak
docker run --rm -v "$PWD:/src" -v trivy-cache:/root/.cache/ \
  aquasec/trivy fs --scanners vuln --severity HIGH,CRITICAL /src
cd ../..
```

Diskusikan di laporan: berkas `.bak` yang dapat diunduh publik masuk kategori OWASP apa, dan apa
dampaknya bila berisi daftar dependensi lengkap beserta versinya.

---

## Bagian G — Triage dan prioritisasi

Scanner menghasilkan daftar mentah. Tugas Anda adalah mengubahnya menjadi keputusan.

### G.1 Ringkas jumlah temuan

```bash
python3 - <<'PY'
import json, collections, pathlib
for nama in ['trivy-fs.json', 'trivy-image.json']:
    p = pathlib.Path('labs/LK03-sca-secret') / nama
    if not p.exists():
        continue
    data = json.loads(p.read_text())
    sev = collections.Counter()
    pkg = collections.Counter()
    for hasil in data.get('Results') or []:
        for v in hasil.get('Vulnerabilities') or []:
            sev[v.get('Severity')] += 1
            pkg[v.get('PkgName')] += 1
    print(f"\n== {nama} ==")
    print("per severity :", dict(sev))
    print("total temuan :", sum(sev.values()))
    print("paket teratas:", pkg.most_common(5))
PY
```

### G.2 Nilai tiap temuan

Untuk setiap temuan yang akan masuk laporan, tanyakan tiga hal:

1. **Seberapa parah?** Lihat severity dan skor CVSS.
2. **Bisa diperbaiki?** Apakah ada `FixedVersion`. Temuan tanpa perbaikan butuh mitigasi lain.
3. **Relevan tidak?** Apakah komponen itu benar-benar dipakai di jalur yang terekspos, atau hanya
   dependensi alat bantu pengembangan.

Temuan dengan severity tinggi **dan** ada versi perbaikan **dan** komponennya terekspos adalah
prioritas teratas.

### G.3 Susun tabel triage

Buat tabel di laporan Anda dengan bentuk berikut (isi dari hasil scan Anda sendiri):

| ID     | Temuan                            | Tipe       | Severity | Versi terpasang | Versi perbaikan | OWASP   | Prioritas | Rekomendasi                               |
| ------ | --------------------------------- | ---------- | -------- | --------------- | --------------- | ------- | --------- | ----------------------------------------- |
| SCA-01 | CVE-XXXX-XXXX pada `nama-paket`   | dependency | CRITICAL | 4.17.15         | 4.17.21         | A06     | Tinggi    | naikkan versi paket                       |
| IMG-01 | CVE-XXXX-XXXX pada `openssl`      | OS package | HIGH     | 1.1.1n          | 1.1.1t          | A06     | Sedang    | perbarui base image                       |
| SEC-01 | Token ditemukan di histori commit | secret     | HIGH     | —               | —               | A02/A05 | Tinggi    | rotasi kredensial, pindah ke secret store |

Minimal **10 temuan** ter-triage. Ingat ketentuan fokus per-NIM di KEBIJAKAN: sertakan setidaknya
2 temuan pada kategori OWASP **Primary** Anda dan 1 pada **Secondary**, dengan analisis lebih dalam
pada kategori tersebut.

---

## Bagian H — Laporan dan refleksi

Tulis `labs/LK03-sca-secret/README.md` yang memuat:

1. **Ringkasan eksekutif** — berapa temuan, sebaran severity, dan tiga risiko teratas.
2. **Cara menjalankan** — perintah yang Anda pakai, agar hasilnya dapat direproduksi.
3. **Tabel triage** dari Bagian G.3.
4. **Perbandingan** hasil scan filesystem vs image, dan gitleaks histori vs worktree.
5. **Analisis kategori fokus** Anda (OWASP Primary/Secondary).
6. **Refleksi 150–300 kata** dengan kata-kata sendiri: apa yang dikerjakan, kendala yang muncul, dan
   pelajaran yang didapat. Bagian ini dinilai dan tidak boleh disalin.
7. **Footer identitas**: `Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>`.

---

## Bagian I — Commit dan push

```bash
git add labs/LK03-sca-secret .gitignore
git commit -m "LK03: SCA dependensi & image + secret scanning + triage OWASP"
git push
```

Commit secara **bertahap** (misalnya setelah scan selesai, lalu setelah laporan ditulis), bukan satu
unggahan besar di akhir.

---

## Luaran

- `labs/LK03-sca-secret/trivy-fs.json` dan `trivy-fs.txt`
- `labs/LK03-sca-secret/trivy-image.json` dan `trivy-image.txt`
- `labs/LK03-sca-secret/gitleaks-history.json` dan `gitleaks-worktree.json`
- `labs/LK03-sca-secret/README.md` berisi triage, perbandingan, dan refleksi

## Kriteria penilaian

Rubrik lengkap ada di KEBIJAKAN §4. Ringkasnya untuk LK ini:

| Aspek                                    | Bobot |
| ---------------------------------------- | ----- |
| Refleksi dan pemahaman (kata sendiri)    | 30%   |
| Kebenaran teknis dan bukti ber-watermark | 30%   |
| Demo/viva bila diminta                   | 20%   |
| Dokumentasi dan ketepatan pemetaan OWASP | 15%   |
| Kerapian repo dan commit bertahap        | 5%    |

## Checklist submit

- [ ] Source di-clone ke folder `ds-<NIM>-target` (watermark ikut di path hasil scan)
- [ ] Trivy filesystem menghasilkan JSON dan tabel
- [ ] Trivy image menghasilkan JSON dan tabel
- [ ] Gitleaks dijalankan dua mode (histori dan worktree), memakai `--redact`
- [ ] Minimal 10 temuan ter-triage dan dipetakan ke OWASP
- [ ] Ada minimal 2 temuan pada OWASP Primary dan 1 pada Secondary
- [ ] Perbandingan filesystem vs image dan histori vs worktree dijelaskan
- [ ] Refleksi 150–300 kata ditulis sendiri
- [ ] Folder `*-target/` tidak ikut ter-commit
- [ ] Sudah `git push`

## Troubleshooting

- **Scan pertama sangat lama.** Trivy sedang mengunduh basis data kerentanan. Pakai volume
  `trivy-cache` agar scan berikutnya cepat.
- **Berkas hasil tidak muncul di laptop.** Hampir selalu karena path `-o` menunjuk ke dalam container,
  bukan ke folder yang di-mount. Pastikan output diarahkan ke `/out/...` dan `/out` sudah di-mount ke
  `labs/LK03-sca-secret`.
- **Gitleaks keluar dengan kode 1.** Itu artinya ada secret ditemukan, bukan error.
- **Gitleaks tidak menemukan apa pun di mode histori.** Kemungkinan clone terlalu dangkal. Ulangi
  dengan `--depth` lebih besar atau clone penuh.
- **`unable to initialize a scanner` atau gagal tarik image.** Periksa koneksi internet; Trivy perlu
  mengakses registry dan basis data kerentanan.
- **Windows PowerShell.** Ganti `"$PWD"` menjadi `${PWD}`, atau jalankan lewat Git Bash / WSL agar
  ekspansi path dan baris `\` bekerja seperti contoh.
- **Ingin memakai socket Docker (image lokal).** Tambahkan
  `-v /var/run/docker.sock:/var/run/docker.sock`. Pada OrbStack, path socketnya berbeda, mis.
  `-v $HOME/.orbstack/run/docker.sock:/var/run/docker.sock`.
