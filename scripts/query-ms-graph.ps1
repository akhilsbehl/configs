[CmdletBinding()]
param(
    [string]$Name,
    [string]$Link,
    [string]$OutputDir = $PSScriptRoot,
    [switch]$ClearCache
)

$ErrorActionPreference = "Stop"
$GraphRoot   = "https://graph.microsoft.com/v1.0"
$Scopes      = @("User.ReadBasic.All", "User.Read.All", "Files.Read.All", "Sites.Read.All")
$EnableDebug = $PSBoundParameters.ContainsKey("Debug")

function Write-Log([string]$Message) {
    $level = if ($EnableDebug) { "DEBUG" } else { "INFO" }
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $level $Message"
}

# --- Prereqs -----------------------------------------------------------
# MSAL.PS wraps MSAL.NET, which is what actually knows how to talk to the
# Windows broker (WAM). This is the piece raw Invoke-RestMethod against
# /oauth2/v2.0/devicecode can never do — device code flow has no device
# identity to hand over, broker auth does (it uses the same PRT dsregcmd
# shows you already have).
if (-not (Get-Module -ListAvailable -Name MSAL.PS)) {
    Write-Log "MSAL.PS not found; installing for current user."
    Install-Module MSAL.PS -Scope CurrentUser -Force -AllowClobber
}
Import-Module MSAL.PS -ErrorAction Stop

if ($ClearCache) {
    Write-Log "Clearing token cache and forcing interactive re-auth."
    $defaultCacheDir = Join-Path $env:LOCALAPPDATA ".IdentityService"
    Remove-Item -Path $defaultCacheDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-AccessToken {
    $tenant = $env:MS_GRAPH_TENANT_ID
    $client = $env:MS_GRAPH_CLIENT_ID
    if ([string]::IsNullOrWhiteSpace($tenant) -or [string]::IsNullOrWhiteSpace($client)) {
        throw "Set MS_GRAPH_TENANT_ID and MS_GRAPH_CLIENT_ID first."
    }

    # v4.37 of Enable-MsalTokenCacheOnDisk takes no path override — it
    # persists to its own fixed, DPAPI-protected location under
    # %LOCALAPPDATA%\.IdentityService automatically. No -CacheFilePath
    # parameter exists on this version, so we don't try to redirect it.
    $app = New-MsalClientApplication -ClientId $client -TenantId $tenant |
        Enable-MsalTokenCacheOnDisk -PassThru

    # Step 1: silent. If a cached access token or a usable refresh token /
    # PRT-derived token exists, this returns with no prompt, no browser,
    # no device code, nothing. This is what makes subsequent runs silent.
    try {
        Write-Log "Attempting silent token acquisition from cache/broker."
        $result = Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent -ErrorAction Stop
        Write-Log "Silent acquisition succeeded (no interaction required)."
        return $result.AccessToken
    }
    catch {
        Write-Log "Silent acquisition failed or no cached session: $($_.Exception.Message)"
    }

    # Step 2: interactive, explicitly routed through the Windows broker
    # (WAM) via -AuthenticationBroker. This is the actual switch that
    # carries device identity/PRT to Entra — -Interactive alone can fall
    # back to an embedded browser with no device binding, which is the
    # device-code-flow problem all over again under a different name.
    Write-Log "No valid cached session; requesting interactive broker sign-in."
    $result = Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Interactive -AuthenticationBroker -ErrorAction Stop
    Write-Log "Interactive broker sign-in succeeded; token cached for future runs."
    return $result.AccessToken
}

function Invoke-Graph([string]$Method, [string]$Uri, [string]$Token) {
    Write-Log "$Method $Uri"
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers @{
        Authorization = "Bearer $Token"
        Accept        = "application/json"
    }
}

function Find-People([string]$PersonName, [string]$Token) {
    $escaped = $PersonName.Replace("'", "''")
    $filter = [uri]::EscapeDataString("startswith(displayName,'$escaped')")
    $select = [uri]::EscapeDataString("id,displayName,givenName,surname,mail,userPrincipalName,jobTitle,department")
    $uri = "$GraphRoot/users?`$filter=$filter&`$select=$select&`$top=25"
    return (Invoke-Graph "GET" $uri $Token).value
}

function ConvertTo-ShareToken([string]$SharingLink) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($SharingLink)
    $base64 = [Convert]::ToBase64String($bytes).TrimEnd([char[]]"=").Replace("+", "-").Replace("/", "_")
    return "u!$base64"
}

function Get-SharedFile([string]$SharingLink, [string]$Token) {
    $shareToken = [uri]::EscapeDataString((ConvertTo-ShareToken $SharingLink))
    $select = [uri]::EscapeDataString("id,name,size,file,parentReference,webUrl,@microsoft.graph.downloadUrl")
    return Invoke-Graph "GET" "$GraphRoot/shares/$shareToken/driveItem?`$select=$select" $Token
}

if (-not $Name -and -not $Link -and -not $ClearCache) {
    throw "Supply -Name, -Link, or both (or -ClearCache to reset auth)."
}

$ExitCode = 0
Write-Log "Starting Microsoft Graph query via MSAL broker auth."
$token = Get-AccessToken
Write-Log "Access token acquired."

if ($Name) {
    try {
        $people = Find-People $Name $token
        Write-Host "`nDirectory matches:"
        if ($people) { $people | ConvertTo-Json -Depth 10 } else { Write-Host "none" }
    }
    catch {
        $ExitCode = 1
        Write-Error "Directory lookup failed: $($_.Exception.Message)"
    }
}

if ($Link) {
    try {
        $file = Get-SharedFile $Link $token
        if (-not $file.file) { throw "The link resolved to a folder or non-file item." }

        $directory = if ([IO.Path]::IsPathRooted($OutputDir)) {
            $OutputDir
        }
        else {
            # [IO.Path]::GetFullPath resolves against .NET's process-level
            # CurrentDirectory, which broker/WAM sign-in can silently leave
            # pointed at system32 for the rest of the session. $PWD is
            # PowerShell's own provider location and doesn't drift with it.
            Join-Path $PWD.Path $OutputDir
        }
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
        $filename = [IO.Path]::GetFileName($file.name)
        $destination = Join-Path $directory $filename
        Write-Log "Downloading $filename to $destination"

        if ($file.'@microsoft.graph.downloadUrl') {
            Invoke-WebRequest -Uri $file.'@microsoft.graph.downloadUrl' -OutFile $destination
        }
        else {
            # Some Graph/SharePoint responses omit the downloadUrl annotation.
            # /content returns the same file through a Graph-managed redirect.
            Write-Log "No downloadUrl annotation; using the /content endpoint."
            $shareToken = [uri]::EscapeDataString((ConvertTo-ShareToken $Link))
            $contentUri = "$GraphRoot/shares/$shareToken/driveItem/content"
            Invoke-WebRequest -Uri $contentUri -Headers @{ Authorization = "Bearer $token" } -OutFile $destination
        }
        Write-Host "`nDownloaded copy: $destination"
    }
    catch {
        $ExitCode = 1
        Write-Error "File operation failed: $($_.Exception.Message)"
    }
}

exit $ExitCode
