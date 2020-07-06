# Simeon Overview

Each Microsoft 365 tenant managed by Simeon will have:

* A Git **repository** in Azure where tenant configurations are stored as code
* An **Export Pipeline** in Azure that exports and stores as code all changes made to a tenant's configurations in the Microsoft Portal
* A **Deploy Pipeline** in Azure that publishes the tenant configurations from the repository to a tenant

Configuration repositories are layered to create the desired state of configurations that are deployed to a tenant. Each subsequent layer takes priority over the layer before it. Simeon uses two layers:   

* Your **MSP Baseline**
  * Configurations an MSP may want to apply to all or many of their tenants \(e.g. custom branding\) 
* **Tenant Specific Configurations**
  * Configurations that are specific to an individual tenant \(e.g. specialized software, printer deployment, and drive mapping scripts\)

The **Simeon Baseline**, a set of best practice configurations developed by Simeon \(e.g. requiring multi-factor authentication and packages for common apps like 7-Zip and Google Chrome\), is provided as a starting point for building your **MSP Baseline**.
