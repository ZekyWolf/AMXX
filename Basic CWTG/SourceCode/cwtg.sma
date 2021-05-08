#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < cstrike >
#include < stripweapons >
#include < csx >
#define CC_COLORS_TYPE CC_COLORS_SHORT
#include < cromchat >

#if AMXX_VERSION_NUM < 183
	#error Please update your AMX Mod X to version 1.8.3 or higher
#endif

#define PLUGIN_NAME               "CWTG System"
#define PLUGIN_AUTHOR             "PlayAsPro.net & Zeky"
#define PLUGIN_VERSION            "1.2"

/*=============================================================================
							SOME PLUGIN DEFINES
=============================================================================*/
#define DEFAULTPASSWORD     "gneu"
#define TASK_CHANGEMAP      16498494

/*=============================================================================
							PREFIX
=============================================================================*/
static const tag[] = "!n[!gBasicCWTG!n]"

/*=============================================================================
							VARIABLES
=============================================================================*/
new admin[ 33 ]
new Match, Rozohra, KnifeRound
new CTRounds, TRounds

new autokick
new maxplayers
new pauza
new HalfTime
//HUD SYNC
new iHudSync[4];

new Array:Loaded_maps, iTimerDelay = 1

/*=============================================================================
							PLUGIN INIT
=============================================================================*/
public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	//HUD SYNC
	for(new i = 0; i < sizeof(iHudSync); i++){ iHudSync[i] = CreateHudSyncObj(); }

	RegCommand("admin", "cmd_admin")
	
	register_concmd( "cttestrounds", "testct" )
	register_concmd( "ttestrounds", "testt" )
	
	register_event("SendAudio", "t_win", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "ct_win", "a", "2&%!MRAD_ctwin")
	
	register_event( "CurWeapon","cur_weapon","be","1=1" )
	
	Match = autokick = pauza = HalfTime = 0;
	
	maxplayers = get_maxplayers( );

	server_cmd("sv_password ^"%s^"", DEFAULTPASSWORD);

	Loaded_maps = ArrayCreate(50, 1);
	LOADMAPS();
}
public testct( ) { CTRounds = 15; }
public testt( ) { TRounds = 15; }
/*=============================================================================
							Welcome Msg
=============================================================================*/
public WelcomeMsg( id ) 
{
	if( admin[ id ] == 0 ) 
	{
		set_hudmessage(0, 128, 0, -1.0, 0.20, 2, 1.0, 6.0, 0.1, 0.1)
		ShowSyncHudMsg(id, iHudSync[1], "Welcome on GameNation.eu | CWTG ^nIf no one is admin of server, write /admin!^n Good Luck & Have Fun !")
	}
}
/*=============================================================================
							Connect + Disconnect
=============================================================================*/
public client_putinserver( id )
{
	new sid[ 32 ], name[ 32 ]
	get_user_name( id, name ,31 )
	get_user_authid( id, sid, 31 )
	CromChat( 0, "%s !g|!b Player: %s !n(!g%s!n) !bis connecting", tag, name, sid )
	
	set_task( 3.0, "WelcomeMsg", id )
	
	if( autokick == 1 ) 
	{
		server_cmd( "kick #%d ^"Autokick is enabled !^"", get_user_userid( id ) )
	}
	admin[ id ] = 0
}

public client_disconnected( id ) 
{
	new sid[ 32 ], name[ 32 ]
	get_user_name( id, name ,31 )
	get_user_authid( id, sid, 31 )
	CromChat( 0, "%s !g|!b Player: !g%s !n(!g%s!n) is disconnecting", tag, name, sid )
	
	new adminname[ 32 ]
	get_user_name( id, adminname, 31 )
	if( admin[ id ] )
	{
		CromChat( 0, "%s !g|!r Player: !g%s!r is no longer admin...", tag, adminname )
		admin[ id ] = 0
		if( autokick == 1 ) {
			autokick = 0
		}
			
		if( pauza == 1 ) {
			pauza = 0
			server_cmd( "amx_pause" )
		}
	}
}
/*=============================================================================
							Knife Round
=============================================================================*/
public cur_weapon( id )
{
	if( Match == 1 ){
		return PLUGIN_HANDLED
	}
	
	new weapon = read_data(2)
	
	if(weapon == CSW_C4){
		return PLUGIN_HANDLED
	}
	
	if( weapon != CSW_KNIFE ){
		if( Rozohra == 0 && KnifeRound == 1 ){
			engclient_cmd( id,"weapon_knife" )
		}
	}
		
	return PLUGIN_CONTINUE
}
/*=============================================================================
							Wins
=============================================================================*/
public t_win( )
{
	new rnd = CTRounds + TRounds
	if( rnd == 30 ) 
	{
		Match = KnifeRound = Rozohra = 0;
		set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
		show_dhudmessage( 0, "DRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW" );
		set_task( 2.0, "round_restart" );
		set_task( 4.0, "round_restart" );
		set_task( 6.0, "round_restart" );
		server_cmd( "mp_roundtime 5.00" );
		server_cmd( "mp_startmoney 16000" );
		server_cmd( "mp_freezetime 0" );
				
		for( new i = 0; i < 3; i++ )
		{
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
		}
			
		for( new i = 0; i < 3; i++ ) 
		{
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
		}
	}
	
	if( TRounds == 16 ) 
	{
		Match = KnifeRound = Rozohra = 0;
		set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
		show_dhudmessage( 0, "TERRORIST WIN -- TERRORIST WIN -- TERRORIST WIN^nTERRORIST WIN -- TERRORIST WIN -- TERRORIST WIN" );
		set_task( 2.0, "round_restart" );
		set_task( 4.0, "round_restart" );
		set_task( 6.0, "round_restart" );
		server_cmd( "mp_roundtime 5.00" );
		server_cmd( "mp_startmoney 16000" );
		server_cmd( "mp_freezetime 0" );
				
		for( new i = 0; i < 3; i++ )
		{
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
		}
			
		for( new i = 0; i < 3; i++ ) 
		{
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
		}
	}
	
	if( Match == 1 ) 
	{
		if( HalfTime == 1 ) 
		{
			CTRounds++;
			set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
			ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
		}else{
			TRounds++;
			set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
			ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
		}
	}
	
	if( ( CTRounds + TRounds ) == 15 ) 
	{
		if( HalfTime == 0 ) 
		{
			HalfTime = 1;
			set_task( 2.0, "round_restart" );
			set_task( 4.0, "round_restart" );
			set_task( 6.0, "round_restart" );
			server_cmd( "mp_roundtime 3.75" );
			server_cmd( "mp_startmoney 800" );
			server_cmd( "mp_freezetime 8" );
			for(new i = 0; i < 3; i++ ) 
			{
				CromChat( 0, "%s !g|!g GH !r--!g GH !r-- !gGH", tag );
			}
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);

			new players[32], num, i
			get_players( players, num )
			for(i = 0; i < num; i++ ){ add_delay( players[i] ); }
		}
	}
}

public ct_win( )
{
	new rnd = CTRounds + TRounds
	
	if( rnd == 30 ) 
	{
		Match = KnifeRound = Rozohra = 0;
		set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
		show_dhudmessage( 0, "DRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW" );
		set_task( 2.0, "round_restart" );
		set_task( 4.0, "round_restart" );
		set_task( 6.0, "round_restart" );
		server_cmd( "mp_roundtime 5.00" );
		server_cmd( "mp_startmoney 16000" );
		server_cmd( "mp_freezetime 0" );
				
		for( new i = 0; i < 3; i++ )
		{
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
		}
			
		for( new i = 0; i < 3; i++ ) 
		{
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
		}
	}
	
	if( CTRounds == 16 ) 
	{
		Match = KnifeRound = Rozohra = 0;
		set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
		show_dhudmessage( 0, "COUNTERTERRORISTS WIN -- COUNTERTERRORISTS WIN -- COUNTERTERRORISTS WIN^nCOUNTERTERRORISTS WIN -- COUNTERTERRORISTS WIN -- COUNTERTERRORISTS WIN" );
		set_task( 2.0, "round_restart" );
		set_task( 4.0, "round_restart" );
		set_task( 6.0, "round_restart" );
		server_cmd( "mp_roundtime 5.00" );
		server_cmd( "mp_startmoney 16000" );
		server_cmd( "mp_freezetime 0" );
				
		for( new i = 0; i < 3; i++ )
		{
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
			CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
		}
			
		for( new i = 0; i < 3; i++ ) 
		{
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
			CromChat( 0, "%s !g|!g GG !r--!g GG !r-- !gGG", tag );
		}
	}
	
	if( Match == 1 ) 
	{
		if( HalfTime == 1 ) 
		{
			CTRounds++;
			set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
			ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
		}else{
			TRounds++;
			set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
			ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
		}
	}
	
	if( ( CTRounds + TRounds ) == 15 ) 
	{
		if( HalfTime == 0 ) 
		{
			HalfTime = 1;
			set_task( 2.0, "round_restart" );
			set_task( 4.0, "round_restart" );
			set_task( 6.0, "round_restart" );
			server_cmd( "mp_roundtime 3.75" );
			server_cmd( "mp_startmoney 800" );
			server_cmd( "mp_freezetime 8" );
			for( new i = 0; i < 3; i++ ) 
			{
				CromChat( 0, "%s !g|!r !!! !gGH !w| !gGH !w| !gGH !r!!!", tag )
			}
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			CromChat(0, "%s !g|!g*** !bCHANGING TEAM !g--!b CHANGING TEAM !g***", tag);
			new players[32], num, i
			get_players( players, num )
			for(i = 0; i < num; i++ ){ add_delay( players[i] ); }
		}
	}
}
/*=============================================================================
							Team Switch
=============================================================================*/
add_delay( id )
{
	switch( id )
	{
		case 1..7: set_task( 0.1, "fnSwitchTeams", id );
		case 8..15: set_task( 0.2, "fnSwitchTeams", id );
		case 16..23: set_task( 0.3, "fnSwitchTeams", id );
		case 24..32: set_task( 0.4, "fnSwitchTeams", id );
	}
}
public fnSwitchTeams( id ) 
{
	switch( cs_get_user_team( id ) )
	{
		case CS_TEAM_CT: cs_set_user_team( id, CS_TEAM_T )
		case CS_TEAM_T: cs_set_user_team( id, CS_TEAM_CT )
	}
}
public round_restart( ) 
{
	server_cmd( "sv_restartround 1" )
	for( new id = 0; id < maxplayers; id++ ) 
	{
		if(is_user_connected(id)){
			cs_set_user_deaths( id, 0 );
			set_user_frags( id, 0 );
		}
	}
	message_begin(MSG_ALL,get_user_msgid("TeamScore"))
	write_string("TERRORIST")
	write_short(0)
	message_end()

	message_begin(MSG_ALL,get_user_msgid("TeamScore"))
	write_string("CT")
	write_short(0)
	message_end()
}
/*=============================================================================
							Admin + Menu
=============================================================================*/
public cmd_admin(id)
{
	new adminname[ 32 ]
	get_user_name( id, adminname, 31 )
	if(!is_somebody_admin())
	{
		admin[id] = 1;
		admin_menu(id);
		
		if( get_user_flags( id ) & ADMIN_KICK ){
			return PLUGIN_HANDLED
		}else{	
			CromChat( 0, "%s !g|!r %s!r is now server admin !", tag, adminname )
			CromChat( 0, "%s !g|!r %s!r is now server admin !", tag, adminname )
			CromChat( 0, "%s !g|!r %s!r is now server admin !", tag, adminname )
		}
	}else{	
		if(admin[id]){
			admin_menu(id)
		}else{
			CromChat( id,"%s !g|!r One admin is already here !", tag )
		}
	}
	return PLUGIN_HANDLED
}
public admin_menu( id )
{
	new name[ 32 ]
	get_user_name( id, name, 31 )
	if( admin[ id ] || get_user_flags( id ) & ADMIN_KICK ) 
	{
		new am = menu_create( "\yCWTG Administration : \d", "adminmenu_Handler" )
		
		menu_additem( am, "\wStart Match", "1");
		menu_additem( am, "\rStop Match", "2");
		menu_additem( am, "\wStart PreMatch", "3");
		menu_additem( am, "\wStart Knife Round", "4");
		menu_additem( am, "\wChange Map", "5");
		menu_additem( am, "\wKick Player", "6");
		menu_additem( am, "\wMore Options", "7");
		
		menu_display( id, am )
		
	} 
	else if( !admin[ id ] || !(get_user_flags( id ) & ADMIN_KICK ) ) 
	{
		CromChat( id, "%s !g|!rYou are not allowed to open Admin Menu !", tag )
	}
	return PLUGIN_HANDLED
}

public adminmenu_Handler( id, menu, item ) 
{
    if(item == MENU_EXIT || !admin[id])
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data)
	switch( key ) 
	{
		case 1: 
		{
			if( Match == 0 ) 
			{
				Match = 1;
				CTRounds = TRounds = 0;
				set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
				show_dhudmessage( 0, "MATCH HAS BEEN STARTED -- MATCH HAS BEEN STARTED^nMATCH HAS BEEN STARTED -- MATCH HAS BEEN STARTED" );
				set_task( 2.0, "round_restart" );
				set_task( 4.0, "round_restart" );
				set_task( 6.0, "round_restart" );
				server_cmd( "mp_roundtime 3.75" );
				server_cmd( "mp_startmoney 800" );
				server_cmd( "mp_freezetime 4" );
				
				for( new i = 0; i < 3; i++ )
				{
					CromChat(0, "%s !g|!b MATCH HAS BEEN STARTED ", tag);
					CromChat(0, "%s !g|!b MATCH HAS BEEN STARTED ", tag);
					CromChat(0, "%s !g|!b MATCH HAS BEEN STARTED ", tag);
				}		
			}else{
				CromChat( id, "%s !g|!r Match is already started...", tag )
				admin_menu( id )
			}
		}
		case 2: 
		{
			if( Match == 1 ) 
			{
				Match = CTRounds = TRounds = KnifeRound = Rozohra = 0;
				set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
				show_dhudmessage( 0, "MATCH END -- MATCH END^nMATCH END -- MATCH END^nMATCH END -- MATCH END" );
				set_task( 2.0, "round_restart" );
				set_task( 4.0, "round_restart" );
				set_task( 6.0, "round_restart" );
				server_cmd( "mp_roundtime 5.00" );
				server_cmd( "mp_startmoney 16000" );
				server_cmd( "mp_freezetime 0" );
				
				for( new i = 0; i < 3; i++ )
				{
					CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
					CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
					CromChat( 0, "%s !g|!r MATCH END -- MATCH END", tag );
				}		
			}else{
				CromChat( id, "%s !g|!r Cant start match, match already end...", tag )
				admin_menu( id )
			}
		}
		case 3: 
		{
			if( Match == 0 ) 
			{
				Match = CTRounds = TRounds = KnifeRound = 0;
				Rozohra = 1;
				set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 );
				show_dhudmessage( 0, "DRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW^nDRAW -- DRAW -- DRAW" );
				set_task( 2.0, "round_restart" );
				set_task( 4.0, "round_restart" );
				set_task( 6.0, "round_restart" );
				server_cmd( "mp_roundtime 5.00" );
				server_cmd( "mp_startmoney 16000" );
				server_cmd( "mp_freezetime 0" );
				
				for( new i = 0; i < 3; i++ )
				{
					CromChat(0, "%s !g|!r DRAW -- DRAW -- DRAW", tag);
					CromChat(0, "%s !g|!r DRAW -- DRAW -- DRAW", tag);
					CromChat(0, "%s !g|!r DRAW -- DRAW -- DRAW", tag);
				}		
			}else{
				CromChat( id, "%s !g|!rCant start Pre-Match, Match already start", tag )
				admin_menu( id )
			}
		}
		case 4: 
		{
			if( Match == 0 ) 
			{
				CTRounds = TRounds = Rozohra = 0;
				KnifeRound = 1;
				set_dhudmessage( 0, 255, 0, -1.0, 0.20,0, 1.0, 2.0 )
				show_dhudmessage( 0, "KNIFE ROUND -- KNIFE ROUND -- KNIFE ROUND^nKNIFE ROUND -- KNIFE ROUND -- KNIFE ROUND" )
				set_task( 2.0, "round_restart" )
				server_cmd( "mp_roundtime 3.75" )
				server_cmd( "mp_startmoney 16000" )
				server_cmd( "mp_freezetime 1.0" )
				engclient_cmd(0,"weapon_knife")
				
				for( new i = 0; i < 3; i++ )
				{
					CromChat(0, "%s !g|!b KNIFE ROUND -- KNIFE ROUND -- KNIFE ROUND", tag);
					CromChat(0, "%s !g|!b KNIFE ROUND -- KNIFE ROUND -- KNIFE ROUND", tag);
					CromChat(0, "%s !g|!b KNIFE ROUND -- KNIFE ROUND -- KNIFE ROUND", tag);
				}		
			}else{
				CromChat( id, "%s !g|!r Cant start Knife Round, because Match is started", tag )
				admin_menu( id )
			}
		}
		case 5: 
		{
			if( Match == 0 ) 
			{
				Maps_menu(id);
			}else{
				admin_menu( id )
				CromChat( id, "%s !g|!r Cant change map, becuase match is started !", tag )
			}
		}
		case 6:{ showkickmenu( id ); }
		case 7:{ adminmenu_more( id ); }
	}
	return PLUGIN_HANDLED
}

public adminmenu_more( id ) 
{
	new am = menu_create( "\yCWTG Administration : \d", "adminmenumore_Handler" )
	
	if( autokick == 1 ){
		menu_additem( am, "\wAutoKick \d|\yENABLED\d|", "1");
	}else{
		menu_additem( am, "\wAutoKick \d|\rDISABLED\d|", "1");
	}
	if( pauza == 1 ) {
		menu_additem( am, "\wPause \d|\yENABLED\d|", "2" );
	}else {
		menu_additem( am, "\wPause \d|\rDISABLED\d|", "2" );
	}
	menu_additem( am, "\wShow Score^n", "3" )
	menu_additem( am, "\rGive up the admin", "4")
		
	menu_display( id, am, 0 )
}

public adminmenumore_Handler( id, menu, item ) 
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data)
	switch( key ) 
	{
		case 1: 
		{
			adminmenu_more( id )
			new  name[ 32 ]
			get_user_name( id, name, 31 )
			
			if( autokick == 1 ) 
			{
				autokick = 0;
				CromChat( 0, "%s !g|!r Admin !g%s!r !gDisabled!r AutoKick", tag, name );
				adminmenu_more( id );
			}else{
				if( Match == 1 ) 
				{
					autokick = 1;
					CromChat( 0, "%s !g|!r Admin !g%s!r !gEnabled!r AutoKick", tag, name );
					adminmenu_more( id )
				}else{
					CromChat( id, "%s !g|!r Cant turn on autokick !", tag )
				}
			}
		}
		case 2: 
		{
			new  name[ 32 ]
			get_user_name( id, name, 31 )
			if( pauza == 1 ) 
			{
				pauza = 0
				server_cmd( "amx_pause" )
				CromChat( 0, "%s !g|!b Admin !g%s!b deaktivoval PAUZU !", tag, name )
				adminmenu_more( id )
			} 
			else 
			{
				pauza = 1
				server_cmd( "amx_pause" )
				CromChat( 0, "%s !g|!r Admin !g%s!r aktivoval PAUZU !", tag, name )
				adminmenu_more( id )
			}
		}
		case 3: 
		{
			if( Match == 1 ){
				showscore( id );
			}else{
				CromChat( id, "%s !g|!r Match is not started !", tag )
				adminmenu_more( id )
			}
		}
        case 4: 
		{
			new  name[ 32 ]
			get_user_name( id, name, 31 )
			CromChat( 0, "%s !g|!r Player !g%s!r give up admin !", tag, name )
			admin[ id ] = 0
		}
	}
	return PLUGIN_HANDLED
}
/*=============================================================================
							Show Score
=============================================================================*/
public showscore( id ) 
{
	if( HalfTime == 0 ) 
	{
		CTRounds++;
		set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
		ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
	}else{
		TRounds++;
		set_hudmessage(0, 191, 255, -1.0, 0.5, 1, 1.0, 5.0, 0.1, 0.1 );
		ShowSyncHudMsg(0, iHudSync[0], "-->>> CounterTerrorists: %i <<< --- >>> Terrorists: %i <<<--", CTRounds, TRounds);
	}
}
/*=============================================================================
							KICK MENU
=============================================================================*/
public showkickmenu( id ) 
{
	new menu = menu_create( "\yChoose Player", "showkickmenu_handler" );

	new players[32], pnum, tempid;
	new szName[32], szUserId[32];
	get_players( players, pnum); 
	for ( new i; i<pnum; i++ )
	{
		tempid = players[i];

		if(id != tempid)
		{
			get_user_name( tempid, szName, charsmax( szName ) );
			formatex( szUserId, charsmax( szUserId ), "%d", get_user_userid( tempid ) );
			menu_additem( menu, szName, szUserId, 0 );
		}
	}
	menu_display( id, menu, 0 );
}
public showkickmenu_handler( id, menu ,item ) 
{
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new iAdmin = admin[ id ]
	new adminname[ 32 ]
	
	get_user_name( iAdmin, adminname, 31 )

	if( !admin[ id ] ){ return PLUGIN_HANDLED; }
	
	new szData[6], szName[64];
	new item_access, item_callback;
	menu_item_getinfo( menu, item, item_access, szData,charsmax( szData ), szName,charsmax( szName ), item_callback );
	
	new userid = str_to_num( szData ),
        player = find_player( "k", userid ),
        playername[ 32 ];

	get_user_name( player, playername, 31 )

	if(player)
	{
		server_cmd("kick #%d You has been kicked out from this server !",get_user_userid(player))
		CromChat( 0, "%s !g|!r Player !g%s!r has been kicked from server by !g%s", tag, playername, adminname )
	}
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}
/*=============================================================================
							MAPS LOAD/MENU + DELAY CHANGE
=============================================================================*/
public LOADMAPS()
{
	new iFile[64], iMapDir[64];
	formatex(iMapDir, charsmax(iMapDir), "maps/")
	if(dir_exists(iMapDir))
	{
		new iDir =  open_dir(iMapDir, iFile, charsmax(iFile))
		while( next_file(iDir, iFile, charsmax(iFile)))
		{
			if(ValidMap(iFile))
			{
				ArrayPushString(Loaded_maps, iFile)
			}
		}
		close_dir(iDir)
	}else{
		log_amx("Maps dir dont exist !");
	}
}
public Maps_menu(id)
{		
	new mapnum = ArraySize(Loaded_maps)
	
	if(!mapnum)
	{
		return PLUGIN_HANDLED
	}
	new menu = menu_create("Maps:","Maps_menu_handle")
	
	new text[128], iNum[3]
	for(new i;i < mapnum;i++)
	{
		ArrayGetString(Loaded_maps, i, text, charsmax(text))
		num_to_str(i, iNum, charsmax(iNum))
		menu_additem(menu, text, iNum, 0)
	}
	menu_display(id,menu,0)
	
	return PLUGIN_HANDLED
}
public Maps_menu_handle(id,menu,item)
{
	if(item < 0)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[64], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, 63, iName, 63, callback);
	new key = str_to_num(data);
	new map_name[32];
	ArrayGetString(Loaded_maps, key, map_name, charsmax(map_name))
	
	iTimerDelay = 8;
	set_task(2.0, "DelayChange", TASK_CHANGEMAP, map_name, charsmax(map_name), "a", 8);
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public DelayChange(mapname[])
{
	iTimerDelay--

	set_hudmessage( 125, 125, 0, -1.0, 0.25, 0, 0.0, 1.0, 0.7, 0.7 )
	ShowSyncHudMsg( 0, iHudSync[3], "<< -- Map has been change to -- >>^n<< -- %s -- >>^n<< -- after -- >>^n<< -- %i -- >>^n<< -- second -- >>", mapname, iTimerDelay ) 

	if( iTimerDelay == 0 ){
		server_cmd( "changelevel %s", mapname )
	}
}
/*=============================================================================
							STOCKS
=============================================================================*/
stock is_somebody_admin( )
{
	new players[ 32 ], num, i
	get_players( players, num, "ch" )
	for( i = 0; i < num; i++ )
	{
		if( admin[ players[ i ] ] == 1 ){
			return 1;
		}
	}
	return 0;
}
stock bool:ValidMap(mapname[])
{
	if(is_map_valid(mapname))
	{
		return true;
	}
	new len = strlen(mapname) - 4;
	if(len < 0)
	{
		return false;
	}
	if(equali(mapname[len], ".bsp"))
	{
		mapname[len] = '^0';
		if(is_map_valid(mapname))
		{
			return true;
		}
	}
	return false;
}
stock RegCommand(command[], function[], flags = -1, console = false)
{
	new text[128]
	new ii[][] = { "say !", "say .", "say /", "say_team !", "say_team .", "say_team /" }
	for(new i = 0; i < sizeof(ii); i++){
		formatex(text, charsmax(text), "%s%s", ii[i], command);
		register_clcmd(text, function, flags);
		if(console){
			register_concmd(command, function, flags);
		}
	}
}