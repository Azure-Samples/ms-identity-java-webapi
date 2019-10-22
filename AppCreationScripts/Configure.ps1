[CmdletBinding()]
param(
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $tenantId
)

<#
 This script creates the Azure AD applications needed for this sample and updates the configuration files
 for the visual Studio projects from the data in the Azure AD applications.

 Before running this script you need to install the AzureAD cmdlets as an administrator. 
 For this:
 1) Run Powershell as an administrator
 2) in the PowerShell window, type: Install-Module AzureAD

 There are four ways to run this script. For more information, read the AppCreationScripts.md file in the same folder as this script.
#>

# Create a password that can be used as an application key
Function ComputePassword
{
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    $aesManaged.GenerateKey()
    return [System.Convert]::ToBase64String($aesManaged.Key)
}

# Create an application key
# See https://www.sabin.io/blog/adding-an-azure-active-directory-application-and-key-using-powershell/
Function CreateAppKey([DateTime] $fromDate, [double] $durationInYears, [string]$pw)
{
    $endDate = $fromDate.AddYears($durationInYears) 
    $keyId = (New-Guid).ToString();
    $key = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential
    $key.StartDate = $fromDate
    $key.EndDate = $endDate
    $key.Value = $pw
    $key.KeyId = $keyId
    return $key
}

# Adds the requiredAccesses (expressed as a pipe separated string) to the requiredAccess structure
# The exposed permissions are in the $exposedPermissions collection, and the type of permission (Scope | Role) is 
# described in $permissionType
Function AddResourcePermission($requiredAccess, `
                               $exposedPermissions, [string]$requiredAccesses, [string]$permissionType)
{
        foreach($permission in $requiredAccesses.Trim().Split("|"))
        {
            foreach($exposedPermission in $exposedPermissions)
            {
                if ($exposedPermission.Value -eq $permission)
                 {
                    $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
                    $resourceAccess.Type = $permissionType # Scope = Delegated permissions | Role = Application permissions
                    $resourceAccess.Id = $exposedPermission.Id # Read directory data
                    $requiredAccess.ResourceAccess.Add($resourceAccess)
                 }
            }
        }
}

#
# Example: GetRequiredPermissions "Microsoft Graph"  "Graph.Read|User.Read"
# See also: http://stackoverflow.com/questions/42164581/how-to-configure-a-new-azure-ad-application-through-powershell
Function GetRequiredPermissions([string] $applicationDisplayName, [string] $requiredDelegatedPermissions, [string]$requiredApplicationPermissions, $servicePrincipal)
{
    # If we are passed the service principal we use it directly, otherwise we find it from the display name (which might not be unique)
    if ($servicePrincipal)
    {
        $sp = $servicePrincipal
    }
    else
    {
        $sp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$applicationDisplayName'"
    }
    $appid = $sp.AppId
    $requiredAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $requiredAccess.ResourceAppId = $appid 
    $requiredAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]

    # $sp.Oauth2Permissions | Select Id,AdminConsentDisplayName,Value: To see the list of all the Delegated permissions for the application:
    if ($requiredDelegatedPermissions)
    {
        AddResourcePermission $requiredAccess -exposedPermissions $sp.Oauth2Permissions -requiredAccesses $requiredDelegatedPermissions -permissionType "Scope"
    }
    
    # $sp.AppRoles | Select Id,AdminConsentDisplayName,Value: To see the list of all the Application permissions for the application
    if ($requiredApplicationPermissions)
    {
        AddResourcePermission $requiredAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType "Role"
    }
    return $requiredAccess
}


Function UpdateLine([string] $line, [string] $value)
{
    $index = $line.IndexOf('=')
    $delimiter = ';'
    if ($index -eq -1)
    {
        $index = $line.IndexOf(':')
        $delimiter = ','
    }
    if ($index -ige 0)
    {
        $line = $line.Substring(0, $index+1) + " "+'"'+$value+'"'+$delimiter
    }
    return $line
}

Function UpdateTextFile([string] $configFilePath, [System.Collections.HashTable] $dictionary)
{
    $lines = Get-Content $configFilePath
    $index = 0
    while($index -lt $lines.Length)
    {
        $line = $lines[$index]
        foreach($key in $dictionary.Keys)
        {
            if ($line.Contains($key))
            {
                $lines[$index] = UpdateLine $line $dictionary[$key]
            }
        }
        $index++
    }

    Set-Content -Path $configFilePath -Value $lines -Force
}
<#.Description
   This function creates a new Azure AD scope (OAuth2Permission) with default and provided values
#>  
Function CreateScope( [string] $value, [string] $userConsentDisplayName, [string] $userConsentDescription, [string] $adminConsentDisplayName, [string] $adminConsentDescription)
{
    $scope = New-Object Microsoft.Open.AzureAD.Model.OAuth2Permission
    $scope.Id = New-Guid
    $scope.Value = $value
    $scope.UserConsentDisplayName = $userConsentDisplayName
    $scope.UserConsentDescription = $userConsentDescription
    $scope.AdminConsentDisplayName = $adminConsentDisplayName
    $scope.AdminConsentDescription = $adminConsentDescription
    $scope.IsEnabled = $true
    $scope.Type = "User"
    return $scope
}

<#.Description
   This function creates a new Azure AD AppRole with default and provided values
#>  
Function CreateAppRole([string] $types, [string] $name, [string] $description)
{
    $appRole = New-Object Microsoft.Open.AzureAD.Model.AppRole
    $appRole.AllowedMemberTypes = New-Object System.Collections.Generic.List[string]
    $typesArr = $types.Split(',')
    foreach($type in $typesArr)
    {
        $appRole.AllowedMemberTypes.Add($type);
    }
    $appRole.DisplayName = $name
    $appRole.Id = New-Guid
    $appRole.IsEnabled = $true
    $appRole.Description = $description
    $appRole.Value = $name;
    return $appRole
}

Set-Content -Value "<html><body><table>" -Path createdApps.html
Add-Content -Value "<thead><tr><th>Application</th><th>AppId</th><th>Url in the Azure portal</th></tr></thead><tbody>" -Path createdApps.html

$ErrorActionPreference = "Stop"

Function ConfigureApplications
{
<#.Description
   This function creates the Azure AD applications for the sample in the provided Azure AD tenant and updates the
   configuration files in the client and service project  of the visual studio solution (App.Config and Web.Config)
   so that they are consistent with the Applications parameters
#> 
    $commonendpoint = "common"

    # $tenantId is the Active Directory Tenant. This is a GUID which represents the "Directory ID" of the AzureAD tenant
    # into which you want to create the apps. Look it up in the Azure portal in the "Properties" of the Azure AD.

    # Login to Azure PowerShell (interactive if credentials are not already provided:
    # you'll need to sign-in with creds enabling your to create apps in the tenant)
    if (!$Credential -and $TenantId)
    {
        $creds = Connect-AzureAD -TenantId $tenantId
    }
    else
    {
        if (!$TenantId)
        {
            $creds = Connect-AzureAD -Credential $Credential
        }
        else
        {
            $creds = Connect-AzureAD -TenantId $tenantId -Credential $Credential
        }
    }

    if (!$tenantId)
    {
        $tenantId = $creds.Tenant.Id
    }

    $tenant = Get-AzureADTenantDetail
    $tenantName =  ($tenant.VerifiedDomains | Where { $_._Default -eq $True }).Name

    # Get the user running the script to add the user as the app owner
    $user = Get-AzureADUser -ObjectId $creds.Account.Id

   # Create the java_webapp AAD application
   Write-Host "Creating the AAD application (java_webapp)"
   # Get a 2 years application key for the java_webapp Application
   $pw = ComputePassword
   $fromDate = [DateTime]::Now;
   $key = CreateAppKey -fromDate $fromDate -durationInYears 2 -pw $pw
   $java_webappAppKey = $pw
   # create the application 
   $java_webappAadApplication = New-AzureADApplication -DisplayName "java_webapp" `
                                                       -LogoutUrl "https://localhost:8080/msal4jsample/sign-out" `
                                                       -ReplyUrls "https://localhost:8080/msal4jsample/secure/aad", "https://localhost:8080/msal4jsample/graph/me" `
                                                       -IdentifierUris "https://$tenantName/java_webapp" `
                                                       -AvailableToOtherTenants $True `
                                                       -PasswordCredentials $key `
                                                       -Oauth2AllowImplicitFlow $true `
                                                       -PublicClient $False

   # create the service principal of the newly created application 
   $currentAppId = $java_webappAadApplication.AppId
   $java_webappServicePrincipal = New-AzureADServicePrincipal -AppId $currentAppId -Tags {WindowsAzureActiveDirectoryIntegratedApp}

   # add the user running the script as an app owner if needed
   $owner = Get-AzureADApplicationOwner -ObjectId $java_webappAadApplication.ObjectId
   if ($owner -eq $null)
   { 
        Add-AzureADApplicationOwner -ObjectId $java_webappAadApplication.ObjectId -RefObjectId $user.ObjectId
        Write-Host "'$($user.UserPrincipalName)' added as an application owner to app '$($java_webappServicePrincipal.DisplayName)'"
   }


   Write-Host "Done creating the java_webapp application (java_webapp)"

   # URL of the AAD application in the Azure portal
   # Future? $java_webappPortalUrl = "https://portal.azure.com/#@"+$tenantName+"/blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/"+$java_webappAadApplication.AppId+"/objectId/"+$java_webappAadApplication.ObjectId+"/isMSAApp/"
   $java_webappPortalUrl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/"+$java_webappAadApplication.AppId+"/objectId/"+$java_webappAadApplication.ObjectId+"/isMSAApp/"
   Add-Content -Value "<tr><td>java_webapp</td><td>$currentAppId</td><td><a href='$java_webappPortalUrl'>java_webapp</a></td></tr>" -Path createdApps.html

   $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

   # Add Required Resources Access (from 'java_webapp' to 'service')
   Write-Host "Getting access from 'java_webapp' to 'service'"
   $requiredPermissions = GetRequiredPermissions -applicationDisplayName "service" `
                                                -requiredDelegatedPermissions "User.Read|access_as_user" `

   $requiredResourcesAccess.Add($requiredPermissions)


   Set-AzureADApplication -ObjectId $java_webappAadApplication.ObjectId -RequiredResourceAccess $requiredResourcesAccess
   Write-Host "Granted permissions."

   # Create the java_obo AAD application
   Write-Host "Creating the AAD application (java_obo)"
   # Get a 2 years application key for the java_obo Application
   $pw = ComputePassword
   $fromDate = [DateTime]::Now;
   $key = CreateAppKey -fromDate $fromDate -durationInYears 2 -pw $pw
   $java_oboAppKey = $pw
   # create the application 
   $java_oboAadApplication = New-AzureADApplication -DisplayName "java_obo" `
                                                    -AvailableToOtherTenants $True `
                                                    -PasswordCredentials $key `
                                                    -PublicClient $False
   $java_oboIdentifierUri = 'api://'+$java_oboAadApplication.AppId
   Set-AzureADApplication -ObjectId $java_oboAadApplication.ObjectId -IdentifierUris $java_oboIdentifierUri

   # create the service principal of the newly created application 
   $currentAppId = $java_oboAadApplication.AppId
   $java_oboServicePrincipal = New-AzureADServicePrincipal -AppId $currentAppId -Tags {WindowsAzureActiveDirectoryIntegratedApp}

   # add the user running the script as an app owner if needed
   $owner = Get-AzureADApplicationOwner -ObjectId $java_oboAadApplication.ObjectId
   if ($owner -eq $null)
   { 
        Add-AzureADApplicationOwner -ObjectId $java_oboAadApplication.ObjectId -RefObjectId $user.ObjectId
        Write-Host "'$($user.UserPrincipalName)' added as an application owner to app '$($java_oboServicePrincipal.DisplayName)'"
   }

    # rename the user_impersonation scope if it exists to match the readme steps or add a new scope
    $scopes = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.OAuth2Permission]
   
    if ($scopes.Count -ge 0) 
    {
        # add all existing scopes first
        $serviceAadApplication.Oauth2Permissions | foreach-object { $scopes.Add($_) }

        $scope = $serviceAadApplication.Oauth2Permissions | Where-Object { $_.Value -eq "User_impersonation" }

        if ($scope -ne $null) 
        {
            $scope.Value = "access_as_user"
        }
        else 
        {
            # Add scope
            $scope = CreateScope -value "access_as_user"  `
                -userConsentDisplayName "Access java_obo"  `
                -userConsentDescription "Allow the application to access java_obo on your behalf."  `
                -adminConsentDisplayName "Access java_obo"  `
                -adminConsentDescription "Allows the app to have the same access to information in the directory on behalf of the signed-in user."
            
            $scopes.Add($scope)
        }        
    }
     
    # add/update scopes
    Set-AzureADApplication -ObjectId $serviceAadApplication.ObjectId -OAuth2Permission $scopes

   Write-Host "Done creating the java_obo application (java_obo)"

   # URL of the AAD application in the Azure portal
   # Future? $java_oboPortalUrl = "https://portal.azure.com/#@"+$tenantName+"/blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/"+$java_oboAadApplication.AppId+"/objectId/"+$java_oboAadApplication.ObjectId+"/isMSAApp/"
   $java_oboPortalUrl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/"+$java_oboAadApplication.AppId+"/objectId/"+$java_oboAadApplication.ObjectId+"/isMSAApp/"
   Add-Content -Value "<tr><td>java_obo</td><td>$currentAppId</td><td><a href='$java_oboPortalUrl'>java_obo</a></td></tr>" -Path createdApps.html

   $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

   # Add Required Resources Access (from 'java_obo' to 'Microsoft Graph')
   Write-Host "Getting access from 'java_obo' to 'Microsoft Graph'"
   $requiredPermissions = GetRequiredPermissions -applicationDisplayName "Microsoft Graph" `
                                                -requiredDelegatedPermissions "User.Read" `

   $requiredResourcesAccess.Add($requiredPermissions)


   Set-AzureADApplication -ObjectId $java_oboAadApplication.ObjectId -RequiredResourceAccess $requiredResourcesAccess
   Write-Host "Granted permissions."

   # Update config file for 'webApp'
   $configFile = $pwd.Path + "\..\appsettings.json"
   Write-Host "Updating the sample code ($configFile)"
   $dictionary = @{ "ClientId" = $webAppAadApplication.AppId;"TenantId" = $tenantId;"Domain" = $tenantName };
   UpdateTextFile -configFilePath $configFile -dictionary $dictionary
  
   Add-Content -Value "</tbody></table></body></html>" -Path createdApps.html  
}

# Pre-requisites
if ((Get-Module -ListAvailable -Name "AzureAD") -eq $null) { 
    Install-Module "AzureAD" -Scope CurrentUser 
}

Import-Module AzureAD

# Run interactively (will ask you for the tenant ID)
ConfigureApplications -Credential $Credential -tenantId $TenantId