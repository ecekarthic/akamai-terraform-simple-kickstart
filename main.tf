# Simple akamai terraform kickstart

# Define the provider and set the edgerc path
provider "akamai" {
     edgerc       = "~/.edgerc"
}

# Get the contract id
data "akamai_contract" "mycontract" {
}

# Get the group id
data "akamai_group" "mygroup"{
	name="ENTER_GROUPNAME_HERE"
}

# Get the cpcode id
data "akamai_cp_code" "mycpcode"{
     name = "ENTER_CPCODENAME_HERE"
     group = "${data.akamai_group.mygroup.id}"
     contract = "${data.akamai_contract.mycontract.id}"
}

# Create an A record for the origin DNS name
resource "akamai_dns_record" "origin" {
    zone       = "ENTER_DOMAIN_NAME_HERE"
    name       = "origin.ENTER_DOMAIN_NAME_HERE"
    recordtype = "A"
    active     = true
    ttl        =  600
    target     = ["ENTER_ORIGINIP_HERE"]
}

# Create a CNAME to the Edgehostname
resource "akamai_dns_record" "www" {
    zone       = "ENTER_DOMAIN_NAME_HERE"
    name       = "www.ENTER_DOMAIN_NAME_HERE"
    recordtype = "CNAME"
    active     = true
    ttl        = 600 
    target     = ["ENTER_EDGE_HOSTNAME_HERE"]
}

# Create an edgehostname
resource "akamai_edge_hostname" "edge-hostname" {
    group         = "${data.akamai_group.mygroup.id}"
    contract      = "${data.akamai_contract.mycontract.id}"
    product       = "prd_SPM"
    edge_hostname = "ENTER_EDGE_HOSTNAME_HERE"
}

# Create the property
resource "akamai_property" "myProperty" {
	name      = "ENTER_CONFIGURATION_NAME HERE"
	group     = "${data.akamai_group.mygroup.id}"
	contract  = "${data.akamai_contract.mycontract.id}"
	product   = "prd_SPM"
	cp_code   = "${data.akamai_cp_code.mycpcode.id}"
	contact   = ["ENTER_EMAIL_HERE"]
	hostnames = {"ENTER_UNIQUE_HOSTNAME_HERE" = "ENTER_EDGE_HOSTNAME_HERE"}
	variables = "${akamai_property_variables.origin.json}"
	rules     = "${data.local_file.rules.content}"
}

# Read the rules.json file
data "local_file" "rules" {
  filename = "rules.json"
}

# Create akamai variables
resource "akamai_property_variables" "origin" {
  variables {
    variable {
      name        = "PMUSER_ORIGIN"
      value       = "origin.ENTER_DOMAIN_NAME_HERE"
      description = "Default origin"
      hidden      = true
      sensitive   = false
    }
  }
}

# Activate the configuration to staging
resource "akamai_property_activation" "staging-activation" {
     property = "${akamai_property.myProperty.id}"
     network  = "STAGING"
     contact  = ["ENTER_EMAIL_HERE"] 
}
