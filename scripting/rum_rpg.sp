#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAX_ENTITIES		2048
#define MAX_CHAT_LENGTH		1024
#define PLUGIN_VERSION		"2.0.2"
#define PLUGIN_CONTACT		"michaeltoth.85@gmail.com"
#define PLUGIN_NAME			"SkyRPG"
#define PLUGIN_DESCRIPTION	"A modular RPG plugin that reads user-generated config files"
#define PLUGIN_URL			"github.com/exskye"
//#define CONFIG_MAIN					"rpg/config.cfg"
#define CONFIG_EVENTS				"rpg/events.cfg"
#define CONFIG_MAINMENU				"rpg/mainmenu.cfg"
#define CONFIG_MENUSURVIVOR			"rpg/survivormenu.cfg"
#define CONFIG_MENUINFECTED			"rpg/infectedmenu.cfg"
#define CONFIG_POINTS				"rpg/points.cfg"
#define CONFIG_MAPRECORDS			"rpg/maprecords.cfg"
#define CONFIG_STORE				"rpg/store.cfg"
#define CONFIG_TRAILS				"rpg/trails.cfg"
#define CONFIG_CHATSETTINGS			"rpg/chatsettings.cfg"

#define LOGFILE				"rum_rpg.txt"
#define DEBUG				false
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#define ZOMBIECLASS_SMOKER											1
#define ZOMBIECLASS_BOOMER											2
#define ZOMBIECLASS_HUNTER											3
#define ZOMBIECLASS_SPITTER											4
#define ZOMBIECLASS_JOCKEY											5
#define ZOMBIECLASS_CHARGER											6
#define ZOMBIECLASS_TANK											8
#define ZOMBIECLASS_SURVIVOR										0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <l4d2_direct>
#include "wrap.inc"
#include "left4downtown.inc"
#include "l4d_stocks.inc"

#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

new String:currentCampaignName[64];
new Float:g_MapFlowDistance;
new Handle:h_KilledPosition_X[MAXPLAYERS + 1];
new Handle:h_KilledPosition_Y[MAXPLAYERS + 1];
new Handle:h_KilledPosition_Z[MAXPLAYERS + 1];
new bool:bIsEligibleMapAward[MAXPLAYERS + 1];
new String:ChatSettingsName[MAXPLAYERS + 1][64];
new Handle:a_ChatSettings;
new Handle:ChatSettings[MAXPLAYERS + 1];
new bool:b_ConfigsExecuted;
new bool:b_FirstLoad;
new bool:b_MapStart;
new bool:b_HardcoreMode[MAXPLAYERS + 1];
new PreviousRoundIncaps[MAXPLAYERS + 1];
new RoundIncaps[MAXPLAYERS + 1];
new RoundDeaths[MAXPLAYERS + 1];
new String:CONFIG_MAIN[64];
new bool:b_HandicapLocked[MAXPLAYERS + 1];
new bool:b_IsCampaignComplete;
new bool:b_IsRoundIsOver;
new bool:b_IsCheckpointDoorStartOpened;
new bool:b_IsSavingInfectedBotData;
new bool:b_IsLoadingInfectedBotData;
new resr[MAXPLAYERS + 1];
new LastPlayLength[MAXPLAYERS + 1];
new RestedExperience[MAXPLAYERS + 1];
new bool:bIsLoadedBotData;
new MapRoundsPlayed;
new String:LastSpoken[MAXPLAYERS + 1][512];
new Handle:RPGMenuPosition[MAXPLAYERS + 1];
new bool:b_ActiveThisRound[MAXPLAYERS + 1];
new bool:b_IsInSaferoom[MAXPLAYERS + 1];
new Handle:hDatabase												=	INVALID_HANDLE;
new String:ConfigPathDirectory[64];
new HandicapLevel[MAXPLAYERS + 1];
new bool:bSaveData[MAXPLAYERS + 1];
new String:PurchaseSurvEffects[MAXPLAYERS + 1][64];
new String:PurchaseTalentName[MAXPLAYERS + 1][64];
new PurchaseTalentPoints[MAXPLAYERS + 1];
new Handle:a_Trails;
new Handle:TrailsKeys[MAXPLAYERS + 1];
new Handle:TrailsValues[MAXPLAYERS + 1];
new bool:b_IsFinaleActive;
new bool:b_IsVehicleReady;
new RoundDamage[MAXPLAYERS + 1];
new String:MVPName[64];
new MVPDamage;
new RoundDamageTotal;
new SpecialsKilled;
new CommonsKilled;
new SurvivorsKilled;
new Handle:BoosterKeys[MAXPLAYERS + 1];
new Handle:BoosterValues[MAXPLAYERS + 1];
new Handle:StoreChanceKeys[MAXPLAYERS + 1];
new Handle:StoreChanceValues[MAXPLAYERS + 1];
new Handle:StoreItemNameSection[MAXPLAYERS + 1];
new Handle:StoreItemSection[MAXPLAYERS + 1];
new String:PathSetting[64];
new Handle:SaveSection[MAXPLAYERS + 1];
new OriginalHealth[MAXPLAYERS + 1];
new bool:b_IsLoadingStore[MAXPLAYERS + 1];
new LoadPosStore[MAXPLAYERS + 1];
new Handle:LoadStoreSection[MAXPLAYERS + 1];
new SlatePoints[MAXPLAYERS + 1];
new FreeUpgrades[MAXPLAYERS + 1];
new Handle:StoreTimeKeys[MAXPLAYERS + 1];
new Handle:StoreTimeValues[MAXPLAYERS + 1];
new Handle:StoreKeys[MAXPLAYERS + 1];
new Handle:StoreValues[MAXPLAYERS + 1];
new Handle:StoreMultiplierKeys[MAXPLAYERS + 1];
new Handle:StoreMultiplierValues[MAXPLAYERS + 1];
new Handle:a_Store_Player[MAXPLAYERS + 1];
new bool:b_IsLoadingTrees[MAXPLAYERS + 1];
new bool:b_IsArraysCreated[MAXPLAYERS + 1];
new Handle:a_Store;
new PlayerUpgradesTotal[MAXPLAYERS + 1];
new Float:f_TankCooldown;
new Float:DeathLocation[MAXPLAYERS + 1][3];
new TimePlayed[MAXPLAYERS + 1];
new bool:b_IsLoading[MAXPLAYERS + 1];
new LastLivingSurvivor;
new Float:f_OriginEnd[MAXPLAYERS + 1][3];
new Float:f_OriginStart[MAXPLAYERS + 1][3];
new t_Distance[MAXPLAYERS + 1];
new t_Healing[MAXPLAYERS + 1];
new bool:b_IsActiveRound;
new bool:b_IsFirstPluginLoad;
new String:s_rup[32];
new bool:b_ClearedAdt;
new Handle:MainKeys;
new Handle:MainValues;
new Handle:a_Menu_Talents_Survivor;
new Handle:a_Menu_Talents_Infected;
new Handle:a_Menu_Talents_Passives;
new Handle:a_Menu_Main;
new Handle:a_Events;
new Handle:a_Points;
new Handle:a_Database_Talents;
new Handle:a_Database_Talents_Defaults;
new Handle:a_Database_Talents_Defaults_Name;
new Handle:MenuKeys[MAXPLAYERS + 1];
new Handle:MenuValues[MAXPLAYERS + 1];
new Handle:MenuSection[MAXPLAYERS + 1];
new Handle:TriggerKeys[MAXPLAYERS + 1];
new Handle:TriggerValues[MAXPLAYERS + 1];
new Handle:TriggerSection[MAXPLAYERS + 1];
new Handle:AbilityKeys[MAXPLAYERS + 1];
new Handle:AbilityValues[MAXPLAYERS + 1];
new Handle:AbilitySection[MAXPLAYERS + 1];
new Handle:ChanceKeys[MAXPLAYERS + 1];
new Handle:ChanceValues[MAXPLAYERS + 1];
new Handle:ChanceSection[MAXPLAYERS + 1];
new Handle:EventSection;
new Handle:HookSection;
new Handle:CallKeys;
new Handle:CallValues;
//new Handle:CallSection;
new Handle:DirectorKeys;
new Handle:DirectorValues;
//new Handle:DirectorSection;
new Handle:DatabaseKeys;
new Handle:DatabaseValues;
new Handle:DatabaseSection;
new Handle:a_Database_PlayerTalents_Bots;
new Handle:PlayerAbilitiesCooldown_Bots;
new Handle:PlayerAbilitiesImmune_Bots;
new Handle:BotSaveKeys;
new Handle:BotSaveValues;
new Handle:BotSaveSection;
new Handle:LoadDirectorSection;
new Handle:QueryDirectorKeys;
new Handle:QueryDirectorValues;
new Handle:QueryDirectorSection;
new Handle:FirstDirectorKeys;
new Handle:FirstDirectorValues;
new Handle:FirstDirectorSection;
new Handle:a_Database_PlayerTalents[MAXPLAYERS + 1];
new Handle:PlayerAbilitiesName;
new Handle:PlayerAbilitiesCooldown[MAXPLAYERS + 1];
new Handle:PlayerAbilitiesImmune[MAXPLAYERS + 1];
//new Handle:PlayerInventory[MAXPLAYERS + 1];
new Handle:a_DirectorActions;
new Handle:a_DirectorActions_Cooldown;
new PlayerLevel[MAXPLAYERS + 1];
new PlayerLevelUpgrades[MAXPLAYERS + 1];
new TotalTalentPoints[MAXPLAYERS + 1];
new ExperienceLevel[MAXPLAYERS + 1];
new SkyPoints[MAXPLAYERS + 1];
new String:MenuSelection[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
new Float:Points[MAXPLAYERS + 1];
new DamageAward[MAXPLAYERS + 1][MAXPLAYERS + 1];
new DefaultHealth[MAXPLAYERS + 1];
new String:white[4];
new String:green[4];
new String:blue[4];
new String:orange[4];
new bool:b_IsBlind[MAXPLAYERS + 1];
new bool:b_IsImmune[MAXPLAYERS + 1];
new Float:DamageMultiplier[MAXPLAYERS + 1];
new Float:DamageMultiplierBase[MAXPLAYERS + 1];
new Float:SpeedMultiplier[MAXPLAYERS + 1];
new Float:SpeedMultiplierBase[MAXPLAYERS + 1];
new bool:b_IsJumping[MAXPLAYERS + 1];
new Handle:g_hEffectAdrenaline = INVALID_HANDLE;
new Handle:g_hCallVomitOnPlayer = INVALID_HANDLE;
new Handle:hRevive = INVALID_HANDLE;
new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:g_hCreateAcid = INVALID_HANDLE;
new Float:GravityBase[MAXPLAYERS + 1];
new bool:b_GroundRequired[MAXPLAYERS + 1];
new CoveredInBile[MAXPLAYERS + 1][MAXPLAYERS + 1];
new CommonKills[MAXPLAYERS + 1];
new CommonKillsHeadshot[MAXPLAYERS + 1];
new String:OpenedMenu[MAXPLAYERS + 1][64];
new Strength[MAXPLAYERS + 1];
new Luck[MAXPLAYERS + 1];
new Agility[MAXPLAYERS + 1];
new Technique[MAXPLAYERS + 1];
new Endurance[MAXPLAYERS + 1];
new ExperienceOverall[MAXPLAYERS + 1];
new String:CurrentTalentLoading_Bots[64];
//new Handle:a_Database_PlayerTalents_Bots;
//new Handle:PlayerAbilitiesCooldown_Bots;				// Because [designation] = ZombieclassID
new Strength_Bots;
new Luck_Bots;
new Agility_Bots;
new Technique_Bots;
new Endurance_Bots;
new ExperienceLevel_Bots;
new ExperienceOverall_Bots;
new PlayerLevelUpgrades_Bots;
new PlayerLevel_Bots;
new TotalTalentPoints_Bots;
new Float:Points_Director;
new Handle:CommonInfectedQueue;
new g_oAbility = 0;
new Handle:g_hSetClass = INVALID_HANDLE;
new Handle:g_hCreateAbility = INVALID_HANDLE;
new Handle:gd = INVALID_HANDLE;
//new Handle:DirectorPurchaseTimer = INVALID_HANDLE;
new bool:b_IsDirectorTalents[MAXPLAYERS + 1];
new LoadPos_Bots;
new LoadPos[MAXPLAYERS + 1];
new LoadPos_Director;
new Handle:g_Steamgroup;
new Handle:g_Tags;
new RoundTime;
new g_iSprite = 0;
new g_BeaconSprite = 0;
//new bool:b_FirstClientLoaded;

public Action:CMD_DropWeapon(client, args) {

	new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	decl String:EntityName[64];
	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

	new Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);

	Origin[2] += 64.0;

	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);

	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	if (!AcceptEntityInput(CurrentEntity, "Kill")) RemoveEdict(CurrentEntity);

	return Plugin_Handled;
}

public Action:CMD_OpenRPGMenu(client, args) {

	BuildMenu(client);
	//SaveAndClear(-1, true);
	return Plugin_Handled;
}

public Action:CMD_LoadBotData(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) ClearAndLoadBot();
	return Plugin_Handled;
}

public Action:CMD_LoadData(client, args) {

	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	ClearAndLoad(key);
	return Plugin_Handled;
}

public Action:CMD_SaveData(client, args) {

	SaveAndClear(client);
	return Plugin_Handled;
}

public OnPluginStart()
{
	CreateConVar("rum_rpg", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_rpg"), PLUGIN_VERSION);

	g_Steamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(g_Steamgroup, GetConVarFlags(g_Steamgroup) & ~FCVAR_NOTIFY);
	g_Tags = FindConVar("sv_tags");
	SetConVarFlags(g_Tags, GetConVarFlags(g_Tags) & ~FCVAR_NOTIFY);

	SetConVarFlags(FindConVar("z_common_limit"), GetConVarFlags(FindConVar("z_common_limit")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_reserved_wanderers"), GetConVarFlags(FindConVar("z_reserved_wanderers")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mega_mob_size"), GetConVarFlags(FindConVar("z_mega_mob_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mob_spawn_max_size"), GetConVarFlags(FindConVar("z_mob_spawn_max_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mob_spawn_finale_size"), GetConVarFlags(FindConVar("z_mob_spawn_finale_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mega_mob_spawn_max_interval"), GetConVarFlags(FindConVar("z_mega_mob_spawn_max_interval")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("director_no_death_check"), GetConVarFlags(FindConVar("director_no_death_check")) & ~FCVAR_NOTIFY);
	if (ReadyUp_GetGameMode() == 2) SetConVarFlags(FindConVar("z_tank_health"), GetConVarFlags(FindConVar("z_tank_health")) & ~FCVAR_NOTIFY);

	//LoadTranslations("common.phrases");
	LoadTranslations("rum_rpg.phrases");

	BuildPath(Path_SM, ConfigPathDirectory, sizeof(ConfigPathDirectory), "configs/readyup/");

	if (!DirExists(ConfigPathDirectory)) CreateDirectory(ConfigPathDirectory, 777);

	RegAdminCmd("resettpl", Cmd_ResetTPL, ADMFLAG_KICK);
	// These are mandatory because of quick commands, so I hardcode the entries.
	RegConsoleCmd("say", CMD_ChatCommand);
	RegConsoleCmd("say_team", CMD_TeamChatCommand);

	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");

	gd = LoadGameConfigFile("rum_rpg");
	if (gd != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();

		g_oAbility = GameConfGetOffset(gd, "oAbility");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CSpitterProjectile_Detonate");
		g_hCreateAcid = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnAdrenalineUsed");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hEffectAdrenaline = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hCallVomitOnPlayer = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnRevived");
		hRevive = EndPrepSDKCall();
	}
	else {

		SetFailState("Error: Unable to load Gamedata rum_rpg.txt");
	}
}

public ReadyUp_TrueDisconnect(client) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		b_IsLoading[client] = false;
		//if (b_IsActiveRound) SaveAndClear(client, true);
		b_HardcoreMode[client] = false;
		SaveAndClear(client, true);
		CreateTimer(1.0, Timer_RemoveSaveSafety, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RemoveSaveSafety(Handle:timer, any:client) {

	b_ActiveThisRound[client] = false;
	return Plugin_Stop;
}

public OnMapStart() {

	// This can call more than once, and we only want it to fire once.
	// The variable resets to false when a map ends.

	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/props_interiors/toaster.mdl", true);
	g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_BeaconSprite = PrecacheModel("materials/sprites/halo01.vmt");
	b_IsActiveRound = false;
	MapRoundsPlayed = 0;
	Points_Director = 0.0;
	bIsLoadedBotData = false;
	b_IsLoadingInfectedBotData = false;
	b_IsSavingInfectedBotData = false;

	b_IsCampaignComplete			= false;
	b_IsRoundIsOver					= false;
	b_IsCheckpointDoorStartOpened	= false;

	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "%srpg/%s.cfg", ConfigPathDirectory, CurrentMap);
	//LogMessage("CONFIG_MAIN DEFAULT: %s", CONFIG_MAIN);
	if (!FileExists(CONFIG_MAIN)) Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/config.cfg");
	else Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/%s.cfg", CurrentMap);

	SetConVarInt(FindConVar("director_no_death_check"), 1);

	if (!b_MapStart) {

		b_MapStart								= true;

		if (MainKeys == INVALID_HANDLE || !b_FirstLoad) MainKeys										= CreateArray(16);
		if (MainValues == INVALID_HANDLE || !b_FirstLoad) MainValues										= CreateArray(16);
		if (a_Menu_Talents_Survivor == INVALID_HANDLE || !b_FirstLoad) a_Menu_Talents_Survivor							= CreateArray(3);
		if (a_Menu_Talents_Infected == INVALID_HANDLE || !b_FirstLoad) a_Menu_Talents_Infected							= CreateArray(3);
		if (a_Menu_Talents_Passives == INVALID_HANDLE || !b_FirstLoad) a_Menu_Talents_Passives							= CreateArray(3);
		if (a_Menu_Main == INVALID_HANDLE || !b_FirstLoad) a_Menu_Main										= CreateArray(3);
		if (a_Events == INVALID_HANDLE || !b_FirstLoad) a_Events										= CreateArray(3);
		if (a_Points == INVALID_HANDLE || !b_FirstLoad) a_Points										= CreateArray(3);
		if (a_Store == INVALID_HANDLE || !b_FirstLoad) a_Store											= CreateArray(3);
		if (a_Trails == INVALID_HANDLE || !b_FirstLoad) a_Trails										= CreateArray(3);
		if (a_Database_Talents == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents								= CreateArray(8);
		if (a_Database_Talents_Defaults == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents_Defaults						= CreateArray(8);
		if (a_Database_Talents_Defaults_Name == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents_Defaults_Name				= CreateArray(8);
		if (EventSection == INVALID_HANDLE || !b_FirstLoad) EventSection									= CreateArray(8);
		if (HookSection == INVALID_HANDLE || !b_FirstLoad) HookSection										= CreateArray(8);
		if (CallKeys == INVALID_HANDLE || !b_FirstLoad) CallKeys										= CreateArray(8);
		if (CallValues == INVALID_HANDLE || !b_FirstLoad) CallValues										= CreateArray(8);
		if (DirectorKeys == INVALID_HANDLE || !b_FirstLoad) DirectorKeys									= CreateArray(8);
		if (DirectorValues == INVALID_HANDLE || !b_FirstLoad) DirectorValues									= CreateArray(8);
		if (DatabaseKeys == INVALID_HANDLE || !b_FirstLoad) DatabaseKeys									= CreateArray(8);
		if (DatabaseValues == INVALID_HANDLE || !b_FirstLoad) DatabaseValues									= CreateArray(8);
		if (DatabaseSection == INVALID_HANDLE || !b_FirstLoad) DatabaseSection									= CreateArray(8);
		if (a_Database_PlayerTalents_Bots == INVALID_HANDLE || !b_FirstLoad) a_Database_PlayerTalents_Bots					= CreateArray(8);
		if (PlayerAbilitiesCooldown_Bots == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesCooldown_Bots					= CreateArray(8);
		if (PlayerAbilitiesImmune_Bots == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesImmune_Bots						= CreateArray(8);
		if (BotSaveKeys == INVALID_HANDLE || !b_FirstLoad) BotSaveKeys										= CreateArray(8);
		if (BotSaveValues == INVALID_HANDLE || !b_FirstLoad) BotSaveValues									= CreateArray(8);
		if (BotSaveSection == INVALID_HANDLE || !b_FirstLoad) BotSaveSection									= CreateArray(8);
		if (LoadDirectorSection == INVALID_HANDLE || !b_FirstLoad) LoadDirectorSection								= CreateArray(8);
		if (QueryDirectorKeys == INVALID_HANDLE || !b_FirstLoad) QueryDirectorKeys								= CreateArray(8);
		if (QueryDirectorValues == INVALID_HANDLE || !b_FirstLoad) QueryDirectorValues								= CreateArray(8);
		if (QueryDirectorSection == INVALID_HANDLE || !b_FirstLoad) QueryDirectorSection							= CreateArray(8);
		if (FirstDirectorKeys == INVALID_HANDLE || !b_FirstLoad) FirstDirectorKeys								= CreateArray(8);
		if (FirstDirectorValues == INVALID_HANDLE || !b_FirstLoad) FirstDirectorValues								= CreateArray(8);
		if (FirstDirectorSection == INVALID_HANDLE || !b_FirstLoad) FirstDirectorSection							= CreateArray(8);
		if (PlayerAbilitiesName == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesName								= CreateArray(8);
		if (a_DirectorActions == INVALID_HANDLE || !b_FirstLoad) a_DirectorActions								= CreateArray(3);
		if (a_DirectorActions_Cooldown == INVALID_HANDLE || !b_FirstLoad) a_DirectorActions_Cooldown						= CreateArray(8);
		if (a_ChatSettings == INVALID_HANDLE || !b_FirstLoad) a_ChatSettings								= CreateArray(3);

		//LogMessage("main arrays created.");

		for (new i = 1; i <= MAXPLAYERS; i++) {

			//LogMessage("Configs executed, creating arrays.");

			if (MenuKeys[i] == INVALID_HANDLE || !b_FirstLoad) MenuKeys[i]								= CreateArray(8);
			if (MenuValues[i] == INVALID_HANDLE || !b_FirstLoad) MenuValues[i]							= CreateArray(8);
			if (MenuSection[i] == INVALID_HANDLE || !b_FirstLoad) MenuSection[i]							= CreateArray(8);
			if (TriggerKeys[i] == INVALID_HANDLE || !b_FirstLoad) TriggerKeys[i]							= CreateArray(8);
			if (TriggerValues[i] == INVALID_HANDLE || !b_FirstLoad) TriggerValues[i]						= CreateArray(8);
			if (TriggerSection[i] == INVALID_HANDLE || !b_FirstLoad) TriggerSection[i]						= CreateArray(8);
			if (AbilityKeys[i] == INVALID_HANDLE || !b_FirstLoad) AbilityKeys[i]							= CreateArray(8);
			if (AbilityValues[i] == INVALID_HANDLE || !b_FirstLoad) AbilityValues[i]						= CreateArray(8);
			if (AbilitySection[i] == INVALID_HANDLE || !b_FirstLoad) AbilitySection[i]						= CreateArray(8);
			if (ChanceKeys[i] == INVALID_HANDLE || !b_FirstLoad) ChanceKeys[i]							= CreateArray(8);
			if (ChanceValues[i] == INVALID_HANDLE || !b_FirstLoad) ChanceValues[i]							= CreateArray(8);
			if (ChanceSection[i] == INVALID_HANDLE || !b_FirstLoad) ChanceSection[i]						= CreateArray(8);
			if (a_Database_PlayerTalents[i] == INVALID_HANDLE || !b_FirstLoad) a_Database_PlayerTalents[i]				= CreateArray(8);
			if (PlayerAbilitiesCooldown[i] == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesCooldown[i]				= CreateArray(8);
			if (PlayerAbilitiesImmune[i] == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesImmune[i]				= CreateArray(8);
			if (a_Store_Player[i] == INVALID_HANDLE || !b_FirstLoad) a_Store_Player[i]						= CreateArray(8);
			if (StoreKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreKeys[i]							= CreateArray(8);
			if (StoreValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreValues[i]							= CreateArray(8);
			if (StoreMultiplierKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreMultiplierKeys[i]					= CreateArray(8);
			if (StoreMultiplierValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreMultiplierValues[i]				= CreateArray(8);
			if (StoreTimeKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreTimeKeys[i]						= CreateArray(8);
			if (StoreTimeValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreTimeValues[i]						= CreateArray(8);
			if (LoadStoreSection[i] == INVALID_HANDLE || !b_FirstLoad) LoadStoreSection[i]						= CreateArray(8);
			if (SaveSection[i] == INVALID_HANDLE || !b_FirstLoad) SaveSection[i]							= CreateArray(8);
			if (StoreChanceKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreChanceKeys[i]						= CreateArray(8);
			if (StoreChanceValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreChanceValues[i]					= CreateArray(8);
			if (StoreItemNameSection[i] == INVALID_HANDLE || !b_FirstLoad) StoreItemNameSection[i]					= CreateArray(8);
			if (StoreItemSection[i] == INVALID_HANDLE || !b_FirstLoad) StoreItemSection[i]						= CreateArray(8);
			if (TrailsKeys[i] == INVALID_HANDLE || !b_FirstLoad) TrailsKeys[i]							= CreateArray(8);
			if (TrailsValues[i] == INVALID_HANDLE || !b_FirstLoad) TrailsValues[i]							= CreateArray(8);
			if (BoosterKeys[i] == INVALID_HANDLE || !b_FirstLoad) BoosterKeys[i]							= CreateArray(8);
			if (BoosterValues[i] == INVALID_HANDLE || !b_FirstLoad) BoosterValues[i]						= CreateArray(8);
			if (RPGMenuPosition[i] == INVALID_HANDLE || !b_FirstLoad) RPGMenuPosition[i]						= CreateArray(8);
			if (ChatSettings[i] == INVALID_HANDLE || !b_FirstLoad) ChatSettings[i]						= CreateArray(8);
			if (h_KilledPosition_X[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_X[i]				= CreateArray(8);
			if (h_KilledPosition_Y[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_Y[i]				= CreateArray(8);
			if (h_KilledPosition_Z[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_Z[i]				= CreateArray(8);
		}

		if (!b_FirstLoad) b_FirstLoad = true;

		LogMessage("CONFIG MAIN SET: %s", CONFIG_MAIN);
	}
}

public OnMapEnd() {

	if (b_ClearedAdt) {

		b_ClearedAdt									= false;
		b_MapStart										= false;
		b_ConfigsExecuted								= false;
		SubmitEventHooks(0);
		//SaveAndClear(-1, true);

		if (MainKeys != INVALID_HANDLE) {

			CloseHandle(Handle:MainKeys);
			MainKeys = INVALID_HANDLE;
		}
		if (MainValues != INVALID_HANDLE) {

			CloseHandle(Handle:MainValues);
			MainValues = INVALID_HANDLE;
		}
		if (a_Menu_Talents_Survivor != INVALID_HANDLE) {

			CloseHandle(Handle:a_Menu_Talents_Survivor);
			a_Menu_Talents_Survivor = INVALID_HANDLE;
		}
		if (a_Menu_Talents_Infected != INVALID_HANDLE) {

			CloseHandle(Handle:a_Menu_Talents_Infected);
			a_Menu_Talents_Infected = INVALID_HANDLE;
		}
		if (a_Menu_Talents_Passives != INVALID_HANDLE) {

			CloseHandle(Handle:a_Menu_Talents_Passives);
			a_Menu_Talents_Passives = INVALID_HANDLE;
		}
		if (a_Menu_Main != INVALID_HANDLE) {

			CloseHandle(Handle:a_Menu_Main);
			a_Menu_Main = INVALID_HANDLE;
		}
		if (a_Events != INVALID_HANDLE) {

			CloseHandle(Handle:a_Events);
			a_Events = INVALID_HANDLE;
		}
		if (a_Points != INVALID_HANDLE) {

			CloseHandle(Handle:a_Points);
			a_Points = INVALID_HANDLE;
		}
		if (a_Store != INVALID_HANDLE) {

			CloseHandle(Handle:a_Store);
			a_Store = INVALID_HANDLE;
		}
		if (a_Trails != INVALID_HANDLE) {

			CloseHandle(Handle:a_Trails);
			a_Trails = INVALID_HANDLE;
		}
		if (a_Database_Talents != INVALID_HANDLE) {

			CloseHandle(Handle:a_Database_Talents);
			a_Database_Talents = INVALID_HANDLE;
		}
		if (a_Database_Talents_Defaults != INVALID_HANDLE) {

			CloseHandle(Handle:a_Database_Talents_Defaults);
			a_Database_Talents_Defaults = INVALID_HANDLE;
		}
		if (a_Database_Talents_Defaults_Name != INVALID_HANDLE) {

			CloseHandle(Handle:a_Database_Talents_Defaults_Name);
			a_Database_Talents_Defaults_Name = INVALID_HANDLE;
		}
		if (EventSection != INVALID_HANDLE) {

			CloseHandle(Handle:EventSection);
			EventSection = INVALID_HANDLE;
		}
		if (HookSection != INVALID_HANDLE) {

			CloseHandle(Handle:HookSection);
			HookSection = INVALID_HANDLE;
		}
		if (CallKeys != INVALID_HANDLE) {

			CloseHandle(Handle:CallKeys);
			CallKeys = INVALID_HANDLE;
		}
		if (CallValues != INVALID_HANDLE) {

			CloseHandle(Handle:CallValues);
			CallValues = INVALID_HANDLE;
		}
		if (DirectorKeys != INVALID_HANDLE) {

			CloseHandle(Handle:DirectorKeys);
			DirectorKeys = INVALID_HANDLE;
		}
		if (DirectorValues != INVALID_HANDLE) {

			CloseHandle(Handle:DirectorValues);
			DirectorValues = INVALID_HANDLE;
		}
		if (DatabaseKeys != INVALID_HANDLE) {

			CloseHandle(Handle:DatabaseKeys);
			DatabaseKeys = INVALID_HANDLE;
		}
		if (DatabaseValues != INVALID_HANDLE) {

			CloseHandle(Handle:DatabaseValues);
			DatabaseValues = INVALID_HANDLE;
		}
		if (DatabaseSection != INVALID_HANDLE) {

			CloseHandle(Handle:DatabaseSection);
			DatabaseSection = INVALID_HANDLE;
		}
		if (a_Database_PlayerTalents_Bots != INVALID_HANDLE) {

			CloseHandle(Handle:a_Database_PlayerTalents_Bots);
			a_Database_PlayerTalents_Bots = INVALID_HANDLE;
		}
		if (PlayerAbilitiesCooldown_Bots != INVALID_HANDLE) {

			CloseHandle(Handle:PlayerAbilitiesCooldown_Bots);
			PlayerAbilitiesCooldown_Bots = INVALID_HANDLE;
		}
		if (PlayerAbilitiesImmune_Bots != INVALID_HANDLE) {

			CloseHandle(Handle:PlayerAbilitiesImmune_Bots);
			PlayerAbilitiesImmune_Bots = INVALID_HANDLE;
		}
		if (BotSaveKeys != INVALID_HANDLE) {

			CloseHandle(Handle:BotSaveKeys);
			BotSaveKeys = INVALID_HANDLE;
		}
		if (BotSaveValues != INVALID_HANDLE) {

			CloseHandle(Handle:BotSaveValues);
			BotSaveValues = INVALID_HANDLE;
		}
		if (BotSaveSection != INVALID_HANDLE) {

			CloseHandle(Handle:BotSaveSection);
			BotSaveSection = INVALID_HANDLE;
		}
		if (LoadDirectorSection != INVALID_HANDLE) {

			CloseHandle(Handle:LoadDirectorSection);
			LoadDirectorSection = INVALID_HANDLE;
		}
		if (QueryDirectorKeys != INVALID_HANDLE) {

			CloseHandle(Handle:QueryDirectorKeys);
			QueryDirectorKeys = INVALID_HANDLE;
		}
		if (QueryDirectorValues != INVALID_HANDLE) {

			CloseHandle(Handle:QueryDirectorValues);
			QueryDirectorValues = INVALID_HANDLE;
		}
		if (QueryDirectorSection != INVALID_HANDLE) {

			CloseHandle(Handle:QueryDirectorSection);
			QueryDirectorSection = INVALID_HANDLE;
		}
		if (FirstDirectorKeys != INVALID_HANDLE) {

			CloseHandle(Handle:FirstDirectorKeys);
			FirstDirectorKeys = INVALID_HANDLE;
		}
		if (FirstDirectorValues != INVALID_HANDLE) {

			CloseHandle(Handle:FirstDirectorValues);
			FirstDirectorValues = INVALID_HANDLE;
		}
		if (FirstDirectorSection != INVALID_HANDLE) {

			CloseHandle(Handle:FirstDirectorSection);
			FirstDirectorSection = INVALID_HANDLE;
		}
		if (PlayerAbilitiesName != INVALID_HANDLE) {

			CloseHandle(Handle:PlayerAbilitiesName);
			PlayerAbilitiesName = INVALID_HANDLE;
		}
		if (a_DirectorActions != INVALID_HANDLE) {

			CloseHandle(Handle:a_DirectorActions);
			a_DirectorActions = INVALID_HANDLE;
		}
		if (a_DirectorActions_Cooldown != INVALID_HANDLE) {

			CloseHandle(Handle:a_DirectorActions_Cooldown);
			a_DirectorActions_Cooldown = INVALID_HANDLE;
		}
		if (a_ChatSettings != INVALID_HANDLE) {

			CloseHandle(Handle:a_ChatSettings);
			a_ChatSettings = INVALID_HANDLE;
		}

		for (new i = 1; i <= MAXPLAYERS; i++) {

			if (MenuKeys[i] != INVALID_HANDLE) {

				CloseHandle(MenuKeys[i]);
				MenuKeys[i] = INVALID_HANDLE;
			}
			if (MenuValues[i] != INVALID_HANDLE) {

				CloseHandle(MenuValues[i]);
				MenuValues[i] = INVALID_HANDLE;
			}
			if (MenuSection[i] != INVALID_HANDLE) {

				CloseHandle(MenuSection[i]);
				MenuSection[i] = INVALID_HANDLE;
			}
			if (TriggerKeys[i] != INVALID_HANDLE) {

				CloseHandle(TriggerKeys[i]);
				TriggerKeys[i] = INVALID_HANDLE;
			}
			if (TriggerValues[i] != INVALID_HANDLE) {

				CloseHandle(TriggerValues[i]); 
				TriggerValues[i] = INVALID_HANDLE;
			}
			if (TriggerSection[i] != INVALID_HANDLE) {

				CloseHandle(TriggerSection[i]); 
				TriggerSection[i] = INVALID_HANDLE;
			}
			if (AbilityKeys[i] != INVALID_HANDLE) {

				CloseHandle(AbilityKeys[i]); 
				AbilityKeys[i] = INVALID_HANDLE;
			}
			if (AbilityValues[i] != INVALID_HANDLE) {

				CloseHandle(AbilityValues[i]); 
				AbilityValues[i] = INVALID_HANDLE;
			}
			if (AbilitySection[i] != INVALID_HANDLE) {

				CloseHandle(AbilitySection[i]); 
				AbilitySection[i] = INVALID_HANDLE;
			}
			if (ChanceKeys[i] != INVALID_HANDLE) {

				CloseHandle(ChanceKeys[i]); 
				ChanceKeys[i] = INVALID_HANDLE;
			}
			if (ChanceValues[i] != INVALID_HANDLE) {

				CloseHandle(ChanceValues[i]); 
				ChanceValues[i] = INVALID_HANDLE;
			}
			if (ChanceSection[i] != INVALID_HANDLE) {

				CloseHandle(ChanceSection[i]); 
				ChanceSection[i] = INVALID_HANDLE;
			}
			if (a_Database_PlayerTalents[i] != INVALID_HANDLE) {

				CloseHandle(a_Database_PlayerTalents[i]);
				a_Database_PlayerTalents[i] = INVALID_HANDLE;
			} 
			if (PlayerAbilitiesCooldown[i] != INVALID_HANDLE) {

				CloseHandle(PlayerAbilitiesCooldown[i]);
				PlayerAbilitiesCooldown[i] = INVALID_HANDLE;
			} 
			if (PlayerAbilitiesImmune[i] != INVALID_HANDLE) {

				CloseHandle(PlayerAbilitiesImmune[i]); 
				PlayerAbilitiesImmune[i] = INVALID_HANDLE;
			}
			if (a_Store_Player[i] != INVALID_HANDLE) {

				CloseHandle(a_Store_Player[i]); 
				a_Store_Player[i] = INVALID_HANDLE;
			}
			if (StoreKeys[i] != INVALID_HANDLE) {

				CloseHandle(StoreKeys[i]); 
				StoreKeys[i] = INVALID_HANDLE;
			}
			if (StoreValues[i] != INVALID_HANDLE) {

				CloseHandle(StoreValues[i]); 
				StoreValues[i] = INVALID_HANDLE;
			}
			if (StoreMultiplierKeys[i] != INVALID_HANDLE) {

				CloseHandle(StoreMultiplierKeys[i]); 
				StoreMultiplierKeys[i] = INVALID_HANDLE;
			}
			if (StoreMultiplierValues[i] != INVALID_HANDLE) {

				CloseHandle(StoreMultiplierValues[i]); 
				StoreMultiplierValues[i] = INVALID_HANDLE;
			}
			if (StoreTimeKeys[i] != INVALID_HANDLE) {

				CloseHandle(StoreTimeKeys[i]); 
				StoreTimeKeys[i] = INVALID_HANDLE;
			}
			if (StoreTimeValues[i] != INVALID_HANDLE) {

				CloseHandle(StoreTimeValues[i]); 
				StoreTimeValues[i] = INVALID_HANDLE;
			}
			if (LoadStoreSection[i] != INVALID_HANDLE) {

				CloseHandle(LoadStoreSection[i]);
				LoadStoreSection[i] = INVALID_HANDLE;
			} 
			if (SaveSection[i] != INVALID_HANDLE) {

				CloseHandle(SaveSection[i]); 
				SaveSection[i] = INVALID_HANDLE;
			}
			if (StoreChanceKeys[i] != INVALID_HANDLE) {

				CloseHandle(StoreChanceKeys[i]);
				StoreChanceKeys[i] = INVALID_HANDLE;
			} 
			if (StoreChanceValues[i] != INVALID_HANDLE) {

				CloseHandle(StoreChanceValues[i]); 
				StoreChanceValues[i] = INVALID_HANDLE;
			}
			if (StoreItemNameSection[i] != INVALID_HANDLE) {

				CloseHandle(StoreItemNameSection[i]);
				StoreItemNameSection[i] = INVALID_HANDLE;
			}
			if (StoreItemSection[i] != INVALID_HANDLE) {

				CloseHandle(StoreItemSection[i]); 
				StoreItemSection[i] = INVALID_HANDLE;
			}
			if (TrailsKeys[i] != INVALID_HANDLE) {

				CloseHandle(TrailsKeys[i]); 
				TrailsKeys[i] = INVALID_HANDLE;
			}
			if (TrailsValues[i] != INVALID_HANDLE) {

				CloseHandle(TrailsValues[i]); 
				TrailsValues[i] = INVALID_HANDLE;
			}
			if (BoosterKeys[i] != INVALID_HANDLE) {

				CloseHandle(BoosterKeys[i]); 
				BoosterKeys[i] = INVALID_HANDLE;
			}
			if (BoosterValues[i] != INVALID_HANDLE) {

				CloseHandle(BoosterValues[i]); 
				BoosterValues[i] = INVALID_HANDLE;
			}
			if (RPGMenuPosition[i] != INVALID_HANDLE) {

				CloseHandle(RPGMenuPosition[i]);
				RPGMenuPosition[i] = INVALID_HANDLE;
			}
			if (ChatSettings[i] != INVALID_HANDLE) {

				CloseHandle(ChatSettings[i]);
				ChatSettings[i] = INVALID_HANDLE;
			}
			if (h_KilledPosition_X[i] != INVALID_HANDLE) {

				CloseHandle(h_KilledPosition_X[i]);
				h_KilledPosition_X[i] = INVALID_HANDLE;
			}
			if (h_KilledPosition_Y[i] != INVALID_HANDLE) {

				CloseHandle(h_KilledPosition_Y[i]);
				h_KilledPosition_Y[i] = INVALID_HANDLE;
			}
			if (h_KilledPosition_Z[i] != INVALID_HANDLE) {

				CloseHandle(h_KilledPosition_Z[i]);
				h_KilledPosition_Z[i] = INVALID_HANDLE;
			}
		}
		Format(PathSetting, sizeof(PathSetting), "none");		// reset when a map ends.
	}
}

public ReadyUp_FirstClientLoaded() {

	//b_FirstClientLoaded = true;
	g_MapFlowDistance	=	L4D2Direct_GetMapMaxFlowDistance();
}

public OnConfigsExecuted() {

	if (!b_ConfigsExecuted) {

		b_ConfigsExecuted = true;
		CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		ReadyUp_NtvGetCampaignName();
	}
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(CONFIG_MAIN);
		ReadyUp_ParseConfig(CONFIG_EVENTS);
		ReadyUp_ParseConfig(CONFIG_MENUSURVIVOR);
		ReadyUp_ParseConfig(CONFIG_MENUINFECTED);
		ReadyUp_ParseConfig(CONFIG_POINTS);
		ReadyUp_ParseConfig(CONFIG_STORE);
		ReadyUp_ParseConfig(CONFIG_TRAILS);
		ReadyUp_ParseConfig(CONFIG_CHATSETTINGS);
		ReadyUp_ParseConfig(CONFIG_MAINMENU);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock RemoveMeleeWeapons() {

	new ent = -1;
	//decl String:Model[64];
	while ((ent = FindEntityByClassname(ent, "weapon_defibrillator")) != -1) {

		//LogMessage("Removing Defibrillators");
		if (!AcceptEntityInput(ent, "Kill")) RemoveEdict(ent);
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "weapon_defibrillator_spawn")) != -1) {

		//LogMessage("Removing Defibrillators");
		if (!AcceptEntityInput(ent, "Kill")) RemoveEdict(ent);
	}
}

public ReadyUp_ReadyUpStart() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) {

			b_HandicapLocked[i] = false;
			bIsEligibleMapAward[i] = true;

			// Anti-Farm/Anti-Camping system stuff.
			ClearArray(h_KilledPosition_X[i]);		// We clear all positions from the array.
			ClearArray(h_KilledPosition_Y[i]);
			ClearArray(h_KilledPosition_Z[i]);
		}
	}
}

public ReadyUp_ReadyUpEnd() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && !b_IsArraysCreated[i]) CreateTimer(0.1, Timer_LoadData, i, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_LoadData(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsFakeClient(client)) {

		ResetData(client);
		decl String:key[64];
		b_IsLoading[client] = false;
		GetClientAuthString(client, key, sizeof(key));
		ClearAndLoad(key);
	}
	return Plugin_Stop;
}

public ReadyUp_CheckpointDoorStartOpened() {

	if (!b_IsCheckpointDoorStartOpened) {

		b_IsCheckpointDoorStartOpened		= true;
		b_IsCampaignComplete				= false;
		b_IsRoundIsOver						= false;

		ClearAndLoadBot();
		bIsLoadedBotData = true;
		RoundTime					=	GetTime();
		PrintToChatAll("%t", "Round Statistics", white, green, AddCommasToString(CommonsKilled), orange, green, AddCommasToString(SpecialsKilled), blue, green, AddCommasToString(SurvivorsKilled), white, green, AddCommasToString(RoundDamageTotal), white, blue, MVPName, white, green, AddCommasToString(MVPDamage));
		if (ReadyUp_GetGameMode() == 2) MapRoundsPlayed = 0;	// Difficulty leniency does not occur in versus.

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && !IsFakeClient(i)) CheckMaxAllowedHandicap(i);
		}

		SpecialsKilled				=	0;
		CommonsKilled				=	0;
		SurvivorsKilled				=	0;
		RoundDamageTotal			=	0;
		MVPDamage					=	0;
		b_IsFinaleActive			=	false;
		b_IsVehicleReady			=	false;

		if (StringToInt(GetConfigValue("director save priority?")) == 1) PrintToChatAll("%t", "Director Priority Save Enabled", white, green);

		if (!StrEqual(GetConfigValue("path setting?"), "none")) {

			if (!StrEqual(GetConfigValue("path setting?"), "random")) ServerCommand("sm_forcepath %s", GetConfigValue("path setting?"));
			else {

				if (StrEqual(PathSetting, "none") && ReadyUp_GetGameMode() == 2 || ReadyUp_GetGameMode() != 2) {

					new random = GetRandomInt(1, 100);
					if (random <= 33) Format(PathSetting, sizeof(PathSetting), "easy");
					else if (random <= 66) Format(PathSetting, sizeof(PathSetting), "medium");
					else Format(PathSetting, sizeof(PathSetting), "hard");
				}
				ServerCommand("sm_forcepath %s", PathSetting);
			}
		}

		b_IsActiveRound = true;	
		f_TankCooldown				=	-1.0;
		Points_Director = 0.0;

		for (new i = 1; i <= MAXPLAYERS; i++) {

			b_ActiveThisRound[i] = false;
			RoundIncaps[i] = 0;
			RoundDeaths[i] = 0;
			if (HandicapLevel[i] < 0) HandicapLevel[i] = -1;
		}

		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i)) {

				RoundDamage[i] = 0;
				if (IsPlayerAlive(i)) b_IsInSaferoom[i] = false;
				ResetCoveredInBile(i);
				BlindPlayer(i);

				if (GetClientTeam(i) == TEAM_SURVIVOR && b_HardcoreMode[i]) EnableHardcoreMode(i);
			}
		}

		if (ReadyUp_GetGameMode() != 2) {

			// It destroys itself when a round ends.
			CreateTimer(1.0, Timer_DirectorPurchaseTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		CreateTimer(StringToFloat(GetConfigValue("settings check interval?")), Timer_SettingsCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_DeductStoreTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, Timer_PeriodicTalents, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_PlayTimeCounter, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_DeathCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		if (StringToInt(GetConfigValue("rpg mode?")) > 0) CreateTimer(1.0, Timer_AwardSkyPoints, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		RemoveMeleeWeapons();
		ClearRelevantData();
		LastLivingSurvivor = 1;

		new size = GetArraySize(a_DirectorActions);
		ResizeArray(a_DirectorActions_Cooldown, size);
		for (new i = 0; i < size; i++) SetArrayString(a_DirectorActions_Cooldown, i, "0");

		if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
		ClearArray(CommonInfectedQueue);

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED) {

				DefaultHealth[i] = 100;

				// The spawn sets the players speed so we don't need to do it here.
				PlayerSpawnAbilityTrigger(i);
				

				//ExecCheatCommand(i, "give", "health");
				if (!b_HardcoreMode[i]) {

					RefreshSurvivor(i);
					GiveMaximumHealth(i);
				}
				else SetClientMaximumTempHealth(i);
				//SpeedMultiplierBase[i] = 1.0 - (HandicapLevel[i] * StringToFloat(GetConfigValue("handicap movement penalty?")));
				//if (IsValidEntity(i)) SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[i]);
				Points[i] = 0.0;

				ResetCoveredInBile(i);
			}
		}
	}
}

stock ResetCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i)) {

			CoveredInBile[client][i] = -1;
			CoveredInBile[i][client] = -1;
		}
	}
}

stock FindTargetClient(client, String:arg[]) {

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
		arg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++) targetclient = target_list[i];
	}
	return targetclient;
}

public Action:CMD_ChatTag(client, args) {

	if (IsReserve(client) && args > 0) {

		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		if (strlen(arg) > StringToInt(GetConfigValue("tag name max length?"))) PrintToChat(client, "%T", "Tag Name Too Long", client, StringToInt(GetConfigValue("tag name max length?")));
		else {
		
			SetArrayString(ChatSettings[client], 1, arg);
			PrintToChat(client, "%T", "Tag Name Set", client, arg);
		}
	}

	return Plugin_Handled;
}

public Action:CMD_GiveLevel(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?")) && args > 1) {

		decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		new targetclient = FindTargetClient(client, arg);
		if (IsLegitimateClient(targetclient) && !IsFakeClient(targetclient) && PlayerLevel[targetclient] < StringToInt(arg2)) {

			PlayerLevel[targetclient] = StringToInt(arg2) - 1;
			FreeUpgrades[targetclient] += (MaximumPlayerUpgrades(targetclient) - PlayerUpgradesTotal[targetclient] - FreeUpgrades[targetclient]);
			PlayerLevelUpgrades[targetclient] = 0;
			PlayerLevel[targetclient]++;
			decl String:Name[64];
			GetClientName(targetclient, Name, sizeof(Name));
			PrintToChat(client, "%T", "client level set", client, Name, green, white, blue, PlayerLevel[targetclient]);
		}
	}

	return Plugin_Handled;
}

public Action:CMD_GiveStorePoints(client, args)
{
	if (!HasCommandAccess(client, GetConfigValue("director talent flags?"))) return Plugin_Handled;
	if (args < 2)
	{
		PrintToChat(client, "%T", "Give Store Points Syntax", client, orange, white);
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	new targetclient = FindTargetClient(client, arg);
	decl String:Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));

	SkyPoints[targetclient] += StringToInt(arg2);

	PrintToChat(client, "%T", "Store Points Award Given", client, white, green, arg2, white, orange, Name);
	PrintToChat(targetclient, "%T", "Store Points Award Received", client, white, green, arg2, white);

	return Plugin_Handled;
}

public ReadyUp_CampaignComplete() {

	if (!b_IsCampaignComplete) {

		b_IsCampaignComplete			= true;
		b_IsActiveRound = false;
		Points_Director = 0.0;

		new Seconds			= GetTime() - RoundTime;
		new Minutes			= 0;

		while (Seconds >= 60) {

			Minutes++;
			Seconds -= 60;
		}

		PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
		if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
		ClearArray(CommonInfectedQueue);

		//SaveAndClear(-1, true);
		for (new i = 0; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && !IsFakeClient(i)) {

				EndOfMapAwardChance(i);
				SaveAndClear(i);
			}
		}
		if (bIsLoadedBotData) {

			bIsLoadedBotData = false;
			SaveInfectedBotData();
		}
		LogMessage("SAVING PLAYER AND BOT DATA. SEARCH CODE: 11384");
		PrintToChatAll("%t", "Data Saved", white, orange);
	}
}

public ReadyUp_RoundIsOver(gamemode) {

	if (!b_IsRoundIsOver) {

		b_IsRoundIsOver					= true;
		b_IsCheckpointDoorStartOpened	= false;
		RemoveImmunities(-1);

		b_IsActiveRound = false;
		Points_Director = 0.0;
		MapRoundsPlayed++;

		new Seconds			= GetTime() - RoundTime;
		new Minutes			= 0;

		while (Seconds >= 60) {

			Minutes++;
			Seconds -= 60;
		}

		for (new i = 1; i <= MAXPLAYERS; i++) {

			b_HardcoreMode[i] = false;
		}

		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i)) {

				if (RoundDamage[i] > MVPDamage) {

					GetClientName(i, MVPName, sizeof(MVPName));
					MVPDamage = RoundDamage[i];
				}
			}
		}

		PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
		if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
		ClearArray(CommonInfectedQueue);

		//SaveAndClear(-1, true);
		for (new i = 0; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && !IsFakeClient(i)) {

				EndOfMapAwardChance(i);
				SaveAndClear(i);
			}
		}
		if (bIsLoadedBotData) {

			bIsLoadedBotData = false;
			SaveInfectedBotData();
		}
		LogMessage("SAVING PLAYER AND BOT DATA. SEARCH CODE: 11384");
		PrintToChatAll("%t", "Data Saved", white, orange);
	}
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, CONFIG_MAIN) ||
		StrEqual(config, CONFIG_EVENTS) ||
		StrEqual(config, CONFIG_MENUSURVIVOR) ||
		StrEqual(config, CONFIG_MENUINFECTED) ||
		StrEqual(config, CONFIG_MAINMENU) ||
		StrEqual(config, CONFIG_POINTS) ||
		StrEqual(config, CONFIG_STORE) ||
		StrEqual(config, CONFIG_TRAILS) ||
		StrEqual(config, CONFIG_CHATSETTINGS)) {
	
		SetFailState("%s , %s", config, error);
	}
}

public ReadyUp_LoadFromConfigEx(Handle:key, Handle:value, Handle:section, String:configname[], keyCount) {

	//PrintToChatAll("Size: %d config: %s", GetArraySize(Handle:key), configname);

	if (!StrEqual(configname, CONFIG_MAIN) &&
		!StrEqual(configname, CONFIG_EVENTS) &&
		!StrEqual(configname, CONFIG_MENUSURVIVOR) &&
		!StrEqual(configname, CONFIG_MENUINFECTED) &&
		!StrEqual(configname, CONFIG_MAINMENU) &&
		!StrEqual(configname, CONFIG_POINTS) &&
		!StrEqual(configname, CONFIG_STORE) &&
		!StrEqual(configname, CONFIG_TRAILS) &&
		!StrEqual(configname, CONFIG_CHATSETTINGS)) return;

	decl String:s_key[64];
	decl String:s_value[64];
	decl String:s_section[64];

	new Handle:TalentKeys		=					CreateArray(64);
	new Handle:TalentValues		=					CreateArray(64);
	new Handle:TalentSection	=					CreateArray(64);

	new lastPosition = 0;
	new counter = 0;

	if (keyCount > 0) {

		if (StrEqual(configname, CONFIG_MENUSURVIVOR)) ResizeArray(a_Menu_Talents_Survivor, keyCount);
		else if (StrEqual(configname, CONFIG_MENUINFECTED)) ResizeArray(a_Menu_Talents_Infected, keyCount);
		else if (StrEqual(configname, CONFIG_MAINMENU)) ResizeArray(a_Menu_Main, keyCount);
		else if (StrEqual(configname, CONFIG_EVENTS)) ResizeArray(a_Events, keyCount);
		else if (StrEqual(configname, CONFIG_POINTS)) ResizeArray(a_Points, keyCount);
		else if (StrEqual(configname, CONFIG_STORE)) ResizeArray(a_Store, keyCount);
		else if (StrEqual(configname, CONFIG_TRAILS)) ResizeArray(a_Trails, keyCount);
		else if (StrEqual(configname, CONFIG_CHATSETTINGS)) ResizeArray(a_ChatSettings, keyCount);
	}

	//PrintToChatAll("CONFIG: %s", configname);

	new a_Size						= GetArraySize(key);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));

		PushArrayString(TalentKeys, s_key);
		PushArrayString(TalentValues, s_value);

		if (StrEqual(configname, CONFIG_MAIN)) {

			PushArrayString(Handle:MainKeys, s_key);
			PushArrayString(Handle:MainValues, s_value);
		}
		//} else {
		if (StrEqual(s_key, "EOM")) {

			GetArrayString(Handle:section, i, s_section, sizeof(s_section));
			PushArrayString(TalentSection, s_section);

			if (StrEqual(configname, CONFIG_MENUSURVIVOR)) SetConfigArrays(configname, a_Menu_Talents_Survivor, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents_Survivor), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MENUINFECTED)) SetConfigArrays(configname, a_Menu_Talents_Infected, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents_Infected), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MAINMENU)) SetConfigArrays(configname, a_Menu_Main, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Main), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_EVENTS)) SetConfigArrays(configname, a_Events, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Events), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_POINTS)) SetConfigArrays(configname, a_Points, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Points), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_STORE)) SetConfigArrays(configname, a_Store, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Store), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_TRAILS)) SetConfigArrays(configname, a_Trails, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Trails), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_CHATSETTINGS)) SetConfigArrays(configname, a_ChatSettings, TalentKeys, TalentValues, TalentSection, GetArraySize(a_ChatSettings), lastPosition - counter);
			
			lastPosition = i + 1;
		}
	}

	if (StrEqual(configname, CONFIG_POINTS)) {

		if (a_DirectorActions != INVALID_HANDLE) ClearArray(a_DirectorActions);
		a_DirectorActions			=	CreateArray(3);
		if (a_DirectorActions_Cooldown != INVALID_HANDLE) ClearArray(a_DirectorActions_Cooldown);
		a_DirectorActions_Cooldown	=	CreateArray(64);

		new size						=	GetArraySize(a_Points);
		new Handle:Keys					=	CreateArray(64);
		new Handle:Values				=	CreateArray(64);
		new Handle:Section				=	CreateArray(64);
		new sizer						=	0;

		for (new i = 0; i < size; i++) {

			Keys						=	GetArrayCell(a_Points, i, 0);
			Values						=	GetArrayCell(a_Points, i, 1);
			Section						=	GetArrayCell(a_Points, i, 2);

			new size2					=	GetArraySize(Keys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:Keys, ii, s_key, sizeof(s_key));
				GetArrayString(Handle:Values, ii, s_value, sizeof(s_value));

				if (StrEqual(s_key, "model?")) PrecacheModel(s_value, false);
				else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {

					sizer				=	GetArraySize(a_DirectorActions);

					ResizeArray(a_DirectorActions, sizer + 1);
					SetArrayCell(a_DirectorActions, sizer, Keys, 0);
					SetArrayCell(a_DirectorActions, sizer, Values, 1);
					SetArrayCell(a_DirectorActions, sizer, Section, 2);

					ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
					SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
				}
			}
		}
		MySQL_Init();	// Testing to see if it works this way.
		//LogMessage("DIRECTOR ACTIONS SIZE: %d", GetArraySize(a_DirectorActions));
	}

	if (StrEqual(configname, CONFIG_MAIN) && !b_IsFirstPluginLoad) {

		b_IsFirstPluginLoad = true;
		RegConsoleCmd(GetConfigValue("rpg menu command?"), CMD_OpenRPGMenu);
		RegConsoleCmd(GetConfigValue("rpg data force load?"), CMD_LoadData);
		RegConsoleCmd(GetConfigValue("rpg data force save?"), CMD_SaveData);
		RegConsoleCmd(GetConfigValue("drop weapon command?"), CMD_DropWeapon);
		RegConsoleCmd(GetConfigValue("director talent command?"), CMD_DirectorTalentToggle);
		RegConsoleCmd(GetConfigValue("rpg data force load bot?"), CMD_LoadBotData);
		RegConsoleCmd(GetConfigValue("rpg data erase?"), CMD_DataErase);
		RegConsoleCmd(GetConfigValue("give store points command?"), CMD_GiveStorePoints);
		RegConsoleCmd(GetConfigValue("give level command?"), CMD_GiveLevel);
		RegConsoleCmd(GetConfigValue("chat tag naming command?"), CMD_ChatTag);
	}

	if (StrEqual(configname, CONFIG_EVENTS)) SubmitEventHooks(1);
	ReadyUp_NtvGetHeader();

	if (StrEqual(configname, CONFIG_MAIN)) {

		PrecacheModel(GetConfigValue("slate item model?"), true);
		PrecacheModel(GetConfigValue("store item model?"), true);
		PrecacheModel(GetConfigValue("locked talent model?"), true);
	}
}

public Action:CMD_DataErase(client, args) {

	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	decl String:tquery[512];
	Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	CreateNewPlayer(client);
	PrintToChat(client, "data erased, new data created.");	// not bothering with a translation here, since it's a debugging command.
	return Plugin_Handled;
}

public Action:CMD_DirectorTalentToggle(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) {

		if (b_IsDirectorTalents[client]) {

			b_IsDirectorTalents[client]			= false;
			PrintToChat(client, "%T", "Director Talents Disabled", client, white, green);
		}
		else {

			b_IsDirectorTalents[client]			= true;
			PrintToChat(client, "%T", "Director Talents Enabled", client, white, green);
		}
	}
	return Plugin_Handled;
}

stock SetConfigArrays(String:Config[], Handle:Main, Handle:Keys, Handle:Values, Handle:Section, size, last) {

	decl String:text[64];
	//GetArrayString(Section, 0, text, sizeof(text));

	new Handle:TalentKey = CreateArray(64);
	new Handle:TalentValue = CreateArray(64);
	new Handle:TalentSection = CreateArray(64);

	decl String:key[64];
	decl String:value[64];
	new a_Size = GetArraySize(Keys);

	for (new i = last; i < a_Size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		GetArrayString(Handle:Values, i, value, sizeof(value));
		//if (DEBUG) PrintToChatAll("\x04Key: \x01%s \x04Value: \x01%s", key, value);

		PushArrayString(TalentKey, key);
		PushArrayString(TalentValue, value);
	}

	GetArrayString(Handle:Section, size, text, sizeof(text));
	PushArrayString(TalentSection, text);
	if (StrEqual(Config, CONFIG_MENUSURVIVOR) || StrEqual(Config, CONFIG_MENUINFECTED)) PushArrayString(a_Database_Talents, text);

	ResizeArray(Main, size + 1);
	SetArrayCell(Main, size, TalentKey, 0);
	SetArrayCell(Main, size, TalentValue, 1);
	SetArrayCell(Main, size, TalentSection, 2);
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_FwdGetCampaignName(const String:mapname[]) {

	strcopy(currentCampaignName, sizeof(currentCampaignName), mapname);
}

#include "rpg/rpg_menu.sp"
#include "rpg/rpg_menu_points.sp"
#include "rpg/rpg_menu_store.sp"
#include "rpg/rpg_menu_chat.sp"
#include "rpg/rpg_menu_director.sp"
#include "rpg/rpg_timers.sp"
#include "rpg/rpg_functions.sp"
#include "rpg/rpg_events.sp"
#include "rpg/rpg_database.sp"