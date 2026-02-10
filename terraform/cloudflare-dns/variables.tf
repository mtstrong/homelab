variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions for the zone"
  type        = string
  sensitive   = true
}

variable "zone_id" {
  description = "Cloudflare Zone ID for tehmatt.com"
  type        = string
}

variable "domain" {
  description = "Root domain name"
  type        = string
  default     = "tehmatt.com"
}

variable "public_ip" {
  description = "Public IP address for A records (your WAN IP that port-forwards to Traefik)"
  type        = string
}

# ---------------------------------------------------------------------------
# DNS record definitions — edit these maps to add/remove subdomains
# ---------------------------------------------------------------------------

variable "a_records" {
  description = "Map of A record subdomains. Key = label (@ for root), value = { proxied, ttl }"
  type = map(object({
    proxied = optional(bool, true)
    ttl     = optional(number, 1) # 1 = automatic when proxied
  }))
  default = {
    "@"        = {}
    "www"      = {}
    "tinyauth" = {}
  }
}

variable "cname_records" {
  description = "Map of CNAME subdomains that point to the root domain. Key = subdomain prefix."
  type = map(object({
    proxied = optional(bool, true)
    ttl     = optional(number, 1)
  }))
  default = {
    "abs"        = {}
    "argocd"     = {}
    "calibre"    = {}
    "checkmk"    = {}
    "gitlab"     = {}
    "grafana"    = {}
    "ha"         = {}
    "hb"         = {}
    "homepage"   = {}
    "kavita"     = {}
    "leslie"     = {}
    "logs"       = {}
    "loki"       = {}
    "mattodo"    = {}
    "mealie"     = {}
    "ollama"     = {}
    "omni"       = {}
    "overseerr"  = {}
    "paperless"  = {}
    "plex"       = {}
    "prometheus" = {}
    "prowlarr"   = {}
    "qt"         = {}
    "radarr"     = {}
    "readarr"    = {}
    "request"    = {}
    "romm"       = {}
    "sab"        = {}
    "semaphore"  = {}
    "sonarr"     = {}
    "starcraft"  = {}
    "tautulli"   = {}
    "tools"      = {}
    "traefik"    = {}
    "uptime"     = {}
    "vault"      = {}
  }
}

variable "txt_records" {
  description = "List of TXT records. Each entry has name, value, ttl."
  type = list(object({
    name  = string
    value = string
    ttl   = optional(number, 120)
  }))
  default = []
}
