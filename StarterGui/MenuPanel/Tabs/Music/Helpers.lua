-- Music/Helpers.lua — Utilidades compartidas (delega a Core/UI donde puede)
local TweenService = game:GetService("TweenService")
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Core"):WaitForChild("UI"))

local Helpers = {}

-- Delegados de UI global
Helpers.rounded = UI.rounded       -- (inst, px)
Helpers.stroked = UI.stroked       -- (inst, alpha, color)
Helpers.hover   = UI.hover         -- (btn, normalColor, hoverColor)
Helpers.brighten = UI.brighten     -- (color, factor)

-- Genérico — UI.lua no tiene create genérico, se mantiene acá
function Helpers.make(class, props)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then i[k] = v end
	end
	if props.Parent then i.Parent = props.Parent end
	return i
end

-- Tween rápido — UI.lua no expone un tween genérico
function Helpers.tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

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

-- Iconos modernos compartidos (mismos que MusicDjDashboard)
Helpers.ICONS = {
	PLAY_ADD = "rbxassetid://106062824601262",
	CHECK    = "rbxassetid://102926522001210",
	DELETE   = "rbxassetid://100580390387788",
	LOADING  = "rbxassetid://72909990569897",
	SKIP     = "rbxassetid://130796780610204",
	BACK     = "rbxassetid://97043688093134",
}

-- CanvasGroup helper — recorta hijos respetando UICorner (protección de bordes)
function Helpers.makeCanvas(parent, corner, z)
	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	canvas.GroupTransparency = 0
	canvas.ZIndex = z or 103
	canvas.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, corner or 10)
	c.Parent = canvas
	return canvas
end

-- Referencia directa a UI por si los módulos necesitan más
Helpers.UI = UI

-- Botón circular outlined reutilizable (transparente + UIStroke + icono centrado)
-- Retorna { btn, icon } para poder cambiar icono/estado después
function Helpers.outlinedCircleBtn(parent, opts)
	local size = opts.size or 32
	local icon = opts.icon
	local theme = opts.theme
	local z = opts.zIndex or 216
	local pos = opts.position or UDim2.new(0, 0, 0, 0)
	local name = opts.name or "OutlinedBtn"

	local btn = Helpers.make("TextButton", {
		Size = UDim2.new(0, size, 0, size),
		Position = pos,
		BackgroundColor3 = theme.card,
		BackgroundTransparency = theme.frameAlpha,
		Text = "", BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = z, Name = name, Parent = parent,
	})
	Helpers.rounded(btn, size / 2)
	Helpers.make("UIStroke", {
		Color = theme.stroke, Thickness = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn,
	})
	local iconLabel = Helpers.make("ImageLabel", {
		Size = UDim2.new(0.55, 0, 0.55, 0), Position = UDim2.new(0.225, 0, 0.225, 0),
		BackgroundTransparency = 1, Image = icon or "",
		ImageColor3 = theme.dim,
		ZIndex = z + 1, Name = "IconImage", Parent = btn,
	})
	return btn, iconLabel
end

return Helpers
