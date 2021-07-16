provider "azurerm" {
    version         = "=2.27.0"
    subscription_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    client_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    tenant_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
features        {}
}


#create a resource group 
resource "azurerm_resource_group" "jkterraformrg" {
    name     = "jkResourceGroup"
    location = "eastus"

    tags = {
        environement = "Terraform Demo"
    }
}

#create a virtual network
resource "azurerm_virtual_network" "jkterraformvnet" {
    name                = "jkvnet1"
    location            = azurerm_resource_group.jkterraformrg.location
    resource_group_name = azurerm_resource_group.jkterraformrg.name    
    address_space       = ["10.1.0.0/16"]
}

#create subnet
resource "azurerm_subnet" "jkterraformsubnet" {
    name                 = "subnet1"
    resource_group_name  = azurerm_resource_group.jkterraformrg.name
    virtual_network_name = azurerm_virtual_network.jkterraformvnet.name
    address_prefixes     = ["10.1.0.0/24"]

}

#create network security group
resource "azurerm_network_security_group" "jkterraformnsg" {
    name                 = "jknsg"
    location             = azurerm_resource_group.jkterraformrg.location
    resource_group_name  = azurerm_resource_group.jkterraformrg.name
#this following set to be used for 4 time, 2 inbound & 2 outbound and then try it. don't include the below old network security rile while executing. weblink at bottom
    security_rule {
        name                        = "jknsr1"
        priority                    = 100
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "3389"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "jknsr2"
        priority                    = 99
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "jknsr3"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "3389"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "jknsr4"
        priority                    = 99
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

}

#create subnetNSG_association
resource "azurerm_subnet_network_security_group_association" "jkterraformnnsga" {
  subnet_id                 = azurerm_subnet.jkterraformsubnet.id
  network_security_group_id = azurerm_network_security_group.jkterraformnsg.id
}

#create public ip
resource "azurerm_public_ip" "jkterraformPip" {
    name                = "acceptanceTestPublicIp1"
    resource_group_name = azurerm_resource_group.jkterraformrg.name
    location            = azurerm_resource_group.jkterraformrg.location
    allocation_method   = "Dynamic"
    sku                 = "Basic"

    tags = {
        environment = "windowstesting"
  }
}

#create network interface
resource "azurerm_network_interface" "jkterraformnic" {
    name                = "jknic"
    location            = azurerm_resource_group.jkterraformrg.location
    resource_group_name = azurerm_resource_group.jkterraformrg.name
   

    ip_configuration {
        name                          = "jkniconfiguration"
        subnet_id                     = azurerm_subnet.jkterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.jkterraformPip.id
    }
}

#create storage account for boot diagnotics

resource "azurerm_storage_account" "jkstorageaccount" {
    name                     = "jkstorageaccount1"
    resource_group_name      = azurerm_resource_group.jkterraformrg.name
    location                 = azurerm_resource_group.jkterraformrg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

#create virtual machine

resource "azurerm_virtual_machine" "jkterraformvm" {
    name                          = "jkvmT1"
    location                      = azurerm_resource_group.jkterraformrg.location
    resource_group_name           = azurerm_resource_group.jkterraformrg.name
    network_interface_ids         = [azurerm_network_interface.jkterraformnic.id]
    vm_size                       = "Standard_B1ls"

    # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    # Uncomment this line to delete the data disks automatically when deleting the VM
    delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }

    storage_os_disk {
        name              = "jkosdisk1"
        disk_size_gb      = "128"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "jkterravm1"
        admin_username = "jkterravm_test"
        admin_password = "jkterra@123!"
    }

    #For windows
    os_profile_windows_config {
        provision_vm_agent = true
    }
boot_diagnostics {
    enabled = "true"
}

    tags = {
        environment = "experimenting"
    }
}