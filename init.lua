local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local KeeV4 = {
	Name = "KeeV4",
	Version = "0.1.0"
}

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = object
end

local function makeDraggable(window, handle)
	local dragging = false
	local dragStart
	local startPosition

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = window.Position
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Position - dragStart

		window.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

function KeeV4:CreateWindow(options)
	options = options or {}

	local parent

	if gethui then
		parent = gethui()
	else
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = options.GuiName or "KeeV4"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parent

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.fromOffset(240, 320)
	window.Position = UDim2.new(0.5, -120, 0.5, -160)
	window.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	window.BorderSizePixel = 0
	window.Parent = screenGui
	addCorner(window, 7)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 42)
	header.BackgroundTransparency = 1
	header.Text = options.Name or "KeeV4"
	header.TextColor3 = Color3.fromRGB(220, 220, 220)
	header.TextSize = 15
	header.Font = Enum.Font.Arial
	header.Parent = window

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 41)
	divider.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
	divider.BorderSizePixel = 0
	divider.Parent = window

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -42)
	content.Position = UDim2.fromOffset(0, 42)
	content.BackgroundTransparency = 1
	content.Parent = window

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	makeDraggable(window, header)

	local windowApi = {
		ScreenGui = screenGui,
		Window = window,
		Content = content
	}

	function windowApi:Destroy()
		screenGui:Destroy()
	end

	return windowApi
end

return KeeV4
