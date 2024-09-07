global function BetterBanInit
global function ConsoleBanlistAdd
global function ConsoleBanlistAddUID
global function ConsoleBanlistRemove

struct {
    string data
} file

void function BetterBanInit()
{
    AddCallback_OnClientConnected( BetterBanConnect )
    AddCallback_OnClientConnecting( BetterBanConnect )
    AddClientCommandCallback("bban", BanlistAdd)
    AddClientCommandCallback("bunban", BanlistRemove)
    AddClientCommandCallback("bbanuid", BanlistAddUID)

    RefreshFileData()

    #if PARSEABLE_LOGS
    AddCallback_GameStateEnter( eGameState.WaitingForPlayers, ReportBans )
    #endif

    thread PlayerCheckLoop()
}

void function BetterBanConnect( entity player )
{

    if ( !NSDoesFileExist( "banlist.txt" ) )
    {
        print( "banlist.txt does not exist, creating it now" )
        NSSaveFile( "banlist.txt", "" )
    }
    BannedCheck( player )
}

void function BannedCheck( entity player )
{

    void functionref( string ) SuccessBanFile = void function ( string data ) : (player)
    {
        if ( file.data != data )
            file.data = data

        // separate by newlines
        array<string> lines = split( data, "\n" )
        if ( lines.len() == 0 )
        {
            print( "banlist.txt is empty" )
            return
        }

        foreach ( string line in lines )
        {
            if ( line == player.GetUID() )
            {
                print( "Player " + player.GetPlayerName() + " is banned" )
                string message = GetConVarString( "disconnect_message" )
                NSDisconnectPlayer( player, message )
                return
            }
        }
    }

    void functionref( ) FailBanFile = void function ()
    {
        print( "Failed to load banlist.txt" )
    }

    NSLoadFile( "banlist.txt", SuccessBanFile, FailBanFile )
}
// =============
// commands
// =============

bool function BanlistAdd(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Chat_ServerPrivateMessage( player, "You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Chat_ServerPrivateMessage( player, "Usage: bban <name>" )
        return false
    }

    string uid = CheckPlayerName( args[0] )
    if ( uid == "null" )
    {
        Chat_ServerPrivateMessage( player, "No player found with that name." )
        return false
    }
    else if ( uid == "multiple" )
    {
        Chat_ServerPrivateMessage( player, "Multiple players found with that name, try to type it out exactly instead." )
        return false
    }
    else if ( CheckRepeatedUID( uid ) )
    {
        Chat_ServerPrivateMessage( player, "That player is already on the banlist." )
        return false
    }

    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    entity banee = GetPlayerByUID( uid )
    if ( banee == null )
    {
        Chat_ServerPrivateMessage( player, "Something went wrong kicking the player, try to kick them manually." )
        return false
    }
    BannedCheck( banee )
    Chat_ServerPrivateMessage( player, "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}

bool function ConsoleBanlistAdd( array<string> args )
{
    string uid = CheckPlayerName( args[0] )
    if ( uid == "null" )
    {
        printt( "No player found with that name." )
        return false
    }
    else if ( uid == "multiple" )
    {
        printt( "Multiple players found with that name, try to type it out exactly instead." )
        return false
    }
    else if ( CheckRepeatedUID( uid ) )
    {
        printt( "That player is already on the banlist." )
        return false
    }
    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    entity banee = GetPlayerByUID( uid )
    if ( banee == null )
    {
        printt( "Something went wrong kicking the player, try to kick them manually." )
        return false
    }
    BannedCheck( banee )
    printt( "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}

bool function ConsoleBanlistRemove( array<string> args )
{
    string uid = args[0]
    if ( !CheckRepeatedUID( uid ) )
    {
        printt( "That player is not banned." )
        return false
    }
    RefreshFileData()
    string data = ""
    foreach ( string line in split( file.data, "\n" ) )
    {
        if ( line != uid )
        {
            data += line
            if ( line != "" )
                data += "\n"
        }
    }
    file.data = data
    NSSaveFile( "banlist.txt", file.data )
    printt( "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}

bool function ConsoleBanlistAddUID( array<string> args )
{
    string uid = args[0]
    if ( CheckRepeatedUID( uid ) )
    {
        printt( "That player is already on the banlist." )
        return false
    }
    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    thread CheckAllPlayers()
    printt( "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}
    

bool function BanlistAddUID(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Chat_ServerPrivateMessage( player,"You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Chat_ServerPrivateMessage( player, "Usage: bbanuid <uid>" )
        return false
    }
    string uid = args[0]
    if ( CheckRepeatedUID( uid ) )
    {
        Chat_ServerPrivateMessage( player, "That player is already on the banlist." )
        return false
    }
    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    thread CheckAllPlayers()
    Chat_ServerPrivateMessage( player, "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}

bool function BanlistRemove(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Chat_ServerPrivateMessage( player,"You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Chat_ServerPrivateMessage( player, "Usage: bunban <uid>" )
        return false
    }
    RefreshFileData()
    string uid = args[0]
    if ( !CheckRepeatedUID( uid ) )
    {
        Chat_ServerPrivateMessage( player, "That player is not banned." )
        return false
    }

    string data = ""
    array<string> lines = split( file.data, "\n" )
    for ( int i = lines.len() - 1; i >= 0; i--  )
    {
        if ( lines[i] == uid )
            lines.remove(i)
        else 
            data += lines[i] + "\n"
    }
    file.data = data
    NSSaveFile( "banlist.txt", data )
    Chat_ServerPrivateMessage( player, "Alright done." )
    #if PARSEABLE_LOGS
    ReportBans()
    #endif
    return true
}

// =============
// utility functions
// =============

bool function CheckBanlistAdmin( entity player )
{
    string cvar = GetConVarString( "bb_grant_admin" )

	array<string> admins = split( cvar, "," )
	foreach ( string admin in admins )
    {
		StringReplace( admin, " ", "" )
        if ( admin == player.GetUID() )
        {
            return true
        }
    }
    return false
}

string function CheckPlayerName( string name )
{
    array<entity> players = GetPlayerArray()
    array<entity> matchingplayers = [];
    foreach (entity player in players)
    {
        if (player != null)
        {
            string playername = player.GetPlayerName()
            if (playername.tolower().find(name.tolower()) != null)
            {
                print("Detected " + playername + "!")
                matchingplayers.append(player)
            }
        }
    }
    if (matchingplayers.len() == 0)
    {
        return "null"
    }
    else if (matchingplayers.len() == 1)
    {
        return matchingplayers[0].GetUID()
    }
    else
    {
        return "multiple"
    }
    unreachable
}

bool function CheckRepeatedUID( string uid )
{
    array<string> lines = split( file.data, "\n" )
    foreach ( string line in lines )
    {
        if ( line == uid )
        {
            return true
        }
    }
    return false
}

entity function GetPlayerByUID( string uid )
{
    array<entity> players = GetPlayerArray()
    foreach ( entity player in players )
    {
        if ( player.GetUID() == uid )
        {
            return player
        }
    }
    return null
}

void function PlayerCheckLoop()
{
    while (GetGameState() != eGameState.Postmatch)
    {
        wait 30.0 
        thread CheckAllPlayers()
    }
}

void function CheckAllPlayers()
{
    wait 1.0
    array<entity> players = GetPlayerArray()
    foreach ( entity player in players )
    {
        BannedCheck( player )
    }
}

void function RefreshFileData()
{
    NSLoadFile( "banlist.txt", SuccessRefresh, FailureRefresh )
}

void function SuccessRefresh( string data )
{
    file.data = data
}

void function FailureRefresh()
{
    print("Failed to load banlist.txt")
}

#if PARSEABLE_LOGS
void function ReportBans()
{
    if ( !NSDoesFileExist( "banlist.txt" ) )
    {
        print( "banlist.txt does not exist, creating it now" )
        NSSaveFile( "banlist.txt", "" )
    }
    if (GetGameState() != eGameState.Playing && GetGameState() != eGameState.Prematch && GetGameState() != eGameState.WaitingForPlayers){
        return
    }
    NSLoadFile( "banlist.txt", SuccessBanReport, FailureBanReport )
}

void function SuccessBanReport( string data )
{
    if ( file.data != data )
        file.data = data
    log_custom("banlist", data)
}

void function FailureBanReport()
{
    print("Failed to load banlist.txt")
}
#endif