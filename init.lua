--[[
    DarkMenuUI v3.4 — Full
    Tabs • Button • Toggle • Slider • Dropdown • Notifications
    GitHub-ready (loadstring).

    Usage:
        local UI = loadstring(game:HttpGet("URL"))()
        local Tab = UI:Tab("Main")
        Tab:Button("Hi", function() print("hi") end)
        Tab:Toggle("On", false, function(s) print(s) end)
        Tab:Slider("Speed", 16, 200, 16, function(v) print(v) end)
        Tab:Dropdown("Mode", {"A","B"}, "A", function(v) print(v) end)
        UI.Notify("Что-то случилось!")

    Changelog v3.4:
        - Round bottom corners of main window
        - Removed Y-axis clamp on drag (can move freely up)
--]]

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local LP    = Players.LocalPlayer
local PGui  = LP:WaitForChild("PlayerGui")

for _, n in ipairs({"DarkMenuUI", "DarkMenuUI_Notifs", "DarkMenuUI_Dropdown"}) do
    local o = PGui:FindFirstChild(n); if o then o:Destroy() end
end

-- ============ CONFIG ============
local C = {
    Title = "Dark Menu",
    Size = UDim2.fromOffset(460, 300),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    ToggleKey = Enum.KeyCode.RightShift,
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    IconFont = Enum.Font.SourceSansBold,
    CornerRadius = 10,

    Background   = Color3.fromRGB(28, 28, 31),
    Background2  = Color3.fromRGB(36, 36, 40),
    Header       = Color3.fromRGB(20, 20, 22),
    Sidebar      = Color3.fromRGB(23, 23, 26),
    Element      = Color3.fromRGB(44, 46, 52),
    ElementHover = Color3.fromRGB(58, 60, 68),
    ElementPress = Color3.fromRGB(70, 72, 80),
    Stroke       = Color3.fromRGB(70, 70, 76),
    StrokeBright = Color3.fromRGB(120, 124, 136),
    Accent       = Color3.fromRGB(210, 214, 224),
    AccentSoft   = Color3.fromRGB(140, 145, 160),
    AccentDim    = Color3.fromRGB(90, 92, 104),
    Text         = Color3.fromRGB(240, 242, 248),
    SubText      = Color3.fromRGB(180, 184, 196),
    Muted        = Color3.fromRGB(120, 124, 136),
    Shadow       = Color3.fromRGB(0, 0, 0),

    RingCount = 12,
    DotCount  = 18,

    NotifWidth = 270,
    NotifHeight = 62,
    NotifPadding = 8,
    NotifMarginRight = 14,
    NotifMarginTop = 14,
    NotifDuration = 4,
    NotifMaxStack = 5,
}
-- ================================

-- ============ HELPERS ============
local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r) return make("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
local function stroke(p, c, t) return make("UIStroke", {Color = c or C.Stroke, Transparency = t or 0.5, Thickness = 1}, p) end
local function tween(o, t, props, s, d)
    local tw = TweenService:Create(o, TweenInfo.new(t, s or Enum.EasingStyle.Quint, d or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
-- ================================

-- ============ ROOT ============
local Gui = make("ScreenGui", {
    Name = "DarkMenuUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
}, PGui)

local Shadow = make("Frame", {
    Size = C.Size, Position = C.Position, AnchorPoint = C.AnchorPoint,
    BackgroundColor3 = C.Shadow, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 0,
}, Gui)
corner(Shadow, C.CornerRadius + 2)

local Main = make("Frame", {
    Size = C.Size, Position = C.Position, AnchorPoint = C.AnchorPoint,
    BackgroundColor3 = C.Background, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, Gui)
corner(Main, C.CornerRadius)
stroke(Main, C.Stroke, 0.2)
make("UIGradient", {Rotation = 135, Color = ColorSequence.new(C.Background2, C.Background)}, Main)

-- ============ BACKGROUND ============
local Pattern = make("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    ClipsDescendants = true, ZIndex = 2,
}, Main)

local rings, dots = {}, {}
for _ = 1, C.RingCount do
    local size = math.random(50, 130)
    local shade = math.random(70, 120)
    local r = make("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, Pattern)
    corner(r, size / 2)
    local s = stroke(r, Color3.fromRGB(shade, shade, shade + 4), math.random(75, 90) / 100)
    rings[#rings+1] = {f = r, s = s, angle = math.random()*math.pi*2, speed = (math.random(15,45)/1000)*(math.random()<0.5 and 1 or -1),
        radius = math.random(40,100)/100, ox = math.random(), oy = math.random(),
        pulse = math.random()*math.pi*2, pulseSpeed = math.random(30,80)/1000}
end
for _ = 1, C.DotCount do
    local size = math.random(2, 3); local shade = math.random(90, 140)
    local d = make("Frame", {Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Color3.fromRGB(shade, shade, shade+4), BackgroundTransparency = math.random(55,80)/100,
        BorderSizePixel = 0, ZIndex = 2}, Pattern)
    corner(d, size / 2)
    dots[#dots+1] = {f = d, x = math.random(), y = math.random(), vx = math.random(-20,20)/10000, vy = math.random(-20,20)/10000}
end

local lastT = tick()
RunService.RenderStepped:Connect(function()
    local now = tick(); local dt = now - lastT; lastT = now
    local sx, sy = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if sx <= 0 or sy <= 0 then return end
    for _, r in ipairs(rings) do
        if not r.f.Parent then continue end
        r.angle = r.angle + r.speed * dt * 60
        r.pulse = r.pulse + r.pulseSpeed * dt * 60
        local cx = r.ox*sx + math.cos(r.angle)*r.radius*100
        local cy = r.oy*sy + math.sin(r.angle*1.3)*r.radius*100
        if cx < -140 then r.ox = 1 end; if cx > sx+140 then r.ox = 0 end
        if cy < -140 then r.oy = 1 end; if cy > sy+140 then r.oy = 0 end
        r.f.Position = UDim2.fromOffset(cx, cy)
        r.s.Transparency = 0.78 + math.sin(r.pulse) * 0.08
    end
    for _, d in ipairs(dots) do
        if not d.f.Parent then continue end
        d.x = d.x + d.vx*dt*60; d.y = d.y + d.vy*dt*60
        if d.x < 0 then d.x = 1 elseif d.x > 1 then d.x = 0 end
        if d.y < 0 then d.y = 1 elseif d.y > 1 then d.y = 0 end
        d.f.Position = UDim2.fromScale(d.x, d.y)
    end
end)

-- ============ HEADER ============
local Header = make("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 8}, Main)
corner(Header, C.CornerRadius)
make("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 8}, Header)
make("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.StrokeBright, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 9}, Header)

local Logo = make("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 14, 0.5, -4), BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 9}, Header)
corner(Logo, 4)
task.spawn(function()
    while Logo.Parent do
        tween(Logo, 1.4, {BackgroundTransparency = 0.5}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
        tween(Logo, 1.4, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
    end
end)

make("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1, Text = C.Title, TextColor3 = C.Text, Font = C.FontBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9}, Header)

local BtnHolder = make("Frame", {Size = UDim2.fromOffset(62, 22), Position = UDim2.new(1, -72, 0.5, -11), BackgroundTransparency = 1, ZIndex = 9}, Header)
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Right}, BtnHolder)

local function headerBtn(text)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(22, 22), BackgroundColor3 = C.Element,
        Text = text, TextColor3 = C.Text, Font = C.IconFont, TextSize = 14,
        AutoButtonColor = false, ZIndex = 10,
    }, BtnHolder)
    corner(b, 5)
    b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = C.ElementHover}) end)
    b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = C.Element}) end)
    return b
end

local MinimizeBtn = headerBtn("—")
local CloseBtn    = headerBtn("×")
CloseBtn.MouseButton1Click:Connect(function() Gui:Destroy() end)

-- ============ DRAG (без Y-ограничения) ============
do
    local dragging, dragStart, startPos
    local function begin(i) dragging = true; dragStart = i.Position; startPos = Main.Position end
    local function update(i)
        if not dragging then return end
        local d = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
    local function finish() dragging = false end
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then begin(i) end
    end)
    Header.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then update(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then finish() end
    end)
    RunService.RenderStepped:Connect(function()
        Shadow.Position = Main.Position + UDim2.fromOffset(3, 4)
        Shadow.Size = Main.Size
    end)
end

-- ============ SIDEBAR / CONTENT ============
-- Высота уменьшена на 10px снизу (-48 вместо -38), чтобы открыть закругление Main
local Sidebar = make("Frame", {Size = UDim2.new(0, 120, 1, -48), Position = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.Sidebar, BorderSizePixel = 0, ZIndex = 6}, Main)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)
make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8)}, Sidebar)

make("Frame", {Size = UDim2.new(0, 1, 1, -48), Position = UDim2.new(0, 120, 0, 38),
    BackgroundColor3 = C.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 6}, Main)

local Content = make("Frame", {Size = UDim2.new(1, -121, 1, -48), Position = UDim2.new(0, 121, 0, 38),
    BackgroundTransparency = 1, ZIndex = 6}, Main)

-- ============ NOTIFICATIONS ============
local NGui = make("ScreenGui", {Name = "DarkMenuUI_Notifs", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 200}, PGui)
local NCont = make("Frame", {Size = UDim2.new(0, C.NotifWidth, 1, -C.NotifMarginTop - 20),
    Position = UDim2.new(1, -C.NotifWidth - C.NotifMarginRight, 0, C.NotifMarginTop),
    BackgroundTransparency = 1, ZIndex = 1}, NGui)
make("UIListLayout", {Padding = UDim.new(0, C.NotifPadding), SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top}, NCont)
make("UIPadding", {PaddingRight = UDim.new(0, 4)}, NCont)

local Notif = {_items = {}}
local function notifReflow() for i, it in ipairs(Notif._items) do it.Holder.LayoutOrder = i end end

function Notif:Push(text, duration)
    duration = duration or C.NotifDuration
    if #self._items >= C.NotifMaxStack then
        local o = self._items[1]; if o then o:Close() end
        table.remove(self._items, 1)
    end

    local Holder = make("Frame", {Size = UDim2.new(1, 0, 0, C.NotifHeight), BackgroundTransparency = 1, ZIndex = 2}, NCont)
    local ShN = make("Frame", {Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(5, 5),
        BackgroundColor3 = C.Shadow, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 2}, Holder)
    corner(ShN, 12)

    local Card = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Element, BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 3}, Holder)
    corner(Card, 12)
    make("UIGradient", {Rotation = 135, Color = ColorSequence.new(C.ElementHover, C.Element)}, Card)
    local CardStroke = make("UIStroke", {Color = C.Stroke, Transparency = 0.35, Thickness = 1}, Card)

    make("Frame", {Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(10, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 4}, Card)

    local Bar = make("Frame", {Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 5}, Card)
    corner(Bar, 2)

    local TitleLbl = make("TextLabel", {Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(16, 10),
        BackgroundTransparency = 1, Text = C.Title, TextColor3 = C.Accent, Font = C.FontBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, TextTransparency = 1}, Card)

    local Body = make("TextLabel", {Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(16, 28),
        BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = C.Font, TextSize = 13,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 4, TextTransparency = 1}, Card)

    local sx = C.NotifWidth + 40
    Holder.Position = UDim2.fromOffset(sx, 0)
    Card.BackgroundTransparency = 0.4
    CardStroke.Transparency = 1

    local item = {Holder = Holder, Closed = false}
    function item:Close()
        if self.Closed then return end
        self.Closed = true
        tween(Holder, 0.28, {Position = UDim2.fromOffset(sx * 0.6, 0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tween(Card, 0.28, {BackgroundTransparency = 0.5})
        tween(Body, 0.2, {TextTransparency = 1})
        tween(TitleLbl, 0.2, {TextTransparency = 1})
        task.delay(0.3, function()
            for i, v in ipairs(Notif._items) do if v == self then table.remove(Notif._items, i); break end end
            Holder:Destroy(); notifReflow()
        end)
    end
    table.insert(self._items, item); notifReflow()

    tween(Holder, 0.55, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(Card, 0.35, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad)
    tween(CardStroke, 0.35, {Transparency = 0.35}, Enum.EasingStyle.Quad)
    tween(Bar, 0.4, {Size = UDim2.new(0, 3, 1, -18)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(0.1, function() tween(TitleLbl, 0.3, {TextTransparency = 0}) end)
    task.delay(0.15, function() tween(Body, 0.35, {TextTransparency = 0}) end)

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if item.Closed or not Bar.Parent then if conn then conn:Disconnect() end; return end
        Bar.BackgroundTransparency = 0.15 + math.sin(tick() * 4) * 0.15
    end)
    task.delay(duration, function() item:Close() end)
    return item
end

local notify = function(text, duration) return Notif:Push(text, duration) end

-- ============ DROPDOWN OVERLAY ============
local DGui = make("ScreenGui", {Name = "DarkMenuUI_Dropdown", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 150}, PGui)
local DHost = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 1}, DGui)
local DCatch = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1}, DHost)
local DList = make("Frame", {Size = UDim2.fromOffset(200, 100), BackgroundColor3 = C.Element, BorderSizePixel = 0,
    ClipsDescendants = true, ZIndex = 2}, DHost)
corner(DList, 6)
make("UIStroke", {Color = C.StrokeBright, Transparency = 0.4}, DList)
make("UIGradient", {Rotation = 90, Color = ColorSequence.new(C.ElementHover, C.Element)}, DList)
make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, DList)
make("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}, DList)

local currentDD = nil
local function closeDD()
    if not currentDD then return end
    currentDD = nil
    DHost.Visible = false
end

local function openDD(anchor, options, selected, onPick)
    closeDD()
    for _, ch in ipairs(DList:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end

    for _, opt in ipairs(options) do
        local ob = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.Element,
            BackgroundTransparency = (opt == selected) and 0.4 or 1,
            Text = tostring(opt), TextColor3 = (opt == selected) and C.Text or C.SubText,
            Font = C.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, ZIndex = 3,
        }, DList)
        corner(ob, 4)
        make("UIPadding", {PaddingLeft = UDim.new(0, 8)}, ob)
        ob.MouseEnter:Connect(function()
            if opt ~= selected then tween(ob, 0.12, {BackgroundTransparency = 0.6, TextColor3 = C.Text}) end
        end)
        ob.MouseLeave:Connect(function()
            if opt ~= selected then tween(ob, 0.12, {BackgroundTransparency = 1, TextColor3 = C.SubText}) end
        end)
        ob.MouseButton1Click:Connect(function()
            closeDD()
            if onPick then local ok, err = pcall(onPick, opt); if not ok then warn("[DarkMenuUI] Dropdown:", err) end end
        end)
    end

    task.defer(function()
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local h = #options * 28 + 8
        DList.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
        DList.Size = UDim2.fromOffset(as.X, 0)
        DHost.Visible = true
        tween(DList, 0.22, {Size = UDim2.fromOffset(as.X, h)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    currentDD = true
end

DCatch.MouseButton1Click:Connect(closeDD)
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and currentDD then
        local p = input.Position
        local ap, as = DList.AbsolutePosition, DList.AbsoluteSize
        local inside = p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y
        if not inside then closeDD() end
    end
end)

-- ============ LIBRARY ============
local Lib = {Tabs = {}, ActiveTab = nil}
local function styleEl(f) f.BackgroundColor3 = C.Element; f.BackgroundTransparency = 0.15; return stroke(f, C.Stroke, 0.55) end

function Lib:Tab(name)
    local Btn = make("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.Element, BackgroundTransparency = 1,
        Text = "  " .. name, TextColor3 = C.SubText, Font = C.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 7}, Sidebar)
    corner(Btn, 5)

    local Ind = make("Frame", {Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = C.Accent, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 8}, Btn)
    corner(Ind, 2)

    local Page = make("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.AccentDim,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 7}, Content)
    make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, Page)
    make("UIPadding", {PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 3)}, Page)

    local D = {Button = Btn, Page = Page, Indicator = Ind, Name = name}
    Btn.MouseButton1Click:Connect(function() Lib:SelectTab(D) end)
    Btn.MouseEnter:Connect(function() if Lib.ActiveTab ~= D then tween(Btn, 0.15, {BackgroundTransparency = 0.5}) end end)
    Btn.MouseLeave:Connect(function() if Lib.ActiveTab ~= D then tween(Btn, 0.15, {BackgroundTransparency = 1}) end end)

    self.Tabs[#self.Tabs+1] = D
    if #self.Tabs == 1 then self:SelectTab(D) end

    local T = {}
    function T:Button(text, cb) return Lib:Button(D, text, cb) end
    function T:Toggle(text, def, cb) return Lib:Toggle(D, text, def, cb) end
    function T:Slider(text, mn, mx, def, cb) return Lib:Slider(D, text, mn, mx, def, cb) end
    function T:Dropdown(text, opts, def, cb) return Lib:Dropdown(D, text, opts, def, cb) end
    function T:Label(text) return Lib:Label(D, text) end
    function T:Section(text) return Lib:Section(D, text) end
    T._data = D
    return T
end

function Lib:SelectTab(D)
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        tween(t.Button, 0.2, {BackgroundTransparency = 1, TextColor3 = C.SubText})
        tween(t.Indicator, 0.2, {BackgroundTransparency = 1})
    end
    D.Page.Visible = true
    tween(D.Button, 0.2, {BackgroundTransparency = 0.2, TextColor3 = C.Text})
    tween(D.Indicator, 0.2, {BackgroundTransparency = 0})
    self.ActiveTab = D
    closeDD()
end

function Lib:Section(D, text)
    local H = make("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 8}, D.Page)
    local M = make("Frame", {Size = UDim2.fromOffset(2, 10), Position = UDim2.new(0, 2, 0.5, -5),
        BackgroundColor3 = C.AccentSoft, BorderSizePixel = 0, ZIndex = 9}, H)
    corner(M, 1)
    make("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = string.upper(text), TextColor3 = C.Muted,
        Font = C.FontBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9}, H)
    return H
end

function Lib:Label(D, text)
    return make("TextLabel", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
        Text = text, TextColor3 = C.SubText, Font = C.Font, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8}, D.Page)
end

function Lib:Button(D, text, cb)
    local B = make("TextButton", {Size = UDim2.new(1, 0, 0, 30), Text = text, TextColor3 = C.Text,
        Font = C.Font, TextSize = 12, AutoButtonColor = false, ZIndex = 8}, D.Page)
    corner(B, 5)
    local s = styleEl(B)
    B.MouseEnter:Connect(function()
        tween(B, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0})
        tween(s, 0.15, {Transparency = 0.3, Color = C.StrokeBright})
    end)
    B.MouseLeave:Connect(function()
        tween(B, 0.15, {BackgroundColor3 = C.Element, BackgroundTransparency = 0.15})
        tween(s, 0.15, {Transparency = 0.55, Color = C.Stroke})
    end)
    B.MouseButton1Down:Connect(function() tween(B, 0.08, {BackgroundColor3 = C.ElementPress, BackgroundTransparency = 0}) end)
    B.MouseButton1Up:Connect(function() tween(B, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0}) end)
    B.MouseButton1Click:Connect(function()
        if cb then local ok, err = pcall(cb); if not ok then warn("[DarkMenuUI] Button:", err) end end
    end)
    return B
end

function Lib:Toggle(D, text, default, cb)
    local state = default and true or false
    local H = make("Frame", {Size = UDim2.new(1, 0, 0, 32), ZIndex = 8}, D.Page)
    corner(H, 5); local s = styleEl(H)

    make("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = C.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9}, H)

    local Track = make("Frame", {Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -40, 0.5, -8),
        BackgroundColor3 = C.Background, BackgroundTransparency = 0.3, ZIndex = 9}, H)
    corner(Track, 8)
    make("UIStroke", {Color = C.Stroke, Transparency = 0.4}, Track)

    local Knob = make("Frame", {Size = UDim2.fromOffset(12, 12),
        Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = state and C.Accent or C.Muted, ZIndex = 10}, Track)
    corner(Knob, 6)

    local Click = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 11}, H)

    local function apply(on, anim)
        local inf = TweenInfo.new(anim and 0.2 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(Knob, inf, {Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = on and C.Accent or C.Muted}):Play()
        TweenService:Create(Track, inf, {BackgroundColor3 = on and C.AccentDim or C.Background}):Play()
    end
    if state then apply(true, false) end

    Click.MouseButton1Click:Connect(function()
        state = not state; apply(state, true)
        if cb then local ok, err = pcall(cb, state); if not ok then warn("[DarkMenuUI] Toggle:", err) end end
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

function Lib:Slider(D, text, min, max, default, cb)
    min, max = min or 0, max or 100
    default = math.clamp(default or min, min, max)
    local value = default

    local H = make("Frame", {Size = UDim2.new(1, 0, 0, 44), ZIndex = 8}, D.Page)
    corner(H, 5); local s = styleEl(H)

    make("TextLabel", {Size = UDim2.new(1, -80, 0, 18), Position = UDim2.fromOffset(12, 4),
        BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = C.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9}, H)

    local VB = make("Frame", {Size = UDim2.fromOffset(50, 16), Position = UDim2.new(1, -62, 0, 5),
        BackgroundColor3 = C.Background, BackgroundTransparency = 0.3, ZIndex = 9}, H)
    corner(VB, 3)

    local VL = make("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = tostring(value), TextColor3 = C.Text, Font = C.FontBold, TextSize = 11, ZIndex = 10}, VB)

    local Bg = make("Frame", {Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 1, -12),
        BackgroundColor3 = C.Background, BackgroundTransparency = 0.3, ZIndex = 9}, H)
    corner(Bg, 3)

    local Fill = make("Frame", {Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent, ZIndex = 10}, Bg)
    corner(Fill, 3)

    local Knob = make("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0), BackgroundColor3 = C.Text, ZIndex = 11}, Bg)
    corner(Knob, 6)
    make("UIStroke", {Color = C.StrokeBright}, Knob)

    local dragging = false
    local function setX(x)
        local rel = math.clamp((x - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1)
        value = math.floor((min + (max - min) * rel) * 100 + 0.5) / 100
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        VL.Text = tostring(value)
        if cb then local ok, err = pcall(cb, value); if not ok then warn("[DarkMenuUI] Slider:", err) end end
    end
    Bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setX(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
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
            v = math.clamp(v, min, max); value = v
            local rel = (v - min) / (max - min)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, 0, 0.5, 0)
            VL.Text = tostring(v)
            if cb then pcall(cb, v) end
        end,
        Get = function() return value end,
    }
end

function Lib:Dropdown(D, text, options, default, cb)
    options = options or {}
    local selected = default or options[1]

    local H = make("Frame", {Size = UDim2.new(1, 0, 0, 32), ZIndex = 8}, D.Page)
    corner(H, 5); local s = styleEl(H)

    make("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = C.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9}, H)

    local VL = make("TextLabel", {Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -120, 0, 0),
        BackgroundTransparency = 1, Text = tostring(selected), TextColor3 = C.SubText, Font = C.Font,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9}, H)

    make("TextLabel", {Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -20, 0.5, -8),
        BackgroundTransparency = 1, Text = "▼", TextColor3 = C.SubText, Font = C.IconFont,
        TextSize = 12, ZIndex = 9}, H)

    local Click = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 11}, H)
    Click.MouseEnter:Connect(function()
        tween(H, 0.15, {BackgroundColor3 = C.ElementHover, BackgroundTransparency = 0})
        tween(s, 0.15, {Transparency = 0.3, Color = C.StrokeBright})
    end)
    Click.MouseLeave:Connect(function()
        tween(H, 0.15, {BackgroundColor3 = C.Element, BackgroundTransparency = 0.15})
        tween(s, 0.15, {Transparency = 0.55, Color = C.Stroke})
    end)
    Click.MouseButton1Click:Connect(function()
        openDD(H, options, selected, function(chosen)
            selected = chosen
            VL.Text = tostring(selected)
            if cb then local ok, err = pcall(cb, selected); if not ok then warn("[DarkMenuUI] Dropdown:", err) end end
        end)
    end)

    return {
        Set = function(v)
            if table.find(options, v) then
                selected = v; VL.Text = tostring(v)
                if cb then pcall(cb, selected) end
            end
        end,
        Get = function() return selected end,
        SetOptions = function(o) options = o or {} end,
    }
end

-- ============ MINIMIZE + TOGGLE ============
local minimized = false
local origSize = C.Size
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    tween(Main, 0.25, {Size = minimized and UDim2.new(0, origSize.X.Offset, 0, 38) or origSize})
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == C.ToggleKey then
        Main.Visible = not Main.Visible
        Shadow.Visible = Main.Visible
    end
end)

-- ============ PUBLIC ============
Lib.Notify = notify
Lib.Config = C
Lib.Gui = Gui

return Lib
