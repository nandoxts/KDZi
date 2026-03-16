--[[
█████╗ ██╗   ██╗████████╗ ██████╗ ██████╗ 
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗
███████║██║   ██║   ██║   ██║   ██║██████╔╝
██╔══██║██║   ██║   ██║   ██║   ██║██╔══██╗
██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║  ██║
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝

/* Copyright (C) 2026 Nando (ignxts) - All rights reserved
 * You only have the right to modify the file.
 *
 * It is strictly forbidden to resell the code,
 * copy the code, distribute the code and above
 * all to make an image of the code.
 *
 * Remember that any violation will result in a report
 * for unauthorized use of copyright.
 */
]]

return {

	PLACE_NAME = "RITMO LATINO",
	VOLUMEN = 0.5,

	-- ══════════════════════════════════════
	--  GAME PASSES  (fuente única de verdad)
	--  Acceso: Config.Gamepasses.VIP.id
	--  devId = 0  →  sin versión de prueba
	-- ══════════════════════════════════════
	Gamepasses = {
		VIP        = { id = 1559766581, devId = 3414346471 },
		COMMANDS   = { id = 1133764521, devId = 3448375846 },
		COLORS     = { id = 1568365009, devId = 3448377425 },
		TOMBO      = { id = 1179926968, devId = 3448376068 },
		CHORO      = { id = 1557650753, devId = 3448376072 },
		SERE       = { id = 1561726418, devId = 3448376069 },
		ARMYBOOMS  = { id = 1709795779, devId = 3448376073 },
		LIGHTSTICK = { id = 1709767521, devId = 3535308027 },
		AURA_PACK  = { id = 1728328748, devId = 3548724904 },
	},
	-- DEV SUPER LIKE --
	SUPER_LIKE = 3447051605,
	LIKE_COOLDOWN = 600,
	SUPER_LIKE_VALUE = 10,
	AUTOSAVE_INTERVAL = 300,
	-- GRUPO --
	GroupID = 35712251,

	-- ANIMATION LEADERBOARD
	DONATIONS_EMOTE = 112420346955388,
	DONATOR_EMOTE = 134559477567523,
	RECEIVER_EMOTE = 75773776265985,
	LIKES_EMOTE = 136648387080677,
	Racha_EMOTE = 119963708755205,
	USER01_EMOTE = 73236219340808,
	USER02_EMOTE = 88693910954718,
	USER03_EMOTE = 88693910954718,
	USER04_EMOTE = 71302743123422,
	USER05_EMOTE = 71302743123422,
	USER06_EMOTE = 73236219340808,

	-- COMMANDS --
	CommandKorblox = "[,.;]korblox",
	CommandHeadless = "[,.;]headless",
	CommandSize = "[,.;]size (%d*%.?%d+)$", -- ^/size (%d%.?%d*)$
	CommandHat = "[,.;]item (.+)$",  -- ^/hat (%d+)$
	CommandParticle = "[,.;]particula (.+)$",
	CommandReset = "^[,.;]update$",
	CommandReset2 = "^[,.;]re$",
	CommandClone = "[,.;]clone%s+(%S+)",
	CommandFIRE   = "^[,.;]fire%s*(.+)$",
	CommandSMK    = "^[,.;]smk%s*(.+)$",
	CommandLGHT   = "^[,.;]lght%s*(.+)$",
	CommandPRTCL  = "^[,.;]prtcl%s*(.+)$",
	CommandTRAIL  = "^[,.;]trail%s*(.+)$",
	CommandRMV    = "^[,.;]rmv$",
	CommandDestacado   = "^[,.;]hl%s*(.+)$",

	-- EMOTE COMMANDS --
	CommandTOMBO = "[,.;]tombo$",
	CommandCHORO = "[,.;]choro$",
	CommandSERE = "[,.;]sere$",
	CommandARMYBOOMS = "[,.;]armybooms$",
	CommandLIGHTSTICK = "[,.;]lightstick$",
	CommandAURA = "^[,.;]aura%s+(%S+)$",

	-- DANCE LEADER --
	FOLLOWER_DANCE = 15, -- Cantidad de seguidores para activar el gui
	CHECK_TIME_FOLLOWER = 300, -- Tiempo de comprobación de seguidores
	BILLBOARD_NAME = "Dance_Leader",

	-- UI ICONS
	UIIcons = {
		Premium = "rbxassetid://13600832988",
	},

	-- ══════════════════════════════════════
	--  GROUP ROLES + ADMIN SYSTEM
	--  Fuente única de verdad para roles y rangos
	--  Cambias aquí = cambia UI, ChatTags y Adonis
	--
	--  Name       → Tag visual en chat/UI
	--  Color/Icon → Visual del rol
	--  AdminRank  → Nombre del rango en Adonis (nil = sin admin)
	--  AdminLevel → Nivel de permisos en Adonis (nil = sin admin)
	-- ══════════════════════════════════════
	GroupRoles = {
		[255] = { Name = "[Creador]", Color = Color3.fromRGB(255, 255, 0), Icon = " ", AdminRank = "Creators",      AdminLevel = 900 },
		[254] = { Name = "[Developer ]",     Color = Color3.fromRGB(0, 255, 170),   Icon = " ", AdminRank = "Creators",      AdminLevel = 900 },
		[253] = { Name = "[Co-Creador ]",      Color = Color3.fromRGB(0, 0, 255),    Icon = "♛", AdminRank = "Help Creator",  AdminLevel = 400 },
		[252] = { Name = "[Help Creator ]",  Color = Color3.fromRGB(255, 85, 255), Icon = "⚜️", AdminRank = "Lead Admin",    AdminLevel = 350 },
		[251] = { Name = "[Lead Admin ]",    Color = Color3.fromRGB(85, 85, 255),  Icon = "🔱", AdminRank = "HeadAdmins",    AdminLevel = 300 },
		[250] = { Name = "[Head Admin ]",    Color = Color3.fromRGB(255, 200, 4),  Icon = "🔰", AdminRank = "Administrador", AdminLevel = 200 },
		[249] = { Name = "[Administrador]", Color = Color3.fromRGB(179, 0, 0),    Icon = "🚨", AdminRank = "Moderador",     AdminLevel = 150 },
		[248] = { Name = "[Moderador]",     Color = Color3.fromRGB(38, 225, 0),   Icon = "🛡️", AdminRank = "DJ",            AdminLevel = 100 },
		[247] = { Name = "[DJ]",            Color = Color3.fromRGB(0, 0, 255),    Icon = "🎧", AdminRank = "Influencer",    AdminLevel = 75 },
		[246] = { Name = "[Influencer]",    Color = Color3.fromRGB(0, 213, 255),  Icon = "⭐", AdminRank = "Socio",         AdminLevel = 50 },
		[245] = { Name = "[Socio]",         Color = Color3.fromRGB(0, 0, 255),    Icon = "🤝"  },
	},

	-- ══════════════════════════════════════
	--  ADMIN OWNERS (Creators nivel 900+)
	-- ══════════════════════════════════════
	AdminOwners = {
		{ Username = "bvwdhfv", UserId = 4074563891 },
		{ Username = "ignxts",  UserId = 8387751399 },
	},

	-- ══════════════════════════════════════
	--  ADMIN POR GAMEPASS
	-- ══════════════════════════════════════
	AdminRanksByGamepass = {
		{ Gamepass = "COMMANDS", Name = "COMMANDS", Level = 20 },
		{ Gamepass = "VIP",     Name = "VIP",      Level = 10 },
	},
}
