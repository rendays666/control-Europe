-- ============================================================
-- MainWindow.lua — ScreenGui, window (drag, minimize, close, tab, hotkey).
-- Hanya membuat "kerangka"; isi tiap halaman ada di ArmyPage / UpgradePage,
-- dan panel log di LogPanel.
-- Return: { armyPage, upgradePage, logHolder }
-- ============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local MainWindow = {}

function MainWindow.build(ctx)
	local Cfg, W = ctx.Config, ctx.W
	local C = Cfg.Colors
	local width, height, logH = Cfg.Window.Width, Cfg.Window.Height, Cfg.Window.LogHeight
	local PG = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- buang instance lama (jika script dijalankan ulang)
	local old = PG:FindFirstChild(Cfg.GuiName)
	if old then
		old:Destroy()
	end

	local gui = W.new("ScreenGui", {
		Name = Cfg.GuiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PG)
	ctx.janitor:Add(gui)
	ctx.janitor:Add(gui.Destroying:Connect(ctx.destroy))

	local root = W.new("Frame", {
		Name = "Root",
		Size = UDim2.fromOffset(width, height),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.bg,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
	}, gui)
	W.corner(root, 10)
	W.stroke(root, C.border, 2)

	-- perkecil otomatis di layar kecil (HP)
	local uiScale = W.new("UIScale", { Scale = 1 }, root)
	local cam = workspace.CurrentCamera
	if cam then
		local vp = cam.ViewportSize
		uiScale.Scale = math.clamp(math.min(vp.X / (width + 40), vp.Y / (height + 40)), 0.5, 1)
	end

	-- ---------- Title bar ----------
	local titleBar = W.new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	}, root)
	W.label(titleBar, Cfg.Title, {
		Size = UDim2.new(1, -90, 1, 0),
		Position = UDim2.new(0, 15, 0, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
	})

	local body = W.new("Frame", {
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundTransparency = 1,
	}, root)

	local minimized = false
	W.button(titleBar, "—", {
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -72, 0, 5),
		TextSize = 15,
	}, function()
		minimized = not minimized
		body.Visible = not minimized
		root.Size = UDim2.fromOffset(width, minimized and 40 or height)
	end)
	W.button(titleBar, "✕", {
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -37, 0, 5),
		BackgroundColor3 = C.danger,
		TextSize = 15,
	}, function()
		ctx.destroy()
	end)

	-- ---------- Drag ----------
	local dragging, dragStart, startPos = false, Vector3.zero, root.Position
	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	titleBar.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging, dragStart, startPos = true, input.Position, root.Position
		end
	end)
	ctx.janitor:Add(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - dragStart) / uiScale.Scale
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	ctx.janitor:Add(UIS.InputEnded:Connect(function(input)
		if isPointer(input) then
			dragging = false
		end
	end))

	-- ---------- Hotkey show/hide ----------
	ctx.janitor:Add(UIS.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Cfg.ToggleKey then
			gui.Enabled = not gui.Enabled
		end
	end))

	-- ---------- Tabs ----------
	local tabBar = W.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, body)
	W.pad(tabBar, 6)
	local armyTab = W.button(tabBar, "🪖 Army Manager", {
		Size = UDim2.new(0.5, -3, 1, 0),
		TextSize = 14,
		BackgroundColor3 = C.panel,
	})
	local upTab = W.button(tabBar, "🏙 Auto Upgrade", {
		Size = UDim2.new(0.5, -3, 1, 0),
		Position = UDim2.new(0.5, 3, 0, 0),
		TextSize = 14,
		BackgroundColor3 = C.panel,
	})

	-- ---------- Pages ----------
	local pages = W.new("Frame", {
		Size = UDim2.new(1, 0, 1, -(40 + logH)),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundTransparency = 1,
	}, body)
	W.pad(pages, 8)
	local armyPage = W.new("Frame", { Name = "ArmyPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, pages)
	local upPage = W.new("Frame", {
		Name = "UpgradePage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, pages)

	local function setTab(which)
		local isArmy = which == "army"
		armyPage.Visible = isArmy
		upPage.Visible = not isArmy
		armyTab.BackgroundColor3 = isArmy and C.accent or C.panel
		armyTab.TextColor3 = isArmy and C.text or C.textDim
		upTab.BackgroundColor3 = isArmy and C.panel or C.accent
		upTab.TextColor3 = isArmy and C.textDim or C.text
	end
	armyTab.MouseButton1Click:Connect(function() setTab("army") end)
	upTab.MouseButton1Click:Connect(function() setTab("upgrade") end)
	setTab("army")

	-- ---------- Log holder (diisi LogPanel) ----------
	local logHolder = W.new("Frame", {
		Name = "LogHolder",
		Size = UDim2.new(1, 0, 0, logH),
		Position = UDim2.new(0, 0, 1, -logH),
		BackgroundTransparency = 1,
	}, body)

	return { armyPage = armyPage, upgradePage = upPage, logHolder = logHolder }
end

return MainWindow
