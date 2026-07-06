--!strict

-- \\ Globals & Services
local Players:	Players = game:GetService("Players")					:: Players
local UIS:		UserInputService = game:GetService("UserInputService")	:: UserInputService
local ts: 		TweenService = game:GetService("TweenService")			:: TweenService

local LP:		Player = Players.LocalPlayer	::	Player

-- // Themes
local Themes	=	{
	Dark		=	{
		bg			=	Color3.fromRGB(17,	17,	20	);
		header		=	Color3.fromRGB(23,	23,	27	);
		colbg		=	Color3.fromRGB(24,	24,	29	);
		border		=	Color3.fromRGB(44,	44,	51	);
		hover		=	Color3.fromRGB(34,	34,	40	);
		text		=	Color3.fromRGB(233,	233, 238);
		dim			=	Color3.fromRGB(150, 150, 160);
		faint		=	Color3.fromRGB(105, 105, 116);
		blue		=	Color3.fromRGB(72,	130, 248);
		red			=	Color3.fromRGB(220,	80,	90	);
		trackOff	=	Color3.fromRGB(58,	58,	66	);
		pill		=	Color3.fromRGB(33,	33,	40	);
		pillBrd		=	Color3.fromRGB(54,	54,	62	);
		knob		=	Color3.fromRGB(240,	240, 245);
	};
}

local CurrentTheme = Themes.Dark

local function SetTheme(name: string)
	local t	= Themes[name]
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

function Util.corner(p: Instance, r: number?)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 6)
	u.Parent = p
end

function Util.stroke(p: Instance, col: Color3, t: number?)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = 1
	s.Transparency = t or 0
	s.Parent = p
end

function Util.tween(obj: Instance, props: {[string]: any}, time: number?)
	ts:Create(
		obj,
		TweenInfo.new(time or 0.12),
		props
	)	:Play()
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

-- \\ Windows
local Window = {}
Window.__index = Window

export type WindowType = {
	Gui: ScreenGui,
	Main: Frame,
	Body: ScrollingFrame,
	
	_makeResizable: (self: WindowType, handle: Frame) -> (),
	_updateColumnSize: (self: WindowType) -> (),
	RefreshTheme: (self: WindowType) -> ()
}

function Window.new(title: string): WindowType
	local self = setmetatable({}, Window) :: WindowType
	
	local function makeDraggable(topbar: Frame)
		local dragging = false
		local dragStart: Vector3
		local startPos: UDim2

		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = self.Main.Position
			end
		end)

		UIS.InputChanged:Connect(function(input)
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

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RebornAdmin"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = LP:WaitForChild("PlayerGui")

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

	Icon(header, "zap", 16, GetTheme().blue).Position = UDim2.fromOffset(16, 14)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.fromOffset(40, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
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
	body.ScrollingDirection = Enum.ScrollingDirection.XY
	body.Position = UDim2.fromOffset(0, 44)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 10
	body.ScrollBarImageColor3 = GetTheme().faint
	body.CanvasSize = UDim2.new(0, 0, 0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.XY
	body.Parent = main

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = body

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Parent = body
	
	local handle = Instance.new("Frame")
	handle.Name = "ResizeHandle"
	handle.Size = UDim2.fromOffset(16, 16)
	handle.AnchorPoint = Vector2.new(1, 1)
	handle.Position = UDim2.new(1, 5, 1, 5)
	handle.BackgroundColor3 = GetTheme().border
	handle.BorderSizePixel = 0
	handle.Parent = main
	Util.corner(handle, 4)

	self:_makeResizable(handle)
	
	main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_updateColumnSize()
	end)

	self.Gui = gui
	self.Main = main
	self.Body = body

	return self
end

function Window:_makeResizable(handle: Frame)
	local resizing = false
	local startPos: Vector2
	local startSize: Vector2

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startPos = UIS:GetMouseLocation()
			startSize = self.Main.AbsoluteSize
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = UIS:GetMouseLocation() - startPos
			local newW = math.clamp(startSize.X + delta.X, 300, 2000)
			local newH = math.clamp(startSize.Y + delta.Y, 200, 2000)

			self.Main.Size = UDim2.fromOffset(newW, newH)
			self:_updateColumnSize()
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
end

function Window:_updateColumnSize()
	local columns = {}
	for _, child: any in ipairs(self.Body:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(columns, child)
		end
	end

	local count = #columns
	if count == 0 then return end

	local bodyWidth: number = self.Body.AbsoluteSize.X
	local bodyHeight: number = self.Body.AbsoluteSize.Y
	local padding = 12
	local minColWidth = 175

	local totalPadding = padding * (count + 1)
	local fullWidthCol = (bodyWidth - totalPadding) / count
	
	local function tweenColumnSize(col, newWidth, newHeight)
		Util.tween(col, {
			Size = UDim2.fromOffset(newWidth, newHeight)
		}, 0.15)
	end
	
	local colHeight = math.max(bodyHeight - padding * 2)

	if fullWidthCol >= minColWidth then
		for _, col: any in ipairs(columns) do
			tweenColumnSize(col, fullWidthCol, colHeight)
		end
	else
		local colsPerRow = math.max(1, math.floor(bodyWidth / (minColWidth + padding)))
		local rowPadding = padding * (colsPerRow + 1)
		local wrappedWidth = (bodyWidth - rowPadding) / colsPerRow

		for _, col in ipairs(columns) do
			tweenColumnSize(col, wrappedWidth, colHeight)
		end
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

-- // Columns
local Column = {}
Column.__index = Column

function Column.new(parent: Instance, order: number)
	local self = setmetatable({}, Column)

	local col = Instance.new("Frame")
	col.Size = UDim2.fromOffset(208, 0)
	col.AutomaticSize = Enum.AutomaticSize.Y
	col.BackgroundColor3 = GetTheme().colbg
	col.BorderSizePixel = 0
	col.LayoutOrder = order
	col.Parent = parent

	Util.corner(col, 8)
	Util.stroke(col, GetTheme().border, 0.25)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = col

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent = col

	self.Frame = col
	return self
end

function Window:addColumn(order: number)
	local col = Column.new(self.Body, order)
	self:_updateColumnSize()
	return col
end

-- \\ Sections
local Section = {}
Section.__index = Section

function Section.new(parent: Instance, name: string, iconName: string?, first: boolean?)
	local self = setmetatable({}, Section)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, first and 20 or 28)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local xo = 4
	if iconName then
		Icon(frame, iconName, 14, GetTheme().faint).Position = UDim2.new(0, 3, 1, -15)
		xo = 22
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -xo, 0, 14)
	label.Position = UDim2.new(0, xo, 1, -14)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = string.upper(name)
	label.TextColor3 = GetTheme().faint
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	self.Frame = frame
	return self
end

export type SectionData = {
	Name: string,
	Icon: string?,
	First: boolean?
}

function Column:addSection(data: SectionData)
	local name = data.Name or "Section"
	local icon = data.Icon or ""
	local first = data.First or true
	return Section.new(self.Frame, name, icon, first)
end

-- // Toggles
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent: Instance, name: string, default: boolean, cb)
	local self = setmetatable({}, Toggle)

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 34)
	f.BackgroundColor3 = GetTheme().hover
	f.BackgroundTransparency = 1
	f.Parent = parent
	Util.corner(f, 6)

	f.MouseEnter:Connect(function()
		Util.tween(f, {BackgroundTransparency = 0})
	end)

	f.MouseLeave:Connect(function()
		Util.tween(f, {BackgroundTransparency = 1})
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -54, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local sw = Instance.new("TextButton")
	sw.Size = UDim2.fromOffset(34, 18)
	sw.Position = UDim2.new(1, -42, 0.5, -9)
	sw.BackgroundColor3 = default and GetTheme().blue or GetTheme().trackOff
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.Parent = f
	Util.corner(sw, 9)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = GetTheme().knob
	knob.BorderSizePixel = 0
	knob.Parent = sw
	Util.corner(knob, 7)

	local state = default

	sw.MouseButton1Click:Connect(function()
		state = not state

		Util.tween(sw, {BackgroundColor3 = state and GetTheme().blue or GetTheme().trackOff}, 0.15)
		Util.tween(knob, {
			Position = state
				and UDim2.new(1, -16, 0.5, -7)
				or UDim2.new(0, 2, 0.5, -7)
		}, 0.15)

		cb(state)
	end)

	self.Frame = f
	return self
end

export type ToggleData = {
	Name: string,
	Default: boolean,
	Callback: ( boolean ) -> ()
}

function Column:addToggle(data: ToggleData)
	local name = data.Name or "Toggle"
	local default = data.Default or false
	local cb = data.Callback or function() end
	return Toggle.new(self.Frame, name, default, cb)
end

-- \\ Sliders
local Slider = {}
Slider.__index = Slider

function Slider.new(parent: Instance, name: string, min: number, max: number, snap: number, default: number, cb)
	local self = setmetatable({}, Slider)

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 46)
	f.BackgroundColor3 = GetTheme().hover
	f.BackgroundTransparency = 1
	f.Parent = parent
	Util.corner(f, 6)

	f.MouseEnter:Connect(function()
		Util.tween(f, {BackgroundTransparency = 0})
	end)

	f.MouseLeave:Connect(function()
		Util.tween(f, {BackgroundTransparency = 1})
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 18)
	lbl.Position = UDim2.fromOffset(10, 7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = name
	lbl.TextColor3 = GetTheme().dim
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local val = Instance.new("TextLabel")
	val.Size = UDim2.fromOffset(50, 18)
	val.Position = UDim2.new(1, -58, 0, 7)
	val.BackgroundTransparency = 1
	val.Font = Enum.Font.GothamBold
	val.Text = tostring(default)
	val.TextColor3 = GetTheme().text
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = f

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 4)
	bar.Position = UDim2.fromOffset(10, 30)
	bar.BackgroundColor3 = GetTheme().trackOff
	bar.BorderSizePixel = 0
	bar.Parent = f
	Util.corner(bar, 2)

	local rel = (default - min) / (max - min)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(rel, 0, 1, 0)
	fill.BackgroundColor3 = GetTheme().blue
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Util.corner(fill, 2)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(12, 12)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(rel, 0, 0.5, 0)
	knob.BackgroundColor3 = GetTheme().knob
	knob.BorderSizePixel = 0
	knob.Parent = bar
	Util.corner(knob, 6)

	local dragging = false

	local function setX(x: number)
		local r = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)

		local raw = min + (max - min) * r
		local v = math.floor(raw / snap + 0.5) * snap

		v = math.clamp(v, min, max)
		local sr = (v - min) / (max - min)

		fill.Size = UDim2.new(sr, 0, 1, 0)
		knob.Position = UDim2.new(sr, 0, 0.5, 0)
		val.Text = tostring(v)

		cb(v)
	end

	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setX(i.Position.X)
		end
	end)

	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			setX(i.Position.X)
		end
	end)

	self.Frame = f
	return self
end

export type SliderData = {
	Name: string,
	Min: number,
	Max: number,
	Step: number,
	Default: number,
	Callback: ( number ) -> ()
}

function Column:addSlider(data: SliderData)
	local name = data.Name or "Slider"
	local min = data.Min or 0
	local max = data.Max or 100
	local snap = data.Step or 1
	local default = data.Default or data.Min or 0
	local cb = data.Callback or function() end
	return Slider.new(self.Frame, name, min, max, snap, default, cb)
end

-- // Pills ( Buttons )
local Pill = {}
Pill.__index = Pill

function Pill.new(parent: Instance, name: string, iconName: string?, cb)
	local self = setmetatable({}, Pill)

	local b = Instance.new("TextButton")
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
	l.Font = Enum.Font.GothamMedium
	l.Text = name
	l.TextColor3 = GetTheme().text
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = b

	b.MouseEnter:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().hover})
	end)

	b.MouseLeave:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().pill})
	end)

	b.MouseButton1Click:Connect(cb)

	self.Frame = b
	return self
end

export type PillData = {
	Name: string,
	Icon: string?,
	Callback: () -> ()
}

function Column:addPill(data: PillData)
	local name = data.Name or "Pill"
	local icon = data.Icon or ""
	local cb = data.Callback or function() end
	return Pill.new(self.Frame, name, icon, cb)
end

-- \\ Player Lists
local PlayerList = {}
PlayerList.__index = PlayerList

local MiniButton = {}
MiniButton.__index = MiniButton

export type PlayerListType = {
	Frame: Frame,
	List: ScrollingFrame,
	Plrs: { [Player]: TextButton },
	
	_refresh: (self: PlayerListType) -> (),
	AddMiniButton: (self: PlayerListType, cfg: MiniButtonConfig) -> ()
}

export type MiniButtonConfig = {
	Text: string,
	XOffset: number,
	Callback: (Player) -> (),
}

function PlayerList.new(parent: Instance): PlayerListType
	local self = setmetatable({}, PlayerList) :: PlayerListType

	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1, 0, 0, 190)
	wrap.BackgroundColor3 = GetTheme().bg
	wrap.BackgroundTransparency = 0.4
	wrap.BorderSizePixel = 0
	wrap.Parent = parent
	Util.corner(wrap, 6)

	local list = Instance.new("ScrollingFrame")
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

	self:_refresh()

	Players.PlayerAdded:Connect(function()
		self:_refresh()
	end)

	Players.PlayerRemoving:Connect(function()
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

	for _, plr: Player in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local row: Frame = Instance.new("Frame") :: Frame
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundColor3 = GetTheme().hover
			row.BackgroundTransparency = 1
			row.Parent = self.List
			Util.corner(row, 5)
			
			self.Plrs[row] = plr

			row.MouseEnter:Connect(function()
				Util.tween(row, {BackgroundTransparency = 0})
			end)

			row.MouseLeave:Connect(function()
				Util.tween(row, {BackgroundTransparency = 1})
			end)

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -70, 1, 0)
			name.Position = UDim2.fromOffset(8, 0)
			name.BackgroundTransparency = 1
			name.Font = Enum.Font.GothamMedium
			name.Text = plr.DisplayName
			name.TextColor3 = GetTheme().text
			name.TextSize = 12
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = row
		end
	end
end

function Column:AddPlayerList()
	return PlayerList.new(self.Frame)
end

-- // Player List Mini Buttons
function MiniButton.new(parent: Instance, plr: Player, cfg: MiniButtonConfig)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(30, 22)
	b.Position = UDim2.new(1, cfg.XOffset, 0.5, -11)
	b.BackgroundColor3 = GetTheme().pill
	b.Text = cfg.Text
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 10
	b.TextColor3 = GetTheme().text
	b.AutoButtonColor = true
	b.Parent = parent

	Util.corner(b, 5)
	Util.stroke(b, GetTheme().pillBrd, 0.3)
	
	b.MouseEnter:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().hover})
	end)
	
	b.MouseLeave:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().pill})
	end)

	b.MouseButton1Click:Connect(function()
		cfg.Callback(plr)
	end)

	local self = setmetatable({}, MiniButton)
	self.Button = b
	return self
end

function PlayerList:AddMiniButton(cfg: MiniButtonConfig)
	for _, row: any in ipairs(self.List:GetChildren()) do
		if row:IsA("Frame") then
			local plr = self.Plrs[row]
			if plr then
				MiniButton.new(row, plr, cfg)
			end
		end
	end
end

-- \\ Exporting
local RebornUI = {
	Window = Window,
	Column = Column,
	Section = Section,
	Toggle = Toggle,
	Slider = Slider,
	Pill = Pill,
	PlayerList = PlayerList,
	MiniButton = MiniButton,
	
	Themes = Themes,
	SetTheme = SetTheme,
	GetTheme = GetTheme
}

return RebornUI
