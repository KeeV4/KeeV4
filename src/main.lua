local import = ...

if type(import) ~= "function" then
	error("KeeV4 main.luau must be loaded through init.lua")
end

-- Keep this as gui.lua if that is your current filename.
local GUI = import("src/gui.lua")

local App = {
	Name = "KeeV4",
	Version = "0.1.0",

	Started = false,
	Window = nil,

	Categories = {},
	Modules = {},

	Settings = {
		Title = "KeeV4",
		GuiName = "KeeV4",
		Keybind = "RightShift",

		Size = UDim2.fromOffset(620, 390),
		Accent = Color3.fromRGB(5, 133, 104),
	},
}

-- Keys available from the settings dropdown.
-- More can be added later.
local AVAILABLE_KEYBINDS = {
	"RightShift",
	"LeftShift",

	"RightControl",
	"LeftControl",

	"RightAlt",
	"LeftAlt",

	"Insert",
	"Home",
	"End",
	"Delete",

	"F1",
	"F2",
	"F3",
	"F4",
	"F5",
	"F6",
	"F7",
	"F8",
	"F9",
	"F10",
}

local function copyTable(original)
	local result = {}

	for key, value in pairs(original) do
		result[key] = value
	end

	return result
end

local function applyOverrides(settings, overrides)
	for key, value in pairs(overrides or {}) do
		settings[key] = value
	end

	return settings
end

function App:GetCategory(name)
	assert(
		self.Window,
		"KeeV4 must be started before creating categories"
	)

	if self.Categories[name] then
		return self.Categories[name]
	end

	local category = self.Window:CreateCategory({
		Name = name,
	})

	self.Categories[name] = category

	return category
end

function App:CreateModule(categoryName, settings)
	assert(
		type(categoryName) == "string",
		"CreateModule requires a category name"
	)

	settings = settings or {}

	local category = self:GetCategory(categoryName)
	local module = category:CreateModule(settings)

	local moduleName = settings.Name or "Module"

	self.Modules[moduleName] = module

	return module
end

function App:SetKeybind(keybind)
	assert(
		self.Window,
		"KeeV4 must be started before changing its keybind"
	)

	local resolvedKeybind = self.Window:SetKeybind(keybind)

	self.Settings.Keybind = resolvedKeybind.Name

	return resolvedKeybind
end

function App:GetKeybind()
	if not self.Window then
		return self.Settings.Keybind
	end

	return self.Window:GetKeybind()
end

function App:SetVisible(visible)
	if self.Window then
		self.Window:SetVisible(visible)
	end
end

function App:Toggle()
	if self.Window then
		self.Window:Toggle()
	end
end

function App:CreateBaseplate()
	-- This creates the button called "Menu" underneath KeeV4.
	local menuCategory = self:GetCategory("Menu")

	-- This creates "PvP" inside the Menu window.
	local pvpModule = self:CreateModule("Menu", {
		Name = "PvP",

		Function = function(enabled)
			print("PvP enabled:", enabled)
		end,
	})

	-- Make the Menu panel show its modules immediately when opened.
	menuCategory:SetExpanded(true)

	-- Settings remains a separate category opened by the gear icon.
	local settingsCategory = self:GetCategory("Settings")

	local interfaceModule = settingsCategory:CreateModule({
		Name = "Interface",
	})

	interfaceModule:CreateDropdown({
		Name = "Toggle key",

		List = AVAILABLE_KEYBINDS,
		Default = self.Settings.Keybind,

		Function = function(selectedKey)
			self:SetKeybind(selectedKey)

			print(
				"KeeV4 keybind changed to:",
				selectedKey
			)
		end,
	})

	interfaceModule:SetOptionsVisible(true)

	self.Modules.Interface = interfaceModule
end

function App:Start(overrides)
	if self.Started and self.Window then
		return self
	end

	local settings = copyTable(self.Settings)

	applyOverrides(settings, overrides)

	self.Settings = settings

	self.Window = GUI:CreateWindow({
		Title = settings.Title,
		GuiName = settings.GuiName,

		-- RightShift by default.
		Keybind = settings.Keybind,

		Size = settings.Size,
		Accent = settings.Accent,
	})

	self.Started = true

	self:CreateBaseplate()

	-- Add the functionality loader here later:
	--
	-- local Functionality = import("src/functionality.luau")
	-- Functionality:Mount(self)

	return self
end

function App:Destroy()
	if self.Window then
		self.Window:Destroy()
		self.Window = nil
	end

	table.clear(self.Categories)
	table.clear(self.Modules)

	self.Started = false
end

return App
