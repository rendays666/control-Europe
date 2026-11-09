-- ============================================================
-- Config.lua — semua konstanta & nilai default ada di sini.
-- Mau ubah warna / interval / daftar unit? Cukup edit file ini.
-- ============================================================

local Config = {}

Config.Title = "⚡ Auto Manager — Control Europe"
Config.Version = "2.0.0"
Config.GuiName = "AutoManagerGui"
Config.ToggleKey = Enum.KeyCode.RightShift -- tombol untuk show/hide GUI

Config.Window = {
	Width = 620,
	Height = 700,
	LogHeight = 130, -- tinggi panel log di bawah
}

Config.Colors = {
	bg = Color3.fromRGB(24, 26, 32),
	panel = Color3.fromRGB(34, 37, 46),
	panel2 = Color3.fromRGB(42, 46, 58),
	accent = Color3.fromRGB(70, 130, 220),
	success = Color3.fromRGB(60, 180, 90),
	danger = Color3.fromRGB(200, 60, 60),
	warn = Color3.fromRGB(230, 170, 60),
	text = Color3.fromRGB(230, 235, 245),
	textDim = Color3.fromRGB(150, 160, 175),
	border = Color3.fromRGB(80, 90, 110),
}

Config.UnitTypes = {
	"Soldier",
	"Tank",
	"Plane",
	"Artillery",
	"Battleship",
	"Aircraft Carrier",
	"TransportShip",
}

-- Nilai awal setting (bisa diubah user lewat GUI)
Config.Defaults = {
	unitType = "Soldier",
	amount = 20000,
	tileName = "",
	groupName = "AutoFarm",
	autoCapture = false,
	autoDeleteEnabled = false,
	autoDeleteThreshold = 10000,
	autoUpgradeTarget = 3,
	autoUpgradeRunning = false,
}

-- Interval loop (detik)
Config.Timing = {
	statusRefresh = 1,
	armyListRefresh = 2,
	cityListRefresh = 3,
	autoCapture = 3,
	autoDelete = 2,
	upgradeCycle = 1,

	countryCache = 0.5, -- cache hasil deteksi negara
	spawnPoll = 1, -- cek army baru setelah spawn
	spawnTimeout = 180, -- batas maksimal menunggu army baru
	spawnQuietAfterFound = 6, -- berhenti jika tidak ada army baru selama N detik

	captureResendCooldown = 10, -- jangan kirim ulang ToggleAutoCapture ke army yang sama
	deleteResendCooldown = 5, -- jangan kirim ulang DeleteSoldiers ke army yang sama

	upgradeWait = 1.2, -- tunggu server memproses DevelopTile
	upgradeFailCooldown = 4, -- jeda per kota yang gagal di-upgrade
	upgradeMaxFails = 3, -- gagal beruntun sebanyak ini = anggap uang kurang, tunggu
	upgradeIdleWait = 3, -- lama menunggu uang
}

Config.LogMaxLines = 150

-- Nama RemoteEvent di game (dipakai lewat Network:Bind)
Config.Remotes = {
	CreateArmyGroup = "CreateArmyGroup",
	AddToArmyGroup = "AddToArmyGroup",
	KickFromArmyGroup = "KickFromArmyGroup",
	CreateArmyOnTile = "CreateArmyOnTile",
	DeleteSoldiers = "DeleteSoldiers",
	ToggleAutoCapture = "ToggleAutoCapture",
	DevelopTile = "DevelopTile",
}

return Config
