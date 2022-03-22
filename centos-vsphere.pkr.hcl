variable "host" {
  type    = string
  default = "192.168.1.205"
}

variable "iso_url" {
  type    = string
  default = "[datastore1] ISOs/CentOS-8.3.2011-x86_64-dvd1.iso"
}

variable "vm-cpu-num" {
  type    = string
  default = "1"
}

variable "vm-disk-size" {
  type    = string
  default = "32768"
}

variable "vm-mem-size" {
  type    = string
  default = "2048"
}

variable "vm-name" {
  type    = string
  default = "CentOS8_Template"
}

variable "vsphere-datastore" {
  type    = string
  default = "datastore1"
}

variable "vsphere-network" {
  type    = string
  default = "DSwitch-VM Network"
}

variable "vsphere-server" {
  type    = string
  default = "192.168.1.206"
}

variable "vsphere-user" {
  type    = string
  default = "administrator@lab.io"
}

locals {
  admin-password = aws_secretsmanager("mehlj_lab_creds", "vsphere")
  ssh-password   = aws_secretsmanager("mehlj_lab_creds", "ssh")
  vault-password = aws_secretsmanager("mehlj_lab_creds", "vault")
}

source "vsphere-iso" "k8stemplate" {
  CPUs                 = "${var.vm-cpu-num}"
  RAM                  = "${var.vm-mem-size}"
  RAM_reserve_all      = false
  boot_command         = ["<tab> text ks=https://raw.githubusercontent.com/mehlj/mehlj-packer/master/ks.cfg<enter><wait>"]
  boot_order           = "disk,cdrom"
  boot_wait            = "10s"
  convert_to_template  = true
  datastore            = "${var.vsphere-datastore}"
  guest_os_type        = "centos8_64Guest"
  host                 = "${var.host}"
  insecure_connection  = "true"
  iso_paths            = ["${var.iso_url}"]
  network_adapters {
    network      = "${var.vsphere-network}"
    network_card = "vmxnet3"
  }
  notes        = "Kubernetes cluster node template. Built via Packer."
  password     = "${local.admin-password}"
  ssh_password = "${local.ssh-password}"
  ssh_username = "mehlj"
  storage {
    disk_size             = "${var.vm-disk-size}"
    disk_thin_provisioned = true
  }
  username       = "${var.vsphere-user}"
  vcenter_server = "${var.vsphere-server}"
  vm_name        = "${var.vm-name}"
}

build {
  sources = ["source.vsphere-iso.k8stemplate"]

  # stage the ansible vault pass file for later usage
  provisioner "file" {
    content         = "${local.vault-password}"
    destination     = "/root/.vault_pass.txt"
  }

  # configure SSH keys
  provisioner "ansible" {
    command         = "./ansible-wrapper.sh"
    playbook_file   = "./mehlj-ansible/playbooks/ssh.yml"
  }

  # configure kubernetes prerequisites
  provisioner "ansible" {
    command         = "./ansible-wrapper.sh"
    playbook_file   = "./mehlj-ansible/playbooks/kubernetes.yml"
    extra_arguments = ["--vault-password-file=/root/.vault_pass.txt"]
  }
}
