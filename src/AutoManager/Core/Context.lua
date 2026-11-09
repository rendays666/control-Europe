-- ============================================================
-- Context.lua — objek `ctx` yang dibagikan ke SEMUA modul.
--
--   ctx.Config     konstanta (Core/Config.lua)
--   ctx.state      setting yang diubah user lewat GUI
--   ctx.runtime    info status (dibaca UI): money, country, upgradeStatus
--   ctx.log        log(msg, level)
--   ctx.logger     objek Logger (onLog, lines, clear)
--   ctx.janitor    kumpulan cleanup
--   ctx.running    false setelah GUI ditutup
--   ctx.every()    jalankan fungsi berulang dengan pcall (aman dari error)
--   ctx.destroy()  matikan semua loop & hapus GUI
--
-- Ditambahkan oleh init.client.lua setelah dibuat:
--   ctx.remote, ctx.world, ctx.W (widgets), ctx.services
-- ============================================================

local Context = {}

local function shallowCopy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

function Context.new(Config, Janitor, Logger)
	local ctx = {}
	ctx.Config = Config
	ctx.state = shallowCopy(Config.Defaults)
	ctx.runtime = {
		country = nil,
		money = nil,
		upgradeStatus = "Status: Idle",
	}
	ctx.logger = Logger.new(Config.LogMaxLines)
	ctx.log = ctx.logger.log
	ctx.janitor = Janitor.new()
	ctx.running = true
	ctx.services = {}

	-- Loop berulang. Error di dalam fn tidak mematikan loop, hanya dilog.
	function ctx.every(interval, fn, name)
		local label = name or "loop"
		local thread = task.spawn(function()
			while ctx.running do
				local ok, err = pcall(fn)
				if not ok then
					ctx.log(("[%s] error: %s"):format(label, tostring(err)), "error")
					task.wait(3) -- redam spam error
				end
				task.wait(interval)
			end
		end)
		ctx.janitor:Add(thread)
		return thread
	end

	function ctx.destroy()
		if not ctx.running then
			return
		end
		ctx.running = false
		ctx.janitor:Cleanup()
	end

	return ctx
end

return Context
