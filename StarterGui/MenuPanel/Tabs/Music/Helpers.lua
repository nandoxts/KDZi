-- Music/Helpers.lua — Funciones específicas de música
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Core"):WaitForChild("UI"))

local Helpers = {}

-- Re-exportar UI completo para backward compat
Helpers.UI = UI
Helpers.make = UI.make
Helpers.tween = UI.tween
Helpers.rounded = UI.rounded
Helpers.stroked = UI.stroked
Helpers.hover = UI.hover
Helpers.brighten = UI.brighten
Helpers.ICONS = UI.ICONS
Helpers.outlinedCircleBtn = UI.outlinedCircleBtn

-- Funciones específicas de música
function Helpers.formatTime(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

function Helpers.isInQueue(queue, id)
	for _, s in ipairs(queue) do
		if s.id == id then return true end
	end
	return false
end

return Helpers
