global function BetterBanInit
global function BetterBanConnect
global function CheckBans

void function BetterBanInit()
{
    AddCallback_OnClientConnecting( BetterBanConnect )
}

void function BetterBanConnect( entity player )
{
    // Construct the GET request
    HttpRequest request = { ... }
    request.method = HttpRequestMethod.GET
    request.url    = "https://relay.awesome.tf/is-banned?uid=" + player.GetUID()

    // Define success callback
    void functionref( HttpRequestResponse ) OnSuccess = void function ( HttpRequestResponse response ) : (player)
    {
        try
        {
            table decoded = DecodeJSON(response.body)

            if ( response.statusCode == 200 && decoded.len() != 0 )
            {
                string banned      = expect string(decoded["banned"])
                string ban_message = expect string(decoded["ban_message"])

                if ( banned.tolower() == "true" )
                {
                    if ( ban_message == "" )
                        ban_message = GetConVarString( "ban_message" )

                    NSDisconnectPlayer( player, ban_message )

                    print("[BetterBan] Kicked player '" + player.GetPlayerName() + "' (UID: " + player.GetUID() + "). Reason: " + ban_message)
                }
            }
            else
            {
                print("[BetterBan] Ban check returned no data or failed. Status: " + response.statusCode + " | Body: " + response.body)
            }
        }
        catch ( exception )
        {
            print("[BetterBan] Error: Failed to decode ban response.")
        }
    }

    void functionref( HttpRequestFailure ) OnFailure = void function ( HttpRequestFailure failure ) : (player)
    {
        print("[BetterBan] Ban check request failed for " + player.GetPlayerName() + " (UID: " + player.GetUID() + ") — Error: " + failure.errorMessage)
    }

    NSHttpRequest( request, OnSuccess, OnFailure )
}


void function CheckBans()
{
    foreach ( entity player in GetPlayerArray() )
    {
        BetterBanConnect( player )
    }
}