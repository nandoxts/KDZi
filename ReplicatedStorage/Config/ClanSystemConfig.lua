--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM - CONFIGURACIÓN
	═══════════════════════════════════════════════════════════
	Autor: by ignxts
	Versión: 2.0 (Simplificado)
]]

local ClanSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- BASE DE DATOS (DATASTORE)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DATABASE = {
	ClanStoreName = "ClanData", -- DataStore único para todo el sistema
	InitDelay = 2, -- Segundos de espera antes de crear clanes por defecto
	CreateClanDelay = 0.1, -- Delay entre crear cada clan por defecto (evitar throttle)
}

-- ═══════════════════════════════════════════════════════════
-- LÍMITES Y RESTRICCIONES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.LIMITS = {
	MinClanNameLength = 3,
	MaxClanNameLength = 30,
	MinTagLength = 2,
	MaxTagLength = 5,
}

-- ═══════════════════════════════════════════════════════════
-- VALORES POR DEFECTO AL CREAR CLAN
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DEFAULTS = {
	Logo = "rbxassetid://0",
	Emoji = "⚔️",
	Color = {255, 255, 255}, -- RGB Blanco
	Description = "Sin descripción",
	MemberRole = "miembro", -- Rol por defecto al unirse
}

-- ═══════════════════════════════════════════════════════════
-- CONSTANTES DE ROLES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ROLE_NAMES = {
	OWNER = "owner",
	LIDER = "lider",
	COLIDER = "colider",
	MIEMBRO = "miembro",
}

-- ═══════════════════════════════════════════════════════════
-- RATE LIMITING (Anti-spam)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.RATE_LIMITS = {
	GetClansList = 0,
	CreateClan = 10,
	LeaveClan = 5,
	InvitePlayer = 1,
	KickPlayer = 2,
	ChangeRole = 3,
	ChangeName = 3,
	ChangeTag = 3,
	ChangeDescription = 3,
	ChangeLogo = 60,
	ChangeEmoji = 10,
	ChangeColor = 10,
	DissolveClan = 10,
	AdminDissolveClan = 10,
	-- NUEVOS RATE LIMITS PARA SOLICITUDES
	RequestJoinClan = 5,      -- 5 segundos entre solicitudes
	ApproveJoinRequest = 1,   -- 1 segundo entre aprobaciones
	RejectJoinRequest = 1,    -- 1 segundo entre rechazos
	CancelJoinRequest = 1,    -- 1 segundo entre cancelaciones
	GetJoinRequests = 0,       -- Sin throttle para consultas de lectura
}

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE ROLES Y PERMISOS
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ROLES = {
	Hierarchy = {
		owner = 4,
		lider = 3,
		colider = 2,
		miembro = 1,
	},

	Permissions = {
		owner = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = true,
			cambiar_colideres = true,
			cambiar_descripcion = true,
			cambiar_nombre = true,
			cambiar_tag = true,
			cambiar_logo = true,
			cambiar_emoji = true,
			cambiar_color = true,
			disolver_clan = true,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- MÚLTIPLES OWNERS
			agregar_owner = true,
			remover_owner = true
		},
		colider = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = true,
			cambiar_colideres = true,
			cambiar_descripcion = true,
			cambiar_nombre = true,
			cambiar_logo = true,
			cambiar_emoji = false,
			cambiar_color = false,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- NO puede cambiar owners
			agregar_owner = false,
			remover_owner = false
		},
		lider = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = false,
			cambiar_colideres = false,
			cambiar_descripcion = true,
			cambiar_nombre = false,
			cambiar_logo = false,
			cambiar_emoji = false,
			cambiar_color = false,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- NO puede cambiar owners
			agregar_owner = false,
			remover_owner = false
		},
		miembro = {
			invitar = false,
			expulsar = false,
			aprobar_solicitudes = false,
			rechazar_solicitudes = false,
			ver_solicitudes = false,
			cambiar_color = false,
			agregar_owner = false,
			remover_owner = false
		}
	},

	-- Configuración visual y jerarquía para UI
	Visual = {
		owner = {
			display = "Owner",
			color = Color3.fromRGB(255, 215, 0),
			icon = "👑",
			priority = 4,
			canManage = {"owner", "lider", "colider", "miembro"}
		},
		lider = {
			display = "Líder",
			color = Color3.fromRGB(100, 200, 255),
			icon = "🔹",
			priority = 3,
			canManage = {"colider", "miembro"}
		},
		colider = {
			display = "Co-Líder", 
			color = Color3.fromRGB(180, 100, 255),
			icon = "⚜️",
			priority = 2,
			canManage = {"miembro"}
		},
		miembro = {
			display = "Miembro",
			color = Color3.fromRGB(200, 200, 200), -- Usar un color muted en lugar de THEME.muted
			icon = "•",
			priority = 1,
			canManage = {}
		}
	},
}

-- ═══════════════════════════════════════════════════════════
-- CLANS POR DEFECTO (Creados automáticamente al iniciar)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DEFAULT_CLANS = {
	{
		clanName = "Shadow Garden",
		ownerId = 758075372, -- Asignar ownerId
		clanTag = "SG",
		clanLogo = "rbxassetid://112234631634424",
		descripcion = "Clan Shadow Garden",
		clanEmoji = "🔱",
		clanColor = {255, 215, 0}, -- Dorado
	},
	{
		clanName = "TH4",
		ownerId = 7938677596, -- Asignar ownerId
		clanTag = "TH4",
		clanLogo = "rbxassetid://116232400811020",
		descripcion = "Clan TH4",
		clanEmoji = "🔥",
		clanColor = {255, 69, 0}, -- Color sugerido (naranja)
	},
	{
		clanName = "King of Darkness",
		ownerId = 2813593883, -- Asignar ownerId
		clanTag = "KD",
		clanLogo = "rbxassetid://110433791728647",
		descripcion = "Clan King of Darkness",
		clanEmoji = "💀",
		clanColor = {138, 43, 226}, -- Morado/Púrpura (BlueViolet)
	},
	{
		clanName = "Demons",
		ownerId = 3186256515,
		clanTag = "DM",
		clanLogo = "rbxassetid://89593175600646",
		descripcion = "Clan DM",
		clanEmoji = "😈",
		clanColor = {148, 0, 211}, -- Morado
	},
	{
		clanName = "LARUTA",
		ownerId = 9754426687,
		clanTag = "LR",
		clanLogo = "rbxassetid://80953801283194",
		descripcion = "Hola somos el clan “LA RUTA”  una familia que nos encanta ir a salones de bailes a pasarla bien, buscamos miembros con nuestra misma vibra🫶🏼",
		clanEmoji = "🏍️",
		clanColor = {255, 0, 0}, -- Rojo
	},

	{
		clanName = "ECLIPSE ROSA",
		ownerId = 8659516822,
		clanTag = "ER",
		clanLogo = "rbxassetid://87193271601992",
		descripcion = "Un clan que brilla incluso en la oscuridad.",
		clanEmoji = "🌙",
		clanColor = {255, 192, 203}, -- Rosado
	},
	{
		clanName = "💥CHEROS💥",
		ownerId = 5425316102,
		clanTag = "CHR",
		clanLogo = "rbxassetid://105573309779066",
		descripcion = "CLAN CHEROS💥 REPRESENTACION DE LA FIDELIDAD",
		clanEmoji = "💥",
		clanColor = {0, 200, 80}, -- Verde
	},
	{
		clanName = "La Vida Loca",
		ownerId = 2920094465,
		clanTag = "LvL",
		clanLogo = "rbxassetid://89677751320941",
		descripcion = "La Vida Loca",
		clanEmoji = "☠️",
		clanColor = {255, 140, 0}, -- Naranja
	},
}

-- ═══════════════════════════════════════════════════════════
-- VALIDACIÓN Y FILTRADO
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.VALIDATION = {
	BlacklistedWords = {
		"admin", "roblox", "owner", "mod", 
	},
}

-- ═══════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════

-- Obtener límite de rate para una acción
function ClanSystemConfig:GetRateLimit(action)
	return self.RATE_LIMITS[action] or 1
end

-- Verificar si tiene permiso
function ClanSystemConfig:HasPermission(rol, permiso)
	local rolePerms = self.ROLES.Permissions[rol]
	return rolePerms and rolePerms[permiso] or false
end

-- Obtener jerarquía de rol
function ClanSystemConfig:GetRoleLevel(rol)
	return self.ROLES.Hierarchy[rol] or 0
end

-- Validar nombre de clan
function ClanSystemConfig:ValidateClanName(name)
	if not name or type(name) ~= "string" then
		return false, "Nombre inválido"
	end

	local len = #name
	if len < self.LIMITS.MinClanNameLength then
		return false, "Nombre muy corto (mínimo " .. self.LIMITS.MinClanNameLength .. " caracteres)"
	end

	if len > self.LIMITS.MaxClanNameLength then
		return false, "Nombre muy largo (máximo " .. self.LIMITS.MaxClanNameLength .. " caracteres)"
	end

	-- Verificar blacklist
	local lowerName = name:lower()
	for _, word in ipairs(self.VALIDATION.BlacklistedWords) do
		if lowerName:find(word:lower()) then
			return false, "Nombre contiene palabras prohibidas"
		end
	end

	return true
end

-- Validar TAG
function ClanSystemConfig:ValidateTag(tag)
	if not tag or type(tag) ~= "string" then
		return false, "TAG inválido"
	end

	local len = #tag
	if len < self.LIMITS.MinTagLength then
		return false, "TAG muy corto (mínimo " .. self.LIMITS.MinTagLength .. " caracteres)"
	end

	if len > self.LIMITS.MaxTagLength then
		return false, "TAG muy largo (máximo " .. self.LIMITS.MaxTagLength .. " caracteres)"
	end

	return true
end



return ClanSystemConfig
