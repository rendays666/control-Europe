-- ============================================================
-- Spawner.lua — spawn army di tile lalu otomatis masukkan ke grup.
-- ============================================================

local Spawner = {}

function Spawner.start(ctx)
	local world, T = ctx.world, ctx.Config.Timing
	local claimed = {} -- soldier yang sudah diproses (cegah dobel AddToArmyGroup)
	local self = {}

	-- Validasi input; return (ok, errorMessage)
	local function validate(st)
		local country = world.getCountry(true)
		if not country then
			return false, "Bukan leader negara manapun"
		end
		if st.tileName == "" then
			return false, "Nama tile kosong (isi manual atau klik Auto Detect)"
		end
		local tile = world.regions:FindFirstChild(st.tileName)
		if not tile then
			return false, ("Tile '%s' tidak ditemukan"):format(st.tileName)
		end
		local owner = tile:FindFirstChild("Country")
		if not owner or owner.Value ~= country then
			return false, ("Tile '%s' bukan milik %s"):format(st.tileName, country)
		end
		return true, nil
	end

	-- Pantau soldier baru di tile, masukkan ke grup. Berhenti jika sudah tenang.
	local function watch(group, tileName, country, existing)
		local deadline = os.clock() + T.spawnTimeout
		local found, lastFound = 0, nil

		while ctx.running and os.clock() < deadline do
			task.wait(T.spawnPoll)
			for _, s in ipairs(world.soldiers:GetChildren()) do
				if not existing[s.Name] and not claimed[s.Name] then
					if world.getSoldierTile(s) == tileName and world.getSoldierCountry(s) == country then
						claimed[s.Name] = true
						existing[s.Name] = true
						if not group:FindFirstChild(s.Name) then
							ctx.remote.fire("AddToArmyGroup", group.Name, s.Name)
							found += 1
							lastFound = os.clock()
							ctx.log(("Added: %s %d"):format(world.getType(s), math.floor(world.getAmount(s))), "ok")
						end
					end
				end
			end
			if lastFound and (os.clock() - lastFound) > T.spawnQuietAfterFound then
				break
			end
		end

		if found == 0 and ctx.running then
			ctx.log("Tidak ada army baru terdeteksi (uang kurang? atau ter-merge dengan army lama di tile)", "warn")
		end
	end

	function self.spawn()
		local st = ctx.state
		local ok, err = validate(st)
		if not ok then
			ctx.log("Error: " .. err, "error")
			return
		end

		local country = world.getCountry()
		local tileName, unit, amount = st.tileName, st.unitType, st.amount

		local group = world.ensureGroup(st.groupName)
		if not group then
			ctx.log(("Error: gagal membuat grup '%s'"):format(st.groupName), "error")
			return
		end

		if st.autoDeleteEnabled and amount <= st.autoDeleteThreshold then
			ctx.log(("Peringatan: Auto Delete aktif & jumlah spawn (%d) ≤ batas (%d) — army akan langsung dihapus!")
				:format(amount, st.autoDeleteThreshold), "warn")
		end

		local existing = {}
		for _, s in ipairs(world.soldiers:GetChildren()) do
			existing[s.Name] = true
		end

		if ctx.remote.fire("CreateArmyOnTile", tileName, unit, amount) then
			ctx.log(("Spawning %d %s di %s"):format(amount, unit, tileName))
			task.spawn(watch, group, tileName, country, existing)
		end
	end

	-- Pilih tile milik kita dengan populasi terbesar; return nama tile / nil
	function self.detectBestTile()
		local tiles = world.getOwnedTiles()
		if #tiles == 0 then
			return nil
		end
		table.sort(tiles, function(a, b)
			return world.getPopulation(a) > world.getPopulation(b)
		end)
		return tiles[1].Name
	end

	ctx.services.spawner = self
	return self
end

return Spawner
