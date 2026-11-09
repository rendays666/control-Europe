-- ============================================================
-- AUTO MANAGER — Control Europe  (entry point)
--
-- LocalScript ini hanya "merakit" modul. Tidak ada logic di sini.
--
--   Core/      Config, Janitor, Logger, Remote, Context   (fondasi)
--   Services/  World, Spawner, AutoCapture, AutoDelete, AutoUpgrade  (logic game)
--   UI/        Widgets, MainWindow, LogPanel, ArmyPage, UpgradePage  (tampilan)
--
-- Semua modul menerima satu objek `ctx` (lihat Core/Context.lua).
-- ============================================================

local Core = script:WaitForChild("Core")
local Services = script:WaitForChild("Services")
local UI = script:WaitForChild("UI")

local Config = require(Core.Config)
local ctx = require(Core.Context).new(Config, require(Core.Janitor), require(Core.Logger))

local ok, err = pcall(function()
	-- urutan penting: remote → world → widgets → service → UI
	ctx.remote = require(Core.Remote).new(ctx)
	ctx.world = require(Services.World).new(ctx)
	ctx.W = require(UI.Widgets).create(Config.Colors)

	require(Services.Spawner).start(ctx)
	require(Services.AutoCapture).start(ctx)
	require(Services.AutoDelete).start(ctx)
	require(Services.AutoUpgrade).start(ctx)

	local window = require(UI.MainWindow).build(ctx)
	require(UI.LogPanel).build(ctx, window.logHolder)
	require(UI.ArmyPage).build(ctx, window.armyPage)
	require(UI.UpgradePage).build(ctx, window.upgradePage)
end)

if not ok then
	warn("[AutoMgr] Gagal start: " .. tostring(err))
	ctx.destroy()
	return
end

ctx.log(("Auto Manager v%s loaded. Negara: %s. Tekan %s untuk show/hide."):format(
	Config.Version, tostring(ctx.world.getCountry(true)), Config.ToggleKey.Name), "ok")
