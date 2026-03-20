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
end
