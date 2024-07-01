global function BetterBanInit

struct {
    entity player
    string uid
    string data
} file

void function BetterBanInit()
{
    AddCallback_OnClientConnected( BetterBanConnect )
    AddCallback_OnClientConnecting( BetterBanConnect )
    AddClientCommandCallback("bban", BanlistAdd);
    AddClientCommandCallback("bunban", BanlistRemove);
    AddClientCommandCallback("bbanuid", BanlistAddUID);
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
    file.uid = player.GetUID()
    file.player = player
    NSLoadFile( "banlist.txt", SuccessBanFile, FailBanFile )
}

void function SuccessBanFile( string data )
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
        if ( line == file.uid )
        {
            print( "Player " + file.player.GetPlayerName() + " is banned" )
            //Chat_ServerBroadcast( "Player " + file.player.GetPlayerName() + " is whitelisted" )
            string message = GetConVarString( "disconnect_message" )
            NSDisconnectPlayer( file.player, message )
            return
        }
    }
    // string message = GetConVarString( "disconnect_message" )
    // NSDisconnectPlayer( file.player, message )
    // Chat_ServerBroadcast( "Player " + file.player.GetPlayerName() + " was kicked for not being whitelisted" )
}

void function FailBanFile()
{
    print( "Failed to load banlist.txt, does the file exist?" )
}

// =============
// commands
// =============

bool function BanlistAdd(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Kprint( player, "You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Kprint( player, "Usage: bban <name>" )
        return false
    }

    string uid = CheckPlayerName( args[0] )
    if ( uid == "null" )
    {
        Kprint( player, "No player found with that name." )
        return false
    }
    else if ( uid == "multiple" )
    {
        Kprint( player, "Multiple players found with that name, try to type it out exactly instead." )
        return false
    }
    else if ( CheckRepeatedUID( uid ) )
    {
        Kprint( player, "That player is already on the banlist." )
        return false
    }

    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    BannedCheck( player )
    Kprint( player, "Alright done." )
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
    printt( "Alright done." )
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
    return true
}
    

bool function BanlistAddUID(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Kprint( player,"You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Kprint( player, "Usage: bbanuid <uid>" )
        return false
    }
    string uid = args[0]
    if ( CheckRepeatedUID( uid ) )
    {
        Kprint( player, "That player is already on the banlist." )
        return false
    }
    file.data += "\n" + uid
    NSSaveFile( "banlist.txt", file.data )
    BannedCheck( player )
    Kprint( player, "Alright done." )
    return true
}

bool function BanlistRemove(entity player, array<string> args)
{
    if (!CheckBanlistAdmin( player ))
    {
        Kprint( player,"You do not have permission to use this command." )
        return false
    }
    if ( args.len() != 1 )
    {
        Kprint( player, "Usage: bunban <uid>" )
        return false
    }

    string uid = args[0]
    if ( !CheckRepeatedUID( uid ) )
    {
        Kprint( player, "That player is not banned." )
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

    NSSaveFile( "banlist.txt", data )
    Kprint( player, "Alright done." )
    return true
}

// =============
// utility functions
// =============

bool function CheckBanlistAdmin( entity player )
{
    string cvar = GetConVarString( "grant_admin" )

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