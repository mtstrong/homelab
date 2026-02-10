provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ----------------------------------------------------------
# Zone data source — validates the zone ID is correct
# ----------------------------------------------------------
data "cloudflare_zone" "tehmatt" {
  zone_id = var.zone_id
}

# ----------------------------------------------------------
# A records  (root, www, tinyauth → public IP)
# ----------------------------------------------------------
resource "cloudflare_record" "a" {
  for_each = var.a_records

  zone_id = var.zone_id
  name    = each.key == "@" ? var.domain : each.key
  type    = "A"
  content = var.public_ip
  ttl     = each.value.proxied ? 1 : each.value.ttl
  proxied = each.value.proxied
}

# ----------------------------------------------------------
# CNAME records  (subdomains → root domain)
# ----------------------------------------------------------
resource "cloudflare_record" "cname" {
  for_each = var.cname_records

  zone_id = var.zone_id
  name    = each.key
  type    = "CNAME"
  content = var.domain
  ttl     = each.value.proxied ? 1 : each.value.ttl
  proxied = each.value.proxied
}

# ----------------------------------------------------------
# TXT records (ACME challenges, SPF, etc.)
# ----------------------------------------------------------
resource "cloudflare_record" "txt" {
  count = length(var.txt_records)

  zone_id = var.zone_id
  name    = var.txt_records[count.index].name
  type    = "TXT"
  content = var.txt_records[count.index].value
  ttl     = var.txt_records[count.index].ttl
  proxied = false
}
