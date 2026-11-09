-- ============================================================
-- AutoDelete.lua — hapus army di grup yang jumlahnya ≤ batas.
-- Ada cooldown per-army agar tidak mengirim DeleteSoldiers berulang-ulang
-- sebelum server sempat menghapus (bug lama: spam log & remote).
-- ============================================================

local AutoDelete = {}

function AutoDelete.start(ctx)
	local world, T = ctx.world, ctx.Config.Timing
	local lastSent = {}

	ctx.every(T.autoDelete, function()
		local st = ctx.state
		if not st.autoDeleteEnabled or st.autoDeleteThreshold <= 0 then
			return
		end
		local group = world.findGroup(st.groupName)
		if not group then
			return
		end

		local now = os.clock()
		for _, s in ipairs(world.getGroupSoldiers(group)) do
			local amount = world.getAmount(s)
			if amount <= st.autoDeleteThreshold then
				if now - (lastSent[s.Name] or 0) >= T.deleteResendCooldown then
					lastSent[s.Name] = now
					ctx.remote.fire("DeleteSoldiers", s.Name)
					-- floor: string.format("%d") error jika angka punya pecahan
					ctx.log(("Auto-deleted %s (%d ≤ %d)"):format(s.Name, math.floor(amount), st.autoDeleteThreshold), "warn")
				end
			end
		end

		for name in pairs(lastSent) do
			if not world.soldiers:FindFirstChild(name) then
				lastSent[name] = nil
			end
		end
	end, "AutoDelete")
end

return AutoDelete
