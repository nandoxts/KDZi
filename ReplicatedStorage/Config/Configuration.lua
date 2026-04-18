
--[[
█████╗ ██╗   ██╗████████╗ ██████╗ ██████╗ 
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗
███████║██║   ██║   ██║   ██║   ██║██████╔╝
██╔══██║██║   ██║   ██║   ██║   ██║██╔══██╗
██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║  ██║
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝

/* Copyright (C) 2026 Nando (nxndoxt) - All rights reserved
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

	PLACE_NAME = "Club KDZ",

	-- ══════════════════════════════════════
	--  GAME PASSES  (fuente única de verdad)
	--  Acceso: Config.Gamepasses.VIP.id
	--  devId = 0  →  sin versión de prueba
	-- ══════════════════════════════════════
	Gamepasses = {
		VIP        = { id = 1749571764, devId = 1749571764, order = 1, state = true, color = Color3.fromRGB(251, 255, 0),   desc = "[ + ] Sistema de VIP exclusivo!\n[ + ] Ascensor para VIP!\n[ + ] Fondo de comunidad!\n[ + ] Comandos Adonis!" },
		COMMANDS   = { id = 1753652728, devId = 1753652728, order = 2, state = true,  color = Color3.fromRGB(0, 217, 255),   desc = "[ + ] Acceso exclusivo a Tarima!\n[ + ] Pon musica en el server!\n[ + ] Beneficios de tarima!" },
	},
	-- GRUPO --
	GroupID = 156212776,

	-- COMMANDS --
	CommandKorblox = "[,.;]korblox",
	CommandHeadless = "[,.;]headless",
	CommandFIRE   = "^[,.;]fire%s*(.+)$",
	CommandLGHT   = "^[,.;]lght%s*(.+)$",
	CommandPRTCL  = "^[,.;]prtcl%s*(.+)$",
	CommandTRAIL  = "^[,.;]trail%s*(.+)$",
	CommandRMV    = "^[,.;]rmv$",
	CommandDestacado   = "^[,.;]hl%s*(.+)$",
	CommandReset  = "^[,.;]ref$",
	CommandReset2 = "^[,.;]unchar$",
	CommandClone  = "^[,.;]clone%s+(%S+)$",

	-- DANCE LEADER --
	FOLLOWER_DANCE = 10, -- Cantidad de seguidores para activar el gui
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
		[255] = { Name = "[Creator]",      Color = Color3.fromRGB(0, 255, 255),   Icon = "💎", AdminRank = "Creators",      AdminLevel = 900,
			Gradient = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(85, 255, 255), Color3.fromRGB(0, 170, 255) } },
		[254] = { Name = "[Creator]",      Color = Color3.fromRGB(0, 255, 255),   Icon = "💎", AdminRank = "Creators",      AdminLevel = 900,
			Gradient = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 170, 255) } },
		[253] = { Name = "[Head Admin]",   Color = Color3.fromRGB(0, 206, 209),   Icon = "🔰", AdminRank = "HeadAdmins",    AdminLevel = 300,
			Gradient = { Color3.fromRGB(0, 206, 209), Color3.fromRGB(64, 224, 208) } },
		[252] = { Name = "[Admin]",        Color = Color3.fromRGB(50, 205, 50),     Icon = "🚨", AdminRank = "Administrador", AdminLevel = 200,
			Gradient = { Color3.fromRGB(50, 205, 50), Color3.fromRGB(144, 238, 144) } },
		[251] = { Name = "[Mod]",          Color = Color3.fromRGB(255, 20, 147),    Icon = "🛡", AdminRank = "Moderador",     AdminLevel = 150 },
		[250] = { Name = "[DJ]",           Color = Color3.fromRGB(255, 140, 0),     Icon = "🎧", AdminRank = "DJ",            AdminLevel = 100 },
		[249] = { Name = "[Influencer]",   Color = Color3.fromRGB(255, 215, 0),   Icon = "⭐", AdminRank = "Influencer",    AdminLevel = 75 },
		[248] = { Name = "[Socio]",        Color = Color3.fromRGB(135, 206, 250),     Icon = "🤝", AdminRank = "Socio",    AdminLevel = 50 },
	},

	-- ══════════════════════════════════════
	--  ADMIN OWNERS (Creators nivel 900+)
	-- ══════════════════════════════════════
	AdminOwners = {
		{ Username = "ignxts",  UserId = 8387751399 },
		{ Username = "Gatita17play",  UserId = 8771639155 },
		
	},
	-- ══════════════════════════════════════
	--  ADMIN POR GAMEPASS
	-- ══════════════════════════════════════
	AdminRanksByGamepass = {
		{ Gamepass = "COMMANDS", Name = "COMMANDS", Level = 20 },
		{ Gamepass = "VIP",     Name = "VIP",      Level = 10 },
	},
}
