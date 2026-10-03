-- =============================================================================
-- 🌟 SLOP TD MACRO RAID STARLARP - TAHAP 1: LAYAR & UI UTAMA
-- =============================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- System Safety: Pengecekan PlayerGui agar Skrip Tidak Stuck/Crash
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
if not playerGui then 
    warn("[Slop Macro]: Gagal menemukan PlayerGui. Skrip dihentikan.")
    return 
end

-- Membersihkan UI lama jika ada sisa eksekusi sebelumnya
if playerGui:FindFirstChild("TowerMacroUI_Advanced") then
    playerGui.TowerMacroUI_Advanced:Destroy()
end

-- ==========================================
-- 🏗️ PEMBUATAN ELEMENT INTERFACE (UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerMacroUI_Advanced"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Main Frame (Compact, Modern, & Bisa Digeser)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 310) -- Ukuran pas, tidak memakan tempat
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0) -- Berada di posisi kiri tengah layar
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar Frame (Bagian Judul & Navigasi)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌟 SLOP TD MACRO RAID"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -52, 0, 3)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = TopBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

-- Close Button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -27, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 13
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

-- Container Utama untuk Konten Tombol
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Fungsi Helper Pembuat Tombol Agar Ukuran & Font Konsisten
local function createButton(text, posTop, bgColor, fontStyle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, posTop)
    btn.BackgroundColor3 = bgColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = fontStyle or Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = ContentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

-- Menambahkan 6 Tombol Utama Sesuai Spesifikasi Fitur Makro Anda
local RecordBtn  = createButton("🔴 Record Macro", 10, Color3.fromRGB(50, 150, 50))
local PlayBtn    = createButton("▶️ Play Macro", 45, Color3.fromRGB(50, 100, 200), Enum.Font.SourceSansBold)
local AutoBtn    = createButton("🤖 Autoplay: OFF", 80, Color3.fromRGB(100, 40, 40), Enum.Font.SourceSansBold)
local SpeedBtn   = createButton("⚡ Speed: 1x", 115, Color3.fromRGB(100, 40, 40), Enum.Font.SourceSansBold)
local PlaceKeyBtn = createButton("🏗️ Placement Key: E", 150, Color3.fromRGB(70, 70, 70))
local SaveBtn    = createButton("💾 Save Macro", 185, Color3.fromRGB(180, 120, 30))

-- Info Board Label (Status Real-time untuk memantau Map/Raid)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 50)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 225)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.Text = "Map Terdeteksi: Menunggu...\nStatus: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = ContentFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

-- ==========================================
-- 🛠️ UI LOGIC EVENTS (MINIMIZE & CLOSE)
-- ==========================================
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 240, 0, 30)
        ContentFrame.Visible = false
        MinimizeBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 240, 0, 310)
        ContentFrame.Visible = true
        MinimizeBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("[Slop Macro]: UI berhasil ditutup.")
end)

-- Safe Auto Minimize saat skrip pertama kali dijalankan agar rapi
task.defer(function()
    task.wait(0.5)
    isMinimized = true
    MainFrame.Size = UDim2.new(0, 240, 0, 30)
    ContentFrame.Visible = false
    MinimizeBtn.Text = "+"
end)

print("[Slop Macro]: Tahap 1 (Layar & Tombol UI) berhasil dimuat!")

-- =============================================================================
-- 🌟 SLOP TD MACRO RAID - PART 2: CORE MACRO LOGIC & AUTO PLAYBACK
-- =============================================================================

-- Memastikan modul grafis UI pada file 1 di atas sudah terpasang
local MacroGuiMod = require(script.Parent.MacroGui)
local UI = MacroGuiMod.CreateUI()

if not UI then 
    warn("[Slop Logic]: Gagal menghubungkan antarmuka UI. Skrip dihentikan.")
    return 
end

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- State Status Utama Makro
local isRecording = false
local isPlaying = false
local autoPlayEnabled = false
local macroSpeed = 1
local startTime = 0
local currentRaidMap = "Menunggu..."

-- Laci Database Mandiri Terpisah untuk Setiap Map (Raid 1 - Raid 4)
local raidMacroDatabase = {
    ["Raid 1"] = {},
    ["Raid 2"] = {},
    ["Raid 3"] = {},
    ["Raid 4"] = {}
}

local PLACEMENT_KEY = Enum.KeyCode.E
local selectedTowerTemplate = "Archer"

local PlaceTowerRemote = ReplicatedStorage:FindFirstChild("PlaceTowerEvent") or Instance.new("RemoteEvent")
local UpgradeTowerRemote = ReplicatedStorage:FindFirstChild("UpgradeTowerEvent") or Instance.new("RemoteEvent")

local function getElapsedTime()
    return (os.clock() - startTime) * macroSpeed
end

local function updateStatus(text, color)
    UI.StatusLabel.Text = "Map Terdeteksi: " .. currentRaidMap .. "\nStatus: " .. text
    if color then UI.StatusLabel.TextColor3 = color end
end

local function recordAction(actionType, details)
    if not isRecording or currentRaidMap == "Menunggu..." then return end
    if not raidMacroDatabase[currentRaidMap] then return end
    
    table.insert(raidMacroDatabase[currentRaidMap], {
        Time = getElapsedTime(),
        Type = actionType,
        Details = details
    })
end

-- Logika Otomatis Pemutaran Balik Rekaman Tower
local function playMacroForCurrentMap()
    local currentData = raidMacroDatabase[currentRaidMap]
    if not currentData or #currentData == 0 then 
        updateStatus("Tidak ada data makro di slot " .. currentRaidMap, Color3.fromRGB(235, 77, 75))
        return 
    end
    if isPlaying then return end
    
    isPlaying = true
    UI.PlayBtn.Text = "⏹️ Stop Macro"
    UI.PlayBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
    updateStatus("Memutar Makro...", Color3.fromRGB(68, 189, 50))
    
    local playbackStart = os.clock()
    local index = 1
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then connection:Disconnect() return end
        
        local currentPlaybackTime = (os.clock() - playbackStart) * macroSpeed
        while index <= #currentData and currentData[index].Time <= currentPlaybackTime do
            local action = currentData[index]
            
            if action.Type == "Place" and action.Details and action.Details.Position then
                local p = action.Details.Position
                local pos = Vector3.new(p[1], p[2], p[3])
                pcall(function() PlaceTowerRemote:FireServer(action.Details.TowerName, CFrame.new(pos)) end)
            elseif action.Type == "Upgrade" then
                pcall(function() UpgradeTowerRemote:FireServer(action.Details.TowerID) end)
            end
            index = index + 1
        end
        
        if index > #currentData then
            isPlaying = false
            UI.PlayBtn.Text = "▶️ Play Macro"
            UI.PlayBtn.BackgroundColor3 = Color3.fromRGB(68, 189, 50)
            updateStatus("Selesai diputar.", Color3.fromRGB(0, 255, 150))
            connection:Disconnect()
        end
    end)
end

-- =============================================================================
-- DETEKSI OTOMATIS MAP RAID YANG DIACAK (BACKGROUND THREAD)
-- =============================================================================
task.spawn(function()
    local RaidVariable = workspace:FindFirstChild("CurrentRaidMode")
    
    local function onRaidMapChanged(newMapName)
        if not newMapName or newMapName == "" then return end
        
        if raidMacroDatabase[newMapName] then
            currentRaidMap = newMapName
            updateStatus("Siap (Menunggu Perintah)", Color3.fromRGB(0, 255, 150))
            
            if autoPlayEnabled then
                task.wait(3) 
                playMacroForCurrentMap()
            end
        else
            updateStatus("Map ("..newMapName..") bukan target Raid.", Color3.fromRGB(241, 196, 15))
        end
    end

    if RaidVariable then
        RaidVariable.Changed:Connect(onRaidMapChanged)
        onRaidMapChanged(RaidVariable.Value)
    else
        task.spawn(function()
            while not RaidVariable do
                RaidVariable = workspace:FindFirstChild("CurrentRaidMode")
                if RaidVariable then
                    RaidVariable.Changed:Connect(onRaidMapChanged)
                    onRaidMapChanged(RaidVariable.Value)
                    break
                end
                task.wait(1)
            end
        end)
    end
end)

-- Listener Keyboard E (Taruh Tower) & Klik (Upgrade)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not isRecording or currentRaidMap == "Menunggu..." then return end
    
    local mouse = LocalPlayer:GetMouse()
    if not mouse then return end

    if input.KeyCode == PLACEMENT_KEY and mouse.Hit then
        local details = {
            TowerName = selectedTowerTemplate,
            Position = {mouse.Hit.Position.X, mouse.Hit.Position.Y, mouse.Hit.Position.Z}
        }
        recordAction("Place", details)
        pcall(function() PlaceTowerRemote:FireServer(details.TowerName, mouse.Hit) end)
        updateStatus("Tower Di-Record!", Color3.fromRGB(241, 196, 15))
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
            local towerInstance = mouse.Target.Parent
            recordAction("Upgrade", {TowerID = towerInstance.Name})
            pcall(function() UpgradeTowerRemote:FireServer(towerInstance) end)
            updateStatus("Upgrade Di-Record!", Color3.fromRGB(241, 196, 15))
        end
    end
end)

-- =============================================================================
-- LOGIKA AKSI KONEKSI BUTTON UI
-- =============================================================================
UI.RecordBtn.MouseButton1Click:Connect(function()
    if currentRaidMap == "Menunggu..." then return end
    isRecording = not isRecording
    if isRecording then
        raidMacroDatabase[currentRaidMap] = {}
        startTime = os.clock()
        UI.RecordBtn.Text = "⏹️ Stop Rec"
        UI.RecordBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
        updateStatus("Merekam Aksi...", Color3.fromRGB(219, 68, 85))
    else
        UI.RecordBtn.Text = "🔴 Record Macro"
        UI.RecordBtn.BackgroundColor3 = Color3.fromRGB(219, 68, 85)
        updateStatus("Aksi Direkam. Total: " .. #raidMacroDatabase[currentRaidMap], Color3.fromRGB(0, 255, 150))
    end
end)

UI.PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then isPlaying = false else playMacroForCurrentMap() end
end)

UI.AutoBtn.MouseButton1Click:Connect(function()
    autoPlayEnabled = not autoPlayEnabled
    if autoPlayEnabled then
        UI.AutoBtn.Text = "🤖 Auto: ON"
        UI.AutoBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        playMacroForCurrentMap()
    else
        UI.AutoBtn.Text = "🤖 Auto: OFF"
        UI.AutoBtn.BackgroundColor3 = Color3.fromRGB(72, 84, 96)
    end
end)

UI.SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1 then
        macroSpeed = 2
        UI.SpeedBtn.Text = "⚡ Speed: 2x"
        UI.SpeedBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    else
        macroSpeed = 1
        UI.SpeedBtn.Text = "⚡ Speed: 1x"
        UI.SpeedBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    end
end)

UI.SaveBtn.MouseButton1Click:Connect(function()
    updateStatus("Seluruh Data Raid 1-4 Tersimpan!", Color3.fromRGB(155, 89, 182))
end)
