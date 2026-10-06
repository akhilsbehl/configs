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
