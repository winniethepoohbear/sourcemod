stock BuildMenuTitle(client, Handle:menu, bot = 0, type = 0) {	// 0 is legacy type that appeared on all menus. 0 - Main Menu | 1 - Upgrades | 2 - Points

	decl String:text[512];

	if (bot == 0) {
	
		if (StringToInt(GetConfigValue("rpg mode?")) == 0) {	// BUY Mode Only

			Format(text, sizeof(text), "%T", "Menu Header 0", client, Points[client]);
		}
		else if (StringToInt(GetConfigValue("rpg mode?")) == 1) {	// RPG Mode Only

			if (type == 0) Format(text, sizeof(text), "%T", "Menu Header 1 Exp", client, PlayerLevel[client], StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), AddCommasToString(GetUpgradeExperienceCost(client)), SkyPoints[client], GetTimePlayed(client), UpgradesUsed(client));
			else if (type == 1) Format(text, sizeof(text), "%T", "Menu Header 3 Exp", client, AddCommasToString(GetUpgradeExperienceCost(client)));
		}
		else if (StringToInt(GetConfigValue("rpg mode?")) == 2) {	// BOTH Modes

			if (type == 0) Format(text, sizeof(text), "%T", "Menu Header 2 Exp", client, PlayerLevel[client], StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), AddCommasToString(GetUpgradeExperienceCost(client)), Points[client], SkyPoints[client], GetTimePlayed(client), UpgradesUsed(client));
			else if (type == 1) Format(text, sizeof(text), "%T", "Menu Header 3 Exp", client, AddCommasToString(GetUpgradeExperienceCost(client)));
			else if (type == 2) Format(text, sizeof(text), "%T", "Menu Header 0", client, Points[client]);
		}
		decl String:text2[512];
		if (FreeUpgrades[client] > 0) {

			Format(text2, sizeof(text2), "%T", "Free Upgrades", client);
			Format(text, sizeof(text), "%s\n%s: %d", text, text2, FreeUpgrades[client]);
		}
		if (RestedExperience[client] > 0) Format(text, sizeof(text), "%T", "Menu Rested Experience", client, text, RestedExperience[client], StringToInt(GetConfigValue("rested experience maximum?")), RoundToCeil(100.0 * StringToFloat(GetConfigValue("rested experience multiplier?"))));
	}
	else {

		if (StringToInt(GetConfigValue("rpg mode?")) == 0 || StringToInt(GetConfigValue("rpg mode?")) == 2 && bot == -1) Format(text, sizeof(text), "%T", "Menu Header 0 Director", client, Points_Director);
		else if (StringToInt(GetConfigValue("rpg mode?")) == 1) {

			// Bots level up strictly based on experience gain. Honestly, I have been thinking about removing talent-based leveling.
			Format(text, sizeof(text), "%T", "Menu Header 1 Talents Bot", client, PlayerLevel_Bots, StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)));
		}
		else if (StringToInt(GetConfigValue("rpg mode?")) == 2) {

			Format(text, sizeof(text), "%T", "Menu Header 2 Talents Bot", client, PlayerLevel_Bots, StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)), Points_Director);
		}
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	SetMenuTitle(menu, text);
}

stock VerifyUpgradeExperienceCost(client) {

	if (GetUpgradeExperienceCost(client) > CheckExperienceRequirement(client) && PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) {

		if (FreeUpgrades[client] < MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]) {

			FreeUpgrades[client] += (MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client] - FreeUpgrades[client]);
		}
	}
}

stock bool:CheckKillPositions(client, bool:b_AddPosition) {

	// If the finale is active, we don't do anything here, and always return false.
	if (!b_IsFinaleActive) return false;

	// If not adding a kill position, it means we need to check the clients current position against all positions in the list, and see if any are within the config value.
	// If they are, we return true, otherwise false.
	// If we are adding a position, we check to see if the size is greater than the max value in the config. If it is, we remove the oldest entry, and add the newest entry.
	// We can do this by removing from array, or just resizing the array to the config value after adding the value.

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);
	decl String:coords[64];

	if (!b_AddPosition) {

		new Float:Last_Origin[3];
		new size				= GetArraySize(h_KilledPosition_X[client]);
		
		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:h_KilledPosition_X[client], i, coords, sizeof(coords));
			Last_Origin[0]		= StringToFloat(coords);
			GetArrayString(Handle:h_KilledPosition_Y[client], i, coords, sizeof(coords));
			Last_Origin[1]		= StringToFloat(coords);
			GetArrayString(Handle:h_KilledPosition_Z[client], i, coords, sizeof(coords));
			Last_Origin[2]		= StringToFloat(coords);

			// If the players current position is too close to any stored positions, return true
			if (GetVectorDistance(Origin, Last_Origin) <= StringToFloat(GetConfigValue("anti farm kill distance?"))) return true;
		}
	}
	else {

		new newsize = GetArraySize(h_KilledPosition_X[client]);

		ResizeArray(h_KilledPosition_X[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[0]);
		SetArrayString(h_KilledPosition_X[client], newsize, coords);

		ResizeArray(h_KilledPosition_Y[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[1]);
		SetArrayString(h_KilledPosition_Y[client], newsize, coords);

		ResizeArray(h_KilledPosition_Z[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[2]);
		SetArrayString(h_KilledPosition_Z[client], newsize, coords);

		while (GetArraySize(h_KilledPosition_X[client]) > StringToInt(GetConfigValue("anti farm kill max locations?"))) {

			RemoveFromArray(Handle:h_KilledPosition_X[client], 0);
			RemoveFromArray(Handle:h_KilledPosition_Y[client], 0);
			RemoveFromArray(Handle:h_KilledPosition_Z[client], 0);
		}
	}
	return false;
}

stock BuildMenu(client) {

	VerifyUpgradeExperienceCost(client);
	ClearArray(RPGMenuPosition[client]);

	// Build the base menu here
	new Handle:menu		=	CreateMenu(BuildMenuHandle);
	decl String:pos[64];

	if (!b_IsDirectorTalents[client]) BuildMenuTitle(client, menu, _, 0);
	else BuildMenuTitle(client, menu, 1);

	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(a_Menu_Main);
	new b_Size			=	0;

	for (new i = 0; i < a_Size; i++) {

		MenuKeys[client]			=	GetArrayCell(a_Menu_Main, i, 0);
		MenuValues[client]			=	GetArrayCell(a_Menu_Main, i, 1);
		b_Size			=	GetArraySize(MenuKeys[client]);

		for (new ii = 0; ii < b_Size; ii++) {

			GetArrayString(Handle:MenuValues[client], ii, text, sizeof(text));
			if (StringToInt(GetConfigValue("rpg mode?")) == 0 && !StrEqual(text, CONFIG_POINTS)) continue;

			//GetArrayString(Handle:MenuKeys[client], ii, text, sizeof(text));

			if (GetArraySize(a_Store) < 1 && StrEqual(text, CONFIG_STORE)) continue;

			if (StringToInt(GetConfigValue("handicap enabled?")) == 0 && StrEqual(text, "handicap")) continue;

			if (b_IsDirectorTalents[client]) {

				if (StrEqual(text, CONFIG_MENUINFECTED) || StrEqual(text, CONFIG_POINTS) || StrEqual(text, "level up")) {

					//decl String:pos[64];
					Format(pos, sizeof(pos), "%d", ii);
					PushArrayString(Handle:RPGMenuPosition[client], pos);
				}
				else if (!StrEqual(text, "EOM")) continue;
			}
			if (StrEqual(text, "EOM")) break;

			if (StrEqual(text, "level up")) {

				if (!b_IsDirectorTalents[client]) {

					if (PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) Format(text, sizeof(text), "%T", "level up unavailable", client, MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]);
					else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(client)));
				}
				else {

					if (PlayerLevelUpgrades_Bots < MaxUpgradesPerLevel()) Format(text, sizeof(text), "%T", "level up unavailable", client, MaxUpgradesPerLevel() - PlayerLevelUpgrades_Bots);
					else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(-1)));
				}
			}
			else {

				GetArrayString(Handle:MenuKeys[client], ii, text, sizeof(text));
				Format(text, sizeof(text), "%T", text, client);
			}

			if (!b_IsDirectorTalents[client]) {

				if ((IsReserve(client) || StringToInt(GetConfigValue("all players chat settings?")) == 1) || !StrEqual(text, CONFIG_CHATSETTINGS)) {

					//decl String:pos[64];
					Format(pos, sizeof(pos), "%d", ii);
					PushArrayString(Handle:RPGMenuPosition[client], pos);
				}
				else if (!StrEqual(text, "EOM")) continue;
			}

			AddMenuItem(menu, text, text);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock PlayerTalentLevel(client) {

	new PTL = RoundToFloor((((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / (MaxUpgradesPerLevel() * PlayerLevel[client])) * PlayerLevel[client]);
	if (PTL < 0) PTL = 0;

	return PTL;
	//return PlayerLevel[client];
}

stock Float:PlayerBuffLevel(client) {

	new Float:PBL = ((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / (MaxUpgradesPerLevel() * PlayerLevel[client]);
	PBL = 1.0 - PBL;
	//PBL = PBL * 100.0;
	if (PBL < 0.0) PBL = 0.0; // This can happen if a player uses free upgrades, so, yeah...
	return PBL;
}

stock MaxUpgradesPerLevel() {

	return RoundToFloor(1.0 / StringToFloat(GetConfigValue("upgrade experience cost?")));
}

stock MaximumPlayerUpgrades(client) {

	return MaxUpgradesPerLevel() * PlayerLevel[client];
}

stock String:UpgradesUsed(client) {

	decl String:text[512];
	Format(text, sizeof(text), "%T", "Upgrades Used", client);
	Format(text, sizeof(text), "(%s: %d / %d)", text, PlayerUpgradesTotal[client], MaximumPlayerUpgrades(client));
	return text;
}

public BuildMenuHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		decl String:key[64];
		decl String:value[64];

		MenuKeys[client]			=	GetArrayCell(a_Menu_Main, 0, 0);
		MenuValues[client]			=	GetArrayCell(a_Menu_Main, 0, 1);

		/*if (!b_IsDirectorTalents[client]) {

			GetArrayString(Handle:MenuKeys[client], slot, key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], slot, value, sizeof(value));
		} else {

			decl String:pos[64];
			GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
			GetArrayString(Handle:MenuKeys[client], StringToInt(pos), key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], StringToInt(pos), value, sizeof(value));
		}*/

		decl String:pos[64];
		GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
		GetArrayString(Handle:MenuKeys[client], StringToInt(pos), key, sizeof(key));
		GetArrayString(Handle:MenuValues[client], StringToInt(pos), value, sizeof(value));

		//if (b_IsDirectorTalents[client] && !StrEqual(value, CONFIG_MENUINFECTED) && !StrEqual(value, CONFIG_POINTS) && !StrEqual(value, "level up")) continue;

		if (StrEqual(value, "level up")) {

			if (!b_IsDirectorTalents[client]) {

				if (PlayerUpgradesTotal[client] >= MaximumPlayerUpgrades(client)) ExperienceBuyLevel(client);
			}
			else ExperienceBuyLevel(client, true);
		}
		else if (StrEqual(value, "slate")) {

			SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
		}
		else if (GetArraySize(a_Store) > 0 && StrEqual(value, CONFIG_STORE)) {

			BuildStoreMenu(client);
		}
		else if (StrEqual(value, "handicap")) {

			SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(value, CONFIG_CHATSETTINGS)) {

			Format(ChatSettingsName[client], sizeof(ChatSettingsName[]), "none");
			BuildChatSettingsMenu(client);
		}
		else if (!StrEqual(value, CONFIG_POINTS)) {

			if (StrEqual(value, CONFIG_MENUSURVIVOR) && b_IsDirectorTalents[client]) PrintToChat(client, "%T", "Director Talents Enabled, No Survivor Talents", client, green, white, green, GetConfigValue("director talent command?"), white);
			else if (StrEqual(value, CONFIG_MENUINFECTED) && b_IsDirectorTalents[client] || !b_IsDirectorTalents[client]) {

				BuildSubMenu(client, key, value);
			}
		}
		else {

			MenuSelection[client] = value;
			BuildPointsMenu(client, key, value);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handle:PlayerHandicapMenu(client) {

	new Handle:menu			= CreatePanel();

	decl String:text[512];
	new Float:HardcoreExperienceMultiplier = StringToFloat(GetConfigValue("experience bonus hardcore?")) + 1.0;
	new Float:HardcoreDamageMultiplier = StringToFloat(GetConfigValue("damage increase hardcore?")) + 1.0;
	if (!b_HardcoreMode[client]) {

		HardcoreExperienceMultiplier	= 1.0;
		HardcoreDamageMultiplier		= 1.0;
	}

	if (HandicapLevel[client] != -1) {

		Format(text, sizeof(text), "%T", "player handicap", client, HandicapLevel[client]);
		DrawPanelText(menu, text);

		Format(text, sizeof(text), "%T", "player handicap bonus", client, (HardcoreExperienceMultiplier * (HandicapLevel[client] * StringToFloat(GetConfigValue("handicap experience bonus?")))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "increase handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "decrease handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "reset handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "disable handicap", client);
		DrawPanelItem(menu, text);
		if (PreviousRoundIncaps[client] == 0 && !b_HandicapLocked[client] && !b_HardcoreMode[client] && HandicapLevel[client] == 10 && IsPlayerAlive(client) && !IsIncapacitated(client)) {

			Format(text, sizeof(text), "%T", "enable hardcore mode", client);
			DrawPanelItem(menu, text);
		}
		Format(text, sizeof(text), "%T", "damage increase commons", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase commons?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase commons level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase commons multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase hunter", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase hunter?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase hunter level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase hunter multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase smoker", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase smoker?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase smoker level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase smoker multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase boomer", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase boomer?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase boomer level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase boomer multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase jockey", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase jockey?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase jockey level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase jockey multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase spitter", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase spitter?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase spitter level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase spitter multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase charger", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase charger?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase charger level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase charger multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "damage increase tank", client, ((((HandicapLevel[client] * StringToFloat(GetConfigValue("damage increase tank?"))) * HardcoreDamageMultiplier) + (PlayerLevel[client] * StringToFloat(GetConfigValue("damage increase tank level?"))) + (LivingHumanSurvivors() * StringToFloat(GetConfigValue("damage increase tank multiplier?"))))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
	}
	else {

		Format(text, sizeof(text), "%T", "handicap disabled", client);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "enable handicap", client);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%T", "main menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public PlayerHandicapHandle(Handle:topmenu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		switch (param2) {

			case 1:
			{
				if (HandicapLevel[client] != -1) {

					if (HandicapLevel[client] < (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed) && !b_HandicapLocked[client]) HandicapLevel[client]++;
				}
				else HandicapLevel[client] = 1;
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 2:
			{
				if (HandicapLevel[client] != -1) {

					if (HandicapLevel[client] > 1) {

						if (b_HardcoreMode[client]) {

							b_HardcoreMode[client] = false;
							SetEntityRenderMode(client, RENDER_NORMAL);
							SetEntityRenderColor(client, 255, 255, 255, 255);
							StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
							SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
						}
						HandicapLevel[client]--;
					}
					SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
				}
				else BuildMenu(client);
			}
			case 3:
			{
				if (HandicapLevel[client] != -1 && HandicapLevel[client] >= 1 && !b_HandicapLocked[client]) {

					HandicapLevel[client] = 1;
				}
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 4:
			{
				if (HandicapLevel[client] != -1 && HandicapLevel[client] >= 1) {

					HandicapLevel[client] = -1;
					if (b_HardcoreMode[client]) {

						b_HardcoreMode[client] = false;
						SetEntityRenderMode(client, RENDER_NORMAL);
						SetEntityRenderColor(client, 255, 255, 255, 255);
						StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
						SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
					}
				}
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 5:
			{
				if (PreviousRoundIncaps[client] == 0 && !b_HandicapLocked[client] && !b_HardcoreMode[client] && HandicapLevel[client] == StringToInt(GetConfigValue("handicap breadth?")) && IsPlayerAlive(client) && !IsIncapacitated(client) && !b_IsCheckpointDoorStartOpened) {

					b_HardcoreMode[client] = true;
					SetEntityRenderMode(client, RENDER_TRANSCOLOR);
					SetEntityRenderColor(client, 255, 0, 0, 255);
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
					EmitSoundToClient(client, "player/heartbeatloop.wav");
					//SetClientMaximumTempHealth(client);

					SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
				}
				else {

					if (HandicapLevel[client] != -1) BuildMenu(client);
				}
			}
			case 6:
			{
				if (PreviousRoundIncaps[client] == 0 && !b_HandicapLocked[client] && !b_HardcoreMode[client] && HandicapLevel[client] != -1 && IsPlayerAlive(client) && !IsIncapacitated(client)) BuildMenu(client);
			}
		}
	}
	if (topmenu != INVALID_HANDLE) {

		CloseHandle(topmenu);
	}
}

public Handle:SlateMenu(client) {

	new Handle:menu = CreatePanel();
	decl String:text[512];
	Format(text, sizeof(text), "%T", "Slate Points", client, SlatePoints[client]);
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%T", "strength slate", client, Strength[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "luck slate", client, Luck[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "agility slate", client, Agility[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "technique slate", client, Technique[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "endurance slate", client, Endurance[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "main menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public SlateHandle(Handle:topmenu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		new SlateMax		= StringToInt(GetConfigValue("slate category maximum?"));
		switch (param2) {

			case 1: {

				if (SlatePoints[client] > 0 && Strength[client] < SlateMax) {

					SlatePoints[client]--;
					Strength[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 2: {

				if (SlatePoints[client] > 0 && Luck[client] < SlateMax) {

					SlatePoints[client]--;
					Luck[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 3: {

				if (SlatePoints[client] > 0 && Agility[client] < SlateMax) {

					SlatePoints[client]--;
					Agility[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 4: {

				if (SlatePoints[client] > 0 && Technique[client] < SlateMax) {

					SlatePoints[client]--;
					Technique[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 5: {

				if (SlatePoints[client] > 0 && Endurance[client] < SlateMax) {

					SlatePoints[client]--;
					Endurance[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 6: {

				if (GetClientTeam(client) != TEAM_SPECTATOR) BuildMenu(client);
			}
		}
	}
	if (topmenu != INVALID_HANDLE) {

		CloseHandle(topmenu);
	}
}

stock BuildSubMenu(client, String:MenuName[], String:ConfigName[]) {

	// Each talent has a defined "menu name" ("part of menu named?") and will list under that menu. Genius, right?

	new Handle:menu					=	CreateMenu(BuildSubMenuHandle);
	decl String:OpenedMenu_t[64];
	Format(OpenedMenu_t, sizeof(OpenedMenu_t), "%s", MenuName);
	OpenedMenu[client]				=	OpenedMenu_t;

	decl String:MenuSelection_t[64];
	Format(MenuSelection_t, sizeof(MenuSelection_t), "%s", ConfigName);
	MenuSelection[client]			=	MenuSelection_t;

	if (!b_IsDirectorTalents[client]) {

		if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR) || StrEqual(ConfigName, CONFIG_MENUINFECTED)) {

			BuildMenuTitle(client, menu, _, 1);
		}
		else if (StrEqual(ConfigName, CONFIG_POINTS)) {

			BuildMenuTitle(client, menu, _, 2);
		}
	}
	else BuildMenuTitle(client, menu, 1);

	decl String:text[PLATFORM_MAX_PATH];
	decl String:pct[4];

	decl String:TalentName[64];
	decl String:TalentName_Temp[64];
	new Float:TalentIncreasePoint	=	0.0;
	new Float:TalentFirstPoint		=	0.0;
	new TalentPointsLevel			=	0;
	new TalentMaximum				=	0;
	new TalentLevelRequired			=	0;
	new PlayerTalentPoints			=	0;
	new TalentAbilityType			=	0;
	new AbilityInherited			=	0;
	new StorePurchaseCost			=	0;

	Format(pct, sizeof(pct), "%");

	decl String:key[64];
	decl String:value[64];

	new size						=	0;

	if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
	else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

	for (new i = 0; i < size; i++) {

		if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) {

			MenuKeys[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
			MenuValues[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
			MenuSection[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);
		}
		else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) {

			MenuKeys[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
			MenuValues[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
			MenuSection[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);
		}

		GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));

		if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;

		new size2			=	GetArraySize(MenuKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "increase per point?"))					TalentIncreasePoint		=	StringToFloat(value);
			else if (StrEqual(key, "first point value?"))				TalentFirstPoint		=	StringToFloat(value);
			else if (StrEqual(key, "maximum talent points allowed?"))	TalentMaximum			=	StringToInt(value);
			else if (StrEqual(key, "minimum level required?"))			TalentLevelRequired		=	StringToInt(value);
			else if (StrEqual(key, "ability inherited?"))				AbilityInherited		=	StringToInt(value);
			else if (StrEqual(key, "ability type?"))					TalentAbilityType		=	StringToInt(value);
			else if (StrEqual(key, "store purchase cost?"))				StorePurchaseCost		=	StringToInt(value);
		}
		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);

		if (!b_IsDirectorTalents[client]) {

			TalentPointsLevel = TalentMaximum;

			PlayerTalentPoints				=	GetTalentStrength(client, TalentName);
		}
		else {

			TalentPointsLevel = TalentMaximum;

			PlayerTalentPoints				=	GetTalentStrength(-1, TalentName);
		}
		if (AbilityInherited == 0 && PlayerTalentPoints < 0) {

			// If the ability is not inherited, it can still be owned by the player if they have at least 1 point in the ability
			// because when a player unlocks an ability, whether through monster drops or purchasing it, they automatically get one point in the talent.

			Format(text, sizeof(text), "%T", "Ability Locked", client, TalentName_Temp, StorePurchaseCost);
		}
		else {

			if (PlayerLevel[client] < TalentLevelRequired) {

				// "Survivor Health (Unlocks At Lv.1)"
				Format(text, sizeof(text), "%T", "Ability Restricted", client, TalentName_Temp, TalentLevelRequired);
			}
			else {

				if (PlayerTalentPoints > 0 || TalentFirstPoint == 0.0) {

					//	"Survivor Health 0 / 50 (2) - BPP: 3% (0%)" <- Survivor Health (current points) / (total maximum allowed) (maximum allowed by level) - Bonus Per Point: BPP% (Bonus based on your current points %)
					if (TalentAbilityType == 0) Format(text, sizeof(text), "%T", "Ability Available Percent", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentIncreasePoint * 100.0, pct, TalentFirstPoint + ((PlayerTalentPoints * TalentIncreasePoint) * 100.0), pct);
					else if (TalentAbilityType == 1) Format(text, sizeof(text), "%T", "Ability Available Time", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentIncreasePoint, TalentFirstPoint + (PlayerTalentPoints * TalentIncreasePoint));
					else Format(text, sizeof(text), "%T", "Ability Available Distance", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentIncreasePoint, TalentFirstPoint + (PlayerTalentPoints * TalentIncreasePoint));
				}
				else {

					if (TalentAbilityType == 0) Format(text, sizeof(text), "%T", "Ability Available Percent - First Point", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentFirstPoint * 100.0, pct);
					else if (TalentAbilityType == 1) Format(text, sizeof(text), "%T", "Ability Available Time - First Point", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentFirstPoint);
					else Format(text, sizeof(text), "%T", "Ability Available Distance - First Point", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum, TalentPointsLevel, TalentFirstPoint);
				}
			}
		}
		AddMenuItem(menu, text, text);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock bool:TalentListingFound(client, Handle:Keys, Handle:Values, String:MenuName[]) {

	new size = GetArraySize(Keys);

	decl String:key[64];
	decl String:value[64];

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, "part of menu named?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (!StrEqual(MenuName, value)) return false;
		}
		if (StrEqual(key, "team?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (strlen(value) > 0 && GetClientTeam(client) != StringToInt(value)) return false;
		}
		if (StrEqual(key, "flags?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (strlen(value) > 0 && !HasCommandAccess(client, value)) return false;
		}
	}
	return true;
}

public BuildSubMenuHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		decl String:ConfigName[64];
		Format(ConfigName, sizeof(ConfigName), "%s", MenuSelection[client]);
		decl String:MenuName[64];
		Format(MenuName, sizeof(MenuName), "%s", OpenedMenu[client]);
		new pos							=	-1;

		BuildMenuTitle(client, menu);

		decl String:pct[4];

		decl String:TalentName[64];
		new TalentPointsLevel			=	0;
		new TalentMaximum				=	0;
		new PlayerTalentPoints			=	0;
		new StorePurchaseCost			=	0;
		decl String:SurvEffects[64];
		Format(SurvEffects, sizeof(SurvEffects), "0");

		Format(pct, sizeof(pct), "%");

		decl String:key[64];
		decl String:value[64];

		new size						=	0;

		if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
		else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

		for (new i = 0; i < size; i++) {

			if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) {

				MenuKeys[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
				MenuValues[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
				MenuSection[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);
			}
			else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) {

				MenuKeys[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
				MenuValues[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
				MenuSection[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);
			}

			GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));

			if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
			pos++;


			new size2			=	GetArraySize(MenuKeys[client]);

			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
				GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

				if (StrEqual(key, "maximum talent points allowed?"))	TalentMaximum		=	StringToInt(value);
				else if (StrEqual(key, "survivor ability effects?")) Format(SurvEffects, sizeof(SurvEffects), "%s", value);
				else if (StrEqual(key, "store purchase cost?")) StorePurchaseCost				=	StringToInt(value);
			}
			if (pos == slot) break;
		}

		if (!b_IsDirectorTalents[client] && IsTalentLocked(client, TalentName)) {

			if (SkyPoints[client] >= StorePurchaseCost) {

				SkyPoints[client] -= StorePurchaseCost;
				UnlockTalent(client, TalentName);
				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}

		}
		else {

			if (!b_IsDirectorTalents[client]) {

				TalentPointsLevel = TalentMaximum;

				PlayerTalentPoints				=	GetTalentStrength(client, TalentName);

				if (ExperienceLevel[client] >= GetUpgradeExperienceCost(client, false) && PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client) && PlayerTalentPoints < TalentPointsLevel && PlayerTalentPoints < TalentMaximum || FreeUpgrades[client] > 0 && PlayerTalentPoints < TalentMaximum) {

					PurchaseTalentName[client]	= TalentName;
					PurchaseTalentPoints[client] = PlayerTalentPoints + 1;
					PurchaseSurvEffects[client]	= SurvEffects;
					Warning_AddTalentPoints(client);
				}
				else BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
			else {

				TalentPointsLevel = TalentMaximum;

				PlayerTalentPoints =	GetTalentStrength(-1, TalentName);

				if (ExperienceLevel_Bots >= GetUpgradeExperienceCost(-1, false) && PlayerTalentPoints < TalentPointsLevel && PlayerTalentPoints < TalentMaximum) {

					if (PlayerTalentPoints >= 0) AddTalentPoints(-1, TalentName, PlayerTalentPoints + 1);
					else AddTalentPoints(-1, TalentName, PlayerTalentPoints + 2);
					ExperienceLevel_Bots -= GetUpgradeExperienceCost(-1, false);
					PlayerLevelUpgrades_Bots++;
				}
				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock Warning_AddTalentPoints(client) {

	new Handle:menu			= CreateMenu(AddTalentsHandle);

	decl String:text[512];
	Format(text, sizeof(text), "%T", "Warning Upgrade TalentName", client, PurchaseTalentName[client]);
	SetMenuTitle(menu, text);
	Format(text, sizeof(text), "%T", "continue", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public AddTalentsHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		switch (slot) {

			case 0: {

				AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
				if (FreeUpgrades[client] == 0 && StringToInt(GetConfigValue("display when players upgrade to team?")) == 1) {

					decl String:text2[64];
					decl String:PlayerName[64];
					GetClientName(client, PlayerName, sizeof(PlayerName));
					for (new k = 1; k <= MaxClients; k++) {

						if (IsLegitimateClient(k) && !IsFakeClient(k) && GetClientTeam(k) == GetClientTeam(client)) {

							Format(text2, sizeof(text2), "%T", PurchaseTalentName[client], k);
							if (GetClientTeam(client) == TEAM_SURVIVOR) PrintToChat(k, "%T", "Player upgrades ability", k, blue, PlayerName, white, green, text2, white);
							else if (GetClientTeam(client) == TEAM_INFECTED) PrintToChat(k, "%T", "Player upgrades ability", k, orange, PlayerName, white, green, text2, white);
						}
					}
				}
				if (FindCharInString(PurchaseSurvEffects[client], 'H') != -1) FindAbilityByTrigger(client, 0, 'a', 0, 0);
				if (FreeUpgrades[client] < 1) ExperienceLevel[client] -= GetUpgradeExperienceCost(client, false);
				else FreeUpgrades[client]--;

				// We have to reset player level upgrades if they purchase an upgrade and are at the limit they can buy per level.
				// This is because you could respec at say, level 2, and have more free upgrades than the number you can get in a level.
				// If we don't do this, the plugin will award them free upgrades, assuming their character hasn't been rolled into the new system, yet.
				if (PlayerLevelUpgrades[client] >= MaxUpgradesPerLevel()) PlayerLevelUpgrades[client] = 0;
				PlayerLevelUpgrades[client]++;
				PlayerUpgradesTotal[client]++;

				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
			case 1: {

				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
		}
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock GetTalentPoints(client, amount) {

	// I've created a function because I'm going to do something else with it... At some point.
	if (client != -1) TotalTalentPoints[client] += amount;
	else TotalTalentPoints_Bots += amount;
}

stock FindTalentPoints(client, String:Name[]) {

	decl String:text[64];

	new a_Size							=	GetArraySize(a_Database_Talents);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			return StringToInt(text);
		}
	}
	//return -1;	// this is to let us know to setfailstate.
	return 0;	// this will be removed. only for testing.
}

stock AddTalentPoints(client, String:Name[], TalentPoints) {
	
	decl String:text[64];
	new a_Size							=	GetArraySize(a_Database_Talents);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			Format(text, sizeof(text), "%d", TalentPoints);
			if (client != -1) SetArrayString(a_Database_PlayerTalents[client], i, text);
			else SetArrayString(a_Database_PlayerTalents_Bots, i, text);
			break;
		}
	}
}

stock UnlockTalent(client, String:Name[], bool:bIsEndOfMapRoll = false) {

	decl String:text[64];
	decl String:PlayerName[64];
	GetClientName(client, PlayerName, sizeof(PlayerName));

	new size			= GetArraySize(a_Database_Talents);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			SetArrayString(a_Database_PlayerTalents[client], i, "0");
			for (new ii = 1; ii <= MaxClients; ii++) {

				if (IsClientInGame(ii) && !IsFakeClient(ii)) {

					Format(text, sizeof(text), "%T", Name, ii);
					if (!bIsEndOfMapRoll) PrintToChat(ii, "%T", "Locked Talent Award", ii, blue, PlayerName, white, orange, text, white);
					else PrintToChat(ii, "%T", "Locked Talent Award (end of map roll)", ii, blue, PlayerName, white, orange, text, white, white, orange, white);
				}
			}
			break;
		}
	}
}

stock bool:IsTalentExists(String:Name[]) {

	decl String:text[64];
	new size			= GetArraySize(a_Database_Talents);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) return true;
	}
	return false;
}

stock bool:IsTalentLocked(client, String:Name[]) {

	decl String:text[64];

	new size			= GetArraySize(a_Database_Talents);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			GetArrayString(a_Database_PlayerTalents[client], i, text, sizeof(text));

			if (StringToInt(text) >= 0) return false;
			break;
		}
	}

	return true;
}

stock WipeTalentPoints(client) {

	new size							= GetArraySize(a_Database_Talents);

	decl String:value[64];

	for (new i = 0; i < size; i++) {	// We only reset talents a player has points in, so locked talents don't become unlocked.

		GetArrayString(a_Database_PlayerTalents[client], i, value, sizeof(value));
		if (StringToInt(value) > 0)	SetArrayString(a_Database_PlayerTalents[client], i, "0");
	}
}