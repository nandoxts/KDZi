--[[
SlideHeader.lua — Header reutilizable con botón de regresar
Para vistas con navegación slide (DJTab, GamepassTab, etc.)
Usa UI helpers centralizados.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

local BACK_ICON = UI.ICONS.BACK
local TW_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local SlideHeader = {}

--[[
SlideHeader.new(props)
props = {
parent    : Instance       — padre donde se crea el header
theme     : table          — ThemeConfig (card, accent, stroke, dim, elevated)
height    : number?        — alto del header (default 60)
bgMode    : "color"|"image"— tipo de fondo (default "color")
overlayAlpha : number?     — transparencia del overlay oscuro (default 0.5)
zBase     : number?        — ZIndex base (default 213)
titleY    : number?        — Y pos del título (default 8)
subtitleY : number?        — Y pos del subtítulo (default 32)
}

Retorna {
frame    : Frame       — contenedor del header
bg       : Frame|ImageLabel — fondo (color o imagen según bgMode)
title    : TextLabel   — label principal
subtitle : TextLabel   — label secundario
backBtn  : TextButton  — botón de regresar
}
]]
function SlideHeader.new(props)
	local THEME = props.theme
	local H = props.height or 60
	local Z = props.zBase or 213

	-- Contenedor
	local header = UI.frame({
		name = props.name or "SlideHeader",
		size = UDim2.new(1, 0, 0, H),
		bg = THEME.card, clips = true, z = Z,
		parent = props.parent,
	})

	-- Fondo
	local bg
	if props.bgMode == "image" then
		bg = UI.make("ImageLabel", {
			Name = "HeaderBg",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			Image = "", ImageTransparency = 0.2,
			ZIndex = Z, Parent = header,
		})
	else
		bg = UI.frame({ name = "HeaderBg", bg = THEME.accent, bgT = 0.7, z = Z, parent = header })
	end

	-- Overlay oscuro
	UI.frame({ bg = Color3.new(0, 0, 0), bgT = props.overlayAlpha or 0.5, z = Z + 1, parent = header })

	-- Botón back (círculo con stroke)
	local backBtn = UI.button({
		name = "BackBtn",
		size = UDim2.new(0, 36, 0, 36),
		pos = UDim2.new(0, 8, 0.5, -18),
		bg = THEME.card, text = "",
		z = Z + 3, parent = header, corner = 18,
	})
	backBtn.BackgroundTransparency = 1
	local stroke = UI.stroked(backBtn, 0, THEME.stroke)
	stroke.Thickness = 1.5

	local iconImg = UI.make("ImageLabel", {
		Size = UDim2.new(0.55, 0, 0.55, 0),
		Position = UDim2.new(0.225, 0, 0.225, 0),
		BackgroundTransparency = 1,
		Image = BACK_ICON, ImageColor3 = THEME.dim,
		ZIndex = Z + 4, Parent = backBtn,
	})

	-- Título
	local title = UI.label({
		size = UDim2.new(1, -60, 0, 22),
		pos = UDim2.new(0, 52, 0, props.titleY or 8),
		font = Enum.Font.GothamBold, textSize = 16,
		color = Color3.new(1, 1, 1),
		truncate = Enum.TextTruncate.AtEnd,
		z = Z + 2, parent = header,
	})

	-- Subtítulo
	local subtitle = UI.label({
		size = UDim2.new(1, -60, 0, 16),
		pos = UDim2.new(0, 52, 0, props.subtitleY or 32),
		font = Enum.Font.GothamBold, textSize = 15,
		color = THEME.accent,
		z = Z + 2, parent = header,
	})

	-- Hover del back button
	backBtn.MouseEnter:Connect(function()
		TweenService:Create(backBtn, TW_HOVER, { BackgroundTransparency = 0, BackgroundColor3 = THEME.elevated }):Play()
	end)
	backBtn.MouseLeave:Connect(function()
		TweenService:Create(backBtn, TW_HOVER, { BackgroundTransparency = 1 }):Play()
	end)

	return {
		frame = header,
		bg = bg,
		title = title,
		subtitle = subtitle,
		backBtn = backBtn,
	}
end

return SlideHeader
