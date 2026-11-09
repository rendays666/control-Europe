-- ============================================================
-- Boot.lua — merakit semua modul. Dipakai oleh DUA jalur:
--   • Studio    → init.client.lua   (load = require ModuleScript)
--   • Executor  → loader.lua        (load = unduh dari GitHub + loadstring)
--
-- Pemakaian: require(Boot)(load)   dengan load("Core/Config") → modul
-- Return: ctx (atau nil jika gagal start)
-- ============================================================

return function(load)
	local Config = load("Core/Config")
	local ctx = load("Core/Context").new(Config, load("Core/Janitor"), load("Core/Logger"))

	local ok, err = pcall(function()
		-- urutan penting: remote → world → widgets → service → UI
		ctx.remote = load("Core/Remote").new(ctx)
		ctx.world = load("Services/World").new(ctx)
		ctx.W = load("UI/Widgets").create(Config.Colors)

		load("Services/Spawner").start(ctx)
		load("Services/AutoCapture").start(ctx)
		load("Services/AutoDelete").start(ctx)
		load("Services/AutoUpgrade").start(ctx)

		local window = load("UI/MainWindow").build(ctx)
		load("UI/LogPanel").build(ctx, window.logHolder)
		load("UI/ArmyPage").build(ctx, window.armyPage)
		load("UI/UpgradePage").build(ctx, window.upgradePage)
	end)

	if not ok then
		warn("[AutoMgr] Gagal start: " .. tostring(err))
		ctx.destroy()
		return nil
	end

	ctx.log(("Auto Manager v%s loaded. Negara: %s. Tekan %s untuk show/hide."):format(
		Config.Version, tostring(ctx.world.getCountry(true)), Config.ToggleKey.Name), "ok")
	return ctx
end
