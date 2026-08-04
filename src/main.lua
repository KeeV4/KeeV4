local import = ...

if type(import) ~= "function" then
	error("KeeV4 main.luau must be loaded through init.lua")
end

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
		Accent = Color3.fromRGB(5, 133, 104),
	},
}

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
	-- KeeV4
	-- └── Menu
	--     ├── PvP
	--     └── Bed Breaking

	local menuCategory = self:GetCategory("PvP")

	local pvpModule = self:CreateModule("PvP", {
		Name = "HitFix",

		Function = function(enabled)
			print("PvP module:", enabled)
		end,
	})


	-- Leave their option areas empty for now.
	-- Later:
	-- pvpModule:CreateButton(...)
	-- pvpModule:CreateToggle(...)
	-- pvpModule:CreateSlider(...)
	--
	-- bedBreakingModule:CreateButton(...)
	-- bedBreakingModule:CreateToggle(...)
	-- bedBreakingModule:CreateSlider(...)

	menuCategory:SetExpanded(true)

	-- Separate interface settings category.
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
		Keybind = settings.Keybind,
		Accent = settings.Accent,
	})

	self.Started = true

	self:CreateBaseplate()

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
