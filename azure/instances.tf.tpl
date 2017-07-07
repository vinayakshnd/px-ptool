
resource "azurerm_storage_account" "astgacc" {
  name                = "stgacc${var.user_prefix}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.px_region}"
  account_type        = "Standard_LRS"

  tags {
    environment = "${var.user_prefix}"
  }
}

resource "azurerm_storage_container" "astgctnr" {
  name                  = "stg-ctnr-${var.user_prefix}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.astgacc.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "avm" {
  name                  = "px-azure-vm-${var.user_prefix}-${count.index}"
  count                 = "${var.px_node_count}"
  location              = "${var.px_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.anetint.*.id, count.index)}"]
  vm_size = "${var.px_vm_size}"

  storage_image_reference {
    publisher = "${var.vm_image_publisher}"
    offer     = "${var.vm_image_offer}"
    sku       = "${var.vm_image_sku}"
    version   = "${var.vm_image_version}"
  }

  storage_os_disk {
    name          = "osdisk${count.index + 1}"
    vhd_uri       = "${azurerm_storage_account.astgacc.primary_blob_endpoint}${azurerm_storage_container.astgctnr.name}/osdisk${count.index + 1}.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "px-azure-node-${count.index + 1}"
    admin_username = "${var.vm_admin_user}"
    admin_password = "${var.vm_admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${var.user_prefix}"
  }

}