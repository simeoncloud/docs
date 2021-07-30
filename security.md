### Where is it hosted

The Simeon software runs securely in your own Azure DevOps environment, tied directly to your own Azure tenant and subscription.

Because Simeon runs in your own Azure DevOps environment, you are in complete control of the security. You can harden access to your Azure DevOps environment as much as you like.

Our Web Admin user interface connects directly to your Azure DevOps environment and none of your data ever passes through our servers.

### Configuring the tenant

Simeon uses a service account to interact with your tenants. When installing Simeon into a tenant, the install process creates the service account with a randomly generated 15 character password that is immediately stored in a secret variable in Azure DevOps and then discarded. This password cannot be viewed by anyone. Only the Sync job can use this password to connect to and configure your tenant.

We also support using PIM, in which case the service account will be granted Global Reader access to your tenant and will prompt for elevation to Global Administrator only when deploying changes. If you do not use PIM, the service account is configured as a Global Administrator. Because the service account runs non-interactively, it must be excluded from any multi-factor authentication policies in your tenant.

Simeon can also run without a service account at all. In this scenario, when syncing your tenant, Simeon will provide a one-time passcode you can enter at https://https://aka.ms/devicelogin and the software will run as the logged in user, without ever providing your credentials to the Simeon software. However, with this approach, the nightly sync jobs will not be able to run on their own and you will need to sync your tenants manually.

Finally, before making any changes to your tenant, Azure DevOps will wait for you to explicitly approve the changes to be made.

### Support 

Simeon support can be granted read-only or contributor access to your Azure DevOps environment to help troubleshoot any issues. Simeon support will never make changes to your tenants and can be explicitly denied permissioned to do so.

### The software

We digitally sign our software and the processes that run in Azure DevOps confirm the integrity of the software before interacting with your tenant. 
