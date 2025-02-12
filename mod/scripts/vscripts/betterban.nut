global function BetterBanInit
global function BetterBanConnect
global function CheckBans

void function BetterBanInit()
{
    AddCallback_OnClientConnecting( BetterBanConnect )
}

void function BetterBanConnect( entity player )
{
    string apiUrl = GetConVarString( "api_url" )

    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url    = apiUrl + "/is-banned?uid=" + player.GetUID()

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : (player)
    {
        table<string, string> data = DecodeJSON( response.body )

        if ( data["banned"].tolower() == "true" )
        {
            string banMessage = data["ban_message"]
            if ( banMessage == "" )
            {
                banMessage = GetConVarString( "disconnect_message" ) 
            }

            NSDisconnectPlayer( player, banMessage )

            print("Kicking player '" + player.GetPlayerName() +"' (UID: " + player.GetUID() + "). Reason: " + banMessage)
        }
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : (uid)
    {
        print("Ban check request failed for UID: " + uid + " Error: " + failure.error)
    }

    NSHttpRequest( request, onSuccess, onFailure )
}

void function CheckBans()
{
    for ( player in GetPlayers() )
    {
        BetterBanConnect( player )
    }
}