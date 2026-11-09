-- ============================================================
-- Remote.lua — pembungkus aman untuk Network:Bind(evt):FireServer(...)
-- ============================================================

local Remote = {}

function Remote.new(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local names = ctx.Config.Remotes

	local ok, Network = pcall(function()
		return require(RS.Modules.Shared.Network)
	end)
	if not ok then
		error("Network module tidak ditemukan (ReplicatedStorage.Modules.Shared.Network): " .. tostring(Network))
	end

	local self = {}

	-- fire("CreateArmyGroup", "Nama") — return true jika berhasil terkirim
	function self.fire(key, ...)
		local evt = names[key]
		if not evt then
			ctx.log("Remote '" .. tostring(key) .. "' tidak terdaftar di Config.Remotes", "error")
			return false
		end
		local args = table.pack(...)
		local success, err = pcall(function()
			Network:Bind(evt):FireServer(table.unpack(args, 1, args.n))
		end)
		if not success then
			ctx.log(evt .. ": " .. tostring(err), "error")
		end
		return success
	end

	return self
end

return Remote
