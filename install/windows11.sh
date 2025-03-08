#!/bin/bash

# Windows 11 VM Creation Script for Proxmox
# Inspired by https://github.com/community-scripts/ProxmoxVE

# Variables (Modify as needed)
VMID=120  # Unique VM ID
VMNAME="win11-vm"
ISO_STORAGE="isos"  # Storage ID where the ISO is stored
ISO_FILE="Win11.iso"  # Windows 11 ISO filename
VIRTIO_ISO="virtio-win.iso"  # VirtIO drivers ISO
STORAGE_TYPE="vmstore"  # Storage type
DISK_SIZE="64G"
RAM_SIZE="8192"  # 8GB RAM
CPU_CORES=4
BRIDGE="vlan10"

# Function to check if a VM ID is in use
check_vm_exists() {
  if qm status $VMID &>/dev/null; then
    echo "Error: VM ID $VMID already exists. Choose a different ID."
    exit 1
  fi
}

# Function to create VM
create_vm() {
  echo "Creating Windows 11 VM with ID $VMID..."
  qm create $VMID \
    --name $VMNAME \
    --memory $RAM_SIZE \
    --cores $CPU_CORES \
    --net0 virtio,bridge=$BRIDGE \
    --ostype win11 \
    --machine q35 \
    --bios ovmf \
    --cpu host \
    --scsihw virtio-scsi-pci
}

# Function to configure TPM and Secure Boot
configure_tpm() {
  echo "Configuring TPM and Secure Boot..."
  qm set $VMID --tpmstate0 ${STORAGE_TYPE}:32,version=v2.0
  qm set $VMID --efidisk0 ${STORAGE_TYPE}:1,format=raw,efitype=4m,pre-enrolled-keys=1
}

# Function to attach ISO files
attach_iso() {
  echo "Attaching Windows 11 and VirtIO ISO..."
  qm set $VMID --ide2 $ISO_STORAGE:iso/$ISO_FILE,media=cdrom
  qm set $VMID --ide3 $ISO_STORAGE:iso/$VIRTIO_ISO,media=cdrom
}

# Function to create and attach disk
create_disk() {
  echo "Creating and attaching disk..."
  qm set $VMID --scsi0 ${STORAGE_TYPE}:$DISK_SIZE,discard=on,ssd=1
}

# Function to set boot order
set_boot_order() {
  echo "Setting boot order to ISO..."
  qm set $VMID --boot order=ide2
}

# Function to start VM
start_vm() {
  echo "Starting Windows 11 VM..."
  qm start $VMID
}

# Main Execution
check_vm_exists
create_vm
configure_tpm
attach_iso
create_disk
set_boot_order
start_vm

echo "Windows 11 VM setup complete!"
