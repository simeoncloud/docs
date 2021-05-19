## Service Account Privacy and Use Statement 

This statement defines parameters for the Partner MSP’s creation of a Simeon-designated service account in Microsoft 365. The service account will be used to connect the Partner’s tenant configurations to its associated Azure DevOps Pipelines functionality.  

1. Service Account 

Partner will designate a service account related to each tenant under Simeon management. Simeon connects Azure DevOps pipeline functionality to the service account in order to export and deploy Partner’s Microsoft 365 configurations.
    
    - Credentials that are created for the service account are:

    - Randomly generated and encrypted at time of creation

    - Stored encrypted in the tenant's DevOps pipeline as a variable
   
    - Never shared in plain text with Simeon

    - Not retrievable in plain text thereafter

    - Not used outside the context of running pipeline jobs 

Partner reserves all rights to the service account including but not limited to: 

    - Revoking Simeon’s access  

    - Deleting or deactivating  

    - Changing the credentials 
 
Usage of Service Account 

The service account will be connected to Azure DevOps pipeline functionality.

Partner does not grant Simeon access to:  

    - Use the service account outside of the stated purpose of running pipeline jobs in Azure DevOps 

    - Make changes to Partner’s configurations without permission

Usage of Service Account for Ongoing Management of Partner

Changes made to Partner’s configurations: 
 
    - Can be set to require both preview and authorization for each deployment 

    - If initiated by Simeon are always at Partner’s request 

    - Can be rolled back within the pipeline functionality to the previous state of configurations  
