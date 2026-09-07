-- Created and Maintained by reborb (@rebornspy).
-- Inspired by various other GUI Suites.
-- Works in studio, at the cost of no icons.

-- \\ Globals & Services
local Players: Players = game:GetService("Players") :: Players
local RunService: RunService = game:GetService("RunService") :: RunService
local UIS: UserInputService = game:GetService("UserInputService") :: UserInputService
local ts: TweenService = game:GetService("TweenService") :: TweenService

local LP: Player = Players.LocalPlayer :: Player

_G.conns = _G.conns or {}
_G.cleanup = function()
	for _, conn: RBXScriptConnection in ipairs(_G.conns) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(_G.conns)
end

-- // Themes
local Themes = {
	Dark = {
		bg = Color3.fromRGB(17, 17, 20);
		header = Color3.fromRGB(23, 23, 27);
		colbg = Color3.fromRGB(24, 24, 29);
		border = Color3.fromRGB(44, 44, 51);
		hover = Color3.fromRGB(34, 34, 40);
		pillHover = Color3.fromRGB(44, 44, 50);
		text = Color3.fromRGB(233, 233, 238);
		dim = Color3.fromRGB(150, 150, 160);
		faint = Color3.fromRGB(105, 105, 116);
		blue = Color3.fromRGB(72, 130, 248);
		trackOff = Color3.fromRGB(58, 58, 66);
		pill = Color3.fromRGB(33, 33, 40);
		pillBrd = Color3.fromRGB(54, 54, 62);
		knob = Color3.fromRGB(240, 240, 245);
	};
}

local CurrentTheme = Themes.Dark

local function SetTheme(name: string)
	local t = Themes[name]
	if t then
		CurrentTheme = t
		return true
	end
	return false
end

local function GetTheme()
	return CurrentTheme
end

-- \\ Utilities
local Util = {}

function Util.GetSafeParent()
	local parent = nil
	
	if RunService:IsStudio() then
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	elseif gethui() then
		parent = gethui()
	elseif game:GetService("CoreGui") then
		parent = game:GetService("CoreGui")
	else
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	return parent
end

function Util.corner(p: Instance, r: number?)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 6)
	u.Parent = p
	return u
end

function Util.stroke(p: Instance, col: Color3, t: number?, tr: number?)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = t or 1
	s.Transparency = tr or 0
	s.Parent = p
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

function Util.tween(obj: Instance, info: TweenInfo, props: {[string]: any})
	return ts:Create(
		obj,
		info,
		props
	)
end

function Util.isValidKeyCode(keyOrString: string)
	for _, key in Enum.KeyCode:GetEnumItems() do
		if key.Name == keyOrString then
			return true
		end
	end
	return false
end

-- // Icons
local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lib/Icons.luau"))()
end)

local function Icon(parent: Instance, name: string, size: number, color: Color3)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(size, size)
	img.ImageColor3 = color

	local set = Lucide and Lucide["48px"] and Lucide["48px"][name]
	if set then
		img.Image = "rbxassetid://"..set[1]
		img.ImageRectSize = Vector2.new(set[2][1], set[2][2])
		img.ImageRectOffset = Vector2.new(set[3][1], set[3][2])
	end

	img.Parent = parent
	return img
end

-- \\ Classes
local Window = {}
Window.__index = Window

local Column = {}
Column.__index = Column

local Section = {}
Section.__index = Section

local Toggle = {}
Toggle.__index = Toggle

local Slider = {}
Slider.__index = Slider

local Pill = {}
Pill.__index = Pill
local PlayerList = {}
PlayerList.__index = PlayerList

local MiniButton = {}
MiniButton.__index = MiniButton

local Keybind = {}
Keybind.__index = Keybind

local Option = {}
Option.__index = Option

local ComponentFactory = {
	Toggle = Toggle;
	Slider = Slider;
	Button = Pill;
	Keybind = Keybind;
}

-- // Windows
export type WindowType = {
	Gui: ScreenGui;
	Main: Frame;
	Body: ScrollingFrame;
	NotificationHolder: Frame;
	Visible: boolean;
	Minimized: boolean;
	PrevSize: UDim2;
	NumberOfColumns: number;
	
	_notifications: {};

	_makeResizable: (self: WindowType, handle: Frame) -> ();
	_updateColumnSize: (self: WindowType) -> ();
	RefreshTheme: (self: WindowType) -> ();
	addColumn: (self: WindowType, order: number) -> ColumnType;
	Minimize: (self: WindowType, minimized: boolean) -> ();
	ToggleUi: (self: WindowType, toggled: boolean) -> ();
	Notify: (self: WindowType, data: NotificationData) -> ();
	_reorderNotifications: (self: WindowType) -> ();
	_removeNotification: (self: WindowType, notif: Frame) -> ();
}

export type WindowData = {
	Name: string;
	Icon: string;
	CloseKeybind: Enum.KeyCode;
}

export type NotificationData = {
	Title: string;
	Message: string;
	Icon: string?;
	Duration: number?;
	Type: "info" | "success" | "warning" | "error"?;
}

function Window.new(data: WindowData): WindowType
	if _G.cleanup then
		_G.cleanup()
	end
	
	if Util.GetSafeParent():FindFirstChild("holder") then
		local holder = Util.GetSafeParent():FindFirstChild("holder")
		holder:Destroy()
	end

	local title = data.Name or "Window"
	local icon = data.Icon or "zap"
	local close
	
	if typeof(data.CloseKeybind) == "string" then
		if Util.isValidKeyCode(data.CloseKeybind) then
			close = Enum.KeyCode[data.CloseKeybind]
		else
			close = Enum.KeyCode.RightShift
			warn(`Window: "{data.CloseKeybind}" is not a valid KeyCode, ask the script creator to change it! \nAs to not error, the keybind for hiding the UI is now RightShift.`)
		end

	elseif typeof(data.CloseKeybind) == "EnumItem" then
		close = data.CloseKeybind

	else
		close = Enum.KeyCode.RightShift
		warn(`Window: {data.CloseKeybind} is not a valid EnumItem or KeyCode, ask the script creator to change it! \nAs to not error, the keybind for hiding the UI is now RightShift.`)
	end

	local self = setmetatable({}, Window) :: WindowType

	local function makeDraggable(topbar: Frame)
		local dragging = false
		local dragStart: Vector3
		local startPos: UDim2

		_G.conns["InputBegan1"] = topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = self.Main.Position
			end
		end)

		_G.conns["InputChanged1"] = UIS.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				self.Main.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)

		_G.conns["InputEnded1"] = UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end

	local holder = Instance.new("Folder")
	holder.Name = "holder"
	holder.Parent = Util.GetSafeParent()

	local gui = Instance.new("ScreenGui")
	gui.Name = title
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = holder

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(700, 350)
	main.AutomaticSize = Enum.AutomaticSize.None
	main.Position = UDim2.fromOffset(200, 100)
	main.BackgroundColor3 = GetTheme().bg
	main.BorderSizePixel = 0
	main.Parent = gui

	Util.corner(main, 12)
	Util.stroke(main, GetTheme().border, 0)

	local header = Instance.new("Frame")
	header.Name = "Topbar"
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = GetTheme().header
	header.Parent = main
	Util.corner(header, 12)

	self.Header = header

	Icon(header, icon, 16, GetTheme().blue).Position = UDim2.fromOffset(16, 14)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.fromOffset(40, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Michroma
	label.Text = title
	label.TextColor3 = GetTheme().text
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	makeDraggable(header)

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 1, -44)
	body.AutomaticSize = Enum.AutomaticSize.None
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.Position = UDim2.fromOffset(0, 44)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 10
	body.ScrollBarImageColor3 = GetTheme().faint
	body.CanvasSize = UDim2.fromScale(0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.Parent = main

	local handle = Instance.new("Frame")
	handle.Name = "ResizeHandle"
	handle.Size = UDim2.fromOffset(16, 16)
	handle.AnchorPoint = Vector2.new(1, 1)
	handle.Position = UDim2.new(1, 5, 1, 5)
	handle.BackgroundColor3 = GetTheme().border
	handle.BorderSizePixel = 0
	handle.Parent = main
	Util.corner(handle, 4)

	self.Gui = gui
	self.Main = main
	self.Body = body
	self.Visible = true
	self.Minimized = false

	self.PrevSize = self.Main.Size

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "Close"
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.Position = UDim2.new(1, -24, 0.5, 0)
	closeButton.BackgroundColor3 = GetTheme().pill
	closeButton.Text = "x"
	closeButton.TextColor3 = GetTheme().text
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.Michroma
	closeButton.Parent = header
	Util.corner(closeButton, 6)

	_G.conns["MouseButton1Click1"] = closeButton.MouseButton1Click:Connect(function()
		self:ToggleUi(false)
		self.Visible = false
	end)

	_G.conns["InputBegan2"] = UIS.InputBegan:Connect(function(input)
		if input.KeyCode == close then
			if self.Visible then
				self:ToggleUi(false)
				self.Visible = false
			else
				self:ToggleUi(true)
				self.Visible = true
			end
		end
	end)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "Minimize"
	minimizeButton.Size = UDim2.new(0, 24, 0, 24)
	minimizeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	minimizeButton.Position = UDim2.new(1, -60, 0.5, 0)
	minimizeButton.BackgroundColor3 = GetTheme().pill
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = GetTheme().text
	minimizeButton.TextSize = 16
	minimizeButton.Font = Enum.Font.Michroma
	minimizeButton.Parent = header
	Util.corner(minimizeButton, 6)

	_G.conns["MouseButton1Click2"] = minimizeButton.MouseButton1Click:Connect(function()
		if self.Minimized then
			self:Minimize(false)

			local tween = Util.tween(minimizeButton, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Rotation = 0
			})
			tween:Play()

			_G.conns["TweenCompleted1"] = tween.Completed:Connect(function()
				minimizeButton.Text = "-"
			end)
		else
			self:Minimize(true)

			local tween = Util.tween(minimizeButton, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Rotation = 90
			})
			tween:Play()

			_G.conns["TweenCompleted2"] = tween.Completed:Connect(function()
				minimizeButton.Text = "+"
			end)
		end
	end)

	self:_makeResizable(handle)

	_G.conns["GetPropertyChangedSignal1"] = main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_updateColumnSize()
	end)

	self:_updateColumnSize()

	self.NumberOfColumns = 0
	
	local notifHolder = Instance.new("Frame")
	notifHolder.Name = "NotificationHolder"
	notifHolder.Parent = gui
	notifHolder.AnchorPoint = Vector2.new(1, 0.5)
	notifHolder.Position = UDim2.fromScale(1, 0.5)
	notifHolder.Size = UDim2.new(0, 300, 1, 0)
	notifHolder.BackgroundTransparency = 1
	notifHolder.ZIndex = 1000
	
	local notifPad = Instance.new("UIPadding")
	notifPad.PaddingBottom = UDim.new(0, 2)
	notifPad.PaddingLeft = UDim.new(0, 8)
	notifPad.PaddingRight = UDim.new(0, 8)
	notifPad.PaddingTop = UDim.new(0, 0)
	notifPad.Parent = notifHolder
	
	self.NotificationHolder = notifHolder
	self._notifications = {}

	return self
end

function Window:_makeResizable(handle: Frame)
	local resizing = false
	local startPos: Vector2
	local startSize: Vector2

	_G.conns["InputBegan3"] = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startPos = UIS:GetMouseLocation()
			startSize = self.Main.AbsoluteSize
		end
	end)

	_G.conns["InputChanged2"] = UIS.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = UIS:GetMouseLocation() - startPos
			local newW = math.clamp(startSize.X + delta.X, 300, 2000)
			local newH = math.clamp(startSize.Y + delta.Y, 200, 2000)

			self.Main.Size = UDim2.fromOffset(newW, newH)
			self:_updateColumnSize()
		end
	end)

	_G.conns["InputEnded2"] = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
end

function Window:_updateColumnSize()
	local columns = {}
	for _, child in ipairs(self.Body:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(columns, child)
		end
	end

	if #columns == 0 then return end

	local bodyWidth = self.Body.AbsoluteSize.X
	local padding = 8
	local minColWidth = 175

	local maxCols = math.max(1, math.floor((bodyWidth - padding) / (minColWidth + padding)))
	local colsPerRow = math.clamp(maxCols, 1, #columns)
	local colWidth = (bodyWidth - padding * (colsPerRow + 1)) / colsPerRow

	for _, col in ipairs(columns) do
		col.Size = UDim2.new(0, colWidth, col.Size.Y.Scale, col.Size.Y.Offset)
	end

	local colHeights = {}
	for _, col in ipairs(columns) do
		local layout = col:FindFirstChildOfClass("UIListLayout")
		if layout then
			colHeights[col] = layout.AbsoluteContentSize.Y + 20
		else
			local h = 0
			for _, c in ipairs(col:GetChildren()) do
				if c:IsA("GuiObject") then
					h += c.AbsoluteSize.Y
				end
			end
			colHeights[col] = h + 20
		end
	end

	local colY = table.create(colsPerRow, padding)

	for i, col in ipairs(columns) do
		local slot = ((i - 1) % colsPerRow) + 1
		local x = padding + (slot - 1) * (colWidth + padding)
		local h = colHeights[col]
		local y = colY[slot]

		Util.tween(col, TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0, colWidth, 0, h)
		}):Play()

		Util.tween(col, TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0, x, 0, y)
		}):Play()

		colY[slot] += h + padding
	end
end

function Window:RefreshTheme()
	local t = GetTheme()

	self.Main.BackgroundColor3 = t.bg
	self.Main.UIStroke.Color = t.border

	for _, obj: any in ipairs(self.Main:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			obj.TextColor3 = t.text
		elseif obj:IsA("Frame") then
			if obj.Name == "Topbar" then
				obj.BackgroundColor3 = t.header
			end
		end
	end
end

function Window:Minimize(minimized)
	if minimized then
		self.Body.Visible = false
		self.Minimized = true
		local handle = self.Main:FindFirstChild("ResizeHandle")
		if handle then handle.Visible = false end

		self.PrevSize = self.Main.Size
		local targetXOffset = self.Main.Size.X.Offset - (self.Main.Size.X.Offset*(4/7))

		if targetXOffset < 250 then
			targetXOffset = 250
		end

		Util.tween(self.Main, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.new(self.Main.Size.X.Scale, targetXOffset, 0, self.Header.Size.Y.Offset)
		}):Play()
	else
		self.Body.Visible = true
		self.Minimized = false
		local handle = self.Main:FindFirstChild("ResizeHandle")
		if handle then handle.Visible = true end

		if self.PrevSize then
			Util.tween(self.Main, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Size = self.PrevSize
			}):Play()
		end
	end
end

function Window:ToggleUi(toggled)
	if toggled then
		self.Main.Visible = true
		self.Visible = true
	else
		self.Main.Visible = false
		self.Visible = false
	end
end

local function getNotifColor(nType)
	if nType == "error" then
		return {
			bg = Color3.fromRGB(181, 40, 45);
			header = Color3.fromRGB(233, 79, 84);
			text = Color3.fromRGB(251, 205, 207);
			faint = Color3.fromRGB(248, 154, 157);
			icon = Color3.fromRGB(67, 13, 15)
		}
	elseif nType == "warning" then
		return {
			bg = Color3.fromRGB(182, 140, 20);
			header = Color3.fromRGB(243, 187, 27);
			text = Color3.fromRGB(12, 9, 0);
			faint = Color3.fromRGB(35, 22, 5);
			icon = Color3.fromRGB(120, 93, 13)
		}
	elseif nType == "success" then
		return {
			bg = Color3.fromRGB(45, 145, 45);
			header = Color3.fromRGB(61, 193, 60);
			text = Color3.fromRGB(206, 239, 206);
			faint = Color3.fromRGB(157, 224, 157);
			icon = Color3.fromRGB(30, 97, 30)
		}
	else
		return {
			bg = GetTheme().bg;
			header = GetTheme().header;
			text = GetTheme().text;
			faint = GetTheme().faint;
			icon = GetTheme().blue
		}
	end
end

function Window:Notify(data: NotificationData)
	local title = data.Title
	local msg = data.Message
	local icon = data.Icon or ""
	local duration = data.Duration or 3
	
	local notifHolder = self.NotificationHolder or self.Gui:FindFirstChild("NotificationHolder") :: Frame
	if not notifHolder then
		error("notification holder missing")
		return
	end
	
	local colors = getNotifColor(data.Type)
	
	local notif = Instance.new("Frame")
	notif.AnchorPoint = Vector2.new(1, 1)
	notif.AutomaticSize = Enum.AutomaticSize.Y
	notif.BackgroundColor3 = colors.bg
	notif.BorderSizePixel = 0
	notif.Name = "Notification"
	notif.Parent = notifHolder
	notif.Position = UDim2.new(1, 0, 1, 200)
	notif.Size = UDim2.new(1, 0, 0, 80)
	notif.ClipsDescendants = true
	Util.corner(notif, 10)
	
	if icon ~= "" then
		local ic = Icon(notif, icon, 18, colors.icon)
		ic.Position = UDim2.fromOffset(9, 9)
	end
	
	local titleLable = Instance.new("TextLabel")
	titleLable.BackgroundColor3 = colors.header
	titleLable.BackgroundTransparency = 0
	titleLable.Name = "TitleLabel"
	titleLable.Parent = notif
	titleLable.Position = UDim2.fromScale(0, 0)
	titleLable.Size = UDim2.fromScale(1, 0.36)
	titleLable.Font = Enum.Font.Michroma
	titleLable.Text = title
	titleLable.TextColor3 = colors.text
	titleLable.TextSize = 14
	titleLable.TextXAlignment = Enum.TextXAlignment.Left
	titleLable.TextYAlignment = Enum.TextYAlignment.Center
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.Parent = titleLable
	titleCorner.BottomLeftRadius = UDim.new(0, 0)
	titleCorner.BottomRightRadius = UDim.new(0, 0)
	titleCorner.TopLeftRadius = UDim.new(0, 8)
	titleCorner.TopRightRadius = UDim.new(0, 8)
	
	local titlePadding = Instance.new("UIPadding")
	titlePadding.Parent = titleLable
	titlePadding.PaddingBottom = UDim.new(0, 0)
	titlePadding.PaddingLeft = UDim.new(0, 33)
	titlePadding.PaddingRight = UDim.new(0, 15)
	titlePadding.PaddingTop = UDim.new(0, 0)
	
	local msgLabel = Instance.new("TextLabel")
	msgLabel.AutomaticSize = Enum.AutomaticSize.Y
	msgLabel.BackgroundTransparency = 1
	msgLabel.Name = "Message"
	msgLabel.Parent = notif
	msgLabel.Position = UDim2.fromScale(0, 0.36)
	msgLabel.Size = UDim2.fromScale(1, 0.64)
	msgLabel.Font = Enum.Font.Michroma
	msgLabel.Text = msg
	msgLabel.TextColor3 = colors.faint
	msgLabel.TextSize = 12
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment = Enum.TextYAlignment.Top
	
	local msgPad = Instance.new("UIPadding")
	msgPad.Parent = msgLabel
	msgPad.PaddingBottom = UDim.new(0, 8)
	msgPad.PaddingLeft = UDim.new(0, 15)
	msgPad.PaddingRight = UDim.new(0, 15)
	msgPad.PaddingTop = UDim.new(0, 8)
	
	Util.tween(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(1, 1)
	}):Play()
	
	table.insert(self._notifications, notif)
	task.defer(function()
		notif:SetAttribute("Height", notif.AbsoluteSize.Y)

		self:_reorderNotifications()
	end)
	
	task.delay(duration, function()
		self:_removeNotification(notif)
	end)
end

function Window:_reorderNotifications()
	local padding = 8
	local yOff = -padding
	
	for i = #self._notifications, 1, -1 do
		local notif = self._notifications[i]
		
		if notif:GetAttribute("Removing") then
			continue
		end
		
		local height = notif:GetAttribute("Height") or 80
		local targetPos = UDim2.new(1, 0, 1, yOff)
		
		Util.tween(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = targetPos
		}):Play()
		
		yOff -= (height + padding)
	end
end

function Window:_removeNotification(notif: Frame)
	if notif:GetAttribute("Removing") then return end
	notif:SetAttribute("Removing", true)
	
	local tween = Util.tween(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(2, 60, notif.Position.Y.Scale, notif.Position.Y.Offset)
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		for i, n in ipairs(self._notifications) do
			if n == notif then
				table.remove(self._notifications, i)
				break
			end
		end
		
		notif:Destroy()
		
		task.defer(function()
			self:_reorderNotifications()
		end)
	end)
end

-- \\ Columns
export type ColumnType = {
	Frame: Frame;
	Window: WindowType;

	addSection: (self: ColumnType, data: SectionData) -> SectionType;
	addToggle: (self: ColumnType, data: ToggleData) -> ToggleType;
	addSlider: (self: ColumnType, data: SliderData) -> SliderType;
	addPill: (self: ColumnType, data: PillData) -> PillType;
	addPlayerList: (self: ColumnType) -> PlayerListType;
}

function Column.new(parent: Instance, window: WindowType): ColumnType
	local self = setmetatable({}, Column) :: ColumnType

	self.Window = window
	local order = self.Window.NumberOfColumns + 1

	local col = Instance.new("Frame")
	col.Name = "Column" .. tostring(order)
	col.Size = UDim2.fromOffset(208, 0)
	col.AutomaticSize = Enum.AutomaticSize.None
	col.ClipsDescendants = true
	col.BackgroundColor3 = GetTheme().colbg
	col.BorderSizePixel = 0
	col.LayoutOrder = order
	col.Parent = parent

	Util.corner(col, 8)
	Util.stroke(col, GetTheme().border, 0.25)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = col

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = col

	self.Frame = col

	self.Window.NumberOfColumns += 1

	return self
end

function Column:ReorderChildren(sortFunc)
	local frame = self.Frame
	local children = {}

	for _, child: any in ipairs(frame:GetChildren()) do
		if #child:GetChildren() ~= 2 then
			if child:IsA("Frame") then
				table.insert(children, child)
			end
		end
	end

	table.sort(children, sortFunc or function(a: any, b)
		return a.Name < b.Name
	end)

	for i, child: any in ipairs(children) do
		child.LayoutOrder = i
	end

	task.defer(function()
		self.Window:_updateColumnSize()
	end)
end

function Window:AddColumn()
	local col = Column.new(self.Body, self)
	self:_updateColumnSize()
	return col
end

-- // Sections
export type SectionType = {
	Frame: Frame;
}

export type SectionData = {
	Name: string;
	Icon: string?;
	First: boolean?;
	LayoutOrder: number?;
}

function Section.new(parent: Instance, data: SectionData): SectionType
	local name = data.Name or "Section"
	local iconName = data.Icon or ""
	local first = data.First or false
	local layoutOrder = (first and 0 or data.LayoutOrder) or 0

	local self = setmetatable({}, Section) :: SectionType

	local frame = Instance.new("Frame")
	frame.LayoutOrder = layoutOrder
	frame.Name = name or "Section"
	frame.Size = UDim2.new(1, 0, 0, first and 20 or 28)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local xo = 4
	if iconName then
		Icon(frame, iconName, 14, GetTheme().faint).Position = UDim2.new(0, 3, 1, -15)
		xo = 22
	end

	local label = Instance.new("TextLabel")
	label.Name = "SectionTitle"
	label.Size = UDim2.new(1, -xo, 0, 14)
	label.Position = UDim2.new(0, xo, 1, -14)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Michroma
	label.Text = string.upper(name)
	label.TextColor3 = GetTheme().faint
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	self.label = label

	self.Frame = frame
	return self
end

function Section:Update(newName: string)
	if newName and newName ~= "" then
		self.label.Text = string.upper(newName)
		self.Frame.Name = newName
	end
end


function Column:AddSection(data: SectionData)
	return Section.new(self.Frame, data)
end

-- \\ Toggles
export type ToggleType = {
	Arrow: ImageButton,
	Window: WindowType,
	Dropdown: Frame,
	DropdownOpen: boolean,
	Frame: Frame,

	_updateArrowVisibility: () -> (),
	AddOption: (self: ToggleType, data: ToggleData) -> (),
	AddComponent: (self: ToggleType, data: ToggleData) -> (),
}

export type ToggleData = {
	Name: string,
	Default: boolean,
	Callback: (boolean) -> (),
	Style: string?,
	LayoutOrder: number?,
}

local RunService = game:GetService("RunService")

function Toggle.new(window: WindowType, parent: Instance, data: ToggleData): ToggleType
	local name: string = data.Name or "Toggle"
	local default: boolean = data.Default or false
	local layoutOrder: number = data.LayoutOrder or 1
	local cb: (boolean) -> () = data.Callback or function() end

	local self = setmetatable({}, Toggle) :: ToggleType
	self.Window = window

	local f = Instance.new("Frame")
	f.Name = name
	f.LayoutOrder = layoutOrder
	f.Size = UDim2.new(1, 0, 0, 34)
	f.BackgroundColor3 = GetTheme().colbg
	f.BackgroundTransparency = 0
	f.Parent = parent
	Util.corner(f, 6)

	_G.conns["MouseEnter1"] = f.MouseEnter:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().hover
		}):Play()
	end)

	_G.conns["MouseLeave1"] = f.MouseLeave:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().colbg
		}):Play()
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.new(1, -54, 0, 0)
	lbl.Position = UDim2.fromOffset(10, 17)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Michroma
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local sw = Instance.new("TextButton")
	sw.Name = "Switch"
	sw.Size = UDim2.fromOffset(34, 18)
	sw.Position = UDim2.new(1, -42, 0, 7)
	sw.BackgroundColor3 = default and GetTheme().blue or GetTheme().trackOff
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.Parent = f
	Util.corner(sw, 9)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = GetTheme().knob
	knob.BorderSizePixel = 0
	knob.Parent = sw
	Util.corner(knob, 7)

	local state = default

	_G.conns["MouseButton1Click3"] = sw.MouseButton1Click:Connect(function()
		state = not state

		Util.tween(sw, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundColor3 = state and GetTheme().blue or GetTheme().trackOff
		}):Play()
		Util.tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = state
				and UDim2.new(1, -16, 0.5, -7)
				or UDim2.new(0, 2, 0.5, -7)
		}):Play()

		cb(state)
	end)

	local arrow = Instance.new("ImageButton")
	arrow.Size = UDim2.fromOffset(16, 16)
	arrow.Name = "DropdownArrow"
	arrow.Position = UDim2.new(1, -(sw.AbsoluteSize.X + 14), 0, 8)
	arrow.AnchorPoint = Vector2.new(1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6031094670"
	arrow.Rotation = 0
	arrow.Parent = f

	self.Arrow = arrow

	local drop = Instance.new("Frame")
	drop.BackgroundTransparency = 0
	drop.Name = "Dropdown"
	drop.BorderSizePixel = 0
	drop.BackgroundColor3 = GetTheme().bg
	drop.ZIndex = 1
	drop.Position = UDim2.new(0, 4, 0, 34)
	drop.Size = UDim2.new(1, -8, 0, 0)
	drop.ClipsDescendants = true
	drop.Parent = f

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = drop

	local dropPadding = Instance.new("UIPadding")
	dropPadding.PaddingTop = UDim.new(0, 4)
	dropPadding.PaddingBottom = UDim.new(0, 4)
	dropPadding.PaddingLeft = UDim.new(0, 4)
	dropPadding.PaddingRight = UDim.new(0, 4)
	dropPadding.Parent = drop
	Util.corner(drop, 8)

	self.Dropdown = drop
	self.DropdownOpen = false

	_G.conns["MouseButton1Click4"] = self.Arrow.MouseButton1Click:Connect(function()
		self.DropdownOpen = not self.DropdownOpen
		self.Dropdown.Visible = true

		Util.tween(self.Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = self.DropdownOpen and -90 or 0
		}):Play()

		local layout = self.Dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local targetHeight = self.DropdownOpen and (layout.AbsoluteContentSize.Y + 8) or 0

		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -8, 0, targetHeight)
		}):Play()

		local baseHeight = self.DropdownOpen and 38 or 34
		
		local tween = Util.tween(self.Frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, baseHeight + targetHeight)
		})
		tween:Play()
		
		local startColSize = parent.Size
		local baseColHeight = startColSize.Y.Offset
		Util.tween(parent, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, startColSize.X.Offset, 0, (self.DropdownOpen and baseColHeight + (layout.AbsoluteContentSize.Y + 8) or baseColHeight - (layout.AbsoluteContentSize.Y + 8)))
		}):Play()
		
		_G.conns["TweenCompleted3"] = tween.Completed:Connect(function()
			if not self.DropdownOpen then
				self.Dropdown.Visible = false
			end
			self.Window:_updateColumnSize()
		end)
	end)

	function self._updateArrowVisibility()
		local hasChildren = #drop:GetChildren() > 3
		self.Arrow.Visible = hasChildren
	end

	self._updateArrowVisibility()
	self.Frame = f
	return self
end

function Toggle:AddOption(data)
	local style = data.Style
	if not style then
		warn("Toggle:AddOption missing Style")
		return
	end

	local class: any = ComponentFactory[style]
	if not class then
		warn("Unknown component style:", style)
		return
	end

	local newComponent: any = class.new(self.Window, self.Dropdown, data)
	local dropdown = self.Dropdown :: Frame

	if self.DropdownOpen then
		local dropdownLayout = dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local newHeight = dropdownLayout.AbsoluteContentSize.Y
		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, newHeight)
		}):Play()
	end

	self:_updateArrowVisibility()

	task.defer(function()
		self.Window:_updateColumnSize()
	end)
end

function Column:AddToggle(data: ToggleData)
	return Toggle.new(self.Window, self.Frame, data)
end

-- // Sliders
export type SliderData = {
	Name: string,
	Min: number,
	Max: number,
	Step: number,
	Default: number,
	LayoutOrder: number?,
	Callback: (number) -> (),
	Style: string?,
}

export type SliderType = {
	Window: WindowType,
	Frame: Frame,
	Arrow: ImageButton,
	Dropdown: Frame,
	DropdownOpen: boolean,

	_min: number,
	_max: number,
	_snap: number,
	_lastVal: number,
	_cb: (number) -> (),

	_fill: Frame,
	_knob: Frame,
	_bar: Frame,
	_val: TextLabel,

	_updateArrowVisibility: () -> (),
	SetValue: (self: SliderType, v: number) -> (),
	AddOption: (self: SliderType, data: SliderData) -> (),
}

function Slider.new(window: WindowType, parent: Instance, data: SliderData): SliderType
	local name: string = data.Name or "Slider"
	local min: number = data.Min or 0
	local max: number = data.Max or 100
	local snap: number = data.Step or 1
	local default: number = data.Default or min
	local layoutOrder: number = data.LayoutOrder or 1
	local cb: (number) -> () = data.Callback or function() end

	local self = setmetatable({}, Slider) :: SliderType
	self.Window = window

	self._min = min
	self._max = max
	self._snap = snap
	self._cb = cb
	self._lastVal = default

	local f = Instance.new("Frame")
	f.Name = name
	f.LayoutOrder = layoutOrder
	f.Size = UDim2.new(1, 0, 0, 46)
	f.BackgroundColor3 = GetTheme().colbg
	f.BackgroundTransparency = 0
	f.Parent = parent
	Util.corner(f, 6)

	_G.conns["MouseEnter2"] = f.MouseEnter:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().hover
		}):Play()
	end)

	_G.conns["MouseLeave2"] = f.MouseLeave:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().colbg
		}):Play()
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.new(1, -20, 0, 18)
	lbl.Position = UDim2.fromOffset(10, 7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Michroma
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local val = Instance.new("TextBox")
	val.Name = "Value"
	val.AutomaticSize = Enum.AutomaticSize.X
	val.AnchorPoint = Vector2.new(1, 0)
	val.Size = UDim2.fromOffset(0, 18)
	val.Position = UDim2.new(1, -8, 0, 7)
	val.BackgroundTransparency = 1
	val.Font = Enum.Font.Michroma
	val.Text = tostring(default)
	val.TextColor3 = GetTheme().text
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = f
	val.ClearTextOnFocus = false

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -20, 0, 4)
	bar.Position = UDim2.fromOffset(10, 30)
	bar.BackgroundColor3 = GetTheme().trackOff
	bar.BorderSizePixel = 0
	bar.Parent = f
	Util.corner(bar, 2)

	local rel = (default - min) / (max - min)

	local arrow = Instance.new("ImageButton")
	arrow.Name = "DropdownArrow"
	arrow.Size = UDim2.fromOffset(16, 16)
	arrow.Position = UDim2.fromScale(0, 0)
	arrow.AnchorPoint = Vector2.new(1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6031094670"
	arrow.Rotation = 0
	arrow.Parent = f

	self.Arrow = arrow

	local drop = Instance.new("Frame")
	drop.BackgroundTransparency = 0
	drop.Name = "Dropdown"
	drop.BorderSizePixel = 0
	drop.BackgroundColor3 = GetTheme().bg
	drop.ZIndex = 1
	drop.Position = UDim2.new(0, 4, 0, 40)
	drop.Size = UDim2.new(1, -8, 0, 0)
	drop.ClipsDescendants = true
	drop.Parent = f

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = drop

	local dropPadding = Instance.new("UIPadding")
	dropPadding.PaddingTop = UDim.new(0, 4)
	dropPadding.PaddingBottom = UDim.new(0, 4)
	dropPadding.PaddingLeft = UDim.new(0, 4)
	dropPadding.PaddingRight = UDim.new(0, 4)
	dropPadding.Parent = drop
	Util.corner(drop, 8)

	self.Dropdown = drop
	self.DropdownOpen = false

	_G.conns["MouseButton1Click5"] = self.Arrow.MouseButton1Click:Connect(function()
		self.DropdownOpen = not self.DropdownOpen
		self.Dropdown.Visible = true

		Util.tween(self.Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = self.DropdownOpen and -90 or 0
		}):Play()

		local layout = self.Dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local targetHeight = self.DropdownOpen and (layout.AbsoluteContentSize.Y + 8) or 0

		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -8, 0, targetHeight)
		}):Play()

		local baseHeight = self.DropdownOpen and 44 or 46

		local tween = Util.tween(self.Frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, baseHeight + targetHeight)
		})
		tween:Play()

		local startColSize = parent.Size
		local baseColHeight = startColSize.Y.Offset
		Util.tween(parent, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, startColSize.X.Offset, 0, (self.DropdownOpen and baseColHeight + (layout.AbsoluteContentSize.Y + 8) or baseColHeight - (layout.AbsoluteContentSize.Y + 8)))
		}):Play()

		_G.conns["TweenCompleted4"] = tween.Completed:Connect(function()
			if not self.DropdownOpen then
				self.Dropdown.Visible = false
			end
			self.Window:_updateColumnSize()
		end)
	end)

	function self._updateArrowVisibility()
		local hasChildren = #drop:GetChildren() > 3
		self.Arrow.Visible = hasChildren
	end

	function self:_updateArrowPosition()
		local valWidth = val.AbsoluteSize.X
		arrow.Position = UDim2.new(1, -(valWidth + 18), 0, 8)
	end

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(rel, 0, 1, 0)
	fill.BackgroundColor3 = GetTheme().blue
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Util.corner(fill, 2)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.ZIndex = 2
	knob.Size = UDim2.fromOffset(12, 12)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(rel, 0, 0.5, 0)
	knob.BackgroundColor3 = GetTheme().knob
	knob.BorderSizePixel = 0
	knob.Parent = bar
	Util.corner(knob, 6)

	self._fill = fill
	self._knob = knob
	self._val = val
	self._bar = bar

	local dragging = false

	local function setX(x: number)
		local r = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)

		local raw = min + (max - min) * r
		local v = math.floor(raw / snap + 0.5) * snap

		v = math.clamp(v, min, max)
		local sr = (v - min) / (max - min)

		Util.tween(fill, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(sr, 0, 1, 0)
		}):Play()
		
		Util.tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(sr, 0, 0.5, 0)
		}):Play()

		val.Text = tostring(v)
		self._lastVal = v

		self:_updateArrowPosition()

		cb(v)
	end

	_G.conns["InputBegan4"] = bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			local leftSidePos = val.Position.X.Offset - (val.AnchorPoint.X * val.AbsoluteSize.X)
			dragging = true
			setX(i.Position.X)
		end
	end)

	_G.conns["InputBegan5"] = knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	_G.conns["InputEnded3"] = UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	_G.conns["InputChanged3"] = UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			setX(i.Position.X)
		end
	end)

	_G.conns["Focused1"] = val.Focused:Connect(function()
		val:CaptureFocus()
		val.CursorPosition = #val.Text + 1
		val.SelectionStart = 1
	end)
	
	_G.conns["GetPropertyChangedSignal2"] = val:GetPropertyChangedSignal("Text"):Connect(function()
		self._updateArrowPosition()
		val.Text = val.Text:gsub("[^%d%-%.]", "")
	end)
	
	_G.conns["FocusLost1"] = val.FocusLost:Connect(function()
		local v = tonumber(val.Text)

		if v then
			self:SetValue(v)
		else
			val.Text = tostring(self._lastVal)
		end
	end)

	self._updateArrowVisibility()
	self._updateArrowPosition()

	self.Frame = f
	return self
end

function Slider:SetValue(v: number)
	local min = self._min
	local max = self._max
	local snap = self._snap

	v = math.clamp(v, min, max)
	v = math.floor(v / snap + 0.5) * snap

	local sr = (v - min) / (max - min)

	Util.tween(self._fill, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(sr, 0, 1, 0)
	}):Play()

	Util.tween(self._knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(sr, 0, 0.5, 0)
	}):Play()
	
	self._val.Text = tostring(v)
	self._lastVal = v

	self._cb(v)
end

function Slider:AddOption(data)
	local style = data.Style
	if not style then
		warn("Toggle:AddComponent missing Style")
		return
	end

	local class: any = ComponentFactory[style]
	if not class then
		warn("Unknown component style:", style)
		return
	end

	local newComponent: any = class.new(self.Window, self.Dropdown, data)
	local dropdown = self.Dropdown :: Frame

	if self.DropdownOpen then
		local dropdownLayout = dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local newHeight = dropdownLayout.AbsoluteContentSize.Y
		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, newHeight)
		}):Play()
	end

	self:_updateArrowVisibility()

	task.defer(function()
		self.Window:_updateColumnSize()
	end)

	return newComponent
end

function Column:AddSlider(data: SliderData)
	return Slider.new(self.Window, self.Frame, data)
end

-- \\ Pills ( Buttons )
export type PillData = {
	Name: string,
	Icon: string?,
	LayoutOrder: number?,
	Callback: () -> (),
}

export type PillType = {
	Window: WindowType,
	Frame: TextButton,
}

function Pill.new(window: WindowType, parent: Instance, data: PillData): PillType
	local name: string = data.Name or "Pill"
	local iconName: string? = data.Icon or ""
	local layoutOrder: number = data.LayoutOrder or 1
	local cb: () -> () = data.Callback or function() end

	local self = setmetatable({}, Pill) :: PillType
	self.Window = window

	local b = Instance.new("TextButton")
	b.Name = name or "Button"
	b.LayoutOrder = layoutOrder or 1
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = GetTheme().pill
	b.Text = ""
	b.AutoButtonColor = false
	b.Parent = parent
	Util.corner(b, 6)
	Util.stroke(b, GetTheme().pillBrd, 0)

	if iconName then
		Icon(b, iconName, 14, GetTheme().dim).Position = UDim2.new(0, 12, 0.5, -7)
	end

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -40, 1, 0)
	l.Position = UDim2.fromOffset(iconName and 34 or 14, 0)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Michroma
	l.Text = name
	l.TextColor3 = GetTheme().text
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = b

	_G.conns["MouseEnter3"] = b.MouseEnter:Connect(function()
		Util.tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().pillHover
		}):Play()
	end)

	_G.conns["MouseLeave3"] = b.MouseLeave:Connect(function()
		Util.tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().pill
		}):Play()
	end)

	_G.conns["MouseButton1Click6"] = b.MouseButton1Click:Connect(function()
		cb()
	end)

	self.Frame = b
	return self
end

function Column:AddPill(data: PillData)
	return Pill.new(self.Window, self.Frame, data)
end

--// Player Lists
export type PlayerListType = {
	Frame: Frame,
	List: ScrollingFrame,
	Window: WindowType,
	Plrs: { [Frame]: Player },

	_refresh: (self: PlayerListType) -> (),
	AddMiniButton: (self: PlayerListType, cfg: MiniButtonConfig) -> (),
}

export type MiniButtonConfig = {
	Text: string,
	XOffset: number,
	Callback: (Player) -> (),
}

function PlayerList.new(window: WindowType, parent: Instance, table: {}?): PlayerListType
	local self = setmetatable({}, PlayerList) :: PlayerListType
	self.Window = window

	local wrap = Instance.new("Frame")
	wrap.LayoutOrder = 0
	wrap.Name = "PlayerListHolder"
	wrap.Size = UDim2.new(1, 0, 0, 190)
	wrap.BackgroundColor3 = GetTheme().bg
	wrap.BackgroundTransparency = 0.4
	wrap.BorderSizePixel = 0
	wrap.Parent = parent
	Util.corner(wrap, 6)

	local list = Instance.new("ScrollingFrame")
	list.Name = "PlayerList"
	list.Size = UDim2.new(1, -4, 1, -4)
	list.Position = UDim2.fromOffset(2, 2)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = GetTheme().border
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = wrap

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.Name
	layout.Parent = list

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 2)
	pad.Parent = list

	self.Frame = wrap
	self.List = list
	self.Plrs = {}
	self.MiniButtonConfigs = {}

	self:_refresh()

	_G.conns["PlayerAdded1"] = Players.PlayerAdded:Connect(function()
		self:_refresh()
	end)

	_G.conns["PlayerRemoving1"] = Players.PlayerRemoving:Connect(function()
		self:_refresh()
	end)

	return self
end

function PlayerList:_refresh()
	for _, child: any in ipairs(self.List:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	self.Plrs = {}

	for _, plr: Player in ipairs(Players:GetPlayers()) do
		if plr then
			local row: Frame = Instance.new("Frame") :: Frame
			row.Name = `{plr.Name}PlayerListFrame`
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundColor3 = GetTheme().hover
			row.BackgroundTransparency = 1
			row.Parent = self.List
			Util.corner(row, 5)

			self.Plrs[plr] = row

			_G.conns["MouseEnter4"] = row.MouseEnter:Connect(function()
				Util.tween(row, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0
				}):Play()
			end)

			_G.conns["MouseLeave4"] = row.MouseLeave:Connect(function()
				Util.tween(row, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1
				}):Play()
			end)

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -70, 1, 0)
			name.Position = UDim2.fromOffset(8, 0)
			name.BackgroundTransparency = 1
			name.Font = Enum.Font.Michroma
			name.Text = plr.DisplayName
			name.TextColor3 = GetTheme().text
			name.TextSize = 12
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = row

			for _, cfg in ipairs(self.MiniButtonConfigs) do
				MiniButton.new(row, plr, cfg)
			end
		end
	end
end

function Column:AddPlayerList()
	return PlayerList.new(self.Window, self.Frame, {})
end

-- \\ Player List Mini Buttons
function MiniButton.new(parent: Instance, plr: Player, cfg: MiniButtonConfig)
	local b = Instance.new("TextButton")
	b.Name = cfg.Text or "PlayerListMiniButton"
	b.Size = UDim2.fromOffset(30, 22)
	b.Position = UDim2.new(1, cfg.XOffset, 0.5, -11)
	b.BackgroundColor3 = GetTheme().pill
	b.Text = cfg.Text
	b.Font = Enum.Font.Michroma
	b.TextSize = 10
	b.TextColor3 = GetTheme().text
	b.AutoButtonColor = true
	b.Parent = parent

	Util.corner(b, 5)
	Util.stroke(b, GetTheme().pillBrd, 0.3)

	_G.conns["MouseEnter5"] = b.MouseEnter:Connect(function()
		Util.tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().hover
		}):Play()
	end)

	_G.conns["MouseLeave5"] = b.MouseLeave:Connect(function()
		Util.tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().pill
		}):Play()
	end)

	_G.conns["MouseButton1Click7"] = b.MouseButton1Click:Connect(function()
		cfg.Callback(plr)
	end)

	local self = setmetatable({}, MiniButton)
	self.Button = b
	return self
end

function PlayerList:AddMiniButton(cfg: MiniButtonConfig)
	table.insert(self.MiniButtonConfigs, cfg)

	for plr, row in pairs(self.Plrs) do
		MiniButton.new(row, plr, cfg)
	end
end

-- // Keybinds
export type KeybindType = {
	Frame: Frame,
	Arrow: ImageButton,
	Dropdown: Frame,
	DropdownOpen: boolean,
	Window: WindowType,
	CurrentKey: Enum.KeyCode,
	Connection: RBXScriptConnection,
	_updateArrowVisibility: (self: KeybindType) -> (),
}

export type KeybindData = {
	Name: string,
	Keybind: Enum.KeyCode | string,
	LayoutOrder: number?,
	Callback: (Enum.KeyCode) -> (),
}

function Keybind.new(window: WindowType, parent: Instance, data: KeybindData): KeybindType
	local name = data.Name or "Keybind"
	local layoutOrder = data.LayoutOrder or 1
	local defaultKey
	local cb = data.Callback or function() end
	
	if typeof(data.Keybind) == "string" then
		if Util.isValidKeyCode(data.Keybind) then
			defaultKey = Enum.KeyCode[data.Keybind]
		else
			defaultKey = Enum.KeyCode.F
			warn(`{name}: "{data.Keybind}" is not a valid KeyCode, ask the script creator to change it! \nAs to not error, the keybind for this action is now F`)
		end

	elseif typeof(data.Keybind) == "EnumItem" then
		defaultKey = data.Keybind

	else
		defaultKey = Enum.KeyCode.F
		warn(`{name}: {data.Keybind} is not a valid EnumItem or KeyCode, ask the script creator to change it! \nAs to not error, the keybind for this action is now F`)
	end

	local self = setmetatable({}, Keybind) :: KeybindType
	self.Window = window
	self.CurrentKey = defaultKey

	local f = Instance.new("Frame")
	f.Name = name
	f.LayoutOrder = layoutOrder
	f.Size = UDim2.new(1, 0, 0, 34)
	f.BackgroundColor3 = GetTheme().colbg
	f.BackgroundTransparency = 0
	f.Parent = parent
	Util.corner(f, 6)

	_G.conns["MouseEnter6"] = f.MouseEnter:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().hover
		}):Play()
	end)

	_G.conns["MouseLeave6"] = f.MouseLeave:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().colbg
		}):Play()
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.new(1, -60, 0, 34)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Michroma
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local keyBtn = Instance.new("TextButton")
	keyBtn.Name = "KeyButton"
	keyBtn.Size = UDim2.fromOffset(30, 22)
	keyBtn.Position = UDim2.new(1, -40, 0, 6)
	keyBtn.BackgroundColor3 = GetTheme().pill
	keyBtn.Text = defaultKey.Name
	keyBtn.Font = Enum.Font.Michroma
	keyBtn.TextSize = 12
	keyBtn.TextColor3 = GetTheme().text
	keyBtn.AutoButtonColor = false
	keyBtn.Parent = f
	Util.corner(keyBtn, 6)

	_G.conns["MouseEnter7"] = keyBtn.MouseEnter:Connect(function()
		Util.tween(keyBtn, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().pillHover
		}):Play()
	end)

	_G.conns["MouseLeave7"] = keyBtn.MouseLeave:Connect(function()
		Util.tween(keyBtn, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = GetTheme().pill
		}):Play()
	end)

	local arrow = Instance.new("ImageButton")
	arrow.Name = "DropdownArrow"
	arrow.Size = UDim2.fromOffset(16, 16)
	arrow.Position = UDim2.new(1, -50, 0, 8)
	arrow.AnchorPoint = Vector2.new(1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6031094670"
	arrow.Rotation = 0
	arrow.Parent = f

	self.Arrow = arrow

	local drop = Instance.new("Frame")
	drop.Name = "Dropdown"
	drop.BackgroundColor3 = GetTheme().bg
	drop.BorderSizePixel = 0
	drop.Position = UDim2.new(0, 4, 0, 34)
	drop.Size = UDim2.new(1, -8, 0, 0)
	drop.ClipsDescendants = true
	drop.Parent = f
	Util.corner(drop, 8)

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = drop

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = drop

	self.Dropdown = drop
	self.DropdownOpen = false

	_G.conns["MouseButton1Click8"] = self.Arrow.MouseButton1Click:Connect(function()
		self.DropdownOpen = not self.DropdownOpen
		self.Dropdown.Visible = true

		Util.tween(self.Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = self.DropdownOpen and -90 or 0
		}):Play()

		local layout = self.Dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local targetHeight = self.DropdownOpen and (layout.AbsoluteContentSize.Y + 8) or 0

		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -8, 0, targetHeight)
		}):Play()

		local baseHeight = self.DropdownOpen and 38 or 34

		local tween = Util.tween(self.Frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, baseHeight + targetHeight)
		})
		tween:Play()

		local startColSize = parent.Size
		local baseColHeight = startColSize.Y.Offset
		Util.tween(parent, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, startColSize.X.Offset, 0, (self.DropdownOpen and baseColHeight + (layout.AbsoluteContentSize.Y + 8) or baseColHeight - (layout.AbsoluteContentSize.Y + 8)))
		}):Play()

		_G.conns["TweenCompleted5"] = tween.Completed:Connect(function()
			if not self.DropdownOpen then
				self.Dropdown.Visible = false
			end
			self.Window:_updateColumnSize()
		end)
	end)

	local capturing = false

	_G.conns["MouseButton1Click9"] = keyBtn.MouseButton1Click:Connect(function()
		capturing = true
		keyBtn.Text = "..."
	end)

	_G.conns["InputBegan6"] = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end

		if capturing and input.KeyCode then
			capturing = false
			self.CurrentKey = input.KeyCode
			keyBtn.Text = input.KeyCode.Name
			return
		end

		if not capturing and input.KeyCode == self.CurrentKey then
			cb(self.CurrentKey)
		end
		
		if capturing and input.UserInputType == Enum.UserInputType.MouseButton1 then
			capturing = false
			keyBtn.Text = self.CurrentKey.Name
		end
	end)

	self.Connection = _G.conns["InputBegan6"]

	function self:_updateArrowVisibility()
		local count = #drop:GetChildren()
		self.Arrow.Visible = count > 3
	end

	self:_updateArrowVisibility()

	self.Frame = f
	return self
end

function Keybind:DisconnectKey()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function Keybind:AddOption(data)
	local style = data.Style
	if not style then
		warn("Toggle:AddComponent missing Style")
		return
	end

	local class: any = ComponentFactory[style]
	if not class then
		warn("Unknown component style:", style)
		return
	end

	local newComponent: any = class.new(self.Window, self.Dropdown, data)
	local dropdown = self.Dropdown :: Frame

	if self.DropdownOpen then
		local dropdownLayout = dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local newHeight = dropdownLayout.AbsoluteContentSize.Y
		Util.tween(self.Dropdown, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, newHeight)
		}):Play()
	end

	self:_updateArrowVisibility()

	task.defer(function()
		self.Window:_updateColumnSize()
	end)

	return newComponent
end

function Column:AddKeybind(data:KeybindData)
	return Keybind.new(self.Window, self.Frame, data)
end

-- \\ Options
function Option.new(parentComponent, name, cb: (boolean? | number?) -> ())
	local self = setmetatable({}, Option)

	name = name or "Option"
	cb = cb or function() end

	local f = Instance.new("Frame")
	f.Name = name or "Option"
	f.Size = UDim2.new(1, 0, 0, 28)
	f.BackgroundColor3 = GetTheme().hover
	f.BackgroundTransparency = 1
	f.Parent = parentComponent.Frame
	Util.corner(f, 6)

	_G.conns["MouseEnter7"] = f.MouseEnter:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
	end)

	_G.conns["MouseLeave7"] = f.MouseLeave:Connect(function()
		Util.tween(f, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Michroma
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	_G.conns["InputBegan7"] = f.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			cb()
		end
	end)

	self.Frame = f
	return self
end

-- // Module Export
local RebornUI = {
	Window = Window,
	Column = Column,
	Section = Section,
	Toggle = Toggle,
	Slider = Slider,
	Pill = Pill,
	PlayerList = PlayerList,
	MiniButton = MiniButton,
	Keybind = Keybind,
	Option = Option,

	Themes = Themes,
	SetTheme = SetTheme,
	GetTheme = GetTheme,
}

return RebornUI
