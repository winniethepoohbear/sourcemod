#define			TEAM_SURVIVOR							2
#define			TEAM_INFECTED							3
#define			PLUGIN_VERSION							"0.1"
#define			PLUGIN_CONTACT							"skylorekatja@gmail.com"
#define			PLUGIN_NAME								"Infected Bot Spawner"
#define			PLUGIN_DESCRIPTION						"Spawns infected bots based on respawn timer"
#define			CVAR_SHOW								FCVAR_NOTIFY | FCVAR_PLUGIN

#include		<sourcemod>
#include		<sdktools>

#undef			REQUIRE_PLUGIN
#include		"readyup.inc"

#include		"wrap.inc"

new bool:b_IsActiveRound;

public Plugin:myinfo = { name = PLUGIN_NAME, author = PLUGIN_CONTACT, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_CONTACT };

public OnPluginStart() {

	CreateConVar("infectedbots_version", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("infectedbots_version"), PLUGIN_VERSION);

	RegAdminCmd("startbots", CMD_StartBots, ADMFLAG_ROOT);
}

public Action:CMD_StartBots(client, args) {

	b_IsActiveRound = true;
	CreateTimer(GetRandomInt(GetConVarInt(FindConVar("z_ghost_delay_min")), GetConVarInt(FindConVar("z_ghost_delay_max"))) * 1.0, Timer_SpawnInfectedBots, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public ReadyUp_CheckpointDoorStartOpened() {

	if (ReadyUp_GetGameMode() != 2) {

		b_IsActiveRound = true;
		CreateTimer(GetRandomInt(GetConVarInt(FindConVar("z_ghost_delay_min")), GetConVarInt(FindConVar("z_ghost_delay_max"))) * 1.0, Timer_SpawnInfectedBots, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else {

		b_IsActiveRound = true;
		CreateTimer(1.0, Timer_RemoveInfectedBots, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RemoveInfectedBots(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && IsFakeClient(i) && !IsGhost(i) && FindZombieClass(i) != 8) ForcePlayerSuicide(i);
	}

	return Plugin_Continue;
}

public Action:Timer_SpawnInfectedBots(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	new Survivors				=	SurvivorCount();
	new Zombies					=	InfectedCount();

	if (Survivors > Zombies) Zombies = Survivors - Zombies;

	for (new i = Zombies; i > 0 && TotalPlayers() < MAXPLAYERS && b_IsActiveRound; i--) SpawnInfectedBot();

	CreateTimer(GetRandomInt(GetConVarInt(FindConVar("z_ghost_delay_min")), GetConVarInt(FindConVar("z_ghost_delay_max"))) * 1.0, Timer_SpawnInfectedBots, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

stock TotalPlayers() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) count++;
	}
	return count;
}

public ReadyUp_RoundIsOver(gamemode) {

	b_IsActiveRound = false;
}

stock SpawnInfectedBot() {

	new bot						=	CreateFakeClient("InfectedBot");
	if (bot > 0) {

		new num					=	GetRandomInt(1, 6);
		if (num == 1) ExecCheatCommand(bot, "z_spawn_old", "hunter auto");
		if (num == 2) ExecCheatCommand(bot, "z_spawn_old", "smoker auto");
		if (num == 3) ExecCheatCommand(bot, "z_spawn_old", "boomer auto");
		if (num == 4) ExecCheatCommand(bot, "z_spawn_old", "jockey auto");
		if (num == 5) ExecCheatCommand(bot, "z_spawn_old", "spitter auto");
		if (num == 6) ExecCheatCommand(bot, "z_spawn_old", "charger auto");

		CreateTimer(0.1, Timer_KickInfectedBot, bot, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock InfectedCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_INFECTED) Count++;
	}

	return Count;
}

stock SurvivorCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}

	return Count;
}

stock GetValidClient() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i)) return i;
	}

	return 0;
}

public Action:Timer_KickInfectedBot(Handle:timer, any:bot) {

	if (IsClientConnected(bot) && IsFakeClient(bot)) {

		KickClient(bot);
	}

	return Plugin_Stop;
}