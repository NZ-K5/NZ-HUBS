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

for _, k in ipairs({  }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    local g = _G.__NZHUB_UTILITY
    if g and g.Destroy then g:Destroy() end
    _G.__NZHUB_UTILITY = nil
    if _G.__NZFly and _G.__NZFly.Destroy then pcall(function() _G.__NZFly:Destroy() end) end
    _G.__NZFly = nil
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZ-HUB", "NZ-UTILITY" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur_UTILITY" then
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
gui.Name = "NZ-UTILITY"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB_UTILITY = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur_UTILITY"
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
title.Text = "NZ-UTILITY"
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
    for _, k in ipairs({  }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB_UTILITY = nil
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

local HUB_TAB = "Utility"
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
    local destroyBtn = pageWideBtn(page, y, "Destroy NZ-UTILITY", Color3.fromRGB(80, 20, 20)); y = y + 40
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
        for _, k in ipairs({  }) do
            local fn = _G[k]
            if fn then pcall(fn) end
            _G[k] = nil
        end
        _G.__NZAbLock = false
        _G.__NZZHold = false
        _G.__NZZAbRadius = nil
        pcall(function() blur:Destroy() end)
        gui:Destroy()
        _G.__NZHUB_UTILITY = nil
    end)
end

print("NZ-UTILITY loaded")
