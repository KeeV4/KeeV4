local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local KeeV4 = {}

local Theme = {
	Main = Color3.fromRGB(26, 25, 26),
	Text = Color3.fromRGB(200, 200, 200),
	Accent = Color3.fromRGB(5, 133, 104),

	Font = Enum.Font.Arial,
	TweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Linear),
}

local Assets = {
	Blur = "rbxassetid://14898786664",
	Close = "rbxassetid://14368309446",
	Bind = "rbxassetid://14368304734",
	Edit = "rbxassetid://14368315443",
	Dots = "rbxassetid://14368314459",
	ExpandRight = "rbxassetid://14368316544",
	ExpandUp = "rbxassetid://14368317595",
	Settings = "rbxassetid://14368318994",
	Utility = "rbxassetid://14368359107",
}

local CategoryIcons = {
	Main = Assets.Utility,
	Settings = Assets.Settings,
}

local activeTweens = {}

local function create(className, properties)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		if property ~= "Parent" then
			object[property] = value
		end
	end

	if properties and properties.Parent then
		object.Parent = properties.Parent
	end

	return object
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = radius or UDim.new(0, 5),
		Parent = parent,
	})
end

local function addBlur(parent)
	local blur = create("ImageLabel", {
		Name = "Blur",
		Size = UDim2.new(1, 89, 1, 52),
		Position = UDim2.fromOffset(-48, -31),
		BackgroundTransparency = 1,
		Image = Assets.Blur,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(52, 31, 261, 502),
		Parent = parent,
	})

	return blur
end

local function shiftValue(colour, amount)
	local hue, saturation, value = colour:ToHSV()
	return Color3.fromHSV(
		hue,
		saturation,
		math.clamp(value + amount, 0, 1)
	)
end

local function light(colour, amount)
	return shiftValue(colour, amount)
end

local function dark(colour, amount)
	return shiftValue(colour, -amount)
end

local function tween(object, properties)
	if activeTweens[object] then
		activeTweens[object]:Cancel()
		activeTweens[object] = nil
	end

	if not object.Parent then
		return nil
	end

	local animation = TweenService:Create(
		object,
		Theme.TweenInfo,
		properties
	)

	activeTweens[object] = animation

	animation.Completed:Once(function()
		if activeTweens[object] == animation then
			activeTweens[object] = nil
		end
	end)

	animation:Play()
	return animation
end

local function resolveKeyCode(value)
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
		return value
	end

	if type(value) == "string" then
		return Enum.KeyCode[value] or Enum.KeyCode.RightShift
	end

	return Enum.KeyCode.RightShift
end

local function getTextWidth(text, size, font)
	return TextService:GetTextSize(
		tostring(text),
		size,
		font,
		Vector2.new(10000, 10000)
	).X
end

local function textColourForAccent(accent)
	local hue, saturation, value = accent:ToHSV()

	if value >= 0.7 and (saturation < 0.6 or (hue > 0.04 and hue < 0.56)) then
		return Color3.fromRGB(48, 48, 48)
	end

	return Color3.new(1, 1, 1)
end

local function makeDraggable(window, handle, registerConnection)
	local dragging = false
	local dragStart
	local startPosition
	local activeInput

	registerConnection(handle.InputBegan:Connect(function(input)
		local validInput =
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch

		if not validInput then
			return
		end

		if input.Position.Y - handle.AbsolutePosition.Y >= 40 then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = window.Position
		activeInput = input
	end))

	registerConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPosition then
			return
		end

		local validInput =
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch

		if not validInput then
			return
		end

		local delta = input.Position - dragStart

		window.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end))

	registerConnection(UserInputService.InputEnded:Connect(function(input)
		if input == activeInput
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
			dragStart = nil
			startPosition = nil
			activeInput = nil
		end
	end))
end

local function insertOption(moduleApi, name, optionApi)
	moduleApi.Options[name] = optionApi
	table.insert(moduleApi.OptionOrder, optionApi)
end

function KeeV4:CreateWindow(options)
	options = options or {}

	if options.Accent then
		Theme.Accent = options.Accent
	end

	local player = Players.LocalPlayer
	while not player do
		task.wait()
		player = Players.LocalPlayer
	end

	local parent
	local getHiddenUi = gethui

	if type(getHiddenUi) == "function" then
		local success, hiddenUi = pcall(getHiddenUi)
		if success then
			parent = hiddenUi
		end
	end

	parent = parent or player:WaitForChild("PlayerGui")

	local existing = parent:FindFirstChild(options.GuiName or "KeeV4")
	if existing then
		existing:Destroy()
	end

	local connections = {}

	local function registerConnection(connection)
		table.insert(connections, connection)
		return connection
	end

	local screenGui = create("ScreenGui", {
		Name = options.GuiName or "KeeV4",
		DisplayOrder = 999,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	local clickGui = create("Frame", {
		Name = "ClickGui",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})

	local windowApi = {
		Gui = screenGui,
		Object = clickGui,
		Categories = {},
		CategoryOrder = {},
		Modules = {},
		Visible = true,
		Keybind = resolveKeyCode(options.Keybind or options.ToggleKey),
		BindingTarget = nil,
		Destroyed = false,
	}

	local mainWindow = create("TextButton", {
		Name = "GUICategory",
		Size = UDim2.fromOffset(220, 41),
		Position = UDim2.fromOffset(6, 60),
		BackgroundColor3 = dark(Theme.Main, 0.02),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = clickGui,
	})

	addBlur(mainWindow)
	addCorner(mainWindow)
	makeDraggable(mainWindow, mainWindow, registerConnection)

	local logo = create("TextLabel", {
		Name = "KeeLogo",
		Size = UDim2.fromOffset(70, 22),
		Position = UDim2.fromOffset(11, 8),
		BackgroundTransparency = 1,
		Text = options.Title or "KeeV4",
		TextColor3 = select(3, Theme.Main:ToHSV()) > 0.5
			and Theme.Text
			or Color3.new(1, 1, 1),
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.ArialBold,
		Parent = mainWindow,
	})

	local logoAccent = create("Frame", {
		Name = "Accent",
		Size = UDim2.fromOffset(3, 17),
		Position = UDim2.fromOffset(7, 10),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = mainWindow,
	})
	addCorner(logoAccent, UDim.new(1, 0))

	local settingsButton = create("TextButton", {
		Name = "Settings",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -40, 0, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = mainWindow,
	})

	local settingsIcon = create("ImageLabel", {
		Name = "Icon",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(15, 12),
		BackgroundTransparency = 1,
		Image = Assets.Settings,
		ImageColor3 = light(Theme.Main, 0.37),
		Parent = settingsButton,
	})

	local mainChildren = create("Frame", {
		Name = "Children",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 37),
		BackgroundTransparency = 1,
		Parent = mainWindow,
	})

	local mainLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = mainChildren,
	})

	local function updateMainWindowSize()
		local contentHeight = mainLayout.AbsoluteContentSize.Y
		mainChildren.Size = UDim2.new(1, 0, 0, contentHeight)
		mainWindow.Size = UDim2.fromOffset(220, 42 + contentHeight)
	end

	registerConnection(mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
		updateMainWindowSize
	))

	function windowApi:SetVisible(value)
		self.Visible = value == true
		screenGui.Enabled = self.Visible
	end

	function windowApi:Toggle()
		self:SetVisible(not self.Visible)
	end

	function windowApi:SetKeybind(keybind)
		self.Keybind = resolveKeyCode(keybind)
		return self.Keybind
	end

	function windowApi:GetKeybind()
		return self.Keybind
	end

	function windowApi:Destroy()
		if self.Destroyed then
			return
		end

		self.Destroyed = true

		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		table.clear(connections)
		table.clear(activeTweens)

		if screenGui.Parent then
			screenGui:Destroy()
		end
	end

	local function toggleCategory(category, forcedValue)
		local visible = forcedValue
		if visible == nil then
			visible = not category.Visible
		end

		category.Visible = visible == true
		category.Object.Visible = category.Visible

		tween(category.LaunchArrow, {
			Position = UDim2.new(
				1,
				category.Visible and -14 or -20,
				0,
				16
			),
		})

		category.LaunchButton.TextColor3 = category.Visible
			and Theme.Accent
			or dark(Theme.Text, 0.16)
		category.LaunchButton.BackgroundColor3 = category.Visible
			and light(Theme.Main, 0.02)
			or Theme.Main

		if category.LaunchIcon then
			category.LaunchIcon.ImageColor3 = category.LaunchButton.TextColor3
		end
	end

	function windowApi:CreateCategory(settings)
		settings = settings or {}

		local name = settings.Name or "Category"
		if self.Categories[name] then
			return self.Categories[name]
		end

		local categoryIndex = #self.CategoryOrder + 1
		local panelX = 236 + ((categoryIndex - 1) * 230)
		local iconAsset = settings.Icon or CategoryIcons[name] or Assets.Utility
		local iconSize = settings.Size or UDim2.fromOffset(16, 16)

		local category = {
			Name = name,
			Modules = {},
			Expanded = false,
			Visible = false,
			Index = categoryIndex,
		}

		local categoryWindow = create("TextButton", {
			Name = name .. "Category",
			Size = UDim2.fromOffset(220, 41),
			Position = UDim2.fromOffset(panelX, 60),
			BackgroundColor3 = Theme.Main,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Visible = false,
			Text = "",
			Parent = clickGui,
		})

		addBlur(categoryWindow)
		addCorner(categoryWindow)
		makeDraggable(categoryWindow, categoryWindow, registerConnection)

		local icon = create("ImageLabel", {
			Name = "Icon",
			Size = iconSize,
			Position = UDim2.fromOffset(12, iconSize.X.Offset > 20 and 14 or 13),
			BackgroundTransparency = 1,
			Image = iconAsset,
			ImageColor3 = Theme.Text,
			Parent = categoryWindow,
		})

		local titleOffset = iconSize.X.Offset > 18 and 40 or 33
		local title = create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -titleOffset, 0, 41),
			Position = UDim2.fromOffset(titleOffset, 0),
			BackgroundTransparency = 1,
			Text = name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Text,
			TextSize = 13,
			Font = Theme.Font,
			Parent = categoryWindow,
		})

		local arrowButton = create("TextButton", {
			Name = "Arrow",
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(1, -40, 0, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = categoryWindow,
		})

		local arrow = create("ImageLabel", {
			Name = "Arrow",
			Size = UDim2.fromOffset(9, 4),
			Position = UDim2.fromOffset(20, 18),
			BackgroundTransparency = 1,
			Image = Assets.ExpandUp,
			ImageColor3 = Color3.fromRGB(140, 140, 140),
			Rotation = 180,
			Parent = arrowButton,
		})

		local children = create("ScrollingFrame", {
			Name = "Children",
			Size = UDim2.new(1, 0, 1, -41),
			Position = UDim2.fromOffset(0, 37),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ScrollBarThickness = 2,
			ScrollBarImageTransparency = 0.75,
			ScrollBarImageColor3 = Theme.Text,
			CanvasSize = UDim2.new(),
			Parent = categoryWindow,
		})

		local divider = create("Frame", {
			Name = "Divider",
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromOffset(0, 37),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.928,
			BorderSizePixel = 0,
			Visible = false,
			Parent = categoryWindow,
		})

		local categoryLayout = create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = children,
		})

		local launchButton = create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(220, 40),
			LayoutOrder = categoryIndex,
			BackgroundColor3 = Theme.Main,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "             " .. name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = dark(Theme.Text, 0.16),
			TextSize = 14,
			Font = Theme.Font,
			Parent = mainChildren,
		})

		local launchIcon = create("ImageLabel", {
			Name = "Icon",
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(13, 12),
			BackgroundTransparency = 1,
			Image = iconAsset,
			ImageColor3 = dark(Theme.Text, 0.16),
			Parent = launchButton,
		})

		local launchArrow = create("ImageLabel", {
			Name = "Arrow",
			Size = UDim2.fromOffset(4, 8),
			Position = UDim2.new(1, -20, 0, 16),
			BackgroundTransparency = 1,
			Image = Assets.ExpandRight,
			ImageColor3 = light(Theme.Main, 0.37),
			Parent = launchButton,
		})

		category.Object = categoryWindow
		category.Icon = icon
		category.Title = title
		category.Children = children
		category.Divider = divider
		category.Layout = categoryLayout
		category.Arrow = arrow
		category.LaunchButton = launchButton
		category.LaunchArrow = launchArrow
		category.LaunchIcon = launchIcon

		local function updateCategorySize()
			local contentHeight = categoryLayout.AbsoluteContentSize.Y
			children.CanvasSize = UDim2.fromOffset(0, contentHeight)

			if category.Expanded then
				categoryWindow.Size = UDim2.fromOffset(
					220,
					math.min(41 + contentHeight, 601)
				)
			end
		end

		function category:SetVisible(value)
			toggleCategory(self, value)
		end

		function category:ToggleVisible()
			toggleCategory(self)
		end

		function category:SetExpanded(value)
			value = value == true
			self.Expanded = value
			children.Visible = value
			arrow.Rotation = value and 0 or 180

			local contentHeight = categoryLayout.AbsoluteContentSize.Y
			categoryWindow.Size = UDim2.fromOffset(
				220,
				value and math.min(41 + contentHeight, 601) or 41
			)

			divider.Visible = value and children.CanvasPosition.Y > 10
		end

		function category:Expand()
			self:SetExpanded(not self.Expanded)
		end

		function category:CreateModule(moduleSettings)
			moduleSettings = moduleSettings or {}

			local moduleName = moduleSettings.Name or "Module"
			if self.Modules[moduleName] then
				return self.Modules[moduleName]
			end

			local moduleIndex = 0
			for _ in pairs(self.Modules) do
				moduleIndex += 1
			end
			moduleIndex += 1

			local module = {
				Name = moduleName,
				Enabled = false,
				Options = {},
				OptionOrder = {},
				Bind = {},
				OptionsVisible = false,
				Index = moduleIndex,
			}

			local hovered = false

			local moduleButton = create("TextButton", {
				Name = moduleName,
				Size = UDim2.fromOffset(220, 40),
				LayoutOrder = moduleIndex * 2 - 1,
				BackgroundColor3 = Theme.Main,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "            " .. moduleName,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = dark(Theme.Text, 0.16),
				TextSize = 14,
				Font = Theme.Font,
				Parent = children,
			})

			local gradient = create("UIGradient", {
				Name = "Gradient",
				Rotation = 0,
				Enabled = false,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.Accent),
					ColorSequenceKeypoint.new(1, light(Theme.Accent, 0.06)),
				}),
				Parent = moduleButton,
			})

			local bindButton = create("TextButton", {
				Name = "Bind",
				Size = UDim2.fromOffset(20, 21),
				Position = UDim2.new(1, -36, 0, 9),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.92,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Visible = false,
				Text = "",
				Parent = moduleButton,
			})
			addCorner(bindButton, UDim.new(0, 4))

			local bindIcon = create("ImageLabel", {
				Name = "Icon",
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new(0.5, -6, 0, 5),
				BackgroundTransparency = 1,
				Image = Assets.Bind,
				ImageColor3 = dark(Theme.Text, 0.43),
				Parent = bindButton,
			})

			local bindText = create("TextLabel", {
				Name = "TextLabel",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, 1),
				BackgroundTransparency = 1,
				Visible = false,
				Text = "",
				TextColor3 = dark(Theme.Text, 0.43),
				TextSize = 12,
				Font = Theme.Font,
				Parent = bindButton,
			})

			local bindCover = create("Frame", {
				Name = "BindCover",
				Size = UDim2.fromOffset(154, 40),
				BackgroundColor3 = dark(Theme.Main, 0.02),
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 4,
				Parent = moduleButton,
			})
			addCorner(bindCover)

			local bindCoverText = create("TextLabel", {
				Name = "Text",
				Size = UDim2.new(1, -10, 1, -3),
				Position = UDim2.fromOffset(5, 1),
				BackgroundTransparency = 1,
				Text = "PRESS A KEY TO BIND",
				TextColor3 = Theme.Text,
				TextSize = 11,
				Font = Theme.Font,
				ZIndex = 5,
				Parent = bindCover,
			})

			local dotsButton = create("TextButton", {
				Name = "Dots",
				Size = UDim2.fromOffset(25, 40),
				Position = UDim2.new(1, -25, 0, 0),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = moduleButton,
			})

			local dots = create("ImageLabel", {
				Name = "Dots",
				Size = UDim2.fromOffset(3, 16),
				Position = UDim2.fromOffset(4, 12),
				BackgroundTransparency = 1,
				Image = Assets.Dots,
				ImageColor3 = light(Theme.Main, 0.37),
				Parent = dotsButton,
			})

			local moduleChildren = create("Frame", {
				Name = moduleName .. "Children",
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = moduleIndex * 2,
				BackgroundColor3 = dark(Theme.Main, 0.02),
				BorderSizePixel = 0,
				Visible = false,
				ClipsDescendants = true,
				Parent = children,
			})

			local optionLayout = create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Parent = moduleChildren,
			})

			local moduleDivider = create("Frame", {
				Name = "Divider",
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Color3.fromRGB(48, 48, 48),
				BackgroundTransparency = 0.52,
				BorderSizePixel = 0,
				Visible = false,
				Parent = moduleButton,
			})

			module.Object = moduleButton
			module.Children = moduleChildren
			module.Dots = dots
			module.BindButton = bindButton
			module.BindCover = bindCover

			local function updateOptionsHeight()
				local height = optionLayout.AbsoluteContentSize.Y
				moduleChildren.Size = UDim2.new(1, 0, 0, height)
				updateCategorySize()
			end

			function module:SetEnabled(value)
				value = value == true

				if self.Enabled == value then
					return
				end

				self.Enabled = value
				gradient.Enabled = value
				moduleDivider.Visible = value

				if value then
					moduleButton.BackgroundColor3 = Color3.new(1, 1, 1)
					moduleButton.TextColor3 = textColourForAccent(Theme.Accent)
					dots.ImageColor3 = moduleButton.TextColor3
					bindIcon.ImageColor3 = moduleButton.TextColor3
					bindText.TextColor3 = moduleButton.TextColor3
				else
					moduleButton.BackgroundColor3 =
						(hovered or self.OptionsVisible)
						and light(Theme.Main, 0.02)
						or Theme.Main
					moduleButton.TextColor3 =
						(hovered or self.OptionsVisible)
						and Theme.Text
						or dark(Theme.Text, 0.16)
					dots.ImageColor3 = light(Theme.Main, 0.37)
					bindIcon.ImageColor3 = dark(Theme.Text, 0.43)
					bindText.TextColor3 = dark(Theme.Text, 0.43)
				end

				if moduleSettings.Function then
					task.spawn(moduleSettings.Function, value)
				end
			end

			function module:Toggle()
				self:SetEnabled(not self.Enabled)
			end

			function module:SetOptionsVisible(value)
				self.OptionsVisible = value == true
				moduleChildren.Visible = self.OptionsVisible

				if self.OptionsVisible then
					updateOptionsHeight()
				end

				if not self.Enabled then
					moduleButton.BackgroundColor3 = self.OptionsVisible
						and light(Theme.Main, 0.02)
						or (hovered and light(Theme.Main, 0.02) or Theme.Main)
					moduleButton.TextColor3 = self.OptionsVisible
						and Theme.Text
						or (hovered and Theme.Text or dark(Theme.Text, 0.16))
				end

				bindButton.Visible = #self.Bind > 0
					or hovered
					or self.OptionsVisible
			end

			function module:ToggleOptions()
				self:SetOptionsVisible(not self.OptionsVisible)
			end

			function module:SetBind(keys)
				local resolved = {}

				if typeof(keys) == "EnumItem" then
					table.insert(resolved, keys)
				elseif type(keys) == "string" then
					table.insert(resolved, resolveKeyCode(keys))
				elseif type(keys) == "table" then
					for _, key in ipairs(keys) do
						table.insert(resolved, resolveKeyCode(key))
					end
				end

				self.Bind = resolved

				if #resolved == 0 then
					bindText.Visible = false
					bindIcon.Visible = true
					bindButton.Size = UDim2.fromOffset(20, 21)
					return
				end

				local names = {}
				for _, key in ipairs(resolved) do
					table.insert(names, key.Name:upper())
				end

				bindText.Text = table.concat(names, " + ")
				bindText.Visible = true
				bindIcon.Visible = false
				bindButton.Size = UDim2.fromOffset(
					math.max(getTextWidth(bindText.Text, 12, Theme.Font) + 10, 20),
					21
				)
			end

			function module:CreateToggle(toggleSettings)
				toggleSettings = toggleSettings or {}
				local optionName = toggleSettings.Name or "Toggle"
				local option = {
					Type = "Toggle",
					Enabled = false,
				}

				local optionHovered = false

				local row = create("TextButton", {
					Name = optionName .. "Toggle",
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = dark(
						moduleChildren.BackgroundColor3,
						toggleSettings.Darker and 0.02 or 0
					),
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Visible = toggleSettings.Visible == nil
						or toggleSettings.Visible,
					Text = "          " .. optionName,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = dark(Theme.Text, 0.16),
					TextSize = 14,
					Font = Theme.Font,
					Parent = moduleChildren,
				})

				local track = create("Frame", {
					Name = "Knob",
					Size = UDim2.fromOffset(22, 12),
					Position = UDim2.new(1, -30, 0, 9),
					BackgroundColor3 = light(Theme.Main, 0.14),
					BorderSizePixel = 0,
					Parent = row,
				})
				addCorner(track, UDim.new(1, 0))

				local knob = create("Frame", {
					Name = "Knob",
					Size = UDim2.fromOffset(8, 8),
					Position = UDim2.fromOffset(2, 2),
					BackgroundColor3 = Theme.Main,
					BorderSizePixel = 0,
					Parent = track,
				})
				addCorner(knob, UDim.new(1, 0))

				function option:SetEnabled(value)
					value = value == true
					if self.Enabled == value then
						return
					end

					self.Enabled = value

					tween(track, {
						BackgroundColor3 = value
							and Theme.Accent
							or (optionHovered
								and light(Theme.Main, 0.37)
								or light(Theme.Main, 0.14)),
					})

					tween(knob, {
						Position = UDim2.fromOffset(value and 12 or 2, 2),
					})

					if toggleSettings.Function then
						toggleSettings.Function(value)
					end
				end

				function option:Toggle()
					self:SetEnabled(not self.Enabled)
				end

				registerConnection(row.MouseEnter:Connect(function()
					optionHovered = true
					if not option.Enabled then
						tween(track, {
							BackgroundColor3 = light(Theme.Main, 0.37),
						})
					end
				end))

				registerConnection(row.MouseLeave:Connect(function()
					optionHovered = false
					if not option.Enabled then
						tween(track, {
							BackgroundColor3 = light(Theme.Main, 0.14),
						})
					end
				end))

				registerConnection(row.MouseButton1Click:Connect(function()
					option:Toggle()
				end))

				insertOption(module, optionName, option)
				updateOptionsHeight()

				if toggleSettings.Default then
					option:SetEnabled(true)
				end

				return option
			end

			function module:CreateSlider(sliderSettings)
				sliderSettings = sliderSettings or {}

				local optionName = sliderSettings.Name or "Slider"
				local minimum = tonumber(sliderSettings.Min) or 0
				local maximum = tonumber(sliderSettings.Max) or 100
				local decimal = tonumber(sliderSettings.Decimal) or 1
				local startingValue = tonumber(sliderSettings.Default) or minimum

				if maximum <= minimum then
					maximum = minimum + 1
				end

				local option = {
					Type = "Slider",
					Value = math.clamp(startingValue, minimum, maximum),
					Min = minimum,
					Max = maximum,
				}

				local row = create("TextButton", {
					Name = optionName .. "Slider",
					Size = UDim2.new(1, 0, 0, 50),
					BackgroundColor3 = dark(
						moduleChildren.BackgroundColor3,
						sliderSettings.Darker and 0.02 or 0
					),
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Visible = sliderSettings.Visible == nil
						or sliderSettings.Visible,
					Text = "",
					Parent = moduleChildren,
				})

				local label = create("TextLabel", {
					Name = "Title",
					Size = UDim2.fromOffset(120, 30),
					Position = UDim2.fromOffset(10, 2),
					BackgroundTransparency = 1,
					Text = optionName,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = dark(Theme.Text, 0.16),
					TextSize = 11,
					Font = Theme.Font,
					Parent = row,
				})

				local valueButton = create("TextButton", {
					Name = "Value",
					Size = UDim2.fromOffset(60, 15),
					Position = UDim2.new(1, -69, 0, 9),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = dark(Theme.Text, 0.16),
					TextSize = 11,
					Font = Theme.Font,
					Parent = row,
				})

				local valueBox = create("TextBox", {
					Name = "Box",
					Size = valueButton.Size,
					Position = valueButton.Position,
					BackgroundTransparency = 1,
					Visible = false,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = dark(Theme.Text, 0.16),
					TextSize = 11,
					Font = Theme.Font,
					ClearTextOnFocus = false,
					Parent = row,
				})

				local bar = create("Frame", {
					Name = "Slider",
					Size = UDim2.new(1, -20, 0, 2),
					Position = UDim2.fromOffset(10, 37),
					BackgroundColor3 = light(Theme.Main, 0.034),
					BorderSizePixel = 0,
					Parent = row,
				})

				local fill = create("Frame", {
					Name = "Fill",
					Size = UDim2.fromScale(0.04, 1),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = bar,
				})

				local knobHolder = create("Frame", {
					Name = "KnobHolder",
					Size = UDim2.fromOffset(24, 4),
					Position = UDim2.fromScale(1, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = row.BackgroundColor3,
					BorderSizePixel = 0,
					Parent = fill,
				})

				local knob = create("Frame", {
					Name = "Knob",
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = knobHolder,
				})
				addCorner(knob, UDim.new(1, 0))

				local suffix = sliderSettings.Suffix
				local function valueText(value)
					local suffixValue = ""
					if suffix then
						suffixValue = type(suffix) == "function"
							and tostring(suffix(value))
							or tostring(suffix)
					end

					return tostring(value)
						.. (suffixValue ~= "" and " " .. suffixValue or "")
				end

				function option:SetValue(newValue, final)
					newValue = tonumber(newValue)
					if not newValue or newValue ~= newValue then
						return
					end

					newValue = math.clamp(newValue, minimum, maximum)
					newValue = math.floor(newValue * decimal + 0.5) / decimal

					local changed = self.Value ~= newValue
					self.Value = newValue
					valueButton.Text = valueText(newValue)

					local percentage = (newValue - minimum) / (maximum - minimum)
					tween(fill, {
						Size = UDim2.fromScale(math.clamp(percentage, 0.04, 0.96), 1),
					})

					if (changed or final) and sliderSettings.Function then
						sliderSettings.Function(newValue, final == true)
					end
				end

				local function updateFromInput(input, final)
					local percentage = math.clamp(
						(input.Position.X - bar.AbsolutePosition.X)
							/ bar.AbsoluteSize.X,
						0,
						1
					)

					option:SetValue(
						minimum + (maximum - minimum) * percentage,
						final
					)
				end

				registerConnection(row.InputBegan:Connect(function(input)
					local validInput =
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch

					if not validInput then
						return
					end

					if input.Position.Y - row.AbsolutePosition.Y <= 20 then
						return
					end

					updateFromInput(input, false)

					local changedConnection
					local endedConnection

					changedConnection = UserInputService.InputChanged:Connect(function(changedInput)
						if changedInput.UserInputType == Enum.UserInputType.MouseMovement
							or changedInput.UserInputType == Enum.UserInputType.Touch
						then
							updateFromInput(changedInput, false)
						end
					end)

					endedConnection = UserInputService.InputEnded:Connect(function(endedInput)
						if endedInput.UserInputType == Enum.UserInputType.MouseButton1
							or endedInput.UserInputType == Enum.UserInputType.Touch
						then
							changedConnection:Disconnect()
							endedConnection:Disconnect()
							option:SetValue(option.Value, true)
						end
					end)
				end))

				registerConnection(row.MouseEnter:Connect(function()
					tween(knob, {
						Size = UDim2.fromOffset(16, 16),
					})
				end))

				registerConnection(row.MouseLeave:Connect(function()
					tween(knob, {
						Size = UDim2.fromOffset(14, 14),
					})
				end))

				registerConnection(valueButton.MouseButton1Click:Connect(function()
					valueButton.Visible = false
					valueBox.Visible = true
					valueBox.Text = tostring(option.Value)
					valueBox:CaptureFocus()
				end))

				registerConnection(valueBox.FocusLost:Connect(function(enterPressed)
					valueButton.Visible = true
					valueBox.Visible = false

					if enterPressed and tonumber(valueBox.Text) then
						option:SetValue(tonumber(valueBox.Text), true)
					end
				end))

				insertOption(module, optionName, option)
				option:SetValue(option.Value, false)
				updateOptionsHeight()
				return option
			end

			function module:CreateDropdown(dropdownSettings)
				dropdownSettings = dropdownSettings or {}

				local optionName = dropdownSettings.Name or "Dropdown"
				local values = dropdownSettings.List or {}
				local startingValue = dropdownSettings.Default
					or values[1]
					or "None"

				local option = {
					Type = "Dropdown",
					Value = startingValue,
					List = values,
					Open = false,
				}

				local dropdown = create("TextButton", {
					Name = optionName .. "Dropdown",
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundColor3 = dark(
						moduleChildren.BackgroundColor3,
						dropdownSettings.Darker and 0.02 or 0
					),
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Visible = dropdownSettings.Visible == nil
						or dropdownSettings.Visible,
					Text = "",
					Parent = moduleChildren,
				})

				local border = create("Frame", {
					Name = "BKG",
					Size = UDim2.new(1, -20, 1, -9),
					Position = UDim2.fromOffset(10, 4),
					BackgroundColor3 = light(Theme.Main, 0.034),
					BorderSizePixel = 0,
					Parent = dropdown,
				})
				addCorner(border, UDim.new(0, 6))

				local button = create("TextButton", {
					Name = "Dropdown",
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.fromOffset(1, 1),
					BackgroundColor3 = Theme.Main,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Parent = border,
				})
				addCorner(button, UDim.new(0, 6))

				local titleLabel = create("TextLabel", {
					Name = "Title",
					Size = UDim2.new(1, -30, 0, 29),
					BackgroundTransparency = 1,
					Text = "         " .. optionName .. " - " .. tostring(option.Value),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = dark(Theme.Text, 0.16),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = Theme.Font,
					Parent = button,
				})

				local arrowImage = create("ImageLabel", {
					Name = "Arrow",
					Size = UDim2.fromOffset(4, 8),
					Position = UDim2.new(1, -17, 0, 11),
					BackgroundTransparency = 1,
					Image = Assets.ExpandRight,
					ImageColor3 = Color3.fromRGB(140, 140, 140),
					Rotation = 90,
					Parent = button,
				})

				local optionHolder

				local function destroyList()
					option.Open = false
					arrowImage.Rotation = 90
					dropdown.Size = UDim2.new(1, 0, 0, 40)

					if optionHolder then
						optionHolder:Destroy()
						optionHolder = nil
					end

					updateOptionsHeight()
				end

				function option:SetValue(newValue)
					if not table.find(values, newValue) then
						newValue = values[1] or "None"
					end

					self.Value = newValue
					titleLabel.Text = "         "
						.. optionName
						.. " - "
						.. tostring(newValue)

					destroyList()

					if dropdownSettings.Function then
						dropdownSettings.Function(newValue)
					end
				end

				function option:Change(newList)
					values = newList or {}
					self.List = values
					if not table.find(values, self.Value) then
						self:SetValue(values[1] or "None")
					end
				end

				local function openList()
					if option.Open then
						destroyList()
						return
					end

					option.Open = true
					arrowImage.Rotation = 270

					local extraCount = math.max(#values - 1, 0)
					dropdown.Size = UDim2.new(1, 0, 0, 40 + extraCount * 26)

					optionHolder = create("Frame", {
						Name = "Children",
						Size = UDim2.new(1, 0, 0, extraCount * 26),
						Position = UDim2.fromOffset(0, 27),
						BackgroundTransparency = 1,
						Parent = button,
					})

					local optionIndex = 0
					for _, value in ipairs(values) do
						if value ~= option.Value then
							local optionButton = create("TextButton", {
								Name = tostring(value) .. "Option",
								Size = UDim2.new(1, 0, 0, 26),
								Position = UDim2.fromOffset(0, optionIndex * 26),
								BackgroundColor3 = Theme.Main,
								BorderSizePixel = 0,
								AutoButtonColor = false,
								Text = "         " .. tostring(value),
								TextXAlignment = Enum.TextXAlignment.Left,
								TextColor3 = dark(Theme.Text, 0.16),
								TextSize = 13,
								TextTruncate = Enum.TextTruncate.AtEnd,
								Font = Theme.Font,
								Parent = optionHolder,
							})

							registerConnection(optionButton.MouseEnter:Connect(function()
								tween(optionButton, {
									BackgroundColor3 = light(Theme.Main, 0.02),
								})
							end))

							registerConnection(optionButton.MouseLeave:Connect(function()
								tween(optionButton, {
									BackgroundColor3 = Theme.Main,
								})
							end))

							registerConnection(optionButton.MouseButton1Click:Connect(function()
								option:SetValue(value)
							end))

							optionIndex += 1
						end
					end

					updateOptionsHeight()
				end

				registerConnection(button.MouseButton1Click:Connect(openList))

				registerConnection(dropdown.MouseEnter:Connect(function()
					tween(border, {
						BackgroundColor3 = light(Theme.Main, 0.0875),
					})
				end))

				registerConnection(dropdown.MouseLeave:Connect(function()
					tween(border, {
						BackgroundColor3 = light(Theme.Main, 0.034),
					})
				end))

				insertOption(module, optionName, option)
				updateOptionsHeight()
				return option
			end

			registerConnection(optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
				updateOptionsHeight
			))

			registerConnection(bindButton.MouseEnter:Connect(function()
				bindText.Visible = false
				bindIcon.Visible = true
				bindIcon.Image = Assets.Edit

				if not module.Enabled then
					bindIcon.ImageColor3 = dark(Theme.Text, 0.16)
				end
			end))

			registerConnection(bindButton.MouseLeave:Connect(function()
				bindText.Visible = #module.Bind > 0
				bindIcon.Visible = not bindText.Visible
				bindIcon.Image = Assets.Bind

				if not module.Enabled then
					bindIcon.ImageColor3 = dark(Theme.Text, 0.43)
				end
			end))

			registerConnection(bindButton.MouseButton1Click:Connect(function()
				bindCoverText.Text = "PRESS A KEY TO BIND"
				bindCover.Size = UDim2.fromOffset(
					getTextWidth(bindCoverText.Text, 11, Theme.Font) + 20,
					40
				)
				bindCover.Visible = true
				windowApi.BindingTarget = module
			end))

			registerConnection(dotsButton.MouseEnter:Connect(function()
				if not module.Enabled then
					dots.ImageColor3 = Theme.Text
				end
			end))

			registerConnection(dotsButton.MouseLeave:Connect(function()
				if not module.Enabled then
					dots.ImageColor3 = light(Theme.Main, 0.37)
				end
			end))

			registerConnection(dotsButton.MouseButton1Click:Connect(function()
				module:ToggleOptions()
			end))

			registerConnection(dotsButton.MouseButton2Click:Connect(function()
				module:ToggleOptions()
			end))

			registerConnection(moduleButton.MouseEnter:Connect(function()
				hovered = true

				if not module.Enabled and not module.OptionsVisible then
					moduleButton.TextColor3 = Theme.Text
					moduleButton.BackgroundColor3 = light(Theme.Main, 0.02)
				end

				bindButton.Visible = #module.Bind > 0
					or hovered
					or module.OptionsVisible
			end))

			registerConnection(moduleButton.MouseLeave:Connect(function()
				hovered = false

				if not module.Enabled and not module.OptionsVisible then
					moduleButton.TextColor3 = dark(Theme.Text, 0.16)
					moduleButton.BackgroundColor3 = Theme.Main
				end

				bindButton.Visible = #module.Bind > 0
					or hovered
					or module.OptionsVisible
			end))

			registerConnection(moduleButton.MouseButton1Click:Connect(function()
				module:Toggle()
			end))

			registerConnection(moduleButton.MouseButton2Click:Connect(function()
				module:ToggleOptions()
			end))

			self.Modules[moduleName] = module
			windowApi.Modules[moduleName] = module
			updateCategorySize()
			return module
		end

		registerConnection(arrowButton.MouseButton1Click:Connect(function()
			category:Expand()
		end))

		registerConnection(arrowButton.MouseButton2Click:Connect(function()
			category:Expand()
		end))

		registerConnection(arrowButton.MouseEnter:Connect(function()
			arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
		end))

		registerConnection(arrowButton.MouseLeave:Connect(function()
			arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
		end))

		registerConnection(children:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			divider.Visible = category.Expanded
				and children.CanvasPosition.Y > 10
		end))

		registerConnection(categoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
			updateCategorySize
		))

		registerConnection(categoryWindow.MouseButton2Click:Connect(function()
			local mouse = UserInputService:GetMouseLocation()
			if mouse.Y < categoryWindow.AbsolutePosition.Y + 41 then
				category:Expand()
			end
		end))

		registerConnection(launchButton.MouseEnter:Connect(function()
			if not category.Visible then
				launchButton.TextColor3 = Theme.Text
				launchIcon.ImageColor3 = Theme.Text
				launchButton.BackgroundColor3 = light(Theme.Main, 0.02)
			end
		end))

		registerConnection(launchButton.MouseLeave:Connect(function()
			if not category.Visible then
				launchButton.TextColor3 = dark(Theme.Text, 0.16)
				launchIcon.ImageColor3 = dark(Theme.Text, 0.16)
				launchButton.BackgroundColor3 = Theme.Main
			end
		end))

		registerConnection(launchButton.MouseButton1Click:Connect(function()
			category:ToggleVisible()
		end))

		self.Categories[name] = category
		table.insert(self.CategoryOrder, category)
		updateMainWindowSize()
		return category
	end

	registerConnection(settingsButton.MouseEnter:Connect(function()
		settingsIcon.ImageColor3 = Theme.Text
	end))

	registerConnection(settingsButton.MouseLeave:Connect(function()
		settingsIcon.ImageColor3 = light(Theme.Main, 0.37)
	end))

	registerConnection(settingsButton.MouseButton1Click:Connect(function()
		local settingsCategory = windowApi.Categories.Settings
		if settingsCategory then
			settingsCategory:ToggleVisible()
		end
	end))

	registerConnection(UserInputService.InputBegan:Connect(function(input, processed)
		if windowApi.Destroyed then
			return
		end

		if windowApi.BindingTarget then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local target = windowApi.BindingTarget
				windowApi.BindingTarget = nil

				if input.KeyCode == Enum.KeyCode.Escape
					or input.KeyCode == Enum.KeyCode.Backspace
				then
					target:SetBind({})
					target.BindCover.Text.Text = "BIND REMOVED"
				else
					target:SetBind({input.KeyCode})
					target.BindCover.Text.Text = "BOUND TO " .. input.KeyCode.Name:upper()
				end

				task.delay(0.7, function()
					if target.BindCover and target.BindCover.Parent then
						target.BindCover.Visible = false
					end
				end)
			end

			return
		end

		if not processed and input.KeyCode == windowApi.Keybind then
			windowApi:Toggle()
			return
		end

		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		for _, module in pairs(windowApi.Modules) do
			if #module.Bind > 0 then
				local matches = true

				for _, keyCode in ipairs(module.Bind) do
					if keyCode ~= input.KeyCode
						and not UserInputService:IsKeyDown(keyCode)
					then
						matches = false
						break
					end
				end

				if matches then
					module:Toggle()
				end
			end
		end
	end))

	updateMainWindowSize()
	return windowApi
end

return KeeV4
