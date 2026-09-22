-- ================================================
-- ROCKET Egg ESP v24 для Ride a Pet
-- Оптимизировано: без фризов каждые 3 сек
-- Уведомления через DescendantAdded
-- Скорость ТП: 700
-- ================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- ============ НАСТРОЙКИ ============
local TARGET_EGGS = {"Galaxy", "Blackhole", "BlackHole", "Black Hole", "Solaris", "Cherub"}
local espEnabled = false
local trackedEggs = {}
local hudOpen = false
local fullyDisabled = false
local notifiedEggs = {}

-- ============ СПИСОК ЯИЦ ============
local EGG_LIST_NAMES = {
    "Glass Egg", "Golden Egg", "Crystal Egg", "Skull Egg",
    "Dominus Egg", "Flaming Egg", "Sinister Egg", "Soul Egg",
    "Aurora Egg", "Galaxy Egg", "Blackhole Egg",
    "Solaris Egg", "Cherub Egg",
}

local EGG_RARITY = {
    ["Glass Egg"] = {"Legendary", Color3.fromRGB(255, 200, 50), 1},
    ["Golden Egg"] = {"Legendary", Color3.fromRGB(255, 200, 50), 1},
    ["Crystal Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Skull Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Dominus Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Flaming Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Sinister Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Soul Egg"] = {"Mythic", Color3.fromRGB(255, 100, 100), 2},
    ["Aurora Egg"] = {"Divine", Color3.fromRGB(255, 100, 255), 3},
    ["Galaxy Egg"] = {"Divine", Color3.fromRGB(255, 100, 255), 3},
    ["Blackhole Egg"] = {"Ethereal", Color3.fromRGB(0, 255, 200), 4},
    ["Solaris Egg"] = {"Ethereal", Color3.fromRGB(0, 255, 200), 4},
    ["Cherub Egg"] = {"Ethereal", Color3.fromRGB(0, 255, 200), 4},
}

local eggCache = {}
local eggCacheTime = 0
local CACHE_LIFETIME = 3

-- ============ НАСТРОЙКИ ТП ============
local TELEPORT_SPEED = 700
local TELEPORT_STEP_TIME = 0.03
local TELEPORT_STOP_DISTANCE = 3
local NOCLIP_ENABLED = true

-- ============ ФИЛЬТР БАЗ ============
local BASE_IGNORE_RADIUS = 100
local BASE_KEYWORDS = {"Base", "Plot", "Pen", "Farm", "Yard", "House", "Home", "Territory", "Claim"}

-- ============ ГРАДИЕНТЫ ============
local GRADIENTS = {
    ["Galaxy"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(120, 60, 220)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(60, 120, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 80, 200)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 220, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(180, 100, 255)),
    }),
    ["Blackhole"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 180, 60)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(255, 80, 20)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(140, 40, 220)),
        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(40, 20, 80)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 200, 100)),
    }),
    ["BlackHole"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 180, 60)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(255, 80, 20)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(140, 40, 220)),
        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(40, 20, 80)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 200, 100)),
    }),
    ["Solaris"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 255, 180)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 200, 150)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 150, 100)),
    }),
    ["Cherub"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 240, 150)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 200, 80)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(200, 150, 50)),
    }),
}

-- ============ КАРТОГРАФ ============
local cartographEnabled = false
local savedEffects = {}

local function enableCartograph()
    if cartographEnabled then return end
    cartographEnabled = true
    savedEffects = {}

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") then
            table.insert(savedEffects, {obj = effect, prop = "Size", value = effect.Size})
            effect.Size = 0
        elseif effect:IsA("BloomEffect") then
            table.insert(savedEffects, {obj = effect, prop = "Intensity", value = effect.Intensity})
            effect.Intensity = 0
        elseif effect:IsA("ColorCorrectionEffect") then
            table.insert(savedEffects, {obj = effect, prop = "Saturation", value = effect.Saturation})
            effect.Saturation = -1
        elseif effect:IsA("SunRaysEffect") then
            table.insert(savedEffects, {obj = effect, prop = "Intensity", value = effect.Intensity})
            effect.Intensity = 0
        elseif effect:IsA("DepthOfFieldEffect") then
            table.insert(savedEffects, {obj = effect, prop = "FarIntensity", value = effect.FarIntensity})
            effect.FarIntensity = 0
        elseif effect:IsA("Atmosphere") then
            table.insert(savedEffects, {obj = effect, prop = "Density", value = effect.Density})
            effect.Density = 0
        elseif effect:IsA("Clouds") then
            table.insert(savedEffects, {obj = effect, prop = "Cover", value = effect.Cover})
            effect.Cover = 0
        end
    end

    local lightingProps = {"GlobalShadows", "Brightness", "Ambient", "OutdoorAmbient", "FogEnd", "FogStart", "EnvironmentDiffuseScale", "EnvironmentSpecularScale"}
    for _, prop in ipairs(lightingProps) do
        table.insert(savedEffects, {obj = Lighting, prop = prop, value = Lighting[prop]})
    end

    Lighting.GlobalShadows = false
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            if obj.Enabled then
                table.insert(savedEffects, {obj = obj, prop = "Enabled", value = true})
                obj.Enabled = false
            end
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            table.insert(savedEffects, {obj = obj, prop = "Transparency", value = obj.Transparency})
            obj.Transparency = 1
        end
    end
    print("[ROCKET] Картограф: ВКЛЮЧЁН")
end

local function disableCartograph()
    if not cartographEnabled then return end
    cartographEnabled = false
    for _, data in ipairs(savedEffects) do
        pcall(function()
            if data.obj and data.obj.Parent then
                data.obj[data.prop] = data.value
            end
        end)
    end
    savedEffects = {}
    print("[ROCKET] Картограф: ВЫКЛЮЧЕН")
end

-- ============ NOCLIP ============
local noclipActive = false
task.spawn(function()
    while true do
        task.wait(0.1)
        if noclipActive then
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- ============ ESP ============
local function getEggType(name)
    local lowerName = name:lower()
    for _, key in ipairs(TARGET_EGGS) do
        if lowerName:find(key:lower()) then return key end
    end
    return nil
end

local function isBaseObject(obj)
    local current = obj
    while current and current ~= Workspace do
        for _, keyword in ipairs(BASE_KEYWORDS) do
            if current.Name:find(keyword) then return true end
        end
        current = current.Parent
    end
    return false
end

local function isNearPlayerBase(obj)
    if isBaseObject(obj) then return true end
    local pos
    if obj:IsA("BasePart") then pos = obj.Position
    elseif obj:IsA("Model") then
        local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if primary then pos = primary.Position end
    end
    if not pos then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if (pos - char.HumanoidRootPart.Position).Magnitude < BASE_IGNORE_RADIUS then
                return true
            end
        end
    end
    return false
end

local function isTargetEgg(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    if not getEggType(obj.Name) then return false end
    if isNearPlayerBase(obj) then return false end
    return true
end

local function getEggPosition(obj)
    if obj:IsA("BasePart") then return obj.Position
    elseif obj:IsA("Model") then
        local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    end
    return nil
end

local function addEgg(obj)
    if trackedEggs[obj] then return end
    if not isTargetEgg(obj) then return end
    trackedEggs[obj] = true
    local eggType = getEggType(obj.Name)
    local gradient = GRADIENTS[eggType] or GRADIENTS["Galaxy"]

    local highlight = Instance.new("Highlight")
    highlight.Name = "EggHighlight"
    highlight.Adornee = obj
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = obj

    local hGrad = Instance.new("UIGradient")
    hGrad.Color = gradient
    hGrad.Parent = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggBillboard"
    billboard.Adornee = obj
    billboard.Size = UDim2.new(0, 120, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = obj

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = obj.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    local tGrad = Instance.new("UIGradient")
    tGrad.Color = gradient
    tGrad.Parent = label

    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(game) then
            trackedEggs[obj] = nil
        end
    end)
end

local function removeEgg(obj)
    trackedEggs[obj] = nil
    local h = obj:FindFirstChild("EggHighlight")
    if h then h:Destroy() end
    local b = obj:FindFirstChild("EggBillboard")
    if b then b:Destroy() end
end

local function removeAll()
    for obj, _ in pairs(trackedEggs) do
        removeEgg(obj)
    end
    trackedEggs = {}
end

local function scanExisting()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isTargetEgg(obj) then addEgg(obj) end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if espEnabled then
        task.wait(0.05)
        if obj.Parent and isTargetEgg(obj) then addEgg(obj) end
    end
end)

local function setESP(state)
    espEnabled = state
    if espEnabled then
        scanExisting()
        print("[ROCKET] ESP: ВКЛ")
    else
        removeAll()
        print("[ROCKET] ESP: ВЫКЛ")
    end
end

-- ============ УВЕДОМЛЕНИЯ (ОПТИМИЗИРОВАНО) ============
local function showNotification(eggName, distance)
    local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ROCKET_HUD")
    if not screenGui then return end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 320, 0, 70)
    notif.Position = UDim2.new(0, -350, 0.15, 0)
    notif.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    notif.BackgroundTransparency = 0.05
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    notif.Parent = screenGui

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 14)
    notifCorner.Parent = notif

    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 4, 1, 4)
    border.Position = UDim2.new(0, -2, 0, -2)
    border.BackgroundColor3 = Color3.fromRGB(255, 120, 40)
    border.BackgroundTransparency = 0.3
    border.BorderSizePixel = 0
    border.ZIndex = 99
    border.Parent = notif

    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 16)
    borderCorner.Parent = border

    local borderGrad = Instance.new("UIGradient")
    borderGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 60)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 80, 20)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(140, 40, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100)),
    })
    borderGrad.Rotation = 45
    borderGrad.Parent = border

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 60, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🕳"
    icon.TextColor3 = Color3.fromRGB(255, 180, 60)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.ZIndex = 101
    icon.Parent = notif

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 30)
    title.Position = UDim2.new(0, 60, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "🕳 BLACKHOLE EGG СПАВН!"
    title.TextColor3 = Color3.fromRGB(255, 180, 60)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 101
    title.Parent = notif

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, -70, 0, 25)
    distLabel.Position = UDim2.new(0, 60, 0, 38)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Расстояние: " .. math.floor(distance) .. " studs"
    distLabel.TextColor3 = Color3.fromRGB(255, 200, 150)
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.ZIndex = 101
    distLabel.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 0.15, 0),
    }):Play()

    task.delay(5, function()
        if notif and notif.Parent then
            local t = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -350, 0.15, 0),
                BackgroundTransparency = 1,
            })
            t:Play()
            t.Completed:Connect(function()
                if notif then notif:Destroy() end
            end)
        end
    end)
end

local function checkNewObject(obj)
    if fullyDisabled then return end
    if not obj or not obj.Parent then return end
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
    if notifiedEggs[obj] then return end

    local name = obj.Name:lower()
    if name:find("blackhole") or name:find("black hole") then
        if not isBaseObject(obj) then
            local pos = getEggPosition(obj)
            if pos then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    notifiedEggs[obj] = true
                    local dist = (pos - hrp.Position).Magnitude
                    showNotification("Blackhole Egg", dist)
                    print("[ROCKET] 🕳 Blackhole Egg спавн! Дистанция: " .. math.floor(dist))
                end
            end
        end
    end
end

-- Слушаем добавление новых объектов
Workspace.DescendantAdded:Connect(function(obj)
    if fullyDisabled then return end
    task.wait(0.1)
    pcall(checkNewObject, obj)
end)

-- Проверяем существующие при запуске (один раз)
task.spawn(function()
    task.wait(2)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("blackhole") or name:find("black hole") then
                pcall(checkNewObject, obj)
            end
        end
    end
end)

-- Очистка списка уведомлённых (редко)
task.spawn(function()
    while true do
        task.wait(10)
        for obj, _ in pairs(notifiedEggs) do
            if not obj or not obj.Parent then
                notifiedEggs[obj] = nil
            end
        end
    end
end)

-- ============ МАТЧ ЯЙЦА ============
local function matchEgg(name)
    for _, eggFull in ipairs(EGG_LIST_NAMES) do
        if name == eggFull or name:find(eggFull) then
            return eggFull
        end
    end
    return nil
end

-- ============ EGG LIST DATA ============
local function getEggListData()
    local list = {}
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return list end
    local now = tick()

    if now - eggCacheTime > CACHE_LIFETIME then
        eggCacheTime = now
        eggCache = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local matchedName = matchEgg(obj.Name)
                if matchedName and not isBaseObject(obj) then
                    local pos = getEggPosition(obj)
                    if pos then
                        local rarityData = EGG_RARITY[matchedName] or {"Unknown", Color3.fromRGB(150,150,150), 99}
                        table.insert(eggCache, {
                            obj = obj, name = matchedName,
                            rarity = rarityData[1], color = rarityData[2],
                            tier = rarityData[3] or 99, position = pos,
                        })
                    end
                end
            end
        end
    end

    for _, egg in ipairs(eggCache) do
        if egg.obj and egg.obj.Parent then
            egg.distance = (egg.position - hrp.Position).Magnitude
            table.insert(list, egg)
        end
    end

    table.sort(list, function(a, b)
        if a.tier == b.tier then return a.distance < b.distance end
        return a.tier < b.tier
    end)

    return list
end

-- ============ ТП ============
local teleporting = false

local function smoothTeleport(targetPos, label)
    if teleporting then return end
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    teleporting = true
    noclipActive = true

    local startPos = hrp.Position
    local distance = (targetPos - startPos).Magnitude
    print("[ROCKET] ТП к " .. label .. " (" .. math.floor(distance) .. " studs)")

    if distance < 10 then
        hrp.CFrame = CFrame.new(targetPos)
        noclipActive = false
        teleporting = false
        return
    end

    coroutine.wrap(function()
        local currentPos = startPos
        local stepSize = TELEPORT_SPEED * TELEPORT_STEP_TIME

        while true do
            local remaining = targetPos - currentPos
            if remaining.Magnitude <= TELEPORT_STOP_DISTANCE then break end
            if not hrp.Parent then break end

            local moveAmount = math.min(stepSize, remaining.Magnitude)
            currentPos = currentPos + remaining.Unit * moveAmount
            hrp.CFrame = CFrame.new(currentPos, currentPos + remaining.Unit)
            hrp.Velocity = Vector3.new(0, 0, 0)
            task.wait(TELEPORT_STEP_TIME)
        end

        hrp.CFrame = CFrame.new(targetPos)
        task.wait(0.1)
        noclipActive = false
        teleporting = false
        print("[ROCKET] ТП завершён")
    end)()
end

local function teleportToEgg(eggType)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closestEgg, closestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isTargetEgg(obj) then
            local objType = getEggType(obj.Name)
            if objType == eggType then
                local pos = getEggPosition(obj)
                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestEgg = pos
                    end
                end
            end
        end
    end

    if closestEgg then
        smoothTeleport(closestEgg + Vector3.new(0, 3, 0), eggType)
    else
        print("[ROCKET] Яйцо " .. eggType .. " не найдено")
    end
end

local function teleportToBase()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        smoothTeleport(spawn.Position + Vector3.new(0, 5, 0), "база")
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            for _, keyword in ipairs(BASE_KEYWORDS) do
                if obj.Name:find(keyword) then
                    local pos = getEggPosition(obj)
                    if pos then
                        smoothTeleport(pos + Vector3.new(0, 5, 0), "база")
                        return
                    end
                end
            end
        end
    end
    print("[ROCKET] База не найдена")
end

-- ============================================================
-- ===== HUD =====
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ROCKET_HUD"
screenGui.Parent = LocalPlayer.PlayerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 520)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainFrame

local glowFrame = Instance.new("Frame")
glowFrame.Size = UDim2.new(1, 6, 1, 6)
glowFrame.Position = UDim2.new(0, -3, 0, -3)
glowFrame.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
glowFrame.BackgroundTransparency = 0.2
glowFrame.BorderSizePixel = 0
glowFrame.Parent = mainFrame

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 22)
glowCorner.Parent = glowFrame

local glowGrad = Instance.new("UIGradient")
glowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200)),
})
glowGrad.Rotation = 45
glowGrad.Parent = glowFrame

local innerBg = Instance.new("Frame")
innerBg.Size = UDim2.new(1, 0, 1, 0)
innerBg.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
innerBg.BorderSizePixel = 0
innerBg.Parent = mainFrame

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 20)
innerCorner.Parent = innerBg

local innerGrad = Instance.new("UIGradient")
innerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 20)),
})
innerGrad.Rotation = 90
innerGrad.Parent = innerBg

local mainPage = Instance.new("Frame")
mainPage.Name = "MainPage"
mainPage.Size = UDim2.new(1, 0, 1, 0)
mainPage.BackgroundTransparency = 1
mainPage.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "✦  EGG ESP  ✦"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextStrokeColor3 = Color3.fromRGB(0, 150, 255)
title.TextStrokeTransparency = 0.3
title.Parent = mainPage

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Position = UDim2.new(0, 0, 0, 42)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Galaxy • Blackhole • Solaris • Cherub"
subtitle.TextColor3 = Color3.fromRGB(150, 200, 255)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = mainPage

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0.5, 0, 0, 42)
espBtn.Position = UDim2.new(0.25, 0, 0, 70)
espBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
espBtn.BackgroundTransparency = 0.15
espBtn.Text = "❌  ESP ВЫКЛЮЧЕН"
espBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
espBtn.TextScaled = true
espBtn.Font = Enum.Font.GothamBold
espBtn.BorderSizePixel = 2
espBtn.BorderColor3 = Color3.fromRGB(255, 50, 50)
espBtn.Parent = mainPage

local espBtnCorner = Instance.new("UICorner")
espBtnCorner.CornerRadius = UDim.new(0, 12)
espBtnCorner.Parent = espBtn

local espBtnGrad = Instance.new("UIGradient")
espBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 0)),
})
espBtnGrad.Rotation = 90
espBtnGrad.Parent = espBtn

espBtn.MouseButton1Click:Connect(function()
    if fullyDisabled then return end
    setESP(not espEnabled)
    if espEnabled then
        espBtn.Text = "✅  ESP ВКЛЮЧЁН"
        espBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        espBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        espBtn.BorderColor3 = Color3.fromRGB(50, 255, 50)
        espBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 255, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 0)),
        })
    else
        espBtn.Text = "❌  ESP ВЫКЛЮЧЕН"
        espBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        espBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        espBtn.BorderColor3 = Color3.fromRGB(255, 50, 50)
        espBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 0)),
        })
    end
end)

local tpGalaxyBtn = Instance.new("TextButton")
tpGalaxyBtn.Size = UDim2.new(0.30, 0, 0, 50)
tpGalaxyBtn.Position = UDim2.new(0.03, 0, 0, 130)
tpGalaxyBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
tpGalaxyBtn.BackgroundTransparency = 0.15
tpGalaxyBtn.Text = "🌌  ТП Galaxy"
tpGalaxyBtn.TextColor3 = Color3.fromRGB(220, 180, 255)
tpGalaxyBtn.TextScaled = true
tpGalaxyBtn.Font = Enum.Font.GothamBold
tpGalaxyBtn.BorderSizePixel = 2
tpGalaxyBtn.BorderColor3 = Color3.fromRGB(160, 100, 255)
tpGalaxyBtn.Parent = mainPage

local tpGalaxyCorner = Instance.new("UICorner")
tpGalaxyCorner.CornerRadius = UDim.new(0, 12)
tpGalaxyCorner.Parent = tpGalaxyBtn

local tpGalaxyGrad = Instance.new("UIGradient")
tpGalaxyGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 80, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
})
tpGalaxyGrad.Rotation = 45
tpGalaxyGrad.Parent = tpGalaxyBtn

tpGalaxyBtn.MouseButton1Click:Connect(function()
    teleportToEgg("Galaxy")
end)

local tpBlackholeBtn = Instance.new("TextButton")
tpBlackholeBtn.Size = UDim2.new(0.30, 0, 0, 50)
tpBlackholeBtn.Position = UDim2.new(0.35, 0, 0, 130)
tpBlackholeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 20)
tpBlackholeBtn.BackgroundTransparency = 0.15
tpBlackholeBtn.Text = "🕳  ТП Blackhole"
tpBlackholeBtn.TextColor3 = Color3.fromRGB(255, 200, 150)
tpBlackholeBtn.TextScaled = true
tpBlackholeBtn.Font = Enum.Font.GothamBold
tpBlackholeBtn.BorderSizePixel = 2
tpBlackholeBtn.BorderColor3 = Color3.fromRGB(255, 120, 50)
tpBlackholeBtn.Parent = mainPage

local tpBlackholeCorner = Instance.new("UICorner")
tpBlackholeCorner.CornerRadius = UDim.new(0, 12)
tpBlackholeCorner.Parent = tpBlackholeBtn

local tpBlackholeGrad = Instance.new("UIGradient")
tpBlackholeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 40, 220)),
})
tpBlackholeGrad.Rotation = 45
tpBlackholeGrad.Parent = tpBlackholeBtn

tpBlackholeBtn.MouseButton1Click:Connect(function()
    teleportToEgg("Blackhole")
end)

local tpBaseBtn = Instance.new("TextButton")
tpBaseBtn.Size = UDim2.new(0.30, 0, 0, 50)
tpBaseBtn.Position = UDim2.new(0.67, 0, 0, 130)
tpBaseBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
tpBaseBtn.BackgroundTransparency = 0.15
tpBaseBtn.Text = "🏠  ТП к базе"
tpBaseBtn.TextColor3 = Color3.fromRGB(200, 240, 255)
tpBaseBtn.TextScaled = true
tpBaseBtn.Font = Enum.Font.GothamBold
tpBaseBtn.BorderSizePixel = 2
tpBaseBtn.BorderColor3 = Color3.fromRGB(0, 200, 255)
tpBaseBtn.Parent = mainPage

local tpBaseCorner = Instance.new("UICorner")
tpBaseCorner.CornerRadius = UDim.new(0, 12)
tpBaseCorner.Parent = tpBaseBtn

local tpBaseGrad = Instance.new("UIGradient")
tpBaseGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 150)),
})
tpBaseGrad.Rotation = 45
tpBaseGrad.Parent = tpBaseBtn

tpBaseBtn.MouseButton1Click:Connect(function()
    teleportToBase()
end)

local tpSolarisBtn = Instance.new("TextButton")
tpSolarisBtn.Size = UDim2.new(0.30, 0, 0, 50)
tpSolarisBtn.Position = UDim2.new(0.03, 0, 0, 190)
tpSolarisBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
tpSolarisBtn.BackgroundTransparency = 0.15
tpSolarisBtn.Text = "☀  ТП Solaris"
tpSolarisBtn.TextColor3 = Color3.fromRGB(150, 255, 220)
tpSolarisBtn.TextScaled = true
tpSolarisBtn.Font = Enum.Font.GothamBold
tpSolarisBtn.BorderSizePixel = 2
tpSolarisBtn.BorderColor3 = Color3.fromRGB(0, 255, 180)
tpSolarisBtn.Parent = mainPage

local tpSolarisCorner = Instance.new("UICorner")
tpSolarisCorner.CornerRadius = UDim.new(0, 12)
tpSolarisCorner.Parent = tpSolarisBtn

local tpSolarisGrad = Instance.new("UIGradient")
tpSolarisGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 100)),
})
tpSolarisGrad.Rotation = 45
tpSolarisGrad.Parent = tpSolarisBtn

tpSolarisBtn.MouseButton1Click:Connect(function()
    teleportToEgg("Solaris")
end)

local tpCherubBtn = Instance.new("TextButton")
tpCherubBtn.Size = UDim2.new(0.30, 0, 0, 50)
tpCherubBtn.Position = UDim2.new(0.35, 0, 0, 190)
tpCherubBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 80)
tpCherubBtn.BackgroundTransparency = 0.15
tpCherubBtn.Text = "👼  ТП Cherub"
tpCherubBtn.TextColor3 = Color3.fromRGB(255, 240, 150)
tpCherubBtn.TextScaled = true
tpCherubBtn.Font = Enum.Font.GothamBold
tpCherubBtn.BorderSizePixel = 2
tpCherubBtn.BorderColor3 = Color3.fromRGB(255, 220, 100)
tpCherubBtn.Parent = mainPage

local tpCherubCorner = Instance.new("UICorner")
tpCherubCorner.CornerRadius = UDim.new(0, 12)
tpCherubCorner.Parent = tpCherubBtn

local tpCherubGrad = Instance.new("UIGradient")
tpCherubGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 50)),
})
tpCherubGrad.Rotation = 45
tpCherubGrad.Parent = tpCherubBtn

tpCherubBtn.MouseButton1Click:Connect(function()
    teleportToEgg("Cherub")
end)

local cartographBtn = Instance.new("TextButton")
cartographBtn.Size = UDim2.new(0.94, 0, 0, 50)
cartographBtn.Position = UDim2.new(0.03, 0, 0, 250)
cartographBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
cartographBtn.BackgroundTransparency = 0.15
cartographBtn.Text = "🗺  КАРТОГРАФ: ВЫКЛ"
cartographBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
cartographBtn.TextScaled = true
cartographBtn.Font = Enum.Font.GothamBold
cartographBtn.BorderSizePixel = 2
cartographBtn.BorderColor3 = Color3.fromRGB(120, 120, 120)
cartographBtn.Parent = mainPage

local cartographCorner = Instance.new("UICorner")
cartographCorner.CornerRadius = UDim.new(0, 12)
cartographCorner.Parent = cartographBtn

local cartographGrad = Instance.new("UIGradient")
cartographGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60)),
})
cartographGrad.Rotation = 90
cartographGrad.Parent = cartographBtn

cartographBtn.MouseButton1Click:Connect(function()
    if cartographEnabled then
        disableCartograph()
        cartographBtn.Text = "🗺  КАРТОГРАФ: ВЫКЛ"
        cartographBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        cartographBtn.BorderColor3 = Color3.fromRGB(120, 120, 120)
        cartographGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60)),
        })
    else
        enableCartograph()
        cartographBtn.Text = "🗺  КАРТОГРАФ: ВКЛ (FPS+)"
        cartographBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        cartographBtn.BorderColor3 = Color3.fromRGB(50, 255, 50)
        cartographGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 200, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 0)),
        })
    end
end)

local eggListBtn = Instance.new("TextButton")
eggListBtn.Size = UDim2.new(0.94, 0, 0, 50)
eggListBtn.Position = UDim2.new(0.03, 0, 0, 310)
eggListBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
eggListBtn.BackgroundTransparency = 0.15
eggListBtn.Text = "📋  EGG LIST"
eggListBtn.TextColor3 = Color3.fromRGB(200, 240, 255)
eggListBtn.TextScaled = true
eggListBtn.Font = Enum.Font.GothamBold
eggListBtn.BorderSizePixel = 2
eggListBtn.BorderColor3 = Color3.fromRGB(0, 200, 255)
eggListBtn.Parent = mainPage

local eggListCorner = Instance.new("UICorner")
eggListCorner.CornerRadius = UDim.new(0, 12)
eggListCorner.Parent = eggListBtn

local eggListGrad = Instance.new("UIGradient")
eggListGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 150)),
})
eggListGrad.Rotation = 45
eggListGrad.Parent = eggListBtn

local panicBtn = Instance.new("TextButton")
panicBtn.Size = UDim2.new(0.94, 0, 0, 45)
panicBtn.Position = UDim2.new(0.03, 0, 0, 370)
panicBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
panicBtn.BackgroundTransparency = 0.1
panicBtn.Text = "🛑  ВЫКЛЮЧИТЬ ВСЁ"
panicBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
panicBtn.TextScaled = true
panicBtn.Font = Enum.Font.GothamBold
panicBtn.BorderSizePixel = 2
panicBtn.BorderColor3 = Color3.fromRGB(255, 50, 50)
panicBtn.Parent = mainPage

local panicCorner = Instance.new("UICorner")
panicCorner.CornerRadius = UDim.new(0, 12)
panicCorner.Parent = panicBtn

local panicGrad = Instance.new("UIGradient")
panicGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0)),
})
panicGrad.Rotation = 90
panicGrad.Parent = panicBtn

panicBtn.MouseButton1Click:Connect(function()
    fullyDisabled = true
    espEnabled = false
    notifiedEggs = {}
    pcall(removeAll)
    if cartographEnabled then
        pcall(disableCartograph)
    end
    if screenGui then screenGui:Destroy() end
    print("[ROCKET] СКРИПТ ПОЛНОСТЬЮ ВЫКЛЮЧЕН")
end)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 16)
hint.Position = UDim2.new(0, 0, 1, -22)
hint.BackgroundTransparency = 1
hint.Text = "ПРАВЫЙ SHIFT — открыть/закрыть"
hint.TextColor3 = Color3.fromRGB(100, 140, 200)
hint.TextScaled = true
hint.Font = Enum.Font.Gotham
hint.TextTransparency = 0.4
hint.Parent = mainPage

local eggListPage = Instance.new("Frame")
eggListPage.Name = "EggListPage"
eggListPage.Size = UDim2.new(1, 0, 1, 0)
eggListPage.BackgroundTransparency = 1
eggListPage.Visible = false
eggListPage.Parent = mainFrame

local elTitle = Instance.new("TextLabel")
elTitle.Size = UDim2.new(1, -120, 0, 35)
elTitle.Position = UDim2.new(0, 60, 0, 8)
elTitle.BackgroundTransparency = 1
elTitle.Text = "📋  EGG LIST"
elTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
elTitle.TextScaled = true
elTitle.Font = Enum.Font.GothamBold
elTitle.TextStrokeColor3 = Color3.fromRGB(0, 200, 255)
elTitle.TextStrokeTransparency = 0.3
elTitle.Parent = eggListPage

local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0, 50, 0, 30)
backBtn.Position = UDim2.new(0, 5, 0, 10)
backBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
backBtn.BackgroundTransparency = 0.15
backBtn.Text = "←"
backBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
backBtn.TextScaled = true
backBtn.Font = Enum.Font.GothamBold
backBtn.BorderSizePixel = 2
backBtn.BorderColor3 = Color3.fromRGB(255, 80, 80)
backBtn.Parent = eggListPage

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 8)
backCorner.Parent = backBtn

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 50, 0, 30)
refreshBtn.Position = UDim2.new(1, -55, 0, 10)
refreshBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 150)
refreshBtn.BackgroundTransparency = 0.15
refreshBtn.Text = "🔄"
refreshBtn.TextColor3 = Color3.fromRGB(150, 220, 255)
refreshBtn.TextScaled = true
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BorderSizePixel = 2
refreshBtn.BorderColor3 = Color3.fromRGB(0, 180, 255)
refreshBtn.Parent = eggListPage

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = refreshBtn

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -30, 0, 24)
countLabel.Position = UDim2.new(0, 15, 0, 48)
countLabel.BackgroundTransparency = 1
countLabel.Text = "🥚 Найдено: 0"
countLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
countLabel.TextScaled = true
countLabel.Font = Enum.Font.GothamBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = eggListPage

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -30, 1, -90)
scroll.Position = UDim2.new(0, 15, 0, 78)
scroll.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
scroll.BackgroundTransparency = 0.3
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = eggListPage

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 10)
scrollCorner.Parent = scroll

local eggRows = {}

local function updateEggList()
    local eggs = getEggListData()
    countLabel.Text = "🥚 Найдено: " .. #eggs
    local maxItems = math.min(#eggs, 50)

    task.spawn(function()
        for i = 1, maxItems do
            local egg = eggs[i]
            if not eggRows[i] then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.Position = UDim2.new(0, 0, 0, (i - 1) * 42 + 4)
                row.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
                row.BackgroundTransparency = 0.2
                row.BorderSizePixel = 0
                row.Parent = scroll

                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = UDim.new(0, 8)
                rowCorner.Parent = row

                local strip = Instance.new("Frame")
                strip.Size = UDim2.new(0, 4, 1, 0)
                strip.BorderSizePixel = 0
                strip.Parent = row

                local stripCorner = Instance.new("UICorner")
                stripCorner.CornerRadius = UDim.new(0, 8)
                stripCorner.Parent = strip

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.55, -20, 1, 0)
                nameLabel.Position = UDim2.new(0, 12, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextScaled = true
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = row

                local rarityLabel = Instance.new("TextLabel")
                rarityLabel.Size = UDim2.new(0.45, -10, 1, 0)
                rarityLabel.Position = UDim2.new(0.55, 0, 0, 0)
                rarityLabel.BackgroundTransparency = 1
                rarityLabel.TextScaled = true
                rarityLabel.Font = Enum.Font.Gotham
                rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
                rarityLabel.Parent = row

                eggRows[i] = {row = row, strip = strip, name = nameLabel, rarity = rarityLabel}
            end

            local r = eggRows[i]
            r.strip.BackgroundColor3 = egg.color
            r.name.Text = egg.name
            r.name.TextColor3 = egg.color
            r.rarity.Text = egg.rarity .. " • " .. math.floor(egg.distance) .. " studs"
            r.rarity.TextColor3 = egg.color
            r.row.Position = UDim2.new(0, 0, 0, (i - 1) * 42 + 4)
            r.row.Visible = true

            if i % 3 == 0 then
                task.wait()
            end
        end

        for i = maxItems + 1, #eggRows do
            if eggRows[i] and eggRows[i].row then
                eggRows[i].row.Visible = false
            end
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, maxItems * 42 + 10)
    end)
end

eggListBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    eggListPage.Visible = true
    updateEggList()
end)

backBtn.MouseButton1Click:Connect(function()
    eggListPage.Visible = false
    mainPage.Visible = true
end)

refreshBtn.MouseButton1Click:Connect(function()
    updateEggList()
end)

local function openHUD()
    if hudOpen or fullyDisabled then return end
    hudOpen = true
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 480, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -240, 0.5, 0)
    mainFrame.BackgroundTransparency = 1
    innerBg.BackgroundTransparency = 1
    glowFrame.BackgroundTransparency = 1

    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 480, 0, 520),
        Position = UDim2.new(0.5, -240, 0.5, -260),
        BackgroundTransparency = 0.1,
    }):Play()
    TweenService:Create(innerBg, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(glowFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0.2}):Play()
end

local function closeHUD()
    if not hudOpen then return end
    hudOpen = false
    local t = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 480, 0, 0),
        Position = UDim2.new(0.5, -240, 0.5, 0),
        BackgroundTransparency = 1,
    })
    t:Play()
    TweenService:Create(innerBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(glowFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    t.Completed:Connect(function()
        if not hudOpen then mainFrame.Visible = false end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if fullyDisabled then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if hudOpen then closeHUD() else openHUD() end
    end
end)

-- ============ ЗАПУСК ============
print("[ROCKET] Egg ESP v24 загружен")
print("[ROCKET] Скорость ТП: 700")
print("[ROCKET] Уведомления: через DescendantAdded (без фризов)")
print("[ROCKET] ПРАВЫЙ SHIFT — открыть/закрыть")
