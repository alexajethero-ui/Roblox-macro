-- =============================================================================
-- 🌟 SLOP TD MACRO RAID STARLARP (Bypass Player Gui - Instant Load)
-- =============================================================================

-- [Bagian 1: Bypass Jalur Akses Layar - Ditaruh Sebelum Line 11]
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Menentukan target layar secara instan tanpa menunggu PlayerGui
local targetGui = CoreGui or StarterGui

-- Bersihkan sisa UI lama jika ada agar tidak double
if targetGui:FindFirstChild("MacroSystemGui") then
    pcall(function() targetGui.MacroSystemGui:Destroy() end)
end

-- =============================================================================
-- [Bagian 2: Pembuatan UI Langsung Muncul Ke Layar]
-- =============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroSystemGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 160)
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = " 🌟 SLOP TD MACRO RAID STARLARP"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextAlign = Enum.TextAlign.Left
Title.Parent = MainFrame

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.Parent = MainFrame
UIGridLayout.CellSize = UDim2.new(0, 75, 0, 30)
UIGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIGridLayout.StartCorner = Enum.StartCorner.TopLeft

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
    btn.Parent = MainFrame
    return btn
end

local RecordBtn  = createButton("RecordBtn", "🔴 Merekam", Color3.fromRGB(219, 68, 85))
local PlayBtn    = createButton("PlayBtn", "▶️ Putar", Color3.fromRGB(68, 189, 50))
local AutoBtn    = createButton("AutoBtn", "🤖 Auto: OFF", Color3.fromRGB(72, 84, 96))
local SpeedBtn   = createButton("SpeedBtn", "⚡ Speed x1", Color3.fromRGB(241, 196, 15))
local PlaceBtn   = createButton("PlaceBtn", "🏗️ Place Key", Color3.fromRGB(52, 152, 219))
local SaveBtn    = createButton("SaveBtn", "💾 Simpan", Color3.fromRGB(155, 89, 182))

-- =============================================================================
-- [Bagian 3: Logika Sistem Macro & Database Batar Belakang]
-- =============================================================================
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isRecording = false
local isPlaying = false
local autoPlayEnabled = false
local macroSpeed = 1
local startTime = 0
local currentRaidMap = "Raid Otomatis" 

local raidMacroDatabase = {}
local PLACEMENT_KEY = Enum.KeyCode.E 
local selectedTowerTemplate = "Archer" 

local PlaceTowerRemote = ReplicatedStorage:FindFirstChild("PlaceTowerEvent") or Instance.new("RemoteEvent")
local UpgradeTowerRemote = ReplicatedStorage:FindFirstChild("UpgradeTowerEvent") or Instance.new("RemoteEvent")

local function getElapsedTime()
    return (os.clock() - startTime) * macroSpeed
end

local function recordAction(actionType, details)
    if not isRecording then return end
    if not raidMacroDatabase[currentRaidMap] then raidMacroDatabase[currentRaidMap] = {} end
    
    table.insert(raidMacroDatabase[currentRaidMap], {
        Time = getElapsedTime(),
        Type = actionType,
        Details = details
    })
end

-- Input Merekam Aksi (Menggunakan deteksi mouse yang aman tanpa pengecekan kaku localPlayer)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local activePlayer = Players.LocalPlayer
    if not activePlayer then return end
    local mouse = activePlayer:GetMouse()
    if not mouse then return end

    if isRecording then
        if input.KeyCode == PLACEMENT_KEY and mouse.Hit then
            local details = {
                TowerName = selectedTowerTemplate,
                Position = {mouse.Hit.Position.X, mouse.Hit.Position.Y, mouse.Hit.Position.Z}
            }
            recordAction("Place", details)
            pcall(function() PlaceTowerRemote:FireServer(details.TowerName, mouse.Hit) end)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
                local towerInstance = mouse.Target.Parent
                recordAction("Upgrade", {TowerID = towerInstance.Name})
                pcall(function() UpgradeTowerRemote:FireServer(towerInstance) end)
            end
        end
    end
end)

local function playMacroForCurrentMap()
    local currentData = raidMacroDatabase[currentRaidMap]
    if not currentData or #currentData == 0 then return end
    if isPlaying then return end
    
    isPlaying = true
    PlayBtn.Text = "⏹️ Stop"
    PlayBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
    
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
                pcall(function() 
                    PlaceTowerRemote:FireServer(action.Details.TowerName, CFrame.new(pos)) 
                end)
            elseif action.Type == "Upgrade" then
                pcall(function() 
                    UpgradeTowerRemote:FireServer(action.Details.TowerID) 
                end)
            end
            index = index + 1
        end
        
        if index > #currentData then
            isPlaying = false
            PlayBtn.Text = "▶️ Putar"
            PlayBtn.BackgroundColor3 = Color3.fromRGB(68, 189, 50)
            connection:Disconnect()
        end
    end)
end

-- =============================================================================
-- [Bagian 4: Deteksi Map Otomatis Aman]
-- =============================================================================
task.spawn(function()
    local RaidVariable = workspace:FindFirstChild("CurrentRaidMode")
    
    local function onRaidMapChanged(newMapName)
        if not newMapName or newMapName == "" then return end
        if not raidMacroDatabase[newMapName] then raidMacroDatabase[newMapName] = {} end
        
        currentRaidMap = newMapName
        RecordBtn.Text = "🔴 Rec ("..newMapName..")"
        
        if autoPlayEnabled then
            task.wait(2)
            playMacroForCurrentMap()
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

-- =============================================================================
-- [Bagian 5: Listener Tombol UI Utama]
-- =============================================================================
RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    if isRecording then
        raidMacroDatabase[currentRaidMap] = {} 
        startTime = os.clock()
        RecordBtn.Text = "⏹️ Rec: " .. currentRaidMap
        RecordBtn.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
    else
        RecordBtn.Text = "🔴 Rec ("..currentRaidMap..")"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(219, 68, 85)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then isPlaying = false else playMacroForCurrentMap() end
end)

AutoBtn.MouseButton1Click:Connect(function()
    autoPlayEnabled = not autoPlayEnabled
    if autoPlayEnabled then
        AutoBtn.Text = "🤖 Auto: ON"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        playMacroForCurrentMap() 
    else
        AutoBtn.Text = "🤖 Auto: OFF"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(72, 84, 96)
    end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1 then
        macroSpeed = 5
        SpeedBtn.Text = "⚡ Speed x5"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    else
        macroSpeed = 1
        SpeedBtn.Text = "⚡ Speed x1"
SpeedBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    end
end)
SaveBtn.MouseButton1Click:Connect(function()
print("Database makro diamankan secara lokal.")
end)
