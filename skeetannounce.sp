/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

#define PLUGIN_VERSION "1.4"
#define FL_CUMSKEET 1
#define FL_DEADSTOPS 2
#define FL_ALLSKEET 4
#define HITGROUP_HEAD 1
new pouncing[MAXPLAYERS + 1];
//Skeet damage variables
new damageDone[MAXPLAYERS+1][MAXPLAYERS+1];
new hitsDone[MAXPLAYERS+1][MAXPLAYERS+1];
new headshots[MAXPLAYERS+1][MAXPLAYERS+1];

new String:hitboxNames[8][20] = { "Body", "Head", "Chest", "Stomach", "Left Arm", "Right Arm", "Left Leg", "Right Leg"};

new Handle:hVerbosity;
new Handle:hDeathSkeets;

new bool:bIsL4D2;


new String:l4d_WeaponNames[][] =
{
    "autoshotgun",
    "smg",
    "rifle",
    "pumpshotgun",
	"hunting_rifle",
	"pistol",
	"pipe_bomb",
	"prop_minigun"
}

new String:l4d2_WeaponNames[][] =
{
    "pistol",
    "pistol_magnum",
    "shotgun_chrome",
    "pumpshotgun",
	"autoshotgun",
	"shotgun_spas",
	"smg",
	"smg_silenced",
	"rifle",
	"rifle_ak47",
	"rifle_desert",
	"rifle_sg552",
	"rifle_m60",
	"hunting_rifle",
	"sniper_military",
	"weapon_grenade_launcher",
	"frying_pan",
	"electric_guitar",
	"machete",
	"tonfa",
	"fireaxe",
	"crowbar",
	"baseball_bat",
	"cricket_bat",
	"golfclub",
	"katana",
	"knife",
	"chainsaw",
	"spawnminigun",
	"spawnminigun2"
}

public Plugin:myinfo = 
{
	name = "Skeet Announce",
	author = "n0limit, $atanic $pirit",
	description = "Announces damage done to a hunter during a pounce in midair (skeets) and dead stops",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=923976"
}

public OnPluginStart()
{
	// Checking if its L4D or L4D2
	decl String:GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		bIsL4D2=true;
	else
		bIsL4D2=false;
	
	HookEvent("player_shoved",Event_PlayerShoved);
	HookEvent("player_hurt",Event_PlayerHurt);
	HookEvent("ability_use",Event_AbilityUse);
	HookEvent("player_death",Event_PlayerDeath);
	
	CreateConVar("skeetannounce_version",PLUGIN_VERSION,"SkeetAnnounce Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hVerbosity = CreateConVar("skeetannounce_verbosity","3","The verbosity level of skeet announce. Default is 3.",FCVAR_SPONLY|FCVAR_NOTIFY);
	hDeathSkeets = CreateConVar("skeetannounce_deathskeets","1","Only prints skeet information if the player is killed by the skeet. Otherwise, it prints any damage incured while skeeting. Default is 1.",FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true,"skeetannounce");
}

public Event_PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:attackerName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];
	
	//If the hunter lands on another player's head, they're technically grounded.
	//Instead of using isGrounded, this uses the pouncing[] array with less precise timer
	if(pouncing[victim] && GetConVarInt(hVerbosity) & FL_DEADSTOPS)
	{ //Dead Stop
		GetClientName(victim,victimName,sizeof(victimName));
		GetClientName(attacker,attackerName,sizeof(attackerName));
		PrintToChatAll("[\x03Skeet\x01]%s deadstopped %s",attackerName, victimName);
	}
}


public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(pouncing[user])
	{ 
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new damage = GetEventInt(event,"dmg_health");
		new hitGroup = GetEventInt(event,"hitgroup");
		new String:attackerName[MAX_NAME_LENGTH];
		new String:victimName[MAX_NAME_LENGTH];
		new String: weapon[MAX_NAME_LENGTH];

		GetEventString(event,"weapon",weapon,sizeof(weapon));
		GetClientName(victim,victimName,sizeof(victimName));
		GetClientName(attacker,attackerName,sizeof(attackerName));
		if(isAcceptableWeapon(weapon))
		{
			if(GetConVarInt(hVerbosity) & FL_CUMSKEET)
			{
				damageDone[victim][attacker] += damage;
				hitsDone[victim][attacker]++;
				if(hitGroup == HITGROUP_HEAD)
					headshots[victim][attacker]++;
			}
			if(GetConVarInt(hVerbosity) & FL_ALLSKEET)
				PrintToChatAll("[\x03Skeet\x01]%s skeeted %s in the %s with %s for %d HP",attackerName,victimName,hitboxNames[hitGroup],weapon,damage);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new String:victimName[MAX_NAME_LENGTH];
	new String:playerName[MAX_NAME_LENGTH];
	
	GetClientName(victim,victimName,sizeof(victimName));
	if(!GetConVarBool(hDeathSkeets) || pouncing[victim])
	{
		if(GetConVarInt(hVerbosity) & FL_CUMSKEET)
		{
			for(new i=0; i < MaxClients;i++)
			{
				if(hitsDone[victim][i] > 0)
				{
					GetClientName(i,playerName,sizeof(playerName));
					if(headshots[victim][i] > 0)
						PrintToChatAll("[\x03Skeet\x01]%s skeeted %s, landing %d bullet(s) with %d headshot(s) for %d damage", playerName,victimName,hitsDone[victim][i],headshots[victim][i],damageDone[victim][i]);
					else
						PrintToChatAll("[\x03Skeet\x01]%s skeeted %s, landing %d bullet(s) for %d damage", playerName,victimName,hitsDone[victim][i],damageDone[victim][i]);
					hitsDone[victim][i] = 0;
					damageDone[victim][i] = 0;
					headshots[victim][i] = 0;
				}
			}
		}
	}
}

public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:abilityName[64];
	
	GetEventString(event,"ability",abilityName,sizeof(abilityName));
	if(isClient(user) && strcmp(abilityName,"ability_lunge",false) == 0 && !pouncing[user])
	{
		//Hunter pounce
		pouncing[user] = true;
		CreateTimer(0.5,groundTouchTimer,user,TIMER_REPEAT);
	}
}

public Action:groundTouchTimer(Handle:timer, any:client)
{
	if((isClient(client) && isGrounded(client)) || !IsPlayerAlive(client))
	{
		//Reached the ground or died in mid-air
		pouncing[client] = false;
		KillTimer(timer);
	}
}

public bool:isGrounded(client)
{
	return (GetEntProp(client,Prop_Data,"m_fFlags") & FL_ONGROUND) > 0;
}

public bool:isClient(client)
{
	return IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}

public bool:isAcceptableWeapon(const String:weapon[])
{
	new bool:bIsWeaponFound;
	
	if(bIsL4D2)
	{
		for (new i = 0; i < sizeof(l4d2_WeaponNames); i++) 
		{
			if (StrEqual(l4d2_WeaponNames[i], weapon)) 
			{
				bIsWeaponFound = true;
				break;
			}
		}
	}
	if(!bIsL4D2)
	{	
		for (new i = 0; i < sizeof(l4d_WeaponNames); i++) 
		{
			if (StrEqual(l4d_WeaponNames[i], weapon)) 
			{
				bIsWeaponFound = true;
				break;
			}
		}
	}
	
	if (bIsWeaponFound) {
		return true;
	}
	PrintToChatAll("[\x03Skeet\x01]Could not find weapon name")
	return false;	
}