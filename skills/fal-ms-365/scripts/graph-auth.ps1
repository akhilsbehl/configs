function Connect-Graph([string[]]$Scopes) {
    if(!(Get-Module -ListAvailable -Name MSAL.PS)){throw 'MSAL.PS is missing. Ask before installing dependencies.'}
    foreach($key in @('MS_GRAPH_TENANT_ID','MS_GRAPH_CLIENT_ID')){
        if([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($key))){throw "Missing environment variable: $key"}
    }
    Import-Module MSAL.PS -ErrorAction Stop
    $app=New-MsalClientApplication -ClientId $env:MS_GRAPH_CLIENT_ID -TenantId $env:MS_GRAPH_TENANT_ID | Enable-MsalTokenCacheOnDisk -PassThru
    try{$result=Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent -ErrorAction Stop}
    catch{throw 'Silent Graph authentication failed. Stop; ask the user to refresh the auth cache. Do not retry or open an interactive login.'}
    $script:GraphToken=$result.AccessToken
}
function Connect-ExistingGraph {
    Connect-Graph @('User.ReadBasic.All','User.Read.All','Files.Read.All','Sites.Read.All')
}
