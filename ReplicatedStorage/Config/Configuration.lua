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

	-- GAME PASS --
	VIP = 1559766581,
	COMMANDS = 1133764521,
	COLORS = 1568365009,
	TOMBO = 1179926968,
	CHORO = 1557650753,
	SERE = 1561726418,
	ARMYBOOMS = 1709795779,
	LIGHTSTICK = 1709767521,
	-- DEV PASS --
	DEV_VIP = 3414346471,
	DEV_COMMANDS = 3448375846,
	DEV_COLORS = 3448377425,
	DEV_TOMBO = 3448376068,
	DEV_CHORO = 3448376072,
	DEV_SERE = 3448376069,
	DEV_ARMYBOOMS = 3448376073,
	DEV_LIGHTSTICK = 3535308027,
	-- DEV SUPER LIKE --
	SUPER_LIKE = 3447051605,
	LIKE_COOLDOWN = 600,
	SUPER_LIKE_VALUE = 10,
	AUTOSAVE_INTERVAL = 300,
	-- GRUPO --
	GroupID = 35712251,
	OWS = {522683358,1836329833,4074563891,5819550352,8387751399},
	-- RANKS PERMISSION
	ALLOWED_RANKS_OWS = {255,254},
	ALLOWED_DJ_RANKS = {255,254},
	ALLOWED_RANKS_EVENTS = {255,254,253,252,251},
	
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

	-- AURAS --
	AURA_PACK  = 1728328748,
	DEV_AURA_PACK = 3548724904,

	-- DANCE LEADER --
	FOLLOWER_DANCE = 15, -- Cantidad de seguidores para activar el gui
	CHECK_TIME_FOLLOWER = 300, -- Tiempo de comprobación de seguidores
	BILLBOARD_NAME = "Dance_Leader",
}
