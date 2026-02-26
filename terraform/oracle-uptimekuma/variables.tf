variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
}

variable "fingerprint" {
  description = "API signing key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API signing private key"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "Compartment OCID where resources will be created"
  type        = string
}

variable "availability_domain_index" {
  description = "Availability domain index (0-based)"
  type        = number
  default     = 0
}

variable "ssh_public_key" {
  description = "SSH public key content for instance access"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the instance (Ubuntu images typically use 'ubuntu')"
  type        = string
  default     = "ubuntu"
}

variable "instance_display_name" {
  description = "Display name for the compute instance"
  type        = string
  default     = "uptimekuma-oracle"
}

variable "hostname_label" {
  description = "Hostname label for the instance"
  type        = string
  default     = "uptimekuma"
}

variable "shape" {
  description = "Instance shape (Always Free: VM.Standard.E2.1.Micro or VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "flex_shape" {
  description = "Set true when using a flexible shape like VM.Standard.A1.Flex"
  type        = bool
  default     = false
}

variable "flex_ocpus" {
  description = "OCPU count for flexible shapes"
  type        = number
  default     = 1
}

variable "flex_memory_gbs" {
  description = "Memory in GB for flexible shapes"
  type        = number
  default     = 6
}

variable "image_ocid" {
  description = "Image OCID for the instance (use an Ubuntu image for easiest Docker setup)"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Freeform tags for OCI resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Homelab-Monitoring"
    ManagedBy   = "OpenTofu"
    Owner       = "Matt"
  }
}
