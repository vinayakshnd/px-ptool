resource "azurerm_virtual_network" "avn" {
  name                = "virtual-net-${var.user_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.px_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "asubnet" {
  name                 = "virtual-subnet-${var.user_prefix}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.avn.name}"
  address_prefix       = "10.0.2.0/24"
}


resource "azurerm_public_ip" "apubip" {
  count                        = "${var.px_node_count}"
  name                         = "px-azure-${var.user_prefix}-pub-ip-${count.index}"
  location                     = "${var.px_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
}


resource "azurerm_network_interface" "anetint" {
  name                = "net-intf-${var.user_prefix}-${count.index}"
  count               = "${var.px_node_count}"
  location            = "${var.px_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "ip-conf-${var.user_prefix}"
    subnet_id                     = "${azurerm_subnet.asubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.apubip.*.id, count.index)}"
  }
}

