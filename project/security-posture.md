# Security Posture (Before → After) — <Target App>

> Luaran CB4 (→ UAS). Ringkas perubahan postur keamanan. Watermark: ds-<NIM>.

## Ringkasan before → after
| Metrik | Sebelum | Sesudah |
|---|---|---|
| Temuan CRITICAL/HIGH | <n> | <n> |
| Temuan injection (A03) | <n> | <n> |
| Secret ter-hardcode | <n> | 0 |
| Container non-root | tidak | ya |
| Security gate aktif | tidak | ya |

**Remediation Rate** = temuan tertutup / total prioritas = <…%>

## Kontrol yang diterapkan
- [ ] Secure coding (parameterized query, output encoding, authz)
- [ ] Hardening container (multi-stage, non-root, image scan gate)
- [ ] Secret management (env/secrets, tak ada hardcode)
- [ ] Security gate SAST/SCA/secret/DAST di pipeline
- [ ] Logging/monitoring + IR runbook

## Sisa risiko (accepted/mitigated)
<daftar temuan yang belum ditutup + alasan keputusan>

## Bukti
- Pipeline hijau end-to-end: <tautan Actions>
- SBOM: [`sbom.cdx.json`](sbom.cdx.json)

---
*Dikerjakan oleh <Nama> (<NIM>) — WM ds-<NIM>*
