Each Microsoft 365 tenant managed by Simeon will have:

* A Git **repository** where tenant configurations are stored as code
* A **Sync Pipeline** that performs a bidirectional sync between the Git repository and your tenant

Configuration repositories are layered to create the desired state of configurations that are deployed to a tenant. Each subsequent layer takes priority over the layer before it. Simeon uses two layers:   

* Your **Baseline**
  * Configurations an MSP may want to apply to all or many of their tenants \(e.g. Conditional Access Policies\) 
* **Tenant Specific Configurations**
  * Configurations that are specific to an individual tenant \(e.g. Company branding, printer deployment, and drive mapping scripts\)

The **Simeon Baseline**, a set of best practice configurations developed by Simeon \(e.g. requiring multi-factor authentication and packages for common apps like 7-Zip and Google Chrome\), is provided as a starting point for building your **Baseline**.
