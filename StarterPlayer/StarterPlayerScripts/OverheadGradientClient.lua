local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GRADIENT_NAME = "RoleGradient"
local GRADIENT_SPEED = 0.5
local RESCAN_INTERVAL = 1

local trackedGradients = {}

local function shouldTrack(instance)
	return instance:IsA("UIGradient") and instance.Name == GRADIENT_NAME
end

local function trackGradient(gradient)
	if not shouldTrack(gradient) then
		return
	end
	trackedGradients[gradient] = true
end

local function untrackGradient(gradient)
	trackedGradients[gradient] = nil
end

local function scanWorkspaceGradients()
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if shouldTrack(instance) then
			trackGradient(instance)
		end
	end
end

scanWorkspaceGradients()

Workspace.DescendantAdded:Connect(function(instance)
	if shouldTrack(instance) then
		trackGradient(instance)
	end
end)

Workspace.DescendantRemoving:Connect(function(instance)
	if trackedGradients[instance] then
		untrackGradient(instance)
	end
end)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local x = ((now * GRADIENT_SPEED) % 2) - 1

	for gradient in pairs(trackedGradients) do
		if gradient.Parent then
			if gradient.Enabled then
				gradient.Offset = Vector2.new(x, 0)
			end
		else
			untrackGradient(gradient)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(RESCAN_INTERVAL)
		scanWorkspaceGradients()
	end
end)