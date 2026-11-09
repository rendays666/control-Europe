-- ============================================================
-- AUTO MANAGER — Control Europe  (entry point untuk Roblox Studio / Rojo)
--
-- Hanya menyiapkan fungsi `load` lalu menyerahkan ke Boot.lua.
-- (Untuk executor/loadstring, pakai loader.lua di root repo.)
--
--   Core/      Config, Janitor, Logger, Remote, Context   (fondasi)
--   Services/  World, Spawner, AutoCapture, AutoDelete, AutoUpgrade  (logic game)
--   UI/        Widgets, MainWindow, LogPanel, ArmyPage, UpgradePage  (tampilan)
-- ============================================================

local function load(path)
	local inst = script
	for segment in path:gmatch("[^/]+") do
		inst = inst:WaitForChild(segment)
	end
	return require(inst)
end

require(script:WaitForChild("Boot"))(load)
