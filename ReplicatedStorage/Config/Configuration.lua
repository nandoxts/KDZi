return {

	PLACE_NAME = "Club KDZ",

	-- ══════════════════════════════════════
	--  GAME PASSES  (fuente única de verdad)
	--  Acceso: Config.Gamepasses.VIP.id
	--  devId = 0  →  sin versión de prueba
	-- ══════════════════════════════════════
	Gamepasses = {
		VIP        = { id = 1749571764, devId = 0 },
		COMMANDS   = { id = 1753652728, devId = 0 },
	},
	-- GRUPO --
	GroupID = 35712251,

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
		[255] = { Name = "[Creator]",      Color = Color3.fromRGB(186, 85, 211),   Icon = "👑", AdminRank = "Creators",      AdminLevel = 900,
			Gradient = { Color3.fromRGB(186, 85, 211), Color3.fromRGB(138, 43, 226), Color3.fromRGB(75, 0, 130) } },
		[254] = { Name = "[Head Admin]",   Color = Color3.fromRGB(0, 206, 209),   Icon = "🔰", AdminRank = "HeadAdmins",    AdminLevel = 300,
			Gradient = { Color3.fromRGB(0, 206, 209), Color3.fromRGB(64, 224, 208) } },
		[253] = { Name = "[Admin]",        Color = Color3.fromRGB(50, 205, 50),     Icon = "🚨", AdminRank = "Administrador", AdminLevel = 200,
			Gradient = { Color3.fromRGB(50, 205, 50), Color3.fromRGB(144, 238, 144) } },
		[252] = { Name = "[Mod]",          Color = Color3.fromRGB(255, 20, 147),    Icon = "🛡", AdminRank = "Moderador",     AdminLevel = 150 },
		[251] = { Name = "[DJ]",           Color = Color3.fromRGB(255, 140, 0),     Icon = "🎧", AdminRank = "DJ",            AdminLevel = 100 },
		[250] = { Name = "[Influencer]",   Color = Color3.fromRGB(255, 215, 0),   Icon = "⭐", AdminRank = "Influencer",    AdminLevel = 75 },
		[249] = { Name = "[Socio]",        Color = Color3.fromRGB(135, 206, 250),     Icon = "🤝" },
	},

	-- ══════════════════════════════════════
	--  ADMIN OWNERS (Creators nivel 900+)
	-- ══════════════════════════════════════
	AdminOwners = {
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
