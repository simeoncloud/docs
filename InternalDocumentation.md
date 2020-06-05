# Internal-Documentation

## Setting up a Client

* **New project** &gt; MSP name 
* **Project settings** &gt; disable all except **repos & pipelines**
* In **Project settings** &gt; **Permissions** &gt; **Contributors** &gt; **Members** &gt; **Add** - **Project Collection Build Service Accounts** &gt; **Save** 
  * **Project settings** &gt; **repositories** &gt; rename default repository \[e.g. demo map 2\] to baseline 
  * **Project settings** &gt; **Pipelines settings** &gt; uncheck **Limit job authorization scope to current project**  
* Add client users to their project
  * **Simeoncloud** \(in DevOps\) &gt; **Organization settings** &gt; **Users** &gt; **Add users** &gt; \[client email address\] &gt; **Add to projects** &gt; corresponding project name &gt; **Add** 

## Setting up a Tenant

Note - you should always first create a tenant for a baseline 

* If not already created, create a repository named after the tenant \(in the case of baseline, this should be called baseline\)
  * **Repos** &gt; dropdown at top &gt; **New repository** &gt; **Repository name** \(tenant name, which in the case of baseline should be called **baseline**\) &gt; uncheck **Add a README**
* In the repository, add a config.json 
  * **Files** \(under Repos; make sure you have the correct tenant selected at the top\) &gt;  Import a repository &gt; **Import** &gt; paste in URL \([https://github.com/admin-simeon/DefaultTenant.git](https://github.com/simeoncloud/DefaultTenant)\) &gt; **Import** 
* **Pipelines** &gt; **New** **pipeline** &gt; **Azure Repos Git** &gt; change dropdown to **All projects** &gt; **M365Management.AzurePipelines** &gt; **Existing Azure Pipelines YAML File** &gt; **M365ManagementExport.yml** &gt; **Variables** &gt; add variables below &gt; **Save** &gt; Run dropdown &gt; **Save** 
  * Variables: **AadAuth:Password** \(make sure to add password as a secret variable\), **AadAuth:Username**, **BaselineRepository**, **Repository**
* **Pipelines** &gt; **…** &gt; **Rename** &gt; name accordingly \(for export, use **\[tenant name\] - Export** and for deploy, use **\[tenant name\] - Deploy**
* Repeat process for deploy pipeline, using **M365ManagementDeploy.yml**

