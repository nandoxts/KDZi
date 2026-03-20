local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")

local GRADIENT_NAME = "RoleGradient"
local CYCLE_TIME    = 2       -- segundos para un ciclo completo (ida y vuelta)

local tweenInfo = TweenInfo.new(
	CYCLE_TIME,                    -- duración
	Enum.EasingStyle.Linear,       -- sin aceleración
	Enum.EasingDirection.InOut,
	-1,                            -- repetir infinito
	true                           -- reversa (va y vuelve)
)

local trackedGradients = {} -- [gradient] = Tween

local function startTween(gradient)
	if trackedGradients[gradient] then return end
	if not (gradient:IsA("UIGradient") and gradient.Name == GRADIENT_NAME) then return end

	gradient.Offset = Vector2.new(-1, 0)
	local tween = TweenService:Create(gradient, tweenInfo, { Offset = Vector2.new(1, 0) })
	tween:Play()
	trackedGradients[gradient] = tween
end

local function stopTween(gradient)
	local tween = trackedGradients[gradient]
	if tween then
		tween:Cancel()
	end
	trackedGradients[gradient] = nil
end

-- Enganchar los que ya existen
for _, inst in ipairs(Workspace:GetDescendants()) do
	startTween(inst)
end

-- Enganchar nuevos
Workspace.DescendantAdded:Connect(startTween)

-- Limpiar al removerse
Workspace.DescendantRemoving:Connect(stopTween)