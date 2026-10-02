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

for _, k in ipairs({ "__NZCleanMZ" }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    local g = _G.__NZHUB_MZ
    if g and g.Destroy then g:Destroy() end
    _G.__NZHUB_MZ = nil
    if _G.__NZFly and _G.__NZFly.Destroy then pcall(function() _G.__NZFly:Destroy() end) end
    _G.__NZFly = nil
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZ-HUB", "NZ-MICHEALZOMBIES" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur_MICHEALZOMBIES" then
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
gui.Name = "NZ-MICHEALZOMBIES"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB_MZ = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur_MICHEALZOMBIES"
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
title.Text = "NZ-MICHEALZOMBIES"
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
    for _, k in ipairs({ "__NZCleanMZ" }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB_MZ = nil
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

local HUB_TAB = "Micheal Zombies"
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
    local page = pages["Micheal Zombies"]
    local y = 4
    local mzStatus = Instance.new("TextLabel")
    mzStatus.Size = UDim2.new(1, -8, 0, 16); mzStatus.Position = UDim2.new(0, 4, 0, y)
    mzStatus.BackgroundTransparency = 1; mzStatus.Text = "Status: Ready"; mzStatus.TextColor3 = COL_GREEN
    mzStatus.Font = Enum.Font.Gotham; mzStatus.TextSize = 10; mzStatus.TextXAlignment = Enum.TextXAlignment.Left; mzStatus.Parent = page
    y = y + 20
    local function mzOk(m) mzStatus.Text = m; mzStatus.TextColor3 = COL_GREEN end
    local function mzErr(m) mzStatus.Text = m; mzStatus.TextColor3 = COL_RED end
    local function mzInfo(m) mzStatus.Text = m; mzStatus.TextColor3 = COL_YELLOW end

    local function mzFind(name)
        local f = player:FindFirstChild(name)
        if f then return f end
        local pg = player:FindFirstChild("PlayerGui")
        local par = pg and pg.Parent
        if par then
            for _, c in ipairs(par:GetChildren()) do
                if c.Name == name then return c end
            end
            for _, d in ipairs(par:GetDescendants()) do
                if d.Name == name and (d:IsA("Folder") or d:IsA("Model")) then return d end
            end
        end
        return nil
    end
    local function mzBaseData()
        local bd = mzFind("BaseData")
        if bd then return bd end
        return nil
    end
    local function mzGunStats() return mzFind("GunStats") end
    local function mzZombies()
        local ig = Workspace:FindFirstChild("Ignore")
        return ig and ig:FindFirstChild("Zombies")
    end

    pageLabel(page, y, "Levels", 200); y = y + 22
    pageLabel(page, y, "Set Level"); local mzlBox = pageBox(page, y - 2, 160, 90, "100"); local mzlApply = pageApply(page, y - 2, 258, "Apply"); y = y + 30
    local mzlGiveBtn = pageWideBtn(page, y, "Give Levels"); y = y + 34
    local mzlRevBtn = pageWideBtn(page, y, "Revert Levels"); y = y + 34
    local mzlOrig, mzlSnapped = nil, false
    local function mzLevelValue()
        local bd = mzBaseData()
        local v = bd and bd:FindFirstChild("Level")
        if v and v:IsA("IntValue") then return v end
        return nil
    end
    local function mzSnapshot()
        local v = mzLevelValue()
        if v and not mzlSnapped then
            mzlOrig = v.Value
            mzlSnapped = true
        end
        return v
    end
    mzlApply.MouseButton1Click:Connect(function()
        local n = tonumber(mzlBox.Text)
        if not n then flashErr(mzlBox) return end
        local v = mzSnapshot()
        if not v then mzErr("Level not found in BaseData") return end
        pcall(function() v.Value = math.floor(n) end)
        flashOk(mzlBox); mzlBox.Text = tostring(math.floor(n))
        mzOk("Level -> " .. tostring(math.floor(n)))
    end)
    mzlGiveBtn.MouseButton1Click:Connect(function()
        local n = tonumber(mzlBox.Text)
        if not n then flashErr(mzlBox) return end
        local v = mzSnapshot()
        if not v then mzErr("Level not found in BaseData") return end
        local add = math.floor(n)
        local now = v.Value
        pcall(function() v.Value = now + add end)
        flashOk(mzlBox)
        mzOk("Gave " .. add .. " levels (now " .. tostring(v.Value) .. ")")
    end)
    mzlRevBtn.MouseButton1Click:Connect(function()
        if not mzlSnapped then mzErr("nothing to revert yet") return end
        local v = mzLevelValue()
        if not v then mzErr("Level not found in BaseData") return end
        pcall(function() v.Value = mzlOrig end)
        mzInfo("Level reverted -> " .. tostring(mzlOrig))
    end)

    pageLabel(page, y, "Visuals", 200); y = y + 22
    local mzeBtn = pageWideBtn(page, y, "Give Infinite Emeralds"); y = y + 34
    local mzcBtn = pageWideBtn(page, y, "Give Infinite Coins"); y = y + 34
    local MZ_INF = 99999999
    local function mzGiveCurrency(label)
        local bd = mzBaseData()
        if not bd then mzErr("BaseData not found") return end
        local n = 0
        for _, nm in ipairs({ "Coins", "Emeralds" }) do
            local v = bd:FindFirstChild(nm)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                pcall(function() v.Value = MZ_INF end)
                n = n + 1
            end
        end
        if n > 0 then mzOk(label .. ": " .. n .. " values -> " .. MZ_INF)
        else mzErr("Coins/Emeralds not found in BaseData") end
    end
    mzeBtn.MouseButton1Click:Connect(function() mzGiveCurrency("Emeralds") end)
    mzcBtn.MouseButton1Click:Connect(function() mzGiveCurrency("Coins") end)

    pageLabel(page, y, "Gun Visuals", 200); y = y + 22
    local mzExpBtn = pageWideBtn(page, y, "Give Infinite EXP"); y = y + 34
    local mzLvlBtn = pageWideBtn(page, y, "Give Infinite Levels"); y = y + 34
    local mzKillBtn = pageWideBtn(page, y, "Give Infinite Kills"); y = y + 34
    local mzHsBtn = pageWideBtn(page, y, "Give Infinite Headshots"); y = y + 34
    local mzAttBtn = pageWideBtn(page, y, "Give Infinite Attachments"); y = y + 34
    local function mzSetGunAttr(attr, value)
        local gs = mzGunStats()
        if not gs then mzErr("GunStats not found") return false end
        local n = 0
        for _, f in ipairs(gs:GetChildren()) do
            local ok, hit = pcall(function()
                local cur = f:GetAttribute(attr)
                if cur == nil then return false end
                if type(cur) == "string" then f:SetAttribute(attr, tostring(value))
                else f:SetAttribute(attr, value) end
                return true
            end)
            if ok and hit then n = n + 1 end
        end
        if n > 0 then mzOk(attr .. " -> " .. tostring(value) .. " (" .. n .. " guns)")
        else mzErr(attr .. " not found on any gun") end
        return n > 0
    end
    mzExpBtn.MouseButton1Click:Connect(function() mzSetGunAttr("EXP", 99999) end)
    mzLvlBtn.MouseButton1Click:Connect(function() mzSetGunAttr("Level", 99999) end)
    mzKillBtn.MouseButton1Click:Connect(function() mzSetGunAttr("Kills", 99999) end)
    mzHsBtn.MouseButton1Click:Connect(function() mzSetGunAttr("Headshots", 99999) end)
    mzAttBtn.MouseButton1Click:Connect(function()
        local inv = mzFind("Inventory")
        local at = inv and inv:FindFirstChild("Attachments")
        if not at then mzErr("Inventory/Attachments not found") return end
        local n = 0
        for k, v in pairs(at:GetAttributes()) do
            local ok = pcall(function()
                if type(v) == "string" then at:SetAttribute(k, "99")
                else at:SetAttribute(k, 99) end
            end)
            if ok then n = n + 1 end
        end
        if n > 0 then mzOk("Attachments -> 99 (" .. n .. " attributes)")
        else mzErr("no attributes on Attachments") end
    end)

    pageLabel(page, y, "Gun Mods", 200); y = y + 22
    local mzBarrelBtn = pageWideBtn(page, y, "Change Barrel"); y = y + 34
    local mzSightBtn = pageWideBtn(page, y, "Change Sight"); y = y + 34
    local mzUnderBtn = pageWideBtn(page, y, "Change Underbarrel"); y = y + 34
    local mzSideBtn = pageWideBtn(page, y, "Change Side"); y = y + 34
    pageLabel(page, y, "Change AmmoType"); local mzAmmoBox = pageBox(page, y - 2, 160, 90, "AP"); local mzAmmoApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    local mzDrop = Instance.new("ScrollingFrame")
    mzDrop.Size = UDim2.new(0, 300, 0, 300)
    mzDrop.Position = UDim2.new(0, 4, 0, y)
    mzDrop.BackgroundColor3 = COL_BG_ALT
    mzDrop.BorderSizePixel = 0
    mzDrop.ScrollBarThickness = 4
    mzDrop.ScrollBarImageColor3 = COL_ACCENT
    mzDrop.Visible = false
    mzDrop.ZIndex = 50
    mzDrop.Parent = page
    corner(mzDrop, 8)
    stroke(mzDrop, COL_ACCENT, 1)
    local function mzFillDrop(frame, groups, onPick)
        for _, c in ipairs(frame:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        local ly = 4
        for _, g in ipairs(groups) do
            local h = Instance.new("TextLabel")
            h.Size = UDim2.new(1, -8, 0, 20); h.Position = UDim2.new(0, 4, 0, ly)
            h.BackgroundTransparency = 1; h.Text = g.name .. "  -  " .. #g.items
            h.TextColor3 = COL_ACCENT; h.Font = Enum.Font.GothamBold; h.TextSize = 12
            h.TextXAlignment = Enum.TextXAlignment.Left; h.Parent = frame; h.ZIndex = 51
            ly = ly + 22
            for _, item in ipairs(g.items) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, -8, 0, 22); b.Position = UDim2.new(0, 4, 0, ly)
                b.BackgroundColor3 = COL_BG_ALT; b.Text = item; b.TextColor3 = COL_TEXT
                b.Font = Enum.Font.Gotham; b.TextSize = 11; b.BorderSizePixel = 0
                b.AutoButtonColor = false; b.Parent = frame; b.ZIndex = 51
                corner(b, 4)
                b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(42, 46, 58) end)
                b.MouseLeave:Connect(function() b.BackgroundColor3 = COL_BG_ALT end)
                local pick = item
                b.MouseButton1Click:Connect(function()
                    frame.Visible = false
                    onPick(pick)
                end)
                ly = ly + 24
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, ly + 4)
    end
    local function mzOpenDrop(frame, groups, onPick)
        if frame.Visible then frame.Visible = false return end
        mzFillDrop(frame, groups, onPick)
        frame.Visible = true
    end
    local function mzSetEquip(attr, value)
        local gs = mzGunStats()
        if not gs then mzErr("GunStats not found") return false end
        local n = 0
        for _, f in ipairs(gs:GetChildren()) do
            local ok = pcall(function() f:SetAttribute(attr, value) end)
            if ok then n = n + 1 end
        end
        if n > 0 then mzOk(attr .. " = " .. tostring(value) .. " (" .. n .. " guns)")
        else mzErr("GunStats not found") end
        return n > 0
    end
    local mzBarrelList = { "Suppressor", "Cola_Suppressor", "09_Suppressor", "Witches_Suppressor", "Festive_Suppressor", "The_Silent_Night", "Unsawed_off" }
    local mzSightList = { "Mini", "Holo", "Reflex", "Kobra", "M68_CCO", "ACOG", "Pumpkin_Carver", "EMF_Kobra", "Candelit" }
    local mzUnderList = { "Angled_Grip", "Stubby_Grip", "Vertical_Grip", "Candy_Aim", "Blue_Laser", "Red_Laser", "Green_Laser", "Orange_Laser", "Pink_Laser", "Purple_Laser", "Teal_Laser", "White_Laser", "Yellow_Laser", "Poltergeist", "Spirit", "Purple_Pink_Laser", "Purple_Teal_Laser", "Red_Orange_Laser", "Candy_Cane_Laser", "Rainbow_Laser", "Scrapped_Light", "Flashlight", "UV_Light" }
    local mzSideList = { "JTEK_Alamo", "JTEK_Hellfire", "Rapid_Fire", "Recoil_Springs", "Redwood_Varnish", "Galvanized_Coating", "DIY_Kit" }
    mzBarrelBtn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzDrop, { { name = "Barrels", items = mzBarrelList } }, function(p) mzSetEquip("EquippedBarrel", p) end)
    end)
    mzSightBtn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzDrop, { { name = "Sights", items = mzSightList } }, function(p) mzSetEquip("EquippedSight", p) end)
    end)
    mzUnderBtn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzDrop, { { name = "Underbarrels", items = mzUnderList } }, function(p) mzSetEquip("EquippedUnderbarrel", p) end)
    end)
    mzSideBtn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzDrop, { { name = "Sides", items = mzSideList } }, function(p) mzSetEquip("EquippedSide", p) end)
    end)
    mzAmmoApply.MouseButton1Click:Connect(function()
        local t = tostring(mzAmmoBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
        if t == "" then flashErr(mzAmmoBox) return end
        if mzSetEquip("EquippedAmmoType", t) then flashOk(mzAmmoBox) end
    end)

    pageLabel(page, y, "Zombie Visuals", 200); y = y + 22
    pageLabel(page, y, "Micheal ESP"); local mzeEspTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Micheal Aimbot"); local mzAimTog = pageToggle(page, y - 2, 160, 150); mzAimTog.Text = "Micheal Aimbot: Off"; y = y + 30
    pageLabel(page, y, "Peaceful Mode"); local mzPeaceTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Zombie Del Radius", 140); local mzRadBox = pageBox(page, y - 2, 150, 60, "30"); local mzRadApply = pageApply(page, y - 2, 216, "Set"); local mzRadTog = pageToggle(page, y - 2, 282, 70); y = y + 34
    local mzHidden = {}
    local function mzUnhide()
        local c = 0
        for _, d in ipairs(mzHidden) do
            if d.Item then
                pcall(function()
                    d.Item.Parent = d.Parent
                    c = c + 1
                end)
            end
        end
        mzHidden = {}
        return c
    end
    local function mzHideZombies(maxDist)
        local zf = mzZombies()
        if not zf then return 0 end
        local rp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local n = 0
        for _, m in ipairs(zf:GetChildren()) do
            if m:IsA("Model") then
                local skip = false
                if maxDist then
                    if not rp then skip = true
                    else
                        local ok, piv = pcall(function() return m:GetPivot() end)
                        if not ok or (piv.Position - rp.Position).Magnitude > maxDist then skip = true end
                    end
                end
                if not skip then
                    local par = m.Parent
                    local ok = pcall(function() m.Parent = nil end)
                    if ok then
                        table.insert(mzHidden, { Item = m, Parent = par })
                        n = n + 1
                    end
                end
            end
        end
        return n
    end
    local mzPeaceOn = false
    mzPeaceTog.MouseButton1Click:Connect(function()
        mzPeaceOn = not mzPeaceOn; setToggle(mzPeaceTog, mzPeaceOn)
        if mzPeaceOn then
            mzInfo("Micheal peaceful ON")
            task.spawn(function()
                while mzPeaceOn do
                    mzHideZombies(nil)
                    task.wait(1.5)
                end
            end)
        else
            mzInfo("Micheal peaceful OFF (" .. mzUnhide() .. " restored)")
        end
    end)
    local mzRadOn, mzRadVal = false, 30
    mzRadApply.MouseButton1Click:Connect(function()
        local n = tonumber(mzRadBox.Text)
        if n then mzRadVal = math.clamp(n, 5, 500); mzRadBox.Text = tostring(mzRadVal); flashOk(mzRadBox)
        else flashErr(mzRadBox) end
    end)
    mzRadTog.MouseButton1Click:Connect(function()
        mzRadOn = not mzRadOn; setToggle(mzRadTog, mzRadOn)
        if mzRadOn then
            mzInfo("Radius hide ON (" .. tostring(mzRadVal) .. ")")
            task.spawn(function()
                while mzRadOn do
                    mzHideZombies(mzRadVal)
                    task.wait(1)
                end
            end)
        else
            mzInfo("Radius hide OFF (" .. mzUnhide() .. " restored)")
        end
    end)
    local MZ_COL = Color3.fromRGB(0, 235, 255)
    local mzEspOn, mzEspSets, mzEspConn, mzEspFrame, mzEspPhase, mzEspTick = false, {}, nil, 0, 0, 0
    mzeEspTog.MouseButton1Click:Connect(function()
        mzEspOn = not mzEspOn; setToggle(mzeEspTog, mzEspOn)
        if mzEspConn then pcall(function() mzEspConn:Disconnect() end) mzEspConn = nil end
        if mzEspOn then
            local okD, test = pcall(function() return Drawing.new("Square") end)
            if not okD or not test then
                mzEspOn = false; setToggle(mzeEspTog, false)
                mzErr("Drawing unsupported"); return
            end
            pcall(function() test:Remove() end)
            mzOk("Micheal ESP ON")
            mzEspConn = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if not cam then return end
                mzEspFrame = mzEspFrame + 1
                local seen = {}
                local shown = 0
                local pool = {}
                local zf = mzZombies()
                if zf then
                    for _, m in ipairs(zf:GetChildren()) do
                        if m:IsA("Model") then table.insert(pool, m) end
                    end
                end
                for _, m in ipairs(pool) do
                    seen[m] = true
                    local set = mzEspSets[m]
                    if not set then
                        local box = Drawing.new("Square")
                        box.Visible = false
                        box.Filled = false
                        box.Thickness = 1.5
                        box.Color = MZ_COL
                        local name = Drawing.new("Text")
                        name.Visible = false
                        name.Centered = true
                        name.Size = 13
                        name.Outline = true
                        name.Color = MZ_COL
                        set = { box = box, name = name, phase = mzEspPhase, part = nil, hum = nil }
                        mzEspPhase = mzEspPhase + 1
                        if mzEspPhase >= 2 then mzEspPhase = 0 end
                        mzEspSets[m] = set
                    end
                    if not set.part or not set.part.Parent then
                        set.part = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
                        set.hum = m:FindFirstChildOfClass("Humanoid")
                    end
                    local part, hum = set.part, set.hum
                    if part and (not hum or hum.Health > 0) then
                        local d = (cam.CFrame.Position - part.Position).Magnitude
                        if d > 1500 then
                            set.box.Visible = false
                            set.name.Visible = false
                        elseif d <= 250 or (mzEspFrame + (set.phase or 0)) % 2 == 0 then
                            local v, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local h = math.clamp(1500 / math.max(d, 1), 20, 300)
                                local w = h * 0.6
                                set.box.Size = Vector2.new(w, h)
                                set.box.Position = Vector2.new(v.X - w * 0.5, v.Y - h * 0.5)
                                set.box.Visible = true
                                set.name.Text = "Micheals [" .. math.floor(d + 0.5) .. "]"
                                set.name.Position = Vector2.new(v.X, v.Y - h * 0.5 - 14)
                                set.name.Visible = true
                                shown = shown + 1
                            else
                                set.box.Visible = false
                                set.name.Visible = false
                            end
                        end
                    else
                        set.box.Visible = false
                        set.name.Visible = false
                    end
                end
                for m, set in pairs(mzEspSets) do
                    if not seen[m] or not m.Parent then
                        pcall(function() set.box:Remove() end)
                        pcall(function() set.name:Remove() end)
                        mzEspSets[m] = nil
                    end
                end
                if os.clock() - mzEspTick >= 1 then
                    mzEspTick = os.clock()
                    mzStatus.Text = "Micheals " .. shown .. " shown"
                    mzStatus.TextColor3 = COL_GREEN
                end
            end)
        else
            for m, set in pairs(mzEspSets) do
                pcall(function() set.box:Remove() end)
                pcall(function() set.name:Remove() end)
                mzEspSets[m] = nil
            end
            mzInfo("Micheal ESP OFF")
        end
    end)
    local mzAimOn, mzAimRadius, mzAimConn, mzHolding, mzAimCircle = false, 120, nil, false, nil
    mzAimTog.MouseButton1Click:Connect(function()
        mzAimOn = not mzAimOn; setToggle(mzAimTog, mzAimOn, "Micheal Aimbot: On", "Micheal Aimbot: Off")
        if mzAimConn then pcall(function() mzAimConn:Disconnect() end) mzAimConn = nil end
        if mzAimOn then
            if not mzAimCircle then
                pcall(function()
                    local c = Drawing.new("Circle")
                    c.Visible = false
                    c.NumSides = 64
                    c.Thickness = 1.5
                    c.Color = MZ_COL
                    c.Radius = mzAimRadius
                    mzAimCircle = c
                end)
            end
            mzOk("Micheal Aim ON (hold R-Click)")
            mzAimConn = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if not cam then return end
                if mzAimCircle then
                    mzAimCircle.Position = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
                    mzAimCircle.Radius = mzAimRadius
                    mzAimCircle.Visible = mzAimOn
                end
                if not mzAimOn or (not mzHolding and not _G.__NZZHold) then return end
                if _G.__NZAbLock then return end
                local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
                local best, bestPart, bestD = nil, nil, mzAimRadius
                local zf = mzZombies()
                if zf then
                    for _, m in ipairs(zf:GetChildren()) do
                        if m:IsA("Model") then
                            local hum = m:FindFirstChildOfClass("Humanoid")
                            if not hum or hum.Health > 0 then
                                local part = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local v, on = cam:WorldToViewportPoint(part.Position)
                                    if on then
                                        local d = (Vector2.new(v.X, v.Y) - Vector2.new(cx, cy)).Magnitude
                                        if d <= bestD then best, bestPart, bestD = m, part, d end
                                    end
                                end
                            end
                        end
                    end
                end
                if best and bestPart and bestPart.Parent then
                    local camPos = cam.CFrame.Position
                    pcall(function()
                        cam.CFrame = CFrame.new(camPos, bestPart.Position)
                    end)
                    mzStatus.Text = "Micheal Aim"
                    mzStatus.TextColor3 = COL_GREEN
                end
            end)
        else
            mzHolding = false
            if mzAimCircle then mzAimCircle.Visible = false end
            mzInfo("Micheal Aim OFF")
        end
    end)
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and not isAnyTextBoxFocused() then
            mzHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            mzHolding = false
        end
    end)

    local mzGunGroups = {
        { name = "Normal Guns", items = { "AK47", "AK74u", "AUG", "B93R", "BAR", "DBSG", "FG42", "Gewehr_43", "Kar98k", "LSAT", "M1911", "M1919", "M1A1_Carbine", "M1_Garand", "M4A4", "MG42", "MP40", "MP5", "Magnum", "MauserC96", "Model680", "PPSH", "Pistol", "STG44", "Saiga-12", "Thompson", "Trench", "Type100", "Walther", "PTRS", "Deagle", "FamasF1", "M14", "M16", "Shorty", "RPK", "LeverAction" } },
        { name = "Special Guns", items = { "Flamethrower", "Raygun", "GhoulBuster", "CoachGun", "Wunder_Waffe" } },
        { name = "Classic Guns", items = { "ClassicAK47", "ClassicAUG", "ClassicM4", "ClassicMP5", "ClassicP90", "ClassicRocketLauncher", "ClassicShotgun", "ClassicSniper", "ClassicFlamethrower" } },
        { name = "Explosive Guns", items = { "Panzer" } },
        { name = "PAP Guns", items = { "_PAP_Wunder_Waffe", "_PAP_ClassicFlamethrower", "_PAP_LeverAction", "_PAP_FamasF1", "_PAP_RPK", "_PAP_M16", "_PAP_Shorty", "_PAP_AK47", "_PAP_AK74u", "_PAP_AUG", "_PAP_B93R", "_PAP_BAR", "_PAP_ClassicAK47", "_PAP_ClassicAUG", "_PAP_ClassicM4", "_PAP_ClassicMP5", "_PAP_ClassicP90", "_PAP_ClassicRocketLauncher", "_PAP_ClassicShotgun", "_PAP_ClassicSniper", "_PAP_DBSG", "_PAP_FG42", "_PAP_Flamethrower", "_PAP_Gewehr_43", "_PAP_Kar98k", "_PAP_LSAT", "_PAP_M1911", "_PAP_M1919", "_PAP_M1A1_Carbine", "_PAP_M1_Garand", "_PAP_M4A4", "_PAP_MG42", "_PAP_MP40", "_PAP_MP5", "_PAP_Magnum", "_PAP_MauserC96", "_PAP_Model680", "_PAP_PPSH", "_PAP_Walther", "_PAP_Panzer", "_PAP_Pistol", "_PAP_Raygun", "_PAP_STG44", "_PAP_Saiga-12", "_PAP_Thompson", "_PAP_Trench", "_PAP_Type100", "_PAP_PTRS", "_PAP_Deagle" } },
        { name = "Water Guns", items = { "WaterDeagle", "WaterThompson", "WaterM1911", "WaterM1_Garand", "WaterMP5", "WaterModel680", "WaterPPSH", "WaterShorty", "WaterAK47", "WaterMP40", "WaterRaygun", "WaterType100" } },
    }
    local mzKnifeGroups = {
        { name = "Melees", items = { "Classic", "Bowie", "Oar", "Pan", "SportsBat", "LinkedSword", "TennisRacketBlue", "TennisRacketGreen", "TennisRacketRed", "TennisRacketYellow" } },
    }
    pageLabel(page, y, "In-Game Gun", 200); y = y + 22
    local mzG1Btn = pageWideBtn(page, y, "Change Gun1 Model"); y = y + 34
    local mzG2Btn = pageWideBtn(page, y, "Change Gun2 Model"); y = y + 34
    local mzG3Btn = pageWideBtn(page, y, "Change Gun3 Model"); y = y + 34
    local mzKnBtn = pageWideBtn(page, y, "Change Knife Model"); y = y + 34
    local mzModelDrop = Instance.new("ScrollingFrame")
    mzModelDrop.Size = UDim2.new(0, 300, 0, 300)
    mzModelDrop.Position = UDim2.new(0, 4, 0, y)
    mzModelDrop.BackgroundColor3 = COL_BG_ALT
    mzModelDrop.BorderSizePixel = 0
    mzModelDrop.ScrollBarThickness = 4
    mzModelDrop.ScrollBarImageColor3 = COL_ACCENT
    mzModelDrop.Visible = false
    mzModelDrop.ZIndex = 50
    mzModelDrop.Parent = page
    corner(mzModelDrop, 8)
    stroke(mzModelDrop, COL_ACCENT, 1)
    local function mzCharValue(name)
        local cs = mzFind("CharStats")
        if not cs then return nil end
        if name == "Knife" then
            local k = cs:FindFirstChild("Knife")
            if k and k:IsA("StringValue") then return k end
            return nil
        end
        local gi = cs:FindFirstChild("GunInventory")
        local g = gi and gi:FindFirstChild(name)
        if g and g:IsA("StringValue") then return g end
        return nil
    end
    local function mzSetModel(target, value)
        local v = mzCharValue(target)
        if not v then mzErr(target .. " not found in CharStats") return false end
        pcall(function() v.Value = value end)
        mzOk(target .. " = " .. value)
        return true
    end
    mzG1Btn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzModelDrop, mzGunGroups, function(p) mzSetModel("Gun1", p) end)
    end)
    mzG2Btn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzModelDrop, mzGunGroups, function(p) mzSetModel("Gun2", p) end)
    end)
    mzG3Btn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzModelDrop, mzGunGroups, function(p) mzSetModel("Gun3", p) end)
    end)
    mzKnBtn.MouseButton1Click:Connect(function()
        mzOpenDrop(mzModelDrop, mzKnifeGroups, function(p) mzSetModel("Knife", p) end)
    end)

    pageLabel(page, y, "Map Visuals", 200); y = y + 22
    pageLabel(page, y, "Remove Invisible Barriers", 200); local mzMapTog = pageToggle(page, y - 2, 160); y = y + 34
    local mzMapSaved = {}
    mzMapTog.MouseButton1Click:Connect(function()
        local on = mzMapTog.Text == "OFF"
        setToggle(mzMapTog, on)
        if on then
            local ig = Workspace:FindFirstChild("Ignore")
            local mc = ig and ig:FindFirstChild("MapCollisions")
            if mc then
                table.insert(mzMapSaved, { Item = mc, Parent = mc.Parent })
                pcall(function() mc.Parent = nil end)
                mzOk("MapCollisions removed")
            else
                mzErr("Ignore/MapCollisions not found")
            end
        else
            local c = 0
            for _, d in ipairs(mzMapSaved) do
                if d.Item then
                    pcall(function()
                        d.Item.Parent = d.Parent
                        c = c + 1
                    end)
                end
            end
            mzMapSaved = {}
            mzInfo("MapCollisions restored (" .. c .. ")")
        end
    end)

    page.CanvasSize = UDim2.new(0, 0, 0, math.max(y + 20, mzDrop.Position.Y.Offset + mzDrop.Size.Y.Offset, mzModelDrop.Position.Y.Offset + mzModelDrop.Size.Y.Offset) + 8)
    local function cleanMZ()
        mzPeaceOn = false
        mzRadOn = false
        mzEspOn = false
        mzAimOn = false
        mzHolding = false
        if mzEspConn then pcall(function() mzEspConn:Disconnect() end) mzEspConn = nil end
        if mzAimConn then pcall(function() mzAimConn:Disconnect() end) mzAimConn = nil end
        for mm, set in pairs(mzEspSets) do
            pcall(function() set.box:Remove() end)
            pcall(function() set.name:Remove() end)
            mzEspSets[mm] = nil
        end
        if mzAimCircle then pcall(function() mzAimCircle:Remove() end) mzAimCircle = nil end
        for _, dd in ipairs(mzMapSaved) do
            if dd.Item then pcall(function() dd.Item.Parent = dd.Parent end) end
        end
        mzMapSaved = {}
        mzUnhide()
        mzDrop.Visible = false
        mzModelDrop.Visible = false
    end
    _G.__NZCleanMZ = cleanMZ
end

print("NZ-MICHEALZOMBIES loaded")
