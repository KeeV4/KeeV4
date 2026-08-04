local BASE_URL =
	"https://github.com/KeeV4/KeeV4/tree/main"

local cache = {}
local currentlyLoading = {}

local function import(path)
	if cache[path] ~= nil then
		return cache[path]
	end

	if currentlyLoading[path] then
		error("Circular import detected: " .. path)
	end

	currentlyLoading[path] = true

	local downloadSuccess, source = pcall(function()
		return game:HttpGet(BASE_URL .. path, true)
	end)

	if not downloadSuccess then
		currentlyLoading[path] = nil

		error(
			"KeeV4 failed to download "
				.. path
				.. ": "
				.. tostring(source)
		)
	end

	local chunk, compileError = loadstring(
		source,
		"@" .. path
	)

	if not chunk then
		currentlyLoading[path] = nil

		error(
			"KeeV4 failed to compile "
				.. path
				.. ": "
				.. tostring(compileError)
		)
	end

	-- Passes the import function into every module through ...
	local executionSuccess, result = pcall(
		chunk,
		import
	)

	currentlyLoading[path] = nil

	if not executionSuccess then
		error(
			"KeeV4 failed to execute "
				.. path
				.. ": "
				.. tostring(result)
		)
	end

	if result == nil then
		error(path .. " did not return anything")
	end

	cache[path] = result

	return result
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
	repeat
		task.wait()
		player = Players.LocalPlayer
	until player
end

-- Information the whitelist system can inspect.
local whitelistContext = {
	Player = player,
	UserId = player.UserId,
	Username = player.Name,
	DisplayName = player.DisplayName,

	PlaceId = game.PlaceId,
	GameId = game.GameId,
	JobId = game.JobId,
}

-- Whitelist check occurs before main.lua is loaded.
local Whitelist = import("src/whitelist.lua")

local checkSuccess, allowed, denialReason = pcall(
	function()
		return Whitelist:Check(whitelistContext)
	end
)

if not checkSuccess then
	error(
		"KeeV4 whitelist check failed: "
			.. tostring(allowed)
	)
end

if not allowed then
	error(
		denialReason
			or "You are not authorised to use KeeV4."
	)
end

-- Only authorised users reach the main application.
local App = import("src/main.lua")

App.Whitelist = Whitelist
App.WhitelistContext = whitelistContext

return App
