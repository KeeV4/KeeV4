local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local KeeV4 = {}

local Theme = {
	Main = Color3.fromRGB(26, 25, 26),
	Secondary = Color3.fromRGB(32, 31, 32),
	Component = Color3.fromRGB(38, 37, 38),
	ComponentHover = Color3.fromRGB(46, 45, 46),

	Text = Color3.fromRGB(220, 220, 220),
	MutedText = Color3.fromRGB(145, 145, 145),

	Accent = Color3.fromRGB(5, 133, 104),

	Font = Enum.Font.Arial,
	TweenInfo = TweenInfo.new(
		0.16,
		Enum.EasingStyle.Linear
	),
}

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

local function addCorner(object, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 6),
		Parent = object,
	})
end

local function tween(object, properties)
	local animation = TweenService:Create(
		object,
		Theme.TweenInfo,
		properties
	)

	animation:Play()
	return animation
end

local function makeDraggable(window, handle)
	local dragging = false
	local dragStart
	local startPosition

	handle.InputBegan:Connect(function(input)
		local validInput =
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch

		if not validInput then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = window.Position
	end)

	UserInputService.InputChanged:Connect(function(input)
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
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

function KeeV4:CreateWindow(options)
	options = options or {}

	if options.Accent then
		Theme.Accent = options.Accent
	end

	local parent

	if gethui then
		parent = gethui()
	else
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local screenGui = create("ScreenGui", {
		Name = options.GuiName or "KeeV4",
		DisplayOrder = 999,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	local window = create("Frame", {
		Name = "Window",
		Size = options.Size or UDim2.fromOffset(620, 390),
		Position = UDim2.new(0.5, -310, 0.5, -195),
		BackgroundColor3 = Theme.Main,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui,
	})

	addCorner(window, 8)

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		Parent = window,
	})

	local title = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -55, 1, 0),
		Position = UDim2.fromOffset(15, 0),
		BackgroundTransparency = 1,
		Text = options.Title or "KeeV4",
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		Parent = header,
	})

	local closeButton = create("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(36, 30),
		Position = UDim2.new(1, -42, 0, 7),
		BackgroundColor3 = Theme.Component,
		AutoButtonColor = false,
		Text = "×",
		TextColor3 = Theme.MutedText,
		TextSize = 22,
		Font = Theme.Font,
		Parent = header,
	})

	addCorner(closeButton, 6)

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, -44),
		Position = UDim2.fromOffset(0, 44),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		Parent = window,
	})

	local sidebarPadding = create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = sidebar,
	})

	local sidebarLayout = create("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})

	local pageHolder = create("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -150, 1, -44),
		Position = UDim2.fromOffset(150, 44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = window,
	})

	makeDraggable(window, header)

	local windowApi = {
		Gui = screenGui,
		Object = window,
		Categories = {},
		Visible = true,
		SelectedCategory = nil,
	}

	function windowApi:SetVisible(value)
		self.Visible = value == true
		screenGui.Enabled = self.Visible
	end

	function windowApi:Toggle()
		self:SetVisible(not self.Visible)
	end

	function windowApi:Destroy()
		screenGui:Destroy()
	end

	function windowApi:SelectCategory(category)
		if self.SelectedCategory == category then
			return
		end

		for _, currentCategory in pairs(self.Categories) do
			local selected = currentCategory == category

			currentCategory.Page.Visible = selected
			currentCategory.Button.TextColor3 =
				selected and Theme.Text or Theme.MutedText

			tween(currentCategory.Button, {
				BackgroundColor3 =
					selected and Theme.ComponentHover
					or Theme.Secondary,
			})

			currentCategory.Indicator.Visible = selected
		end

		self.SelectedCategory = category
	end

	function windowApi:CreateCategory(settings)
		settings = settings or {}

		local category = {
			Name = settings.Name or "Category",
			Modules = {},
		}

		local button = create("TextButton", {
			Name = category.Name .. "Button",
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Secondary,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "   " .. category.Name,
			TextColor3 = Theme.MutedText,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.Font,
			Parent = sidebar,
		})

		addCorner(button, 6)

		local indicator = create("Frame", {
			Name = "Indicator",
			Size = UDim2.fromOffset(3, 20),
			Position = UDim2.fromOffset(2, 8),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = button,
		})

		addCorner(indicator, 3)

		local page = create("ScrollingFrame", {
			Name = category.Name .. "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.MutedText,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Visible = false,
			Parent = pageHolder,
		})

		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = page,
		})

		create("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		category.Button = button
		category.Indicator = indicator
		category.Page = page

		function category:CreateModule(moduleSettings)
			moduleSettings = moduleSettings or {}

			local module = {
				Name = moduleSettings.Name or "Module",
				Enabled = false,
				Options = {},
			}

			local holder = create("Frame", {
				Name = module.Name .. "Module",
				Size = UDim2.new(1, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Parent = page,
			})

			addCorner(holder, 7)

			local moduleLayout = create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = holder,
			})

			local moduleButton = create("TextButton", {
				Name = "Button",
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "   " .. module.Name,
				TextColor3 = Theme.MutedText,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Theme.Font,
				Parent = holder,
			})

			local status = create("Frame", {
				Name = "Status",
				Size = UDim2.fromOffset(4, 18),
				Position = UDim2.fromOffset(5, 11),
				BackgroundColor3 = Theme.Component,
				BorderSizePixel = 0,
				Parent = moduleButton,
			})

			addCorner(status, 3)

			local dots = create("TextButton", {
				Name = "OptionsButton",
				Size = UDim2.fromOffset(36, 40),
				Position = UDim2.new(1, -36, 0, 0),
				BackgroundTransparency = 1,
				Text = "•••",
				TextColor3 = Theme.MutedText,
				TextSize = 14,
				Font = Theme.Font,
				Parent = moduleButton,
			})

			local optionsHolder = create("Frame", {
				Name = "Options",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Component,
				BorderSizePixel = 0,
				Visible = false,
				Parent = holder,
			})

			create("UIPadding", {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
				Parent = optionsHolder,
			})

			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = optionsHolder,
			})

			function module:SetEnabled(value)
				value = value == true

				if self.Enabled == value then
					return
				end

				self.Enabled = value

				tween(status, {
					BackgroundColor3 =
						self.Enabled and Theme.Accent
						or Theme.Component,
				})

				tween(moduleButton, {
					TextColor3 =
						self.Enabled and Theme.Text
						or Theme.MutedText,
				})

				if moduleSettings.Function then
					task.spawn(moduleSettings.Function, self.Enabled)
				end
			end

			function module:Toggle()
				self:SetEnabled(not self.Enabled)
			end

			function module:CreateToggle(toggleSettings)
				toggleSettings = toggleSettings or {}

				local toggleApi = {
					Enabled = toggleSettings.Default == true,
				}

				local row = create("TextButton", {
					Name = (toggleSettings.Name or "Toggle") .. "Toggle",
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "   " .. (toggleSettings.Name or "Toggle"),
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Theme.Font,
					Parent = optionsHolder,
				})

				local track = create("Frame", {
					Name = "Track",
					Size = UDim2.fromOffset(24, 14),
					Position = UDim2.new(1, -34, 0.5, -7),
					BackgroundColor3 =
						toggleApi.Enabled and Theme.Accent
						or Theme.Secondary,
					BorderSizePixel = 0,
					Parent = row,
				})

				addCorner(track, 7)

				local knob = create("Frame", {
					Name = "Knob",
					Size = UDim2.fromOffset(10, 10),
					Position = UDim2.fromOffset(
						toggleApi.Enabled and 12 or 2,
						2
					),
					BackgroundColor3 = Theme.Text,
					BorderSizePixel = 0,
					Parent = track,
				})

				addCorner(knob, 5)

				function toggleApi:SetEnabled(value)
					self.Enabled = value == true

					tween(track, {
						BackgroundColor3 =
							self.Enabled and Theme.Accent
							or Theme.Secondary,
					})

					tween(knob, {
						Position = UDim2.fromOffset(
							self.Enabled and 12 or 2,
							2
						),
					})

					if toggleSettings.Function then
						toggleSettings.Function(self.Enabled)
					end
				end

				function toggleApi:Toggle()
					self:SetEnabled(not self.Enabled)
				end

				row.Activated:Connect(function()
					toggleApi:Toggle()
				end)

				table.insert(module.Options, toggleApi)
				return toggleApi
			end

			function module:CreateSlider(sliderSettings)
				sliderSettings = sliderSettings or {}

				local minimum = sliderSettings.Min or 0
				local maximum = sliderSettings.Max or 100
				local value = sliderSettings.Default or minimum
				local decimal = sliderSettings.Decimal or 1

				local sliderApi = {
					Value = value,
				}

				local row = create("Frame", {
					Name = (sliderSettings.Name or "Slider") .. "Slider",
					Size = UDim2.new(1, 0, 0, 48),
					BackgroundTransparency = 1,
					Parent = optionsHolder,
				})

				local label = create("TextLabel", {
					Size = UDim2.new(1, -70, 0, 25),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					Text = sliderSettings.Name or "Slider",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Theme.Font,
					Parent = row,
				})

				local valueLabel = create("TextLabel", {
					Size = UDim2.fromOffset(55, 25),
					Position = UDim2.new(1, -65, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(value),
					TextColor3 = Theme.MutedText,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Font = Theme.Font,
					Parent = row,
				})

				local bar = create("TextButton", {
					Size = UDim2.new(1, -20, 0, 5),
					Position = UDim2.fromOffset(10, 34),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Parent = row,
				})

				addCorner(bar, 3)

				local fill = create("Frame", {
					Size = UDim2.fromScale(
						math.clamp(
							(value - minimum) /
							(maximum - minimum),
							0,
							1
						),
						1
					),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = bar,
				})

				addCorner(fill, 3)

				function sliderApi:SetValue(newValue)
					newValue = math.clamp(
						tonumber(newValue) or minimum,
						minimum,
						maximum
					)

					newValue =
						math.floor(newValue * decimal + 0.5)
						/ decimal

					self.Value = newValue
					valueLabel.Text = tostring(newValue)

					tween(fill, {
						Size = UDim2.fromScale(
							(newValue - minimum) /
							(maximum - minimum),
							1
						),
					})

					if sliderSettings.Function then
						sliderSettings.Function(newValue)
					end
				end

				local function updateFromInput(input)
					local percentage = math.clamp(
						(input.Position.X - bar.AbsolutePosition.X)
						/ bar.AbsoluteSize.X,
						0,
						1
					)

					sliderApi:SetValue(
						minimum +
						(maximum - minimum) * percentage
					)
				end

				bar.InputBegan:Connect(function(input)
					if
						input.UserInputType
							~= Enum.UserInputType.MouseButton1
						and input.UserInputType
							~= Enum.UserInputType.Touch
					then
						return
					end

					updateFromInput(input)

					local changedConnection
					local endedConnection

					changedConnection =
						UserInputService.InputChanged:Connect(
							function(changedInput)
								if
									changedInput.UserInputType
										== Enum.UserInputType.MouseMovement
									or changedInput.UserInputType
										== Enum.UserInputType.Touch
								then
									updateFromInput(changedInput)
								end
							end
						)

					endedConnection =
						UserInputService.InputEnded:Connect(
							function(endedInput)
								if
									endedInput.UserInputType
										== Enum.UserInputType.MouseButton1
									or endedInput.UserInputType
										== Enum.UserInputType.Touch
								then
									changedConnection:Disconnect()
									endedConnection:Disconnect()
								end
							end
						)
				end)

				table.insert(module.Options, sliderApi)
				return sliderApi
			end

			function module:CreateDropdown(dropdownSettings)
				dropdownSettings = dropdownSettings or {}

				local values = dropdownSettings.List or {}
				local dropdownApi = {
					Value = dropdownSettings.Default
						or values[1]
						or "None",
				}

				local holder = create("Frame", {
					Name = (dropdownSettings.Name or "Dropdown")
						.. "Dropdown",
					Size = UDim2.new(1, 0, 0, 36),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = optionsHolder,
				})

				local button = create("TextButton", {
					Size = UDim2.new(1, -20, 0, 30),
					Position = UDim2.fromOffset(10, 3),
					BackgroundColor3 = Theme.Secondary,
					AutoButtonColor = false,
					Text = "",
					Parent = holder,
				})

				addCorner(button, 5)

				local text = create("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					Text = (dropdownSettings.Name or "Dropdown")
						.. ": "
						.. tostring(dropdownApi.Value),
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Theme.Font,
					Parent = button,
				})

				local list = create("Frame", {
					Size = UDim2.new(1, -20, 0, 0),
					Position = UDim2.fromOffset(10, 36),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Theme.Secondary,
					Visible = false,
					Parent = holder,
				})

				addCorner(list, 5)

				create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = list,
				})

				function dropdownApi:SetValue(newValue)
					self.Value = newValue

					text.Text =
						(dropdownSettings.Name or "Dropdown")
						.. ": "
						.. tostring(newValue)

					list.Visible = false

					if dropdownSettings.Function then
						dropdownSettings.Function(newValue)
					end
				end

				for _, option in ipairs(values) do
					local optionButton = create("TextButton", {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundTransparency = 1,
						Text = tostring(option),
						TextColor3 = Theme.MutedText,
						TextSize = 12,
						Font = Theme.Font,
						Parent = list,
					})

					optionButton.Activated:Connect(function()
						dropdownApi:SetValue(option)
					end)
				end

				button.Activated:Connect(function()
					list.Visible = not list.Visible
				end)

				table.insert(module.Options, dropdownApi)
				return dropdownApi
			end

			moduleButton.Activated:Connect(function()
				module:Toggle()
			end)

			dots.Activated:Connect(function()
				optionsHolder.Visible = not optionsHolder.Visible
			end)

			table.insert(category.Modules, module)
			return module
		end

		button.Activated:Connect(function()
			windowApi:SelectCategory(category)
		end)

		table.insert(self.Categories, category)

		if not self.SelectedCategory then
			self:SelectCategory(category)
		end

		return category
	end

	closeButton.MouseEnter:Connect(function()
		tween(closeButton, {
			BackgroundColor3 = Theme.ComponentHover,
			TextColor3 = Theme.Text,
		})
	end)

	closeButton.MouseLeave:Connect(function()
		tween(closeButton, {
			BackgroundColor3 = Theme.Component,
			TextColor3 = Theme.MutedText,
		})
	end)

	closeButton.Activated:Connect(function()
		windowApi:SetVisible(false)
	end)

	local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == toggleKey then
			windowApi:Toggle()
		end
	end)

	return windowApi
end

return KeeV4
