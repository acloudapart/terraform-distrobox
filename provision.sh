#!/usr/bin/env bash

# Set non-interactive frontend for apt to prevent interactive dialogs
export DEBIAN_FRONTEND=noninteractive

# Update package lists and install prerequisite packages
sudo apt-get update
sudo apt-get install -y software-properties-common curl gpg

# Create the directory for APT keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Download and add the HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp repository, falling back to Ubuntu 22.04 LTS (jammy) for compatibility
# This ensures stability until 24.04 (noble) is fully supported by HashiCorp's repo.
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package lists again to include the new repository
sudo apt-get update

# Install Terraform
sudo apt-get install -y terraform

# Verify the installation
echo "Terraform installation complete. Version:"
terraform -v