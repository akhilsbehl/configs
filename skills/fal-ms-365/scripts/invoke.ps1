param([Parameter(Mandatory=$true)][string]$RequestPath)
[Console]::OutputEncoding=New-Object Text.UTF8Encoding($false)
. (Join-Path $PSScriptRoot 'common.ps1')
foreach($file in @('graph-auth','outlook-connect','mail','calendar','directory','files','teams','diagnose')){. (Join-Path $PSScriptRoot ($file+'.ps1'))}
$request=$null;$exitCode=0;$backend=$null
try{
    $request=Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $operation=[string](Required $request 'operation');$action=[string](Required $request 'action')
    $defaultBackend=if($operation -in @('mail','calendar') -or ($operation -eq 'diagnose' -and $action -in @('sync','sync-status'))){'com'}elseif($operation -eq 'diagnose' -and $action -eq 'installation'){'windows'}else{'graph'}
    $backend=[string](Value $request 'backend' $defaultBackend)
    if($operation -in @('mail','calendar') -and $backend -ne 'com'){throw 'Mail/calendar use COM in this draft; Graph adapter not implemented'}
    if($operation -in @('files','teams') -and $backend -ne 'graph'){throw 'Files/Teams require Graph'}
    if($operation -eq 'diagnose' -and $backend -ne $defaultBackend){throw 'Diagnostic backend is determined by the selected action'}
    # Reject unauthorised writes before attaching to Outlook or acquiring a token.
    if(($operation -eq 'mail' -and $action -in @('send','save-draft','mark-read','move')) -or
       ($operation -eq 'calendar' -and $action -in @('create-invite','respond')) -or
       ($operation -eq 'teams' -and $action -in @('send-chat','send-channel')) -or
       ($operation -eq 'diagnose' -and $action -eq 'sync')){Assert-Approval $request}
    $data=switch($operation){
        'mail' {Invoke-Mail $request}
        'calendar' {Invoke-Calendar $request}
        'directory' {Invoke-Directory $request}
        'files' {Invoke-Files $request}
        'teams' {Invoke-Teams $request}
        'diagnose' {Invoke-Diagnose $request}
        default {throw 'Unknown operation'}
    }
    $result=[ordered]@{status='ok';backend=$backend;operation=$operation;action=$action;checkedAt=[DateTime]::UtcNow.ToString('o');warnings=@($script:Warnings.ToArray())}
    foreach($key in $data.Keys){$result[$key]=$data[$key]}
}catch{
    $exitCode=1;$code=$null;try{$code=[int]$_.Exception.Response.StatusCode}catch{}
    $message=$_.Exception.Message
    # Do not expose request bodies, token-bearing headers, or raw download URLs in failure logs.
    $result=[ordered]@{status=if($script:MutationAttempted){'unknown-mutation-outcome'}else{'error'};backend=$backend;operation=(Value $request 'operation');action=(Value $request 'action');checkedAt=[DateTime]::UtcNow.ToString('o');error=$message;httpStatus=$code;warnings=@($script:Warnings.ToArray());nextAction=if($script:MutationAttempted){'Inspect and surface the outcome. Do not retry or switch backends.'}else{'Surface the failure. Do not use a browser fallback or change authentication/permissions.'}}
}
$result|ConvertTo-Json -Depth 30
exit $exitCode
