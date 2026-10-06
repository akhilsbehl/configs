function Connect-Outlook {
    try{$script:Outlook=[Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application')}
    catch{throw 'Cannot attach to classic Outlook. Ask the user to open it and complete startup prompts. Do not auto-start Outlook.'}
    $script:Namespace=$script:Outlook.GetNamespace('MAPI')
    $script:Warnings.Add('COM reads the current Outlook view. Empty or partial folders do not establish server state or completed sync.')
}
function Get-MailFolder($Request) {
    $store=Value $Request 'store'
    $root=$script:Namespace.DefaultStore.GetRootFolder()
    if($store){
        $found=@();foreach($s in $script:Namespace.Stores){if($s.DisplayName -eq $store){$found+=,$s}}
        if($found.Count -ne 1){throw 'store must uniquely match an Outlook store display name'}
        $root=$found[0].GetRootFolder()
    }
    $path=Value $Request 'folder' 'Inbox'
    $parts=@($path -split '[\\/]')
    $f=$root
    foreach($part in $parts){if(!$part){throw 'Empty folder path segment'};$f=$f.Folders.Item($part)}
    return $f
}
function Get-OutlookItem($Request) {
    $id=Required $Request 'entryId'
    $storeId=Value $Request 'storeId'
    if($storeId){return $script:Namespace.GetItemFromID($id,$storeId)}
    return $script:Namespace.GetItemFromID($id)
}
function Mail-Summary($m,$Folder) {
    $row=[ordered]@{entryId=$m.EntryID;class=[int]$m.Class;subject=$m.Subject;folder=$Folder.FolderPath;storeId=$Folder.StoreID}
    foreach($field in @('SenderName','ReceivedTime','UnRead','Sent','To','SentOn')){
        try{$row[$field]=$m.$field}catch{$row[$field]=$null}
    }
    return [pscustomobject]$row
}
