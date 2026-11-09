-- ============================================================
-- ArmyPage.lua — tab "Army Manager": spawn, grup, auto capture/delete, daftar army.
-- Daftar army memakai diff-update (baris dipakai ulang, tidak dihancurkan
-- tiap refresh) sehingga tombol Kick/Delete tidak "hilang" saat diklik.
-- ============================================================

local ArmyPage = {}

function ArmyPage.build(ctx, page)
	local C, W, st, world = ctx.Config.Colors, ctx.W, ctx.state, ctx.world
	local T = ctx.Config.Timing
	local spawner = ctx.services.spawner
	local stack = W.stack(page, 6)

	-- ---------- Status ----------
	local statusRow = stack:row(28, true)
	local statusLabel = W.label(statusRow, "", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
	})

	-- ---------- Pilih unit ----------
	local unitRow = stack:row(34)
	local types = ctx.Config.UnitTypes
	W.new("UIGridLayout", {
		CellSize = UDim2.new(1 / #types, -6, 1, 0),
		CellPadding = UDim2.fromOffset(6, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, unitRow)
	local unitBtns = {}
	local function selectUnit(name)
		st.unitType = name
		for n, btn in pairs(unitBtns) do
			btn.BackgroundColor3 = (n == name) and C.accent or C.panel2
		end
	end
	for _, name in ipairs(types) do
		unitBtns[name] = W.button(unitRow, name, { TextSize = 10, TextWrapped = true }, function()
			selectUnit(name)
		end)
	end
	selectUnit(st.unitType)

	-- ---------- Amount / Tile ----------
	local atRow = stack:hrow(28)
	W.label(atRow, "Amount:", { Size = UDim2.new(0, 55, 1, 0), TextColor3 = C.textDim })
	local amountBox = W.input(atRow, { Size = UDim2.new(0, 90, 1, 0), Text = tostring(st.amount) }, function(box)
		local n = tonumber(box.Text)
		if n and n > 0 then
			st.amount = math.floor(n)
		end
		box.Text = tostring(st.amount)
	end)
	W.label(atRow, "Tile:", { Size = UDim2.new(0, 32, 1, 0), TextColor3 = C.textDim })
	local tileBox = W.input(atRow, {
		Size = UDim2.new(0, 170, 1, 0),
		Text = st.tileName,
		PlaceholderText = "nama tile (mis. Vilnius)",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, function(box)
		st.tileName = box.Text:match("^%s*(.-)%s*$")
		box.Text = st.tileName
	end)
	W.button(atRow, "Auto Detect", { Size = UDim2.new(0, 110, 1, 0), TextSize = 11 }, function()
		local name = spawner.detectBestTile()
		if name then
			st.tileName = name
			tileBox.Text = name
			ctx.log("Tile terdeteksi: " .. name, "ok")
		else
			ctx.log("Tidak ada tile milik " .. tostring(world.getCountry(true) or "?"), "warn")
		end
	end)

	-- ---------- Group ----------
	local grpRow = stack:hrow(28)
	W.label(grpRow, "Group:", { Size = UDim2.new(0, 55, 1, 0), TextColor3 = C.textDim })
	W.input(grpRow, { Size = UDim2.new(0, 200, 1, 0), Text = st.groupName, TextXAlignment = Enum.TextXAlignment.Left }, function(box)
		local name = box.Text:match("^%s*(.-)%s*$")
		if name ~= "" then
			st.groupName = name
		end
		box.Text = st.groupName
	end)
	W.label(grpRow, "(dibuat otomatis jika belum ada)", { Size = UDim2.new(0, 220, 1, 0), TextColor3 = C.textDim, TextSize = 11 })

	-- ---------- Auto Capture / Auto Delete ----------
	local autoRow = stack:hrow(28)
	W.toggle(autoRow, "Auto Capture", st.autoCapture, { Size = UDim2.new(0, 170, 1, 0) }, function(v)
		st.autoCapture = v
	end)
	W.toggle(autoRow, "Auto Delete", st.autoDeleteEnabled, { Size = UDim2.new(0, 150, 1, 0) }, function(v)
		st.autoDeleteEnabled = v
	end)
	W.label(autoRow, "hapus jika ≤", { Size = UDim2.new(0, 75, 1, 0), TextColor3 = C.textDim, TextXAlignment = Enum.TextXAlignment.Right })
	local threshBox = W.input(autoRow, { Size = UDim2.new(0, 100, 1, 0), Text = tostring(st.autoDeleteThreshold) }, function(box)
		local n = tonumber(box.Text)
		if n and n >= 0 then
			st.autoDeleteThreshold = math.floor(n)
		end
		box.Text = tostring(st.autoDeleteThreshold)
	end)

	-- ---------- Spawn ----------
	-- FocusLost TextBox belum tentu terpanggil sebelum klik, jadi baca ulang semua input.
	local function commitInputs()
		local n = tonumber(amountBox.Text)
		if n and n > 0 then st.amount = math.floor(n) end
		amountBox.Text = tostring(st.amount)
		st.tileName = tileBox.Text:match("^%s*(.-)%s*$")
		local t = tonumber(threshBox.Text)
		if t and t >= 0 then st.autoDeleteThreshold = math.floor(t) end
	end

	local busy = false
	local spawnRow = stack:row(34)
	W.button(spawnRow, "🚀 SPAWN & ADD TO GROUP", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.success,
		TextSize = 14,
	}, function()
		if busy then return end
		busy = true
		commitInputs()
		local ok, err = pcall(spawner.spawn)
		if not ok then
			ctx.log("Spawn error: " .. tostring(err), "error")
		end
		busy = false
	end)

	-- ---------- Daftar army ----------
	local header = W.label(page, "Group Armies:", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, stack.y),
		Font = Enum.Font.GothamBold,
	})
	local listTop = stack.y + 24
	local list = W.scroll(page, {
		Size = UDim2.new(1, 0, 1, -listTop),
		Position = UDim2.new(0, 0, 0, listTop),
	}, 4)

	local emptyLabel = W.label(list, "", {
		Size = UDim2.new(1, -12, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.textDim,
		LayoutOrder = 0,
	})

	local rows = {} -- [soldierName] = { frame, label }
	local refresh

	local function makeRow(name)
		local frame = W.new("Frame", { Size = UDim2.new(1, -12, 0, 40), BackgroundColor3 = C.panel2, BorderSizePixel = 0 }, list)
		W.corner(frame, 4)
		local label = W.label(frame, "", {
			Size = UDim2.new(1, -140, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		W.button(frame, "Kick", {
			Size = UDim2.fromOffset(55, 26),
			Position = UDim2.new(1, -128, 0.5, -13),
			BackgroundColor3 = C.panel,
			TextSize = 11,
		}, function()
			ctx.remote.fire("KickFromArmyGroup", name)
			task.delay(0.4, function() pcall(refresh) end)
		end)
		W.button(frame, "Delete", {
			Size = UDim2.fromOffset(60, 26),
			Position = UDim2.new(1, -68, 0.5, -13),
			BackgroundColor3 = C.danger,
			TextSize = 11,
		}, function()
			ctx.remote.fire("DeleteSoldiers", name)
			task.delay(0.6, function() pcall(refresh) end)
		end)
		return { frame = frame, label = label }
	end

	refresh = function()
		if not ctx.running then return end
		local group = world.findGroup(st.groupName)
		local soldiers = world.getGroupSoldiers(group)
		table.sort(soldiers, function(a, b) return a.Name < b.Name end)

		local seen, total = {}, 0
		for i, s in ipairs(soldiers) do
			seen[s.Name] = true
			local row = rows[s.Name] or makeRow(s.Name)
			rows[s.Name] = row
			row.frame.LayoutOrder = i
			local amount = math.floor(world.getAmount(s))
			total += amount
			row.label.Text = ("%s • %s • %s • AC:%s"):format(
				world.getType(s), W.fmtNumber(amount), world.getSoldierTile(s) or "?",
				s:GetAttribute("AutoCapture") and "ON" or "OFF")
		end
		for name, row in pairs(rows) do
			if not seen[name] then
				row.frame:Destroy()
				rows[name] = nil
			end
		end

		emptyLabel.Visible = #soldiers == 0
		emptyLabel.Text = group and ("Belum ada army di grup '%s'"):format(st.groupName)
			or ("Grup '%s' belum dibuat (akan dibuat saat Spawn)"):format(st.groupName)
		header.Text = ("Group Armies: %d army • total %s"):format(#soldiers, W.fmtNumber(total))
	end

	-- ---------- Loops ----------
	ctx.every(T.statusRefresh, function()
		local country = world.getCountry()
		local money = world.getMoney()
		statusLabel.Text = ("Country: %s  |  Money: %s  |  Group: %s"):format(
			country or "?", money and W.fmtNumber(money) or "?", st.groupName)
	end, "ArmyStatus")
	ctx.every(T.armyListRefresh, refresh, "ArmyList")
end

return ArmyPage
