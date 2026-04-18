local TweenService = game:GetService("TweenService")

local salon = workspace:WaitForChild("Luces")
local pista = workspace:WaitForChild("LucesPiso")

_G.LucesActivas = false

local coloresOriginales = {}
local tweensActivos = {}

-- guardar colores originales del salon
for _, obj in ipairs(salon:GetDescendants()) do
	if obj:IsA("BasePart") then
		coloresOriginales[obj] = obj.Color
	end
end

-- 🎨 colores actualizados (con amarillo y rosa)
local colores = {
	Color3.fromRGB(255,0,0), -- rojo
	Color3.new(0.1,0.1,0.1),

	Color3.fromRGB(255,255,0), -- amarillo
	Color3.new(0.1,0.1,0.1),

	Color3.fromRGB(0,255,0), -- verde
	Color3.new(0.1,0.1,0.1),

	Color3.fromRGB(255,20,147), -- rosa (más neón)
	Color3.new(0.1,0.1,0.1),

	Color3.fromRGB(0,0,255), -- azul
	Color3.new(0.1,0.1,0.1)
}

local index = 1

task.spawn(function()
	while true do

		local color = colores[index]
		local tiempo = 0.5

		if color == Color3.new(0.1,0.1,0.1) then
			tiempo = 0.15
		end

		if _G.LucesActivas then

			for _, obj in ipairs(salon:GetDescendants()) do
				if obj:IsA("BasePart") then

					local tween = TweenService:Create(
						obj,
						TweenInfo.new(tiempo, Enum.EasingStyle.Linear),
						{Color = color}
					)

					table.insert(tweensActivos, tween)
					tween:Play()
				end
			end

			for _, obj in ipairs(pista:GetChildren()) do
				if obj:IsA("BasePart") then

					local tween = TweenService:Create(
						obj,
						TweenInfo.new(tiempo, Enum.EasingStyle.Linear),
						{Color = color}
					)

					table.insert(tweensActivos, tween)
					tween:Play()
				end
			end

		else

			for _, obj in ipairs(pista:GetChildren()) do
				if obj:IsA("BasePart") then

					local tween = TweenService:Create(
						obj,
						TweenInfo.new(tiempo, Enum.EasingStyle.Linear),
						{Color = color}
					)

					tween:Play()
				end
			end

		end

		task.wait(tiempo)

		index += 1
		if index > #colores then
			index = 1
		end

	end
end)

_G.LucesOn = function()
	_G.LucesActivas = true
end

_G.LucesOff = function()

	_G.LucesActivas = false

	-- cancelar tweens
	for _, tween in ipairs(tweensActivos) do
		pcall(function()
			tween:Cancel()
		end)
	end

	tweensActivos = {}

	task.wait()

	-- restaurar colores originales
	for part, color in pairs(coloresOriginales) do
		if part and part.Parent then
			part.Color = color
		end
	end

end