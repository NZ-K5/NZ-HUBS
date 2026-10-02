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

for _, k in ipairs({ "__NZCleanGFX" }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    local g = _G.__NZHUB_GRAPHICS
    if g and g.Destroy then g:Destroy() end
    _G.__NZHUB_GRAPHICS = nil
    if _G.__NZFly and _G.__NZFly.Destroy then pcall(function() _G.__NZFly:Destroy() end) end
    _G.__NZFly = nil
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZ-HUB", "NZ-GRAPHICS" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur_GRAPHICS" then
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
gui.Name = "NZ-GRAPHICS"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB_GRAPHICS = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur_GRAPHICS"
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
title.Text = "NZ-GRAPHICS"
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
    for _, k in ipairs({ "__NZCleanGFX" }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB_GRAPHICS = nil
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

local HUB_TAB = "Graphics"
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
    local page = pages["Graphics"]
    local y = 4
    pageLabel(page, y, "FPS Unlock"); local fuBox = pageBox(page, y - 2, 160, 90, "144"); local fuApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Graphic Mode"); local gfxTog = pageToggle(page, y - 2, 160); y = y + 30
    local gfxNames = { "Optimized Realism", "Low Realism", "Medium Realism", "Ultra Realism" }
    local gfxOptBtns = {}
    for _, nm in ipairs(gfxNames) do
        local b = pageWideBtn(page, y, nm)
        b.TextColor3 = COL_TEXT_DIM
        gfxOptBtns[nm] = b
        y = y + 34
    end
    local fogMode = "Original Fog"
    local fogPresets = {
        ["Low Fog"]    = { fogEnd = 70000, density = 0.18, haze = 1 },
        ["Medium Fog"] = { fogEnd = 24000, density = 0.35, haze = 3 },
        ["High Fog"]   = { fogEnd = 6000,  density = 0.55, haze = 5 },
        ["FoggyDay"]   = { fogEnd = 1200,  density = 0.78, haze = 8 },
    }
    local fogBtns = {}
    local function fogPaint()
        for nm, b in pairs(fogBtns) do
            if nm == fogMode then
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = COL_ACCENT, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            else
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = COL_BG_ALT, TextColor3 = COL_TEXT_DIM }):Play()
            end
        end
    end
    y = y + 8
    pageLabel(page, y, "Fog Options")
    y = y + 24
    local fogNames = { "Original Fog", "Low Fog", "Medium Fog", "High Fog", "FoggyDay" }
    for i, nm in ipairs(fogNames) do
        local b = pageWideBtn(page, y, nm)
        b.Size = UDim2.new(0, 165, 0, 26)
        b.TextColor3 = COL_TEXT_DIM
        if i % 2 == 0 then b.Position = UDim2.new(0, 177, 0, y) end
        if i % 2 == 0 then y = y + 30 end
        fogBtns[nm] = b
    end
    y = y + 34
    local fpsLbl = Instance.new("TextLabel")
    fpsLbl.Size = UDim2.new(1, -8, 0, 16); fpsLbl.Position = UDim2.new(0, 4, 0, y)
    fpsLbl.BackgroundTransparency = 1; fpsLbl.Text = "FPS: -"; fpsLbl.TextColor3 = COL_GREEN
    fpsLbl.Font = Enum.Font.GothamBold; fpsLbl.TextSize = 12; fpsLbl.TextXAlignment = Enum.TextXAlignment.Left; fpsLbl.Parent = page
    y = y + 20
    local gfxStatus = Instance.new("TextLabel")
    gfxStatus.Size = UDim2.new(1, -8, 0, 16); gfxStatus.Position = UDim2.new(0, 4, 0, y)
    gfxStatus.BackgroundTransparency = 1; gfxStatus.Text = "Status: Ready"; gfxStatus.TextColor3 = COL_TEXT_DIM
    gfxStatus.Font = Enum.Font.Gotham; gfxStatus.TextSize = 10; gfxStatus.TextXAlignment = Enum.TextXAlignment.Left; gfxStatus.Parent = page
    y = y + 22
    page.CanvasSize = UDim2.new(0, 0, 0, y + 20)
    local function setCap(n)
        if not setfpscap then return false end
        local ok = pcall(function() setfpscap(n) end)
        return ok
    end
    fuApply.MouseButton1Click:Connect(function()
        local n = tonumber(fuBox.Text)
        if not n then flashErr(fuBox) return end
        n = math.clamp(math.floor(n), 30, 1000)
        if setCap(n) then
            fuBox.Text = tostring(n); flashOk(fuBox)
            gfxStatus.Text = "FPS cap " .. tostring(n); gfxStatus.TextColor3 = COL_GREEN
        else
            gfxStatus.Text = "setfpscap unsupported"; gfxStatus.TextColor3 = COL_RED
        end
    end)
    local fpsAcc, fpsN = 0, 0
    local fpsConn = RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end
        fpsAcc = fpsAcc + dt
        fpsN = fpsN + 1
        if fpsAcc >= 0.5 then
            local f = math.floor(fpsN / math.max(fpsAcc, 0.001) + 0.5)
            if fpsLbl and fpsLbl.Parent then fpsLbl.Text = "FPS: " .. tostring(f) end
            fpsAcc, fpsN = 0, 0
        end
    end)
    local gfxOn, gfxPreset, gfxSaved, gfxMade, gfxLoop = false, "Optimized Realism", {}, {}, false
    local function techEnum(member)
        local ok, e = pcall(function() return Enum.Technology[member] end)
        if ok and e then return e end
        ok, e = pcall(function() return Enum.LightingTechnology[member] end)
        if ok and e then return e end
        return nil
    end
    local TECH = {
        ShadowMap = techEnum("ShadowMap"),
        Voxel = techEnum("Voxel"),
        Future = techEnum("Future"),
    }
    local gfxPresets = {
        ["Optimized Realism"] = { tech = TECH.ShadowMap, shadows = true, bright = 2, bloom = 0.6, dof = 0, rays = 0.02, sat = 0.15, con = 0.1 },
        ["Low Realism"] = { tech = TECH.Voxel, shadows = false, bright = 1.5, bloom = 0, dof = 0, rays = 0, sat = 0, con = 0 },
        ["Medium Realism"] = { tech = TECH.ShadowMap, shadows = true, bright = 2.2, bloom = 1, dof = 0.15, rays = 0.05, sat = 0.25, con = 0.15 },
        ["Ultra Realism"] = { tech = TECH.Future, shadows = true, bright = 2.5, bloom = 1.6, dof = 0.4, rays = 0.09, sat = 0.35, con = 0.2 },
    }
    local function gfxPaintOpts()
        for nm, b in pairs(gfxOptBtns) do
            if nm == gfxPreset then
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = COL_ACCENT, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            else
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = COL_BG_ALT, TextColor3 = COL_TEXT_DIM }):Play()
            end
        end
    end
    local function gfxFx(class, props)
        local e = nil
        for _, d in ipairs(Lighting:GetChildren()) do
            if d.ClassName == class and d.Name == "_NZFx" then e = d break end
        end
        if not e then
            e = Instance.new(class)
            e.Name = "_NZFx"
            e.Parent = Lighting
            table.insert(gfxMade, e)
        end
        for k, v in pairs(props) do pcall(function() e[k] = v end) end
        return e
    end
    local function gfxSave()
        gfxSaved = {}
        for _, k in ipairs({ "Technology", "GlobalShadows", "Brightness", "FogColor", "FogEnd", "FogStart", "Ambient", "OutdoorAmbient" }) do
            pcall(function() gfxSaved[k] = Lighting[k] end)
        end
        local at = Lighting:FindFirstChildOfClass("Atmosphere")
        if at then
            gfxSaved.atmo = {}
            for _, k in ipairs({ "Density", "Offset", "Color", "Decay", "Glare", "Haze" }) do
                pcall(function() gfxSaved.atmo[k] = at[k] end)
            end
        end
    end
    local function gfxClearMade()
        for _, e in ipairs(gfxMade) do pcall(function() e:Destroy() end) end
        gfxMade = {}
    end
    local function gfxRestore()
        for k, v in pairs(gfxSaved) do
            if k ~= "atmo" then pcall(function() Lighting[k] = v end) end
        end
        if gfxSaved.atmo then
            local at = Lighting:FindFirstChildOfClass("Atmosphere")
            if at then
                for k, v in pairs(gfxSaved.atmo) do pcall(function() at[k] = v end) end
            end
        end
        gfxClearMade()
    end
    local function applyFog(day)
        if fogMode == "Original Fog" then
            local s = gfxSaved
            pcall(function()
                Lighting.FogStart = (s.FogStart ~= nil) and s.FogStart or 0
                Lighting.FogEnd = (s.FogEnd ~= nil) and s.FogEnd or 100000
                if s.FogColor then Lighting.FogColor = s.FogColor end
            end)
            local a = s.atmo
            local at = Lighting:FindFirstChildOfClass("Atmosphere")
            if at and at.Name == "_NZFx" and not a then
                for i, e in ipairs(gfxMade) do
                    if e == at then table.remove(gfxMade, i) break end
                end
                pcall(function() at:Destroy() end)
                at = nil
            end
            if at and a then
                pcall(function()
                    if a.Density then at.Density = a.Density end
                    if a.Haze then at.Haze = a.Haze end
                    if a.Color then at.Color = a.Color end
                    if a.Decay then at.Decay = a.Decay end
                    if a.Glare then at.Glare = a.Glare end
                    if a.Offset then at.Offset = a.Offset end
                end)
            end
            return
        end
        local f = fogPresets[fogMode]
        if not f then return end
        pcall(function()
            Lighting.FogStart = 0
            Lighting.FogEnd = f.fogEnd
            Lighting.FogColor = day and Color3.fromRGB(200, 208, 220) or Color3.fromRGB(24, 28, 44)
        end)
        local at = Lighting:FindFirstChildOfClass("Atmosphere")
        if not at then at = gfxFx("Atmosphere", {}) end
        if at then
            pcall(function()
                at.Density = f.density
                at.Haze = f.haze
                at.Color = day and Color3.fromRGB(205, 214, 228) or Color3.fromRGB(26, 32, 50)
                at.Decay = day and Color3.fromRGB(150, 180, 200) or Color3.fromRGB(10, 15, 30)
                at.Glare = 0
            end)
        end
    end
    local function gfxApply(name)
        local p = gfxPresets[name]
        if not p then return end
        local mins = 720
        pcall(function() mins = Lighting:GetMinutesAfterMidnight() end)
        local day = mins > 360 and mins < 1080
        if p.tech then pcall(function() Lighting.Technology = p.tech end) end
        pcall(function() Lighting.GlobalShadows = p.shadows end)
        pcall(function() Lighting.Brightness = p.bright end)
        pcall(function()
            if day then
                Lighting.Ambient = Color3.fromRGB(140, 140, 150)
                Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 130)
            else
                Lighting.Ambient = Color3.fromRGB(35, 35, 45)
                Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 40)
            end
        end)
        applyFog(day)
        gfxFx("BloomEffect", { Intensity = p.bloom, Size = 24, Threshold = day and 1.2 or 0.9 })
        gfxFx("SunRaysEffect", { Intensity = p.rays, Spread = 0.3 })
        gfxFx("ColorCorrectionEffect", { Saturation = p.sat, Contrast = p.con, TintColor = Color3.fromRGB(255, 255, 255) })
        gfxFx("DepthOfFieldEffect", { FarIntensity = p.dof, FocusDistance = 500, InFocusRadius = 100, NearIntensity = 0 })
    end
    for nm, b in pairs(gfxOptBtns) do
        local pick = nm
        b.MouseButton1Click:Connect(function()
            gfxPreset = pick
            gfxPaintOpts()
            gfxStatus.Text = pick
            if gfxOn then
                gfxRestore()
                gfxApply(pick)
            end
        end)
        b.MouseLeave:Connect(function() task.defer(gfxPaintOpts) end)
    end
    gfxPaintOpts()
    for nm, b in pairs(fogBtns) do
        local pick = nm
        b.MouseButton1Click:Connect(function()
            fogMode = pick
            fogPaint()
            gfxStatus.Text = "Fog: " .. pick
            if gfxOn then gfxApply(gfxPreset) end
        end)
        b.MouseLeave:Connect(function() task.defer(fogPaint) end)
    end
    fogPaint()
    gfxTog.MouseButton1Click:Connect(function()
        gfxOn = not gfxOn; setToggle(gfxTog, gfxOn)
        if gfxOn then
            gfxStatus.Text = "Applying..."; gfxStatus.TextColor3 = COL_YELLOW
            gfxSave()
            gfxApply(gfxPreset)
            local applied = gfxPreset
            if not gfxLoop then
                gfxLoop = true
                task.spawn(function()
                    while gfxOn do
                        task.wait(2)
                        if gfxOn then gfxApply(gfxPreset) end
                    end
                    gfxLoop = false
                end)
            end
            gfxStatus.Text = applied .. " ON"; gfxStatus.TextColor3 = COL_GREEN
            task.delay(1.5, function()
                if not gfxOn or gfxPreset ~= applied then return end
                local okC, cur = pcall(function() return Lighting.Brightness end)
                local w = gfxPresets[applied]
                if okC and w and math.abs(cur - w.bright) > 0.01 then
                    gfxStatus.Text = applied .. " - game is reverting"
                    gfxStatus.TextColor3 = COL_YELLOW
                end
            end)
        else
            gfxRestore()
            gfxSaved = {}
            gfxStatus.Text = "Graphics restored"
        end
    end)
    local function cleanGFX()
        gfxOn = false
        gfxLoop = false
        if fpsConn then pcall(function() fpsConn:Disconnect() end) fpsConn = nil end
        gfxRestore()
        gfxSaved = {}
    end
    _G.__NZCleanGFX = cleanGFX
end

print("NZ-GRAPHICS loaded")
