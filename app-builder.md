Simeon makes managing Windows Intune applications easy. Using the App Builder, you can package an application once, store a copy in your baseline repository, and easily deploy it to all of your tenants. The App Builder makes it simple to update your applications once and deploy the updates and patches to all of your tenants. Once an app has been packaged using Simeon, you can view and manage it on Reconcile like any other configuration.

## Package a new application using the New Application Wizard

- From the Simeon Portal, navigate to the App Builder > select the tenant you want to create the application package in > click on **+ NEW APPLICATION** > Select **Win32** or **MSI** from the **Application Type** dropdown > **CONTINUE**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/1.png"/>

- If you selected Win32, you will need to download the empty placeholder file (empty.intunewin) for the app install files that will be required in the next step
	- When install files are uploaded to the Endpoint portal, they become encrypted and it is difficult for Simeon to decrypt these files. Therefore, the *empty.intunewin* file acts as a placeholder in the portal so you can proceed with configuring the app. You can then upload the install files in Simeon which are saved to the tenant's repository.

	<br />
	<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/2.png" width='338'/>
	<br />
	<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/3.png" width='275'/>

- Click **LAUNCH THE ENDPOINT PORTAL**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/4.png" width='338'/>

- Log in to the tenant that you are creating the application package in
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/5.png"/>

- Click **Select app package file**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/6.png"/>

- Upload the *empty.intunewin* file > **OK** > fill in the necessary information for your app > **NEXT**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/7.png"/>

- Fill in Program details > **NEXT**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/8.png"/>

- Fill in Requirements details > **NEXT**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/9.png"/>

- Fill in Detection rules > **NEXT**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/10.png"/>

- Add any Dependencies and/or Supersedence > **NEXT**
- Add any Assignments (all apps in the Simeon Baseline are assigned to the group *Baseline - Corporate Devices*) > **NEXT**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/11.png"/>

- Create. You are now done configuring your app. Go back to the **New Application Wizard** in the Simeon app > **CONTINUE** > **SYNC NOW** and wait for the Sync to finish.
	- The Sync will export the configured app into the tenant’s repository in your Simeon environment (Azure DevOps organization)
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/12.png" width='338'/>

- **DONE** > the App Builder will now load the app you just created in the tenant
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/13.png" width='338'/>

- From the App Builder, select the new app you just created in the tenant
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/14.png"/>
- We can now upload the install files by clicking **+ ADD FILE**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/15.png"/>

- Add the required install files. The different install file options are described below.

| **Install file type** | **Details** |
| :-- | :-- |
| Static File: | For single files less than 20 MB (repository limit) |
| Standard URL: | For single files larger than 20 MB, you can use a public install URL or create a public blob storage (must be downloadable without sign-in) per the instructions below <ul><li>On https://portal.azure.com/  > **Storage accounts** > **+ Create** > select a subscriptions > **Create new resource group** > name the storage account > **Standard performance** > **GRS** > **Review and create** </li><li> Once created, navigate to **Containers** > **Create** > upload the file > click the '...' > **Generate SAS** > change the **Expiry** to years out (once the expiry date lapses, then the install URL will be invalidated and must be regenerated) > **Generate SAS token and URL** > copy the **Blob SAS URL** > add the URL in the Simeon App Builder as a standard URL. You can test the URL by pasting it into a window and the installer should automatically download</li></ul> |
| Zipped URL: | A URL for multiple install files in a zip archive |
| Azure File Share Path: | Files that have this format \\anexampleaccountname.file.core.windows.net\file-share-name . See [Microsoft’s documentation](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows) |

- Select any of the Options you want as described below
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/16.png"/>
<table>
<tr>
<th> Option </th> <th> Details </th>
</tr>
<tr>
<td> Use Simeon Standard Install.bat: </td>
<td>
When checked, Simeon’s Install.bat adds a standard batch file to assist in the app installation process. The install file orchestrates the installation of any file named <b>Setup.exe/msi</b> or <b>Setup-x64.exe/msi</b> located in the same directory as the <b>install.bat</b>.
```
rem generic setup script for installing microsoft.graph.win32LobApp (intunewin) packaged applications that have both x86 and x64 installers
SETLOCAL EnableDelayedExpansion
reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > nul && set setup=setup|| set setup=Setup-x64
@echo Status of PendingFileRenameOperations before install
%SystemRoot%\System32\reg.exe query "HKLM\System\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations
if exist "%~dp0%setup%.exe" (
	start "" /b /wait "%~dp0%setup%.exe" %*
	set returncode=!errorlevel!
) else if exist "%~dp0%setup%.msi" (
    set "SystemPath=%SystemRoot%\System32"
    if exist "%SystemRoot%\Sysnative\cmd.exe" set "SystemPath=%SystemRoot%\Sysnative"
	start "" /b /wait !SystemPath!\msiexec.exe /i "%~dp0%setup%.msi" %* /quiet /l*v install.log
	set returncode=!errorlevel!
	type install.log
)
@echo Status of PendingFileRenameOperations after install
%SystemRoot%\System32\reg.exe query "HKLM\System\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations
@echo Exiting %0 with ERRORLEVEL=%returncode%
exit /b %returncode%
```
</td>
</tr>
<tr>
<td> Automatically version application: </td>
<td>
When checked, Simeon will automatically include a detection rule so that the app is reinstalled any time you make changes to the package.
</td>
</tr>
</tr>
<tr>
<td> Enable Application Install Logging: </td>
<td>
An important aspect of application install/uninstall troubleshooting is valid and consistent logs on the end-user’s device. When Enable Application Install Logging is checked, Simeon includes the property <b>enableInstallLogging</b> in the application configuration .json file to assist with the logging process. All logs captured during application installation will be written to the %temp% directory in a file named: <b>MobileApp.{name of application}.{version}.install.log</b>. This setting allows the <b>installCommandLine</b> in the application configuration .json file to be:
```
"enableInstallLogging": true,
...
"installCommandLine": "Install.bat /S",
```
When uploaded to Intune, Simeon changes the install command line to:
```
cmd /s /v /c "(Install.bat /S) >> "!temp!\MobileApp.7-Zip.012.install.log" 2>&1"
```
If the application is running as System, the logs will be found in <b>C:\windows\temp</b>. Or if the application is running in the user’s context, the logs will be in the user’s temp directory.
</td>
</tr>
</table>

- **SAVE APPLICATION** > **SYNC NOW**
<br />
	<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/17.png"/>

- Approve the Sync that is pending approval to deploy the install files to the tenant
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/18.png"/>

## Package existing apps for use with Simeon

Intune apps previously created using the Endpoint portal have encrypted install files that cannot be read/decrypted by Simeon. To manage these apps using Simeon, you must first package the existing app using the App Builder. Apps packaged with the **[App builder](https://app.simeoncloud.com/appbuilder)** can be updated by changing the install files.

- From the Simeon Portal, navigate to the **[App builder](https://app.simeoncloud.com/appbuilder)** > select your tenant > from the **Existing Application** dropdown, select the app > add install files and select any desired options as described above.
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/19.png"/>

- **SAVE APPLICATION**
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/app-builder/20.png"/>

- **SYNC NOW** > once the status changes to pending approval, Approve the Sync to deploy the package to the tenant with the newly uploaded install files. This will repackage the application with the install files you uploaded to Simeon.

### If you would like to use Variables in your apps, you can follow this guide: [ Add variables to configurations and Intune Apps](https://simeoncloud.github.io/docs/#/how-to?id=add-variables-to-configurations-and-intune-apps)