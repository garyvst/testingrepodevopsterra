resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "appgwrg" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

# Locals block for hardcoded names
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.appgwnw.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.appgwnw.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.appgwnw.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.appgwnw.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.appgwnw.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.appgwnw.name}-rqrt"
  app_gateway_subnet_name        = "appgwsubnet"
}

# User Assigned Identities 
resource "azurerm_user_assigned_identity" "Identity" {
  resource_group_name = azurerm_resource_group.appgwrg.name
  location            = azurerm_resource_group.appgwrg.location

  name = "identity1"

  tags = var.tags
}

resource "azurerm_virtual_network" "appgwnw" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.appgwrg.location
  resource_group_name = azurerm_resource_group.appgwrg.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix
  }

  subnet {
    name           = "appgwsubnet"
    address_prefix = var.app_gateway_subnet_address_prefix
  }

  tags = var.tags
}

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.appgwnw.name
  resource_group_name  = azurerm_resource_group.appgwrg.name
  depends_on           = [azurerm_virtual_network.appgwnw]
}

data "azurerm_subnet" "appgwsubnet" {
  name                 = "appgwsubnet"
  virtual_network_name = azurerm_virtual_network.appgwnw.name
  resource_group_name  = azurerm_resource_group.appgwrg.name
  depends_on           = [azurerm_virtual_network.appgwnw]
}

# Public Ip 
resource "azurerm_public_ip" "pip" {
  name                = "publicIp1"
  location            = azurerm_resource_group.appgwrg.location
  resource_group_name = azurerm_resource_group.appgwrg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_application_gateway" "network" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.appgwrg.name
  location            = azurerm_resource_group.appgwrg.location

  sku {
    name     = var.app_gateway_sku
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.appgwsubnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = var.tags

  depends_on = [azurerm_virtual_network.appgwnw, azurerm_public_ip.pip]
}

resource "azurerm_role_assignment" "ra1" {
  scope                = data.azurerm_subnet.kubesubnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_service_principal_object_id

  depends_on = [azurerm_virtual_network.appgwnw]
}

resource "azurerm_role_assignment" "ra2" {
  scope                = azurerm_user_assigned_identity.Identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_service_principal_object_id
  depends_on           = [azurerm_user_assigned_identity.Identity]
}

resource "azurerm_role_assignment" "ra3" {
  scope                = azurerm_application_gateway.network.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.Identity.principal_id
  depends_on           = [azurerm_user_assigned_identity.Identity, azurerm_application_gateway.network]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = azurerm_resource_group.appgwrg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.Identity.principal_id
  depends_on           = [azurerm_user_assigned_identity.Identity, azurerm_application_gateway.network]
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  dns_prefix          = "${azurerm_resource_group.aks_rg.name}"
  location            = azurerm_resource_group.aks_rg.location
  name                = "${azurerm_resource_group.aks_rg.name}-cluster"
  resource_group_name = azurerm_resource_group.aks_rg.name
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  node_resource_group = "${azurerm_resource_group.aks_rg.name}-nrg"


  default_node_pool {
    name       = "systempool"
    vm_size    = "Standard_DS2_v2"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    os_disk_size_gb      = 30
    type           = "VirtualMachineScaleSets"
    vnet_subnet_id  = data.azurerm_subnet.kubesubnet.id
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
      "app"           = "system-apps"
    }
    tags = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
      "app"           = "system-apps"
    }    
  }

# Identity (System Assigned or Service Principal)
  identity { type = "SystemAssigned" }

# Add On Profiles
  addon_profile {
    azure_policy { enabled = true }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
    }

    ingress_application_gateway {
      enabled    = true
      gateway_id = azurerm_application_gateway.network.id
    }
  }

# RBAC and Azure AD Integration Block
role_based_access_control {
  enabled = true
  azure_active_directory {
    managed                = true
    admin_group_object_ids = [azuread_group.aks_administrators.id]
  }
}  

 #role_based_access_control {
    #enabled = true
        #azure_active_directory {
           # server_app_id     = "${var.rbac_server_app_id}"
           # server_app_secret = "${var.rbac_server_app_secret}"
            #client_app_id     = "${var.rbac_client_app_id}"
            #tenant_id         = "${var.tenant_id}"
        #}
    #}
    # https://github.com/PixelRobots/terraform-aks-rbac-azure-ad/blob/master/Terraform/main.tf
# Windows Admin Profile
windows_profile {
  admin_username            = var.windows_admin_username
  admin_password            = var.windows_admin_password
}

# Linux Profile
linux_profile {
  admin_username = "ubuntu"
  ssh_key {
      key_data = file(var.ssh_public_key)
  }
}

# Network Profile
network_profile {
  load_balancer_sku = "Standard"
  network_plugin = "azure"
}

# AKS Cluster Tags 
tags = {
  Environment = var.environment
}

depends_on = [azurerm_virtual_network.appgwnw, azurerm_application_gateway.network]
  
}