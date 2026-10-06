Set-StrictMode -Version 2
$ErrorActionPreference='Stop'
$script:Warnings=New-Object 'System.Collections.Generic.List[string]'
$script:MutationAttempted=$false
function Value($Object,[string]$Name,$Default=$null) {
    if($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]){return $Object.$Name}
    return $Default
}
function Required($Object,[string]$Name) {
    $v=Value $Object $Name
    if($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)){throw "Required field: $Name"}
    return $v
}
function Assert-Approval($Request) {
    $approval=Value $Request 'approved' $false
    if($approval -isnot [bool] -or $approval -ne $true){throw 'Write blocked: approved=true required AFTER explicit user authorisation of exact action/content.'}
}
function Limit($Request) {
    $n=[int](Value $Request 'limit' 25)
    if($n -lt 1 -or $n -gt 100){throw 'limit must be 1..100'}
    return $n
}
function Offset($Request) {
    $n=[int](Value $Request 'offset' 0)
    if($n -lt 0){throw 'offset must be nonnegative'}
    return $n
}
function Safe-Name([string]$Name) {
    # Flatten untrusted attachment names. Windows separators may occur in Graph metadata.
    $s=($Name -replace '[\\/]', '_') -replace '[<>:"|?*\x00-\x1f]', '_'
    $s=$s.Trim().TrimEnd('.')
    if(!$s -or $s -eq '..' -or $s -eq '.'){throw 'Invalid output name'}
    if($s -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)'){$s='_'+$s}
    return $s
}
function New-Staging {
    $p=Join-Path $env:TEMP ('fal-ms-365-'+[Guid]::NewGuid().ToString())
    $null=New-Item -ItemType Directory -Path $p
    return $p
}
function Assert-GraphUri([string]$Uri) {
    $u=[Uri]$Uri
    if($u.Scheme -ne 'https' -or $u.Host -ne 'graph.microsoft.com' -or -not $u.IsDefaultPort){throw 'Graph request URL must be https://graph.microsoft.com'}
}
function Invoke-Graph([string]$Method,[string]$Uri,$Body=$null) {
    Assert-GraphUri $Uri
    $params=@{Method=$Method;Uri=$Uri;Headers=@{Authorization='Bearer '+$script:GraphToken};ErrorAction='Stop'}
    if($null -ne $Body){$params.ContentType='application/json';$params.Body=[Text.Encoding]::UTF8.GetBytes(($Body|ConvertTo-Json -Depth 15 -Compress))}
    # Deliberately no mutation retry, no auth fallback, and no generic automatic retry in this draft.
    return Invoke-RestMethod @params
}
function Graph-Page([string]$Uri) {
    $r=Invoke-Graph 'GET' $Uri
    return @{items=@(Value $r 'value' @());nextLink=(Value $r '@odata.nextLink');completeness='page'}
}
