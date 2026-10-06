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
            foreach($m in $items){if($seen++ -lt $offset){continue};if($rows.Count -ge $limit){$more=$true;break};$rows+=,@{entryId=$m.EntryID;subject=$m.Subject;start=$m.Start.ToString('s');end=$m.End.ToString('s');organizer=$m.Organizer;location=$m.Location;meetingStatus=$m.MeetingStatus}}
            return @{items=$rows;timezone=[TimeZoneInfo]::Local.Id;moreAvailable=$more;offset=$offset;completeness='local-view-page'}
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
        default {throw 'Supported calendar actions: list, create-invite. Updates/cancellations are not implemented in this draft.'}
    }
}
