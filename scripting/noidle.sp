#define			TEAM_SPECTATOR							1
#define			PLUGIN_VERSION							"0.1"
#define			PLUGIN_CONTACT							"skylorekatja@gmail.com"
#define			PLUGIN_NAME								"No Idle"
#define			PLUGIN_DESCRIPTION						"Removes players from the server if they idle for a set period of time."
#define			CVAR_SHOW								FCVAR_NOTIFY | FCVAR_PLUGIN

#include		<sourcemod>
#include		<sdktools>
#include		"wrap.inc"
#include		"l4d_stocks.inc"

#undef			REQUIRE_PLUGIN
#include		"readyup.inc"

new Handle:g_IdleTime;
new Handle:g_IdleInterval;
new Handle:g_IdleWarning;
new i_IdleTime[MAXPLAYERS + 1];
new Float:Pos[MAXPLAYERS + 1][3];
new Float:Eye[MAXPLAYERS + 1][3];
new bool:b_IsActiveRound;
new String:white[4];
new String:green[4];
new String:blue[4];
new String:orange[4];
new bool:b_IsIdleTimerActive;

public Plugin:myinfo = { name = PLUGIN_NAME, author = PLUGIN_CONTACT, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_CONTACT };

public OnPluginStart() {

	CreateConVar("noidle_version", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("noidle_version"), PLUGIN_VERSION);

	g_IdleTime				= CreateConVar("noidle_kicktime","45","The number of times a player may consecutively fail the idle check before being kicked from the server.", CVAR_SHOW);
	g_IdleInterval			= CreateConVar("noidle_interval","1.0","How far apart (in seconds) each idle check is.", CVAR_SHOW);
	g_IdleWarning			= CreateConVar("noidle_warning","30","The number of idles a player must have to be warned about being removed.", CVAR_SHOW);

	SetConVarInt(FindConVar("noidle_kicktime"), GetConVarInt(g_IdleTime));
	SetConVarFloat(FindConVar("noidle_interval"), GetConVarFloat(g_IdleInterval));
	SetConVarInt(FindConVar("noidle_warning"), GetConVarInt(g_IdleWarning));

	Format(white, sizeof(white), "\x01");
	Format(blue, sizeof(blue), "\x03");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");

	LoadTranslations("noidle.phrases");
}

public OnMapStart() { b_IsIdleTimerActive = false; }

public ReadyUp_TrueDisconnect(client) { i_IdleTime[client] = 0; }

public ReadyUp_IsClientLoaded(client) { i_IdleTime[client] = 0; }

public ReadyUp_RoundIsOver(gamemode) {

	b_IsActiveRound = false;
	LogMessage("Round End, resetting idle times.");
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) i_IdleTime[i] = 0;
	}
}

public ReadyUp_CheckpointDoorStartOpened() {

	b_IsActiveRound = true;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) i_IdleTime[i] = 0;
	}

	if (!b_IsIdleTimerActive) {

		b_IsIdleTimerActive = true;
		CreateTimer(GetConVarFloat(g_IdleInterval), Timer_IdleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_IdleCheck(Handle:timer) {

	if (!b_IsActiveRound) {

		b_IsIdleTimerActive = false;
		return Plugin_Stop;	// we don't check when a round isn't active.
	}

	new Float:NewEye[3];
	new Float:NewPos[3];
	decl String:text[64];
	decl String:name[64];

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == TEAM_SPECTATOR || !IsPlayerAlive(i)) continue;

		GetClientAbsOrigin(i, Float:NewPos);
		GetClientEyeAngles(i, Float:NewEye);

		if (GetVectorDistance(NewEye, Eye[i]) == 0.0 && GetVectorDistance(NewPos, Pos[i]) == 0.0 && L4D2_GetInfectedAttacker(i) == -1) {

			i_IdleTime[i]++;
			GetClientAbsOrigin(i, Pos[i]);
			GetClientEyeAngles(i, Eye[i]);

			if (i_IdleTime[i] == GetConVarInt(g_IdleTime)) {

				GetClientName(i, name, sizeof(name));
				
				ReadyUp_NtvChangeTeam(i, TEAM_SPECTATOR);
				//PrintToChatAll("%t", "player spectator", green, name, white, blue);
				/*if (HasCommandAccess(i, "a") || HasCommandAccess(i, "k") || HasCommandAccess(i, "z")) ReadyUp_NtvChangeTeam(i, TEAM_SPECTATOR);
				else {

					PrintToChatAll("%t", "kick", blue, name, white, orange);
					KickClient(i, "%T", "idle kick", i);
				}*/
			}
			else if (i_IdleTime[i] == GetConVarInt(g_IdleWarning)) {

				PrintToChat(i, "%T", "warning", i, blue, GetConVarInt(g_IdleTime) - i_IdleTime[i], white, green);
				//if (HasCommandAccess(i, "a") || HasCommandAccess(i, "k") || HasCommandAccess(i, "z")) PrintToChat(i, "%T", "warning", i, blue, GetConVarInt(g_IdleTime) - i_IdleTime[i], white, green);
				//else PrintToChat(i, "%T", "kick warning", i, blue, GetConVarInt(g_IdleTime) - i_IdleTime[i], white, green);
			}
		}
		else {

			if (L4D2_GetInfectedAttacker(i) == -1) {

				//	If the client is ensnared, we don't reset their idle time. This way, if an idle client gets ensnared and then released, they still get removed if they dont stop idling.
				i_IdleTime[i] = 0;
			}
			GetClientAbsOrigin(i, Pos[i]);
			GetClientEyeAngles(i, Eye[i]);
		}
	}

	return Plugin_Continue;
}