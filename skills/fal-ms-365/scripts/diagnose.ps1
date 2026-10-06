function Invoke-Diagnose($Request) {
    switch(Required $Request 'action'){
        'installation' {
            $new=@();if(Get-Command Get-AppxPackage -ErrorAction SilentlyContinue){$new=@(Get-AppxPackage -Name Microsoft.OutlookForWindows | Select-Object Name,Version)}
            $classic=@();foreach($key in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE')){
                if(Test-Path $key){$p=(Get-ItemProperty $key).'(default)';$classic+=,@{path=$p;exists=(Test-Path -LiteralPath $p)}}
            }
            $type=[Type]::GetTypeFromProgID('Outlook.Application')
            return @{items=@(@{newOutlook=$new;classicOutlook=$classic;comRegistered=($null -ne $type);running=@(Get-Process -Name OUTLOOK,olk -ErrorAction SilentlyContinue|Select-Object ProcessName)});completeness='machine-inspection'}
        }
        {$_ -in @('sync-status','sync')} {
            if((Required $Request 'action') -eq 'sync'){Assert-Approval $Request}
            Connect-Outlook
            if($Request.action -eq 'sync'){$script:MutationAttempted=$true;$script:Namespace.SendAndReceive($false);$script:Warnings.Add('Send/Receive requested. This does not prove sync completion or perform folder-specific UI Update Folder.')}
            $rows=@();foreach($name in @('Inbox','Sent Items','Drafts','Snoozed')){
                try{$f=Get-MailFolder ([pscustomobject]@{folder=$name});$rows+=,@{folder=$name;count=$f.Items.Count;unread=$f.UnReadItemCount}}catch{$script:Warnings.Add("Cannot inspect folder: $name")}
            }
            $errors=@();foreach($id in @(19,20,21,22)){
                try{$f=$script:Namespace.GetDefaultFolder($id);$log=$f.Items;$log.Sort('[CreationTime]',$true);$recent=@();for($i=1;$i -le [Math]::Min(3,$log.Count);$i++){$m=$log.Item($i);$recent+=,@{subject=$m.Subject;created=$m.CreationTime}};$errors+=,@{folder=$f.Name;count=$f.Items.Count;recent=$recent}}catch{$script:Warnings.Add('Sync diagnostic folder unavailable')}
            }
            return @{items=@(@{offline=$script:Namespace.Offline;exchangeConnectionMode=$script:Namespace.ExchangeConnectionMode;timezone=[TimeZoneInfo]::Local.Id;folders=$rows;syncLogs=$errors});completeness='local-snapshot'}
        }
        'graph-capabilities' {
            Connect-ExistingGraph;$rows=@()
            foreach($uri in @('https://graph.microsoft.com/v1.0/me/joinedTeams','https://graph.microsoft.com/v1.0/me/chats?$top=1')){
                try{$r=Invoke-Graph 'GET' $uri;$rows+=,@{endpoint=$uri;result='pass';returnedCount=@($r.value).Count}}
                catch{$code=$null;try{$code=[int]$_.Exception.Response.StatusCode}catch{};$rows+=,@{endpoint=$uri;result='fail';httpStatus=$code};if($code -eq 401){throw 'Graph authentication rejected. Stop; refresh authentication.'}}
            }
            return @{items=$rows;completeness='endpoint-probes-existing-token'}
        }
        default {throw 'Unsupported diagnostics action'}
    }
}
