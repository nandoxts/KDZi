--[[
	LevelConfig.lua
	Configuración visual de niveles basada en minutos jugados.
]]

local LevelConfig = {}

-- Devuelve la configuración visual para un nivel dado
function LevelConfig.getLevelConfig(level)
	level = level or 1
	if level >= 150 then
		return { Emoji = "💎", Color = Color3.fromRGB(0, 255, 255) }
	elseif level >= 100 then
		return { Emoji = "👑", Color = Color3.fromRGB(255, 215, 0) }
	elseif level >= 75 then
		return { Emoji = "🌟", Color = Color3.fromRGB(255, 200, 50) }
	elseif level >= 50 then
		return { Emoji = "🔥", Color = Color3.fromRGB(255, 140, 0) }
	elseif level >= 25 then
		return { Emoji = "⚡", Color = Color3.fromRGB(130, 255, 80) }
	elseif level >= 10 then
		return { Emoji = "✨", Color = Color3.fromRGB(100, 180, 255) }
	else
		return { Emoji = "🌱", Color = Color3.fromRGB(200, 200, 200) }
	end
end

return LevelConfig
