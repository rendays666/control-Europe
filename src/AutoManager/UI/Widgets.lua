-- ============================================================
-- Widgets.lua — helper pembuat elemen UI (tombol, input, label, scroll, dll).
-- Pemakaian: local W = Widgets.create(Config.Colors)
-- ============================================================

local Widgets = {}

local function merge(base, extra)
	for k, v in pairs(extra or {}) do
		base[k] = v
	end
	return base
end

function Widgets.create(C)
	local W = {}

	-- Buat Instance + set properti + parent.
	-- Jika parent punya UIListLayout/UIGridLayout dan LayoutOrder tidak diisi,
	-- LayoutOrder otomatis = urutan pembuatan.
	function W.new(className, props, parent)
		local inst = Instance.new(className)
		for k, v in pairs(props or {}) do
			inst[k] = v
		end
		if parent then
			local hasOrder = props ~= nil and props.LayoutOrder ~= nil
			if not hasOrder and inst:IsA("GuiObject") then
				if parent:FindFirstChildOfClass("UIListLayout") or parent:FindFirstChildOfClass("UIGridLayout") then
					inst.LayoutOrder = #parent:GetChildren()
				end
			end
			inst.Parent = parent
		end
		return inst
	end

	function W.corner(inst, radius)
		return W.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, inst)
	end

	function W.stroke(inst, color, thickness)
		return W.new("UIStroke", { Color = color, Thickness = thickness or 1 }, inst)
	end

	function W.pad(inst, p)
		return W.new("UIPadding", {
			PaddingTop = UDim.new(0, p),
			PaddingBottom = UDim.new(0, p),
			PaddingLeft = UDim.new(0, p),
			PaddingRight = UDim.new(0, p),
		}, inst)
	end

	function W.label(parent, text, props)
		return W.new("TextLabel", merge({
			Text = text,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, props), parent)
	end

	function W.button(parent, text, props, onClick)
		local btn = W.new("TextButton", merge({
			Text = text,
			BackgroundColor3 = C.panel2,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = C.text,
			BorderSizePixel = 0,
		}, props), parent)
		W.corner(btn, 4)
		if onClick then
			btn.MouseButton1Click:Connect(function()
				onClick(btn)
			end)
		end
		return btn
	end

	-- onCommit(box) dipanggil saat fokus hilang (Enter / klik di luar)
	function W.input(parent, props, onCommit)
		local box = W.new("TextBox", merge({
			BackgroundColor3 = C.panel2,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.text,
			PlaceholderColor3 = C.textDim,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, props), parent)
		W.corner(box, 4)
		if onCommit then
			box.FocusLost:Connect(function()
				onCommit(box)
			end)
		end
		return box
	end

	-- Tombol ON/OFF. Return (button, setValue)
	function W.toggle(parent, name, initial, props, onChange)
		local value = initial
		local btn
		local function render()
			btn.Text = name .. ": " .. (value and "ON" or "OFF")
			btn.BackgroundColor3 = value and C.success or C.panel2
		end
		btn = W.button(parent, "", props, function()
			value = not value
			render()
			if onChange then
				onChange(value)
			end
		end)
		render()
		return btn, function(v)
			value = v
			render()
		end
	end

	-- ScrollingFrame vertikal dengan list otomatis. Return (frame, layout)
	function W.scroll(parent, props, gap)
		local sf = W.new("ScrollingFrame", merge({
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = C.accent,
		}, props), parent)
		W.corner(sf, 6)
		W.pad(sf, 6)
		local layout = W.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap or 4),
		}, sf)
		return sf, layout
	end

	-- Susun baris dari atas ke bawah dengan posisi manual.
	-- stack.y = posisi Y berikutnya (berguna untuk elemen "sisa ruang").
	function W.stack(parent, gap)
		local s = { y = 0, gap = gap or 6 }

		function s:row(height, filled)
			local f = W.new("Frame", {
				Size = UDim2.new(1, 0, 0, height),
				Position = UDim2.new(0, 0, 0, self.y),
				BackgroundTransparency = filled and 0 or 1,
				BackgroundColor3 = C.panel,
				BorderSizePixel = 0,
			}, parent)
			if filled then
				W.corner(f, 6)
			end
			self.y += height + self.gap
			return f
		end

		-- baris horizontal: anak-anaknya tersusun kiri → kanan otomatis
		function s:hrow(height)
			local f = self:row(height)
			W.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}, f)
			return f
		end

		return s
	end

	-- 1234567 → "1,234,567"
	function W.fmtNumber(n)
		local sign, digits = tostring(math.floor(n)):match("^(-?)(%d+)$")
		if not digits then
			return tostring(n)
		end
		digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
		digits = digits:gsub("^,", "")
		return sign .. digits
	end

	return W
end

return Widgets
