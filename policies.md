## Service Account Privacy and Use Statement 

This statement defines parameters for the Partner MSP’s creation of a Simeon-designated service account in Microsoft 365. The service account will be used to connect the Partner’s tenant configurations to its associated Azure DevOps Pipelines functionality.  

1. Service Account 

    - Partner will designate a service account related to each tenant under Simeon management. Simeon connects Azure Dev Ops pipeline functionality to the service account in order to export and deploy Partner’s Microsoft 365 configurations.  

    - Credentials that are created for the service account are: 

    - Entered by Partner only 

    - Encrypted at time of creation 

    - Not retrievable in plain text thereafter 

    - Never shared in plain text with Simeon 

    - Not used outside the context of running pipelines 

2. Partner reserves all rights to the service account including but not limited to: 

    - Revoking Simeon’s access  

    - Deleting or deactivating  

    - Changing the credentials 
 
3. Usage of Service Account in Initial Reconciliation 

The service account will be connected to Azure Dev Ops pipeline functionality. Partner will run an export pipeline, or grant Simeon access to run an export pipeline, for the purpose of creating a Reconciliation Preview report. 

Partner does not grant Simeon access to:  

Use the service account outside of the stated purpose of creating a Reconciliation Preview 

Make changes to Partner’s configurations 

4. Usage of Service Account for Ongoing Management of Partner 
  - Changes made to Partner’s configurations: 
 
  - Can be set to require both preview and authorization for each deployment 

  - If initiated by Simeon are always at Partner’s request 

  - Never made by Simeon without preauthorization by Partner 

  - Can be rolled back within the pipeline functionality to the previous state of configurations  
