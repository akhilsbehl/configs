function Invoke-Directory($Request) {
    $backend=Value $Request 'backend' 'graph'
    if($backend -eq 'com'){
        Connect-Outlook
        if((Required $Request 'action') -ne 'profile'){throw 'COM directory supports profile lookup only'}
        $r=$script:Namespace.CreateRecipient([string](Required $Request 'identity'));$null=$r.Resolve()
        if(!$r.Resolved){throw 'Directory identity could not be resolved'}
        $u=$r.AddressEntry.GetExchangeUser();if($null -eq $u){throw 'Resolved address is not an Exchange user'}
        $data=[ordered]@{}
        foreach($field in @('Name','FirstName','LastName','Alias','PrimarySmtpAddress','JobTitle','Department','CompanyName','OfficeLocation','BusinessTelephoneNumber','MobileTelephoneNumber','StreetAddress','City','StateOrProvince','PostalCode')){
            try{$data[$field]=$u.$field}catch{$data[$field]=$null}
        }
        try{$m=$u.GetExchangeUserManager();$data.manager=if($m){@{name=$m.Name;email=$m.PrimarySmtpAddress}}else{$null}}catch{$script:Warnings.Add('Manager unavailable')}
        if([bool](Value $Request 'relationships' $false)){
            $reports=@();try{foreach($a in $u.GetDirectReports()){$e=$a.GetExchangeUser();$reports+=,@{name=$a.Name;email=if($e){$e.PrimarySmtpAddress}else{$null};title=if($e){$e.JobTitle}else{$null}}}}catch{$script:Warnings.Add('Direct reports unavailable')};$data.directReports=$reports
            $groups=@();try{foreach($a in $u.GetMemberOfList()){$groups+=$a.Name}}catch{$script:Warnings.Add('Visible memberships unavailable')};$data.visibleMemberships=$groups
        }
        return @{items=@([pscustomobject]$data);completeness='directory-returned-fields'}
    }
    if($backend -ne 'graph'){throw 'directory backend must be graph or com'}
    Connect-ExistingGraph
    $root='https://graph.microsoft.com/v1.0'
    switch(Required $Request 'action'){
        'search' {
            $name=([string](Required $Request 'name')).Replace("'","''")
            $filter=[Uri]::EscapeDataString("startswith(displayName,'$name') or startswith(givenName,'$name')")
            $limit=Limit $Request
            return Graph-Page ($root+'/users?$filter='+$filter+'&$select=id,displayName,givenName,surname,mail,userPrincipalName,jobTitle,department&$top='+$limit)
        }
        'profile' {
            $id=[Uri]::EscapeDataString([string](Required $Request 'identity'))
            $profile=Invoke-Graph 'GET' ($root+'/users/'+$id+'?$select=id,displayName,givenName,surname,mail,userPrincipalName,jobTitle,department,companyName,officeLocation,businessPhones,mobilePhone,city,state,country')
            $data=@{profile=$profile}
            try{$data.manager=Invoke-Graph 'GET' ($root+'/users/'+$id+'/manager')}catch{$script:Warnings.Add('Manager lookup failed or not populated')}
            if([bool](Value $Request 'relationships' $false)){
                $data.directReports=Graph-Page ($root+'/users/'+$id+'/directReports')
                $data.visibleMemberships=Graph-Page ($root+'/users/'+$id+'/memberOf')
            }
            return @{items=@($data);completeness='profile-and-relationship-pages'}
        }
        'page' {
            $uri=[string](Required $Request 'nextLink');Assert-GraphUri $uri
            if(([Uri]$uri).AbsolutePath -notlike '/v1.0/users*'){throw 'Directory continuation must target users'}
            return Graph-Page $uri
        }
        default {throw 'Supported directory actions: search, profile, page'}
    }
}
