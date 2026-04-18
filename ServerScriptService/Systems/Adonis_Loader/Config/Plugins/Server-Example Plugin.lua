--[[
	SERVER PLUGINS' NAMES MUST START WITH "Server:" OR "Server-"
	CLIENT PLUGINS' NAMES MUST START WITH "Client:" OR "Client-"

	Plugins have full access to the server/client tables and most variables.

	You can use the MakePluginEvent to use the script instead of setting up an event.
	PlayerJoined will fire after the player finishes initial loading
	CharacterAdded will also fire after the player is loaded, it does not use the CharacterAdded event.
--]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local ColorConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ColorConfig"))
	local TitleColors = {}
	for name, color in pairs(ColorConfig.colors) do
		TitleColors[name] = { Name = name, Color = color }
	end
	--pantalla
	local liveSystem = ReplicatedStorage:WaitForChild("LiveSystem")
	local currentTarget = liveSystem:WaitForChild("CurrentTarget")

	-- Helper: obtiene el RemoteEvent de Systems/Events
	local function getEvent(name)
		local eventsFolder = ReplicatedStorage:FindFirstChild("Systems")
		eventsFolder = eventsFolder and eventsFolder:FindFirstChild("Events")
		return eventsFolder and eventsFolder:FindFirstChild(name)
	end

	-- Helper: resuelve targets (all / me / player)
	local function fireEffect(plr, args, eventName)
		local evt = getEvent(eventName)
		if not evt then return end

		local target = args[1]
		if target then
			local lowered = type(target) == "string" and target:lower() or ""
			if lowered == "all" or lowered == "everyone" or lowered == "*" then
				evt:FireAllClients()
				return
			end
			if lowered == "others" then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= plr then evt:FireClient(p) end
				end
				return
			end
			-- Buscar jugador por nombre
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Name:lower() == lowered or (p.DisplayName and p.DisplayName:lower() == lowered) then
					evt:FireClient(p)
					return
				end
			end
		end
		-- Sin argumento o no encontrado → aplicar al speaker
		evt:FireClient(plr)
	end
	
	local function setTitle(players, text, color)
		for _, p in ipairs(players) do
			if p.Character and p.Character:FindFirstChild("Head") then
				local head = p.Character.Head
				local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
				if not humanoid then continue end

				local old = head:FindFirstChild("TITLE")
				if old then old:Destroy() end

				local heightScale = humanoid:FindFirstChild("BodyHeightScale")
				local headScale = humanoid:FindFirstChild("HeadScale")
				local scaleFactor = math.max(
					heightScale and heightScale.Value or 1,
					headScale and headScale.Value or 1
				)

				local gui = Instance.new("BillboardGui")
				gui.Name = "TITLE"
				gui.Adornee = head
				gui.Size = UDim2.new(4 * scaleFactor, 0, 1 * scaleFactor, 0)
				gui.StudsOffsetWorldSpace = Vector3.new(0, 3 * scaleFactor, 0)
				gui.AlwaysOnTop = true
				gui.MaxDistance = 1000
				gui.LightInfluence = 0
				gui.Parent = head

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextScaled = true
				label.TextSize = 12
				label.TextColor3 = color
				label.TextStrokeColor3 = Color3.fromRGB(51, 0, 0)
				label.TextStrokeTransparency = 0.5
				label.TextTransparency = 0
				label.TextWrapped = true
				label.TextTruncate = Enum.TextTruncate.None
				label.TextXAlignment = Enum.TextXAlignment.Center
				label.TextYAlignment = Enum.TextYAlignment.Bottom
				label.Font = Enum.Font.SourceSansBold
				label.RichText = false
				label.Parent = gui
			end
		end
	end


	-- ═══════════════════════════════════════
	--  COMANDOS DE EFECTOS VISUALES
	-- ═══════════════════════════════════════

	server.Commands.Fiesta = {
		Prefix = server.Settings.Prefix;
		Commands = {"fiesta"};
		Args = {"player/all (opcional)"};
		Description = "Inicia efectos de fiesta";
		Hidden = false;
		Fun = true;
		AdminLevel = "Creators";
		Function = function(plr, args)
			fireEffect(plr, args, "FiestaEvent")
		end
	}

	server.Commands.Pulse = {
		Prefix = server.Settings.Prefix;
		Commands = {"pulse"};
		Args = {"player/all (opcional)"};
		Description = "Dispara efecto de pulso/rotación";
		Hidden = false;
		Fun = true;
		AdminLevel = "Creators";
		Function = function(plr, args)
			fireEffect(plr, args, "RotateEffectEvent")
		end
	}

	server.Commands.Quake = {
		Prefix = server.Settings.Prefix;
		Commands = {"quake"};
		Args = {"player/all (opcional)"};
		Description = "Activa efecto terremoto";
		Hidden = false;
		Fun = true;
		AdminLevel = "Creators";
		Function = function(plr, args)
			fireEffect(plr, args, "TerremotoEvent")
		end
	}

	server.Commands.Acid = {
		Prefix = server.Settings.Prefix;
		Commands = {"acid"};
		Args = {"player/all (opcional)"};
		Description = "Activa efecto aurora/acid trip";
		Hidden = false;
		Fun = true;
		AdminLevel = "Creators";
		Function = function(plr, args)
			fireEffect(plr, args, "AcidTripEvent")
		end
	}

	server.Commands.Pyscho = {
		Prefix = server.Settings.Prefix;
		Commands = {"pyscho"};
		Args = {"player/all (opcional)"};
		Description = "Activa efecto pyscho";
		Hidden = false;
		Fun = true;
		AdminLevel = "Creators";
		Function = function(plr, args)
			fireEffect(plr, args, "PsicoSkyEvent")
		end
	}
	server.Commands.Luces = {
		Prefix = server.Settings.Prefix;
		Commands = {"luces"};
		Args = {};
		Description = "Activa o desactiva las luces";
		Hidden = false;
		Fun = true;
		AdminLevel = "Moderators";

		Function = function(plr, args)

			if _G.LucesActivas then
				_G.LucesOff()
			else
				_G.LucesOn()
			end

		end
	}
	server.Commands.LucesOff = {
		Prefix = server.Settings.Prefix;
		Commands = {"lucesoff"};
		Args = {};
		Description = "Apaga las luces";
		Hidden = false;
		Fun = true;
		AdminLevel = "Moderators";

		Function = function(plr, args)
			_G.LucesOff()
		end
	}
	server.Commands.KDZ = {
		Prefix = server.Settings.Prefix;
		Commands = {"kdz"};
		Args = {};
		Description = "Activa lluvia";
		AdminLevel = "Moderators";

		Function = function(plr, args)

			local rain = workspace:FindFirstChild("lluvia")

			if rain then
				for _, v in ipairs(rain:GetDescendants()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = true
					end
				end
			end

		end
	}

	server.Commands.KDZOFF = {
		Prefix = server.Settings.Prefix;
		Commands = {"kdzoff"};
		Args = {};
		Description = "Apaga lluvia";
		AdminLevel = "Moderators";

		Function = function(plr, args)

			local rain = workspace:FindFirstChild("lluvia")

			if rain then
				for _, v in ipairs(rain:GetDescendants()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
					end
				end
			end

		end
	}
	--titulos
	for cmdName, colorData in pairs(TitleColors) do
		local commandName = "title" .. cmdName  -- Ejemplo: titley, titler, titleg

		server.Commands[commandName] = {
			Prefix = server.Settings.Prefix;
			Commands = {commandName};
			Args = {"player", "text"};
			Description = "Asigna un título de color " .. colorData.Name;
			AdminLevel = "Admins";

			Function = function(plr, args)
				local targets = service.GetPlayers(plr, args[1])
				local text = table.concat(args, " ", 2)

				if text == "" then
					return "Debes especificar el texto del título."
				end

				if not targets or #targets == 0 then
					return "No se encontraron jugadores."
				end

				setTitle(targets, text, colorData.Color)
			end
		}
	end

	-- ═══════════════════════════════════════
	-- COMANDO PARA ELIMINAR EL TÍTULO
	-- ═══════════════════════════════════════
	server.Commands.removetitle = {
		Prefix = server.Settings.Prefix;
		Commands = {"removetitle", "notitle", "untitle"};
		Args = {"player"};
		Description = "Elimina el título del jugador";
		AdminLevel = "Admins";

		Function = function(plr, args)
			local targets = service.GetPlayers(plr, args[1])
			for _, p in ipairs(targets) do
				if p.Character and p.Character:FindFirstChild("Head") then
					local old = p.Character.Head:FindFirstChild("TITLE")
					if old then old:Destroy() end
				end
			end
		end
	}

	--pantalla 
	server.Commands.Screen = {
		Prefix = server.Settings.Prefix;
		Commands = {"screen"};
		Args = {"player"};
		Description = "Show player on screen";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";

		Function = function(plr, args)
			local targetName = args[1]

			if not targetName then return end

			targetName = string.lower(targetName)

			-- 🟣 YO MISMO
			if targetName == "me" then
				currentTarget.Value = plr.Name
				print("[ADONIS] Showing yourself:", plr.Name)
				return
			end

			-- 🔴 APAGAR
			if targetName == "off" then
				currentTarget.Value = ""
				print("[ADONIS] Screen OFF")
				return
			end

			-- 🟡 ALL (opcional)
			if targetName == "all" then
				print("[ADONIS] Screen ALL (puedes hacer rotación)")
				return
			end

			-- 🟢 BUSCAR PLAYER (PARCIAL)
			local foundPlayer = nil

			for _, p in pairs(Players:GetPlayers()) do
				local name = string.lower(p.Name)
				local display = string.lower(p.DisplayName)

				if string.find(name, targetName) or string.find(display, targetName) then
					foundPlayer = p
					break
				end
			end

			if foundPlayer then
				currentTarget.Value = foundPlayer.Name
				print("[ADONIS] Showing:", foundPlayer.Name)
			else
				warn("[ADONIS] Player not found:", targetName)
			end
		end
	}
	server.Commands.Can = {
		Prefix = server.Settings.Prefix;
		Commands = {"can"};
		Args = {"player"};
		Description = "Animación de perro";
		AdminLevel = "Admins";

		Function = function(plr, args)
			local targets = service.GetPlayers(plr, args[1])

			for _,v in pairs(targets) do
				if v.Character and v.Character:FindFirstChild("Humanoid") then

					local hum = v.Character.Humanoid

					-- Eliminar animación anterior
					for _,track in pairs(hum:GetPlayingAnimationTracks()) do
						if track.Name == "DOG_ANIM_TRACK" then
							track:Stop()
						end
					end

					local anim = Instance.new("Animation")
					anim.AnimationId = "rbxassetid://114731495347458"

					local track = hum:LoadAnimation(anim)
					track.Name = "DOG_ANIM_TRACK"
					track.Looped = true
					track:Play()
					local root = v.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://122709731022286"
						sound.Volume = 1
						sound.PlayOnRemove = true
						sound.Parent = root
						sound:Destroy() -- 🔥 se reproduce una sola vez
					end
				end
			end
		end
	}
	server.Commands.Uncan = {
		Prefix = server.Settings.Prefix;
		Commands = {"uncan"};
		Args = {"player"};
		Description = "Quita animación de perro";
		AdminLevel = "Admins";

		Function = function(plr, args)
			local targets = service.GetPlayers(plr, args[1])

			for _,v in pairs(targets) do
				if v.Character and v.Character:FindFirstChild("Humanoid") then

					local hum = v.Character.Humanoid

					for _,track in pairs(hum:GetPlayingAnimationTracks()) do
						if track.Name == "DOG_ANIM_TRACK" then
							track:Stop()
						end
					end
				end
			end
		end
	}
end
