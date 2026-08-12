terraform {
    backend "gcs" {
        bucket = "kubernetes-securityz"
        prefix = "kubeadm"
        credentials = "C:\\Users\\hansj\\Downloads\\kubernetes-security.json"
    }
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "5.42.0"
        }
        random = {
            source = "hashicorp/google"
            version = "3.6.3"
        }
    }
}

provider "google" {
    project = var.gcp_project
    credentials = file(var.key_path)
    zone = var.project_zone
}

provider "google-beta" {
    project = var.gcp_project
    credentials = file(var.key_path)
    zone = var.project_zone
}

resource "google_compute_network" "kubeadm_network" {
    name = "kubeadm-network"
    description = "VPC managed by Terraform"
    project = var.gcp_project
    auto_create_subnetworks = false
    network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

resource "google_compute_subnetwork" "kubeadm_subnetwork" {
    name = "kubeadm-subnetwork"
    network = google_compute_network.kubeadm_network.name
    ip_cidr_range = "10.10.0.0/16"
    stack_type = "IPV4_ONLY"
    region = var.region
}

resource "google_service_account" "service_account" {
    count = length(var.instances_names)
    account_id = var.instances_names[count.index]
    display_name = var.instances_names[count.index]
}

resource "google_compute_address" "address" {
    count = length(var.instances_names)
    name = var.instances_names[count.index]
    address_type = "EXTERNAL"
    region = var.region
}

resource "google_compute_global_address" "global_address" {
    provider = google-beta
    name = "kubeadm-private-ip"
    purpose = "VPC_PEERING"
    address_type = "INTERNAL"
    prefix_length = 16
    network = google_compute_network.kubeadm_network.id
    address = "10.230.0.0"
}

resource "google_service_networking_connection" "connection" {
    provider = google-beta
    network = google_compute_network.kubeadm_network.id
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.global_address.name]
}

resource "random_password" "password" {
    length = 15
    min_lower = 5
    min_upper = 5
    min_numeric = 5
}

resource "google_sql_database_instance" "postgres" {
    depends_on = [ google_service_networking_connection.connection ]
    provider = google-beta
    name = "kubeadm-sql"
    project = var.gcp_project
    region = var.region
    database_version = "POSTGRES_15"
    root_password = random_password.password.result
    deletion_protection = false 

    settings {
        deletion_protection_enabled = false
        tier = "db-n1-standard-1"
        activation_policy = "ALWAYS"
        availability_type = "REGIONAL"
        disk_size = 15
        disk_autoresize = false
        disk_type = "PD_SSD"

        backup_configuration {
          enabled = true
          start_time = "06:00"
          location = var.region
        }

        ip_configuration {
          ipv4_enabled = false
          private_network = google_compute_network.kubeadm_network.id
          enable_private_path_for_google_cloud_services = true
        }
        maintenance_window {
          day = 7
          hour = 23
        }
    }
}

resource "google_compute_instance" "instance" {
    depends_on = [ google_sql_database_instance.postgres ]
    count = length(var.instances_names)
    name = var.instances_names[count.index]
    machine_type = "e2-standard-2"
    zone = "us-central1-a"

    tags = [ "kubeadm-vm" ]
    metadata = {
        ssh-keys = "hansj:${file(var.ssh_path)}"
    }

    network_interface {
        network = google_compute_network.kubeadm_network.name
        subnetwork = google_compute_subnetwork.kubeadm_subnetwork.name
        access_config {
            nat_ip = google_compute_address.address[count.index].address
        }
    }

    metadata_startup_script = var.instances_names[count.index] == "webhook-server" ? file("..\\setups\\setup_webhook.sh") : ( var.instances_names[count.index] == "my-machine" ? file("..\\setups\\setup_machine.sh") : ( var.instances_names[count.index] == "control-plane" ? file("..\\setups\\setup_master.sh") : ( var.instances_names[count.index] == "worker-node" ? file("..\\setups\\setup_node.sh") : "echo 'nothing'" )))

    service_account {
      email = google_service_account.service_account[count.index].email
      scopes = [ "https://www.googleapis.com/auth/cloud-platform" ]
    }
    allow_stopping_for_update = true
    boot_disk {
        auto_delete = true
        mode = "READ_WRITE"
        initialize_params {
          image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }
}

resource "google_compute_firewall" "firewall" {
    for_each = { for firewall in var.firewall_object : firewall.name => firewall }
    name = each.value.name
    direction = each.value.direction
    network = google_compute_network.kubeadm_network.name
    priority = each.value.priority

    allow {
        protocol = each.value.protocol
        ports = each.value.ports
    }
    
    source_ranges = each.value.source_ranges
    target_tags = each.value.target_tags
}