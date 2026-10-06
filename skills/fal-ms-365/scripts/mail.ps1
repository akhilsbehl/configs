function Invoke-Mail($Request) {
    Connect-Outlook
    $action=Required $Request 'action'
    switch($action){
        {$_ -in @('list','search')} {
            $f=Get-MailFolder $Request;$items=$f.Items
            $unread=[bool](Value $Request 'unreadOnly' $false)
            if($unread){$items=$items.Restrict('[UnRead] = True')}
            if($action -eq 'search'){
                $term=[string](Required $Request 'query');$term=$term.Replace("'","''")
                $sql='@SQL="urn:schemas:httpmail:subject" LIKE '+[char]39+'%'+$term+'%'+[char]39
                $items=$items.Restrict($sql)
                $script:Warnings.Add('Search covers subject only. For body evidence, read the returned candidate IDs. Search local view may be incomplete.')
            }
            $items.Sort('[ReceivedTime]',$true)
            $count=$items.Count;$start=Offset $Request;$limit=Limit $Request;$rows=@()
            for($i=$start+1;$i -le [Math]::Min($count,$start+$limit);$i++){$rows+=,(Mail-Summary $items.Item($i) $f)}
            return @{items=$rows;matchedCount=$count;folderItemCount=$f.Items.Count;folderUnreadCount=$f.UnReadItemCount;offset=$start;moreAvailable=($count -gt $start+$limit);completeness='local-view-page'}
        }
        'read' {
            $m=Get-OutlookItem $Request;$row=Mail-Summary $m $m.Parent
            $body=$null;try{$body=$m.Body}catch{$script:Warnings.Add('Body unavailable for this item type.')}
            $attachments=@();foreach($a in $m.Attachments){$attachments+=,[pscustomobject]@{index=$a.Index;name=$a.FileName;bytes=$a.Size}}
            return @{items=@(@{message=$row;body=$body;attachments=$attachments});completeness='single-local-item'}
        }
        'export' {
            $m=Get-OutlookItem $Request
            if($m.Class -ne 43){throw 'HTML export currently supports mail items only'}
            $dir=New-Staging;$name=Safe-Name ([string](Value $Request 'name' 'email'))
            if($name -match '\.html?$'){$name=$name -replace '\.html?$',''}
            $m.SaveAs((Join-Path $dir ($name+'.html')),5)
            if([bool](Value $Request 'includeAttachments' $true)){
                foreach($a in $m.Attachments){
                    $an=Safe-Name $a.FileName
                    # Index prefix prevents same-name collisions and separates attachments from HTML assets.
                    $a.SaveAsFile((Join-Path $dir ('attachment-'+$a.Index+'-'+$an)))
                }
            }
            $artifacts=@();foreach($file in Get-ChildItem -LiteralPath $dir){$artifacts+=,@{name=$file.Name;verified=$false}}
            return @{stagingWindowsDirectory=$dir;artifacts=$artifacts;items=@();completeness='exported-local-item'}
        }
        {$_ -in @('send','save-draft')} {
            Assert-Approval $Request
            $to=@(Required $Request 'to');$subject=[string](Required $Request 'subject');$body=[string](Value $Request 'body' '')
            $m=$script:Outlook.CreateItem(0)
            foreach($address in $to){$recipient=$m.Recipients.Add([string]$address);$recipient.Type=1}
            foreach($address in @(Value $Request 'cc' @())){$recipient=$m.Recipients.Add([string]$address);$recipient.Type=2}
            if(!$m.Recipients.ResolveAll()){throw 'Recipient resolution failed; nothing sent'}
            $m.Subject=$subject;$m.Body=$body
            foreach($p in @(Value $Request 'attachments' @())){if(!(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Attachment missing'};$null=$m.Attachments.Add($p)}
            $script:MutationAttempted=$true
            if($action -eq 'send'){$m.Send();return @{items=@();verification='submitted-not-delivery-confirmed'}}
            $m.Save();return @{items=@(@{entryId=$m.EntryID;subject=$m.Subject});verification='saved-local-draft'}
        }
        'mark-read' {
            Assert-Approval $Request
            $ids=@(Required $Request 'entryIds');$messages=@()
            # Resolve every target before any write. User approval must cover this exact ID set.
            foreach($id in $ids){$messages+=,(Get-OutlookItem ([pscustomobject]@{entryId=$id;storeId=(Value $Request 'storeId')}))}
            $done=@();foreach($m in $messages){$script:MutationAttempted=$true;$m.UnRead=$false;$m.Save();$done+=$m.EntryID}
            return @{items=$done;verification='saved-local-state'}
        }
        'move' {
            Assert-Approval $Request;$m=Get-OutlookItem $Request
            $dest=Get-MailFolder ([pscustomobject]@{folder=(Required $Request 'destinationFolder');store=(Value $Request 'store')})
            $script:MutationAttempted=$true;$moved=$m.Move($dest)
            return @{items=@((Mail-Summary $moved $dest));verification='moved-local-state'}
        }
        default {throw "Unsupported mail action: $action"}
    }
}
