# Define variables
variable "location" {
  description = "Azure region for the resources"
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "gfakxrg"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  default     = "gfakxacr"
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  default     = "gfakxaks"
}

variable "dns_prefix" {
  description = "DNS prefix for AKS cluster"
  default     = "gfakxaks"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  default     = "Standard"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for the AKS nodes"
  default     = "Standard_A2_v2"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create ACR
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

# Create ACR pull for AKS - Role Assignment
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
