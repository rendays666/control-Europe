-- ============================================================
-- LogPanel.lua — panel log global di bagian bawah (terlihat di semua tab).
-- Bug lama: error dari tab Army tampil di log tab Upgrade (tidak terlihat).
-- ============================================================

local LogPanel = {}

function LogPanel.build(ctx, parent)
	local C, W = ctx.Config.Colors, ctx.W
	local levelColor = {
		info = C.textDim,
		ok = C.success,
		warn = C.warn,
		error = Color3.fromRGB(235, 90, 90),
	}

	local header = W.new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
	W.label(header, "Log", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Font = Enum.Font.GothamBold,
	})

	local list, layout = W.scroll(parent, {
		Size = UDim2.new(1, -16, 1, -28),
		Position = UDim2.new(0, 8, 0, 24),
	}, 2)

	local lines, order = {}, 0

	local function addLine(entry)
		order += 1
		local label = W.label(list, ("[%s] %s"):format(entry.time, entry.msg), {
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextSize = 11,
			TextColor3 = levelColor[entry.level] or C.textDim,
			LayoutOrder = order,
		})
		table.insert(lines, label)
		if #lines > ctx.Config.LogMaxLines then
			table.remove(lines, 1):Destroy()
		end
	end

	local function clearLines()
		for _, l in ipairs(lines) do
			l:Destroy()
		end
		lines = {}
	end

	W.button(header, "Clear", {
		Size = UDim2.fromOffset(56, 18),
		Position = UDim2.new(1, -66, 0, 2),
		TextSize = 10,
	}, function()
		clearLines()
		ctx.logger.clear()
	end)

	-- auto-scroll ke baris terbaru
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
	end)

	for _, entry in ipairs(ctx.logger.lines) do
		addLine(entry)
	end
	ctx.janitor:Add(ctx.logger.onLog(addLine))
end

return LogPanel
