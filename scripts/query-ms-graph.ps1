[CmdletBinding()]
param(
    [string]$Name,
    [string]$Link,
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"
$GraphRoot = "https://graph.microsoft.com/v1.0"
$Scopes = "User.ReadBasic.All User.Read.All Files.Read.All Sites.Read.All"
$CachePath = Join-Path $env:LOCALAPPDATA "ms-graph\token-cache.dat"
$EnableDebug = $PSBoundParameters.ContainsKey("Debug")

function Write-Log([string]$Message) {
    $level = if ($EnableDebug) { "DEBUG" } else { "INFO" }
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $level $Message"
}

function Save-TokenCache([object]$Token, [string]$Tenant, [string]$Client) {
    $directory = Split-Path -Parent $CachePath
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $record = [ordered]@{
        tenant_id    = $Tenant
        client_id    = $Client
        access_token = $Token.access_token
        refresh_token = $Token.refresh_token
        expires_at   = ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + [int]$Token.expires_in)
    }
    $plaintext = $record | ConvertTo-Json -Compress
    # DPAPI encrypts this for the current Windows user on this Windows machine.
    $protected = ConvertFrom-SecureString (ConvertTo-SecureString $plaintext -AsPlainText -Force)
    Set-Content -Path $CachePath -Value $protected -Encoding ASCII
}

function Read-TokenCache([string]$Tenant, [string]$Client) {
    if (-not (Test-Path $CachePath)) { return $null }
    try {
        $protected = (Get-Content -Path $CachePath -Raw).Trim()
        $secure = ConvertTo-SecureString -String $protected
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $plaintext = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
        $record = $plaintext | ConvertFrom-Json
        if ($record.tenant_id -ne $Tenant -or $record.client_id -ne $Client) { return $null }
        return $record
    }
    catch {
        # Log only the exception metadata. Never log the protected cache contents.
        Write-Log "Ignoring unreadable token cache: $CachePath"
        Write-Log "Cache read error: $($_.Exception.GetType().FullName): $($_.Exception.Message)"
        return $null
    }
}

function Get-AccessToken {
    $tenant = $env:MS_GRAPH_TENANT_ID
    $client = $env:MS_GRAPH_CLIENT_ID
    if ([string]::IsNullOrWhiteSpace($tenant) -or [string]::IsNullOrWhiteSpace($client)) {
        throw "Set MS_GRAPH_TENANT_ID and MS_GRAPH_CLIENT_ID first."
    }

    $tokenEndpoint = "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token"
    $cached = Read-TokenCache $tenant $client
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    if ($cached -and $cached.access_token -and [int64]$cached.expires_at -gt ($now + 300)) {
        Write-Log "Using cached access token."
        return $cached.access_token
    }

    if ($cached -and $cached.refresh_token) {
        Write-Log "Access token expired or near expiry; refreshing from encrypted cache."
        try {
            $token = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body @{
                grant_type    = "refresh_token"
                client_id     = $client
                refresh_token = $cached.refresh_token
                scope         = $Scopes
            }
            if (-not $token.refresh_token) { $token | Add-Member -NotePropertyName refresh_token -NotePropertyValue $cached.refresh_token }
            Save-TokenCache $token $tenant $client
            return $token.access_token
        }
        catch { Write-Log "Cached refresh token was rejected; starting device sign-in." }
    }

    $deviceEndpoint = "https://login.microsoftonline.com/$tenant/oauth2/v2.0/devicecode"
    $device = Invoke-RestMethod -Method Post -Uri $deviceEndpoint -ContentType "application/x-www-form-urlencoded" -Body @{
        client_id = $client
        scope     = $Scopes
    }

    Write-Host "`n$($device.message)`n" -ForegroundColor Yellow
    $deadline = (Get-Date).AddSeconds([int]$device.expires_in)
    $delay = [int]$device.interval

    do {
        Start-Sleep -Seconds $delay
        try {
            $token = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body @{
                grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
                client_id   = $client
                device_code = $device.device_code
            }
            if ($token.access_token) {
                Save-TokenCache $token $tenant $client
                Write-Log "New token acquired and saved to encrypted Windows cache."
                return $token.access_token
            }
        }
        catch {
            $message = $_.Exception.Message
            if ($message -match "authorization_declined|expired_token|bad_verification_code") {
                throw "Device-code sign-in failed: $message"
            }
        }
    } while ((Get-Date) -lt $deadline)

    throw "Device-code sign-in timed out."
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

if (-not $Name -and -not $Link) {
    throw "Supply -Name, -Link, or both."
}

$ExitCode = 0
Write-Log "Starting Microsoft Graph diagnostic from Windows PowerShell."
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

        $directory = [IO.Path]::GetFullPath($OutputDir)
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
