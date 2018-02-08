variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {}

data "oci_identity_availability_domains" "ADs" {
    compartment_id = "${var.tenancy_ocid}"
}

variable "InstanceShape" {
    default = "VM.Standard1.2"
}

variable "InstanceImageOCID" {
    type = "map"
    default = {
        // Oracle-provided image "Oracle-Linux-7.4-2017.12.18-0"
        // See https://docs.us-phoenix-1.oraclecloud.com/Content/Resources/Assets/OracleProvidedImageOCIDs.pdf
        us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaasc56hnpnx7swoyd2fw5gyvbn3kcdmqc2guiiuvnztl2erth62xnq"
        us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaaxrqeombwty6jyqgk3fraczdd63bv66xgfsqka4ktr7c57awr3p5a"
        eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaayxmzu6n5hsntq4wlffpb4h6qh6z3uskpbm5v3v4egqlqvwicfbyq"
    }
}

########################################
#        PROVIDER
########################################

provider "oci" {
  tenancy_ocid = "${var.tenancy_ocid}"
  user_ocid = "${var.user_ocid}"
  fingerprint = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  region = "${var.region}"
   disable_auto_retries = "true"
}


########################################
#        NETWORK
########################################
resource "oci_core_virtual_network" "vcn1" {
  cidr_block = "10.0.0.0/16"
  dns_label = "holvcn"
  compartment_id = "${var.compartment_ocid}"
  display_name = "holvcn"
}

resource "oci_core_internet_gateway" "internetgateway1" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "ig01"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
}

resource "oci_core_route_table" "csr-rt" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
    display_name = "csr-rt"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.internetgateway1.id}"
    }
}

resource "oci_core_security_list" "csr-sl" {
  display_name   = "csr-sl"
  compartment_id = "${oci_core_virtual_network.vcn1.compartment_id}"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"

    egress_security_rules = [{
        protocol    = "all"
        destination = "0.0.0.0/0"
    },
    ]

    ingress_security_rules = [{
        tcp_options {
        "max" = 22
        "min" = 22
        }

        protocol = "6"
        source   = "0.0.0.0/0"
    },
    ]
}

resource "oci_core_subnet" "csr-sub" {
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
    cidr_block = "10.0.1.0/24"
    display_name = "csr-subnet"
    dns_label = "csrsub"
    security_list_ids = ["${oci_core_security_list.csr-sl.id}"]
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
    route_table_id = "${oci_core_route_table.csr-rt.id}"
    dhcp_options_id = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"

    provisioner "local-exec" {
        command = "sleep 9"
    }
}


########################################
#        COMPUTE
########################################

resource "oci_core_instance" "cloudshowrome01" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "cloudshowrome01"
  image = "${var.InstanceImageOCID[var.region]}"
  shape = "${var.InstanceShape}"
  subnet_id = "${oci_core_subnet.csr-sub.id}"
  hostname_label = "cloudshowrome01"
  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}

########################################
#        OUTPUT
########################################

output "cloudshowrome01_primary_IP_addresses" {
  value = ["${oci_core_instance.cloudshowrome01.public_ip}",
           "${oci_core_instance.cloudshowrome01.private_ip}"]
}