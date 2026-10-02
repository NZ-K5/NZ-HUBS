local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

for _, k in ipairs({ "__NZCleanA", "__NZCleanCM", "__NZCleanBH", "__NZCleanPL", "__NZCleanLZ", "__NZCleanMZ", "__NZCleanIS", "__NZCleanGFX" }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    if _G.__NZHub then _G.__NZHub:Destroy() _G.__NZHub = nil end
    if _G.__NZFly then _G.__NZFly:Destroy() _G.__NZFly = nil end
    if _G.__NZHUB then _G.__NZHUB:Destroy() _G.__NZHUB = nil end
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZHub", "NZFly", "BackdoorRoot", "ModRoot", "InfectiousRoot", "NZ-HUB" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur" then
        pcall(function() v:Destroy() end)
    end
end
_G.__NZFlyActive = false
_G.__NZFlyStop = nil
_G.__NZFlyHold = { forward = false, back = false, up = false, down = false, left = false, right = false }

local COL_BG       = Color3.fromRGB(18, 19, 24)
local COL_BG_ALT   = Color3.fromRGB(26, 27, 34)
local COL_BORDER   = Color3.fromRGB(48, 50, 62)
local COL_TEXT     = Color3.fromRGB(230, 232, 240)
local COL_TEXT_DIM = Color3.fromRGB(130, 134, 152)
local COL_ACCENT   = Color3.fromRGB(88, 140, 255)
local COL_GREEN    = Color3.fromRGB(72, 196, 120)
local COL_RED      = Color3.fromRGB(214, 78, 78)
local COL_YELLOW   = Color3.fromRGB(230, 190, 90)
local ON_BG, OFF_BG = Color3.fromRGB(20, 60, 30), Color3.fromRGB(40, 20, 20)
local ON_TX, OFF_TX = Color3.fromRGB(100, 255, 100), Color3.fromRGB(255, 100, 100)

local function corner(obj, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = obj; return c
end
local function stroke(obj, col, t)
    local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = obj; return s
end
local function setToggle(btn, on, onText, offText)
    btn.Text = on and (onText or "ON") or (offText or "OFF")
    TweenService:Create(btn, TweenInfo.new(0.18), {
        BackgroundColor3 = on and COL_GREEN or COL_BG_ALT,
        TextColor3 = on and Color3.fromRGB(255, 255, 255) or COL_TEXT_DIM }):Play()
end
local function flashOk(obj)
    local s = nil
    if obj and obj:IsA("UIStroke") then s = obj
    elseif obj then s = obj:FindFirstChildWhichIsA("UIStroke") end
    if not s then return end
    TweenService:Create(s, TweenInfo.new(0.12), { Color = COL_GREEN }):Play()
    task.delay(0.25, function()
        if s and s.Parent then TweenService:Create(s, TweenInfo.new(0.35), { Color = COL_BORDER }):Play() end
    end)
end
local function flashErr(box)
    if not box then return end
    box.TextColor3 = COL_RED
    TweenService:Create(box, TweenInfo.new(0.4), { TextColor3 = COL_TEXT }):Play()
end
local function isAnyTextBoxFocused()
    local ok, f = pcall(function() return UserInputService:GetFocusedTextBox() end)
    return ok and f ~= nil
end
local function isVehicleModel(m)
    if not m:IsA("Model") then return false end
    local parts, hasSeat, hasWheel = 0, false, false
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then parts = parts + 1 end
        if d:IsA("Seat") or d:IsA("VehicleSeat") then hasSeat = true end
        local nm = d.Name
        if nm == "Wheels" or nm == "FL" or nm == "FR" or nm == "Body" or nm == "Chassis" then hasWheel = true end
        if parts >= 3 and (hasSeat or hasWheel) then return true end
        if parts > 300 then break end
    end
    return false
end

local function findRiddenModelFallback()
    local ch = player.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pp = root.Position
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") and isVehicleModel(m) then
            local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
            if ok and cf then
                local rel = cf:PointToObjectSpace(pp)
                if math.abs(rel.X) <= size.X * 0.5 + 2
                    and math.abs(rel.Y) <= size.Y * 0.5 + 3
                    and math.abs(rel.Z) <= size.Z * 0.5 + 2 then
                    return m
                end
            end
        end
    end
    return nil
end

local WIN_W, WIN_H = 640, 440
if isMobile then
    local vp0 = camera.ViewportSize
    WIN_W = math.clamp(vp0.X - 20, 300, 420)
    WIN_H = math.clamp(vp0.Y - 120, 320, 440)
end

local gui = Instance.new("ScreenGui")
gui.Name = "NZ-HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10000
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB = gui
_G.__NZHub = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur"
blur.Size = 6
blur.Parent = Lighting

local main = Instance.new("Frame")
main.Name = "Window"
main.Size = UDim2.new(0, WIN_W, 0, 36)
main.Position = UDim2.new(0.5, -WIN_W / 2, 0.45, -WIN_H / 2)
main.BackgroundColor3 = COL_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 12)
stroke(main, COL_BORDER, 1)
local mouseFreed = false
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end)
            mouseFreed = true
        end
    end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if not mouseFreed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if gp then return end
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end)
    mouseFreed = false
end)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = COL_BG_ALT
titleBar.BorderSizePixel = 0
titleBar.Parent = main
corner(titleBar, 12)
local under = Instance.new("Frame")
under.Size = UDim2.new(1, 0, 0, 12)
under.Position = UDim2.new(0, 0, 1, -12)
under.BackgroundColor3 = COL_BG_ALT
under.BorderSizePixel = 0
under.Parent = titleBar
local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 3, 0, 16)
accent.Position = UDim2.new(0, 12, 0.5, -8)
accent.BackgroundColor3 = COL_ACCENT
accent.BorderSizePixel = 0
accent.Parent = titleBar
corner(accent, 2)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 22, 0, 0)
title.BackgroundTransparency = 1
title.Text = "NZ-HUB"
title.TextColor3 = COL_TEXT
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -32, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(38, 39, 48)
minBtn.Text = "-"
minBtn.TextColor3 = COL_TEXT_DIM
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
minBtn.AutoButtonColor = false
minBtn.Parent = titleBar
corner(minBtn, 6)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -60, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(38, 39, 48)
closeBtn.Text = "X"
closeBtn.TextColor3 = COL_TEXT_DIM
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function()
    for _, k in ipairs({ "__NZCleanA", "__NZCleanCM", "__NZCleanBH", "__NZCleanPL", "__NZCleanLZ", "__NZCleanMZ", "__NZCleanIS", "__NZCleanGFX" }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZFlyActive = false
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    if _G.__NZFlyStop then pcall(_G.__NZFlyStop) end
    if _G.__NZSitStop then pcall(_G.__NZSitStop) end
    if _G.__NZHoldFlingStop then pcall(_G.__NZHoldFlingStop) end
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB, _G.__NZHub, _G.__NZFly = nil, nil, nil
    _G.__NZFlyStop, _G.__NZSitStop, _G.__NZHoldFlingStop = nil, nil, nil
end)

do
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 30)
tabBar.Position = UDim2.new(0, 12, 0, 42)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local TAB_DEFS = { "Player", "Utility", "Other Scripts", "HUBS" }
local tabBtns, pages = {}, {}
local function createPage(name)
    local pg = Instance.new("ScrollingFrame")
    pg.Name = name
    pg.Size = UDim2.new(1, -24, 1, -84)
    pg.Position = UDim2.new(0, 12, 0, 76)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.ScrollBarThickness = 4
    pg.ScrollBarImageColor3 = COL_ACCENT
    pg.CanvasSize = UDim2.new(0, 0, 0, 500)
    pg.ScrollingDirection = isMobile and Enum.ScrollingDirection.XY or Enum.ScrollingDirection.Y
    pg.Visible = false
    pg.Parent = main
    return pg
end
for i, name in ipairs(TAB_DEFS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / #TAB_DEFS, -6, 1, 0)
    b.Position = UDim2.new((i - 1) / #TAB_DEFS, (i == 1) and 0 or 3, 0, 0)
    b.BackgroundColor3 = COL_BG_ALT
    b.Text = name
    b.TextColor3 = COL_TEXT_DIM
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = tabBar
    corner(b, 6)
    stroke(b, COL_BORDER, 1)
    tabBtns[name] = b
    pages[name] = createPage(name)
end
local currentTab = "Player"
local function selectTab(name)
    currentTab = name
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        if n == name then
            b.BackgroundColor3 = COL_ACCENT; b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = COL_BG_ALT; b.TextColor3 = COL_TEXT_DIM
        end
    end
end
for n, b in pairs(tabBtns) do b.MouseButton1Click:Connect(function() selectTab(n) end) end
if isMobile then for _, b in pairs(tabBtns) do b.TextSize = 9 end end
if not isMobile and #TAB_DEFS > 8 then for _, b in pairs(tabBtns) do b.TextSize = 10 end end
selectTab("Player")

local FULL_H = WIN_H
local MINI_S = 64
local minimized = false
local function tweenMain(h)
    TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, WIN_W, 0, h),
    }):Play()
end
local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 48, 0, 48)
miniBtn.Position = UDim2.new(0.5, -24, 0.5, -24)
miniBtn.BackgroundColor3 = COL_BG_ALT
miniBtn.Text = "+"
miniBtn.TextColor3 = COL_TEXT
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 28
miniBtn.BorderSizePixel = 0
miniBtn.Visible = false
miniBtn.Parent = main
corner(miniBtn, 12)
stroke(miniBtn, COL_ACCENT, 1)
local function setMinimized(on)
    minimized = on
    if on then
        titleBar.Visible = false
        tabBar.Visible = false
        for _, pg in pairs(pages) do pg.Visible = false end
        miniBtn.Visible = true
        blur.Size = 0
        main.Position = UDim2.new(1, -MINI_S - 12, 1, -MINI_S - 12)
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, MINI_S, 0, MINI_S),
        }):Play()
    else
        miniBtn.Visible = false
        titleBar.Visible = true
        tabBar.Visible = true
        selectTab(currentTab)
        blur.Size = 6
        main.Position = UDim2.new(0.5, -WIN_W / 2, 0.45, -WIN_H / 2)
        tweenMain(FULL_H)
    end
end
task.spawn(function() task.wait(0.05) tweenMain(FULL_H) end)
minBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)
local miniDrag, miniStart, miniOrig, miniMoved = false, nil, nil, false
miniBtn.MouseButton1Click:Connect(function()
    if miniMoved then miniMoved = false return end
    setMinimized(false)
end)
miniBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDrag = true
        miniStart = input.Position
        miniOrig = main.Position
    end
end)
miniBtn.InputChanged:Connect(function(input)
    if miniDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - miniStart
        if math.abs(d.X) + math.abs(d.Y) > 10 then miniMoved = true end
        if miniMoved then
            main.Position = UDim2.new(miniOrig.X.Scale, miniOrig.X.Offset + d.X, miniOrig.Y.Scale, miniOrig.Y.Offset + d.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDrag = false
    end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        setMinimized(not minimized)
    end
end)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if minimized then
        main.Position = UDim2.new(1, -MINI_S - 12, 1, -MINI_S - 12)
    else
        main.Position = UDim2.new(0.5, -WIN_W / 2, 0.45, -WIN_H / 2)
    end
end)

local function pageLabel(parent, y, text, w)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, math.min(600, math.max(w or 150, math.ceil(#text * 6.4) + 10)), 0, 22)
    l.Position = UDim2.new(0, 4, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = COL_TEXT_DIM
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end
local function pageBox(parent, y, x, w, def)
    local b = Instance.new("TextBox")
    b.Size = UDim2.new(0, w or 110, 0, 26)
    b.Position = UDim2.new(0, x or 160, 0, y)
    b.BackgroundColor3 = COL_BG_ALT
    b.Text = tostring(def or "")
    b.TextColor3 = COL_TEXT
    b.PlaceholderColor3 = COL_TEXT_DIM
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.ClearTextOnFocus = false
    b.Parent = parent
    corner(b, 6)
    local s = stroke(b, COL_BORDER, 1)
    return b, s
end
local function pageApply(parent, y, x, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 64, 0, 26)
    b.Position = UDim2.new(0, x or 278, 0, y)
    b.BackgroundColor3 = COL_ACCENT
    b.Text = text or "Apply"
    b.TextColor3 = COL_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 6)
    return b
end
local function pageToggle(parent, y, x, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w or 80, 0, 26)
    b.Position = UDim2.new(0, x or 160, 0, y)
    b.BackgroundColor3 = OFF_BG
    b.Text = "OFF"
    b.TextColor3 = OFF_TX
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 6)
    return b
end
local function pageWideBtn(parent, y, text, bg)
    local b = Instance.new("TextButton")
    local baseBg = bg or COL_BG_ALT
    b.Size = UDim2.new(0, 220, 0, 30)
    b.Position = UDim2.new(0, 4, 0, y)
    b.BackgroundColor3 = baseBg
    b.Text = text
    b.TextColor3 = COL_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 6)
    stroke(b, COL_BORDER, 1)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = COL_ACCENT, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = baseBg, TextColor3 = COL_TEXT }):Play()
    end)
    return b
end


do
    local page = pages["Player"]
    local y = 4
    pageLabel(page, y, "Infinite Jump"); local bhInfJ = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Noclip"); local bhNoclip = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Fly Speed"); local bhFlyBox = pageBox(page, y - 2, 160, 90, "50"); local bhFlyApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Player Fly"); local bhFly = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "WalkSpeed");  local bhWSBox = pageBox(page, y - 2, 160, 90, "16"); local bhWSApply = pageApply(page, y - 2, 258); y = y + 30
    pageLabel(page, y, "Speed Loop"); local wsLoopTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "JumpPower");  local bhJPBox = pageBox(page, y - 2, 160, 90, "50"); local bhJPApply = pageApply(page, y - 2, 258); y = y + 30
    pageLabel(page, y, "Enable Jump"); local bhJumpTog = pageToggle(page, y - 2, 160); setToggle(bhJumpTog, true); y = y + 30
    pageLabel(page, y, "Enable Third-Person"); local bhTPTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Character Hitbox"); local bhHBBox = pageBox(page, y - 2, 160, 90, "1"); local bhHBApply = pageApply(page, y - 2, 258, "Set"); y = y + 34
    local bhRespawn = pageWideBtn(page, y, "Respawn"); y = y + 34
    pageLabel(page, y, "ESP"); local espTog = pageToggle(page, y - 2, 160); espTog.Text = "ESP: Off"; y = y + 30
    pageLabel(page, y, "ESP Radius"); local espRadBox = pageBox(page, y - 2, 160, 90, "500"); local espRadApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    local espDestroy = pageWideBtn(page, y, "Destroy ESP"); y = y + 34
    pageLabel(page, y, "Aimbot"); local abTog = pageToggle(page, y - 2, 160, 110); abTog.Text = "Aimbot: Off"; y = y + 30
    pageLabel(page, y, "Aim Radius"); local abBox = pageBox(page, y - 2, 160, 90, "120"); local abApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Team Check"); local abTeamTog = pageToggle(page, y - 2, 160); setToggle(abTeamTog, false); y = y + 34
    pageLabel(page, y, "Clicks Per Click"); local mcCountBox = pageBox(page, y - 2, 160, 90, "1"); local mcCountApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Click Delay"); local mcDelayBox = pageBox(page, y - 2, 160, 90, "0.1"); local mcDelayApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Multi-click"); local mcTog = pageToggle(page, y - 2, 160); y = y + 34
    local plStatus = Instance.new("TextLabel")
    plStatus.Size = UDim2.new(1, -8, 0, 16); plStatus.Position = UDim2.new(0, 4, 0, y)
    plStatus.BackgroundTransparency = 1; plStatus.Text = "Status: Ready"; plStatus.TextColor3 = COL_GREEN
    plStatus.Font = Enum.Font.Gotham; plStatus.TextSize = 10; plStatus.TextXAlignment = Enum.TextXAlignment.Left; plStatus.Parent = page
    page.CanvasSize = UDim2.new(0, 0, 0, y + 30)
    local noclipOn, infJOn, pflyOn = false, false, false
    local pflySpeed, pflyConn, ncChar, standOff, flyWas = 50, nil, nil, 3, false
    local wsVal, wsLoopOn, wsLoopRun = 16, false, false
    local noclipConns, infJConn, origColl = {}, nil, {}
    local lagClone, lagChar, lagTrans, lagT, lagCount = nil, nil, {}, 0, 0
    local function lagClear()
        if lagClone then pcall(function() lagClone:Destroy() end) lagClone = nil end
        lagChar = nil
    end
    local function lagShow()
        lagCount = lagCount + 1
        if lagCount > 1 then return end
        local ch = player.Character
        if not ch then lagCount = 0 return end
        lagChar = ch
        lagTrans = {}
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then lagTrans[p] = p.Transparency p.Transparency = 1 end
        end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
        lagT = 4
    end
    local function lagHide()
        lagCount = lagCount - 1
        if lagCount < 0 then lagCount = 0 end
        if lagCount > 0 then return end
        lagT = 0
        local ch = player.Character
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and lagTrans[p] ~= nil then p.Transparency = lagTrans[p] end
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
        end
        lagTrans = {}
        lagClear()
    end
    local function lagTick(dt)
        if lagCount <= 0 then return end
        local ch = player.Character
        if not ch then return end
        if ch ~= lagChar then
            lagClear()
            lagChar = ch
            lagTrans = {}
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then lagTrans[p] = p.Transparency p.Transparency = 1 end
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
        end
        lagT = lagT + dt
        if lagT >= 4 then
            lagT = 0
            lagClear()
            local m = Instance.new("Model")
            m.Name = player.Name
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then
                    local c = p:Clone()
                    c.Anchored = true
                    c.CanCollide = false
                    c.CanQuery = false
                    c.CanTouch = false
                    c.Transparency = lagTrans[p] or 0
                    c.Parent = m
                end
            end
            m.Parent = Workspace
            lagClone = m
        end
    end
    bhNoclip.MouseButton1Click:Connect(function()
        local ch = player.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hum or not root then plStatus.Text = "No character"; plStatus.TextColor3 = COL_RED return end
        noclipOn = not noclipOn; setToggle(bhNoclip, noclipOn)
        if noclipOn then
            ncChar = ch
            origColl = {}
            pcall(function()
                local ps = game:GetService("PhysicsService")
                pcall(function() ps:RegisterCollisionGroup("NZGhost") end)
                ps:CollisionGroupSetCollidable("NZGhost", "Default", false)
            end)
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then
                    if origColl[p] == nil then origColl[p] = { c = p.CanCollide, t = p.CanTouch, g = p.CollisionGroup } end
                    pcall(function() p.CollisionGroup = "NZGhost" end)
                end
            end
            local rp0 = RaycastParams.new()
            rp0.FilterType = Enum.RaycastFilterType.Exclude
            rp0.FilterDescendantsInstances = { ch }
            local hit0 = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), rp0)
            standOff = hit0 and (root.Position.Y - hit0.Position.Y) or (hum.HipHeight + root.Size.Y * 0.5)
            local hb
            hb = RunService.Heartbeat:Connect(function(dt)
                if not noclipOn then return end
                lagTick(dt)
                local c2 = player.Character
                local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
                if not r2 or not h2 then return end
                if c2 ~= ncChar then
                    ncChar = c2
                    for _, p in ipairs(c2:GetDescendants()) do
                        if p:IsA("BasePart") and origColl[p] == nil then
                            origColl[p] = { c = p.CanCollide, t = p.CanTouch, g = p.CollisionGroup }
                        end
                    end
                end
                for _, p in ipairs(c2:GetDescendants()) do
                    if p:IsA("BasePart") and p.CollisionGroup ~= "NZGhost" then
                        if origColl[p] == nil then origColl[p] = { c = p.CanCollide, t = p.CanTouch, g = p.CollisionGroup } end
                        pcall(function() p.CollisionGroup = "NZGhost" end)
                    end
                end
                if h2.SeatPart then return end
                if r2.AssemblyLinearVelocity.Y > 1 then return end
                local prm = RaycastParams.new()
                prm.FilterType = Enum.RaycastFilterType.Exclude
                prm.FilterDescendantsInstances = { c2 }
                local h = Workspace:Raycast(r2.Position, Vector3.new(0, -(standOff + 6), 0), prm)
                if h then
                    local gy = h.Position.Y + standOff
                    if r2.Position.Y <= gy + 0.5 then
                        r2.CFrame = CFrame.new(r2.Position.X, gy, r2.Position.Z) * (r2.CFrame - r2.CFrame.Position)
                    end
                end
            end)
            table.insert(noclipConns, hb)
            lagShow()
            plStatus.Text = "Noclip ON (floor kept)"
        else
            for p, d in pairs(origColl) do pcall(function() p.CanCollide = d.c; p.CanTouch = d.t; if d.g then p.CollisionGroup = d.g end end) end
            origColl = {}
            for _, c in ipairs(noclipConns) do pcall(function() c:Disconnect() end) end
            noclipConns = {}
            lagHide()
            plStatus.Text = "Noclip OFF"
        end
    end)
    bhInfJ.MouseButton1Click:Connect(function()
        infJOn = not infJOn; setToggle(bhInfJ, infJOn)
        if infJConn then pcall(function() infJConn:Disconnect() end) infJConn = nil end
        if infJOn then
            infJConn = UserInputService.JumpRequest:Connect(function()
                local ch = player.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end)
        end
    end)
    bhFlyApply.MouseButton1Click:Connect(function()
        local n = tonumber(bhFlyBox.Text)
        if n and n >= 1 then pflySpeed = math.clamp(n, 1, 500); bhFlyBox.Text = tostring(pflySpeed); flashOk(bhFlyBox)
        else flashErr(bhFlyBox) end
    end)
    bhFly.MouseButton1Click:Connect(function()
        pflyOn = not pflyOn; setToggle(bhFly, pflyOn)
        if pflyConn then pcall(function() pflyConn:Disconnect() end) pflyConn = nil end
        if pflyOn then
            lagShow()
            plStatus.Text = "Fly ON (WASD + E/Q)"
            pflyConn = RunService.Heartbeat:Connect(function(dt)
                if not pflyOn then return end
                lagTick(dt)
                local ch = player.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if not hum or not root then return end
                local md = hum.MoveDirection
                local vel = Vector3.new(md.X, 0, md.Z) * pflySpeed
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then vel = vel + Vector3.new(0, pflySpeed, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then vel = vel - Vector3.new(0, pflySpeed, 0) end
                if vel.Magnitude < 0.01 then
                    if flyWas then
                        flyWas = false
                        pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
                    end
                    return
                end
                flyWas = true
                pcall(function()
                    root.AssemblyLinearVelocity = vel
                end)
            end)
        else
            local ch = player.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end
            flyWas = false
            lagHide()
            plStatus.Text = "Fly OFF"
        end
    end)
    bhWSApply.MouseButton1Click:Connect(function()
        local ch = player.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then local n = tonumber(bhWSBox.Text); if n then hum.WalkSpeed = n; wsVal = n; flashOk(bhWSBox) else flashErr(bhWSBox) end end
    end)
    wsLoopTog.MouseButton1Click:Connect(function()
        wsLoopOn = not wsLoopOn; setToggle(wsLoopTog, wsLoopOn)
        if wsLoopOn and not wsLoopRun then
            wsLoopRun = true
            task.spawn(function()
                while wsLoopOn do
                    local ch = player.Character
                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local n = tonumber(bhWSBox.Text)
                        if n then wsVal = n end
                        hum.WalkSpeed = wsVal
                    end
                    task.wait(0.5)
                end
                wsLoopRun = false
            end)
        end
        plStatus.Text = wsLoopOn and "Speed loop ON" or "Speed loop OFF"
    end)
    bhJPApply.MouseButton1Click:Connect(function()
        local ch = player.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            local n = tonumber(bhJPBox.Text)
            if n then
                pcall(function() hum.JumpPower = n end)
                pcall(function() hum.JumpHeight = n / 2 end)
                flashOk(bhJPBox); plStatus.Text = "Jump set"
            else flashErr(bhJPBox) end
        end
    end)
    local jumpAllow = true
    local function applyJump()
        local ch = player.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpAllow) end) end
    end
    bhJumpTog.MouseButton1Click:Connect(function()
        jumpAllow = not jumpAllow; setToggle(bhJumpTog, jumpAllow)
        applyJump()
        plStatus.Text = jumpAllow and "Jump enabled" or "Jump disabled"
    end)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyJump()
    end)
    local tpOn, tpMode, tpZoom = false, nil, nil
    bhTPTog.MouseButton1Click:Connect(function()
        tpOn = not tpOn; setToggle(bhTPTog, tpOn)
        local cam = Workspace.CurrentCamera
        if tpOn then
            tpMode = player.CameraMode
            if cam then tpZoom = cam.MaxZoomDistance end
            player.CameraMode = Enum.CameraMode.Classic
            if cam and cam.MaxZoomDistance < 12 then cam.MaxZoomDistance = 60 end
            plStatus.Text = "Third-person on"
        else
            if tpMode then player.CameraMode = tpMode end
            if tpZoom and cam then cam.MaxZoomDistance = tpZoom end
            plStatus.Text = "Camera restored"
        end
    end)
    local chHbMult, chHbOrig, chHbChar = 1, nil, nil
    local function chHbApply()
        local ch = player.Character
        local rp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not rp then plStatus.Text = "No character"; plStatus.TextColor3 = COL_RED return false end
        if ch ~= chHbChar then chHbChar = ch; chHbOrig = rp.Size end
        pcall(function()
            rp.Size = chHbOrig * chHbMult
            rp.CanCollide = false
        end)
        return true
    end
    bhHBApply.MouseButton1Click:Connect(function()
        local n = tonumber(bhHBBox.Text)
        if n and n >= 0.5 and n <= 20 then
            chHbMult = n
            if chHbApply() then
                bhHBBox.Text = tostring(chHbMult); flashOk(bhHBBox)
                plStatus.Text = "Hitbox x" .. tostring(chHbMult); plStatus.TextColor3 = COL_GREEN
            end
        else flashErr(bhHBBox) end
    end)
    player.CharacterAdded:Connect(function(ch)
        ch:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5)
        if chHbMult ~= 1 then chHbApply() end
    end)
    bhRespawn.MouseButton1Click:Connect(function()
        local ch = player.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
    local espOn, espTracked, espConn, espAcc, espFrame, espPhase, espLastT, espLastS, espShown = false, {}, nil, 0, 0, 0, -1, -1, 0
    local espRad = 500
    espRadApply.MouseButton1Click:Connect(function()
        local n = tonumber(espRadBox.Text)
        if n then espRad = math.clamp(n, 50, 10000); espRadBox.Text = tostring(espRad); flashOk(espRadBox); plStatus.Text = "ESP radius " .. tostring(espRad)
        else flashErr(espRadBox) end
    end)
    local function espTeam(plr)
        local col = Color3.fromRGB(255, 255, 255)
        pcall(function()
            if plr.Team then col = plr.TeamColor.Color end
        end)
        return col
    end
    local function espMake()
        local box = Drawing.new("Square")
        box.Visible = false
        box.Filled = false
        box.Thickness = 1.5
        local name = Drawing.new("Text")
        name.Visible = false
        name.Centered = true
        name.Size = 13
        name.Outline = true
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Thickness = 1.2
        return { box = box, name = name, tracer = tracer }
    end
    local function espDrop(set)
        pcall(function() set.box:Remove() end)
        pcall(function() set.name:Remove() end)
        pcall(function() set.tracer:Remove() end)
    end
    local function espHide(set)
        set.box.Visible = false
        set.name.Visible = false
        set.tracer.Visible = false
    end
    local function espCache(plr)
        local e = espTracked[plr]
        if not e then
            e = espMake()
            e.phase = espPhase
            espPhase = espPhase + 1
            if espPhase >= 3 then espPhase = 0 end
            espTracked[plr] = e
        end
        e.char = plr.Character
        e.hum = e.char and e.char:FindFirstChildOfClass("Humanoid")
        e.root = e.char and e.char:FindFirstChild("HumanoidRootPart")
        e.team = plr.Team
        e.col = espTeam(plr)
        e.label = plr.Name
        return e
    end
    local function espSync()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and not espTracked[plr] then
                espCache(plr)
            end
        end
        for plr, set in pairs(espTracked) do
            if plr.Parent ~= Players then
                espDrop(set)
                espTracked[plr] = nil
            end
        end
    end
    espTog.MouseButton1Click:Connect(function()
        if not espOn then
            local okD, test = pcall(function() return Drawing.new("Square") end)
            if not okD or not test then plStatus.Text = "Drawing unsupported"; plStatus.TextColor3 = COL_RED return end
            pcall(function() test:Remove() end)
        end
        espOn = not espOn; setToggle(espTog, espOn, "ESP: On", "ESP: Off")
        if espConn then pcall(function() espConn:Disconnect() end) espConn = nil end
        if espOn then
            espSync()
            plStatus.Text = "ESP ON"
            espConn = RunService.RenderStepped:Connect(function(dt)
                espAcc = espAcc + dt
                if espAcc >= 2 then
                    espAcc = 0
                    espSync()
                    local total = 0
                    for _ in pairs(espTracked) do total = total + 1 end
                    if total ~= espLastT or espShown ~= espLastS then
                        espLastT, espLastS = total, espShown
                        plStatus.Text = "ESP " .. tostring(espShown) .. "/" .. total .. " in range"
                    end
                end
                espFrame = espFrame + 1
                local cam = Workspace.CurrentCamera
                if not cam then return end
                local ch0 = player.Character
                local root0 = ch0 and ch0:FindFirstChild("HumanoidRootPart")
                local from
                if root0 then
                    local v, on = cam:WorldToViewportPoint(root0.Position)
                    if on then from = Vector2.new(v.X, v.Y) end
                end
                if not from then from = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y) end
                local camPos = cam.CFrame.Position
                local pShown = 0
                for plr, e in pairs(espTracked) do
                    if not e.root or not e.root.Parent or e.char ~= plr.Character or e.team ~= plr.Team then
                        espCache(plr)
                    end
                    local hum, root = e.hum, e.root
                    if hum and root and hum.Health > 0 then
                        local d = (camPos - root.Position).Magnitude
                        if d > espRad then
                            espHide(e)
                        elseif d <= 400 or (espFrame + (e.phase or 0)) % 3 == 0 then
                            local v, on = cam:WorldToViewportPoint(root.Position)
                            if on then
                                local h = math.clamp(1500 / math.max(d, 1), 20, 300)
                                local w = h * 0.6
                                e.box.Size = Vector2.new(w, h)
                                e.box.Position = Vector2.new(v.X - w * 0.5, v.Y - h * 0.5)
                                e.box.Color = e.col
                                e.box.Visible = true
                                e.name.Text = e.label .. " [" .. math.floor(d + 0.5) .. "]"
                                e.name.Position = Vector2.new(v.X, v.Y - h * 0.5 - 14)
                                e.name.Color = e.col
                                e.name.Visible = true
                                e.tracer.From = from
                                e.tracer.To = Vector2.new(v.X, v.Y)
                                e.tracer.Color = e.col
                                e.tracer.Visible = true
                                pShown = pShown + 1
                            else
                                espHide(e)
                            end
                        end
                    else
                        espHide(e)
                    end
                end
                espShown = pShown
            end)
        else
            for _, set in pairs(espTracked) do espHide(set) end
            plStatus.Text = "ESP OFF"
        end
    end)
    espDestroy.MouseButton1Click:Connect(function()
        espOn = false; setToggle(espTog, espOn, "ESP: On", "ESP: Off")
        if espConn then pcall(function() espConn:Disconnect() end) espConn = nil end
        for plr, set in pairs(espTracked) do espDrop(set) espTracked[plr] = nil end
        plStatus.Text = "ESP destroyed"
    end)
    local abOn, abRadius, abTeam, abConn, abCircle, abHolding = false, 120, false, nil, nil, false
    abApply.MouseButton1Click:Connect(function()
        local n = tonumber(abBox.Text)
        if n then abRadius = math.clamp(n, 20, 600); abBox.Text = tostring(abRadius); flashOk(abBox)
            if abCircle then abCircle.Radius = abRadius end
        else flashErr(abBox) end
    end)
    abTeamTog.MouseButton1Click:Connect(function()
        abTeam = not abTeam; setToggle(abTeamTog, abTeam)
    end)
    abTog.MouseButton1Click:Connect(function()
        abOn = not abOn; setToggle(abTog, abOn, "Aimbot: On", "Aimbot: Off")
        if abConn then pcall(function() abConn:Disconnect() end) abConn = nil end
        if abOn then
            if not abCircle or not abCircle.Parent then
                pcall(function()
                    if abCircle then abCircle:Remove() end
                    local c = Drawing.new("Circle")
                    c.Visible = false
                    c.NumSides = 64
                    c.Thickness = 1.5
                    c.Color = Color3.fromRGB(255, 60, 60)
                    c.Radius = abRadius
                    abCircle = c
                end)
            end
            plStatus.Text = "Aimbot ON (hold R-Click)"
            abConn = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if not cam then return end
                if abCircle then
                    abCircle.Position = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
                    abCircle.Radius = abRadius
                    abCircle.Visible = abOn
                end
                if not abOn or not abHolding then return end
                _G.__NZAbLock = false
                local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
                local best, bestPart, bestD = nil, nil, abRadius
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player then
                        local ch = plr.Character
                        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if not (abTeam and plr.Team and player.Team and plr.Team == player.Team) then
                                local part = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
                                if part then
                                    local v, on = cam:WorldToViewportPoint(part.Position)
                                    if on then
                                        local d = (Vector2.new(v.X, v.Y) - Vector2.new(cx, cy)).Magnitude
                                        if d <= bestD then best, bestPart, bestD = plr, part, d end
                                    end
                                end
                            end
                        end
                    end
                end
                if best and bestPart and bestPart.Parent then
                    local ch0 = player.Character
                    local camPos = cam.CFrame.Position
                    _G.__NZAbLock = true
                    pcall(function()
                        cam.CFrame = CFrame.new(camPos, bestPart.Position)
                    end)
                    plStatus.Text = "Aim: " .. best.Name
                end
            end)
        else
            if abCircle then abCircle.Visible = false end
            abHolding = false
            _G.__NZAbLock = false
            plStatus.Text = "Aimbot OFF"
        end
    end)
    local abFloat = Instance.new("TextButton")
    abFloat.Size = UDim2.new(0, 56, 0, 56)
    abFloat.Position = UDim2.new(0, 14, 0.5, -28)
    abFloat.BackgroundColor3 = COL_BG_ALT
    abFloat.BackgroundTransparency = 0.15
    abFloat.Text = "AIM"
    abFloat.TextColor3 = COL_TEXT
    abFloat.Font = Enum.Font.GothamBold
    abFloat.TextSize = 12
    abFloat.BorderSizePixel = 0
    abFloat.AutoButtonColor = false
    abFloat.Parent = gui
    corner(abFloat, 28)
    stroke(abFloat, COL_ACCENT, 1)
    local abDrag, abSP, abBP = false, nil, nil
    abFloat.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            abDrag = true
            abSP = input.Position
            abBP = abFloat.Position
            abHolding = true
            _G.__NZZHold = true
        end
    end)
    abFloat.InputChanged:Connect(function(input)
        if abDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - abSP
            if math.abs(d.X) + math.abs(d.Y) > 8 then
                abFloat.Position = UDim2.new(abBP.X.Scale, abBP.X.Offset + d.X, abBP.Y.Scale, abBP.Y.Offset + d.Y)
            end
        end
    end)
    abFloat.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            abDrag = false
            abHolding = false
            _G.__NZZHold = false
        end
    end)
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and not isAnyTextBoxFocused() then
            abHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            abHolding = false
        end
    end)
    local mcCount, mcDelay, mcOn, mcFiring = 1, 0.1, false, false
    mcCountApply.MouseButton1Click:Connect(function()
        local n = tonumber(mcCountBox.Text)
        if n then mcCount = math.clamp(math.floor(n), 1, 50); mcCountBox.Text = tostring(mcCount); flashOk(mcCountBox)
        else flashErr(mcCountBox) end
    end)
    mcDelayApply.MouseButton1Click:Connect(function()
        local n = tonumber(mcDelayBox.Text)
        if n then mcDelay = math.clamp(n, 0, 2); mcDelayBox.Text = tostring(mcDelay); flashOk(mcDelayBox)
        else flashErr(mcDelayBox) end
    end)
    mcTog.MouseButton1Click:Connect(function()
        mcOn = not mcOn; setToggle(mcTog, mcOn)
        plStatus.Text = mcOn and "Multi-click ON" or "Multi-click OFF"
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or isAnyTextBoxFocused() or mcFiring then return end
        local t = input.UserInputType
        if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) and mcOn and mcCount > 1 then
            local okV, vim = pcall(function() return game:GetService("VirtualInputManager") end)
            if not okV or not vim then plStatus.Text = "VIM unsupported"; plStatus.TextColor3 = COL_RED return end
            local pos = input.Position
            local n, dl = mcCount, mcDelay
            mcFiring = true
            task.spawn(function()
                for _ = 2, n do
                    task.wait(dl)
                    local okC = pcall(function()
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    end)
                    task.wait(0.03)
                    pcall(function()
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end)
                    if not okC then break end
                end
                mcFiring = false
            end)
        end
    end)
    local function cleanPL()
        noclipOn = false
        infJOn = false
        pflyOn = false
        mcOn = false
        abOn = false
        espOn = false
        abHolding = false
        mcFiring = false
        _G.__NZAbLock = false
        _G.__NZZHold = false
        if infJConn then pcall(function() infJConn:Disconnect() end) infJConn = nil end
        if pflyConn then pcall(function() pflyConn:Disconnect() end) pflyConn = nil end
        if abConn then pcall(function() abConn:Disconnect() end) abConn = nil end
        if espConn then pcall(function() espConn:Disconnect() end) espConn = nil end
            for p, d in pairs(origColl) do pcall(function() p.CanCollide = d.c; p.CanTouch = d.t; if d.g then p.CollisionGroup = d.g end end) end
            origColl = {}
            for _, c in ipairs(noclipConns) do pcall(function() c:Disconnect() end) end
            noclipConns = {}
            wsLoopOn = false
        for plr, set in pairs(espTracked) do
            pcall(function() set.box:Remove() end)
            pcall(function() set.name:Remove() end)
            pcall(function() set.tracer:Remove() end)
            espTracked[plr] = nil
        end
        if abCircle then pcall(function() abCircle:Remove() end) abCircle = nil end
        jumpAllow = true
        applyJump()
        local ch = player.Character
        if ch then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.WalkSpeed = 16 end)
                pcall(function() hum.JumpPower = 50 end)
                pcall(function() hum.JumpHeight = 7.2 end)
            end
        end
        if chHbChar and chHbOrig then
            local rp = chHbChar:FindFirstChild("HumanoidRootPart")
            if rp then pcall(function() rp.Size = chHbOrig end) end
        end
        chHbMult = 1
        while lagCount > 0 do lagHide() end
        if tpOn then
            tpOn = false
            if tpMode then player.CameraMode = tpMode end
            local cam = Workspace.CurrentCamera
            if tpZoom and cam then cam.MaxZoomDistance = tpZoom end
        end
    end
    _G.__NZCleanPL = cleanPL
end

do
    local page = pages["Utility"]
    local y = 6
    pageLabel(page, y, "Session / server"); y = y + 24
    local rjBtn = pageWideBtn(page, y, "Rejoin Server", COL_ACCENT); y = y + 34
    local rjStatus = Instance.new("TextLabel")
    rjStatus.Size = UDim2.new(1, -8, 0, 16); rjStatus.Position = UDim2.new(0, 4, 0, y)
    rjStatus.BackgroundTransparency = 1; rjStatus.Text = ("Place %d | Job %s"):format(game.PlaceId, game.JobId)
    rjStatus.TextColor3 = COL_TEXT_DIM; rjStatus.Font = Enum.Font.Gotham; rjStatus.TextSize = 10
    rjStatus.TextXAlignment = Enum.TextXAlignment.Left; rjStatus.TextWrapped = true; rjStatus.Parent = page
    y = y + 22
    local copyJob = pageWideBtn(page, y, "Copy JobId"); y = y + 34
    local copyPlace = pageWideBtn(page, y, "Copy PlaceId"); y = y + 34
    local destroyBtn = pageWideBtn(page, y, "Destroy NZ-HUB", Color3.fromRGB(80, 20, 20)); y = y + 40
    pageLabel(page, y, "NZ-HUB unified. Insert = minimize."); y = y + 22
    page.CanvasSize = UDim2.new(0, 0, 0, y + 20)

    rjBtn.MouseButton1Click:Connect(function()
        rjStatus.Text = "Rejoining..."
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    end)
    copyJob.MouseButton1Click:Connect(function()
        local cb = setclipboard or toclipboard
        if cb then pcall(cb, game.JobId) copyJob.Text = "Copied!" task.wait(1) copyJob.Text = "Copy JobId" end
    end)
    copyPlace.MouseButton1Click:Connect(function()
        local cb = setclipboard or toclipboard
        if cb then pcall(cb, tostring(game.PlaceId)) copyPlace.Text = "Copied!" task.wait(1) copyPlace.Text = "Copy PlaceId" end
    end)
    destroyBtn.MouseButton1Click:Connect(function()
        for _, k in ipairs({ "__NZCleanA", "__NZCleanCM", "__NZCleanBH", "__NZCleanPL", "__NZCleanLZ", "__NZCleanMZ", "__NZCleanIS", "__NZCleanGFX" }) do
            local fn = _G[k]
            if fn then pcall(fn) end
            _G[k] = nil
        end
        _G.__NZFlyActive = false
        _G.__NZAbLock = false
        _G.__NZZHold = false
        _G.__NZZAbRadius = nil
        if _G.__NZFlyStop then pcall(_G.__NZFlyStop) end
        if _G.__NZSitStop then pcall(_G.__NZSitStop) end
        if _G.__NZHoldFlingStop then pcall(_G.__NZHoldFlingStop) end
        pcall(function() blur:Destroy() end)
        gui:Destroy()
        _G.__NZHUB, _G.__NZHub, _G.__NZFly = nil, nil, nil
        _G.__NZFlyStop, _G.__NZSitStop, _G.__NZHoldFlingStop = nil, nil, nil
    end)
end

do
    local page = pages["Other Scripts"]
    local y = 4
    local osStatus = Instance.new("TextLabel")
    osStatus.Size = UDim2.new(1, -8, 0, 16); osStatus.Position = UDim2.new(0, 4, 0, y)
    osStatus.BackgroundTransparency = 1; osStatus.Text = "Status: Ready"; osStatus.TextColor3 = COL_GREEN
    osStatus.Font = Enum.Font.Gotham; osStatus.TextSize = 10; osStatus.TextXAlignment = Enum.TextXAlignment.Left; osStatus.Parent = page
    y = y + 20
    local function runExternal(url, raw, label)
        if type(loadstring) ~= "function" then
            osStatus.Text = "loadstring unavailable"
            osStatus.TextColor3 = COL_RED
            return
        end
        local ok, src
        if raw then
            ok, src = pcall(function() return game:HttpGet(url, true) end)
        else
            ok, src = pcall(function() return game:HttpGet(url) end)
        end
        if not ok or type(src) ~= "string" then
            osStatus.Text = label .. " download failed"
            osStatus.TextColor3 = COL_RED
            return
        end
        local ok2, fn = pcall(loadstring, src, "@" .. label)
        if not ok2 or type(fn) ~= "function" then
            osStatus.Text = label .. " compile failed"
            osStatus.TextColor3 = COL_RED
            return
        end
        local ok3, err = pcall(fn)
        if ok3 then
            osStatus.Text = label .. " loaded"
            osStatus.TextColor3 = COL_GREEN
        else
            osStatus.Text = label .. ": " .. tostring(err)
            osStatus.TextColor3 = COL_RED
        end
    end
    pageLabel(page, y, "External Scripts", 200); y = y + 22
    local dexBtn = pageWideBtn(page, y, "Dark Dex"); y = y + 34
    local iyBtn = pageWideBtn(page, y, "Infinite Yield"); y = y + 34
    page.CanvasSize = UDim2.new(0, 0, 0, y + 20)
    dexBtn.MouseButton1Click:Connect(function()
        osStatus.Text = "Downloading Dark Dex..."
        osStatus.TextColor3 = COL_YELLOW
        runExternal("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua", false, "Dark Dex")
    end)
    iyBtn.MouseButton1Click:Connect(function()
        osStatus.Text = "Downloading Infinite Yield..."
        osStatus.TextColor3 = COL_YELLOW
        runExternal("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true, "Infinite Yield")
    end)
end

do
    local page = pages["HUBS"]
    local y = 6
    pageLabel(page, y, "Open Hubs", 200); y = y + 24
    local hubStatus = Instance.new("TextLabel")
    hubStatus.Size = UDim2.new(1, -8, 0, 16); hubStatus.Position = UDim2.new(0, 4, 0, y)
    hubStatus.BackgroundTransparency = 1; hubStatus.Text = "Pick a hub to load"
    hubStatus.TextColor3 = COL_TEXT_DIM; hubStatus.Font = Enum.Font.Gotham; hubStatus.TextSize = 10
    hubStatus.TextXAlignment = Enum.TextXAlignment.Left; hubStatus.TextWrapped = true; hubStatus.Parent = page
    y = y + 26
    local hubs = {
        { label = "Car Mods", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-CARMODS.lua" },
        { label = "Brookhaven", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-BROOKHAVEN.lua" },
        { label = "Project Lazarus", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-PROJECTLAZARUS.lua" },
        { label = "Micheal Zombies", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-MICHEALZOMBIES.lua" },
        { label = "INF Smile", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-INFSMILE.lua" },
        { label = "Backdoor", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-BACKDOOR.lua" },
        { label = "Graphics", url = "https://raw.githubusercontent.com/NZ-K5/NZ-HUBS/refs/heads/main/NZ-GRAPHICS.lua" },
    }
    for _, h in ipairs(hubs) do
        local b = pageWideBtn(page, y, h.label, COL_ACCENT); y = y + 34
        b.MouseButton1Click:Connect(function()
            hubStatus.Text = "Loading " .. h.label .. "..."
            hubStatus.TextColor3 = COL_YELLOW
            local ok, err = pcall(function() loadstring(game:HttpGet(h.url))() end)
            if ok then
                hubStatus.Text = h.label .. " loaded"
                hubStatus.TextColor3 = COL_GREEN
            else
                hubStatus.Text = h.label .. " failed: " .. tostring(err)
                hubStatus.TextColor3 = COL_RED
            end
        end)
    end
    page.CanvasSize = UDim2.new(0, 0, 0, y + 40)
end

print("NZ-HUB loaded: Player / Utility / Other Scripts / HUBS")
