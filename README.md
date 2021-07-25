# mehlj-packer

Lab infrastructure - hosts Packer HCL2 and supporting kickstart files for provisioning Kubernetes hosts.

## Before Building
Make sure your AWS credentials are configured on the system running Packer before building. Secrets are stored in AWS Secrets Manager.

This can usually be done with `aws configure`.

## Building
```
$ packer build -force centos-vsphere.pkr.hcl
```
