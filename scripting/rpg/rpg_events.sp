// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action:Event_Occurred(Handle:event, String:event_name[], bool:dontBroadcast) {

	new a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	decl String:EventName[PLATFORM_MAX_PATH];

	for (new i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:EventSection, 0, EventName, sizeof(EventName));

		if (StrEqual(EventName, event_name)) {

			Call_Event(event, event_name, dontBroadcast, i);
			break;
		}
	}
}

public SubmitEventHooks(value) {

	new size = GetArraySize(a_Events);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		HookSection = GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:HookSection, 0, text, sizeof(text));
		if (StrEqual(text, "player_hurt", false)) {

			if (value == 0) UnhookEvent(text, Event_Occurred, EventHookMode_Pre);
			else HookEvent(text, Event_Occurred, EventHookMode_Pre);
		}
		else {

			if (value == 0) UnhookEvent(text, Event_Occurred);
			else HookEvent(text, Event_Occurred);
		}
	}
}

public Call_Event(Handle:event, String:event_name[], bool:dontBroadcast, pos) {

	if (!b_IsActiveRound) return;		// don't track ANYTHING when it's not an active round.

	decl String:weapon[64];
	decl String:key[64];
	if (StrEqual(event_name, "player_hurt")) GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (StrEqual(event_name, "finale_radio_start")) {

		// When the finale is active, players can earn experience whilst camping (not moving from a spot, re: farming)
		b_IsFinaleActive = true;
		b_IsVehicleReady = false;

		PrintToChatAll("%t", "Farming Prevention Disabled", white, orange, white, orange, white, blue);
	}
	if (StrEqual(event_name, "finale_vehicle_ready")) {

		// When the vehicle arrives, the finale is no longer active, but no experience can be earned. This stops farming.
		b_IsFinaleActive = false;
		b_IsVehicleReady = true;

		PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
	}
	new damagetype					= -1;

	CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);

	new a_Size						= 0;
	a_Size							= GetArraySize(CallKeys);

	decl String:s_key[PLATFORM_MAX_PATH];
	decl String:s_value[PLATFORM_MAX_PATH];

	// Declare the values that can be defined by the event config, so we know whether to consider them.

	new attacker					= 0;
	new victim						= -1;		// can't set to 0 because sometimes 0 means common infected.
	new bool:headshot				= false;
	new healthvalue					= 0;
	new isdamageaward				= 0;
	new sameteam					= 0;
	new deathaward					= 0;

	new originvalue					= 0;
	new distancevalue				= 0;
	new Float:multiplierpts			= 0.0;
	new Float:multiplierexp			= 0.0;

	new RPGMode						= StringToInt(GetConfigValue("rpg mode?"));	// 1 experience 2 experience & points

	decl String:infectedpassives[PLATFORM_MAX_PATH];
	decl String:EventName[PLATFORM_MAX_PATH];
	decl String:AbilityUsed[PLATFORM_MAX_PATH];
	decl String:abilities[PLATFORM_MAX_PATH];

	new tagability					= 0;
	new tagexperience				= 0;
	new Float:tagpoints				= 0.0;
	new bool:explosion				= false;
	new healing						= 0;
	new spawnevent					= 0;
	new isshoved					= 0;
	new bulletimpact				= 0;
	new isinsaferoom				= 0;

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:CallKeys, i, s_key, sizeof(s_key));
		GetArrayString(Handle:CallValues, i, s_value, sizeof(s_value));

		if (StrEqual(s_key, "event name?")) Format(EventName, sizeof(EventName), "%s", s_value);
		if (StrEqual(EventName, event_name)) {
		
			if (StrEqual(s_key, "perpetrator?")) attacker											= GetClientOfUserId(GetEventInt(event, s_value));
			else if (StrEqual(s_key, "victim?")) victim												= GetClientOfUserId(GetEventInt(event, s_value));
			else if (StrEqual(s_key, "headshot?") && StrEqual(s_value, "1")) headshot				= GetEventBool(event, "headshot");
			else if (StrEqual(s_key, "damage type?")) damagetype									= GetEventInt(event, s_value);
			else if (StrEqual(s_key, "health?")) healthvalue										= GetEventInt(event, s_value);
			else if (StrEqual(s_key, "damage award?")) isdamageaward								= StringToInt(s_value);
			else if (StrEqual(s_key, "healing?")) healing											= StringToInt(s_value);
			else if (StrEqual(s_key, "same team?")) sameteam										= StringToInt(s_value);
			else if (StrEqual(s_key, "death award?")) deathaward									= StringToInt(s_value);
			else if (StrEqual(s_key, "abilities?")) Format(abilities, sizeof(abilities), "%s", s_value);
			else if (StrEqual(s_key, "infected passives?")) Format(infectedpassives, sizeof(infectedpassives), "%s", s_value);
			else if (StrEqual(s_key, "tag ability?")) tagability									= StringToInt(s_value);
			else if (StrEqual(s_key, "explosion?") && StrEqual(s_value, "1")) explosion				= GetEventBool(event, "exploded");
			else if (StrEqual(s_key, "tag experience?")) tagexperience								= StringToInt(s_value);
			else if (StrEqual(s_key, "tag points?")) tagpoints										= StringToFloat(s_value);
			else if (StrEqual(s_key, "origin?")) originvalue										= StringToInt(s_value);
			else if (StrEqual(s_key, "distance?")) distancevalue									= StringToInt(s_value);
			else if (StrEqual(s_key, "multiplier points?")) multiplierpts							= StringToFloat(s_value);
			else if (StrEqual(s_key, "multiplier exp?")) multiplierexp								= StringToFloat(s_value);
			else if (StrEqual(s_key, "spawn event?")) spawnevent									= StringToInt(s_value);
			else if (StrEqual(s_key, "shoved?")) isshoved											= StringToInt(s_value);
			else if (StrEqual(s_key, "bulletimpact?")) bulletimpact									= StringToInt(s_value);
			else if (StrEqual(s_key, "entered saferoom?")) isinsaferoom									= StringToInt(s_value);
			else if (StrEqual(s_key, "EOM")) break;
		}
	}

	if ((IsLegitimateClient(attacker) && !IsFakeClient(attacker) && b_IsLoading[attacker]) || (IsLegitimateClient(victim) && !IsFakeClient(victim) && b_IsLoading[victim])) return;
	if (attacker > 0 && IsLegitimateClient(attacker) && !IsFakeClient(attacker) && PlayerLevel[attacker] == 0 && !b_IsLoading[attacker]) {

		GetClientAuthString(attacker, key, sizeof(key));
		b_IsLoading[attacker] = true;
		ResetData(attacker);
		ClearAndLoad(key);
		return;
	}
	if (victim > 0 && IsLegitimateClient(victim) && !IsFakeClient(victim) && PlayerLevel[victim] == 0 && !b_IsLoading[victim]) {

		GetClientAuthString(victim, key, sizeof(key));
		b_IsLoading[victim] = true;
		ResetData(victim);
		ClearAndLoad(key);
		return;
	}

	if (attacker > 0 && IsLegitimateClient(attacker) && !IsFakeClient(attacker)) {

		if (!b_HandicapLocked[attacker]) {

			b_HandicapLocked[attacker] = true;
			PrintToChat(attacker, "%T", "handicap locked until end of round", attacker, white, green, white, orange);
		}
		//if (GetClientTeam(attacker) == TEAM_SURVIVOR && b_HardcoreMode[attacker]) EnableHardcoreMode(attacker);
		b_ActiveThisRound[attacker] = true;
	}
	if (victim > 0 && IsLegitimateClient(victim) && !IsFakeClient(victim)) b_ActiveThisRound[victim] = true;

	// Check if the player entered the saferoom or left it
	if (attacker > 0 && IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

		if (isinsaferoom == 1) b_IsInSaferoom[attacker] = true;
	}
	// When a survivor bot kills special infected, we still want to award players for their earnings, so we do that here.
	// However, special abilities don't fire, for obvious reasons.
	if (deathaward && IsLegitimateClient(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

		SurvivorsKilled++;
		GetClientAbsOrigin(victim, Float:DeathLocation[victim]);
		FindAbilityByTrigger(victim, attacker, 'A', FindZombieClass(victim), 0);
	}
	if (isshoved && IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) != GetClientTeam(attacker)) {

		FindAbilityByTrigger(victim, attacker, 'H', FindZombieClass(victim), 0);
	}
	if (deathaward && IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		if (IsLegitimateClientAlive(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsIncapacitated(attacker)) {

			FindAbilityByTrigger(attacker, attacker, 'k', FindZombieClass(attacker), 0);
		}

		if (IsFakeClient(victim)) b_IsImmune[victim] = false;
		if (ReadyUp_GetGameMode() == 2) {

			// Versus, do tanks have a cooldown?
			if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("versus tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

				f_TankCooldown				=	StringToFloat(GetConfigValue("versus tank cooldown?"));

				CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (ReadyUp_GetGameMode() == 1) {

			if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("director tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

				f_TankCooldown				=	StringToFloat(GetConfigValue("versus tank cooldown?"));

				CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		DamageMultiplierBase[victim] = 0.0;
		SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		if (b_IsLegacyMode) LegacyItemRoll(victim, attacker, false);
		SpawnItemChance(victim, attacker);
		CalculateDamageAward(victim);
	}
	if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) return;	// survivor bots don't participate in the mod, yet.
	if (isdamageaward == 1 && attacker == 0) {

		GetEventString(event, "weapon", weapon, sizeof(weapon));
		ExperienceLevel_Bots += StringToInt(GetConfigValue("common infected director experience?"));
		if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
		if (damagetype != 8 && damagetype != 268435464 && !StrEqual(weapon, "inferno")) {

			Points_Director += (StringToFloat(GetConfigValue("common infected director points?")) * LivingHumanSurvivors());
			//ExperienceLevel_Bots += StringToInt(GetConfigValue("common infected director experience?"));

			//if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);

			// Check to see if the player is currently handing out bile damage to players who have them tagged, because common infected count!
			if (IsLegitimateClientAlive(victim) && !IsFakeClient(victim)) {

				if (GetClientTeam(victim) == TEAM_SURVIVOR && b_IsJumping[victim]) ModifyGravity(victim);
				if (GetClientTeam(victim) == TEAM_SURVIVOR && !IsIncapacitated(victim)) {

					//SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);

					// Commons do damage based on the # of survivor players, who are alive.
					//new CommonsDamage = RoundToCeil(StringToFloat(GetConfigValue("director common damage per player?")) * LivingSurvivors());

					// The damage bonus that commons deal is based on each individual players handicap level.

					if (HandicapLevel[victim] != -1) {

						new CommonsDamage = 0;
						new Float:hardcoreDamageBonus = 1.0;
						if (b_HardcoreMode[victim]) hardcoreDamageBonus += StringToFloat(GetConfigValue("damage increase hardcore?"));

						CommonsDamage = RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase commons?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase commons level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase commons multiplier?")))));

						//if (b_HardcoreMode[victim]) CommonsDamage += (CommonsDamage * StringToFloat(GetConfigValue("damage increase hardcore?")));
						if (!IsIncapacitated(victim) && GetClientTotalHealth(victim) > CommonsDamage) SetClientTotalHealth(victim, CommonsDamage); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
						else if (!IsIncapacitated(victim) && GetClientTotalHealth(victim) <= CommonsDamage) {

							if (b_HardcoreMode[victim]) {

								SetEntityRenderMode(victim, RENDER_NORMAL);
								SetEntityRenderColor(victim, 255, 255, 255, 255);
								b_HardcoreMode[victim] = false;
								PreviousRoundIncaps[victim] = 1;
								HandicapLevel[victim] = -1;
								StopSound(victim, SNDCHAN_AUTO, "player/heartbeatloop.wav");
								ForcePlayerSuicide(victim);
								HandicapReductionCheck(victim);
							}
							else IncapacitateOrKill(victim);
						}
					}
					
				}

				for (new i = 1; i <= MaxClients; i++) {

					if (IsClientInGame(i) && GetClientTeam(i) != GetClientTeam(victim) && CoveredInBile[victim][i] >= 0) {

						CoveredInBile[victim][i]++;
					}
				}
			}
		}
	}
	if (IsLegitimateClientAlive(attacker)) {

		if (bulletimpact == 1 && GetClientTeam(attacker) == TEAM_SURVIVOR && StringToInt(GetConfigValue("trails enabled?")) == 1) {

			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");

			new Float:EyeCoords[3];
			GetClientEyePosition(attacker, EyeCoords);
			// Adjust the coords so they line up with the gun
			EyeCoords[2] += -5.0;

			new TrailsColours[4];
			TrailsColours[3] = 200;

			decl String:ClientModel[64];
			GetClientModel(attacker, ClientModel, sizeof(ClientModel));

			new bulletsize		= GetArraySize(a_Trails);
			for (new i = 0; i < bulletsize; i++) {

				TrailsKeys[attacker] = GetArrayCell(a_Trails, i, 0);
				TrailsValues[attacker] = GetArrayCell(a_Trails, i, 1);

				if (StrEqual(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "model affected?"), ClientModel)) {

					TrailsColours[0]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "red?"));
					TrailsColours[1]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "green?"));
					TrailsColours[2]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "blue?"));
					break;
				}
			}

			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsLegitimateClient(i) && !IsFakeClient(i)) {

					TE_SetupBeamPoints(EyeCoords, Coords, g_iSprite, 0, 0, 0, 0.06, 0.09, 0.09, 1, 0.0, TrailsColours, 0);
					TE_SendToClient(i);
				}
			}
		}
		if (StrEqual(EventName, "ability_use")) {

			GetEventString(event, "ability", AbilityUsed, sizeof(AbilityUsed));
			if (StrContains(AbilityUsed, abilities, false) != -1) {

				// check for any abilities that are based on abilityused.
				if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) {

					GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
					FindAbilityByTrigger(attacker, 0, 'A', ZOMBIECLASS_HUNTER, healthvalue);
				}
				else if (FindZombieClass(attacker) == ZOMBIECLASS_SPITTER) FindAbilityByTrigger(attacker, 0, 'A', ZOMBIECLASS_SPITTER, healthvalue);
			}
		}
		else if (spawnevent || StrEqual(EventName, "player_spawn")) {

			OriginalHealth[attacker] = GetClientHealth(attacker);
			SetBaseHealth(attacker);
			DefaultHealth[attacker] = OriginalHealth[attacker];
			if (IsClientInGame(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && NoHumanInfected()) {

				InfectedBotSpawn(attacker);
			}
			else PlayerSpawnAbilityTrigger(attacker);

			if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

				// Hook the infected player so they can't take melee weapon damage.
				SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		if (originvalue > 0 || distancevalue > 0) {

			if (originvalue == 1) {

				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
			}
			if (originvalue == 2) {

				GetClientAbsOrigin(attacker, Float:f_OriginEnd[attacker]);
			}

			if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY || (distancevalue == 2 && t_Distance[attacker] > 0)) {

				if (distancevalue == 1) t_Distance[attacker] = GetTime();
				if (distancevalue == 2) {

					t_Distance[attacker] = GetTime() - t_Distance[attacker];
					multiplierexp *= t_Distance[attacker];
					multiplierpts *= t_Distance[attacker];
					t_Distance[attacker] = 0;

				}
			}
			else {

				if (distancevalue == 3 && IsLegitimateClientAlive(victim)) GetClientAbsOrigin(victim, Float:f_OriginStart[attacker]);
				if (distancevalue == 2 || originvalue == 2 || distancevalue == 4 && IsLegitimateClientAlive(victim)) {

					if (distancevalue == 4) GetClientAbsOrigin(victim, Float:f_OriginEnd[attacker]);

					new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					multiplierexp *= Distance;
					multiplierpts *= Distance;
				}
			}
			if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {

				if (RPGMode >= 1 && multiplierexp > 0.0) {

					ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
					ExperienceOverall[attacker] += RoundToCeil(multiplierexp);
					if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

						ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
						ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
					}
					if (StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "distance experience", attacker, white, green, RoundToCeil(multiplierexp), white);
				}
				if (RPGMode != 1 && multiplierpts > 0.0) {

					Points[attacker] += multiplierpts;
					if (StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "distance points", attacker, white, green, multiplierpts, white);
				}
			}
		}
		if (healing > 0 && IsLegitimateClientAlive(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			if (healing == 1) {

				if (b_HardcoreMode[victim]) L4D_StaggerPlayer(attacker, victim, NULL_VECTOR);
				else t_Healing[attacker] = GetClientHealth(victim);
			}
			if (healing == 2) {

				LoadHealthMaximum(victim);
				GiveMaximumHealth(victim);
				t_Healing[attacker] = GetMaximumHealth(victim) - t_Healing[attacker];
				ReadyUp_NtvFriendlyFire(attacker, victim, 0 - t_Healing[attacker], GetClientHealth(victim), 0, 0);

				if (attacker != victim) {

					multiplierpts += (0.01 * PlayerLevel[victim]);
					multiplierexp += (0.01 * PlayerLevel[victim]);
					multiplierexp *= t_Healing[attacker];
					if (RPGMode >= 1 && multiplierexp > 0.0) {

						ExperienceLevel[victim] += RoundToCeil(multiplierexp);
						ExperienceOverall[victim] += RoundToCeil(multiplierexp);
						if (ExperienceLevel[victim] > CheckExperienceRequirement(victim)) {

							ExperienceOverall[victim] -= (ExperienceLevel[victim] - CheckExperienceRequirement(victim));
							ExperienceLevel[victim] = CheckExperienceRequirement(victim);
						}
						PrintToChat(victim, "%T", "healing experience", victim, white, green, RoundToCeil(multiplierexp), white);
					}
					if (RPGMode != 1 && multiplierpts > 0.0) {

						multiplierpts *= t_Healing[attacker];
						Points[victim] += multiplierpts;
						PrintToChat(victim, "%T", "healing points", victim, white, green, multiplierpts, white);
					}
				}
			}
			if (healing == 3 && attacker != victim) {

				ReadyUp_NtvFriendlyFire(attacker, victim, 0 - GetReviveHealth(), GetClientHealth(victim), 0, 0);

				FindAbilityByTrigger(attacker, victim, 'r', FindZombieClass(attacker), healthvalue);

				multiplierexp += (0.01 * PlayerLevel[victim]);
				multiplierpts += (0.01 * PlayerLevel[victim]);

				if (RPGMode >= 1 && multiplierexp > 0.0) {


					ExperienceLevel[victim] += RoundToCeil(multiplierexp);
					ExperienceOverall[victim] += RoundToCeil(multiplierexp);
					if (ExperienceLevel[victim] > CheckExperienceRequirement(victim)) {

						ExperienceOverall[victim] -= (ExperienceLevel[victim] - CheckExperienceRequirement(victim));
						ExperienceLevel[victim] = CheckExperienceRequirement(victim);
					}
					PrintToChat(victim, "%T", "assisting experience", victim, white, green, RoundToCeil(multiplierexp), white);
				}
				if (RPGMode != 1 && multiplierpts > 0.0) {

					Points[victim] += multiplierpts;
					PrintToChat(victim, "%T", "assisting points", victim, white, green, multiplierpts, white);
				}
			}
		}
	}
	if (deathaward && IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !IsClientActual(victim) && victim == 0) {

		new cliententity = GetEventInt(event, "entityid");
		if (b_IsLegacyMode) LegacyItemRoll(cliententity, attacker, true);
		else SpawnItemChance(cliententity, attacker);
		CommonsKilled++;

		if (headshot) {

			CommonKillsHeadshot[attacker]++;

			if (CommonKillsHeadshot[attacker] >= StringToInt(GetConfigValue("common headshot award required?"))) {

				ExperienceLevel[attacker] += StringToInt(GetConfigValue("common headshot experience award?"));
				ExperienceOverall[attacker] += StringToInt(GetConfigValue("common headshot experience award?"));
				if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

					ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
					ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
				}
				if (StringToInt(GetConfigValue("display common headshot award?")) == 1) PrintToChat(attacker, "%T", "common headshot award", attacker, white, green, GetConfigValue("common headshot experience award?"), white);
				CommonKillsHeadshot[attacker] = 0;
				if (StringToInt(GetConfigValue("hint text broadcast?")) == 1) ExperienceBarBroadcast(attacker);
			}
		}

		CommonKills[attacker]++;
		if (CommonKills[attacker] >= StringToInt(GetConfigValue("common kills award required?"))) {

			ExperienceLevel[attacker] += StringToInt(GetConfigValue("common experience award?"));
			ExperienceOverall[attacker] += StringToInt(GetConfigValue("common experience award?"));
			if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

				ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
				ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
			}
			if (StringToInt(GetConfigValue("display common kills award?")) == 1) PrintToChat(attacker, "%T", "common kills award", attacker, white, green, GetConfigValue("common experience award?"), white);
			CommonKills[attacker] = 0;
			if (StringToInt(GetConfigValue("hint text broadcast?")) == 1) ExperienceBarBroadcast(attacker);
		}
		FindAbilityByTrigger(attacker, 0, 'C', FindZombieClass(attacker), healthvalue);
	}
	if (IsLegitimateClient(victim) && IsLegitimateClientAlive(attacker)) {

		if (GetClientTeam(victim) != GetClientTeam(attacker) && sameteam == 0 || GetClientTeam(victim) == GetClientTeam(attacker) && sameteam == 1 || sameteam == 2) {

			if (StrEqual(EventName, "player_incapacitated")) {

				if (GetClientTeam(victim) == TEAM_SURVIVOR && GetClientTeam(attacker) != GetClientTeam(victim)) {

					if (b_HardcoreMode[victim]) {

						SetEntityRenderMode(victim, RENDER_NORMAL);
						SetEntityRenderColor(victim, 255, 255, 255, 255);
						b_HardcoreMode[victim] = false;
						PreviousRoundIncaps[victim] = 1;
						HandicapLevel[victim] = -1;
						StopSound(victim, SNDCHAN_AUTO, "player/heartbeatloop.wav");
						ForcePlayerSuicide(victim);
					}
					else {

						RoundIncaps[victim]++;

						if (L4D2_GetInfectedAttacker(victim) == -1) FindAbilityByTrigger(victim, attacker, 'n', FindZombieClass(victim), healthvalue);
						else if (IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker)) {
							
							CreateTimer(1.0, Timer_IsIncapacitated, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							FindAbilityByTrigger(victim, attacker, 'N', FindZombieClass(victim), healthvalue);
							if (L4D2_GetInfectedAttacker(victim) == attacker) FindAbilityByTrigger(attacker, victim, 'm', FindZombieClass(attacker), healthvalue);
							else FindAbilityByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'm', FindZombieClass(victim), healthvalue);
						}
					}
				}
			}

			if (tagability) {

				if (!IsFakeClient(attacker)) ExperienceLevel[attacker] += tagexperience;
				else ExperienceLevel_Bots += tagexperience;
				if (!IsFakeClient(attacker)) {

					ExperienceOverall[attacker] += tagexperience;
					if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

						ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
						ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
					}
				}
				if (!IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "Tag Experience", attacker, white, green, white, tagexperience);
				if (!IsFakeClient(attacker)) Points[attacker] += tagpoints;
				else Points_Director += tagpoints;
				if (!IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "Tag Points", attacker, white, green, white, tagpoints);

				if (!IsFakeClient(attacker) && CoveredInBile[victim][attacker] < 0) {

					CoveredInBile[victim][attacker] = 0;

					new Handle:pack;
					CreateDataTimer(StringToFloat(GetConfigValue("default bile points time?")), Timer_CoveredInBile, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(pack, attacker);
					WritePackCell(pack, victim);
				}
				if (StringToInt(GetConfigValue("display tag text?")) == 1 && !IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "tag player", attacker, white, green, tagexperience, white);

				FindAbilityByTrigger(attacker, victim, 'i', FindZombieClass(attacker), healthvalue);
				FindAbilityByTrigger(victim, attacker, 'I', FindZombieClass(victim), healthvalue);
			}
			// Hey, the player earns damage points. Sameteam = 2 means doesn't matter if they're the same team.
			if (isdamageaward == 1) {

				if (GetClientTeam(attacker) != GetClientTeam(victim)) {

					BaseDamageMultiplier(attacker, weapon);

					if (GetClientTeam(victim) == TEAM_INFECTED && IsPlayerAlive(victim) || GetClientTeam(victim) == TEAM_SURVIVOR && IsPlayerAlive(victim) && !IsIncapacitated(victim)) {

						RestoreClientTotalHealth(victim, healthvalue);
					}

					if (GetClientTeam(attacker) == TEAM_INFECTED && GetClientTeam(victim) == TEAM_SURVIVOR && !IsIncapacitated(victim)) {	// Damage modifying only occurs on players who are not incapacitated.

						if (b_IsJumping[victim]) ModifyGravity(victim);
						FindAbilityByTrigger(attacker, victim, 'D', FindZombieClass(attacker), healthvalue);
						FindAbilityByTrigger(victim, attacker, 'L', FindZombieClass(victim), healthvalue);

						new handicapDamageBonus = 0;
						new Float:hardcoreDamageBonus = 1.0;
						if (b_HardcoreMode[victim]) hardcoreDamageBonus += StringToFloat(GetConfigValue("damage increase hardcore?"));
						if (HandicapLevel[victim] != -1) {

							if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase hunter?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase hunter level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase hunter multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_SMOKER) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase smoker?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase smoker level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase smoker multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_BOOMER) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase boomer?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase boomer level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase boomer multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase jockey?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase jockey level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase jockey multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_SPITTER) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase spitter?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase spitter level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase spitter multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_CHARGER) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase charger?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase charger level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase charger multiplier?")))));
							else if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) handicapDamageBonus += RoundToCeil(healthvalue * (((HandicapLevel[victim] * StringToFloat(GetConfigValue("damage increase tank?"))) * hardcoreDamageBonus) + (PlayerLevel[victim] * StringToFloat(GetConfigValue("damage increase tank level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase tank multiplier?")))));
						}
						new totalIncomingDamage = (RoundToFloor(DamageMultiplier[attacker] * healthvalue) + handicapDamageBonus);
						if (totalIncomingDamage >= GetClientTotalHealth(victim)) IncapacitateOrKill(victim, attacker);
						else SetClientTotalHealth(victim, totalIncomingDamage);

						DamageAward[attacker][victim] += (RoundToFloor(DamageMultiplier[attacker] * healthvalue));	// handicap bonus does not calculate into experience or round earnings.
						RoundDamageTotal += healthvalue;
						RoundDamage[attacker] += healthvalue;
					}
					else if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED &&
							damagetype != 8 && damagetype != 268435464 && !StrEqual(weapon, "inferno") && IsPlayerAlive(victim) &&
							!RestrictedWeaponList(weapon)) {

						FindAbilityByTrigger(attacker, victim, 'D', FindZombieClass(attacker), healthvalue);
						FindAbilityByTrigger(victim, attacker, 'L', FindZombieClass(victim), healthvalue);
						if (RoundToFloor(DamageMultiplier[attacker] * healthvalue) >= GetClientTotalHealth(victim)) ForcePlayerSuicide(victim);	// We'll have to make a talent that, instead of suicide restores health, just for infected, as survivors have rebirth.
						else SetClientTotalHealth(victim, RoundToFloor(DamageMultiplier[attacker] * healthvalue));

						DamageAward[attacker][victim] += (RoundToFloor(DamageMultiplier[attacker] * healthvalue));
						RoundDamageTotal += healthvalue;
						RoundDamage[attacker] += healthvalue;
					}

					if (StrEqual(weapon, "insect_swarm")) FindAbilityByTrigger(attacker, victim, 'T', FindZombieClass(attacker), healthvalue);

					if (L4D2_GetInfectedAttacker(victim) == attacker) FindAbilityByTrigger(victim, attacker, 's', FindZombieClass(victim), healthvalue);
					if (GetClientTeam(victim) == TEAM_SURVIVOR && L4D2_GetInfectedAttacker(victim) != -1) {

						// If the infected player dealing the damage isn't the player hurting the victim, we give the victim a chance to strike at both! This is balance!
						FindAbilityByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'V', FindZombieClass(victim), healthvalue);
						if (attacker != L4D2_GetInfectedAttacker(victim)) FindAbilityByTrigger(victim, attacker, 'V', FindZombieClass(victim), healthvalue);
					}
					if (GetClientTeam(attacker) == TEAM_INFECTED && L4D2_GetSurvivorVictim(attacker) != -1) FindAbilityByTrigger(attacker, L4D2_GetSurvivorVictim(attacker), 'v', FindZombieClass(attacker), healthvalue);

					if (CoveredInBile[victim][attacker] >= 0) CoveredInBile[victim][attacker]++;
					if (GetClientTeam(attacker) == TEAM_SURVIVOR && L4D2_GetSurvivorVictim(victim) != -1) FindAbilityByTrigger(victim, attacker, 't', FindZombieClass(victim), healthvalue);
				}
				else if (GetClientTeam(attacker) == GetClientTeam(victim)) {

					if (damagetype != 8 && damagetype != 268435464 && !StrEqual(weapon, "inferno")) {

						new FFIncrease			= StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingSurvivors();
						if (!IsIncapacitated(victim) && GetClientHealth(victim) <= FFIncrease) FFIncrease			= GetClientHealth(victim);

						//ReadyUp_NtvFriendlyFire(attacker, victim, (StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingHumanSurvivors()) + healthvalue, GetClientHealth(victim), 0);
						if (!b_HardcoreMode[victim]) ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 0, FFIncrease);

						// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
						FindAbilityByTrigger(attacker, victim, 'd', FindZombieClass(attacker), healthvalue);
						FindAbilityByTrigger(victim, attacker, 'l', FindZombieClass(victim), healthvalue);
					}
					else {

						if (!b_HardcoreMode[victim]) ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
					}
				}
			}
			if (deathaward && (GetClientTeam(victim) == TEAM_SURVIVOR || GetClientTeam(victim) == TEAM_INFECTED)) {

				HandicapReductionCheck(victim);

				if (GetClientTeam(attacker) != GetClientTeam(victim)) {

					FindAbilityByTrigger(attacker, victim, 'e', FindZombieClass(attacker), healthvalue);
					FindAbilityByTrigger(victim, attacker, 'E', FindZombieClass(victim), healthvalue);
				}
				if (explosion) {

					FindAbilityByTrigger(attacker, victim, 'x', FindZombieClass(attacker), healthvalue);
					FindAbilityByTrigger(victim, attacker, 'X', FindZombieClass(victim), healthvalue);
					// ability trigger goes here for explosion.
				}
			}
		}
	}
}

stock EndOfMapAwardChance(client) {

	if (IsClientActual(client) && GetClientTeam(client) != TEAM_SPECTATOR && IsPlayerAlive(client) && !IsIncapacitated(client) && (IsReserve(client) || StringToInt(GetConfigValue("all players end of map rolls?")) == 1) && bIsEligibleMapAward[client]) {

		new rollchances		= StringToInt(GetConfigValue("number of end of map rolls?"));
		decl String:Name[64];
		GetClientName(client, Name, sizeof(Name));
		decl String:EName[64];
		decl String:NameTranslation[64];

		for (new i = 0; i < rollchances; i++) {

			if (IsSlateChance(client, true)) {

				PrintToChatAll("%t", "SLATE Award (end of map roll)", blue, Name, white, orange, white, white, orange, white);
				SlatePoints[client]++;
			}
			else {

				new pos = -1;
				pos = IsStoreChance(client, client, true);
				if (pos >= 0) {

					Format(EName, sizeof(EName), "%s", StoreItemName(client, pos));

					IsStoreItem(client, EName, true);
					for (new ii = 1; ii <= MaxClients; ii++) {

						if (IsClientInGame(ii) && !IsFakeClient(ii)) {

							Format(NameTranslation, sizeof(NameTranslation), "%T", EName, ii);
							PrintToChat(ii, "%T", "Store Item Award (end of map roll)", ii, blue, Name, white, orange, NameTranslation, white, white, orange, white);
						}
					}
				}
				else {

					pos = -1;
					pos = IsLockedTalentChance(client, true);
					if (pos >= 0) {

						GetArrayString(Handle:a_Database_Talents_Defaults_Name, pos, EName, sizeof(EName));
						if (IsTalentLocked(client, EName)) UnlockTalent(client, EName, true);
					}
				}
			}
		}
	}
}

stock SpawnItemChance(client, attacker) {

	if (HumanPlayersInGame() >= StringToInt(GetConfigValue("required humans for item drops?"))) {

		if (IsClientActual(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !AnySurvivorsIncapacitated()) {

			if (IsSlateChance(client)) AwardSlatePoints(client);
			else {

				new pos = -1;
				pos = IsStoreChance(client, attacker);	// This method only allows one store item to drop, in the rare event that multiple would have dropped.
				if (pos >= 0) AwardStoreItems(client, attacker, pos);
				else {

					pos = -1;
					pos = IsLockedTalentChance(client);
					if (pos >= 0) AwardLockedTalentItems(client, pos);
				}
			}
		}
	}
}

stock bool:IsSlateChance(client, bool:bIsEndOfMapRoll = false) {

	new random = 0;
	if (!bIsEndOfMapRoll) {

		if (IsClientActual(client) && FindZombieClass(client) != ZOMBIECLASS_TANK) random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("slate chance specials?")));
		else if (IsClientActual(client) && FindZombieClass(client) == ZOMBIECLASS_TANK) random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("slate chance bosses?")));
		else random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("slate chance commons?")));
	}
	else random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("slate chance end of map roll?")));
	random = GetRandomInt(1, random);

	if (random == 1) return true;
	return false;
}

stock IsLockedTalentChance(client, bool:bIsEndOfMapRoll = false) {

	new random = 0;
	decl String:text[64];
	new size		= GetArraySize(a_Database_Talents_Defaults);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents_Defaults, i, text, sizeof(text));

		if (StringToInt(text) == 0) {	// talent is not inherited

			if (!bIsEndOfMapRoll) {

				if (IsClientActual(client) && FindZombieClass(client) != ZOMBIECLASS_TANK) random			= RoundToCeil(1.0 / StringToFloat(GetConfigValue("locked talent special chance?")));
				else if (IsClientActual(client) && FindZombieClass(client) == ZOMBIECLASS_TANK) random		= RoundToCeil(1.0 / StringToFloat(GetConfigValue("locked talent tank chance?")));
				else random																					= RoundToCeil(1.0 / StringToFloat(GetConfigValue("locked talent common chance?")));
			}
			else random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("talent chance end of map roll?")));
			random			= GetRandomInt(1, random);
			if (random == 1) return i;
		}
	}
	return -1;
}

stock AwardLockedTalentItems(client, pos) {

	decl String:Name[64];
	GetArrayString(Handle:a_Database_Talents_Defaults_Name, pos, Name, sizeof(Name));

	new entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", Name);
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "glowstate", GetConfigValue("store item glow?"));
	DispatchKeyValue(entity, "solid", GetConfigValue("store item state?"));
	DispatchKeyValue(entity, "model", GetConfigValue("locked talent model?"));
	DispatchSpawn(entity);

	new Float:vel[3];
	vel[0] = GetRandomFloat(-500.0, 500.0);
	vel[1] = GetRandomFloat(-500.0, 500.0);
	vel[2] = GetRandomFloat(10.0, 500.0);

	new Float:origin[3];
	if (IsClientActual(client)) GetClientAbsOrigin(client, Float:origin);
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		LogMessage("Creating talent on common zombie at origin: %3.3f %3.3f %3.3f", origin[0], origin[1], origin[2]);
	}
	origin[2] += 128.0;
	TeleportEntity(entity, Float:origin, NULL_VECTOR, vel);

	//CreateTimer(StringToFloat(GetConfigValue("discovery item expiry time?")), Timer_DestroyDiscoveryItem, entity, TIMER_FLAG_NO_MAPCHANGE);
}

stock IsStoreChance(client, attacker, bool:bIsEndOfMapRoll = false) {

	//decl String:key[64];
	//decl String:value[64];

	new random				= 0;
	new size				= GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		StoreChanceKeys[attacker]				= GetArrayCell(a_Store, i, 0);
		StoreChanceValues[attacker]				= GetArrayCell(a_Store, i, 1);

		// There are some items a server operator may not WANT to be eligible to be awarded from world drops or end of map rolls. If that's the case, we skip it.
		if (StringToInt(GetKeyValue(StoreChanceKeys[attacker], StoreChanceValues[attacker], "store purchase only?")) == 1) continue;

		if (!bIsEndOfMapRoll) {

			if (IsClientActual(client) && FindZombieClass(client) != ZOMBIECLASS_TANK) {

				random								= RoundToCeil(1.0 / StringToFloat(GetKeyValue(StoreChanceKeys[attacker], StoreChanceValues[attacker], "special drop chance?")));
			}
			else if (IsClientActual(client) && FindZombieClass(client) == ZOMBIECLASS_TANK) {

				random								= RoundToCeil(1.0 / StringToFloat(GetKeyValue(StoreChanceKeys[attacker], StoreChanceValues[attacker], "tank drop chance?")));
			}
			else {

				random								= RoundToCeil(1.0 / StringToFloat(GetKeyValue(StoreChanceKeys[attacker], StoreChanceValues[attacker], "common drop chance?")));
			}
		}
		else random = RoundToCeil(1.0 / StringToFloat(GetConfigValue("store chance end of map roll?")));
		random									= GetRandomInt(1, random);
		if (random == 1) return i;
	}
	return -1;
}

stock String:StoreItemName(client, pos) {

	decl String:Name[64];
	StoreItemNameSection[client]					= GetArrayCell(a_Store, pos, 2);

	GetArrayString(StoreItemNameSection[client], 0, Name, sizeof(Name));

	return Name;
}

stock bool:IsStoreItem(client, String:EName[], bool:b_IsAwarding = true) {

	decl String:Name[64];
	new size				= GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		StoreItemSection[client]				= GetArrayCell(a_Store, i, 2);
		GetArrayString(StoreItemSection[client], 0, Name, sizeof(Name));

		if (StrEqual(Name, EName)) {

			if (b_IsAwarding) GiveClientStoreItem(client, i);
			return true;
		}
	}
	return false;
}

stock AwardStoreItems(client, attacker, pos) {

	new entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", StoreItemName(attacker, pos));
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "glowstate", GetConfigValue("store item glow?"));
	DispatchKeyValue(entity, "solid", GetConfigValue("store item state?"));
	DispatchKeyValue(entity, "model", GetConfigValue("store item model?"));
	DispatchSpawn(entity);

	new Float:vel[3];
	vel[0] = GetRandomFloat(-500.0, 500.0);
	vel[1] = GetRandomFloat(-500.0, 500.0);
	vel[2] = GetRandomFloat(10.0, 500.0);

	new Float:origin[3];
	if (IsClientActual(client)) GetClientAbsOrigin(client, Float:origin);
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		LogMessage("Creating store item on common zombie at origin: %3.3f %3.3f %3.3f", origin[0], origin[1], origin[2]);
	}
	origin[2] += 128.0;
	TeleportEntity(entity, Float:origin, NULL_VECTOR, vel);

	//CreateTimer(StringToFloat(GetConfigValue("discovery item expiry time?")), Timer_DestroyDiscoveryItem, entity, TIMER_FLAG_NO_MAPCHANGE);
}

stock AwardSlatePoints(client) {

	new entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", "slate");

	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "glowstate", GetConfigValue("slate item glow?"));
	DispatchKeyValue(entity, "solid", GetConfigValue("slate item state?"));

	DispatchKeyValue(entity, "model", GetConfigValue("slate item model?"));
	DispatchSpawn(entity);

	new Float:vel[3];
	vel[0] = GetRandomFloat(-500.0, 500.0);
	vel[1] = GetRandomFloat(-500.0, 500.0);
	vel[2] = GetRandomFloat(10.0, 500.0);

	new Float:origin[3];
	if (IsClientActual(client)) GetClientAbsOrigin(client, Float:origin);
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		LogMessage("Creating slate point on common zombie at origin: %3.3f %3.3f %3.3f", origin[0], origin[1], origin[2]);
	}
	origin[2] += 128.0;
	TeleportEntity(entity, Float:origin, NULL_VECTOR, vel);

	//CreateTimer(StringToFloat(GetConfigValue("discovery item expiry time?")), Timer_DestroyDiscoveryItem, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (IsLegitimateClientAlive(client) && !IsFakeClient(client)) {

		if (IsPlayerAlive(client)) {

			if (buttons & IN_JUMP) {

				if (L4D2_GetInfectedAttacker(client) == -1 && L4D2_GetSurvivorVictim(client) == -1 && (GetEntityFlags(client) & FL_ONGROUND) && !IsTanksActive()) {

					FindAbilityByTrigger(client, 0, 'j', FindZombieClass(client), 0);
				}
				if (L4D2_GetSurvivorVictim(client) != -1) {

					new victim = L4D2_GetSurvivorVictim(client);
					if ((GetEntityFlags(victim) & FL_ONGROUND)) FindAbilityByTrigger(client, victim, 'J', FindZombieClass(client), 0);
				}
			}
			else if (!(buttons & IN_JUMP) && b_IsJumping[client]) ModifyGravity(client);
		}
		if (IsPlayerAlive(client) && ((GetClientTeam(client) == TEAM_SURVIVOR && !AnySurvivorsIncapacitated()) || (!IsGhost(client) && GetClientTeam(client) == TEAM_INFECTED))) {

			if (buttons & IN_USE) {

				decl String:Name[MAX_NAME_LENGTH];
				GetClientName(client, Name, sizeof(Name));
				decl String:EName[64];

				new entity = GetClientAimTarget(client, false);

				if (entity != -1) {

					GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));

					if (!b_IsActiveRound) {

						// Don't let them pick up melee weapons, but allow everything else.
						decl String:Model[64];
						GetEntityClassname(entity, Model, sizeof(Model));
						if (StrEqual(Model, "weapon_melee_spawn")) return Plugin_Handled;
					}

					new Float:PPos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", PPos);
					new Float:EPos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EPos);
					new Float:Distance = GetVectorDistance(PPos, EPos);

					if (Distance <= StringToFloat(GetConfigValue("item distance?"))) {

						if (StrEqual(EName, "slate")) {

							PrintToChatAll("%t", "backpack roll", orange, Name, white);
							SlateItemRoll();
						}
						else if (IsStoreItem(client, EName, false)) {

							PrintToChatAll("%t", "backpack roll", orange, Name, white);
							StoreItemRoll(EName);
						}
						else if (IsTalentExists(EName)) {

							PrintToChatAll("%t", "backpack roll", orange, Name, white);
							UnlockTalentRoll(EName);
						}
						else return Plugin_Continue;

						if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
					}
					else return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

stock FindSlatePoints(bool:IsMaximum, maximum = 0) {

	new value = 0;
	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) {

			count		= Strength[i] + Luck[i] + Agility[i] + Technique[i] + Endurance[i] + SlatePoints[i];
			if (maximum == 0 && count > value) value = count;
			else if (maximum > 0 && count < value) value = count;
		}
	}
	return value;
}

stock GetTotalSlatePoints(client) {

	new count = Strength[client] + Luck[client] + Agility[client] + Technique[client] + Endurance[client] + SlatePoints[client];
	return count;
}

stock bool:AnyEligibleSlateClients(range) {

	new SlateMax = StringToInt(GetConfigValue("slate category maximum?"));
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && GetTotalSlatePoints(i) <= range &&
			Strength[i] < SlateMax ||
			Luck[i] < SlateMax ||
			Agility[i] < SlateMax ||
			Technique[i] < SlateMax ||
			Endurance[i] < SlateMax) return true;
	}
	return false;
}

stock bool:IsEligibleSlateClient(client) {

	new SlateMax = StringToInt(GetConfigValue("slate category maximum?"));
	if (Strength[client] < SlateMax || Luck[client] < SlateMax || Agility[client] < SlateMax || Technique[client] < SlateMax || Endurance[client] < SlateMax) return true;
	return false;
}

stock SlateItemRoll() {

	new max = FindSlatePoints(true);
	new min = FindSlatePoints(false, max);

	new breadth = GetRandomInt(min, max);
	// Only players who have total slate count at less than or equal to the breadth can be awarded the slate point.
	// This increases the chance that players less will get the slate point while decreasing the chance players with more will get it.

	new client = -1;
	while (IsPlayersParticipating() && AnyEligibleSlateClients(breadth) && client == -1) {

		client			= GetRandomInt(1, MaxClients);
		if (IsLegitimateClient(client) && !IsFakeClient(client) && GetClientTeam(client) != TEAM_SPECTATOR && IsEligibleSlateClient(client)) {

			SlatePoints[client]++;
			decl String:Name[64];
			GetClientName(client, Name, sizeof(Name));
			PrintToChatAll("%t", "SLATE Award Special", blue, Name, white, orange, white);
			return;
		}
		else client = -1;
	}
	PrintToChatAll("%t", "backpack fizzle", white, orange);
}

stock bool:IsEveryoneBoosterTime() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && !HasBoosterTime(i)) return false;
	}
	return true;
}

stock StoreItemRoll(String:StoreItemName[]) {

	decl String:NameTranslation[512];
	decl String:Name[64];
	new bool:b_IsPriorityRoll = IsEveryoneBoosterTime();
	new client = -1;
	while (IsPlayersParticipating() && client == -1) {

		client			= GetRandomInt(1, MaxClients);
		if (IsLegitimateClient(client) && !IsFakeClient(client) && GetClientTeam(client) != TEAM_SPECTATOR && (b_IsPriorityRoll || !HasBoosterTime(client))) {

			IsStoreItem(client, StoreItemName, true);
			GetClientName(client, Name, sizeof(Name));
			for (new i = 1; i <= MaxClients; i++) {

				if (IsClientInGame(i) && !IsFakeClient(i)) {

					Format(NameTranslation, sizeof(NameTranslation), "%T", StoreItemName, i);
					PrintToChat(i, "%T", "Store Item Award", i, blue, Name, white, orange, NameTranslation, white);
				}
			}
			return;
		}
		else client = -1;
	}
	PrintToChatAll("%t", "backpack fizzle", white, orange);
}

stock bool:IsAnyoneTalentLocked(String:TalentName[]) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && IsTalentLocked(i, TalentName)) return true;
	}
	return false;
}

stock UnlockTalentRoll(String:TalentName[]) {

	new client = -1;
	while (IsPlayersParticipating() && client == -1 && IsAnyoneTalentLocked(TalentName)) {

		client			= GetRandomInt(1, MaxClients);
		if (IsLegitimateClient(client) && !IsFakeClient(client) && GetClientTeam(client) != TEAM_SPECTATOR && IsTalentLocked(client, TalentName)) {

			UnlockTalent(client, TalentName);
			return;
		}
		else {

			client		= -1;
		}
	}
	PrintToChatAll("%t", "backpack fizzle", white, orange);
}

public CalculateDamageAward(client) {
	
	// Award the damage to the infected player who died, and then to all of the survivor players who hurt it.

	if (IsLegitimateClient(client)) {

		SpecialsKilled++;

		new RPGMode									= StringToInt(GetConfigValue("rpg mode?"));
		new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
		new InfExp									= 0;
		new Float:InfPoints							= 0.0;
		new SurvExp									= 0;
		new Float:SurvPoints						= 0.0;
		new InfTotalExp								= 0;
		new Float:InfTotalPoints					= 0.0;
		new RestedAwardBonus						= 0;
		new Float:teamworkExperienceMultiplier		= 0.0;
		new Float:teamworkPointsMultiplier			= 0.0;
		new Float:experienceMultiplierSurvivor		= StringToFloat(GetConfigValue("experience multiplier survivor?"));
		new Float:pointsMultiplierSurvivor			= StringToFloat(GetConfigValue("points multiplier survivor?"));

		decl String:InfectedName[PLATFORM_MAX_PATH];
		decl String:SurvivorName[PLATFORM_MAX_PATH];
		GetClientName(client, InfectedName, sizeof(InfectedName));
		if (IsFakeClient(client)) Format(InfectedName, sizeof(InfectedName), "%s %s", GetConfigValue("director team name?"), InfectedName);

		if (FindEligibleParticipants(client) > 0) AwardEligibleParticipants(client);

		for (new i = 1; i <= MaxClients; i++) {			// Calculate the damage award the infected player receives for every survivor he hurt.

			if (!IsClientInGame(i) || IsFakeClient(i) || i == client || GetClientTeam(i) != TEAM_SURVIVOR) continue;
			GetClientName(i, SurvivorName, sizeof(SurvivorName));

			/*if (HandicapLevel[client] != -1 && MapRoundsPlayed < StringToInt(GetConfigValue("difficulty leniency rounds required?"))) {

				DamageAward[client][i] = DamageAward[client][i] + RoundToCeil(DamageAward[client][i] * (HandicapLevel[client] * StringToFloat(GetConfigValue("handicap experience bonus?"))));
			}*/
			// Disabled handicap award bonuses when playing as infected until such handicap negative effects are introduced.
			InfExp = RoundToFloor(StringToFloat(GetConfigValue("experience multiplier infected?")) * DamageAward[client][i]);
			InfPoints = StringToFloat(GetConfigValue("points multiplier infected?")) * DamageAward[client][i];
			
			if (!IsFakeClient(client)) InfExp = RoundToCeil(CheckExperienceBooster(client, InfExp));
			if (RestedExperience[client] > 0) {

				RestedAwardBonus = RoundToFloor(InfExp * StringToFloat(GetConfigValue("rested experience multiplier?")));
				if (RestedAwardBonus > RestedExperience[client]) RestedAwardBonus = RestedExperience[client];

				InfExp += RestedAwardBonus;
				RestedExperience[client] -= RestedAwardBonus;
			}
			InfTotalExp += InfExp;
			InfTotalPoints += InfPoints;

			// Survivors don't earn experience if they've entered the saferoom this round.
			// They also don't earn experience if they are too close to a position where they've previously killed a special infected.
			// Special infected still earn experience from them in both scenarios.
			if (b_IsInSaferoom[i] || b_IsVehicleReady || CheckKillPositions(i, false)) {

				// If they're too close to where they were supposed to be, we act as if they never hurt the special infected to begin with.
				// This also occurs if the rescue vehicle has arrived.
				DamageAward[i][client] = 0;
			}
			if (DamageAward[i][client] > 0 && !CheckKillPositions(i, true)) {

				teamworkExperienceMultiplier		= TeamworkProximityMultiplier(i, true);
				teamworkPointsMultiplier			= TeamworkProximityMultiplier(i, false);

				// Add the survivors' current position to the list of kill spots, so they can't get experience if standing too close to this location, again, during the same round.
				// It prevents farming, as silly as it is to need a system like this...
				if (!IsIncapacitated(i) && HandicapLevel[i] != -1) {

					DamageAward[i][client] = DamageAward[i][client] + RoundToCeil(DamageAward[i][client] * (HandicapLevel[i] * StringToFloat(GetConfigValue("handicap experience bonus?"))));
				}
				SurvExp = RoundToFloor((experienceMultiplierSurvivor + teamworkExperienceMultiplier) * DamageAward[i][client]);
				SurvPoints = ((pointsMultiplierSurvivor + teamworkPointsMultiplier) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("points multiplier survivor count?")))) * DamageAward[i][client];
				if (IsIncapacitated(i)) {

					SurvPoints *= StringToFloat(GetConfigValue("points multiplier survivor incapped?"));
				}
				if (b_HardcoreMode[i]) {

					SurvExp += RoundToCeil(SurvExp * StringToFloat(GetConfigValue("experience bonus hardcore?")));
				}

				// Check to see if they have an experience booster active.
				SurvExp = RoundToCeil(CheckExperienceBooster(i, SurvExp));
				if (RestedExperience[i] > 0) {

					RestedAwardBonus = RoundToFloor(SurvExp * StringToFloat(GetConfigValue("rested experience multiplier?")));
					if (RestedAwardBonus > RestedExperience[i]) RestedAwardBonus = RestedExperience[i];

					SurvExp += RestedAwardBonus;
					RestedExperience[i] -= RestedAwardBonus;
				}
			}

			if (RPGMode > 0) {

				if (!IsFakeClient(client)) ExperienceLevel[client] += InfExp;
				else ExperienceLevel_Bots += InfExp;
				if (!IsFakeClient(client)) {

					ExperienceOverall[client] += InfExp;
					if (ExperienceLevel[client] > CheckExperienceRequirement(client)) {

						ExperienceOverall[client] -= (ExperienceLevel[client] - CheckExperienceRequirement(client));
						ExperienceLevel[client] = CheckExperienceRequirement(client);
					}
				}
				else if (IsFakeClient(client) && ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
				ExperienceLevel[i] += SurvExp;
				ExperienceOverall[i] += SurvExp;
				if (ExperienceLevel[i] > CheckExperienceRequirement(i)) {

					ExperienceOverall[i] -= (ExperienceLevel[i] - CheckExperienceRequirement(i));
					ExperienceLevel[i] = CheckExperienceRequirement(i);
				}

				if (InfExp > 0 && RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(client, "%T", "Experience Earned Self", client, white, blue, white, green, white, SurvivorName, InfExp);
				if (SurvExp > 0 && RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(i, "%T", "Experience Earned Self", i, white, orange, white, green, white, InfectedName, SurvExp);
			}
			if (RPGMode != 1) {

				if (!IsFakeClient(client)) Points[client] += InfPoints;
				else Points_Director += InfPoints;
				Points[i] += SurvPoints;
				
				if (InfPoints > 0.0 && RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(client, "%T", "Points Earned Self", client, white, blue, white, green, white, SurvivorName, InfPoints);
				if (SurvPoints > 0.0 && RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(i, "%T", "Points Earned Self", i, white, orange, white, green, white, InfectedName, SurvPoints);
			}

			//if (SurvExp > 0 && RPGMode > 0 && RPGBroadcast == 3) PrintToSurvivors(RPGMode, SurvivorName, InfectedName, SurvExp, SurvPoints);
			if (!IsFakeClient(client) && ExperienceLevel[client] > CheckExperienceRequirement(client)) ExperienceLevel[client] = CheckExperienceRequirement(client);
			else if (IsFakeClient(client) && ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);

			if (SurvExp > 0) ExperienceBarBroadcast(i);

			DamageAward[client][i] = 0;
			DamageAward[i][client] = 0;

			SurvExp = 0;			// it resets here for each survivor, so we need to put survivor show team up here.
			SurvPoints = 0.0;
			InfExp = 0;
			InfPoints = 0.0;
		}

		if (RPGBroadcast > 0) {

			if (RPGMode > 0) {

				if (!IsFakeClient(client) && RPGBroadcast == 2 && InfTotalExp > 0) {

					if (RPGMode == 1) PrintToChat(client, "%T", "Experience Earned Total Self", client, white, green, white, InfTotalExp);
					else if (RPGMode == 2) PrintToChat(client, "%T", "Experience Points Earned Total Self", client, white, green, white, green, white, InfTotalExp, InfTotalPoints);
				}
				else if (InfTotalExp > 0 && RPGBroadcast == 3) PrintToInfected(RPGMode, "None", InfectedName, InfTotalExp, InfTotalPoints);
			}
			if (RPGMode == 0 && !IsFakeClient(client) && RPGBroadcast == 2 && InfTotalPoints > 0.0) PrintToChat(client, "%T", "Points Earned Total Self", client, white, green, white, InfTotalPoints);
		}
		if (StringToInt(GetConfigValue("hint text broadcast?")) == 1 && InfTotalExp > 0) {

			ExperienceBarBroadcast(client);
		}
	}
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"