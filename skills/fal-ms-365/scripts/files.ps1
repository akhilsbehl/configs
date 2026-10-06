function Invoke-Files($Request) {
    Connect-ExistingGraph
    $root='https://graph.microsoft.com/v1.0';$action=Required $Request 'action'
    if($action -eq 'search'){
        $query=[string](Required $Request 'query');$from=Offset $Request;$limit=Limit $Request
        $body=@{requests=@(@{entityTypes=@('driveItem');query=@{queryString=$query};from=$from;size=$limit})}
        $result=Invoke-Graph 'POST' ($root+'/search/query') $body
        $rows=@();$total=0;$more=$false
        foreach($v in $result.value){foreach($c in $v.hitsContainers){$total=$c.total;$more=$c.moreResultsAvailable;foreach($h in @(Value $c 'hits' @())){
            $r=$h.resource;$parent=Value $r 'parentReference'
            $rows+=,@{name=$r.name;id=$r.id;driveId=(Value $parent 'driveId');webUrl=$r.webUrl;modified=(Value $r 'lastModifiedDateTime');bytes=(Value $r 'size');summary=(Value $h 'summary');rank=$h.rank}
        }}}
        return @{items=$rows;total=$total;offset=$from;moreAvailable=$more;completeness='indexed-search-page'}
    }
    if($action -notin @('metadata','download')){throw 'Supported files actions: search, metadata, download'}
    $link=Value $Request 'link'
    if($link){
        $u=[Uri]$link
        if($u.Scheme -ne 'https'){throw 'Sharing link must use HTTPS'}
        $encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($link)).TrimEnd('=').Replace('+','-').Replace('/','_')
        $uri=$root+'/shares/u!'+$encoded+'/driveItem'
    }else{
        $drive=[Uri]::EscapeDataString([string](Required $Request 'driveId'))
        $id=[Uri]::EscapeDataString([string](Required $Request 'itemId'))
        $uri=$root+'/drives/'+$drive+'/items/'+$id
    }
    $r=Invoke-Graph 'GET' $uri
    if($action -eq 'metadata'){
        $r.PSObject.Properties.Remove('@microsoft.graph.downloadUrl')
        return @{items=@($r);completeness='single-drive-item'}
    }
    if($null -eq (Value $r 'file')){throw 'Only file downloads are supported; no folder recursion'}
    $dir=New-Staging;$name=Safe-Name ([string](Value $Request 'name' $r.name));$dest=Join-Path $dir $name
    $download=Value $r '@microsoft.graph.downloadUrl'
    if($download){
        if(([Uri]$download).Scheme -ne 'https'){throw 'Download URL must use HTTPS'}
        # A Graph-provided preauthenticated download URL receives NO Graph bearer header.
        $null=Invoke-WebRequest -UseBasicParsing -Uri $download -OutFile $dest
    }else{
        # Same behaviour as the established sharing-link client; do not log bearer headers.
        $null=Invoke-WebRequest -UseBasicParsing -Uri ($uri+'/content') -Headers @{Authorization='Bearer '+$script:GraphToken} -OutFile $dest
    }
    if((Get-Item -LiteralPath $dest).Length -ne [long]$r.size){throw 'Download size differs from Graph metadata'}
    return @{items=@(@{name=$r.name;webUrl=$r.webUrl;bytes=$r.size});stagingWindowsDirectory=$dir;artifacts=@(@{name=$name;verified=$false});completeness='downloaded-drive-item'}
}
