local BASE_URL =
	"https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/"

local function import(path)
	local success, source = pcall(function()
		return game:HttpGet(BASE_URL .. path, true)
	end)

	if not success then
		error(
			"KeeV4 failed to download "
			.. path
			.. ": "
			.. tostring(source)
		)
	end

	local chunk, compileError = loadstring(source, path)

	if not chunk then
		error(
			"KeeV4 failed to compile "
			.. path
			.. ": "
			.. tostring(compileError)
		)
	end

	return chunk()
end

return import("src/gui.lua")
