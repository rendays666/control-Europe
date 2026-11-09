-- ============================================================
-- AutoCapture.lua — aktifkan auto-capture untuk army di grup.
-- Hanya mengirim ke army yang atribut AutoCapture-nya belum aktif,
-- dengan cooldown per-army (tidak spam server tiap 3 detik).
-- ============================================================

local AutoCapture = {}

function AutoCapture.start(ctx)
	local world, T = ctx.world, ctx.Config.Timing
	local lastSent = {} -- [soldierName] = waktu terakhir kirim

	ctx.every(T.autoCapture, function()
		if not ctx.state.autoCapture then
			return
		end
		local group = world.findGroup(ctx.state.groupName)
		if not group then
			return
		end

		local now = os.clock()
		for _, s in ipairs(world.getGroupSoldiers(group)) do
			if not s:GetAttribute("AutoCapture") then
				if now - (lastSent[s.Name] or 0) >= T.captureResendCooldown then
					lastSent[s.Name] = now
					ctx.remote.fire("ToggleAutoCapture", s.Name, true, "Attack")
				end
			end
		end

		-- bersihkan catatan soldier yang sudah hilang
		for name in pairs(lastSent) do
			if not world.soldiers:FindFirstChild(name) then
				lastSent[name] = nil
			end
		end
	end, "AutoCapture")
end

return AutoCapture
