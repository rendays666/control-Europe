-- ============================================================
-- Janitor.lua — kumpulkan semua koneksi/instance/thread,
-- lalu bersihkan sekaligus saat GUI ditutup (anti memory leak).
-- ============================================================

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
	return setmetatable({ _items = {} }, Janitor)
end

-- Terima: RBXScriptConnection, Instance, function, atau thread
function Janitor:Add(item)
	table.insert(self._items, item)
	return item
end

function Janitor:Cleanup()
	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		local item = items[i]
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			pcall(item)
		elseif kind == "thread" then
			if item ~= coroutine.running() then
				pcall(task.cancel, item)
			end
		end
	end
end

return Janitor
