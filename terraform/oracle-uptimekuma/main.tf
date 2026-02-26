terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_vcn" "uptimekuma" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "uptimekuma-vcn"
  dns_label      = "uptimekuma"

  freeform_tags = var.tags
}

resource "oci_core_internet_gateway" "uptimekuma" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.uptimekuma.id
  display_name   = "uptimekuma-igw"

  freeform_tags = var.tags
}

resource "oci_core_route_table" "uptimekuma" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.uptimekuma.id
  display_name   = "uptimekuma-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.uptimekuma.id
  }

  freeform_tags = var.tags
}

resource "oci_core_security_list" "uptimekuma" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.uptimekuma.id
  display_name   = "uptimekuma-sl"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 3001
      max = 3001
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  freeform_tags = var.tags
}

resource "oci_core_subnet" "uptimekuma" {
  cidr_block        = var.subnet_cidr
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.uptimekuma.id
  display_name      = "uptimekuma-subnet"
  dns_label         = "uptimesub"
  route_table_id    = oci_core_route_table.uptimekuma.id
  security_list_ids = [oci_core_security_list.uptimekuma.id]

  prohibit_public_ip_on_vnic = false

  freeform_tags = var.tags
}

resource "oci_core_instance" "uptimekuma" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_display_name
  shape               = var.shape

  dynamic "shape_config" {
    for_each = var.flex_shape ? [1] : []
    content {
      ocpus         = var.flex_ocpus
      memory_in_gbs = var.flex_memory_gbs
    }
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.uptimekuma.id
    hostname_label   = var.hostname_label
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = var.tags
}

data "oci_core_vnic_attachments" "uptimekuma" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.uptimekuma.id
}

data "oci_core_vnic" "uptimekuma" {
  vnic_id = data.oci_core_vnic_attachments.uptimekuma.vnic_attachments[0].vnic_id
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../ansible/uptimekuma-oracle/inventory.ini"
  content  = <<-EOT
  [uptimekuma_oracle]
  ${data.oci_core_vnic.uptimekuma.public_ip_address} ansible_user=${var.ssh_user}
  EOT

  file_permission = "0644"
}
