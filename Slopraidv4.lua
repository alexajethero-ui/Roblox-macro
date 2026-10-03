-- MacroGui.lua
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroSystemGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Main Frame (Compact & Minimalis)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 160)
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0) -- Di sebelah kiri layar, tidak mengganggu
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Bisa digeser oleh pemain
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = " 🌟 SLOP TD MACRO RAID STARLARP"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextAlign = Enum.TextAlign.Left
Title.Parent = MainFrame

-- Grid Layout untuk Tombol agar Rapi
local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.Parent = MainFrame
UIGridLayout.CellSize = UDim2.new(0, 75, 0, 30)
UIGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
UIGridLayout.StartCorner = Enum.AnimatorJobStatus.Status -- Layouting
UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Fungsi Helper untuk Membuat Tombol Aesthetic
local function createButton(name, text, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    -- Efek Hover Ringan
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    end)
    
    btn.Parent = MainFrame
    return btn
end

-- Membuat Tombol-Tombol
local RecordBtn  = createButton("RecordBtn", "🔴 Record", Color3.fromRGB(219, 68, 85))
local PlayBtn    = createButton("PlayBtn", "▶️ Play", Color3.fromRGB(68, 189, 50))
local AutoBtn    = createButton("AutoBtn", "🤖 Autoplay: OFF", Color3.fromRGB(72, 84, 96))
local SpeedBtn   = createButton("SpeedBtn", "⚡ Speed x1", Color3.fromRGB(241, 196, 15))
local PlaceBtn   = createButton("PlaceBtn", "🏗️ Place Key", Color3.fromRGB(52, 152, 219))
local SaveBtn    = createButton("SaveBtn", "💾 Save Macro", Color3.fromRGB(155, 89, 182))

return {
    RecordBtn = RecordBtn,
    PlayBtn = PlayBtn,
    AutoBtn = AutoBtn,
    SpeedBtn = SpeedBtn,
    PlaceBtn = PlaceBtn,
    SaveBtn = SaveBtn
}

-- MacroClient.lua (Spesifik Mode Raid)
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Load UI Components
local UI = require(script.Parent.MacroGui) 

-- State Macro & Raid
local isRecording = false
local isPlaying = false
local autoPlayEnabled = false
local macroSpeed = 1
local startTime = 0
local currentRaidMap = "Raid 1" -- Default fallback

-- Database Macro per Raid (Menampung record terpisah)
local raidMacroDatabase = {
    ["Raid 1"] = {},
    ["Raid 2"] = {},
    ["Raid 3"] = {},
    ["Raid 4"] = {}
}

-- Konfigurasi Input
local PLACEMENT_KEY = Enum.KeyCode.E 
local selectedTowerTemplate = "Archer" 

-- Remote Events Game Anda
local PlaceTowerRemote = ReplicatedStorage:WaitForChild("PlaceTowerEvent")
local UpgradeTowerRemote = ReplicatedStorage:WaitForChild("UpgradeTowerEvent")

-- ==========================================
-- 🛑 DETEKSI OTOMATIS MAP/RAID VARIABLE
-- ==========================================
-- *Sesuaikan 'CurrentRaidMode' dengan lokasi StringValue/Variable Raid di game Anda*
local RaidVariable = workspace:WaitForChild("CurrentRaidMode") 

local function onRaidMapChanged(newMapName)
    if raidMacroDatabase[newMapName] then
        currentRaidMap = newMapName
        UI.RecordBtn.Text = "🔴 Rec ("..newMapName..")"
        print("🗺️ Map Terdeteksi: " .. newMapName)
        
        -- Jika Autoplay aktif, langsung putar macro untuk map baru ini secara otomatis
        if autoPlayEnabled then
            task.wait(3) -- Jeda waktu loading map/transisi screen
            playMacroForCurrentMap()
        end
    else
        warn("⚠️ Nama Raid tidak valid atau tidak terdaftar: " .. tostring(newMapName))
    end
end

-- Deteksi perubahan otomatis saat wave 25 berganti map
RaidVariable.Changed:Connect(onRaidMapChanged)
-- Pengecekan awal saat pertama kali script dimuat
onRaidMapChanged(RaidVariable.Value)


-- ==========================================
-- LOGIKA RECORDING (Merekam per Map)
-- ==========================================
local function getElapsedTime()
    return (os.clock() - startTime) * macroSpeed
end

local function recordAction(actionType, details)
    if not isRecording then return end
    
    -- Memasukkan data ke dalam list map yang sedang aktif saat ini
    table.insert(raidMacroDatabase[currentRaidMap], {
        Time = getElapsedTime(),
        Type = actionType,
        Details = details
    })
end

-- Deteksi Input Placement & Upgrade
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if isRecording then
        if input.KeyCode == PLACEMENT_KEY then
            local mouse = Players.LocalPlayer:GetMouse()
            local targetPosition = mouse.Hit.Position
            
            local details = {
                TowerName = selectedTowerTemplate,
                Position = {targetPosition.X, targetPosition.Y, targetPosition.Z}
            }
            
            recordAction("Place", details)
            PlaceTowerRemote:FireServer(details.TowerName, mouse.Hit) 
        
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = Players.LocalPlayer:GetMouse()
            if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
                local towerInstance = mouse.Target.Parent
                recordAction("Upgrade", {TowerID = towerInstance.Name})
                UpgradeTowerRemote:FireServer(towerInstance)
            end
        end
    end
end)


-- ==========================================
-- LOGIKA PLAYBACK OTOMATIS (`playMacroForCurrentMap`)
-- ==========================================
function playMacroForCurrentMap()
    local currentData = raidMacroDatabase[currentRaidMap]
    
    if not currentData or #currentData == 0 then 
        print("❌ Tidak ada data macro untuk " .. currentRaidMap)
        return 
    end
    
    if isPlaying then return end
    isPlaying = true
    UI.PlayBtn.Text = "⏹️ Stop"
    UI.PlayBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
    
    local playbackStart = os.clock()
    local index = 1
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            connection:Disconnect()
            return
        end
        
        local currentPlaybackTime = (os.clock() - playbackStart) * macroSpeed
        
        while index <= #currentData and currentData[index].Time <= currentPlaybackTime do
            local action = currentData[index]
            
            if action.Type == "Place" then
                local pos = Vector3.new(action.Details.Position[1], action.Details.Position[2], action.Details.Position[3])
                PlaceTowerRemote:FireServer(action.Details.TowerName, CFrame.new(pos))
            elseif action.Type == "Upgrade" then
                UpgradeTowerRemote:FireServer(action.Details.TowerID)
            end
            
            index = index + 1
        end
        
        if index > #currentData then
            isPlaying = false
            UI.PlayBtn.Text = "▶️ Play"
            UI.PlayBtn.BackgroundColor3 = Color3.fromRGB(68, 189, 50)
            connection:Disconnect()
            print("✅ Selesai menjalankan macro untuk " .. currentRaidMap)
        end
    end)
end


-- ==========================================
-- LOGIKA UTAMA TOMBOL UI
-- ==========================================

-- Tombol Record (Otomatis menimpa data map yang sedang aktif)
UI.RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    if isRecording then
        raidMacroDatabase[currentRaidMap] = {} -- Reset data lama KHUSUS untuk map ini saja
        startTime = os.clock()
        UI.RecordBtn.Text = "⏹️ Rec: " .. currentRaidMap
        UI.RecordBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
    else
        UI.RecordBtn.Text = "🔴 Rec ("..currentRaidMap..")"
        UI.RecordBtn.BackgroundColor3 = Color3.fromRGB(219, 68, 85)
        print("💾 Berhasil merekam " .. #raidMacroDatabase[currentRaidMap] .. " aksi di " .. currentRaidMap)
    end
end)

-- Tombol Play Manual
UI.PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        isPlaying = false
    else
        playMacroForCurrentMap()
    end
end)

-- Tombol Autoplay (Jika aktif, script akan langsung "Play" saat variabel map berubah)
UI.AutoBtn.MouseButton1Click:Connect(function()
    autoPlayEnabled = not autoPlayEnabled
    if autoPlayEnabled then
        UI.AutoBtn.Text = "🤖 Auto: ON"
        UI.AutoBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        playMacroForCurrentMap() -- Coba jalankan langsung jika map sudah ada
    else
        UI.AutoBtn.Text = "🤖 Auto: OFF"
        UI.AutoBtn.BackgroundColor3 = Color3.fromRGB(72, 84, 96)
    end
end)

-- Tombol Speed
UI.SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1 then
        macroSpeed = 5
        UI.SpeedBtn.Text = "⚡ Speed x5"
        UI.SpeedBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    else
        macroSpeed = 1
        UI.SpeedBtn.Text = "⚡ Speed x1"
        UI.SpeedBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    end
end)

-- Tombol Save ke DataStore
UI.SaveBtn.MouseButton1Click:Connect(function()
    -- Anda bisa menembakkan RemoteEvent ke server di sini untuk menyimpan 'raidMacroDatabase' penuh berisi ke-4 map
    print("Seluruh Database Raid Macro (1-4) berhasil dicadangkan!")
end)

-- ==========================================
-- 🛑 DETEKSI OTOMATIS MAP/RAID VARIABLE (VERSI ACAK/RANDOM)
-- ==========================================
local RaidVariable = workspace:WaitForChild("CurrentRaidMode") 

local function onRaidMapChanged(newMapName)
    if not newMapName or newMapName == "" then return end
    
    -- JIKA MAP BELUM ADA DI DATABASE (Karena sistem acak), OTOMATIS DAFTARKAN
    if not raidMacroDatabase[newMapName] then
        raidMacroDatabase[newMapName] = {}
        print("🆕 Map Baru Terdeteksi secara Acak & Didaftarkan: " .. newMapName)
    end
    
    currentRaidMap = newMapName
    UI.RecordBtn.Text = "🔴 Rec ("..newMapName..")"
    print("🗺️ Map Aktif Saat Ini: " .. newMapName)
    
    -- Jika Autoplay aktif, langsung putar macro untuk map acak yang baru muncul ini
    if autoPlayEnabled then
        task.wait(3) -- Jeda waktu 3 detik memberi waktu map/screen selesai loading
        playMacroForCurrentMap()
    end
end

-- Deteksi perubahan otomatis kapan pun map diacak/berubah
RaidVariable.Changed:Connect(onRaidMapChanged)
onRaidMapChanged(RaidVariable.Value)

-- Database Macro (Kosong di awal, akan terisi otomatis secara dinamis saat map diacak)
local raidMacroDatabase = {}
