function Invoke-Calendar($Request) {
    Connect-Outlook
    switch(Required $Request 'action'){
        'list' {
            $start=[DateTime]::Parse([string](Required $Request 'start'))
            $end=[DateTime]::Parse([string](Required $Request 'end'))
            if($end -le $start){throw 'end must be after start'}
            $f=$script:Namespace.GetDefaultFolder(9);$items=$f.Items
            $items.Sort('[Start]');$items.IncludeRecurrences=$true
            # Outlook Restrict expects locally formatted date strings, without seconds.
            $filter="[Start] < '"+$end.ToString('g')+"' AND [End] > '"+$start.ToString('g')+"'"
            $items=$items.Restrict($filter);$rows=@();$limit=Limit $Request;$offset=Offset $Request;$seen=0;$more=$false
            foreach($m in $items){if($seen++ -lt $offset){continue};if($rows.Count -ge $limit){$more=$true;break}
                $recurrenceState=$null;$responseStatus=$null;$globalId=$null;$originalDate=$null
                try{$recurrenceState=[int]$m.RecurrenceState}catch{}
                try{$responseStatus=[int]$m.ResponseStatus}catch{}
                try{$globalId=[string]$m.GlobalAppointmentID}catch{}
                try{if($null -ne $m.OriginalDate){$originalDate=$m.OriginalDate.ToString('s')}}catch{}
                $rows+=,@{entryId=$m.EntryID;storeId=$f.StoreID;subject=$m.Subject;start=$m.Start.ToString('s');end=$m.End.ToString('s');organizer=$m.Organizer;location=$m.Location;meetingStatus=$m.MeetingStatus;responseStatus=$responseStatus;isRecurring=[bool]$m.IsRecurring;recurrenceState=$recurrenceState;globalAppointmentId=$globalId;originalDate=$originalDate}}
            return @{items=$rows;timezone=[TimeZoneInfo]::Local.Id;moreAvailable=$more;offset=$offset;completeness='local-view-page';freeBusyAvailable=$false;freeBusyNote='Use calendar/free-busy with an explicitly resolved recipient and local time range.'}
        }
        'free-busy' {
            $startText=[string](Required $Request 'start');$endText=[string](Required $Request 'end');$zone=[string](Required $Request 'timezone')
            if($zone -ne [TimeZoneInfo]::Local.Id){throw 'timezone must match the Windows local timezone ID; do not silently convert'}
            $start=[DateTime]::ParseExact($startText,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture);$end=[DateTime]::ParseExact($endText,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture)
            if($end -le $start){throw 'end must be after start'}
            if([TimeZoneInfo]::Local.IsInvalidTime($start) -or [TimeZoneInfo]::Local.IsAmbiguousTime($start) -or [TimeZoneInfo]::Local.IsInvalidTime($end) -or [TimeZoneInfo]::Local.IsAmbiguousTime($end)){throw 'Ambiguous or invalid DST time; clarify before querying free/busy'}
            $minutes=[int](Value $Request 'minutesPerInterval' 30);if($minutes -lt 1 -or $minutes -gt 1440){throw 'minutesPerInterval must be 1..1440'}
            $recipient=$script:Namespace.CreateRecipient([string](Required $Request 'recipient'));if(!$recipient.Resolve()){throw 'Free/busy recipient did not resolve uniquely'}
            $busy=[string]$recipient.FreeBusy($start,$minutes,$true);$needed=[int][Math]::Ceiling(($end-$start).TotalMinutes/$minutes)
            if($busy.Length -lt $needed){throw 'Outlook returned insufficient free/busy intervals for the requested range'}
            $busy=$busy.Substring(0,$needed)
            return @{recipient=$recipient.Name;start=$start.ToString('s');end=$end.ToString('s');timezone=$zone;minutesPerInterval=$minutes;requestedIntervals=$needed;freeBusy=$busy;encoding='Outlook FreeBusy status digits; one per interval (0 free, 1 tentative, 2 busy, 3 out of office; confirm tenant/client mappings for other values)';completeness='local-Outlook-freebusy'}
        }
        'respond' {
            Assert-Approval $Request
            $id=[string](Required $Request 'entryId');$expectedSubject=[string](Required $Request 'expectedSubject');$expectedOrganizer=[string](Required $Request 'expectedOrganizer');$startText=[string](Required $Request 'start');$endText=[string](Required $Request 'end');$zone=[string](Required $Request 'timezone')
            if($zone -ne [TimeZoneInfo]::Local.Id){throw 'timezone must match the Windows local timezone ID; do not silently convert'}
            $start=[DateTime]::ParseExact($startText,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture);$end=[DateTime]::ParseExact($endText,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture)
            if($end -le $start){throw 'end must be after start'}
            if([TimeZoneInfo]::Local.IsInvalidTime($start) -or [TimeZoneInfo]::Local.IsAmbiguousTime($start) -or [TimeZoneInfo]::Local.IsInvalidTime($end) -or [TimeZoneInfo]::Local.IsAmbiguousTime($end)){throw 'Ambiguous or invalid DST time; clarify before responding'}
            $storeId=Value $Request 'storeId';if($storeId){$m=$script:Namespace.GetItemFromID($id,[string]$storeId)}else{$m=$script:Namespace.GetItemFromID($id)}
            if([int]$m.Class -ne 26){throw 'Target is not an Outlook calendar appointment'}
            if([string]$m.Subject -cne $expectedSubject){throw 'Target subject mismatch; no response sent'}
            if([string]$m.Organizer -cne $expectedOrganizer){throw 'Target organizer mismatch; no response sent'}
            if($m.Start.ToString('s') -cne $startText -or $m.End.ToString('s') -cne $endText){throw 'Target local start/end mismatch; no response sent'}
            if([int]$m.MeetingStatus -eq 5){throw 'Cancelled meeting cannot be answered'}
            if([int]$m.MeetingStatus -ne 3){throw 'Target is not a received meeting; organizer or non-meeting items cannot be answered'}
            $responseName=[string](Required $Request 'response')
            $responseCode=switch($responseName){'accept'{3}'tentative'{2}'decline'{4}default{throw 'response must be accept, tentative, or decline'}}
            $currentResponseStatus=[int]$m.ResponseStatus
            $allowAcceptedToDeclined=Value $Request 'allowAcceptedToDeclinedChange' $false
            if($allowAcceptedToDeclined -isnot [bool]){throw 'allowAcceptedToDeclinedChange must be a JSON boolean'}
            if($currentResponseStatus -in @(0,5)){
                if($allowAcceptedToDeclined -or $null -ne (Value $Request 'expectedPriorResponseStatus')){throw 'Accepted-to-declined override applies only to a currently accepted meeting'}
            }elseif($currentResponseStatus -eq 3){
                if($responseName -cne 'decline' -or !$allowAcceptedToDeclined){throw 'Meeting already has a response; accepted-to-declined change requires explicit opt-in'}
                $expectedPriorStatus=Value $Request 'expectedPriorResponseStatus'
                if($expectedPriorStatus -isnot [int] -and $expectedPriorStatus -isnot [long]){throw 'expectedPriorResponseStatus must be the numeric Outlook status authorized for this change'}
                if([int]$expectedPriorStatus -ne 3 -or $currentResponseStatus -ne [int]$expectedPriorStatus){throw 'Current Outlook response status differs from expectedPriorResponseStatus; no response sent'}
            }else{throw 'Meeting already has a response; inspect Outlook instead of responding again'}
            $state=[int]$m.RecurrenceState
            if([bool]$m.IsRecurring -or $state -ne 0){throw 'Recurring meetings and occurrences are not supported for responses; target a non-recurring received meeting'}
            $expectedResponseClass=switch($responseCode){3{56}2{57}4{55}}
            # Snapshot identity before Respond: Outlook can replace the calendar item.
            $targetSnapshot=@{entryId=$m.EntryID;subject=$m.Subject;start=$m.Start.ToString('s');end=$m.End.ToString('s');organizer=$m.Organizer;response=$Request.response;recurrenceState=$state;globalAppointmentId=[string]$m.GlobalAppointmentID}
            # Respond returns a MeetingItem. With fNoUI=true the returned item must
            # be explicitly sent. Mutation starts at Respond, before any possible error.
            $script:MutationAttempted=$true
            $responseItem=$m.Respond([int]$responseCode,$true,$false)
            if($null -eq $responseItem -or [int]$responseItem.Class -ne $expectedResponseClass){throw "Outlook Respond returned unexpected response class; expected $expectedResponseClass"}
            $responseItem.Send()
            return @{items=@($targetSnapshot);verification='submitted-local-meeting-response-not-delivery-confirmed'}
        }
        'create-invite' {
            Assert-Approval $Request
            $zone=[string](Required $Request 'timezone')
            if($zone -ne [TimeZoneInfo]::Local.Id){throw 'timezone must match the Windows local timezone ID; do not silently convert'}
            $text=[string](Required $Request 'start')
            $start=[DateTime]::ParseExact($text,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture)
            $tz=[TimeZoneInfo]::Local
            if($tz.IsInvalidTime($start) -or $tz.IsAmbiguousTime($start)){throw 'Ambiguous or invalid DST time; clarify before creating invite'}
            $duration=[int](Required $Request 'durationMinutes');if($duration -lt 1 -or $duration -gt 1440){throw 'durationMinutes must be 1..1440'}
            $to=@(Required $Request 'attendees');$m=$script:Outlook.CreateItem(1)
            $m.Subject=[string](Required $Request 'subject');$m.Start=$start;$m.Duration=$duration;$m.MeetingStatus=1
            $m.Body=[string](Value $Request 'body' '');$m.Location=[string](Value $Request 'location' '')
            foreach($address in $to){$recipient=$m.Recipients.Add([string]$address);$recipient.Type=1}
            if(!$m.Recipients.ResolveAll()){throw 'Attendee resolution failed; nothing sent'}
            $script:MutationAttempted=$true;$m.Send()
            return @{items=@(@{entryId=$m.EntryID;subject=$m.Subject;start=$start.ToString('s');end=$start.AddMinutes($duration).ToString('s');timezone=$zone});verification='submitted-local-calendar-not-server-confirmed'}
        }
        default {throw 'Supported calendar actions: list, free-busy, create-invite, respond. Event updates/cancellations are not implemented in this draft.'}
    }
}
