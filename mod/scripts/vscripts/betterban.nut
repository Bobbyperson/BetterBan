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
        table data = DecodeJSON( response.body )
        string is_banned = expect string( data["banned"] )
        string banMessage = expect string( data["ban_message"] )

        if ( data.banned == "true" )
        {
            if ( banMessage == "" )
            {
                banMessage = GetConVarString( "disconnect_message" ) 
            }

            NSDisconnectPlayer( player, banMessage )

            print("Kicking player '" + player.GetPlayerName() +"' (UID: " + player.GetUID() + "). Reason: " + banMessage)
        }
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : (player)
    {
        print("Ban check request failed for UID: " + player.GetUID() + " Error: " + failure.errorMessage)
    }

    NSHttpRequest( request, onSuccess, onFailure )
}

void function CheckBans()
{
    foreach ( entity player in GetPlayerArray() )
    {
        BetterBanConnect( player )
    }
}