[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, HelpMessage="This is the URL to the SharePoint Online site with the document library where you want to reset inheritance.")]
    [string]$Url, 

    [Parameter(Mandatory=$true, HelpMessage="This is the name of the document library where you want to reset inheritance.")]
    [string]$ListName, 

    [Parameter(Mandatory=$false, HelpMessage="This is the path to the DLLs for CSOM.")]
    [string]$CSOMPath
)

Set-Strictmode -Version 1

If ($CSOMPath -eq $null -or $CSOMPath -eq "") { $CSOMPath = "." }

Add-Type -Path "$CSOMPath\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "$CSOMPath\Microsoft.SharePoint.Client.Runtime.dll" 

$psCredentials = Get-Credential
$spoCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($psCredentials.UserName, $psCredentials.Password)
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($Url) 
$clientContext.Credentials = $spoCredentials 

$domain = ([System.Uri]$Url).Host
$userName = $psCredentials.UserName

If ($clientContext.ServerObjectIsNull.Value) { 
    Write-Error "Could not connect to SharePoint Online site collection: $Url"
} Else {
    Write-Host "Connected to SharePoint Online site collection: " $Url -ForegroundColor Green        
                
    $web = $clientContext.Web
    $clientContext.Load($web)
    $list = $web.Lists.GetByTitle($ListName)
    $clientContext.Load($list)
    $clientContext.ExecuteQuery()

    $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
    $items = $list.GetItems($query)
    $clientContext.Load($items)
    $clientContext.ExecuteQuery()

    $items | % {
        $_.ResetRoleInheritance()
        $_.Update()
    }
    $clientContext.ExecuteQuery()
}