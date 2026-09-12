-- Ghost Pepper UI - standalone test library
-- API: Library:CreateWindow() -> Window:AddTab() -> Tab:AddSection()

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Run this UI from a LocalScript/executor client")

local Library = {
	Theme = {
		Background = Color3.fromRGB(93, 10, 21),
		Sidebar = Color3.fromRGB(114, 14, 29),
		Surface = Color3.fromRGB(137, 24, 42),
		SurfaceHover = Color3.fromRGB(163, 32, 55),
		Control = Color3.fromRGB(151, 28, 48),
		Accent = Color3.fromRGB(239, 67, 108),
		AccentDark = Color3.fromRGB(181, 29, 61),
		Enabled = Color3.fromRGB(40, 168, 91),
		Outline = Color3.fromRGB(102, 10, 27),
		Text = Color3.fromRGB(255, 239, 241),
		Muted = Color3.fromRGB(190, 133, 145),
	},
	_activeSlider = nil,
}

local function tween(object, properties, duration)
	TweenService:Create(object, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties):Play()
end

local function corner(object, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 8)
	value.Parent = object
	return value
end

local function outline(object, color, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color or Library.Theme.Outline
	value.Thickness = thickness or 1
	value.Parent = object
	return value
end

local function new(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function text(parent, value, size, color, font)
	return new("TextLabel", {
		BackgroundTransparency = 1, Text = value or "", TextSize = size or 14,
		TextColor3 = color or Library.Theme.Text, Font = font or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local buttonRestColor = setmetatable({}, { __mode = "k" })
local function setButtonRestColor(control, color)
	buttonRestColor[control] = color
	control.BackgroundColor3 = color
end

local function button(parent, value)
	local control = new("TextButton", {
		AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = Library.Theme.Surface,
		Text = value or "", TextColor3 = Library.Theme.Text, TextSize = 13, Font = Enum.Font.GothamMedium,
	}, parent)
	corner(control, 7)
	outline(control)
	buttonRestColor[control] = Library.Theme.Surface
	control.MouseEnter:Connect(function()
		local base = buttonRestColor[control] or Library.Theme.Surface
		local hover = base == Library.Theme.Enabled and Color3.fromRGB(53, 190, 105) or Library.Theme.SurfaceHover
		tween(control, { BackgroundColor3 = hover })
	end)
	control.MouseLeave:Connect(function() tween(control, { BackgroundColor3 = buttonRestColor[control] or Library.Theme.Surface }) end)
	return control
end

-- One shared slider dispatcher prevents a new InputChanged connection per slider.
UserInputService.InputChanged:Connect(function(input)
	local active = Library._activeSlider
	if not active or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
	active:SetFromX(input.Position.X)
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Library._activeSlider = nil
	end
end)

function Library:CreateWindow(config)
	config = config or {}
	-- gethui() may point to a protected CoreGui-like container.  In Studio and
	-- restricted executors parenting there raises "lacking capability Plugin".
	-- PlayerGui is available to every LocalScript/executor context and survives
	-- respawns because ResetOnSpawn is disabled below.
	local guiParent = player:WaitForChild("PlayerGui")
	local guiName = config.Name or "GhostPepperUITest"
	local old = guiParent:FindFirstChild(guiName)
	if old then old:Destroy() end

	local gui = new("ScreenGui", { Name = guiName, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent)
	local window = { Gui = gui, Tabs = {}, Selected = nil, Collapsed = false }
	local width, height = config.Width or 760, config.Height or 500
	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height), BorderSizePixel = 0, BackgroundColor3 = self.Theme.Background,
	}, gui)
	corner(main, 12)
	outline(main, self.Theme.AccentDark, 2)
	window.Main = main

	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = self.Theme.Sidebar, BorderSizePixel = 0 }, main)
	corner(header, 12)
	local headerLine = new("Frame", { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, -1), BackgroundColor3 = self.Theme.Outline, BorderSizePixel = 0 }, header)
	local logo = new("ImageLabel", { Name = "Logo", BackgroundTransparency = 1, Image = "rbxassetid://139877446989431", Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14, 12), ScaleType = Enum.ScaleType.Fit }, header)
	local title = text(header, config.Title or "GHOST PEPPER HUB", 16, self.Theme.Text, Enum.Font.GothamBold)
	title.AnchorPoint, title.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 9)
	title.Size, title.TextXAlignment = UDim2.new(1, -180, 0, 24), Enum.TextXAlignment.Center
	local subtitle = text(header, config.Subtitle or "CONTROL PANEL", 10, self.Theme.Muted, Enum.Font.GothamMedium)
	subtitle.AnchorPoint, subtitle.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 33)
	subtitle.Size, subtitle.TextXAlignment = UDim2.new(1, -180, 0, 15), Enum.TextXAlignment.Center

	local minimize = button(header, "-")
	minimize.Size, minimize.Position = UDim2.fromOffset(30, 28), UDim2.new(1, -72, 0, 14)
	local close = button(header, "X")
	close.Size, close.Position = UDim2.fromOffset(30, 28), UDim2.new(1, -38, 0, 14)

	local reopen = button(gui, "")
	reopen.Name, reopen.Visible, reopen.Size = "Reopen", true, UDim2.fromOffset(44, 44)
	reopen.Position, reopen.TextSize = UDim2.new(0, 18, 0.5, -22), 16
	setButtonRestColor(reopen, Color3.fromRGB(12, 3, 6))
	local reopenCorner = reopen:FindFirstChildOfClass("UICorner")
	if reopenCorner then reopenCorner.CornerRadius = UDim.new(1, 0) end
	local reopenOutline = reopen:FindFirstChildOfClass("UIStroke")
	if reopenOutline then reopenOutline.Color, reopenOutline.Thickness = self.Theme.Accent, 2 end
	new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://139877446989431", Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(7, 7), ScaleType = Enum.ScaleType.Fit }, reopen)

	local sidebar = new("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(10, 68), Size = UDim2.new(0, 164, 1, -78), BackgroundColor3 = self.Theme.Sidebar, BorderSizePixel = 0 }, main)
	corner(sidebar, 10)
	local tabsTitle = text(sidebar, "TABS", 11, self.Theme.Muted, Enum.Font.GothamBold)
	tabsTitle.Position, tabsTitle.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 18)
	local tabList = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 35), Size = UDim2.new(1, -16, 1, -43), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = self.Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, sidebar)
	local tabLayout = new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)

	local pageHolder = new("Frame", { Name = "Pages", Position = UDim2.fromOffset(184, 68), Size = UDim2.new(1, -194, 1, -78), BackgroundTransparency = 1 }, main)
	local notificationLimit = math.clamp(tonumber(config.NotificationLimit) or 4, 1, 6)
	local notificationOrder = 0
	local notificationHost = new("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(280, notificationLimit * 48), BackgroundTransparency = 1,
	}, gui)
	new("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }, notificationHost)

	function window:SetVisible(visible)
		main.Visible = visible
		-- The floating logo stays available in both states and acts as the
		-- open/close toggle for the window.
		reopen.Visible = true
	end
	function window:Destroy() gui:Destroy() end
	function window:Notify(message, duration)
		local existing = {}
		for _, child in ipairs(notificationHost:GetChildren()) do if child:IsA("Frame") then table.insert(existing, child) end end
		while #existing >= notificationLimit do
			existing[1]:Destroy()
			table.remove(existing, 1)
		end
		notificationOrder += 1
		local toast = new("Frame", { Size = UDim2.fromOffset(280, 42), BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, LayoutOrder = notificationOrder }, notificationHost)
		corner(toast, 9); outline(toast, Library.Theme.AccentDark)
		new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://139877446989431", Size = UDim2.fromOffset(25, 25), Position = UDim2.fromOffset(10, 8), ScaleType = Enum.ScaleType.Fit }, toast)
		local toastText = text(toast, message, 13, Library.Theme.Text, Enum.Font.GothamMedium)
		toastText.Position, toastText.Size = UDim2.fromOffset(44, 0), UDim2.new(1, -56, 1, 0)
		toast.BackgroundTransparency, toastText.TextTransparency = 1, 1
		tween(toast, { BackgroundTransparency = 0 }, 0.16)
		tween(toastText, { TextTransparency = 0 }, 0.16)
		task.delay(duration or 3, function()
			if toast.Parent then tween(toast, { BackgroundTransparency = 1 }, 0.15); tween(toastText, { TextTransparency = 1 }, 0.15); task.wait(0.16); toast:Destroy() end
		end)
	end

	function window:SelectTab(tab)
		for _, other in pairs(self.Tabs) do
			other.Page.Visible = other == tab
			other.Button.BackgroundColor3 = other == tab and Library.Theme.AccentDark or Library.Theme.Surface
		end
		self.Selected = tab
	end

	local tabOrder = 0
	function window:AddTab(name)
		local tab = { Name = name, Sections = {} }
		local tabButton = button(tabList, name)
		tabButton.Size, tabButton.LayoutOrder = UDim2.new(1, 0, 0, 38), tabOrder
		tabOrder += 1
		tab.Button = tabButton
		local page = new("ScrollingFrame", { Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Library.Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, pageHolder)
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		tab.Page = page
		self.Tabs[name] = tab
		tabButton.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

		function tab:AddSection(sectionName)
			local section = { Name = sectionName }
			local card = new("Frame", { Size = UDim2.new(1, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0 }, page)
			corner(card, 10); outline(card)
			local heading = text(card, string.upper(sectionName), 11, Library.Theme.Muted, Enum.Font.GothamBold)
			heading.Position, heading.Size = UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 21)
			local body = new("Frame", { Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, card)
			new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)
			new("UIPadding", { PaddingBottom = UDim.new(0, 8) }, body)
			body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				card.Size = UDim2.new(1, -5, 0, math.max(40, body.AbsoluteSize.Y + 40))
			end)

			local function row(labelText, height)
				local rowFrame = new("Frame", { Size = UDim2.new(1, 0, 0, height or 42), BackgroundColor3 = Library.Theme.Control, BorderSizePixel = 0 }, body)
				corner(rowFrame, 8); outline(rowFrame, Library.Theme.Outline)
				local rowLabel = text(rowFrame, labelText, 13, Library.Theme.Text, Enum.Font.GothamMedium)
				rowLabel.Position, rowLabel.Size = UDim2.fromOffset(13, 0), UDim2.new(1, -145, 1, 0)
				return rowFrame, rowLabel
			end

			function section:AddToggle(config)
				config = config or {}; local value = config.Default == true
				local frame = row(config.Text or "Toggle")
				local toggle = button(frame, value and (config.OnText or "ON") or (config.OffText or "OFF"))
				toggle.Size, toggle.Position = UDim2.fromOffset(60, 28), UDim2.new(1, -70, 0.5, -14)
				local object = {}
				function object:Set(nextValue, silent)
					value = nextValue == true
					toggle.Text = value and (config.OnText or "ON") or (config.OffText or "OFF")
					setButtonRestColor(toggle, value and Library.Theme.Enabled or Library.Theme.Surface)
					if not silent and config.Callback then config.Callback(value) end
				end
				function object:Get() return value end
				toggle.MouseButton1Click:Connect(function() object:Set(not value) end)
				object:Set(value, true)
				return object
			end

			function section:AddSlider(config)
				config = config or {}; local minimum, maximum = tonumber(config.Min) or 0, tonumber(config.Max) or 100
				local step, value = tonumber(config.Step) or 1, tonumber(config.Default) or minimum
				local frame, rowLabel = row(config.Text or "Slider", 58)
				rowLabel.Size = UDim2.new(1, -90, 0, 28)
				local box = new("TextBox", { Text = "", ClearTextOnFocus = false, TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, Size = UDim2.fromOffset(62, 24), Position = UDim2.new(1, -72, 0, 8) }, frame)
				corner(box, 6); outline(box)
				local track = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(13, 42), Size = UDim2.new(1, -26, 0, 6) }, frame)
				corner(track, 4)
				local fill = new("Frame", { BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, track); corner(fill, 4)
				local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Library.Theme.Text, BorderSizePixel = 0 }, track); corner(knob, 9); outline(knob)
				local object = {}
				local function format(number) return number % 1 == 0 and tostring(math.floor(number)) or string.format("%.2f", number):gsub("0+$", ""):gsub("%.$", "") end
				function object:Set(nextValue, silent)
					value = math.clamp(math.floor(((nextValue - minimum) / step) + 0.5) * step + minimum, minimum, maximum)
					local alpha = (value - minimum) / math.max(maximum - minimum, 0.001)
					box.Text = format(value) .. (config.Suffix or "")
					tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.08); tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.08)
					if not silent and config.Callback then config.Callback(value) end
				end
				function object:Get() return value end
				function object:SetFromX(x) object:Set(minimum + (maximum - minimum) * math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)) end
				track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Library._activeSlider = object; object:SetFromX(input.Position.X) end end)
				box.FocusLost:Connect(function() object:Set(tonumber(string.match(box.Text, "[-%d%.]+")) or value) end)
				object:Set(value, true)
				return object
			end

			function section:AddButton(config)
				config = config or {}; local control = button(body, config.Text or "Button")
				control.Size = UDim2.new(1, 0, 0, 38)
				control.MouseButton1Click:Connect(function() if config.Callback then config.Callback() end end)
				return control
			end

			function section:AddDropdown(config)
				config = config or {}; local options, value = config.Options or {}, config.Default
				-- Holder participates in the section UIListLayout. Expanding it pushes
				-- the following controls down instead of drawing options over them.
				local holder = new("Frame", { Name = "DropdownHolder", Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false }, body)
				local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Library.Theme.Control, BorderSizePixel = 0 }, holder)
				corner(frame, 8); outline(frame, Library.Theme.Outline)
				local rowLabel = text(frame, config.Text or "Dropdown", 13, Library.Theme.Text, Enum.Font.GothamMedium)
				rowLabel.Position, rowLabel.Size = UDim2.fromOffset(13, 0), UDim2.new(1, -145, 1, 0)
				local select = button(frame, tostring(value or "Select"))
				select.Size, select.Position = UDim2.fromOffset(118, 28), UDim2.new(1, -128, 0.5, -14)
				select.TextXAlignment = Enum.TextXAlignment.Center
				local arrow = text(select, "v", 12, Library.Theme.Muted, Enum.Font.GothamBold)
				arrow.AnchorPoint, arrow.Position = Vector2.new(1, 0.5), UDim2.new(1, -9, 0.5, 0)
				arrow.Size, arrow.TextXAlignment = UDim2.fromOffset(14, 20), Enum.TextXAlignment.Center
				local list = new("Frame", { Visible = false, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, #options * 31 + 6), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0 }, holder)
				corner(list, 8); outline(list)
				new("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, list)
				local function setValue(nextValue, fireCallback)
					value = nextValue
					select.Text = tostring(value or "Select")
					if fireCallback and config.Callback then config.Callback(value) end
				end
				for _, option in ipairs(options) do
					local choice = button(list, tostring(option)); choice.Size, choice.ZIndex = UDim2.new(1, -8, 0, 27), 5
					choice.MouseButton1Click:Connect(function() setValue(option, true); list.Visible = false; arrow.Text = "v"; holder.Size = UDim2.new(1, 0, 0, 42) end)
				end
				select.MouseButton1Click:Connect(function()
					list.Visible = not list.Visible
					arrow.Text = list.Visible and "^" or "v"
					holder.Size = UDim2.new(1, 0, 0, list.Visible and (#options * 31 + 52) or 42)
				end)
				return { Get = function() return value end, Set = function(_, nextValue) setValue(nextValue, false) end }
			end
			return section
		end
		if not self.Selected then self:SelectTab(tab) end
		return tab
	end

	local dragging, startPosition, startPointer = false, nil, nil
	header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging, startPointer, startPosition = true, input.Position, main.Position end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - startPointer; main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	minimize.MouseButton1Click:Connect(function()
		window.Collapsed = not window.Collapsed
		sidebar.Visible, pageHolder.Visible = not window.Collapsed, not window.Collapsed
		local offset = (height - 58) * 0.5
		local position = main.Position
		if window.Collapsed then
			-- Keep the top edge fixed: collapsing moves the center upward first.
			main.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset - offset)
			main.Size = UDim2.fromOffset(width, 58)
		else
			-- Restore from the same top edge, so the body grows downward.
			main.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + offset)
			main.Size = UDim2.fromOffset(width, height)
		end
	end)
	close.MouseButton1Click:Connect(function() window:SetVisible(false) end)
	local reopenDragging, reopenMoved, reopenStart, reopenPosition = false, false, nil, nil
	reopen.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			reopenDragging, reopenMoved = true, false
			reopenStart, reopenPosition = input.Position, reopen.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not reopenDragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
		local delta = input.Position - reopenStart
		if delta.Magnitude > 3 then reopenMoved = true end
		reopen.Position = UDim2.new(reopenPosition.X.Scale, reopenPosition.X.Offset + delta.X, reopenPosition.Y.Scale, reopenPosition.Y.Offset + delta.Y)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then reopenDragging = false end
	end)
	reopen.MouseButton1Click:Connect(function()
		if reopenMoved then return end
		window:SetVisible(not main.Visible)
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			window:SetVisible(not main.Visible)
		end
	end)
	return window
end

-- Visual test. Set false when this file becomes only a library.
local DEMO = false
if DEMO then
	local Window = Library:CreateWindow({ Title = "GHOST PEPPER HUB", Subtitle = "" })
	local Main = Window:AddTab("Main")
	local Controls = Main:AddSection("Movement")
	Controls:AddToggle({ Text = "Manual Bypass", Default = false, OnText = "Enabled", OffText = "Disabled" })
	Controls:AddSlider({ Text = "Movement Speed", Min = 500, Max = 1000, Step = 10, Default = 500 })
	Controls:AddDropdown({ Text = "Movement Mode", Options = { "Smooth", "Fast", "Safe" }, Default = "Smooth" })
	local Visuals = Window:AddTab("Visuals")
	local View = Visuals:AddSection("Display")
	View:AddToggle({ Text = "Egg ESP" })
	View:AddButton({ Text = "Show notification", Callback = function() Window:Notify("Ghost Pepper UI is ready") end })
end

return Library
