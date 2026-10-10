--[[
    DarkMenuUI v3.0
    Минималистичное тёмно-серое меню для Roblox.
    GitHub-ready. Загружается через loadstring.

    Использование:
        local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/src/init.lua"))()
        local tab = UI:Tab("Main")
        tab:Button("Click me", function() print("clicked") end)
        tab:Toggle("Enable", false, function(state) print(state) end)
        tab:Slider("Speed", 16, 200, 16, function(v) print(v) end)
--]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Уничтожаем старую версию, если есть
local OLD = PlayerGui:FindFirstChild("DarkMenuUI")
if OLD then OLD:Destroy() end

-- =========================================================
--  CONFIG
-- =========================================================
local C = {
    Title        = "Dark Menu",
    Size         = UDim2.fromOffset(450, 290),
    Position     = UDim2.fromScale(0.5, 0.5),
    AnchorPoint  = Vector2.new(0.5, 0.5),
    ToggleKey    = Enum.KeyCode.RightShift,
    Font         = Enum.Font.GothamMedium,
    FontBold     = Enum.Font.GothamBold,

    Background   = Color3.fromRGB(24, 24, 26),
    Background2  = Color3.fromRGB(31, 31, 34),
    Header       = Color3.fromRGB(17, 17, 19),
    Sidebar      = Color3.fromRGB(20, 20, 22),
    Element      = Color3.fromRGB(38, 38, 42),
    ElementHover = Color3.fromRGB(50, 50, 55),
    ElementPress = Color3.fromRGB(58, 58, 64),
    Stroke       = Color3.fromRGB(62, 62, 68),
    StrokeBright = Color3.fromRGB(88, 88, 94),
    Accent       = Color3.fromRGB(168, 168, 178),
    AccentDim    = Color3.fromRGB(72, 72, 78),
    Text         = Color3.fromRGB(232, 232, 236),
    SubText      = Color3.fromRGB(150, 150, 156),
    Muted        = Color3.fromRGB(100, 100, 106),
    Shadow       = Color3.fromRGB(0, 0, 0),

    RingCount    = 12,
    DotCount     = 18,
}
-- =========================================================

-- =========================================================
--  HELPERS
-- =========================================================
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, r)
    return make("UICorner", {CornerRadius = UDim.new(0, r or 6)}, parent)
end

local function stroke(parent, color, transparency)
    return make("UIStroke", {
        Color = color or C.Stroke,
        Transparency = transparency or 0.5,
        Thickness = 1,
    }, parent)
end

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end
-- =========================================================

-- =========================================================
--  ROOT
-- =========================================================
local Gui = make("ScreenGui", {
    Name = "DarkMenuUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
}, PlayerGui)

local Shadow = make("Frame", {
    Size = C.Size,
    Position = C.Position,
    AnchorPoint = C.AnchorPoint,
    BackgroundColor3 = C.Shadow,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 0,
}, Gui)
corner(Shadow, 12)

local Main = make("Frame", {
    Size = C.Size,
    Position = C.Position,
    AnchorPoint = C.AnchorPoint,
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
}, Gui)
corner(Main, 10)
local MainStroke = stroke(Main, C.Stroke, 0.2)
make("UIGradient", {
    Rotation = 135,
    Color = ColorSequence.new(C.Background2, C.Background),
}, Main)
-- =========================================================

-- =========================================================
--  BACKGROUND (rings + dots)
-- =========================================================
local Pattern = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
}, Main)

local rings, dots = {}, {}

for _ = 1, C.RingCount do
    local size = math.random(50, 130)
    local shade = math.random(70, 120)
    local r = make("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Pattern)
    corner(r, size / 2)
    local s = stroke(r, Color3.fromRGB(shade, shade, shade + 4), math.random(75, 90) / 100)
    rings[#rings+1] = {
        f = r, s = s,
        angle = math.random() * math.pi * 2,
        speed = (math.random(15, 45) / 1000) * (math.random() < 0.5 and 1 or -1),
        radius = math.random(40, 100) / 100,
        ox = math.random(), oy = math.random(),
        pulse = math.random() * math.pi * 2,
        pulseSpeed = math.random(30, 80) / 1000,
    }
end

for _ = 1, C.DotCount do
    local size = math.random(2, 3)
    local shade = math.random(90, 140)
    local d = make("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Color3.fromRGB(shade, shade, shade + 4),
        BackgroundTransparency = math.random(55, 80) / 100,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Pattern)
    corner(d, size / 2)
    dots[#dots+1] = {
        f = d, x = math.random(), y = math.random(),
        vx = math.random(-20, 20) / 10000,
        vy = math.random(-20, 20) / 10000,
    }
end

local lastTick = tick()
RunService.RenderStepped:Connect(function()
    local now = tick()
    local dt = now - lastTick
    lastTick = now
    local sx, sy = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if sx <= 0 or sy <= 0 then return end

    for _, r in ipairs(rings) do
        if not r.f.Parent then continue end
        r.angle = r.angle + r.speed * dt * 60
        r.pulse = r.pulse + r.pulseSpeed * dt * 60
        local cx = r.ox * sx + math.cos(r.angle) * r.radius * 100
        local cy = r.oy * sy + math.sin(r.angle * 1.3) * r.radius * 100
        if cx < -140 then r.ox = 1 end
        if cx > sx + 140 then r.ox = 0 end
        if cy < -140 then r.oy = 1 end
        if cy > sy + 140 then r.oy = 0 end
        r.f.Position = UDim2.fromOffset(cx, cy)
        r.s.Transparency = 0.78 + math.sin(r.pulse) * 0.08
    end
    for _, d in ipairs(dots) do
        if not d.f.Parent then continue end
        d.x = d.x + d.vx * dt * 60
        d.y = d.y + d.vy * dt * 60
        if d.x < 0 then d.x = 1 elseif d.x > 1 then d.x = 0 end
        if d.y < 0 then d.y = 1 elseif d.y > 1 then d.y = 0 end
        d.f.Position = UDim2.fromScale(d.x, d.y)
    end
end)
-- =========================================================

-- =========================================================
--  HEADER
-- =========================================================
local Header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
    ZIndex = 8,
}, Main)
corner(Header, 10)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
    ZIndex = 8,
}, Header)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.StrokeBright,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    ZIndex = 9,
}, Header)

local LogoDot = make("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
    ZIndex = 9,
}, Header)
corner(LogoDot, 4)

task.spawn(function()
    while LogoDot.Parent do
        tween(LogoDot, 1.4, {BackgroundTransparency = 0.5}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
        tween(LogoDot, 1.4, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
    end
end)

make("TextLabel", {
    Size = UDim2.new(1, -140, 1, 0),
    Position = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1,
    Text = C.Title,
    TextColor3 = C.Text,
    Font = C.FontBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
}, Header)

-- Header buttons
local BtnHolder = make("Frame", {
    Size = UDim2.fromOffset(62, 22),
    Position = UDim2.new(1, -72, 0.5, -11),
    BackgroundTransparency = 1,
    ZIndex = 9,
}, Header)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, BtnHolder)

local function headerBtn(text)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = C.Element,
        Text = text,
        TextColor3 = C.Text,
        Font = C.FontBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 10,
    }, BtnHolder)
    corner(b, 5)
    b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = C.ElementHover}) end)
    b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = C.Element}) end)
    return b
end

local MinimizeBtn = headerBtn("—")
local CloseBtn    = headerBtn("✕")
CloseBtn.MouseButton1Click:Connect(function() Gui:Destroy() end)
-- =========================================================

-- =========================================================
--  DRAG (PC + Mobile)
-- =========================================================
do
    local dragging, dragStart, startPos

    local function begin(input)
        dragging  = true
        dragStart = input.Position
        startPos  = Main.Position
    end
    local function update(input)
        if not dragging then return end
        local d = input.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local w = Main.AbsoluteSize.X
        local nx = math.clamp(startPos.X.Offset + d.X, -w * 0.6, vp.X - w * 0.4)
        local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - 30)
        Main.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
    end
    local function finish() dragging = false end

    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            begin(i)
        end
    end)
    Header.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            update(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            finish()
        end
    end)

    RunService.RenderStepped:Connect(function()
        Shadow.Position = Main.Position + UDim2.fromOffset(3, 4)
        Shadow.Size = Main.Size
    end)
end
-- =========================================================

-- =========================================================
--  SIDEBAR + CONTENT
-- =========================================================
local Sidebar = make("Frame", {
    Size = UDim2.new(0, 120, 1, -38),
    Position = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.Sidebar,
    BorderSizePixel = 0,
    ZIndex = 6,
}, Main)
make("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)
make("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 8),
}, Sidebar)

make("Frame", {
    Size = UDim2.new(0, 1, 1, -38),
    Position = UDim2.new(0, 120, 0, 38),
    BackgroundColor3 = C.Stroke,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ZIndex = 6,
}, Main)

local Content = make("Frame", {
    Size = UDim2.new(1, -121, 1, -38),
    Position = UDim2.new(0, 121, 0, 38),
    BackgroundTransparency = 1,
    ZIndex = 6,
}, Main)
-- =========================================================

-- =========================================================
--  LIBRARY
-- =========================================================
local Library = {}
Library.Tabs = {}
Library.ActiveTab = nil

local function styleElement(frame)
    frame.BackgroundColor3 = C.Element
    frame.BackgroundTransparency = 0.15
    local s = stroke(frame, C.Stroke, 0.55)
    return s
end

-- === TAB ===
function Library:Tab(name)
    local Btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = C.Element,
        BackgroundTransparency = 1,
        Text = "  " .. name,
        TextColor3 = C.SubText,
        Font = C.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 7,
    }, Sidebar)
    corner(Btn, 5)

    local Indicator = make("Frame", {
        Size = UDim2.fromOffset(3, 14),
        Position = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 8,
    }, Btn)
    corner(Indicator, 2)

    local Page = make("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.AccentDim,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 7,
    }, Content)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Page)
    make("UIPadding", {PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 3)}, Page)

    local Data = {Button = Btn, Page = Page, Indicator = Indicator, Name = name}

    Btn.MouseButton1Click:Connect(function() Library:SelectTab(Data) end)
    Btn.MouseEnter:Connect(function()
        if Library.ActiveTab ~= Data then
            tween(Btn, 0.15, {BackgroundTransparency = 0.5})
        end
    end)
    Btn.MouseLeave:Connect(function()
        if Library.ActiveTab ~= Data then
            tween(Btn, 0.15, {BackgroundTransparency = 1})
        end
    end)

    self.Tabs[#self.Tabs+1] = Data
    if #self.Tabs == 1 then self:SelectTab(Data) end

    -- Возвращаем объект-обёртку с методами
    local Tab = {}
    function Tab:Button(text, cb) return Library:Button(Data, text, cb) end
    function Tab:Toggle(text, def, cb) return Library:Toggle(Data, text, def, cb) end
    function Tab:Slider(text, mn, mx, def, cb) return Library:Slider(Data, text, mn, mx, def, cb) end
    function Tab:Label(text) return Library:Label(Data, text) end
    function Tab:Section(text) return Library:Section(Data, text) end
    Tab._data = Data
    return Tab
end

function Library:SelectTab(Data)
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        tween(t.Button, 0.2, {BackgroundTransparency = 1, TextColor3 = C.SubText})
        tween(t.Indicator, 0.2, {BackgroundTransparency = 1})
    end
    Data.Page.Visible = true
    tween(Data.Button, 0.2, {BackgroundTransparency = 0.2, TextColor3 = C.Text})
    tween(Data.Indicator, 0.2, {BackgroundTransparency = 0})
    self.ActiveTab = Data
end

-- === SECTION ===
function Library:Section(Data, text)
    local H = make("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 8,
    }, Data.Page)
    make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.Stroke,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, H)
    make("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = C.Background,
        Text = "  " .. string.upper(text),
        TextColor3 = C.Muted,
        Font = C.FontBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9,
    }, H)
    return H
end

-- === LABEL ===
function Library:Label(Data, text)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.SubText,
        Font = C.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8,
    }, Data.Page)
end

-- === BUTTON ===
function Library:Button(Data, text, cb)
    local B = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Text = text,
        TextColor3 = C.Text,
        Font = C.Font,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 8,
    }, Data.Page)
    corner(B, 5)
    local s = styleElement(B)

    B.MouseEnter:Connect(function()
        tween(B, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0})
        tween(s, 0.15, {Transparency = 0.3, Color = C.StrokeBright})
    end)
    B.MouseLeave:Connect(function()
        tween(B, 0.15, {BackgroundColor3 = C.Element, BackgroundTransparency = 0.15})
        tween(s, 0.15, {Transparency = 0.55, Color = C.Stroke})
    end)
    B.MouseButton1Down:Connect(function()
        tween(B, 0.08, {BackgroundColor3 = C.ElementPress, BackgroundTransparency = 0})
    end)
    B.MouseButton1Up:Connect(function()
        tween(B, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0})
    end)
    B.MouseButton1Click:Connect(function()
        if cb then
            local ok, err = pcall(cb)
            if not ok then warn("[DarkMenuUI] Button:", err) end
        end
    end)
    return B
end

-- === TOGGLE ===
function Library:Toggle(Data, text, default, cb)
    local state = default and true or false

    local H = make("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 8,
    }, Data.Page)
    corner(H, 5)
    local s = styleElement(H)

    make("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        Font = C.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9,
    }, H)

    local Track = make("Frame", {
        Size = UDim2.fromOffset(30, 16),
        Position = UDim2.new(1, -40, 0.5, -8),
        BackgroundColor3 = C.Background,
        BackgroundTransparency = 0.3,
        ZIndex = 9,
    }, H)
    corner(Track, 8)
    make("UIStroke", {Color = C.Stroke, Transparency = 0.4}, Track)

    local Knob = make("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = state and C.Accent or C.Muted,
        ZIndex = 10,
    }, Track)
    corner(Knob, 6)

    local Click = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 11,
    }, H)

    local function apply(on, anim)
        local info = TweenInfo.new(anim and 0.2 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(Knob, info, {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = on and C.Accent or C.Muted,
        }):Play()
        TweenService:Create(Track, info, {
            BackgroundColor3 = on and C.AccentDim or C.Background,
        }):Play()
    end
    if state then apply(true, false) end

    Click.MouseButton1Click:Connect(function()
        state = not state
        apply(state, true)
        if cb then
            local ok, err = pcall(cb, state)
            if not ok then warn("[DarkMenuUI] Toggle:", err) end
        end
    end)
    Click.MouseEnter:Connect(function()
        tween(H, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0})
        tween(s, 0.15, {Transparency = 0.3, Color = C.StrokeBright})
    end)
    Click.MouseLeave:Connect(function()
        tween(H, 0.15, {BackgroundColor3 = C.Element, BackgroundTransparency = 0.15})
        tween(s, 0.15, {Transparency = 0.55, Color = C.Stroke})
    end)

    return {
        Set = function(v) state = v and true or false; apply(state, true) end,
        Get = function() return state end,
    }
end

-- === SLIDER ===
function Library:Slider(Data, text, min, max, default, cb)
    min, max = min or 0, max or 100
    default = math.clamp(default or min, min, max)
    local value = default

    local H = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 8,
    }, Data.Page)
    corner(H, 5)
    local s = styleElement(H)

    make("TextLabel", {
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.fromOffset(12, 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        Font = C.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9,
    }, H)

    local ValueBox = make("Frame", {
        Size = UDim2.fromOffset(50, 16),
        Position = UDim2.new(1, -62, 0, 5),
        BackgroundColor3 = C.Background,
        BackgroundTransparency = 0.3,
        ZIndex = 9,
    }, H)
    corner(ValueBox, 3)

    local ValueLabel = make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextColor3 = C.Text,
        Font = C.FontBold,
        TextSize = 11,
        ZIndex = 10,
    }, ValueBox)

    local BarBg = make("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 1, -12),
        BackgroundColor3 = C.Background,
        BackgroundTransparency = 0.3,
        ZIndex = 9,
    }, H)
    corner(BarBg, 3)

    local Fill = make("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        ZIndex = 10,
    }, BarBg)
    corner(Fill, 3)

    local Knob = make("Frame", {
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = C.Text,
        ZIndex = 11,
    }, BarBg)
    corner(Knob, 6)
    make("UIStroke", {Color = C.StrokeBright}, Knob)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * rel
        value = math.floor(value * 100 + 0.5) / 100
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        ValueLabel.Text = tostring(value)
        if cb then
            local ok, err = pcall(cb, value)
            if not ok then warn("[DarkMenuUI] Slider:", err) end
        end
    end

    BarBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    H.MouseEnter:Connect(function()
        tween(H, 0.15, {BackgroundTransparency = 0.05})
        tween(s, 0.15, {Transparency = 0.4, Color = C.StrokeBright})
    end)
    H.MouseLeave:Connect(function()
        tween(H, 0.15, {BackgroundTransparency = 0.15})
        tween(s, 0.15, {Transparency = 0.55, Color = C.Stroke})
    end)

    if cb then pcall(cb, value) end

    return {
        Set = function(v)
            v = math.clamp(v, min, max)
            value = v
            local rel = (v - min) / (max - min)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, 0, 0.5, 0)
            ValueLabel.Text = tostring(v)
            if cb then pcall(cb, v) end
        end,
        Get = function() return value end,
    }
end

-- =========================================================
--  MINIMIZE + TOGGLE
-- =========================================================
local minimized = false
local originalSize = C.Size

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    tween(Main, 0.25, {
        Size = minimized and UDim2.new(0, originalSize.X.Offset, 0, 38) or originalSize,
    })
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == C.ToggleKey then
        Main.Visible = not Main.Visible
        Shadow.Visible = Main.Visible
    end
end)

-- =========================================================
--  RETURN LIBRARY
-- =========================================================
Library.Config = C
Library.Gui = Gui

return Library
