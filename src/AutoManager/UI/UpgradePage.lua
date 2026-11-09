-- ============================================================
-- UpgradePage.lua — tab "Auto Upgrade": target level, start/stop, daftar kota.
-- Logic upgrade ada di Services/AutoUpgrade.lua (halaman ini hanya tampilan).
-- ============================================================

local UpgradePage = {}

function UpgradePage.build(ctx, page)
	local C, W, st, world = ctx.Config.Colors, ctx.W, ctx.state, ctx.world
	local T = ctx.Config.Timing
	local upgrade = ctx.services.upgrade
	local stack = W.stack(page, 6)

	-- ---------- Status ----------
	local statusRow = stack:row(28, true)
	local statusLabel = W.label(statusRow, ctx.runtime.upgradeStatus, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
	})

	-- ---------- Target / Start / Stop ----------
	local refreshCities
	local function commitTarget(box)
		local n = tonumber(box.Text)
		if n and n >= 1 then
			st.autoUpgradeTarget = math.floor(n)
		end
		box.Text = tostring(st.autoUpgradeTarget)
		pcall(refreshCities)
	end

	local tRow = stack:hrow(32)
	W.label(tRow, "Target Level:", { Size = UDim2.new(0, 90, 1, 0), TextColor3 = C.textDim })
	local targetBox = W.input(tRow, { Size = UDim2.new(0, 60, 1, 0), Text = tostring(st.autoUpgradeTarget) }, commitTarget)
	W.button(tRow, "▶ START AUTO UPGRADE", {
		Size = UDim2.new(0, 190, 1, 0),
		BackgroundColor3 = C.success,
	}, function()
		commitTarget(targetBox) -- pastikan angka yang sedang diketik ikut terbaca
		upgrade.startRun()
	end)
	W.button(tRow, "■ STOP", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.danger }, function()
		upgrade.stopRun()
	end)

	-- ---------- Daftar kota ----------
	local header = W.label(page, "Kota milik negaramu:", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, stack.y),
		Font = Enum.Font.GothamBold,
	})
	local listTop = stack.y + 24
	local list = W.scroll(page, {
		Size = UDim2.new(1, 0, 1, -listTop),
		Position = UDim2.new(0, 0, 0, listTop),
	}, 3)

	local emptyLabel = W.label(list, "", {
		Size = UDim2.new(1, -12, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.textDim,
		LayoutOrder = 0,
	})

	local rows = {} -- [tileName] = { frame, name, level }

	local function makeRow()
		local frame = W.new("Frame", { Size = UDim2.new(1, -12, 0, 26), BackgroundColor3 = C.panel2, BorderSizePixel = 0 }, list)
		W.corner(frame, 4)
		local name = W.label(frame, "", {
			Size = UDim2.new(1, -110, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local level = W.label(frame, "", {
			Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.new(1, -108, 0, 0),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		return { frame = frame, name = name, level = level }
	end

	refreshCities = function()
		if not ctx.running then return end
		local tiles = world.getOwnedTiles()
		table.sort(tiles, function(a, b) return a.Name < b.Name end)

		local seen, doneCount = {}, 0
		for i, tile in ipairs(tiles) do
			seen[tile.Name] = true
			local row = rows[tile.Name] or makeRow()
			rows[tile.Name] = row
			local tier = world.getTier(tile)
			local done = tier >= st.autoUpgradeTarget
			if done then doneCount += 1 end
			row.frame.LayoutOrder = i
			row.name.Text = (done and "✓ " or "• ") .. tile.Name
			row.name.TextColor3 = done and C.success or C.text
			row.level.Text = ("Lv %d / %d"):format(tier, st.autoUpgradeTarget)
			row.level.TextColor3 = done and C.success or C.text
		end
		for name, row in pairs(rows) do
			if not seen[name] then
				row.frame:Destroy()
				rows[name] = nil
			end
		end

		emptyLabel.Visible = #tiles == 0
		emptyLabel.Text = "Tidak ada kota milik " .. tostring(world.getCountry() or "?")
		header.Text = ("Kota milik negaramu: %d total • %d selesai"):format(#tiles, doneCount)
	end

	ctx.every(T.statusRefresh, function()
		statusLabel.Text = ctx.runtime.upgradeStatus
	end, "UpgradeStatus")
	ctx.every(T.cityListRefresh, refreshCities, "CityList")
end

return UpgradePage
