# ---------------------------------------------------------------------------
# Zone
# ---------------------------------------------------------------------------
output "zone_name" {
  description = "The Cloudflare zone name"
  value       = data.cloudflare_zone.tehmatt.name
}

# ---------------------------------------------------------------------------
# A Records
# ---------------------------------------------------------------------------
output "a_records" {
  description = "Created A records"
  value = {
    for k, v in cloudflare_record.a : k => {
      fqdn    = v.hostname
      content = v.content
      proxied = v.proxied
    }
  }
}

# ---------------------------------------------------------------------------
# CNAME Records
# ---------------------------------------------------------------------------
output "cname_records" {
  description = "Created CNAME records"
  value = {
    for k, v in cloudflare_record.cname : k => {
      fqdn    = v.hostname
      content = v.content
      proxied = v.proxied
    }
  }
}

# ---------------------------------------------------------------------------
# TXT Records
# ---------------------------------------------------------------------------
output "txt_records" {
  description = "Created TXT records"
  value = [
    for v in cloudflare_record.txt : {
      fqdn    = v.hostname
      content = v.content
    }
  ]
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
output "total_records" {
  description = "Total number of DNS records managed by Terraform"
  value       = length(cloudflare_record.a) + length(cloudflare_record.cname) + length(cloudflare_record.txt)
}
