#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# import.sh — Import existing Cloudflare DNS records into Terraform state
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars and fill in values
#   2. Run: terraform init
#   3. Run: bash import.sh
#   4. Run: terraform plan   (should show no changes if everything matches)
# ---------------------------------------------------------------------------
set -euo pipefail

ZONE_ID="92658e3b20f15a19ca4aabe7244e6c4f"

echo "==> Importing A records..."
terraform import "cloudflare_record.a[\"@\"]"        "${ZONE_ID}/89e7ba1336f79067ad89c16d65aa5d1b"
terraform import "cloudflare_record.a[\"www\"]"       "${ZONE_ID}/0ba0f1d4b1bd6616614abfd8c8c5b795"
terraform import "cloudflare_record.a[\"tinyauth\"]"  "${ZONE_ID}/a7f937775ed8236240ee56fb23e542a7"

echo "==> Importing CNAME records..."
terraform import "cloudflare_record.cname[\"abs\"]"        "${ZONE_ID}/fc30ac0c185555a5d1a75f6e7d719561"
terraform import "cloudflare_record.cname[\"argocd\"]"     "${ZONE_ID}/8e5d749c4975e12d2c250a279131a8dc"
terraform import "cloudflare_record.cname[\"calibre\"]"    "${ZONE_ID}/030bfbd1b643f1b2c4637294991623de"
terraform import "cloudflare_record.cname[\"checkmk\"]"    "${ZONE_ID}/c0ebc4362509dee029c3947e3fb4299f"
terraform import "cloudflare_record.cname[\"gitlab\"]"     "${ZONE_ID}/05e959377bbfd7d341b216991336cf8e"
terraform import "cloudflare_record.cname[\"grafana\"]"    "${ZONE_ID}/defe719b74a9b89e39a134afc66a5aa8"
terraform import "cloudflare_record.cname[\"ha\"]"         "${ZONE_ID}/82648cbe10f8e9f15c735fa7a8339a44"
terraform import "cloudflare_record.cname[\"hb\"]"         "${ZONE_ID}/8eacf9eb4e29cf591551e8fd0306168e"
terraform import "cloudflare_record.cname[\"homepage\"]"   "${ZONE_ID}/4ed71e40428d9b7f7a0eb8e1bc34166d"
terraform import "cloudflare_record.cname[\"kavita\"]"     "${ZONE_ID}/d788f1a52ccee418a50a9e788ea66e5f"
terraform import "cloudflare_record.cname[\"leslie\"]"     "${ZONE_ID}/0f47a551525c7e071dbf8831da5a20d9"
terraform import "cloudflare_record.cname[\"logs\"]"       "${ZONE_ID}/7804fdd3e21fef5b56592cfcba1c438d"
terraform import "cloudflare_record.cname[\"loki\"]"       "${ZONE_ID}/eade6dfbbaedab326dbae21b67d0bf67"
terraform import "cloudflare_record.cname[\"mattodo\"]"    "${ZONE_ID}/07d7c01a1035b99dd44bef3c128f6828"
terraform import "cloudflare_record.cname[\"mealie\"]"     "${ZONE_ID}/4d389d0fc0b54f306a369bbd462f31d1"
terraform import "cloudflare_record.cname[\"ollama\"]"     "${ZONE_ID}/3a52843a55767807c9e5985208964525"
terraform import "cloudflare_record.cname[\"omni\"]"       "${ZONE_ID}/127d4bed5209339cfbb0b7e19f236a70"
terraform import "cloudflare_record.cname[\"overseerr\"]"  "${ZONE_ID}/615c923472752a631c2f1c09497f82f5"
terraform import "cloudflare_record.cname[\"paperless\"]"  "${ZONE_ID}/0f2a3129e98c03e06a70193306267787"
terraform import "cloudflare_record.cname[\"plex\"]"       "${ZONE_ID}/198ce74b020e9c39238e6299aa65021b"
terraform import "cloudflare_record.cname[\"prometheus\"]" "${ZONE_ID}/07af6821a75d13dceca86ef8c5aa1698"
terraform import "cloudflare_record.cname[\"prowlarr\"]"   "${ZONE_ID}/25835cebc113965d1827ba153a8bd1d4"
terraform import "cloudflare_record.cname[\"qt\"]"         "${ZONE_ID}/4ea9e73b407311faf23c039cb1f1fe7a"
terraform import "cloudflare_record.cname[\"radarr\"]"     "${ZONE_ID}/df29aab4f0c595f88ebc36102f6f0dcc"
terraform import "cloudflare_record.cname[\"readarr\"]"    "${ZONE_ID}/3e41eea1a9d4149e09556661fa25cb48"
terraform import "cloudflare_record.cname[\"request\"]"    "${ZONE_ID}/fe751df1ede6c75e45a2059ff10af563"
terraform import "cloudflare_record.cname[\"romm\"]"       "${ZONE_ID}/29f975e665ab26e5a71b32ebcfab43b0"
terraform import "cloudflare_record.cname[\"sab\"]"        "${ZONE_ID}/4f6b738c1baeac008dce1a8efe22fd2c"
terraform import "cloudflare_record.cname[\"semaphore\"]"  "${ZONE_ID}/924394ffad96c142fb9f23fc8b742788"
terraform import "cloudflare_record.cname[\"sonarr\"]"     "${ZONE_ID}/7bce334d55edbcc0775054b2b5d9edbe"
terraform import "cloudflare_record.cname[\"starcraft\"]"  "${ZONE_ID}/d70c3d1a8779fca26a49bc8e47491c8a"
terraform import "cloudflare_record.cname[\"tautulli\"]"   "${ZONE_ID}/8ebfbccc7af656f7b9a82c17bf770501"
terraform import "cloudflare_record.cname[\"tools\"]"      "${ZONE_ID}/8c4d298263298a8e587c70e229a6a340"
terraform import "cloudflare_record.cname[\"traefik\"]"    "${ZONE_ID}/9c846ac5ee119171f23b22dcb11fb6d9"
terraform import "cloudflare_record.cname[\"uptime\"]"     "${ZONE_ID}/2eed82ef4a5849996f9ca1b818d01af2"
terraform import "cloudflare_record.cname[\"vault\"]"      "${ZONE_ID}/131d3e230cb75dc98673babfb5db201d"

echo ""
echo "==> Import complete! Run 'terraform plan' to verify no drift."
