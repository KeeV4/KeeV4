local UI = {}

UI.Name = "KeeV4 UI"
UI.Version = "0.1.0"

function UI:CreateWindow(options)
	options = options or {}

	print("Creating window:", options.Name or "Window")
end

return UI
