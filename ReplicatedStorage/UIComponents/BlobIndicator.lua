--[[
	BlobIndicator — Indicador deslizante reutilizable (stretch → settle)
	
	Uso:
		local BlobIndicator = require(...)
		local blob = BlobIndicator.new(parentFrame, {
			tabCount    = 4,
			bgColor     = THEME.elevated,
			padding     = 4,         -- (default 4)
			cornerRadius = 8,        -- (default 8)
			zIndex      = 204,       -- (default parent.ZIndex + 1)
		})
		blob:jumpTo(1)               -- posición inmediata
		blob:animateTo(1, 3)         -- stretch → settle animado
]]

local TweenService = game:GetService("TweenService")

local BlobIndicator = {}
BlobIndicator.__index = BlobIndicator

function BlobIndicator.new(parent, config)
	config = config or {}
	local self = setmetatable({}, BlobIndicator)

	local tabCount     = config.tabCount or 2
	local padding      = config.padding or 4
	local cornerRadius = config.cornerRadius or 8
	local bgColor      = config.bgColor or Color3.fromRGB(32, 32, 32)
	local zIndex       = config.zIndex or (parent.ZIndex + 1)

	self._tabCount = tabCount
	self._padding  = padding
	self._scale    = 1 / tabCount

	-- Crear Frame blob
	local frame = Instance.new("Frame")
	frame.Name = "BlobIndicator"
	frame.Size = self:getSize()
	frame.Position = self:getPosForIndex(1)
	frame.BackgroundColor3 = bgColor
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = frame

	self._frame = frame
	return self
end

function BlobIndicator:getSize()
	local p = self._padding
	return UDim2.new(self._scale, -p * 2, 1, -p * 2)
end

function BlobIndicator:getPosForIndex(index)
	local p = self._padding
	return UDim2.new(self._scale * (index - 1), p, 0, p)
end

function BlobIndicator:jumpTo(index)
	self._frame.Position = self:getPosForIndex(index)
	self._frame.Size = self:getSize()
end

function BlobIndicator:animateTo(oldIndex, newIndex)
	local p = self._padding
	local s = self._scale
	local blob = self._frame

	local minIdx = math.min(oldIndex, newIndex)
	local maxIdx = math.max(oldIndex, newIndex)
	local span   = maxIdx - minIdx + 1

	local stretchPos  = UDim2.new(s * (minIdx - 1), p, 0, p)
	local stretchSize = UDim2.new(s * span, -p * 2, 1, -p * 2)
	local targetPos   = self:getPosForIndex(newIndex)
	local targetSize  = self:getSize()

	local TW_STRETCH = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local TW_SETTLE  = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	TweenService:Create(blob, TW_STRETCH, { Size = stretchSize, Position = stretchPos }):Play()
	task.delay(0.19, function()
		TweenService:Create(blob, TW_SETTLE, { Size = targetSize, Position = targetPos }):Play()
	end)
end

function BlobIndicator:getFrame()
	return self._frame
end

return BlobIndicator
