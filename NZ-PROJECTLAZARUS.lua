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

for _, k in ipairs({ "__NZCleanLZ" }) do
    local fn = _G[k]
    if fn then pcall(fn) end
    _G[k] = nil
end
pcall(function()
    local g = _G.__NZHUB_LAZARUS
    if g and g.Destroy then g:Destroy() end
    _G.__NZHUB_LAZARUS = nil
    if _G.__NZFly and _G.__NZFly.Destroy then pcall(function() _G.__NZFly:Destroy() end) end
    _G.__NZFly = nil
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, n in ipairs({ "NZ-HUB", "NZ-PROJECTLAZARUS" }) do
            local g = pg:FindFirstChild(n)
            if g then g:Destroy() end
        end
    end
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") and v.Name == "_NZBlur_PROJECTLAZARUS" then
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
gui.Name = "NZ-PROJECTLAZARUS"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
local okP = pg and pcall(function() gui.Parent = pg end)
if not okP then pcall(function() gui.Parent = CoreGui end) end
_G.__NZHUB_LAZARUS = gui

local blur = Instance.new("BlurEffect")
blur.Name = "_NZBlur_PROJECTLAZARUS"
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
title.Text = "NZ-PROJECTLAZARUS"
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
    for _, k in ipairs({ "__NZCleanLZ" }) do
        local fn = _G[k]
        if fn then pcall(fn) end
        _G[k] = nil
    end
    _G.__NZAbLock = false
    _G.__NZZHold = false
    _G.__NZZAbRadius = nil
    pcall(function() blur:Destroy() end)
    gui:Destroy()
    _G.__NZHUB_LAZARUS = nil
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

local HUB_TAB = "Project Lazarus"
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
    local page = pages["Project Lazarus"]
    local y = 4
    local lzStatus = Instance.new("TextLabel")
    lzStatus.Size = UDim2.new(1, -8, 0, 16); lzStatus.Position = UDim2.new(0, 4, 0, y)
    lzStatus.BackgroundTransparency = 1; lzStatus.Text = "Status: Ready"; lzStatus.TextColor3 = COL_GREEN
    lzStatus.Font = Enum.Font.Gotham; lzStatus.TextSize = 10; lzStatus.TextXAlignment = Enum.TextXAlignment.Left; lzStatus.Parent = page
    y = y + 20
    pageLabel(page, y, "Change All Weapon Camos"); y = y + 22
    local camoBtn = pageWideBtn(page, y, "Click To Select Camo"); y = y + 34
    local camoList = Instance.new("ScrollingFrame")
    camoList.Size = UDim2.new(0, 300, 0, 300)
    camoList.Position = UDim2.new(0, 4, 0, y)
    camoList.BackgroundColor3 = COL_BG_ALT
    camoList.BorderSizePixel = 0
    camoList.ScrollBarThickness = 4
    camoList.ScrollBarImageColor3 = COL_ACCENT
    camoList.Visible = false
    camoList.ZIndex = 50
    camoList.Parent = page
    corner(camoList, 8)
    stroke(camoList, COL_ACCENT, 1)
    pageLabel(page, y, "Change Level"); local lvlBox = pageBox(page, y - 2, 160, 90, "1"); local lvlApply = pageApply(page, y - 2, 258); y = y + 30
    pageLabel(page, y, "Peaceful Mode"); local peaceTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Del Zombie Radius", 140); local zrBox = pageBox(page, y - 2, 150, 60, "30"); local zrApply = pageApply(page, y - 2, 216, "Set"); local zrTog = pageToggle(page, y - 2, 282, 70); y = y + 30
    pageLabel(page, y, "Del InvisibleWalls"); local invTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Change FOV"); local fovBox = pageBox(page, y - 2, 160, 90, "70"); local fovApply = pageApply(page, y - 2, 258); y = y + 30
    pageLabel(page, y, "Zombie Esp"); local zespTog = pageToggle(page, y - 2, 160); y = y + 30
    pageLabel(page, y, "Zombie Aimbot"); local zAimTog = pageToggle(page, y - 2, 160, 150); zAimTog.Text = "Zombie Aimbot: Off"; y = y + 30
    pageLabel(page, y, "Zombie Aim Radius"); local zAbBox = pageBox(page, y - 2, 160, 90, "120"); local zAbApply = pageApply(page, y - 2, 258, "Set"); y = y + 30
    pageLabel(page, y, "Freeze All Zombies"); local zhbTog = pageToggle(page, y - 2, 160); y = y + 34
    pageLabel(page, y, "Perk Stuff", 200); y = y + 22
    local perkNames = { "Double Tap Root Beer", "Quick Revive", "Juggernog", "Speed Cola", "Mule Kick" }
    local perkLabels = { "Give Double Tap", "Give Quick Revive", "Give Juggernog", "Give Speed Cola", "Give Mule Kick" }
    local perkBtns = {}
    for i, nm in ipairs(perkNames) do
        local b = pageWideBtn(page, y, perkLabels[i]); y = y + 34
        perkBtns[nm] = b
    end
    local giveAllBtn = pageWideBtn(page, y, "Give All Perks"); y = y + 34
    local remAllBtn = pageWideBtn(page, y, "Remove All Perks"); y = y + 34
    pageLabel(page, y, "Gamepasses", 200); y = y + 22
    local gpData = {
        { "Give Glock Expansion", "Glock Expansion", 797889459 },
        { "Give AK Expansion", "AK Expansion", 26939810 },
        { "Give M16 Expansion", "M16 Expansion", 16679404 },
    }
    local gpBtns = {}
    for _, gd in ipairs(gpData) do
        local b = pageWideBtn(page, y, gd[1]); y = y + 34
        table.insert(gpBtns, b)
    end
    local gpAllBtn = pageWideBtn(page, y, "Give All GamePasses"); y = y + 34
    local gpRemBtn = pageWideBtn(page, y, "Remove All GamePasses"); y = y + 34
    page.CanvasSize = UDim2.new(0, 0, 0, y + 20)
    local camoData = {
        { name = "Common", items = { "Default", "Autumn", "Blue", "Desert", "Jungle", "Olive", "Red", "Snow", "Urban", "Violet", "Woodland" } },
        { name = "Rare", items = { "Abyss", "Adjudicator", "Antarctic", "Alder", "Bark", "Bellis", "Below Zero", "Bright Green", "Bright Yellow", "Bronze", "Buried", "Burnt Sienna", "Buttermilk", "Carnation", "Copper", "Crimson", "Cursed", "Cyan", "Dark Indigo", "Dawn", "Decay", "Deep Orange", "Desolate", "Diffusion", "Dove", "Dream", "Dry Heat", "Dusty Rose", "Eco", "Enforcer", "Engineer", "Everest", "Fairway", "Flint", "Flowerfield", "Foliage", "Forager", "Gyrfalcon", "Hot Cocoa", "Hot Pink", "Illusion", "Knave", "Laurel", "Lavender", "Lilac", "Lime", "Lithium", "Magnolia", "Maroon", "Medic", "Midnight", "Navy", "North Star", "Olive Oil", "Olivine", "Pacific", "Pastel Violet", "Patchwork", "Pine Cone", "Pulse", "Raider", "Rainforest", "Rust", "Sand Matte", "Shamrock", "Sludge", "Stonework", "Storm", "Sunken", "Sunrise", "Sunset", "Sunstroke", "Teal", "Tidal", "Tundra", "Vaporwave" } },
        { name = "Epic", items = { "Acid Drip", "Ancient", "Astro", "Bandit", "Buccellati", "Bumblebee", "Burgundy", "Calico", "Cartilage", "Caustic", "Cherry Blossom", "Cinders", "Copper Duds", "Curry", "Detective", "Dollhouse", "Dullahan", "E-Tech", "Eggplant", "Festive", "Friend", "Frosted", "Golden Wind", "Green Eggs", "Gremlin", "Guts", "Haunted", "Hyperion", "Kakapo", "Kirin", "Lambda", "Luminous", "Lycoris", "Maliwan", "Monkey", "Neapolitan", "Nerf", "Nordic", "Old Fashioned", "Pearl", "Phoenix", "Pink Devil", "Pumpkin", "Reaper", "Royal", "Shark", "Solitary", "Summer Waves", "Torque", "Toxic", "Tyto", "Vladof", "Watermelon" } },
        { name = "Legendary", items = { "Diamond", "Gold", "Malachite", "Obsidian", "Platinum" } },
    }
    local function lzCustom()
        local uname = string.lower(player.Name)
        local holders = {}
        local function addHolder(x)
            if x then
                for _, h in ipairs(holders) do if h == x then return end end
                table.insert(holders, x)
            end
        end
        addHolder(Players:FindFirstChild(player.Name))
        local ch = player.Character
        if ch then addHolder(ch) end
        for _, r in ipairs({ Workspace, game:GetService("ReplicatedStorage"), Lighting, Players }) do
            local ok, kids = pcall(function() return r:GetChildren() end)
            if ok then
                for _, k in ipairs(kids) do
                    if string.lower(k.Name) == uname then addHolder(k) end
                    if (k:IsA("Folder") or k:IsA("Model")) and string.lower(k.Name) == "players" then
                        local ok2, sub = pcall(function() return k:GetChildren() end)
                        if ok2 then
                            for _, s in ipairs(sub) do
                                if string.lower(s.Name) == uname then addHolder(s) end
                            end
                        end
                    end
                end
            end
        end
        for _, h in ipairs(holders) do
            for _, f in ipairs(h:GetDescendants()) do
                if f:IsA("Folder") and f.Name == "Customization" then return f end
            end
        end
        return nil
    end
    local function lzMe()
        local ch = player.Character
        if ch then return ch end
        return Workspace:FindFirstChild(player.Name)
    end
    local function lzSetCamo(camo)
        local f = lzCustom()
        if not f then lzStatus.Text = "Customization not found"; lzStatus.TextColor3 = COL_RED return false end
        local n = 0
        for _, v in ipairs(f:GetDescendants()) do
            if v:IsA("StringValue") and v.Name == "Selected" then
                local ok = pcall(function() v.Value = camo end)
                if ok then n = n + 1 end
            end
        end
        lzStatus.Text = camo .. " (" .. n .. " weapons)"; lzStatus.TextColor3 = COL_GREEN
        return true
    end
    local ly = 0
    for _, g in ipairs(camoData) do
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, -8, 0, 20); h.Position = UDim2.new(0, 4, 0, ly)
        h.BackgroundTransparency = 1; h.Text = g.name .. " â€” " .. #g.items
        h.TextColor3 = COL_ACCENT; h.Font = Enum.Font.GothamBold; h.TextSize = 12
        h.TextXAlignment = Enum.TextXAlignment.Left; h.Parent = camoList; h.ZIndex = 51
        ly = ly + 22
        for _, cn in ipairs(g.items) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -8, 0, 22); b.Position = UDim2.new(0, 4, 0, ly)
            b.BackgroundColor3 = COL_BG_ALT; b.Text = cn; b.TextColor3 = COL_TEXT
            b.Font = Enum.Font.Gotham; b.TextSize = 11; b.BorderSizePixel = 0
            b.AutoButtonColor = false; b.Parent = camoList; b.ZIndex = 51
            corner(b, 4)
            local pick = cn
            b.MouseButton1Click:Connect(function()
                camoBtn.Text = pick
                camoList.Visible = false
                lzSetCamo(pick)
            end)
            ly = ly + 24
        end
    end
    camoList.CanvasSize = UDim2.new(0, 0, 0, ly + 4)
    camoBtn.MouseButton1Click:Connect(function()
        camoList.Visible = not camoList.Visible
    end)
    lvlApply.MouseButton1Click:Connect(function()
        local n = tonumber(lvlBox.Text)
        if not n then flashErr(lvlBox) return end
        local holder = Players:FindFirstChild(player.Name)
        local plv = holder and holder:FindFirstChild("Leveling")
        local v = plv and plv:FindFirstChild("Level")
        if (not v or not v:IsA("IntValue")) then
            local m = lzMe()
            local lv = m and m:FindFirstChild("Leveling")
            v = lv and lv:FindFirstChild("Level")
        end
        if (not v or not v:IsA("IntValue")) then
            local m = lzMe()
            if m then
                local direct = m:FindFirstChild("Level")
                if direct and direct:IsA("IntValue") then v = direct end
            end
        end
        if (not v or not v:IsA("IntValue")) then
            local m = lzMe()
            if m then
                for _, d in ipairs(m:GetDescendants()) do
                    if d:IsA("IntValue") and d.Name == "Level" then v = d break end
                end
            end
        end
        if v and v:IsA("IntValue") then
            v.Value = math.floor(n); flashOk(lvlBox)
            lvlBox.Text = tostring(math.floor(n))
            lzStatus.Text = "Level " .. tostring(math.floor(n)); lzStatus.TextColor3 = COL_GREEN
        else
            lzStatus.Text = "Level not found"; lzStatus.TextColor3 = COL_RED
        end
    end)
    local function lzKillZombies(maxDist)
        local bf = Workspace:FindFirstChild("Baddies")
        if not bf then return 0 end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local n = 0
        for _, m in ipairs(bf:GetChildren()) do
            if m:IsA("Model") and m.Name == "Zombie" then
                local skip = false
                if maxDist then
                    if not root then skip = true
                    else
                        local ok, piv = pcall(function() return m:GetPivot() end)
                        if not ok or (piv.Position - root.Position).Magnitude > maxDist then skip = true end
                    end
                end
                if not skip then
                    local ok = pcall(function() m:Destroy() end)
                    if ok then n = n + 1 end
                end
            end
        end
        return n
    end
    local peaceOn = false
    peaceTog.MouseButton1Click:Connect(function()
        peaceOn = not peaceOn; setToggle(peaceTog, peaceOn)
        if peaceOn then
            lzStatus.Text = "Peaceful ON"
            task.spawn(function()
                while peaceOn do
                    lzKillZombies(nil)
                    task.wait(1.5)
                end
            end)
        else
            lzStatus.Text = "Peaceful OFF"
        end
    end)
    local zrOn, zrRad = false, 30
    zrApply.MouseButton1Click:Connect(function()
        local n = tonumber(zrBox.Text)
        if n then zrRad = math.clamp(n, 5, 500); zrBox.Text = tostring(zrRad); flashOk(zrBox)
        else flashErr(zrBox) end
    end)
    zrTog.MouseButton1Click:Connect(function()
        zrOn = not zrOn; setToggle(zrTog, zrOn)
        if zrOn then
            lzStatus.Text = "Radius delete ON (" .. tostring(zrRad) .. ")"
            task.spawn(function()
                while zrOn do
                    lzKillZombies(zrRad)
                    task.wait(1)
                end
            end)
        else
            lzStatus.Text = "Radius delete OFF"
        end
    end)
    local invSaved = {}
    invTog.MouseButton1Click:Connect(function()
        local on = invTog.Text == "OFF"
        setToggle(invTog, on)
        if on then
            local ig = Workspace:FindFirstChild("Ignore")
            if ig then
                for _, f in ipairs(ig:GetChildren()) do
                    if f:IsA("Folder") then
                        local nl = string.lower(f.Name)
                        if nl:find("invisib") or nl:find("nvisib") or nl:find("nsivib") then
                            table.insert(invSaved, { Item = f, Parent = f.Parent })
                            pcall(function() f.Parent = nil end)
                        end
                    end
                end
            end
            lzStatus.Text = "InvisibleWalls deleted (" .. #invSaved .. ")"
        else
            local c = 0
            for _, d in ipairs(invSaved) do
                if d.Item then
                    pcall(function()
                        d.Item.Parent = d.Parent
                        c = c + 1
                    end)
                end
            end
            invSaved = {}
            lzStatus.Text = "InvisibleWalls restored (" .. c .. ")"
        end
    end)
    local fovVal, fovLoop, fovRun = nil, false, false
    fovApply.MouseButton1Click:Connect(function()
        local n = tonumber(fovBox.Text)
        if not n then flashErr(fovBox) return end
        fovVal = n
        fovBox.Text = tostring(n)
        flashOk(fovBox)
        lzStatus.Text = "FOV looping " .. tostring(n); lzStatus.TextColor3 = COL_GREEN
        if not fovLoop then
            fovLoop = true
            fovRun = true
            task.spawn(function()
                while fovRun do
                    if fovVal then
                        local m = lzMe()
                        local v = m and m:FindFirstChild("CamFOV")
                        if v and v:IsA("NumberValue") then
                            pcall(function() v.Value = fovVal end)
                        end
                    end
                    task.wait(0.25)
                end
            end)
        end
    end)
    local zespOn, zespSets, zespConn, zespFrame, zespPhase, zespTick = false, {}, nil, 0, 0, 0
    zespTog.MouseButton1Click:Connect(function()
        zespOn = not zespOn; setToggle(zespTog, zespOn)
        if zespConn then pcall(function() zespConn:Disconnect() end) zespConn = nil end
        if zespOn then
            local okD, test = pcall(function() return Drawing.new("Square") end)
            if not okD or not test then
                zespOn = false; setToggle(zespTog, false)
                lzStatus.Text = "Drawing unsupported"; lzStatus.TextColor3 = COL_RED
                return
            end
            pcall(function() test:Remove() end)
            lzStatus.Text = "Zombie ESP ON"
            zespConn = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if not cam then return end
                zespFrame = zespFrame + 1
                local seen = {}
                local zShown = 0
                local pool = {}
                local bf = Workspace:FindFirstChild("Baddies")
                if bf then
                    for _, m in ipairs(bf:GetChildren()) do
                        if m:IsA("Model") and m.Name == "Zombie" then table.insert(pool, m) end
                    end
                end
                for _, m in ipairs(pool) do
                    seen[m] = true
                    local set = zespSets[m]
                    if not set then
                        local box = Drawing.new("Square")
                        box.Visible = false
                        box.Filled = false
                        box.Thickness = 1.5
                        box.Color = Color3.fromRGB(0, 255, 100)
                        local name = Drawing.new("Text")
                        name.Visible = false
                        name.Centered = true
                        name.Size = 13
                        name.Outline = true
                        name.Color = Color3.fromRGB(0, 255, 100)
                        set = { box = box, name = name, phase = zespPhase, part = nil, hum = nil }
                        zespPhase = zespPhase + 1
                        if zespPhase >= 2 then zespPhase = 0 end
                        zespSets[m] = set
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
                        elseif d <= 250 or (zespFrame + (set.phase or 0)) % 2 == 0 then
                            local v, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local h = math.clamp(1500 / math.max(d, 1), 20, 300)
                                local w = h * 0.6
                                set.box.Size = Vector2.new(w, h)
                                set.box.Position = Vector2.new(v.X - w * 0.5, v.Y - h * 0.5)
                                set.box.Visible = true
                            set.name.Text = "Zombie [" .. math.floor(d + 0.5) .. "]"
                            set.name.Position = Vector2.new(v.X, v.Y - h * 0.5 - 14)
                            set.name.Visible = true
                            zShown = zShown + 1
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
                for m, set in pairs(zespSets) do
                    if not seen[m] or not m.Parent then
                        pcall(function() set.box:Remove() end)
                        pcall(function() set.name:Remove() end)
                        zespSets[m] = nil
                    end
                end
                if os.clock() - zespTick >= 1 then
                    zespTick = os.clock()
                    lzStatus.Text = "ZESP " .. zShown .. " shown"
                end
            end)
        else
            for m, set in pairs(zespSets) do
                pcall(function() set.box:Remove() end)
                pcall(function() set.name:Remove() end)
                zespSets[m] = nil
            end
            lzStatus.Text = "Zombie ESP OFF"
        end
    end)
    local zAbOn, zAbRadius, zAbConn, zHolding, zAbCircle = false, 120, nil, false, nil
    zAbApply.MouseButton1Click:Connect(function()
        local n = tonumber(zAbBox.Text)
        if n then zAbRadius = math.clamp(n, 20, 600); zAbBox.Text = tostring(zAbRadius); flashOk(zAbBox)
            if zAbCircle then zAbCircle.Radius = zAbRadius end
        else flashErr(zAbBox) end
    end)
    zAimTog.MouseButton1Click:Connect(function()
        zAbOn = not zAbOn; setToggle(zAimTog, zAbOn, "Zombie Aimbot: On", "Zombie Aimbot: Off")
        if zAbConn then pcall(function() zAbConn:Disconnect() end) zAbConn = nil end
        if zAbOn then
            if not zAbCircle then
                pcall(function()
                    local c = Drawing.new("Circle")
                    c.Visible = false
                    c.NumSides = 64
                    c.Thickness = 1.5
                    c.Color = Color3.fromRGB(0, 255, 100)
                    c.Radius = zAbRadius
                    zAbCircle = c
                end)
            end
            lzStatus.Text = "Zombie Aim ON (hold R-Click)"
            zAbConn = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if not cam then return end
                if zAbCircle then
                    zAbCircle.Position = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
                    zAbCircle.Radius = zAbRadius
                    zAbCircle.Visible = zAbOn
                end
                if not zAbOn or (not zHolding and not _G.__NZZHold) then return end
                if _G.__NZAbLock then return end
                local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
                local best, bestPart, bestD = nil, nil, zAbRadius
                local bf = Workspace:FindFirstChild("Baddies")
                if bf then
                    for _, m in ipairs(bf:GetChildren()) do
                        if m:IsA("Model") and m.Name == "Zombie" then
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
                    local ch0 = player.Character
                    local camPos = cam.CFrame.Position
                    pcall(function()
                        cam.CFrame = CFrame.new(camPos, bestPart.Position)
                    end)
                    lzStatus.Text = "ZAim"
                end
            end)
        else
            zHolding = false
            if zAbCircle then zAbCircle.Visible = false end
            lzStatus.Text = "Zombie Aim OFF"
        end
    end)
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and not isAnyTextBoxFocused() then
            zHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            zHolding = false
        end
    end)
    local zhbOn, zhbMult, zhbOrig = false, 100, {}
    local function zhbApplyModel(m)
        local rp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
        if not rp then return end
        if zhbOrig[rp] == nil then
            zhbOrig[rp] = { s = rp.Size, t = rp.Transparency, c = rp.CanCollide, m = rp.Massless }
        end
        pcall(function()
            rp.Size = zhbOrig[rp].s * zhbMult
            rp.Transparency = 1
            rp.CanCollide = false
            rp.CanQuery = true
            rp.Massless = true
        end)
    end
    zhbTog.MouseButton1Click:Connect(function()
        zhbOn = not zhbOn; setToggle(zhbTog, zhbOn)
        if zhbOn then
            lzStatus.Text = "Frozen x" .. tostring(zhbMult)
            task.spawn(function()
                while zhbOn do
                    local bf = Workspace:FindFirstChild("Baddies")
                    if bf then
                        for _, m in ipairs(bf:GetChildren()) do
                            if m:IsA("Model") and m.Name == "Zombie" then zhbApplyModel(m) end
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            for p, v in pairs(zhbOrig) do
                pcall(function()
                    p.Size = v.s
                    p.Transparency = v.t
                    p.CanCollide = v.c
                    p.Massless = v.m
                end)
            end
            zhbOrig = {}
            lzStatus.Text = "Unfrozen"
        end
    end)
    local function lzPerkFolder()
        local bp = player:FindFirstChild("Backpack")
        if not bp then return nil end
        local f = bp:FindFirstChild("Perks")
        if not f then
            local ok, nf = pcall(function()
                local nn = Instance.new("Folder")
                nn.Name = "Perks"
                nn.Parent = bp
                return nn
            end)
            if ok then f = nf end
        end
        return f
    end
    local function lzGivePerk(nm)
        local f = lzPerkFolder()
        if not f then lzStatus.Text = "No backpack"; lzStatus.TextColor3 = COL_RED return 0 end
        local v = f:FindFirstChild(nm)
        if not v then
            v = Instance.new("BoolValue")
            v.Name = nm
            v.Parent = f
        end
        pcall(function() v.Value = true end)
        return 1
    end
    for nm, b in pairs(perkBtns) do
        local want = nm
        b.MouseButton1Click:Connect(function()
            if lzGivePerk(want) > 0 then
                lzStatus.Text = want .. " given"; lzStatus.TextColor3 = COL_GREEN
            end
        end)
    end
    giveAllBtn.MouseButton1Click:Connect(function()
        local n = 0
        for _, nm in ipairs(perkNames) do n = n + lzGivePerk(nm) end
        lzStatus.Text = "All perks given (" .. n .. ")"; lzStatus.TextColor3 = COL_GREEN
    end)
    remAllBtn.MouseButton1Click:Connect(function()
        local bp = player:FindFirstChild("Backpack")
        local f = bp and bp:FindFirstChild("Perks")
        local n = 0
        if f then
            for _, nm in ipairs(perkNames) do
                local v = f:FindFirstChild(nm)
                if v then pcall(function() v:Destroy() end) n = n + 1 end
            end
        end
        lzStatus.Text = "Removed " .. n .. " perks"; lzStatus.TextColor3 = COL_YELLOW
    end)
    local function lzGamepasses()
        local cf = lzCustom()
        local holder = cf and cf.Parent
        local gf = holder and holder:FindFirstChild("GamePasses")
        return gf
    end
    local function lzGivePass(nm, id)
        local gf = lzGamepasses()
        if not gf then lzStatus.Text = "GamePasses not found"; lzStatus.TextColor3 = COL_RED return 0 end
        local v = gf:FindFirstChild(nm)
        if not v then
            v = Instance.new("IntValue")
            v.Name = nm
            v.Parent = gf
        end
        pcall(function() v.Value = id end)
        return 1
    end
    for i, b in ipairs(gpBtns) do
        local nm = gpData[i][2]
        local id = gpData[i][3]
        b.MouseButton1Click:Connect(function()
            if lzGivePass(nm, id) > 0 then
                lzStatus.Text = nm .. " given"; lzStatus.TextColor3 = COL_GREEN
            end
        end)
    end
    gpAllBtn.MouseButton1Click:Connect(function()
        local n = 0
        for _, gd in ipairs(gpData) do n = n + lzGivePass(gd[2], gd[3]) end
        lzStatus.Text = "All gamepasses given (" .. n .. ")"; lzStatus.TextColor3 = COL_GREEN
    end)
    gpRemBtn.MouseButton1Click:Connect(function()
        local gf = lzGamepasses()
        local n = 0
        if gf then
            for _, gd in ipairs(gpData) do
                local v = gf:FindFirstChild(gd[2])
                if v then pcall(function() v:Destroy() end) n = n + 1 end
            end
        end
        lzStatus.Text = "Removed " .. n .. " gamepasses"; lzStatus.TextColor3 = COL_YELLOW
    end)
    local function cleanLZ()
        peaceOn = false
        zrOn = false
        fovVal = nil
        fovRun = false
        zespOn = false
        zAbOn = false
        zHolding = false
        zhbOn = false
        for p, v in pairs(zhbOrig) do
            pcall(function()
                p.Size = v.s
                p.Transparency = v.t
                p.CanCollide = v.c
                p.Massless = v.m
            end)
        end
        zhbOrig = {}
        if zespConn then pcall(function() zespConn:Disconnect() end) zespConn = nil end
        if zAbConn then pcall(function() zAbConn:Disconnect() end) zAbConn = nil end
        for mm, set in pairs(zespSets) do
            pcall(function() set.box:Remove() end)
            pcall(function() set.name:Remove() end)
            zespSets[mm] = nil
        end
        if zAbCircle then pcall(function() zAbCircle:Remove() end) zAbCircle = nil end
        for _, dd in ipairs(invSaved) do
            if dd.Item then pcall(function() dd.Item.Parent = dd.Parent end) end
        end
        invSaved = {}
    end
    _G.__NZCleanLZ = cleanLZ
end

print("NZ-PROJECTLAZARUS loaded")
