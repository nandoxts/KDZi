--[[
	═══════════════════════════════════════════════════════════
	MUSIC SYSTEM - CONFIGURACIÓN
	═══════════════════════════════════════════════════════════
	Autor: ignxts - Nando
	Versión: 3.2 (Simplificado)
]]

local MusicSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- LÍMITES Y RESTRICCIONES
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.LIMITS = {
	MaxQueueSize = 15,
	AllowDuplicatesInQueue = false,
	AddToQueueCooldown = 2,
	SkipCooldown = 30,
	-- Límites por rol (cuántas canciones puede añadir cada jugador a la cola)
	MaxSongsPerUserNormal = 3,  -- Jugadores normales
	MaxSongsPerUserVIP = 5,     -- VIP
	MaxSongsPerUserAdmin = 999, -- Admins (prácticamente infinito)
}

-- ═══════════════════════════════════════════════════════════
-- REPRODUCCIÓN Y AUDIO
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.PLAYBACK = {
	DefaultVolume = 1,
	MinVolume = 0,
	MaxVolume = 1.0,
}

-- ═══════════════════════════════════════════════════════════
-- MODO EVENTO (Bloquea skip y cambios de cola)
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.EVENT_MODE = {
	Enabled = false,
	BlockedActions = {"NextSong", "AddToQueue", "RemoveFromQueue", "ClearQueue"},
}

-- ═══════════════════════════════════════════════════════════
-- DJS PREDETERMINADOS
-- ═══════════════════════════════════════════════════════════
--[[ FORMATO DE EJEMPLO:
	["NOMBRE DJ"] = {          -- NOMBRE DJ
		ImageId = "rbxassetid://123456789", -- IMAGEN DJ
		SongIds = {            -- IDs de canciones separadas por coma
			18411501,
			18411502,
			18411503,
			18411504
		}
	}
]]

function MusicSystemConfig:GetDJs()
	return {
		["DJ Dev"] = { -- Mix pop/hits en inglés (Danny Ocean, Ariana Grande, etc.)
			ImageId = "rbxassetid://127392141037758",-- IMAGEN DJ (reemplaza con el ID de imagen que desees)
			SongIds = { -- IDs separadas por id,id,id,id............
				99610928109795,72406866872082,112814033555377, 134274680440581,129439385384963,109022337963156, 93977984649577, 138851258640604, 106960622152552,

			},
		},
		["Trap Latino"] = { -- NOMBRE DJ
			ImageId = "rbxassetid://134539500342373",-- IMAGEN DJ
			SongIds = { -- IDs separadas por id,id,id,id............
				117842056144641,133801963582628,98323432740085,138321894748700,129228319037128,99959005223193,127835125044169,126760506748810,140602564713331,133910436173066,95871436904167,82395199863426,71352672599183,99250050549994,101735666717241,126426605733101,135227703169372,94749813540059,126302234107254,129323983572163,125653031493513,103437788200547,101740605843691,
				83048968204109,115865825095191,107999669968875,100209555946461,79672009991598,126032896148413,134174859874864,94088385927435,139690188078826,--DEMBOW#99009914709642,93557476982298,101071221683063,112488133017775,138260932217476,74715314491860,
				
			},
		},

	}
end

-- ═══════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════

-- Verificar si un usuario es admin
function MusicSystemConfig:IsAdmin(user)
	-- Acepta Player instance o nombre string. Convertir a nombre.
	local name
	if typeof(user) == "Instance" and user.Name then
		name = user.Name
	elseif type(user) == "string" then
		name = user
	else
		return false
	end

	-- Usar AdminConfig en ReplicatedStorage/Config/AdminConfig
	local ok, adminModule = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("AdminConfig"))
	end)
	if ok and adminModule and adminModule.IsAdmin then
		return adminModule:IsAdmin(name)
	end

	return false
end

-- Obtener volumen predeterminado
function MusicSystemConfig:GetDefaultVolume()
	return self.PLAYBACK.DefaultVolume
end

return MusicSystemConfig
