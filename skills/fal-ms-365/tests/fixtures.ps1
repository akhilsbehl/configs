$ErrorActionPreference='Stop'
$base=Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
# Parse every script without executing its entry point.
foreach($p in Get-ChildItem -LiteralPath $base -Filter '*.ps1'){
    $tokens=$null;$errors=$null;$null=[Management.Automation.Language.Parser]::ParseFile($p.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($p.Name+': '+($errors|Out-String))}
}
. (Join-Path $base 'common.ps1')
foreach($name in @('mail','calendar','directory','files','teams')){. (Join-Path $base ($name+'.ps1'))}
function Assert($Condition,[string]$Name){if(!$Condition){throw "FAIL: $Name"};Write-Output "PASS: $Name"}
function Throws([scriptblock]$Call,[string]$Pattern){try{& $Call|Out-Null}catch{if($_.Exception.Message -like $Pattern){return $true};throw};return $false}
Assert (Throws {Assert-Approval ([pscustomobject]@{})} '*approved=true*') 'write guard rejects missing approval'
Assert (Throws {Assert-Approval ([pscustomobject]@{approved='true'})} '*approved=true*') 'write guard rejects string approval'
Assert-Approval ([pscustomobject]@{approved=$true})
Assert ((Safe-Name '../folder\CON.pdf') -notmatch '[\\/]') 'attachment names flatten traversal'
Assert ((Safe-Name 'CON.pdf') -eq '_CON.pdf') 'reserved Windows names escaped'
Assert (Throws {Limit ([pscustomobject]@{limit=101})} '*1..100*') 'page limit bounded'
Assert (Throws {Offset ([pscustomobject]@{offset=-1})} '*nonnegative*') 'offset bounded'
Assert (Throws {Assert-GraphUri 'https://evil.example/v1.0/users'} '*graph.microsoft.com*') 'bearer destination allowlist'
Assert (Throws {Assert-GraphUri 'http://graph.microsoft.com/v1.0/users'} '*graph.microsoft.com*') 'Graph HTTPS required'
# Mock COM boundary. No real COM object is created or attached.
function Connect-Outlook {}
function Get-MailFolder($Request){return $script:FakeFolder}
function Mail-Summary($m,$Folder){return @{class=$m.Class;subject=$m.Subject;entryId=$m.EntryID}}
$script:FakeItems=[pscustomobject]@{Count=2;Rows=@([pscustomobject]@{Class=43;Subject='Mail';EntryID='mail-id'},[pscustomobject]@{Class=53;Subject='Invite';EntryID='invite-id'});LastFilter=$null}
$script:FakeItems|Add-Member ScriptMethod Sort {param($field,$descending)}
$script:FakeItems|Add-Member ScriptMethod Restrict {param($filter);$this.LastFilter=$filter;return $this}
$script:FakeItems|Add-Member ScriptMethod Item {param($i);return $this.Rows[$i-1]}
$script:FakeFolder=[pscustomobject]@{Items=$script:FakeItems;UnReadItemCount=2}
$r=Invoke-Mail ([pscustomobject]@{action='list';unreadOnly=$true;limit=25})
Assert ($r.items.Count -eq 2 -and $r.items[1].class -eq 53) 'unread list retains meeting requests'
$r=Invoke-Mail ([pscustomobject]@{action='list';limit=1;offset=1})
Assert ($r.items.Count -eq 1 -and $r.items[0].entryId -eq 'invite-id') 'COM offset page'
$r=Invoke-Mail ([pscustomobject]@{action='search';query="O'Brien";limit=1})
Assert ($script:FakeItems.LastFilter.Contains("O''Brien")) 'subject filter escapes single quotes'
Assert (Throws {Invoke-Mail ([pscustomobject]@{action='send';approved=$false})} '*approved=true*') 'mail send blocked before object creation'
Assert (Throws {Invoke-Calendar ([pscustomobject]@{action='create-invite';approved=$false})} '*approved=true*') 'calendar invite blocked before object creation'
$script:Zone=[TimeZoneInfo]::Local.Id
Assert (Throws {Invoke-Calendar ([pscustomobject]@{action='create-invite';approved=$true;timezone='INVALID'})} '*Windows local timezone*') 'invite timezone mismatch rejected'
# Calendar COM fakes: no live Outlook attachment and no external writes.
$script:TestStart=[DateTime]::Today.AddDays(7).AddHours(10).ToString('yyyy-MM-ddTHH:mm:ss')
$script:TestEnd=[DateTime]::Today.AddDays(7).AddHours(11).ToString('yyyy-MM-ddTHH:mm:ss')
$script:FakeAppointment=[pscustomobject]@{Class=26;EntryID='occurrence-id';Subject='Planning';Start=[DateTime]::ParseExact($script:TestStart,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture);End=[DateTime]::ParseExact($script:TestEnd,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture);Organizer='organizer@example.com';MeetingStatus=3;ResponseStatus=0;IsRecurring=$false;RecurrenceState=0;GlobalAppointmentID='global-occurrence-id';Location='Room';OriginalDate=$null;LastResponseCode=$null;LastNoUI=$null;LastAdditionalTextDialog=$null;RespondThrows=$false;RespondCallCount=0;ForceClassMismatch=$false}
$script:FakeMeetingResponse=[pscustomobject]@{Class=53;SendCalled=$false;SendThrows=$false}
$script:FakeMeetingResponse|Add-Member ScriptMethod Send {if($this.SendThrows){throw 'mock Send failure'};$this.SendCalled=$true}
$script:FakeAppointment|Add-Member ScriptMethod Respond {param($response,$noUI,$extraText);$this.RespondCallCount++;$this.LastResponseCode=$response;$this.LastNoUI=$noUI;$this.LastAdditionalTextDialog=$extraText;if($this.RespondThrows){throw 'mock Respond failure'};if($this.ForceClassMismatch){$script:FakeMeetingResponse.Class=53}else{$script:FakeMeetingResponse.Class=switch([int]$response){3{56}2{57}4{55}}};return $script:FakeMeetingResponse}
$script:FakeNamespace=[pscustomobject]@{Target=$script:FakeAppointment;LastStore=$null;LastRecipient=$null}
$script:FakeNamespace|Add-Member ScriptMethod GetItemFromID {param($id,$store);$this.LastStore=$store;if($id -ne $this.Target.EntryID){throw 'not found'};return $this.Target}
$script:FakeNamespace|Add-Member ScriptMethod CreateRecipient {param($name);$this.LastRecipient=$name;$r=[pscustomobject]@{Name=$name};$r|Add-Member ScriptMethod Resolve {return $true};$r|Add-Member ScriptMethod FreeBusy {param($start,$minutes,$complete);return ('0123'*500)};return $r}
$script:Namespace=$script:FakeNamespace
$script:Outlook=[pscustomobject]@{CreateItem={}}
$script:MutationAttempted=$false
$baseRequest=@{action='respond';approved=$true;entryId='occurrence-id';expectedSubject='Planning';expectedOrganizer='organizer@example.com';start=$script:TestStart;end=$script:TestEnd;timezone=[TimeZoneInfo]::Local.Id;response='accept'}
$r=Invoke-Calendar ([pscustomobject]$baseRequest)
Assert ($r.items[0].recurrenceState -eq 0 -and $r.verification -eq 'submitted-local-meeting-response-not-delivery-confirmed') 'response returns non-recurring target identity and bounded outcome'
Assert ($script:FakeAppointment.LastResponseCode -eq 3 -and $script:FakeAppointment.LastNoUI -eq $true -and $script:FakeAppointment.LastAdditionalTextDialog -eq $false) 'accept calls Respond(olMeetingAccepted, true, false)'
Assert ($script:FakeMeetingResponse.Class -eq 56 -and $script:FakeMeetingResponse.SendCalled) 'accept response returns class 56 and sends MeetingItem'
$script:FakeMeetingResponse.SendCalled=$false;$baseRequest.response='tentative';$r=Invoke-Calendar ([pscustomobject]$baseRequest)
Assert ($script:FakeAppointment.LastResponseCode -eq 2 -and $script:FakeMeetingResponse.Class -eq 57 -and $script:FakeMeetingResponse.SendCalled) 'tentative returns class 57 and sends MeetingItem'
$script:FakeMeetingResponse.SendCalled=$false;$baseRequest.response='decline';$r=Invoke-Calendar ([pscustomobject]$baseRequest)
Assert ($script:FakeAppointment.LastResponseCode -eq 4 -and $script:FakeMeetingResponse.Class -eq 55 -and $script:FakeMeetingResponse.SendCalled) 'decline returns class 55 and sends MeetingItem'
$script:FakeMeetingResponse.SendCalled=$false;$baseRequest.response='accept';$script:MutationAttempted=$false
$script:FakeAppointment.ForceClassMismatch=$true
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*expected 56*') 'unexpected returned response class rejected before Send'
Assert ($script:MutationAttempted -and !$script:FakeMeetingResponse.SendCalled) 'class mismatch is an unknown outcome and is not sent'
$script:FakeAppointment.ForceClassMismatch=$false;$script:MutationAttempted=$false
$script:FakeMeetingResponse.SendThrows=$true
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*mock Send failure*') 'returned MeetingItem.Send failure surfaces'
Assert ($script:MutationAttempted -and !$script:FakeMeetingResponse.SendCalled) 'Send failure is classified as unknown mutation outcome'
$script:FakeMeetingResponse.SendThrows=$false
$script:FakeAppointment.RespondThrows=$true;$script:MutationAttempted=$false
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*mock Respond failure*') 'Respond failure surfaces'
Assert ($script:MutationAttempted) 'Respond failure is classified as unknown mutation outcome'
$script:FakeAppointment.RespondThrows=$false;$script:MutationAttempted=$false
$script:FakeAppointment.ResponseStatus=3
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*already has a response*') 'duplicate response blocked by current response status'
$script:FakeAppointment.ResponseStatus=0
$countBeforeApproval=$script:FakeAppointment.RespondCallCount
Assert (Throws {Invoke-Calendar ([pscustomobject]@{action='respond';approved=$false})} '*approved=true*') 'response blocked without exact user approval'
Assert ($script:FakeAppointment.RespondCallCount -eq $countBeforeApproval) 'approval guard prevents response method call'
$baseRequest.response='decline';$script:FakeAppointment.ResponseStatus=3
$countBeforeOverride=$script:FakeAppointment.RespondCallCount
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*explicit opt-in*') 'accepted-to-declined change blocked without explicit opt-in'
Assert ($script:FakeAppointment.RespondCallCount -eq $countBeforeOverride) 'absent opt-in never reaches Respond'
$baseRequest.allowAcceptedToDeclinedChange=$true;$baseRequest.expectedPriorResponseStatus=5
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*differs from expectedPriorResponseStatus*') 'stale expected prior status rejected'
$baseRequest.expectedPriorResponseStatus=3;$baseRequest.expectedOrganizer='wrong@example.com'
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*organizer mismatch*') 'override cannot bypass exact organizer check'
$baseRequest.expectedOrganizer='organizer@example.com'
$script:FakeMeetingResponse.SendCalled=$false;$r=Invoke-Calendar ([pscustomobject]$baseRequest)
Assert ($script:FakeAppointment.LastResponseCode -eq 4 -and $script:FakeMeetingResponse.Class -eq 55 -and $script:FakeMeetingResponse.SendCalled) 'explicit accepted-to-declined override submits negative response'
$script:FakeAppointment.ResponseStatus=0;$baseRequest.response='decline';$baseRequest.Remove('allowAcceptedToDeclinedChange');$baseRequest.Remove('expectedPriorResponseStatus')
$script:FakeAppointment.IsRecurring=$true;$script:FakeAppointment.RecurrenceState=1
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*Recurring meetings and occurrences are not supported*') 'recurring series response rejected'
$script:FakeAppointment.RecurrenceState=3
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*Recurring meetings and occurrences are not supported*') 'individual recurring occurrence response rejected'
$script:FakeAppointment.IsRecurring=$false;$script:FakeAppointment.RecurrenceState=0;$baseRequest.start=$script:TestStart;$baseRequest.end=([DateTime]::ParseExact($script:TestEnd,'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture).AddHours(1).ToString('yyyy-MM-ddTHH:mm:ss'))
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*start/end mismatch*') 'stale or wrong occurrence rejected before response'
$baseRequest.end=$script:TestEnd
$script:FakeAppointment.MeetingStatus=1;$baseRequest.start=$script:TestStart
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*not a received meeting*') 'organiser item cannot be responded to'
$script:FakeAppointment.MeetingStatus=3
$baseRequest.expectedOrganizer='wrong@example.com'
Assert (Throws {Invoke-Calendar ([pscustomobject]$baseRequest)} '*organizer mismatch*') 'organizer mismatch rejected'
$baseRequest.expectedOrganizer='organizer@example.com'
$r=Invoke-Calendar ([pscustomobject]@{action='free-busy';recipient='person@example.com';start=$script:TestStart;end=$script:TestEnd;timezone=[TimeZoneInfo]::Local.Id})
Assert ($r.freeBusy.Length -eq 2 -and $r.requestedIntervals -eq 2) 'free/busy result is clipped to explicit local range'
Assert (Throws {Invoke-Calendar ([pscustomobject]@{action='free-busy';recipient='person@example.com';start=$script:TestStart;end=$script:TestEnd;timezone='INVALID'})} '*Windows local timezone*') 'free/busy timezone mismatch rejected'
# Mock Graph and auth boundaries. No network/auth operations.
function Connect-ExistingGraph {}
function Connect-Graph([string[]]$Scopes) {$script:LastScopes=$Scopes}
function Invoke-Graph([string]$Method,[string]$Uri,$Body=$null){$script:LastUri=$Uri;$script:LastBody=$Body;return $script:GraphFixture}
$script:GraphFixture=[pscustomobject]@{value=@([pscustomobject]@{id='one'});'@odata.nextLink'='https://graph.microsoft.com/v1.0/me/chats?$skiptoken=next'}
$r=Invoke-Teams ([pscustomobject]@{action='chats';limit=25})
Assert ($r.items.Count -eq 1 -and $r.nextLink -like '*skiptoken*') 'Graph page retains continuation'
Assert ($script:LastScopes -contains 'Chat.Read') 'chat read scope selected'
Assert (Throws {Invoke-Teams ([pscustomobject]@{action='chats';limit=51})} '*1..50*') 'Teams endpoint limit capped at 50'
Assert (Throws {Invoke-Teams ([pscustomobject]@{action='send-chat';approved=$false})} '*approved=true*') 'Teams send blocked'
Assert (Throws {Invoke-Teams ([pscustomobject]@{action='page';nextLink='https://evil.example/v1.0/me/chats'})} '*graph.microsoft.com*') 'unsafe continuation rejected'
$script:GraphFixture=[pscustomobject]@{value=@([pscustomobject]@{hitsContainers=@([pscustomobject]@{hits=@([pscustomobject]@{rank=1;summary='match';resource=[pscustomobject]@{name='deck.pptx';id='item';webUrl='https://tenant.sharepoint.com/deck';parentReference=[pscustomobject]@{driveId='drive'}}});total=2;moreResultsAvailable=$true})})}
$r=Invoke-Files ([pscustomobject]@{action='search';query='AI Governance';offset=25;limit=25})
Assert ($r.items.Count -eq 1 -and $r.moreAvailable -and $r.offset -eq 25) 'file search paging and IDs'
Assert ($script:LastBody.requests[0].from -eq 25) 'search request offset passed'
$script:GraphFixture=[pscustomobject]@{name='file.pdf';'@microsoft.graph.downloadUrl'='https://secret.example/token'}
$r=Invoke-Files ([pscustomobject]@{action='metadata';driveId='drive';itemId='item'})
Assert ($null -eq $r.items[0].PSObject.Properties['@microsoft.graph.downloadUrl']) 'metadata does not expose preauthenticated URL'
Write-Output 'PowerShell fixtures completed; no Outlook writes or network calls.'
