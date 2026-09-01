# Kebijakan Praktik DevSecOps

Semua mahasiswa memakai langkah dan aplikasi yang kurang lebih sama, sehingga wajar bila luaran mudah
terlihat mirip. Dokumen ini menjelaskan cara menjaga agar tiap pekerjaan tetap milik masing-masing,
tetap kolaboratif, dan dinilai berdasarkan pemahaman. Bacalah sebelum mulai.

Daftar isi:

1. [Pembagian Fokus Tugas per-NIM](#1-pembagian-fokus-tugas-per-nim)
2. [Integritas Akademik](#2-integritas-akademik)
3. [Peer Security Review](#3-peer-security-review)
4. [Rubrik Penilaian](#4-rubrik-penilaian)
5. [Alur Evaluasi](#5-alur-evaluasi)

Organization kelas: **https://github.com/Devsecops-Filkom-2026**

---

# 1) Pembagian Fokus Tugas per-NIM

Metode praktiknya sama, tetapi tiap mahasiswa diberi fokus OWASP yang berbeda dan menandai
pekerjaannya dengan identitasnya sendiri. Dengan begitu hasil kerja tidak mungkin identik, dan menyalin
punya orang lain jadi gampang ketahuan. Bagian ini wajib dan diperiksa dosen.

## 1.1 Manifest identitas

Pada Minggu 1, tiap mahasiswa membuat `project/IDENTITY.md` dan meng-commit-nya lebih dulu:

```markdown
# IDENTITY
- Nama : <Nama Lengkap>
- NIM  : <NIM>
- Watermark (WM) : ds-<NIM>
- OWASP Primary   : A0<k>    (lihat formula di bawah)
- OWASP Secondary : A0<m>
- Target App      : <default Juice Shop, atau sesuai rotasi kelas>
- Repo            : https://github.com/Devsecops-Filkom-2026/devsecops-<nim>
- Bantuan AI      : <sebutkan bila memakai AI untuk belajar, atau "tidak ada">
```

Dosen memakai berkas ini untuk mengecek apakah temuan dan remediasi seorang mahasiswa memang sesuai
fokus yang ditugaskan kepadanya.

## 1.2 Formula pembagian fokus

Ambil dua digit terakhir NIM, sebut `d2` (00–99).

```
k = (d2 mod 10) + 1          -> OWASP Primary   = A0k   (A01..A10)
m = ((d2 div 10) mod 10) + 1 -> OWASP Secondary = A0m
WM = "ds-" + NIM             -> watermark identitas
```

Contoh:

| NIM (…) | d2 | Primary | Secondary | Watermark |
|---|---|---|---|---|
| …15 | 15 | (15 mod 10)+1 = A06 | (1 mod 10)+1 = A02 | ds-…15 |
| …23 | 23 | (3)+1 = A04 | (2)+1 = A03 | ds-…23 |
| …40 | 40 | (0)+1 = A01 | (4)+1 = A05 | ds-…40 |
| …77 | 77 | (7)+1 = A08 | (7)+1 = A08 → A09* | ds-…77 |

Bila `k` sama dengan `m`, geser Secondary ke `A0((m mod 10)+1)`. Untuk NIM berakhiran 77, Secondary
menjadi A09.

## 1.3 Konsekuensi pembagian di tiap fase

| Fase | Yang harus mencerminkan fokus Anda |
|---|---|
| LK03–LK06 (scan/exploit) | Minimal 2 temuan di OWASP Primary dan 1 di Secondary, dengan analisis yang lebih dalam pada kategori itu. |
| CB1 (VA/UTS) | Risk register menyorot kategori Primary/Secondary sebagai bahasan mendalam. |
| CB3 (Remediasi) | Perbaiki minimal 3 temuan di Primary dan 2 di Secondary, sehingga set perbaikan tiap orang berbeda. |
| CB4 (Risk/SBOM) | Skor CVSS dan keputusan risiko difokuskan pada temuan kategori Anda. |

## 1.4 Watermark pada bukti

Supaya bukti tidak bisa dipinjam dari orang lain, tiap artefak harus memuat identitas pemiliknya:

- Akun uji didaftarkan dengan email `<nim>@student.ub.ac.id`.
- Payload PoC memuat watermark, misalnya `<script>alert('ds-<NIM>')</script>`, atau string
  `ds-<NIM>` pada input uji.
- Tangkapan layar menampilkan URL, nama pengguna/hostname terminal, dan waktu.
- Footer laporan tiap LK ditulis: `Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>`.

Bukti yang tidak memuat watermark milik pengumpul dianggap tidak sah.

## 1.5 Rotasi aplikasi target (opsional)

Untuk kelas paralel yang besar, dosen boleh merotasi aplikasi target agar hasil makin beragam. Langkah
scan dan DAST tetap sama, hanya image dan URL yang berganti.

| NIM mod 4 | Aplikasi | Menjalankan |
|---|---|---|
| 0 | OWASP Juice Shop | `docker run -p 3000:3000 bkimminich/juice-shop` |
| 1 | OWASP WebGoat | `docker run -p 8080:8080 -p 9090:9090 webgoat/webgoat` |
| 2 | DVWA | `docker run -p 8081:80 vulnerables/web-dvwa` |
| 3 | OWASP NodeGoat | `docker compose up` (fork repo OWASP/NodeGoat) |

Bila tidak dirotasi, default mata kuliah adalah Juice Shop. Panduan LK ditulis untuk Juice Shop; untuk
aplikasi lain cukup sesuaikan URL dan portnya karena metodologinya sama.

## 1.6 Cara dosen memverifikasi

Dosen mencocokkan isi `project/IDENTITY.md` dengan NIM dan formula, memastikan temuan serta remediasi
sesuai fokus yang ditugaskan, dan mencari watermark `ds-<NIM>` di setiap bukti. Berkas output scan yang
persis sama antar mahasiswa menjadi tanda kuat adanya penyalinan (lihat bagian 2).

---

# 2) Integritas Akademik

Integritas dijaga dari tiga arah: luaran yang menempel pada tiap individu (bagian 1), deteksi kesamaan,
dan pemeriksaan pemahaman.

## 2.1 Prinsip

Yang dinilai adalah pemahaman dan proses Anda, bukan file hasilnya. Output scan yang sama persis dengan
milik orang lain tidak bernilai apa-apa; yang bernilai adalah analisis, bukti yang ber-watermark, dan
kemampuan menjelaskan apa yang Anda kerjakan.

## 2.2 Yang boleh dan yang tidak

| Boleh | Tidak boleh |
|---|---|
| Berdiskusi soal konsep dan pendekatan | Menyalin laporan, kode, atau PoC mahasiswa lain |
| Saling meninjau lewat Peer Review | Menukar berkas output scan, SARIF, atau tangkapan layar |
| Memakai dokumentasi resmi dan AI untuk belajar | Menyerahkan hasil AI atau orang lain tanpa memahaminya |
| Meminjam ide struktur laporan | Mem-fork/klon repo teman lalu mengganti nama |

Pemakaian AI harus disebutkan di `project/IDENTITY.md`, dan mahasiswa tetap bertanggung jawab penuh
menjelaskan setiap baris hasilnya.

## 2.3 Bukti yang wajib disertakan

Setiap LK/CB harus memuat:

1. Watermark NIM pada akun uji, payload, dan footer laporan (lihat 1.4).
2. Commit yang bertahap — beberapa commit bermakna selama pengerjaan, bukan satu unggahan besar di
   akhir.
3. Refleksi 150–300 kata dengan kata-kata sendiri: apa yang dikerjakan, kendalanya, dan apa yang
   dipelajari.
4. Screencast atau asciinema 30–90 detik untuk tugas yang menuntut aksi langsung, yaitu LK06
   (eksploitasi), LK07 dan CB2 (pipeline), CB3 (sebelum/sesudah), dan CB4 (demo). Tampilkan
   watermark/NIM di layar saat merekam.

## 2.4 Cara dosen mendeteksi kecurangan

Beberapa cara dipakai bersamaan: pemeriksaan kesamaan kode dan laporan secara otomatis (bagian 2.4a),
pemeriksaan sidik jari output (bagian 2.4b), penelusuran fork network GitHub untuk melihat siapa
mengklon dari siapa, pemeriksaan riwayat commit yang polanya ganjil (satu commit besar atau waktu yang
seragam), laporan dari peer reviewer, serta viva singkat 2–3 menit di mana mahasiswa diminta
menjelaskan dan memperagakan ulang pekerjaannya. Ketidakmampuan memperagakan ulang adalah petunjuk
kuat bahwa itu bukan hasil kerja sendiri.

## 2.4a Pemeriksaan kesamaan kode

Kode remediasi (CB3), workflow CI/CD, dan laporan bisa saja mirip, jadi dosen menjalankan alat
pendeteksi kesamaan secara berkala. Alat ini membandingkan struktur kode, bukan sekadar teksnya,
sehingga sekadar mengganti nama variabel atau merapikan format tetap terdeteksi.

Tiga pilihan alat yang mendukung banyak bahasa (JS/TS, Python, Java, dan lainnya):

| Alat | Sifat | Menjalankan |
|---|---|---|
| Dolos (KU Leuven) | modern, laporan visual, berbasis tree-sitter | `npx @dodona/dolos run -f web app/**/*.js` |
| JPlag | matang, laporan interaktif, banyak bahasa | `java -jar jplag.jar -l javascript -r report submissions/` |
| MOSS (Stanford) | klasik, lewat skrip (perlu registrasi id) | `perl moss -l javascript submissions/*/*.js` |

Langkah pemeriksaannya, dijalankan dosen dari organisasi kelas:
```bash
# 1) Kumpulkan semua repo mahasiswa ke folder submissions/
ORG=Devsecops-Filkom-2026
mkdir -p submissions
gh repo list "$ORG" --limit 500 --json name -q '.[].name' | while read -r r; do
  git clone --depth 1 "https://github.com/$ORG/$r.git" "submissions/$r"
done

# 2a) Kesamaan kode remediasi dengan Dolos
npx @dodona/dolos run -f web -l javascript submissions/*/app/**/*.js

# 2b) Alternatif dengan JPlag (laporan interaktif)
# java -jar jplag.jar -l javascript -r report -bc BASE submissions/
```

Beberapa catatan agar hasilnya akurat. Sertakan base code — template dan fork Juice Shop yang belum
diubah — lewat opsi `-bc` (JPlag) atau template (Dolos), supaya bagian boilerplate yang memang sama
tidak dihitung sebagai plagiarisme; yang dibandingkan hanya bagian yang benar-benar ditulis mahasiswa.
Untuk laporan berbentuk Markdown, jalankan alat dalam mode teks atau gunakan Turnitin. Pasangan dengan
kemiripan di atas 70–80% di luar base code perlu diperiksa manual dan diklarifikasi lewat viva.
Pemeriksaan ini bisa dijadwalkan otomatis (cron) di akhir tiap fase.

## 2.4b Sidik jari output

Cara ini menyasar berkas hasil scan (Trivy JSON, Semgrep SARIF, laporan ZAP, Gitleaks JSON). Berkas
seperti itu otomatis membawa metadata lingkungan tempat scan dijalankan, jadi kalau dua mahasiswa
menyerahkan berkas yang identik atau memuat jejak orang lain, berkas itu jelas hasil salinan.

Metadata yang berfungsi sebagai sidik jari antara lain path absolut (misalnya `/home/<username>/...`
atau `/Users/<nama>/target-src`, yang membocorkan mesin siapa), hostname dan username OS, waktu scan,
versi alat dan ruleset, serta field khas seperti `automationDetails.id` pada SARIF, `CreatedAt` dan
`ArtifactName` pada Trivy, atau waktu generate pada ZAP. Susunan dan urutan temuan yang sama persis
juga menjadi petunjuk.

Untuk memperkuat, mintalah mahasiswa menjalankan scan dari folder ber-NIM agar path ikut ter-watermark:
```bash
git clone <target> ds-<NIM>-target
docker run --rm -v "$PWD/ds-<NIM>-target:/src" aquasec/trivy fs -f json -o /src/out.json /src
# path di dalam out.json akan memuat "ds-<NIM>-target"
```

Dosen memeriksanya dengan membandingkan hash berkas dan mencari jejak identitas asing:
```bash
# a) hash semua output; hash sama antar mahasiswa berarti disalin
find submissions -name '*.sarif' -o -name 'trivy*.json' -o -name 'zap*.json' | \
  xargs -I{} sh -c 'printf "%s  " "$(sha1sum "{}" | cut -d" " -f1)"; echo "{}"' | sort

# b) cari jejak identitas di dalam output (harus memuat NIM pemilik, bukan orang lain)
grep -rEl "ds-[0-9]+|/Users/|/home/[a-z]+" submissions/*/labs/**/ | head
```
Hash yang identik antar mahasiswa, atau output yang memuat path/username orang lain (atau justru tidak
memuat NIM pemiliknya), menjadi temuan yang perlu ditindaklanjuti.

## 2.5 Konsekuensi

| Pelanggaran | Sanksi (contoh, sesuaikan aturan fakultas) |
|---|---|
| Output atau laporan identik tanpa watermark sah | Nilai artefak 0 dan diinvestigasi |
| Menyalin atau menukar deliverable | Nilai 0 untuk komponen dan dicatat |
| Tidak bisa memperagakan ulang saat viva | Nilai artefak dibatalkan, wajib viva ulang |
| Plagiarisme berulang | Diteruskan sesuai kebijakan integritas UB/FILKOM |

---

# 3) Peer Security Review

Ini bentuk kolaborasi mata kuliah, masuk komponen Aktivitas Partisipatif (5%). Tiap mahasiswa tetap
bekerja sendiri di reponya, tetapi saling meninjau repo atau pull request temannya, meniru budaya code
review keamanan di industri. Kegiatan ini sekaligus menjadi kontrol kecurangan, karena pekerjaan yang
identik akan langsung terlihat oleh reviewer. Kompetensi yang didukung adalah kolaborasi tim
(IF_CPL_KU2).

## 3.1 Penetapan reviewer

Daftar kelas diurutkan dengan indeks `i = 0..N-1`. Untuk tiap fase, reviewer ditentukan dengan offset
berbeda agar pasangannya selalu berganti:

```
reviewer_of(i, fase) = roster[(i + fase) mod N]
```

| Fase | Minggu | Yang ditinjau | Offset |
|---|---|---|---|
| P1 — Assessment | 4–7 | LK03–LK06 dan draft CB1 | +1 |
| P2 — Pipeline | 9–11 | LK07, CB2, LK08 | +2 |
| P3 — Remediasi | 12–13 | CB3, LK09 | +3 |
| P4 — Secure/Final | 14–15 | CB4, LK10 | +5 |

Dosen mengumumkan pasangan di awal tiap fase, dan reviewer harus berbeda dari fase sebelumnya.

## 3.2 Cara kerjanya

Reviewer diberi akses baca ke repo rekannya (atau rekannya membuka pull request). Reviewer lalu membuka
Issue berlabel `peer-review` atau memberi komentar baris-per-baris pada pull request. Pemilik repo
menanggapi tiap masukan: memperbaiki, menjelaskan, atau menandai tidak diperbaiki dengan alasan. Semua
jejak ini terlihat dosen dan menjadi bukti partisipasi.

## 3.3 Templat Issue

Simpan sebagai `.github/ISSUE_TEMPLATE/peer-review.md`, atau tempel manual:

```markdown
## Peer Security Review — Fase <P?>
- Reviewer : <Nama/NIM>
- Reviewee : <Nama/NIM>
- Cakupan  : <LK/CB yang ditinjau>

### Temuan / masukan (minimal 3, spesifik dan bisa ditindaklanjuti)
1. [Severity/Jenis] <deskripsi> — Lokasi: <file/laporan> — Saran: <perbaikan> — Rujukan: <OWASP/CWE>
2.
3.

### Yang sudah baik
-

### Verifikasi reproducibility
- [ ] Saya mengikuti langkah reviewee dan hasilnya dapat/tidak dapat direproduksi karena ...

### Catatan integritas
- [ ] Tidak menemukan kemiripan mencurigakan dengan pekerjaan lain
```

## 3.4 Mutu tinjauan yang diharapkan

Reviewer diharapkan memberi setidaknya tiga masukan yang spesifik (bukan sekadar "sudah bagus"),
merujuk OWASP/CWE atau praktik konkret, menyebut lokasi yang tepat, dan mencoba mereproduksi minimal
satu langkah atau temuan milik rekannya. Nadanya harus konstruktif. Bila menemukan kemiripan yang
mencurigakan, laporkan ke dosen.

## 3.5 Rubrik penilaian

| Aspek | Bobot |
|---|---|
| Mutu tinjauan yang diberikan (spesifik, bisa ditindaklanjuti, ada rujukan) | 50% |
| Tanggapan atas tinjauan yang diterima (ada tindak lanjut nyata) | 20% |
| Konsistensi partisipasi (semua fase dan diskusi kelas) | 20% |
| Presensi | 10% |

Reviewer yang hanya menulis "bagus" atau "lgtm" tanpa isi tidak mendapat nilai penuh.

## 3.6 Kegiatan kelas pendukung

Pada Minggu 2 diadakan lokakarya threat modeling: mahasiswa berdiskusi dalam kelompok sementara membahas
satu kasus, tetapi tiap orang tetap menyerahkan model ancaman versinya sendiri. Pada Minggu 7 dan 13
ada diskusi temuan berupa presentasi kilat tiga menit. Dengan pola ini, kolaborasi terjadi pada proses
dan umpan balik, bukan pada berbagi deliverable.

---

# 4) Rubrik Penilaian

Rubrik ini menggantikan tabel ringkas di tiap file LK/CB. Perubahan utamanya: bobot digeser dari output
scan mentah ke pemahaman (refleksi, analisis, demo/viva), sehingga menyalin file tidak lagi
menguntungkan.

## 4.1 Untuk Lembar Kerja (LK01–LK10), komponen Tugas

| Aspek | Bobot | Catatan |
|---|---|---|
| Refleksi dan pemahaman (150–300 kata, kata sendiri) | 30% | menjelaskan apa dan mengapa, bukan menempel output |
| Kebenaran teknis dan bukti (reproducible, ber-watermark NIM) | 30% | hasil benar dan langkah dapat diulang; output mentah hanya pendukung |
| Demo/viva (bisa diminta sewaktu-waktu) | 20% | mampu menjelaskan dan mereproduksi langsung |
| Dokumentasi dan pemetaan OWASP | 15% | kejelasan dan ketepatan kategori |
| Kerapian repo dan commit bertahap | 5% | progres commit wajar |

Output scan yang identik antar mahasiswa tidak menambah nilai dan memicu pemeriksaan integritas.

## 4.2 Untuk Milestone Proyek (CB1–CB4), komponen Hasil Proyek / UTS / UAS

| Aspek | Bobot | Catatan |
|---|---|---|
| Analisis dan keputusan risiko (kata sendiri) | 25% | risk scoring, prioritas, justifikasi |
| Efektivitas teknis (assessment/remediasi/pipeline), terukur sebelum-sesudah | 30% | bukti nyata dari pipeline dan scan |
| Demo/viva dan mempertahankan hasil | 25% | presentasi dan tanya jawab; reproduksi langsung |
| Dokumentasi (laporan, risk register, SBOM, IR) | 10% | kelengkapan dan kualitas |
| Kolaborasi (Peer Review dua arah) | 10% | lihat bagian 3 |

## 4.3 Yang wajib ada di semua tugas

Tiap tugas harus dilengkapi `project/IDENTITY.md` sesuai bagian 1, watermark `ds-<NIM>` pada akun uji,
payload, dan footer laporan, refleksi di tiap LK/CB, screencast untuk LK06, LK07/CB2, CB3, dan CB4,
serta commit yang bertahap. Ketiadaan komponen wajib ini mengurangi nilai atau membatalkan keabsahan
artefak.

## 4.4 Kaitan dengan bobot mata kuliah

| Komponen SIM OBE | Bobot | Rubrik |
|---|---|---|
| Aktivitas Partisipatif | 5% | bagian 3.5 |
| Tugas (LK01–LK10) | 20% | bagian 4.1 |
| Hasil Proyek (CB1–CB4) | 40% | bagian 4.2 |
| Quiz | 10% | kuis konsep di kelas |
| UTS (CB1) | 12,5% | bagian 4.2 dan presentasi |
| UAS (CB4) | 12,5% | bagian 4.2 dan demo |

Bobot komponen SIM OBE mengikuti RPS. Rubrik 4.1 dan 4.2 mengatur cara menilai di dalam tiap komponen
agar menekankan pemahaman dan keaslian.

---

# 5) Alur Evaluasi

Langkah menilai tiap LK/CB memadukan tiga hal: bukti objektif dari pipeline, pemahaman lewat refleksi
dan viva, serta keaslian lewat pemeriksaan kesamaan dan sidik jari.

| Langkah | Yang dilakukan | Rujukan |
|---|---|---|
| 1 | Buka repo mahasiswa (private di organisasi; dosen owner, akses otomatis) | GitHub / `gh` |
| 2 | Cek `IDENTITY.md`, pastikan fokus OWASP sesuai formula NIM | bagian 1.1–1.2 |
| 3 | Cek kelengkapan luaran dan watermark `ds-<NIM>` pada bukti | bagian 1.4 |
| 4 | Cek pipeline (tab Actions): run lolos? security gate berjalan? | bagian 3, 4 |
| 5 | Baca refleksi dan tonton screencast | bagian 2.3 |
| 6 | Beri nilai dengan rubrik 4.1 (LK) atau 4.2 (CB) | bagian 4 |
| 7 | Cek keaslian: kesamaan kode (2.4a), sidik jari output (2.4b), riwayat commit, fork network | bagian 2.4 |
| 8 | Viva singkat acak: jelaskan dan reproduksi langsung | bagian 2.4 |
| 9 | Rekap ke SIM OBE: LK ke Tugas, CB ke Hasil Proyek, CB1 ke UTS, CB4 ke UAS, peer review ke Partisipatif | bagian 4.4 |

Sebagian langkah bisa dibantu otomasi: memeriksa kelengkapan berkas lewat autograding sederhana di CI,
menarik status pipeline massal dengan `gh run list -R <org>/<repo> --json conclusion`, serta
menjadwalkan pemeriksaan kesamaan dan sidik jari. Meski begitu, angka objektif hanya penyaring awal;
nilai akhir tetap ditentukan dosen lewat rubrik, refleksi, dan viva, dengan flag keaslian sebagai
pemicu pemeriksaan lebih lanjut.

Contoh mengecek status pipeline seluruh kelas:
```bash
ORG=Devsecops-Filkom-2026
gh repo list "$ORG" --limit 500 --json name -q '.[].name' | while read -r r; do
  st=$(gh run list -R "$ORG/$r" -L 1 --json conclusion -q '.[0].conclusion' 2>/dev/null)
  printf "%-28s %s\n" "$r" "${st:-<belum ada run>}"
done
```
