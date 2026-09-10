# DevSecOps — Repo Tugas Mahasiswa

Template repositori untuk mata kuliah DevSecOps (CIF60038). Repo ini di-provision menjadi
`devsecops-<nim>` (private) untuk tiap mahasiswa, di dalam organisasi
[Devsecops-Filkom-2026](https://github.com/Devsecops-Filkom-2026). Kerjakan semua hands-on di sini,
commit secara bertahap, lalu push. Dosen menilai langsung dari repo ini, termasuk jalannya pipeline
CI/CD dan bukti shift-left.

Panduan lengkap dan aturannya ada di berkas mata kuliah: kumpulan panduan hands-on (LK01–LK10 dan
CB1–CB4) serta KEBIJAKAN.md (pembagian fokus per-NIM, integritas, peer review, dan rubrik). Baca itu
lebih dulu.

## Langkah pertama (Minggu 1)

1. Isi [`project/IDENTITY.md`](project/IDENTITY.md): NIM, watermark `ds-<NIM>`, dan fokus OWASP
   (formula ada di KEBIJAKAN §1).
2. Jalankan aplikasi target dengan `docker compose up -d`, lalu buka http://localhost:3000.
3. Commit dan push. Lihat tab Actions; workflow `validate` akan mengecek kelengkapan repo Anda.

## Struktur

```
.
├── project/IDENTITY.md               # identitas, fokus OWASP, watermark
├── docker-compose.yml                # menjalankan aplikasi target (Juice Shop)
├── .env.example                      # contoh variabel (jangan commit .env asli)
├── labs/                             # satu folder per LK (pakai _TEMPLATE_LK.md)
├── project/                          # luaran proyek: VA, risk register, SBOM, IR runbook
├── app/                              # (fase remediasi) fork aplikasi yang Anda perbaiki
├── scripts/                          # skrip bantu scan lokal dan validasi
├── .zap/rules.tsv                    # aturan alert ZAP
└── .github/
    ├── workflows/                    # ci, security, dast, validate
    └── ISSUE_TEMPLATE/peer-review.md
```

## Pipeline (GitHub Actions)

| Workflow | Kapan | Fungsi | LK/CB |
|---|---|---|---|
| `validate.yml` | tiap push | cek kelengkapan repo dan watermark | — |
| `ci.yml` | push/PR | build dan smoke test | LK07 |
| `security.yml` | push/PR | SAST, SCA, secret (gate) | CB2 |
| `dast.yml` | PR / manual | ZAP baseline (aplikasi ephemeral) | LK08 |

Untuk menampilkan badge status, ganti `<nim>` pada tautan berikut lalu tempel di bagian atas README:
```
![CI](https://github.com/Devsecops-Filkom-2026/devsecops-<nim>/actions/workflows/ci.yml/badge.svg)
![Security](https://github.com/Devsecops-Filkom-2026/devsecops-<nim>/actions/workflows/security.yml/badge.svg)
```

## Scan lokal (opsional, lewat Docker)

```bash
bash scripts/scan-local.sh <NIM>   # menjalankan trivy, gitleaks, dan semgrep; output ke labs/
```

## Aturan penting

Repo harus tetap private, dan jangan pernah meng-commit secret (pakai `.env`, yang sudah masuk
`.gitignore`). Semua bukti wajib memuat watermark `ds-<NIM>` di akun uji, payload, dan footer laporan.
Commit dibuat bertahap, bukan satu unggahan besar, dan sertakan refleksi serta screencast sesuai
kebijakan.
