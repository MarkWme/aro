# DNS Server

## Overview

Deploys an Ubuntu virtual machine and configures a Bind DNS server instance.

The deployment script attempts to choose a random name for the services to be deployed and to create a new virtual network in the 10.x.0.0/16 CIDR range.

The script deploys a virtual network and subnet for the DNS server to be deployed to.

We assign the DNS server VM a static private IP address of 10.x.0.250 so that we know where to find it and which values to use when configuring the DNS server zone files etc.

A cloud init script is used to update packages, install Bind and copy the relevant configuration files to the correct locations. When finished, the cloud init script initiates a restart of the server with a one minute delay. The delay is in place as we have to change the virtual network configuration *after* the server has been deployed. If we configure custom DNS when the virtual network is first deployed, then once the DNS server VM is deployed it tries to use itself as a DNS server and can't because Bind is yet to be installed, and Bind cannot be installed because the Ubuntu package manager can't resolve any DNS names. So, we initally configure Azure DNS, allow the DNS server to be deployed and to configure itself, then change the virtual network custom DNS configuration to point to the newly deployed server. The server then reboots and picks up the custom DNS configuration.

## Pre-requisites

### Key Vault

A Key Vault containing the following secrets is required

Secret name | Expected value
--- | ---
adminUser | Name of the admin user to create
sshKey | SSH public key to be associated with the admin user

### DNS Zone

The script just needs to know the FQDN of the private DNS zone that will be created - i.e. private.example.com. The script will then handle creation of the appropriate DNS configuration.

## Deployment

Change to the `dns-server` folder.
Run `./deploy.sh`