-- ============================================================
-- Logger.lua — log terpusat. UI (LogPanel) cukup subscribe lewat onLog.
-- Level: "info" | "ok" | "warn" | "error"
-- ============================================================

local Logger = {}

function Logger.new(maxLines)
	local self = {
		lines = {},
		_listeners = {},
	}

	function self.log(msg, level)
		level = level or "info"
		local text = tostring(msg)
		if level == "error" or level == "warn" then
			warn("[AutoMgr] " .. text)
		else
			print("[AutoMgr] " .. text)
		end

		local entry = { time = os.date("%H:%M:%S"), msg = text, level = level }
		table.insert(self.lines, entry)
		if #self.lines > maxLines then
			table.remove(self.lines, 1)
		end
		for _, fn in ipairs(self._listeners) do
			pcall(fn, entry)
		end
	end

	-- Kembalikan fungsi unsubscribe
	function self.onLog(fn)
		table.insert(self._listeners, fn)
		return function()
			local idx = table.find(self._listeners, fn)
			if idx then
				table.remove(self._listeners, idx)
			end
		end
	end

	function self.clear()
		self.lines = {}
	end

	return self
end

return Logger
