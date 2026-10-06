function Invoke-Teams($Request) {
    $root='https://graph.microsoft.com/v1.0';$action=Required $Request 'action'
    $limit=Limit $Request
    if($limit -gt 50){throw 'Teams limit must be 1..50'}
    switch($action){
        'joined' {Connect-ExistingGraph;return Graph-Page ($root+'/me/joinedTeams')}
        'channels' {
            Connect-Graph @('Channel.ReadBasic.All')
            $team=[Uri]::EscapeDataString([string](Required $Request 'teamId'))
            return Graph-Page ($root+'/teams/'+$team+'/channels')
        }
        'chats' {Connect-Graph @('Chat.Read');return Graph-Page ($root+'/me/chats?$top='+$limit)}
        'chat-messages' {
            Connect-Graph @('Chat.Read');$chat=[Uri]::EscapeDataString([string](Required $Request 'chatId'))
            return Graph-Page ($root+'/chats/'+$chat+'/messages?$top='+$limit)
        }
        'channel-messages' {
            Connect-Graph @('ChannelMessage.Read.All')
            $team=[Uri]::EscapeDataString([string](Required $Request 'teamId'));$channel=[Uri]::EscapeDataString([string](Required $Request 'channelId'))
            $script:Warnings.Add('Channel message list contains root messages; replies require a separate channel-replies request.')
            return Graph-Page ($root+'/teams/'+$team+'/channels/'+$channel+'/messages?$top='+$limit)
        }
        'channel-replies' {
            Connect-Graph @('ChannelMessage.Read.All')
            $team=[Uri]::EscapeDataString([string](Required $Request 'teamId'));$channel=[Uri]::EscapeDataString([string](Required $Request 'channelId'));$message=[Uri]::EscapeDataString([string](Required $Request 'messageId'))
            return Graph-Page ($root+'/teams/'+$team+'/channels/'+$channel+'/messages/'+$message+'/replies?$top='+$limit)
        }
        {$_ -in @('send-chat','send-channel')} {
            Assert-Approval $Request
            $text=[string](Required $Request 'body')
            if($action -eq 'send-chat'){
                Connect-Graph @('ChatMessage.Send');$chat=[Uri]::EscapeDataString([string](Required $Request 'chatId'));$uri=$root+'/chats/'+$chat+'/messages'
            }else{
                Connect-Graph @('ChannelMessage.Send');$team=[Uri]::EscapeDataString([string](Required $Request 'teamId'));$channel=[Uri]::EscapeDataString([string](Required $Request 'channelId'));$uri=$root+'/teams/'+$team+'/channels/'+$channel+'/messages'
            }
            $script:MutationAttempted=$true;$r=Invoke-Graph 'POST' $uri @{body=@{contentType='text';content=$text}}
            return @{items=@(@{id=$r.id;createdDateTime=$r.createdDateTime;webUrl=(Value $r 'webUrl')});verification='graph-created-message'}
        }
        'page' {
            $uri=[string](Required $Request 'nextLink');Assert-GraphUri $uri;$path=([Uri]$uri).AbsolutePath
            if($path -match '^/v1.0/(me/)?chats') {Connect-Graph @('Chat.Read')}
            elseif($path -match '^/v1.0/teams/.+/channels/.+/messages'){Connect-Graph @('ChannelMessage.Read.All')}
            elseif($path -match '^/v1.0/teams/.+/channels'){Connect-Graph @('Channel.ReadBasic.All')}
            elseif($path -eq '/v1.0/me/joinedTeams'){Connect-ExistingGraph}
            else{throw 'Unsupported Teams continuation path'}
            return Graph-Page $uri
        }
        default {throw 'Unsupported Teams action'}
    }
}
