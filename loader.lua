-- ============================================================
-- AUTO MANAGER — loader untuk executor (loadstring)
--
-- Jalankan:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/rendays666/control-Europe/main/loader.lua"))()
--
-- Mengunduh tiap modul dari GitHub, mengompilasinya dengan loadstring,
-- lalu menyerahkan ke Boot.lua (sama persis dengan jalur Studio).
--
-- Opsional (sebelum menjalankan loader):
--   getgenv().AutoManagerBase = "https://raw.githubusercontent.com/<user>/<repo>/<branch>/src/AutoManager/"
-- ============================================================

local DEFAULT_BASE = "https://raw.githubusercontent.com/rendays666/control-Europe/main/src/AutoManager/"
local BASE = (getgenv and getgenv().AutoManagerBase) or DEFAULT_BASE

local function httpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok or type(body) ~= "string" or body == "" then
		-- cadangan: fungsi request bawaan executor
		local req = (syn and syn.request) or (http and http.request) or http_request or request
		if req then
			local ok2, res = pcall(req, { Url = url, Method = "GET" })
			if ok2 and type(res) == "table" and res.StatusCode == 200 then
				body, ok = res.Body, true
			end
		end
	end
	if not ok or type(body) ~= "string" or body == "" or body == "404: Not Found" then
		error("gagal mengunduh: " .. url)
	end
	return body
end

local cache = {}

local function load(path)
	if cache[path] ~= nil then
		return cache[path]
	end
	local src = httpGet(BASE .. path .. ".lua")
	local fn, err = loadstring(src, "=" .. path)
	if not fn then
		error(("syntax error di %s: %s"):format(path, tostring(err)))
	end
	local value = fn()
	cache[path] = value
	return value
end

local ok, result = pcall(function()
	return load("Boot")(load)
end)
if not ok then
	warn("[AutoMgr] Loader gagal: " .. tostring(result))
end
return result
