#!/usr/bin/env bash
# Validasi kelengkapan repo mahasiswa. Exit != 0 bila ada yang belum lengkap.
set -uo pipefail
fail=0
ok(){ printf "  ✅ %s\n" "$1"; }
bad(){ printf "  ❌ %s\n" "$1"; fail=1; }

echo "== Struktur =="
for p in docker-compose.yml project/IDENTITY.md .github/workflows/ci.yml \
         .github/workflows/security.yml labs project; do
  [ -e "$p" ] && ok "ada: $p" || bad "hilang: $p"
done

echo "== IDENTITY.md =="
ID=project/IDENTITY.md
if [ -f "$ID" ]; then
  grep -q "<NIM>" "$ID"   && bad "IDENTITY masih memuat placeholder <NIM> — belum diisi" || ok "placeholder NIM sudah diganti"
  grep -q "<Nama" "$ID"   && bad "IDENTITY masih memuat placeholder <Nama>" || ok "nama sudah diisi"
  grep -Eq "ds-[0-9]{3,}" "$ID" && ok "watermark ds-<NIM> terisi" || bad "watermark ds-<NIM> belum valid (harus ds-<angka NIM>)"
  grep -Eq "OWASP Primary\s*:\s*A0[1-9]|A10" "$ID" && ok "OWASP Primary terisi" || bad "OWASP Primary belum diisi (A01..A10)"
else
  bad "project/IDENTITY.md tidak ada"
fi

echo "== Kebersihan (tidak ada .env asli / secret) =="
if git ls-files --error-unmatch .env >/dev/null 2>&1; then bad ".env ter-commit — hapus & rotasi secret!"; else ok ".env tidak ter-commit"; fi

echo
if [ "$fail" -eq 0 ]; then
  echo "SEMUA LENGKAP ✅"
else
  echo "MASIH ADA YANG PERLU DILENGKAPI ❌ (lihat tanda ❌ di atas)"
fi
exit "$fail"
