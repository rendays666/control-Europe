-- ============================================================
-- AutoUpgrade.lua — upgrade (DevelopTile) semua kota sampai level target.
-- Hasil status dibaca UI lewat ctx.runtime.upgradeStatus.
-- ============================================================

local AutoUpgrade = {}

function AutoUpgrade.start(ctx)
	local world, T = ctx.world, ctx.Config.Timing
	local cooldown = {} -- [tileName] = waktu boleh dicoba lagi
	local self = {}

	local function setStatus(text)
		ctx.runtime.upgradeStatus = text
	end

	function self.startRun()
		ctx.state.autoUpgradeRunning = true
		ctx.log("Auto Upgrade START → target Lv " .. ctx.state.autoUpgradeTarget, "ok")
	end

	function self.stopRun()
		ctx.state.autoUpgradeRunning = false
		setStatus("Status: Idle")
		ctx.log("Auto Upgrade STOP")
	end

	local function cycle()
		local st = ctx.state
		if not st.autoUpgradeRunning then
			cooldown = {}
			return
		end

		local country = world.getCountry()
		if not country then
			setStatus("Status: Menunggu negara...")
			task.wait(2)
			return
		end

		-- daftar kota yang belum mencapai target, level terendah dulu
		local todo = {}
		for _, tile in ipairs(world.getOwnedTiles()) do
			if world.getTier(tile) < st.autoUpgradeTarget then
				todo[#todo + 1] = tile
			end
		end
		table.sort(todo, function(a, b)
			return world.getTier(a) < world.getTier(b)
		end)

		if #todo == 0 then
			setStatus("Status: ✓ Semua kota sudah Lv " .. st.autoUpgradeTarget)
			return
		end

		local upgraded, fails = 0, 0
		for _, tile in ipairs(todo) do
			if not ctx.running or not st.autoUpgradeRunning then
				break
			end
			if os.clock() >= (cooldown[tile.Name] or 0) then
				local before = world.getTier(tile)
				ctx.remote.fire("DevelopTile", tile.Name, "Tier")
				task.wait(T.upgradeWait)
				local after = world.getTier(tile)

				if after > before then
					upgraded += 1
					fails = 0
					cooldown[tile.Name] = os.clock() + 1
					ctx.log(("Upgraded %s: Lv %d → Lv %d"):format(tile.Name, before, after), "ok")
				else
					fails += 1
					cooldown[tile.Name] = os.clock() + T.upgradeFailCooldown
					-- gagal beruntun = kemungkinan besar uang kurang; jangan buang waktu ke semua kota
					if fails >= T.upgradeMaxFails then
						break
					end
				end
			end
		end

		if fails >= T.upgradeMaxFails and upgraded == 0 then
			setStatus(("Status: Menunggu uang (%d kota pending, target Lv %d)"):format(#todo, st.autoUpgradeTarget))
			task.wait(T.upgradeIdleWait)
		else
			setStatus(("Status: Upgrading (%d pending, %d baru naik, target Lv %d)")
				:format(#todo - upgraded, upgraded, st.autoUpgradeTarget))
		end
	end

	ctx.every(T.upgradeCycle, cycle, "AutoUpgrade")
	ctx.services.upgrade = self
	return self
end

return AutoUpgrade
