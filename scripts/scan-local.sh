#!/usr/bin/env bash
# Menjalankan basic scan lokal (SCA + secret + SAST) via Docker, output ke labs/_scan-local/.
# Pakai folder ber-NIM agar path ikut ter-watermark (lihat KEBIJAKAN §2.4b).
set -uo pipefail

NIM="${1:-}"
if [ -z "$NIM" ]; then
  echo "Pakai: bash scripts/scan-local.sh <NIM> [target-dir]"; exit 1
fi
TARGET="${2:-.}"
OUT="labs/_scan-local"
mkdir -p "$OUT"

echo "== Trivy (SCA) =="
docker run --rm -v "$PWD/$TARGET:/src" aquasec/trivy fs --scanners vuln \
  --severity HIGH,CRITICAL --format json -o /src/trivy-fs.json /src || true
mv "$TARGET/trivy-fs.json" "$OUT/trivy-fs-ds-$NIM.json" 2>/dev/null || true

echo "== Gitleaks (secret) =="
docker run --rm -v "$PWD/$TARGET:/repo" zricethezav/gitleaks:latest \
  detect --source=/repo --no-git --report-format json \
  --report-path=/repo/gitleaks.json --redact || true
mv "$TARGET/gitleaks.json" "$OUT/gitleaks-ds-$NIM.json" 2>/dev/null || true

echo "== Semgrep (SAST) =="
docker run --rm -v "$PWD/$TARGET:/src" -w /src semgrep/semgrep \
  semgrep --config p/owasp-top-ten --sarif -o /src/semgrep.sarif || true
mv "$TARGET/semgrep.sarif" "$OUT/semgrep-ds-$NIM.sarif" 2>/dev/null || true

echo "Selesai. Output di $OUT/ (ber-watermark ds-$NIM)."
