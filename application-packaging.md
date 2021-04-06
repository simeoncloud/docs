Windows Intune applications can be managed easily with Simeon. Once the initial **Sync** has been run, a .json file is created for each of the Windows applications configured in Intune. The files are created and stored in the directory: **MSGraph** > **DeviceAppManagement** > **MobileApps**. Before an app can be deployed to another tenant, Simeon must know the source of the install files. This document outlines how to define the source of the install files and other properties available in Simeon.

Getting started
===============

**Our recommended workflow** is to create the app in the Endpoint Portal using a [blank intunewin file](https://raw.githubusercontent.com/simeoncloud/docs/master/empty.intunewin), **Sync** the tenant, so as to export the app configuration into your repository, and then add the **$manifest** section to the top of the exported JSON.

Creating an App with Intune
---------------------------

*   Navigate to [http://endpoint.microsoft.com](http://endpoint.microsoft.com)
    
*   **Apps** > **All Apps**
    
*   Select **+Add** at the top of the screen
    
*   In the pane that appears, select the app type **Windows app (Win32)**
    
*   Follow the Intune App instructions [provided by Microsoft](https://docs.microsoft.com/en-us/mem/intune/apps/apps-win32-add#step-1-app-information)
    
    *   For the file in the **App Information** screen, upload a [blank intunewin file](https://raw.githubusercontent.com/simeoncloud/docs/master/empty.intunewin)
        
*   Run **Sync**
    

Edit Simeon Application File
----------------------------

Once **Sync** has been run, the information entered while building the application in the portal is captured and stored as a .json file. To edit the application configuration .json file:

*   Navigate to [Azure DevOps](http://dev.azure.com)
    
*   Select the **Tenants** project
    
*   Select **Repos** on the left pane
    
*   At the top of the screen select the tenant repository that the application was added to
    
*   Type the name of the application in the top search pane
    
*   Select **Edit**
    
*   At the top of the file, after the first **{** add a .json tag named **$manifest**. See below for details on the $manfiest section
    
*   Once done editing the file, select **Commit**. Feel free to leave defaults or add a message, then select **Commit** again
    

Specify App Install Files
=========================

In order for Simeon to know how to package the intunewin file, the application configuration .json file must have a **$manifest section**.

The **$manifest section** should be placed at the top of the file after the initial **{**. For example, the application configuration .json file for 7-zip would be as follows:

```
{
    "$manifest": {
      "Install.bat": "${ResourceContext:MSGraph:DeviceAppManagement:MobileApps:Install.bat}",
      "Setup.exe": "https://www.7-zip.org/a/7z1805.exe",
      "Setup-x64.exe": "https://www.7-zip.org/a/7z1805-x64.exe"
    },
    ...Other properties truncated
    "installCommandLine": "Install.bat /S"
}
```

In this example, three files will be packaged and uploaded to Intune during **Sync**:

*   **Setup.exe**: x86 version of 7-Zip downloaded from their website
    
*   **Setup-x64.exe**: x64 version of 7-Zip downloaded from their website
    
*   **Install.bat**: A standard install file, explained later in this document
    
*   The **installCommandLine** is the command run on the device during install. Any of the files listed in the **$manifest section** can be referenced in the **installCommandLine**
    

In order to trigger re-building a package, e.g. when updating the app version, **you must change the fileName** **property** of the application configuration .json file. The property can be set to a value of your choosing; however, we recommend incrementing from **001** to track your updates.

The manifest supports a variety of file sources, including:

|     |     |     |
| --- | --- | --- |
| **Source of Install Files** | **Details** | **Examples for when to use** |
| Static install files | *   Best for text base install files, e.g. .bat/.ps1 files<br>    <br>*   By default includes all files saved in a folder with the same name as the application; it is not necessary to explicitly add these to the **$manifest section** | *   App install that require more than a single line command<br>    <br>*   Simple text files that are required during app installation |
| URL | *   Install files are downloaded from URL during Sync<br>    <br>*   The URL can be dynamically built using variables, e.g. to compose a base URL and SAS token for Azure Blob Storage URLs<br>    <br>*   Supports unzipping downloaded files using the **$unzip** property | *   Generic apps that have a reliable public download link<br>    <br>*   Files stored in an Azure Blob Storage account |
| Azure File Share | *   Packages files or directories from an Azure file share<br>    <br>*   Does not support **$unzip** | *   Access many install files without having to zip install directories<br>    <br>*   Existing install files already stored in file share |

Static install files
--------------------

Installation files can be included in a directory with the same name as the application configuration .json file. Any file stored in such a directory will be packaged as part of the application. Files in the app directory do not need to be included in the app **$manifest section** and if all the install files are sourced from the app folder, the **$manifest section** can be omitted entirely:

To add files to an app directory:

*   Navigate to [Azure DevOps](http://dev.azure.com)
    
*   Select the **Tenants** project
    
*   Select **Repos** on the left pane
    
*   At the top of the screen select the correct tenant repository
    
*   Navigate to **Source/Resources/Content/MSGraph/DeviceAppManagement/MobileApps**
    
*   Create a folder with the same name as the application
    
    *   At the top select **\+ New**, select **Folder** in the dropdown box, name the file, add contents to the created file, select **Commit**
        
    *   For additional files select **\+ New**, select **File**, enter the name of the file, select **Create**, enter the contents of the file, select **Commit**
        

URL
---

To reference a single file in an Azure storage account, define the **$manifest** as follows:

```
"$manifest": {
    "cert.cer": "${ResourceContext:AppInstallsUrl}/MyApp/cert.cer?${ResourceContext:AppInstallsSasToken}",
    "Setup.msi": "${ResourceContext:AppInstallsUrl}/MyApp/Setup.msi?${ResourceContext:AppInstallsSasToken}"
},
```

Then, in the repository’s **config.tenant.json** file, define the following variables:

```
{
  "ResourceContext": {
    "AppInstallsUrl": "https://MyBlobUrl.blob.core.windows.net/MyBlobContainer",
    "AppInstallsSasToken": "***"
  }
}
```

Azure File Share
----------------

The first step when using an Azure File Share is to ensure the host doing the **Sync** has access to the share. Once it has access, the manifest file should be updated to specify which files needed to be included in the intunewin file.

### Granting Simeon Sync access to Azure file share

*   Navigate to [Azure DevOps](http://dev.azure.com)
    
*   Select the **Tenants** project
    
*   Select **Pipelines** on the left pane
    
*   Find and click on the target tenant, will be named \[**TenantName**\] **\-** **Sync**
    
*   Select **Edit**, a screen with the pipeline definition will be loaded
    
*   Navigate to the **Stages** section at the bottom of this file
    
*   In the parameters section, add a parameter named **InitializationScript** (if not already present)
    
    *   The **InitializationScript** is a PowerShell script that gets run each time **Sync** is run
        
    *   Note that the pipeline definition uses YAML format and YAML is strict with spacing. The new parameter must be directly below the previous parameter
        
*   Create/Update the **InitializationScript** as follows, updating the values between the curly braces:
    
    ```
        InitializationScript: cmdkey /add:"{file share address}" /user:"Azure\{user with access to file share}" /pass:"{user password for auth}"
    ```
    
    *   File share address: The URL of the file share e.g. `tenantappinstall.file.core.windows.net`
        
    *   User with access to file share: The username with read access to the file share
        
    *   User password for auth: The auth token corresponding to the user
        
        *   This can be an [Azure DevOps secure variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables). If using a secure variable the value would be:
            
            ```
            /pass:"$(NameOfSecureVariable)"
            ```
            
*   The final definition for the **Sync** parameters would be:
    
    ```
    - template: Sync.yml@Templates
      parameters:
        Comment: ${{ parameters.Comment }}
        Deploy: ${{ parameters.Deploy }}
        UseLastDeployTagForExport: ${{ parameters.UseLastDeployTagForExport }}
        Export: ${{ parameters.Export }}
        UpdateBaseline: ${{ parameters.UpdateBaseline }}
        InitializationScript: cmdkey /add:"{file share address}" /user:"Azure\{user with access to file share}" /pass:"{user password for auth}"
    ```
    

### Updating $manifest to reference file share

Once access to **Sync** has been granted, the **$manifest** can be updated to instruct the download of the install files. The first part of the application configuration .json file tag is where the install files should be downloaded to, and the second part is the source of the files. For example, if all files from a specific file share path should be downloaded to the root of the install directory, the $manifest would look like this:

```
".": "${ResourceContext:AppInstallsFileShare}\\${displayName}"
```

*   `"."` represents the root directory or where the files will be downloaded to
    
*   `${ResourceContext:AppInstallsFileShare}` is defined in the **config.tenant.json** file, for example:
    
    ```
    {
      "ResourceContext": {
        "AppInstallsFileShare": "\\\\tenantappinstall.file.core.windows.net\\apps",
      }
    }
    ```
    
    *   Note the **\\\\\\\\** is required to correctly escape the backslashes and gets translated to **\\\\** during Sync
        
*   `${displayName}` is the display name of the file where this **$manifest section** exists. Update as needed to point to the correct path in the Azure file share
    

Simeon Additions to Streamline Intune Apps
------------------------------------------

Simeon understands that Intune apps can be difficult to work with, so we have provided some additional properties to help the process.

### Support for .zip Files

Zip files are supported in the $manifest. To reference a zip file, include the **$unzip** property with the location of the zip file, for example:

```
"$manifest": {
    "$unzip": "https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_WWMUI.zip"
}
```

The zip file will be unzipped and the root of the zip folder will be uploaded to Intune. The **$unzip** property can be a single URL or an array of URLs.

### Simeon’s Install.bat File

Simeon includes a standard batch file to assist in the app installation process. The install file orchestrates the installation of any file named **Setup.exe/msi** or **Setup-x64.exe/msi** located in the same directory as the **install.bat**. To use the standard **install.bat**, include the following line to the **$manifest section**:

```
"Install.bat": "${ResourceContext:MSGraph:DeviceAppManagement:MobileApps:Install.bat}" 
```

### Enable Application Install Logging

An important aspect of application install/uninstall troubleshooting is valid and consistent logs on the end-user’s device. To assist with the logging process, Simeon includes the property **enableInstallLogging** in the application configuration .json file.

When set to true, all logs captured during application installation are written to the **%temp%** directory in a file named: **MobileApp.{name of application}.{version}.install.log**. This setting allows the **installCommandLine** in the application configuration .json file to be:

```
"enableInstallLogging": true,
...
"installCommandLine": "Install.bat /S",
```

When uploaded to Intune, Simeon changes the install command line to:

```
cmd /s /v /c "(Install.bat /S) >> "!temp!\MobileApp.7-Zip.012.install.log" 2>&1"
```

If the application is running as System, the logs will be found in **C:\\windows\\temp**. Or if the application is running in the user’s context, the logs will be in the user’s temp directory.
