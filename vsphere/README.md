# packer-vsphere-templates

Build VMs in [VMware vSphere][] using [Packer][].

## Pre-requisites
You will need to ensure you have the appropriate 'vsphere-iso' builder for your platform. Download it here:

```sh
wget https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v2.3/packer-builder-vsphere-iso.<linux|macos>
chmod +x packer-builder-vsphere-iso.<linux|macos>
```

## Usage

```sh
packer build -var-file=./var-files/vsphere.json centos/centos-76-base-vsphere.json
```

Ensure that `vsphere.json` contains valid values.

Example `vsphere.json`

```json
{
    "vcenter_username": "administrator@vsphere.local",
    "vcenter_password": "password"
    "vcenter_server": "vcenter.example.com",
    "datacenter": "dc01",
    "cluster": "cluster01",
    "host": "host01",
    "datastore": "ds01",
    "network": "VM_Network",
    "resource_pool": "pool01"
}
```

## Dependencies

This setup uses a Packer Community Plugin ([packer-builder-vsphere](https://github.com/jetbrains-infra/packer-builder-vsphere)) for interacting with the vSphere API. This plugin requires vSphere >= 6.5

[Packer]: https://packer.io
[VMware vSphere]: http://www.vmware.com/products/vsphere-hypervisor.html
