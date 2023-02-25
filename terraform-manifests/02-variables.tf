# Define Input Variables
# 1. Azure Location (CentralUS)
# 2. Azure Resource Group Name 
# 3. Azure AKS Environment Name (Dev, QA, Prod)

# Azure aks Location
variable "location" {
  type = string
  description = "Azure Region where all these resources will be provisioned"
  default = "Central US"
}

#Azure rg group name prefix

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
# Azure Appgw Location
variable "resource_group_location" {
  default     = "Central US"
  description = "Location of the appgw resource group."
}

# Azure Appgw network name
variable "virtual_network_name" {
  description = "Virtual network name"
  default     = "aksVirtualNetwork"
}

# Azure aks network address
variable "virtual_network_address_prefix" {
  description = "VNET address prefix"
  default     = "192.168.0.0/16"
}

# Azure aks subnet name
variable "aks_subnet_name" {
  description = "Subnet Name."
  default     = "kubesubnet"
}

# Azure aks subnet prefix
variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "192.168.0.0/24"
}
# Azure App gateway subnet prefix
variable "app_gateway_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "192.168.1.0/24"
}

# Azure Appgw tags
variable "tags" {
  type = map(string)

  default = {
    source = "terraform"
  }
}
#Azure Appgw name
variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  default     = "ApplicationGateway1"
}

#Azure Appgw sku
variable "app_gateway_sku" {
  description = "Name of the Application Gateway SKU"
  default     = "Standard_v2"
}

# Azure Appgw tier
variable "app_gateway_tier" {
  description = "Tier of the Application Gateway tier"
  default     = "Standard_v2"
}

# Azure Appgw service principal ID
variable "aks_service_principal_app_id" {
  description = "Application ID/Client ID  of the service principal. Used by AKS to manage AKS related resources on Azure like vms, subnets."
}
# Azure Appgw service Clinet secret
variable "aks_service_principal_client_secret" {
  description = "Secret of the service principal. Used by AKS to manage Azure."
}

# Azure Appgw service principal object ID
variable "aks_service_principal_object_id" {
  description = "Object ID of the service principal."
}
# Azure Resource Group Name
variable "resource_group_name" {
  type = string
  description = "This variable defines the Resource Group"
  default = "terraform-aks"
}

# Azure AKS Environment Name
variable "environment" {
  type = string  
  description = "This variable defines the Environment"  
  default = "dev2"
}


# AKS Input Variables

# SSH Public Key for Linux VMs
variable "ssh_public_key" {
  default = "~/.ssh/id_ed25519.pub"
  description = "This variable defines the SSH Public Key for Linux k8s Worker nodes"  
}

# Windows Admin Username for k8s worker nodes
variable "windows_admin_username" {
  type = string
  default = "azureuser"
  description = "This variable defines the Windows admin username k8s Worker nodes"  
}

# Windows Admin Password for k8s worker nodes
variable "windows_admin_password" {
  type = string
  default = "P@ssw0rd1234"
  description = "This variable defines the Windows admin password k8s Worker nodes"  
}

