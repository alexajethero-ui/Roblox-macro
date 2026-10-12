local RECIPES = {}

do
    local function rowsFor(tabName)
        FishShop:SetAttribute("FishingRefreshNonce", (FishShop:GetAttribute("FishingRefreshNonce") or 0) + 1)
        task.wait(0.3)
        BoatsShop:SetAttribute("BoatRefreshNonce", (BoatsShop:GetAttribute("BoatRefreshNonce") or 0) + 1)
        task.wait(0.2)
        local fcu = FishShop:FindFirstChild("FrameCurrent")
        local tab = fcu and childNamed(fcu, tabName)
        local scroll = tab and tab:FindFirstChildWhichIsA("ScrollingFrame")
        if not scroll then
            return {}
        end
        local out = {}
        for _, row in scroll:GetChildren() do
            if row:IsA("GuiObject") and row:GetAttribute("FishingGenerated") then
                table.insert(out, row)
            end
        end
        return out
    end

    for _, row in rowsFor("Rods") do
        table.insert(ROD_NAMES, row.Name)
    end

    local list = BoatsShop:FindFirstChild("List")
    if list then
        for _, row in list:GetChildren() do
            if row:IsA("GuiObject") and row.Name:sub(1, 5) == "Boat_" then
                table.insert(BOAT_NAMES, row.Name:sub(6))
            end
        end
    end

    -- resep + bahan yang dibutuhkan (semua bahan di game ini berupa ikan)
    for _, row in rowsFor("Crafts") do
        local reqs = {}
        for _, d in row:GetDescendants() do
            if d:IsA("Frame") then
                local fishName = d:GetAttribute("FishName")
                local amtNode = d:FindFirstChild("Amount")
                if fishName and amtNode then
                    local digits = (amtNode.Text or ""):gsub("[^%d]", "")
                    local n = tonumber(digits)
                    if n and n > 0 then
                        table.insert(reqs, { fish = fishName, amount = n })
                    end
                end
            end
        end
        table.insert(RECIPES, {
            key = row.Name,
            title = row.Name,
            crateId = row:GetAttribute("CrateId"),
            reqs = reqs,
        })
    end
end

if #ROD_NAMES == 1 then
    local rods = ReplicatedStorage:WaitForChild("Fishing"):FindFirstChild("equippedRods")
    if rods then
        for _, r in rods:GetChildren() do
            table.insert(ROD_NAMES, r.Name)
        end
    end
end
if #BOAT_NAMES == 1 then
    local ob = FishingData:FindFirstChild("OwnedBoats")
    if ob then
        for _, b in ob:GetChildren() do
            table.insert(BOAT_NAMES, b.Name)
        end
    end
end
table.sort(RECIPES, function(a, b)
    return a.key < b.key
end)
    
 
-----------------------------------------
-- SIDEBAR SECTION 1: FISHING
-----------------------------------------
local secFishing = Window:Section({ Title = "Fishing" })

local tabAuto = secFishing:Tab({
    Title = "Auto Fish",
    Desc = "Otomatis cast, luck, dan minigame",
    Icon = "solar:check-square-bold",
    IconColor = Green,
    IconShape = "Square",
    Border = true,
})

tabAuto:Section({
    Title = "Auto Cast",
    Desc = "Melempar joran otomatis mencari air",
    Box = true,
    BoxBorder = true,
    Opened = true,
}):Toggle({
    Flag = "AutoCast",
    Title = "Auto Cast",
    
    Value = CFG.AutoCast,
    Callback = function(v)
        CFG.AutoCast = v
    end,
})

tabAuto:Space()

tabAuto:Section({ Title = "Perfect Luck", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "PerfectLuck",
    Title = "Perfect Luck",
    Desc = "Lepas di puncak bar (HoldStart + 1/Speed)",
    
    Value = CFG.PerfectLuck,
    Callback = function(v)
        CFG.PerfectLuck = v
    end,
})

tabAuto:Space()

tabAuto:Section({ Title = "Auto Minigame", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "AutoMinigame",
    Title = "Auto Minigame",
    Desc = "Klik target ikan otomatis",
    
    Value = CFG.AutoMinigame,
    Callback = function(v)
        CFG.AutoMinigame = v
    end,
})

tabAuto:Space()

tabAuto:Section({ Title = "Tampilan", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "HideUI",
    Title = "Sembunyikan UI Fishing",
    Desc = "Hilangkan bar luck + preview tangkapan",
    
    Value = CFG.HideUI,
    Callback = function(v)
        CFG.HideUI = v
    end,
})

local tabTiming = secFishing:Tab({
    Title = "Timing",
    Desc = "Kecepatan loop dan jeda",
    Icon = "solar:square-transfer-horizontal-bold",
    IconColor = Blue,
    IconShape = "Square",
    Border = true,
})

tabTiming:Section({ Title = "Recast Delay", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "RecastDelay",
    Title = "Recast Delay",
    Desc = "Jeda antar lemparan (detik)",
    Step = 0.5,
    Value = { Min = 1, Max = 12, Default = CFG.RecastDelay },
    Callback = function(v)
        CFG.RecastDelay = v
    end,
})

tabTiming:Space()

tabTiming:Section({ Title = "Hit Delay", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "HitDelay",
    Title = "Hit Delay",
    Desc = "Jeda setelah target muncul (detik)",
    Step = 0.01,
    Value = { Min = 0, Max = 0.5, Default = CFG.HitDelay },
    Callback = function(v)
        CFG.HitDelay = v
    end,
})

tabTiming:Space()

tabTiming:Button({
    Title = "Reset Timing ke Default",
    
    Color = Yellow,
    Callback = function()
        CFG.RecastDelay = 3.0
        CFG.HitDelay = 0.05
        setStatus("Timing direset ke default", true)
    end,
})

-----------------------------------------
-- SIDEBAR SECTION 2: MARKET
-----------------------------------------
local secMarket = Window:Section({ Title = "Market" })

local tabSell = secMarket:Tab({
    Title = "Sell Fish",
    Desc = "Jual otomatis, opsional teleport ke market",
    Icon = "solar:file-text-bold",
    IconColor = Green,
    IconShape = "Square",
    Border = true,
})

tabSell:Section({ Title = "Auto Sell", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "AutoSell",
    Title = "Auto Sell Fish",
    Desc = "Jual ikan saat jumlahnya mencapai batas per jenis",
    
    Value = CFG.AutoSell,
    Callback = function(v)
        CFG.AutoSell = v
    end,
})

tabSell:Space()

tabSell:Section({ Title = "Batas Jual", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "SellThreshold",
    Title = "Batas per Jenis",
    Desc = "Kalau jumlah ikan satu jenis mencapai angka ini, jual SEMUA ikannya",
    Step = 10,
    Value = { Min = 10, Max = 2000, Default = CFG.SellThreshold },
    Callback = function(v)
        CFG.SellThreshold = math.max(1, math.floor(v or 100))
    end,
})

tabSell:Space()

tabSell:Section({ Title = "Teleport", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "SellTeleport",
    Title = "Teleport ke Market",
    Desc = "Pindah ke MerchantShop, jual, lalu balik ke spot mancing",
    
    Value = CFG.SellTeleport,
    Callback = function(v)
        CFG.SellTeleport = v
    end,
})

tabSell:Space()

tabSell:Button({
    Title = "Jual Sekarang",
    Desc = "Jual ikan yang ada di tas saat ini",
Color = Green,
    Callback = function()
        pcall(autoSellOnce, true)
    end,
})

local tabBuy = secMarket:Tab({
    Title = "Buy",
    Desc = "Beli rod dan boat otomatis",
    Icon = "solar:folder-with-files-bold",
    IconColor = Purple,
    IconShape = "Square",
    Border = true,
})

tabBuy:Section({ Title = "Rods", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "AutoBuyRods",
    Title = "Auto Buy Rods",
    Desc = "Beli rod yang dipilih, atau semua (termurah dulu)",
    
    Value = CFG.AutoBuyRods,
    Callback = function(v)
        CFG.AutoBuyRods = v
    end,
})

tabBuy:Space()

tabBuy:Section({ Title = "Pilih Rod", Box = true, BoxBorder = true, Opened = true }):Dropdown({
    Flag = "RodPick",
    Title = "Rod",
    Desc = "All = beli semua yang belum dimiliki",
    Values = ROD_NAMES,
    Value = ROD_NAMES[1],
    Callback = function(v)
        CFG.RodPick = v
        setStatus("Rod target = " .. tostring(v))
    end,
})

tabBuy:Space()

tabBuy:Section({ Title = "", Box = true, BoxBorder = true, Opened = true }):Input({
    Flag = "RodMaxPrice",
    Title = "Rod Max Price",
    Desc = "Batas harga (0 = tanpa batas)",
    Value = tostring(CFG.RodMaxPrice),
    Placeholder = "0 = all",
    
    Callback = function(v)
        CFG.RodMaxPrice = math.max(0, math.floor(tonumber(v) or 0))
    end,
})

tabBuy:Space()

tabBuy:Section({ Title = "Boats", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "AutoBuyBoats",
    Title = "Auto Buy Boats",
    Desc = "Butuh Run to Boat Shop saat Teleport aktif",
    
    Value = CFG.AutoBuyBoats,
    Callback = function(v)
        CFG.AutoBuyBoats = v
    end,
})

tabBuy:Space()

tabBuy:Section({ Title = "Pilih Boat", Box = true, BoxBorder = true, Opened = true }):Dropdown({
    Flag = "BoatPick",
    Title = "Boat",
    Desc = "All = beli semua yang belum dimiliki",
    Values = BOAT_NAMES,
    Value = BOAT_NAMES[1],
    Callback = function(v)
        CFG.BoatPick = v
        setStatus("Boat target = " .. tostring(v))
    end,
})

tabBuy:Space()

tabBuy:Section({ Title = "", Box = true, BoxBorder = true, Opened = true }):Input({
    Flag = "BoatMaxPrice",
    Title = "Boat Max Price",
    Desc = "Batas harga (0 = tanpa batas)",
    Value = tostring(CFG.BoatMaxPrice),
    Placeholder = "0 = all",
    
    Callback = function(v)
        CFG.BoatMaxPrice = math.max(0, math.floor(tonumber(v) or 0))
    end,
})

tabBuy:Space()

tabBuy:Button({
    Title = "Beli Sekarang",
    
    Color = Purple,
    Callback = function()
        pcall(autoBuyRods)
        pcall(autoBuyBoats)
    end,
})

-----------------------------------------
-- TAB: CRAFT
-----------------------------------------
local CRAFT_VALUES = {}
for _, r in RECIPES do
    table.insert(CRAFT_VALUES, r.title)
end
if #CRAFT_VALUES == 0 then
    table.insert(CRAFT_VALUES, "Belum ada resep")
end

local tabCraft = secMarket:Tab({
    Title = "Craft",
    Desc = "Craft crate dan unit otomatis",
    Icon = "solar:home-2-bold",
    IconColor = Yellow,
    IconShape = "Square",
    Border = true,
})

tabCraft:Section({ Title = "Auto Craft", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "AutoCraft",
    Title = "Auto Craft",
    Desc = "Craft berulang saat bahannya cukup",
    Value = CFG.AutoCraft,
    Callback = function(v)
        CFG.AutoCraft = v
    end,
})

tabCraft:Space()

tabCraft:Section({ Title = "Pilih Resep", Box = true, BoxBorder = true, Opened = true }):Dropdown({
    Flag = "CraftList",
    Title = "Resep",
    Desc = "Pilih satu atau lebih resep",
    Values = CRAFT_VALUES,
    Multi = true,
    Value = CFG.CraftList,
    Callback = function(v)
        local picked = {}
        if type(v) == "table" then
            for _, name in ipairs(v) do
                table.insert(picked, name)
            end
        elseif type(v) == "string" then
            table.insert(picked, v)
        end
        CFG.CraftList = picked
        local txt = #picked > 0 and table.concat(picked, ", ") or "tidak ada"
        setStatus("Resep dipilih: " .. txt)
    end,
})

tabCraft:Space()

tabCraft:Section({ Title = "Jeda", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "CraftDelay",
    Title = "Jeda Craft",
    Desc = "Jeda antar craft (detik)",
    Step = 0.5,
    Value = { Min = 0.5, Max = 10, Default = CFG.CraftDelay },
    Callback = function(v)
        CFG.CraftDelay = v
    end,
})

tabCraft:Space()

tabCraft:Button({
    Title = "Craft Sekarang",
    Desc = "Craft satu kali untuk resep yang dipilih",
    Color = Yellow,
    Callback = function()
        pcall(autoCraftOnce, true)
    end,
})

tabCraft:Space()

craftEl = tabCraft:Paragraph({
    Title = "Status Bahan",
    Desc = "Belum ada data",
})

-
tabCraft:Space()

tabCraft:Button({
    Title = "Craft Sekarang",
    Desc = "Craft satu kali untuk resep yang dipilih",
    Color = Yellow,
    Callback = function()
        pcall(autoCraftOnce, true)
    end,
})

tabCraft:Space()

craftEl = tabCraft:Paragraph({
    Title = "Status Bahan",
    Desc = "Belum ada data",
})
-----------------------------------------
-- SIDEBAR SECTION 3: BOSS
-----------------------------------------
local secBoss = Window:Section({ Title = "Boss Fish" })

local tabBoss = secBoss:Tab({
    Title = "Boss Zone",
    Desc = "Pindah ke zona spawn boss, melayang di atas air",
    Icon = "solar:info-square-bold",
    IconColor = Red,
    IconShape = "Square",
    Border = true,
})

tabBoss:Section({ Title = "Auto", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "BossAutoGo",
    Title = "Auto Go ke Zona Boss",
    Desc = "Berpindah saat notifikasi boss muncul",
    
    Value = CFG.BossAutoGo,
    Callback = function(v)
        CFG.BossAutoGo = v
    end,
})

tabBoss:Space()

tabBoss:Section({ Title = "Melayang (Hindari Air)", Box = true, BoxBorder = true, Opened = true }):Toggle({
    Flag = "BossLock",
    Title = "Kunci Melayang",
    Desc = "Jaga karakter melayang, tidak jatuh ke air",
    
    Value = CFG.BossLock,
    Callback = function(v)
        CFG.BossLock = v
    end,
})

tabBoss:Space()

tabBoss:Section({ Title = "", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "BossHover",
    Title = "Tinggi Melayang",
    Desc = "Stud di atas air (permukaan air = y16)",
    Step = 1,
    Value = { Min = 2, Max = 40, Default = CFG.BossHover },
    Callback = function(v)
        CFG.BossHover = v
    end,
})

tabBoss:Space()

tabBoss:Section({ Title = "Titik Spawn", Box = true, BoxBorder = true, Opened = true }):Slider({
    Flag = "BossSpot",
    Title = "Boss Spot",
    Desc = "0 = otomatis pilih yang paling dekat pemain lain",
    Step = 1,
    Value = { Min = 0, Max = 4, Default = CFG.BossSpot },
    Callback = function(v)
        CFG.BossSpot = v
    end,
})

tabBoss:Space()

tabBoss:Button({
    Title = "Pergi ke Zona Boss Sekarang",
    Desc = "Teleport + melayang di atas air",
    
    Color = Red,
    Callback = function()
        pcall(startBossRun, true)
    end,
})

tabBoss:Space()

tabBoss:Button({
    Title = "Kembali ke Spot Asal",
    
    Color = Yellow,
    Callback = function()
        pcall(endBossRun, true)
    end,
})

tabBoss:Space()

bossEl = tabBoss:Paragraph({
    Title = "Status Boss",
    Desc = "Menunggu notifikasi...",
    
})
-----------------------------------------
-- SIDEBAR SECTION 4: INFO
-----------------------------------------
local secInfo = Window:Section({ Title = "Info" })

local tabStatus = secInfo:Tab({
    Title = "Status",
    Desc = "Status hidup + kontrol manual",
    Icon = "solar:home-2-bold",
    IconColor = Grey,
    IconShape = "Square",
    Border = true,
})

statusEl = tabStatus:Paragraph({
    Title = "Status",
    Desc = "Ready",
    
})

tabStatus:Space()

walletEl = tabStatus:Paragraph({
    Title = "Dompet",
    Desc = "Koin: 0",
    
})

tabStatus:Space()

tabStatus:Section({ Title = "Kontrol Manual", Box = true, BoxBorder = true, Opened = true }):Button({
    Title = "Pergi ke Fish Market",
    
    Callback = function()
        pcall(goToMarket)
    end,
})

tabStatus:Space()

tabStatus:Button({
    Title = "Kembali ke Spot Mancing",
    
    Callback = function()
        pcall(goBack)
    end,
})

tabStatus:Space()

tabStatus:Button({
    Title = "Hentikan & Hapus UI",
    
    Color = Red,
    Callback = function()
        if type(ENV.AutoFishStop) == "function" then
            ENV.AutoFishStop()
        end
    end,
})

-----------------------------------------
-- STATE + AUTO CAST
-----------------------------------------
local stateThreads = {}

local function clearStateThreads()
    for _, t in ipairs(stateThreads) do
        pcall(task.cancel, t)
    end
    table.clear(stateThreads)
end

local function later(delay, fn)
    local t = task.delay(delay, fn)
    table.insert(stateThreads, t)
    return t
end

local CAST_ANGLES = { 0, -15, 15, -30, 30, -45, 45, -60, 60, -75, 75, -90, 90, 120, -120, 150, -150, 180 }
local CAST_DISTANCES = { 30, 40, 55, 70, 90, 110 }

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { Workspace.Terrain }
rayParams.IgnoreWater = false

local function findWaterPoint()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local look = hrp.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    local unit = (flat.Magnitude < 0.01 and Vector3.new(0, 0, -1) or flat).Unit

    for _, ang in ipairs(CAST_ANGLES) do
        local dir = CFrame.Angles(0, math.rad(ang), 0):VectorToWorldSpace(unit)
        for _, dist in ipairs(CAST_DISTANCES) do
            local origin = hrp.Position + dir * dist + Vector3.new(0, 60, 0)
            local hit = Workspace:Raycast(origin, Vector3.new(0, -120, 0), rayParams)
            if hit and hit.Material == Enum.Material.Water then
                return hit.Position
            end
        end
  end
  return nil
end

local function autoCast()
    if not CFG.AutoCast or busy or state ~= "Idle" then
        return
    end
    if InFishingZone and InFishingZone.Value == false then
        return
    end

    local pos = findWaterPoint()
    if not pos then
        return -- tidak ada air, jangan kirim cast palsu
    end

    state = "Casting"
    FishingEvent:FireServer("Cast", { Position = pos })

    later(4, function()
        if state == "Casting" then
            state = "Idle"
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(math.max(0.5, CFG.RecastDelay or 3))
        if CFG.AutoCast and state == "Idle" then
            autoCast()
        end
    end
end)

-----------------------------------------
-- EVENT SERVER
-----------------------------------------
local eventConn = FishingEvent.OnClientEvent:Connect(function(action, data)
    data = data or {}

    if action == "CastStarted" then
        state = "Luck"

        if CFG.PerfectLuck and data.Luck and data.Luck.StartTime then
            local holdAt = data.Luck.StartTime
            task.spawn(function()
                local d = holdAt - workspace:GetServerTimeNow()
                if d > 0 then
                    task.wait(d)
                end
                if state ~= "Luck" then
                    return
                end
                FishingEvent:FireServer("LuckHold", { ClickTime = workspace:GetServerTimeNow() })
            end)
        end

    elseif action == "LuckHeld" then
        if CFG.PerfectLuck and data.HoldStart and data.Speed and data.Speed > 0 then
            local perfectTime = data.HoldStart + (1 / data.Speed)
            task.spawn(function()
                local d = perfectTime - workspace:GetServerTimeNow()
                if d > 0 then
                    task.wait(d)
                end
                FishingEvent:FireServer("LuckRelease", { ClickTime = perfectTime })
            end)
        end

    elseif action == "LuckLocked" then
        state = "Waiting"

    elseif action == "Target" then
        state = "Minigame"

        if CFG.AutoMinigame and data.StartTime and data.Index then
            local index = data.Index
            local startTime = data.StartTime
            task.spawn(function()
                local d = math.max(0, startTime - workspace:GetServerTimeNow()) + (CFG.HitDelay or 0.05)
                if d > 0 then
                    task.wait(d)
                end
                if state ~= "Minigame" then
                    return
                end
                FishingEvent:FireServer("Hit", { Index = index })
            end)
        end

    elseif action == "StageHit" then
        state = "Transition"

    elseif action == "Reset" then
        state = "Idle"
        later(0.5, autoCast)

    elseif action == "Catch" then
        state = "Catching"
        later(2.5, function()
            state = "Idle"
            autoCast()
        end)
        later(3.2, function()
            pcall(autoSellOnce, true)
        end)
    end
end)

-----------------------------------------
-- SHOP + TELEPORT
-----------------------------------------
local function atPath(root, ...)
    local node = root
    for _, name in { ... } do
        node = childNamed(node, name)
        if not node then
            return nil
        end
    end
    return node
end

local function parseAmount(text)
    if type(text) ~= "string" then
        return nil
    end
    local cleaned = text:gsub("[,%s]", "")
    if not cleaned:match("^%-?%d+%.?%d*$") then
        return nil
    end
    return tonumber(cleaned)
end

local function forceShopRefresh()
    FishShop:SetAttribute("FishingRefreshNonce", (FishShop:GetAttribute("FishingRefreshNonce") or 0) + 1)
end

local function forceBoatRefresh()
    BoatsShop:SetAttribute("BoatRefreshNonce", (BoatsShop:GetAttribute("BoatRefreshNonce") or 0) + 1)
end

local shopBusy = false
local shopToken = nil

local function callShop(action, payload)
    if shopBusy then
        return false
    end
    shopBusy = true
    local token = {}
    shopToken = token
    task.delay(6, function()
        if shopToken == token then
            shopBusy = false
            shopToken = nil
        end
    end)
    local ok = pcall(function()
        return FishingFunction:InvokeServer(action, payload)
    end)
    if shopToken == token then
        shopBusy = false
        shopToken = nil
    end
    return ok == true
end

local function coins()
    return FishingCoins.Value
end

local function shopMarker(modelName)
    local folder = Workspace:FindFirstChild("Fishing")
    local model = folder and childNamed(folder, modelName)
    if not model then
        return nil
    end
    for _, d in model:GetDescendants() do
        if d:IsA("Part") and d.Shape == Enum.PartType.Cylinder then
            return d.Position
        end
    end
    return model:GetBoundingBox().Position
end

local function teleportTo(target)
    if typeof(target) ~= "Vector3" then
        return false
    end
    local char = LocalPlayer.Character
    if not char then
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Sit = false
    end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("AlignPosition") then
            pcall(function()
                obj:Destroy()
            end)
        end
    end

    local targetCF = CFrame.new(target)
    local seat = char:FindFirstChildOfClass("HumanoidSeatPart")
    if seat and seat.Parent and seat.Parent ~= char then
        pcall(function()
            seat.Parent:PivotTo(targetCF)
        end)
    end
    pcall(function()
        char:PivotTo(targetCF)
    end)

    for i = 1, 3 do
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = targetCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if i < 3 then
            task.wait(0.12)
        end
    end
    return true
end

local function currentPosition()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    local seat = char:FindFirstChildOfClass("HumanoidSeatPart")
    if seat and seat.Parent and seat.Parent ~= char then
        local ok, cf = pcall(function()
            return seat.Parent:GetPivot()
        end)
        if ok and cf then
            return cf.Position
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or nil
end

local marketCache = nil
local boatShopCache = nil
local lastSpot = nil

local function probeShopPoint(markerPos, shopFrame, cache)
    if cache then
        return cache
    end
    if not markerPos then
        return nil
    end
    local found = nil
    for _, radius in ipairs({ 0, 8, 16 }) do
        local steps = (radius == 0) and 1 or 8
        for i = 0, steps - 1 do
            local ang = (i / steps) * math.pi * 2
            local p = markerPos + Vector3.new(math.cos(ang) * radius, 3, math.sin(ang) * radius)
            if teleportTo(p) then
                local deadline = os.clock() + 0.5
                while os.clock() < deadline do
                    if shopFrame.Visible then
                        found = p
                        break
                    end
                    task.wait(0.1)
                end
            end
            if found then
                break
            end
        end
        if found then
            break
        end
    end
    return found or markerPos
end

goToMarket = function()
    if busy then
        return
    end
    local here = currentPosition()
    if here then
        lastSpot = here
    end
    busy = true
    setStatus("Teleport ke fish market...")
    marketCache = probeShopPoint(shopMarker("MerchantShop"), FishShop, marketCache)
    if marketCache then
        teleportTo(marketCache)
    end
    task.wait(0.6)
    busy = false
end

goBack = function()
    if busy or not lastSpot then
        return
    end
    busy = true
    setStatus("Kembali ke spot mancing")
    teleportTo(lastSpot)
    busy = false
    state = "Idle"
end

autoSellOnce = function(force)
    if not CFG.AutoSell or busy or bossMode then
        return
    end
    if CFG.SellTeleport and not force and state ~= "Idle" then
        return
    end

    local keep = math.max(1, math.floor(CFG.SellThreshold or 100))
    local pending = 0
    for _, child in Fish:GetChildren() do
        if math.floor(child.Value or 0) >= keep then
            pending = pending + 1
        end
    end
    if pending == 0 then
        return
    end

    local origin = nil
    if CFG.SellTeleport then
        origin = currentPosition()
        if not origin then
            return
        end
        busy = true
        marketCache = probeShopPoint(shopMarker("MerchantShop"), FishShop, marketCache)
        if marketCache then
            teleportTo(marketCache)
        end
        task.wait(0.8)
    end

    local sold = {}
    local totalFish = 0
    for _, child in Fish:GetChildren() do
        local have = math.floor(child.Value or 0)
        if have >= keep then
            -- batas tercapai: jual SEMUA ikannya, bukan hanya sisanya
            local ok = callShop("SellFish", { Fish = child.Name, Amount = have })
            if ok then
                table.insert(sold, child.Name .. " x" .. have)
                totalFish = totalFish + have
                task.wait(0.25)
            end
        end
    end

    if CFG.AutoBuyRods then
        pcall(autoBuyRods)
    end

    if CFG.AutoBuyBoats then
        boatShopCache = probeShopPoint(shopMarker("BoatShop"), BoatsShop, boatShopCache)
        if boatShopCache then
            teleportTo(boatShopCache)
        end
        task.wait(0.5)
        pcall(autoBuyBoats)
    end

    if #sold > 0 then
        setStatus("Sold " .. totalFish .. " fish: " .. table.concat(sold, ", "), true)
    end

    if origin then
        task.wait(0.4)
        teleportTo(origin)
        busy = false
    end
    state = "Idle"
end

local recentBuy = {}
local buyCooldown = { rods = 0, boats = 0 }

local function collectRods()
    forceShopRefresh()
    local out = {}
    local frameCurrent = FishShop:FindFirstChild("FrameCurrent")
    local rodsFrame = frameCurrent and childNamed(frameCurrent, "Rods")
    local scroll = rodsFrame and rodsFrame:FindFirstChildWhichIsA("ScrollingFrame")
    if not scroll then
        return out
    end
    for _, row in scroll:GetChildren() do
        if row:IsA("GuiObject") and row:GetAttribute("FishingGenerated") then
            local price = nil
            local title = atPath(row, "Main", "Template", "Price", "_TITLE")
            if title then
                price = parseAmount(title.Text)
            end
            if not price then
                local alt = atPath(row, "Main", "Template", "BuyFrame", "Move", "Price", "Amount")
                price = alt and parseAmount(alt.Text) or nil
            end
            local ownedNode = OwnedRods:FindFirstChild(row.Name)
            table.insert(out, {
                name = row.Name,
                price = price,
                owned = (ownedNode and ownedNode.Value == true) or false,
            })
        end
    end
    return out
end
local function collectBoats()
    forceBoatRefresh()
    local out = {}
    local list = BoatsShop:FindFirstChild("List")
    if not list then
        return out
    end
    for _, row in list:GetChildren() do
        if row:IsA("GuiObject") and row.Name:sub(1, 5) == "Boat_" then
            local boatName = row.Name:sub(6)
            local main = childNamed(row, "main")
            local priceNode = main and atPath(main, "Buy", "Price", "_TITLE")
            local ownedNode = OwnedBoats:FindFirstChild(boatName)
            table.insert(out, {
                name = boatName,
                price = priceNode and parseAmount(priceNode.Text) or nil,
                owned = (ownedNode and ownedNode.Value == true) or false,
            })
        end
    end
    return out
end

local function buyLoop(kind, enabled, maxPrice, collect, action, keyName, key, pick)
    if not enabled then
        return
    end
    if os.clock() < (buyCooldown[key] or 0) then
        return
    end
    local items = collect()

    -- kalau dropdown menunjuk satu item tertentu, fokus ke situ saja
    local target = pick and pick ~= "All" and pick or nil
    if target then
        local focused = {}
        for _, item in ipairs(items) do
            if item.name == target then
                table.insert(focused, item)
            end
        end
        if #focused == 0 then
            setStatus(kind .. " '" .. target .. "' tidak ada di shop")
            return
        end
        items = focused
    else
        table.sort(items, function(a, b)
            return (a.price or math.huge) < (b.price or math.huge)
        end)
    end

    local budget = maxPrice or 0
    local bought = {}

    for _, item in ipairs(items) do
        local untilTime = recentBuy[item.name]
        if untilTime and os.clock() < untilTime then
            continue
        end
        recentBuy[item.name] = nil

        if not item.owned and item.price then
            if budget <= 0 or item.price <= budget then
                if coins() >= item.price then
                    recentBuy[item.name] = os.clock() + 10
                    if callShop(action, { [keyName] = item.name }) then
                        table.insert(bought, item.name .. " ($" .. item.price .. ")")
                        task.wait(0.4)
                    end
                else
                    setStatus("Koin kurang untuk " .. item.name .. " ($" .. item.price .. ")")
                    buyCooldown[key] = os.clock() + 10
                    break
                end
            end
        end
    end

    if #bought > 0 then
        setStatus("Bought " .. kind .. ": " .. table.concat(bought, ", "), true)
    end
end

function autoBuyRods()
    buyLoop("rods", CFG.AutoBuyRods, CFG.RodMaxPrice, collectRods, "BuyOrEquipRod", "Rod", "rods", CFG.RodPick)
end

function autoBuyBoats()
    buyLoop("boats", CFG.AutoBuyBoats, CFG.BoatMaxPrice, collectBoats, "BuyOrSpawnBoat", "Boat", "boats", CFG.BoatPick)
end

-- ---------- AUTO CRAFT ----------
-- Semua bahan di game ini berupa ikan, jadi bahan bisa dicek langsung dari
-- FishingData.Fish sebelum mengirim Craft.
local function recipeReady(recipe)
    for _, req in recipe.reqs do
        local node = Fish:FindFirstChild(req.fish)
        if not node or math.floor(node.Value or 0) < req.amount then
            return false, req
        end
    end
    return true, nil
end

local function craftStatusLine()
    local lines = {}
    for _, recipe in RECIPES do
        local ready = recipeReady(recipe)
        local bits = {}
        for _, req in recipe.reqs do
            local node = Fish:FindFirstChild(req.fish)
            local have = node and math.floor(node.Value or 0) or 0
            table.insert(bits, string.format("%s %d/%d", req.fish, have, req.amount))
        end
        table.insert(lines, string.format("%s [%s] %s", recipe.title, ready and "SIAP" or "kurang", table.concat(bits, ", ")))
    end
    return table.concat(lines, "\n")
end
autoCraftOnce = function(manual)
    if not CFG.AutoCraft and not manual then
        return
    end
    if shopBusy then
        return
    end

    local picked = {}
    for _, name in ipairs(CFG.CraftList or {}) do
        for _, recipe in RECIPES do
            if recipe.title == name then
                table.insert(picked, recipe)
            end
        end
    end
    if #picked == 0 then
        return
    end

    local made = {}
    for _, recipe in ipairs(picked) do
        local ready = recipeReady(recipe)
        if ready then
            if callShop("Craft", { Recipe = recipe.key }) then
                table.insert(made, recipe.title)
                task.wait(CFG.CraftDelay or 2)
            end
        elseif manual then
            local missing = {}
            for _, req in recipe.reqs do
                local node = Fish:FindFirstChild(req.fish)
                local have = node and math.floor(node.Value or 0) or 0
                if have < req.amount then
                    table.insert(missing, string.format("%s %d/%d", req.fish, have, req.amount))
                end
            end
            setStatus(recipe.title .. " kurang: " .. table.concat(missing, ", "))
        end
    end

    if #made > 0 then
        setStatus("Craft: " .. table.concat(made, ", "), true)
    end
end

-- loop craft terpisah + refresh label bahan
task.spawn(function()
    while true do
        task.wait(1)
        setDescSafe(craftEl, craftStatusLine())
        if CFG.AutoCraft then
            pcall(autoCraftOnce)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if not CFG.SellTeleport then
            pcall(autoSellOnce)
        end
        pcall(autoBuyRods)
        pcall(autoBuyBoats)
    end
end)

task.delay(6, function()
    if CFG.AutoSell and CFG.SellTeleport and not busy and not bossMode then
        pcall(autoSellOnce)
    end
end)

-----------------------------------------
-- BOSS FISH  (dengan hover di atas air)
-----------------------------------------
-- Permukaan air di SpawnSecretPoints = y 16, marker = y 17.
-- Teleport ke y17 = masuk air = bisa mati/respawn.
-- Karena itu target diletakkan (BossHover) stud DI ATAS air, lalu dikunci
-- lewat PivotTo tiap frame supaya tidak jatuh.
local BOSS_PATTERN = "^boss%s+fish%s+ends%s+in"
local bossOrigin = nil
local bossWasActive = false

local hoverActive = false
local hoverRoot = nil
local hoverCF = nil

local function findBossLabel()
    local lobby = LocalPlayer.PlayerGui:FindFirstChild("_LobbyUI")
    if not lobby then
        return nil, nil
    end
    for _, folder in lobby:GetChildren() do
        local ge = childNamed(folder, "GlobalEvents")
        local frame = ge and childNamed(ge, "Frame")
        local fish = frame and childNamed(frame, "fish")
        if fish then
            return fish, childNamed(fish, "Title")
        end
    end
    return nil, nil
end

local function bossEventActive()
    local frame, title = findBossLabel()
    if not (frame and title) then
        return false
    end
    if not frame.Visible then
        return false
    end
    return string.lower(title.Text or ""):match(BOSS_PATTERN) ~= nil
end

local function bossZonePoint()
    local folder = Workspace:FindFirstChild("Fishing")
    local pts = folder and childNamed(folder, "SpawnSecretPoints")
    if not pts then
        return nil
    end
    local list = {}
    for _, p in pts:GetChildren() do
        if p:IsA("BasePart") then
            table.insert(list, p)
        end
    end
    if #list == 0 then
        return nil
    end

    local wanted = math.floor(CFG.BossSpot or 0)
    local target = nil

    if wanted >= 1 and wanted <= #list then
        target = list[wanted]
    else
        local boats = childNamed(folder, "PlayerBoats")
        local bestDist = math.huge
        if boats then
            for _, boat in boats:GetChildren() do
                for _, part in boat:GetDescendants() do
                    if part:IsA("BasePart") then
                        for _, p in list do
                            local d = (p.Position - part.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                target = p
                            end
                        end
                    end
                end
            end
        end
        target = target or list[1]
    end

    -- y = y air (16) + tinggi melayang -> jauh di atas permukaan air
    local hover = math.max(2, CFG.BossHover or 14)
    return Vector3.new(target.Position.X, 16 + hover, target.Position.Z)
end

local function startHover(cf)
    local char = LocalPlayer.Character
    if not char then
        return
    end
    hoverCF = cf
    local seat = char:FindFirstChildOfClass("HumanoidSeatPart")
    if seat and seat.Parent and seat.Parent ~= char then
        hoverRoot = seat.Parent
    else
        hoverRoot = char
    end
    hoverActive = CFG.BossLock ~= false
end
local function stopHover()
    hoverActive = false
    hoverRoot = nil
    hoverCF = nil
end

function startBossRun(manual)
    if busy or bossMode then
        return
    end
    local point = bossZonePoint()
    if not point then
        setStatus("SpawnSecretPoints tidak ditemukan", true)
        return
    end

    if not manual then
        bossOrigin = currentPosition()
    elseif not bossOrigin then
        bossOrigin = currentPosition()
    end

    busy = true
    setStatus("BOSS! Pergi ke zona boss (melayang y=" .. string.format("%.0f", point.Y) .. ")")

    if teleportTo(point) then
        startHover(CFrame.new(point))
        local deadline = os.clock() + 10
        while InFishingZone and InFishingZone.Value == false and os.clock() < deadline do
            task.wait(0.25)
        end
        bossMode = true
        setStatus("Zona boss - melayang, auto cast jalan", true)
    end

    busy = false
end

function endBossRun(manual)
    if not bossMode and not manual then
        return
    end
    stopHover()
    bossMode = false
    if bossOrigin then
        setStatus("Kembali dari zona boss")
        teleportTo(bossOrigin)
        bossOrigin = nil
    end
    state = "Idle"
end

task.spawn(function()
    while true do
        task.wait(1)
        local frame, title = findBossLabel()
        local ok, active = pcall(bossEventActive)
        active = ok and active == true

        if title then
            local txt = title.Text or "?"
            local shown = active and ("AKTIF - " .. txt) or txt
            setDescSafe(bossEl, shown .. (frame and frame.Visible and "" or " (disembunyikan)"))
        end

        if active ~= bossWasActive then
            bossWasActive = active
            if active then
                if CFG.BossAutoGo and not busy and not bossMode then
                    pcall(startBossRun)
                end
            elseif bossMode then
                pcall(endBossRun)
            end
        end
    end
end)

-- refresh label dompet
task.spawn(function()
    while true do
        task.wait(1)
        setDescSafe(walletEl, "Koin: " .. tostring(math.floor(coins())))
    end
end)

-----------------------------------------
-- HEARTBEAT: hover + sembunyi UI
-----------------------------------------
local heartConn = RunService.Heartbeat:Connect(function()
    if hoverActive and hoverRoot and hoverRoot.Parent and hoverCF then
        pcall(function()
            hoverRoot:PivotTo(hoverCF)
        end)
    end

    if not (CFG.PerfectLuck or CFG.AutoMinigame) or not CFG.HideUI then
        return
    end

    if FishingUI.Visible then
        FishingUI.Visible = false
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local luckBillboard = hrp:FindFirstChild("FishLuck")
        if luckBillboard then
            luckBillboard:Destroy()
        end
    end

    local caughtFish = Workspace:FindFirstChild("CaughtFishPreview")
    if caughtFish then
        caughtFish:Destroy()
    end

    local caughtCrate = Workspace:FindFirstChild("CaughtCratePreview")
    if caughtCrate then
        caughtCrate:Destroy()
    end
end)

-----------------------------------------
-- CLEANUP
-----------------------------------------
ENV.AutoFishStop = function()
    stopHover()
    bossMode = false
    pcall(function()
        eventConn:Disconnect()
    end)
    pcall(function()
        heartConn:Disconnect()
    end)
    clearStateThreads()
    if type(ENV.AutoFishWindow) == "table" and ENV.AutoFishWindow.Destroy then
        pcall(function()
            ENV.AutoFishWindow:Destroy()
        end)
    end
    ENV.AutoFishWindow = nil
end

return CFG
