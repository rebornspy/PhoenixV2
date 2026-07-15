-- Created and Maintained by reborb (@rebornspy).
-- Inspired by various other GUI Suites.
-- Works in studio, at the cost of no icons.

-- \\ Globals & Services
local Players:  Players = game:GetService("Players")                    :: Players
local UIS:      UserInputService = game:GetService("UserInputService")  :: UserInputService
local ts:       TweenService = game:GetService("TweenService")          :: TweenService

local LP:       Player = Players.LocalPlayer    ::  Player

-- // Themes
local Themes    =   {
	Dark        =   {
		bg          =   Color3.fromRGB(17,  17, 20  );
		header      =   Color3.fromRGB(23,  23, 27  );
		colbg       =   Color3.fromRGB(24,  24, 29  );
		border      =   Color3.fromRGB(44,  44, 51  );
		hover       =   Color3.fromRGB(34,  34, 40  );
		pillHover   =   Color3.fromRGB(44,  44, 50  );
		text        =   Color3.fromRGB(233, 233, 238);
		dim         =   Color3.fromRGB(150, 150, 160);
		faint       =   Color3.fromRGB(105, 105, 116);
		blue        =   Color3.fromRGB(72,  130, 248);
		red         =   Color3.fromRGB(220, 80, 90  );
		trackOff    =   Color3.fromRGB(58,  58, 66  );
		pill        =   Color3.fromRGB(33,  33, 40  );
		pillBrd     =   Color3.fromRGB(54,  54, 62  );
		knob        =   Color3.fromRGB(240, 240, 245);
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
	if gethui() or game:GetService("CoreGui") then
    	if gethui() ~= nil then
			parent = gethui()
		elseif game:GetService("CoreGui") then
			parent = game:GetService("CoreGui")
		end
	end
    return parent
end

function Util.corner(p: Instance, r: number?)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 6)
	u.Parent = p
	return u
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
	)   :Play()
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

local Option = {}
Option.__index = Option

local ComponentFactory = {
	Toggle = Toggle,
	Slider = Slider,
	Button = Pill,
}

-- // Windows
export type WindowType = {
	Gui: ScreenGui,
	Main: Frame,
	Body: ScrollingFrame,

	_makeResizable: (self: WindowType, handle: Frame) -> (),
	_updateColumnSize: (self: WindowType) -> (),
	RefreshTheme: (self: WindowType) -> (),
	addColumn: (self: WindowType, order: number) -> ColumnType,
}

function Window.new(title: string): WindowType
	if gethui():FindFirstChild("holder") or game:GetService("CoreGui"):FindFirstChild("holder") then
		local holder = gethui():FindFirstChild("holder") or game:GetService("CoreGui"):FindFirstChild("holder")
		holder:Destroy()
	end
	
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

	self:_makeResizable(handle)

	main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_updateColumnSize()
	end)

	self:_updateColumnSize()

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
	local padding = 8
	local minColWidth = 175

	local maxCols = math.max(1, math.floor((bodyWidth - padding) / (minColWidth + padding)))
	local colsPerRow = math.clamp(maxCols, 1, count)
	local colWidth = (bodyWidth - padding * (colsPerRow + 1)) / colsPerRow

	for _, col: any in ipairs(columns) do
		col.Size = UDim2.new(0, colWidth, col.Size.Y.Scale, col.Size.Y.Offset)
	end

	task.wait()

	local function getColumnContentHeight(col: Frame)
		local layout = col:FindFirstChildOfClass("UIListLayout")
		if layout then
			return layout.AbsoluteContentSize.Y + 20
		end

		local h = 0
		for _, c in ipairs(col:GetChildren()) do
			if c:IsA("GuiObject") then
				h += c.AbsoluteSize.Y
			end
		end
		return h + 20
	end

	local colHeights = {}
	for _, col in ipairs(columns) do
		colHeights[col] = getColumnContentHeight(col)
	end

	local colY = table.create(colsPerRow, padding)

	for i, col in ipairs(columns) do
		local slot = ((i - 1) % colsPerRow) + 1
		local x = padding + (slot - 1) * (colWidth + padding)
		local h = colHeights[col]
		local y = colY[slot]

		Util.tween(col, {
			Size = UDim2.new(0, colWidth, 0, h)
		}, 0.15)

		Util.tween(col, {
			Position = UDim2.new(0, x, 0, y)
		}, 0.15)

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

-- \\ Columns
export type ColumnType = {
	Frame: Frame,
	Window: WindowType,

	addSection: (self: ColumnType, data: SectionData) -> SectionType,
	addToggle: (self: ColumnType, data: ToggleData) -> ToggleType,
	addSlider: (self: ColumnType, data: SliderData) -> SliderType,
	addPill: (self: ColumnType, data: PillData) -> PillType,
	addPlayerList: (self: ColumnType) -> PlayerListType,
}
function Column.new(parent: Instance, order: number, window: WindowType): ColumnType
	local self = setmetatable({}, Column) :: ColumnType

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
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = col

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = col

	self.Frame = col
	self.Window = window

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

function Window:addColumn(order: number)
	local col = Column.new(self.Body, order, self)
	self:_updateColumnSize()
	return col
end

-- // Sections
export type SectionType = {
	Frame: Frame,
}

export type SectionData = {
	Name: string,
	Icon: string?,
	First: boolean?,
	LayoutOrder: number?,
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
	label.Font = Enum.Font.GothamBold
	label.Text = string.upper(name)
	label.TextColor3 = GetTheme().faint
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	self.Frame = frame
	return self
end

function Column:addSection(data: SectionData)
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

	f.MouseEnter:Connect(function()
		Util.tween(f, {BackgroundColor3 = GetTheme().hover})
	end)

	f.MouseLeave:Connect(function()
		Util.tween(f, {BackgroundColor3 = GetTheme().colbg})
	end)

	local arrow = Instance.new("ImageButton")
	arrow.Size = UDim2.fromOffset(16, 16)
	arrow.Name = "DropdownArrow"
	arrow.Position = UDim2.new(1, -40, 0, 8)
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

	self.Arrow.MouseButton1Click:Connect(function()
		self.DropdownOpen = not self.DropdownOpen
		self.Dropdown.Visible = self.DropdownOpen

		Util.tween(self.Arrow, {
			Rotation = self.DropdownOpen and -90 or 0
		}, 0.15)

		local layout = self.Dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local targetHeight = self.DropdownOpen and layout.AbsoluteContentSize.Y or 0

		Util.tween(self.Dropdown, {
			Size = UDim2.new(1, -8, 0, targetHeight + 8)
		}, 0.15)

		local baseHeight = 34
		if self.DropdownOpen then
			Util.tween(self.Frame, {
				Size = UDim2.new(1, 0, 0, baseHeight + targetHeight + 12)
			}, 0.15)
		else
			Util.tween(self.Frame, {
				Size = UDim2.new(1, 0, 0, baseHeight + targetHeight)
			}, 0.15)
		end

		task.delay(0.1, function()
			self.Window:_updateColumnSize()
		end)
	end)

	function self._updateArrowVisibility()
		local hasChildren = #drop:GetChildren() > 3
		self.Arrow.Visible = hasChildren
	end

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.new(1, -54, 0, 0)
	lbl.Position = UDim2.fromOffset(10, 17)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
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
		Util.tween(self.Dropdown, {
			Size = UDim2.new(1, 0, 0, newHeight)
		}, 0.15)
	end

	self:_updateArrowVisibility()

	task.defer(function()
		self.Window:_updateColumnSize()
	end)
end

function Column:addToggle(data: ToggleData)
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
    _cb: (number) -> (),

    _fill: Frame,
    _knob: Frame,
    _bar: Frame,
    _val: TextLabel,

	_updateArrowVisibility: () -> (),
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

	local f = Instance.new("Frame")
	f.Name = name
	f.LayoutOrder = layoutOrder
	f.Size = UDim2.new(1, 0, 0, 46)
	f.BackgroundColor3 = GetTheme().colbg
	f.BackgroundTransparency = 0
	f.Parent = parent
	Util.corner(f, 6)

	f.MouseEnter:Connect(function()
		Util.tween(f, {BackgroundColor3 = GetTheme().hover})
	end)

	f.MouseLeave:Connect(function()
		Util.tween(f, {BackgroundColor3 = GetTheme().colbg})
	end)

	local arrow = Instance.new("ImageButton")
	arrow.Name = "DropdownArrow"
	arrow.Size = UDim2.fromOffset(16, 16)
	arrow.Position = UDim2.new(1, -20, 0, 8)
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

	self.Arrow.MouseButton1Click:Connect(function()
		self.DropdownOpen = not self.DropdownOpen
		self.Dropdown.Visible = self.DropdownOpen

		Util.tween(self.Arrow, {
			Rotation = self.DropdownOpen and -90 or 0
		}, 0.15)

		local layout = self.Dropdown:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		local targetHeight = self.DropdownOpen and layout.AbsoluteContentSize.Y or 0

		Util.tween(self.Dropdown, {
			Size = UDim2.new(1, -8, 0, targetHeight + 8)
		}, 0.15)

		local baseHeight = 34
		Util.tween(self.Frame, {
			Size = UDim2.new(1, 0, 0, baseHeight + targetHeight + 12)
		}, 0.15)

		task.delay(0.1, function()
			self.Window:_updateColumnSize()
		end)
	end)

	function self._updateArrowVisibility()
		local hasChildren = #drop:GetChildren() > 3
		self.Arrow.Visible = hasChildren
	end

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.new(1, -20, 0, 18)
	lbl.Position = UDim2.fromOffset(10, 7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	local val = Instance.new("TextLabel")
	val.Name = "Value"
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
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -20, 0, 4)
	bar.Position = UDim2.fromOffset(10, 30)
	bar.BackgroundColor3 = GetTheme().trackOff
	bar.BorderSizePixel = 0
	bar.Parent = f
	Util.corner(bar, 2)

	local rel = (default - min) / (max - min)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(rel, 0, 1, 0)
	fill.BackgroundColor3 = GetTheme().blue
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Util.corner(fill, 2)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
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

	self._updateArrowVisibility()

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

    self._fill.Size = UDim2.new(sr, 0, 1, 0)
    self._knob.Position = UDim2.new(sr, 0, 0.5, 0)
    self._val.Text = tostring(v)

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
		Util.tween(self.Dropdown, {
			Size = UDim2.new(1, 0, 0, newHeight)
		}, 0.15)
	end

	self:_updateArrowVisibility()

	task.defer(function()
		self.Window:_updateColumnSize()
	end)

	return newComponent
end

function Column:addSlider(data: SliderData)
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
	l.Font = Enum.Font.GothamMedium
	l.Text = name
	l.TextColor3 = GetTheme().text
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = b

	b.MouseEnter:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().pillHover})
	end)

	b.MouseLeave:Connect(function()
		Util.tween(b, {BackgroundColor3 = GetTheme().pill})
	end)

	b.MouseButton1Click:Connect(function()
		cb()
	end)

	self.Frame = b
	return self
end

function Column:addPill(data: PillData)
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
			row.Name = plr.Name .. " PlayerListFrame"
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

function Column:addPlayerList()
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

-- // Options
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

	f.MouseEnter:Connect(function()
		Util.tween(f, {BackgroundTransparency = 0})
	end)

	f.MouseLeave:Connect(function()
		Util.tween(f, {BackgroundTransparency = 1})
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = name
	lbl.TextColor3 = GetTheme().text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f

	f.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			cb()
		end
	end)

	self.Frame = f
	return self
end

-- \\ Module Export
local RebornUI = {
	Window = Window,
	Column = Column,
	Section = Section,
	Toggle = Toggle,
	Slider = Slider,
	Pill = Pill,
	PlayerList = PlayerList,
	MiniButton = MiniButton,
	Option = Option,

	Themes = Themes,
	SetTheme = SetTheme,
	GetTheme = GetTheme,
}

return RebornUI
