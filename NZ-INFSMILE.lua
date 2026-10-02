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

for _, k in ipairs({ "__NZCleanIS" }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    local g = _G.__NZHUB_INFSMILE
    if g and g.Destroy then g:Destroy() end
    _G.__NZHUB_INFSMILE = nil
    if _G.__NZFly and _G.__NZFly.Destroy then pcall(function() _G.__NZFly:Destroy() end) end
    _G.__NZFly = nil
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZ-HUB", "NZ-INFSMILE" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur_INFSMILE" then
        pcall(function() v:Destroy() end)
    end
end

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
gui.Name = "NZ-INFSMILE"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB_INFSMILE = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur_INFSMILE"
blur.Size = 6
blur.Parent = Lighting

local spawnX, spawnY = 0, 0
pcall(function()
    local holder = pg or player:FindFirstChild("PlayerGui")
    if holder then
        local n = 0
        for _, c in ipairs(holder:GetChildren()) do
            if c ~= gui and c:IsA("ScreenGui") and c.Name:sub(1, 3) == "NZ-" then n = n + 1 end
        end
        spawnX, spawnY = n * 44, n * 32
    end
end)
pcall(function()
    local vp = camera.ViewportSize
    local nx0 = 8 - 0.5 * vp.X + WIN_W / 2
    local nx1 = 0.5 * vp.X - WIN_W / 2 - 8
    local ny0 = 8 - 0.45 * vp.Y + WIN_H / 2
    local ny1 = 0.55 * vp.Y - WIN_H / 2 - 8
    if nx1 >= nx0 then spawnX = math.clamp(spawnX, nx0, nx1) end
    if ny1 >= ny0 then spawnY = math.clamp(spawnY, ny0, ny1) end
end)

local main = Instance.new("Frame")
main.Name = "Window"
main.Size = UDim2.new(0, WIN_W, 0, 36)
main.Position = UDim2.new(0.5, -WIN_W / 2 + spawnX, 0.45, -WIN_H / 2 + spawnY)
main.BackgroundColor3 = COL_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 12)
stroke(main, COL_BORDER, 1)

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
title.Text = "NZ-INFSMILE"
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
    for _, k in ipairs({ "__NZCleanIS" }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB_INFSMILE = nil
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
tabBar.Size = UDim2.new(0, 0, 0, 0)
tabBar.Position = UDim2.new(0, 12, 0, 42)
tabBar.BackgroundTransparency = 1
tabBar.Visible = false
tabBar.Parent = main

local HUB_TAB = "INF Smile"
local tabBtns, pages = {}, {}
local function createPage(name)
    local pg = Instance.new("ScrollingFrame")
    pg.Name = name
    pg.Size = UDim2.new(1, -24, 1, -54)
    pg.Position = UDim2.new(0, 12, 0, 46)
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
pages[HUB_TAB] = createPage(HUB_TAB)
pages[HUB_TAB].Visible = true
local currentTab = HUB_TAB
local function selectTab(name)
    currentTab = name
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
end
selectTab(HUB_TAB)

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
        main.Position = UDim2.new(0.5, -WIN_W / 2 + spawnX, 0.45, -WIN_H / 2 + spawnY)
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
        main.Position = UDim2.new(0.5, -WIN_W / 2 + spawnX, 0.45, -WIN_H / 2 + spawnY)
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
    local page = pages["INF Smile"]
    local function isTarget(v, keys)
        if not v.Name then return false end
        local nl = string.lower(v.Name)
        for _, k in ipairs(keys) do if nl:find(k) then return true end end
        return false
    end
    local function isKind(v)
        return v:IsA("BasePart") or v:IsA("Model") or v:IsA("Folder") or v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript")
    end
    local flags = {}
    local stores = {}
    local names = { "Infect", "Kill", "SmileGate", "AntiHack", "Spear", "FireLava", "Weight", "Orb", "BlackHole", "Laser" }
    for _, n in ipairs(names) do flags[n] = false; stores[n] = {} end
    local antiInfOn, dupSad, toolCDOn, toolCDVal, toolLoop, seisConn, seisAcc = false, nil, false, 0, nil, nil, 0
    local y = 4
    pageLabel(page, y, "Infectious Smile map cleanup"); y = y + 22
    local btns = {}
    local defs = {
        { "Infect", "Disable InfectParts" }, { "Kill", "Disable Kill" }, { "SmileGate", "Disable SmileGates" },
        { "AntiHack", "Disable Anti-Hack" }, { "Spear", "Disable Spears" }, { "FireLava", "Disable Fire/Lava" },
        { "Weight", "Disable Weight" }, { "Orb", "Delete Orb" }, { "BlackHole", "Disable BlackHole" }, { "Laser", "Disable Lasers" },
    }
    for _, d in ipairs(defs) do
        pageLabel(page, y, d[2], 170); btns[d[1]] = pageToggle(page, y - 2, 200, 70); y = y + 30
    end
    pageLabel(page, y, "Anti-Infection"); local antiBtn = pageToggle(page, y - 2, 200, 70); y = y + 30
    pageLabel(page, y, "Tool Cooldown"); local cdBox = pageBox(page, y - 2, 160, 60, ""); local cdBtn = pageToggle(page, y - 2, 228, 60); y = y + 30
    pageLabel(page, y, "TP to collector"); local tpBox = pageBox(page, y - 2, 160, 110, ""); y = y + 30
    local tpGo = pageWideBtn(page, y, "TP", COL_ACCENT); tpGo.Size = UDim2.new(0, 90, 0, 26)
    local scanC = pageWideBtn(page, y, "Scan"); scanC.Size = UDim2.new(0, 90, 0, 26); scanC.Position = UDim2.new(0, 100, 0, y)
    y = y + 32
    local tipLbl = Instance.new("TextLabel")
    tipLbl.Size = UDim2.new(1, -8, 0, 16); tipLbl.Position = UDim2.new(0, 4, 0, y)
    tipLbl.BackgroundTransparency = 1; tipLbl.Text = "Keep spamming TP button to get the tool!"; tipLbl.TextColor3 = COL_YELLOW
    tipLbl.Font = Enum.Font.Gotham; tipLbl.TextSize = 10; tipLbl.TextXAlignment = Enum.TextXAlignment.Left; tipLbl.Parent = page
    y = y + 20
    local isStatus = Instance.new("TextLabel")
    isStatus.Size = UDim2.new(1, -8, 0, 32); isStatus.Position = UDim2.new(0, 4, 0, y)
    isStatus.BackgroundTransparency = 1; isStatus.Text = "Status: Ready"; isStatus.TextColor3 = COL_GREEN
    isStatus.Font = Enum.Font.Gotham; isStatus.TextSize = 10; isStatus.TextXAlignment = Enum.TextXAlignment.Left
    isStatus.TextWrapped = true; isStatus.Parent = page
    y = y + 36
    local collLbl = Instance.new("TextLabel")
    collLbl.Size = UDim2.new(1, -8, 0, 40); collLbl.Position = UDim2.new(0, 4, 0, y)
    collLbl.BackgroundTransparency = 1; collLbl.Text = "Collection Models: -"; collLbl.TextColor3 = COL_TEXT_DIM
    collLbl.Font = Enum.Font.Gotham; collLbl.TextSize = 10; collLbl.TextXAlignment = Enum.TextXAlignment.Left
    collLbl.TextYAlignment = Enum.TextYAlignment.Top; collLbl.TextWrapped = true; collLbl.Parent = page
    page.CanvasSize = UDim2.new(0, 0, 0, y + 50)

    local function delItems(found, store)
        for _, v in ipairs(found) do
            if v and v.Parent then table.insert(store, { Item = v, Parent = v.Parent }); pcall(function() v.Parent = nil end) end
        end
    end
    local function resItems(store)
        local c = 0; local rm = {}
        for i, d in ipairs(store) do
            if d and d.Item and not d.Item.Parent then
                pcall(function()
                    d.Item.Parent = (d.Parent and d.Parent.Parent ~= nil) and d.Parent or Workspace
                    c = c + 1; table.insert(rm, i)
                end)
            else table.insert(rm, i) end
        end
        table.sort(rm, function(a, b) return a > b end)
        for _, i in ipairs(rm) do table.remove(store, i) end
        return c
    end
    local function scanFor(key)
        local f = {}
        if key == "Infect" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    for _, c in ipairs(v:GetDescendants()) do
                        if (c:IsA("Script") or c:IsA("LocalScript") or c:IsA("ModuleScript")) and c.Name and string.lower(c.Name):find("infect") then table.insert(f, v) break end
                    end
                end
                if (v:IsA("BasePart") or v:IsA("Model") or v:IsA("Folder")) and v.Name then
                    local nl = string.lower(v.Name)
                    if nl:find("infect") or nl:find("aggressivesmiler") then if not table.find(f, v) then table.insert(f, v) end end
                end
            end
        elseif key == "Kill" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Folder") and v.Name and string.lower(v.Name) == "killbricks" then table.insert(f, v) end
                if v:IsA("BasePart") and v.Name and string.lower(v.Name) == "killzone" then table.insert(f, v) end
            end
        elseif key == "SmileGate" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if isKind(v) and v.Name and string.lower(v.Name):find("smilegate") then table.insert(f, v) end
            end
        elseif key == "AntiHack" then

            for _, v in ipairs(Workspace:GetDescendants()) do
                if isKind(v) and v.Name and isTarget(v, { "anti", "hack", "anticheat", "cheat", "exploit", "bypass", "security" }) then table.insert(f, v) end
            end
        elseif key == "Spear" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if isKind(v) and v.Name and isTarget(v, { "spear", "javelin", "lance", "pike", "harpoon" }) then table.insert(f, v) end
            end
        elseif key == "FireLava" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if isKind(v) and v.Name and isTarget(v, { "fire", "lava", "flame", "burn", "ignite", "molten", "magma", "combust", "pyro" }) then table.insert(f, v) end
            end
        elseif key == "Weight" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name and string.lower(v.Name):find("weight") then table.insert(f, v) end
            end
        elseif key == "Orb" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name and string.lower(v.Name) == "orb" then table.insert(f, v) end
            end
        elseif key == "BlackHole" then
            local mf = Workspace:FindFirstChild("Map")
            local sf = mf and mf:FindFirstChild("System")
            local bh = sf and sf:FindFirstChild("BlackHole")
            if bh then table.insert(f, bh) end
        elseif key == "Laser" then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if isKind(v) and v.Name and string.lower(v.Name):find("laser") then table.insert(f, v) end
            end
        end
        return f
    end
    local function toggleKey(key)
        flags[key] = not flags[key]
        setToggle(btns[key], flags[key])
        if flags[key] then
            local f = scanFor(key)
            delItems(f, stores[key])
            isStatus.Text = (#f > 0) and ("Deleted " .. #f .. " (" .. key .. ")") or ("No " .. key .. " found")
            if key == "Weight" then
                if seisConn then pcall(function() seisConn:Disconnect() end) seisConn = nil end
                seisAcc = 0
                seisConn = RunService.Heartbeat:Connect(function(dt)
                    seisAcc = seisAcc + dt
                    if seisAcc >= 1 then seisAcc = 0; delItems(scanFor("Weight"), stores.Weight) end
                end)
            end
        else
            local c = resItems(stores[key])
            isStatus.Text = "Restored " .. c .. " (" .. key .. ")"
            if key == "Weight" and seisConn then pcall(function() seisConn:Disconnect() end) seisConn = nil end
        end
    end
    for k, b in pairs(btns) do
        b.MouseButton1Click:Connect(function() toggleKey(k) end)
        pcall(function() b.TouchTap:Connect(function() toggleKey(k) end) end)
    end

    antiBtn.MouseButton1Click:Connect(function()
        antiInfOn = not antiInfOn; setToggle(antiBtn, antiInfOn)
        if antiInfOn then
            local sad = nil
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name and string.lower(v.Name):find("sadwater") then sad = v break end
            end
            if not sad then isStatus.Text = "No SadWater found!"; setToggle(antiBtn, false); antiInfOn = false; return end
            local cl = sad:Clone(); cl.Name = "SadWater_AntiInfection"; cl.Parent = Workspace
            cl.Size = Vector3.new(2000, 2000, 2000); cl.Position = Vector3.new(0, 0, 0); cl.CastShadow = false
            dupSad = cl
            isStatus.Text = "Anti-Infection ON (" .. sad.Name .. ")"
        else
            if dupSad then pcall(function() dupSad:Destroy() end) dupSad = nil end
            isStatus.Text = "Anti-Infection OFF"
        end
    end)
    local function applyCD(v)
        local c = 0
        for _, cont in ipairs({ player:FindFirstChild("Backpack"), player:FindFirstChild("Inventory"), player:FindFirstChild("Hotbar"), player.Character, player:FindFirstChild("StarterGear") }) do
            if cont then for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") then
                    local cv = t:FindFirstChild("Cooldown")
                    if cv and cv:IsA("NumberValue") then pcall(function() cv.Value = v; c = c + 1 end) end
                end
            end end
        end
        return c
    end
    cdBtn.MouseButton1Click:Connect(function()
        toolCDOn = not toolCDOn; setToggle(cdBtn, toolCDOn)
        if toolLoop then pcall(function() toolLoop:Disconnect() end) toolLoop = nil end
        if toolCDOn then
            local n = tonumber(cdBox.Text)
            if not n then flashErr(cdBox); setToggle(cdBtn, false); toolCDOn = false; isStatus.Text = "Enter a valid number"; return end
            toolCDVal = n
            applyCD(n)
            flashOk(cdBox)
            toolLoop = RunService.Heartbeat:Connect(function() if toolCDOn then applyCD(toolCDVal) end end)
            isStatus.Text = "Tool cooldown locked: " .. n
        else isStatus.Text = "Tool cooldown off" end
    end)
    tpGo.MouseButton1Click:Connect(function()
        local nm = tpBox.Text; if nm == "" then return end
        local tm = nil
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and string.lower(v.Name) == string.lower(nm) then tm = v break end
        end
        if not tm then isStatus.Text = "Model not found"; return end
        local tp = tm.PrimaryPart
        if not tp or not tp:IsA("BasePart") then
            for _, v in ipairs(tm:GetDescendants()) do if v:IsA("BasePart") then tp = v break end end
        end
        local ch = player.Character; local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if tp and hrp then pcall(function() hrp.CFrame = tp.CFrame + Vector3.new(0, 3, 0) end) isStatus.Text = "Teleported to " .. tm.Name end
    end)
    scanC.MouseButton1Click:Connect(function()
        local f = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name and string.lower(v.Name):find("collection") then table.insert(f, v.Name) end
        end
        collLbl.Text = (#f > 0) and ("Collection Models:\nâ€¢ " .. table.concat(f, "\nâ€¢ ")) or "Collection Models: None found"
    end)
    local function cleanIS()
        for kk in pairs(flags) do
            flags[kk] = false
            if stores[kk] then resItems(stores[kk]) end
        end
        antiInfOn = false
        if dupSad then pcall(function() dupSad:Destroy() end) dupSad = nil end
        toolCDOn = false
        if toolLoop then pcall(function() toolLoop:Disconnect() end) toolLoop = nil end
        if seisConn then pcall(function() seisConn:Disconnect() end) seisConn = nil end
    end
    _G.__NZCleanIS = cleanIS
end

print("NZ-INFSMILE loaded")
