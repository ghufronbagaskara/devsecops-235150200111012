# Panduan Hands-On DevSecOps (CIF60038)

Berkas ini memuat panduan untuk pertemuan kedua tiap minggu Dosen memandu bagian awal, lalu mahasiswa merampungkan sisanya secara mandiri
sebelum pertemuan berikutnya. Semua pekerjaan berjalan di atas Docker dan diunggah ke GitHub. Penilaian dilakukan langsung dari repositori GitHub, termasuk memeriksa jalannya pipeline
CI/CD dan bukti penerapan shift-left.

Setiap mahasiswa bekerja sendiri di repositori masing-masing. Kolaborasi tetap ada, tetapi lewat Peer Security Review: mahasiswa saling meninjau repo atau pull request temannya. Bagian ini masuk ke komponen Aktivitas Partisipatif.

Sebelum mulai, baca [KEBIJAKAN.md](KEBIJAKAN.md). Di sana ada aturan pembagian fokus tugas per-NIM, integritas akademik, tata cara Peer Security Review, dan rubrik penilaian. Singkatnya: langkah praktik sama untuk semua orang, tetapi luaran sengaja dibuat berbeda tiap mahasiswa, dan penilaian menitikberatkan pemahaman — bukan sekadar file hasil.

Organization kelas: **https://github.com/Devsecops-Filkom-2026**

## Alur 16 minggu

| Fase | Minggu | Yang dikerjakan | Luaran |
|---|---|---|---|
| Setup | 1–2 | Docker, GitHub, deploy aplikasi rentan | LK01–LK02 |
| Basic scan | 3–4 | SCA, secret scanning, SAST | LK03–LK04 |
| Advanced hacking | 5–7 | DAST, eksploitasi dasar sampai lanjut | LK05–LK06, CB1 |
| UTS | 8 | Vulnerability Assessment | CB1 |
| Shift-left CI/CD | 9–11 | Pipeline, security gate, DAST di CI | LK07, CB2, LK08 |
| Remediasi & hardening | 12–13 | Perbaiki kode, hardening container | CB3, LK09 |
| Vuln management & secure | 14–15 | Risk register, SBOM, monitoring, IR | CB4, LK10 |
| UAS | 16 | Demo aplikasi secure + pipeline | CB4 (final) |

LK adalah Lembar Kerja, masuk komponen Tugas (20%). CB adalah milestone Hasil Proyek (40%); CB1 menjadi UTS dan CB4 bermuara ke UAS.

## Aplikasi yang dipakai: OWASP Juice Shop

[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) adalah aplikasi web modern (Angular dan
Node/Express) yang sengaja dibuat rentan dan mencakup OWASP Top 10. Kita memakainya untuk recon,
scanning, DAST, dan eksploitasi.

Menjalankannya cukup satu perintah:
```bash
docker run --rm -p 3000:3000 bkimminich/juice-shop
# lalu buka http://localhost:3000
```

Pada fase remediasi nanti, mahasiswa perlu mem-fork source code-nya agar bisa mengubah kode:
```bash
# fork dulu di GitHub: https://github.com/juice-shop/juice-shop
git clone https://github.com/<username-anda>/juice-shop.git
```

Satu hal yang perlu diluruskan soal target "aplikasi secure". Juice Shop memang dirancang untuk tetap rentan sebagai bahan latihan, jadi tujuan akhir bukan menambal seluruh kerentanannya. Yang dituntut adalah: memperbaiki sekitar 5–8 temuan prioritas yang Anda temukan dan dokumentasikan sendiri, melakukan hardening pada container serta pipeline, dan membangun security gate yang membuktikan temuan berkurang (bandingkan kondisi sebelum dan sesudah) dengan pipeline yang lolos. Risiko yang belum sempat ditutup cukup dicatat di risk register beserta keputusannya (diterima atau dimitigasi).

## Struktur repositori yang disarankan

```
devsecops-<nim>/
├── README.md                 # identitas, ringkasan progres, badge pipeline
├── docker-compose.yml        # menjalankan aplikasi target
├── labs/
│   ├── LK01-setup/
│   ├── LK02-recon/
│   ├── LK03-sca-secret/      # laporan + output scan (json/sarif)
│   └── ...                    # satu folder per LK
├── project/
│   ├── vulnerability-assessment.md   # CB1 (UTS)
│   ├── risk-register.csv             # CB1/CB4
│   ├── sbom.cdx.json                 # CB4
│   └── ir-runbook.md                 # LK10
├── app/                      # (fase remediasi) fork juice-shop yang Anda perbaiki
└── .github/workflows/
    ├── ci.yml                # LK07
    ├── security.yml          # CB2 (SAST/SCA/secret)
    └── dast.yml              # LK08
```

## Perkakas (semua lewat Docker)

| Tool | Fungsi | Image |
|---|---|---|
| Docker + Compose | menjalankan semuanya | — |
| Trivy | SCA & image scan | `aquasec/trivy` |
| Grype (alternatif) | SCA | `anchore/grype` |
| Gitleaks | secret scanning | `zricethezav/gitleaks` |
| Semgrep | SAST | `semgrep/semgrep` |
| OWASP ZAP | DAST | `ghcr.io/zaproxy/zaproxy:stable` |
| Syft | SBOM | `anchore/syft` |

Verifikasi lingkungan:
```bash
docker --version && docker compose version && git --version
```

## Visibility repositori: private

Repo mahasiswa harus private. Ada dua alasan. Pertama, mencegah mahasiswa saling menyalin. Kedua, menjaga etika: kode yang sengaja dibuat rentan, PoC eksploitasi, dan temuan secret tidak pantasdipublikasikan.

## Cara mengumpulkan dan menilai

1. Pada Minggu 1, buat `project/IDENTITY.md` sesuai
   [KEBIJAKAN.md §1](KEBIJAKAN.md#1-pembagian-fokus-tugas-per-nim) (NIM, fokus OWASP, watermark).
2. Kerjakan tiap LK/CB, simpan luaran di folder yang sesuai, lengkap dengan watermark `ds-<NIM>`,
   refleksi, dan screencast untuk tugas yang mewajibkannya.
3. Commit secara bertahap dan push ke repo Anda.
4. Lakukan Peer Security Review sesuai fasenya
   ([KEBIJAKAN.md §3](KEBIJAKAN.md#3-peer-security-review)).
5. Kumpulkan tautan repo dan tautan run GitHub Actions di LMS Brone.
6. Dosen menilai dari riwayat commit, kelengkapan luaran, jalannya pipeline, bukti shift-left,
   refleksi/demo, dan keaslian pekerjaan.

Rubrik penilaian ada di [KEBIJAKAN.md §4](KEBIJAKAN.md#4-rubrik-penilaian); rubrik itu menggantikan
tabel ringkas di tiap file LK/CB. Aturan integritas ada di
[KEBIJAKAN.md §2](KEBIJAKAN.md#2-integritas-akademik).

## Daftar panduan

Kebijakan (wajib dibaca) ada di [KEBIJAKAN.md](KEBIJAKAN.md): pembagian fokus per-NIM, integritas
akademik, Peer Security Review, rubrik penilaian, dan alur evaluasi.

Lembar Kerja (komponen Tugas):
- [LK01 — Setup Docker & GitHub](LK01_Setup-Docker-GitHub.md)
- [LK02 — Deploy Aplikasi Rentan & Recon](LK02_Deploy-App-Rentan-Recon.md)
- [LK03 — Basic Scan: SCA & Secret](LK03_Basic-Scan-SCA-Secret.md)
- [LK04 — SAST dengan Semgrep](LK04_SAST-Semgrep.md)
- [LK05 — DAST dengan OWASP ZAP](LK05_DAST-ZAP.md)
- [LK06 — Eksploitasi SQLi & XSS](LK06_Eksploitasi-SQLi-XSS.md)
- [LK07 — Pipeline CI/CD di GitHub Actions](LK07_Pipeline-CICD.md)
- [LK08 — DAST dalam Pipeline](LK08_DAST-Pipeline.md)
- [LK09 — Hardening Container & Secret](LK09_Hardening-Container-Secret.md)
- [LK10 — Aplikasi Secure: Monitoring & IR](LK10_Secure-App-Monitoring-IR.md)

Milestone Proyek (komponen Hasil Proyek):
- [CB1 — Vulnerability Assessment (UTS)](CB1_Vulnerability-Assessment.md)
- [CB2 — Pipeline Security Gate](CB2_Pipeline-Security-Gate.md)
- [CB3 — Remediasi (Secure Coding)](CB3_Remediasi-Secure-Coding.md)
- [CB4 — Risk Register + SBOM (menuju UAS)](CB4_RiskRegister-SBOM.md)
