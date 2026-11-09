-- ============================================================
-- World.lua — akses data game: negara, tile/kota, grup army, soldier.
-- Semua service lain membaca game LEWAT modul ini (bukan langsung).
-- ============================================================

local World = {}

local function waitFor(parent, name)
	local obj = parent:WaitForChild(name, 10)
	if not obj then
		error(("'%s.%s' tidak ditemukan — struktur game berubah?"):format(parent:GetFullName(), name))
	end
	return obj
end

function World.new(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local WS = game:GetService("Workspace")
	local LP = game:GetService("Players").LocalPlayer

	local self = {
		registry = waitFor(RS, "CountryRegistry"), -- folder negara (ActiveLeader, Money)
		armyGroups = waitFor(RS, "ArmyGroups"), -- folder grup army
		regions = waitFor(WS, "Regions"), -- folder tile/kota
		soldiers = waitFor(WS, "SoldiersFolder"), -- folder semua army
	}

	-- ---------- Negara ----------
	local cachedCountry, cachedAt = nil, 0

	-- Cari negara yang dipimpin player ini. Di-cache sebentar agar tidak scan terus.
	function self.getCountry(force)
		local now = os.clock()
		if not force and (now - cachedAt) < ctx.Config.Timing.countryCache then
			return cachedCountry
		end
		local found = nil
		for _, c in ipairs(self.registry:GetChildren()) do
			local leader = c:FindFirstChild("ActiveLeader")
			if leader and leader.Value == LP then
				found = c.Name
				break
			end
		end
		cachedCountry, cachedAt = found, now
		ctx.runtime.country = found
		return found
	end

	function self.getMoney()
		local country = self.getCountry()
		local node = country and self.registry:FindFirstChild(country)
		local money = node and node:FindFirstChild("Money")
		return money and math.floor(money.Value) or nil
	end

	-- ---------- Tile / Kota ----------
	function self.getOwnedTiles()
		local tiles = {}
		local country = self.getCountry()
		if not country then
			return tiles
		end
		for _, tile in ipairs(self.regions:GetChildren()) do
			local owner = tile:FindFirstChild("Country")
			if owner and owner.Value == country then
				tiles[#tiles + 1] = tile
			end
		end
		return tiles
	end

	function self.getTier(tile)
		return tile:GetAttribute("DevelopTier") or 0
	end

	function self.getPopulation(tile)
		return tile:GetAttribute("Population") or 0
	end

	-- ---------- Grup army ----------
	function self.findGroup(name)
		if not name or name == "" then
			return nil
		end
		for _, g in ipairs(self.armyGroups:GetChildren()) do
			if g:GetAttribute("DN") == name or g.Name == name then
				return g
			end
		end
		return nil
	end

	-- Cari grup; kalau belum ada, buat lalu tunggu maksimal ~2 detik.
	function self.ensureGroup(name)
		local g = self.findGroup(name)
		if g then
			return g
		end
		ctx.remote.fire("CreateArmyGroup", name)
		for _ = 1, 10 do
			task.wait(0.2)
			g = self.findGroup(name)
			if g then
				return g
			end
		end
		return nil
	end

	-- Daftar soldier (Instance) yang tergabung di grup
	function self.getGroupSoldiers(group)
		local list = {}
		if not group then
			return list
		end
		for _, child in ipairs(group:GetChildren()) do
			if child:IsA("BoolValue") then
				local s = self.soldiers:FindFirstChild(child.Name)
				if s then
					list[#list + 1] = s
				end
			end
		end
		return list
	end

	-- ---------- Soldier ----------
	function self.getAmount(soldier)
		local amt = soldier:FindFirstChild("Amount")
		return amt and amt.Value or 0
	end

	function self.getType(soldier)
		local t = soldier:FindFirstChild("Type")
		return t and t.Value or "?"
	end

	function self.getSoldierCountry(soldier)
		local c = soldier:FindFirstChild("Country")
		return c and c.Value or nil
	end

	function self.getSoldierTile(soldier)
		return soldier:GetAttribute("StandingOnTile")
	end

	return self
end

return World
