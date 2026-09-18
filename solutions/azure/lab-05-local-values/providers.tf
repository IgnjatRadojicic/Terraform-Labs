# The features block is MANDATORY and has no AWS equivalent. It may be
# empty, but omitting it entirely is an error.
#
# The catch: terraform validate PASSES without it. Only plan fails. This
# is the first thing the Azure track teaches that the AWS track cannot.
provider "azurerm" {
  features {}

  # Terraform 4.x requires a subscription ID. Set ARM_SUBSCRIPTION_ID in
  # your environment, or uncomment and hardcode it here.
  # subscription_id = "00000000-0000-0000-0000-000000000000"
}
