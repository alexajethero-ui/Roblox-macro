-- [[ LAYOUT & CONFIGURATION SAVING ]]
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local filename = "macro_settings.json"
local settings = {
    AutoSkip = false,
    AutoTP = false,
    TargetMap = "Desert",
    MacroName = "MyMacro"
}

-- Load Settings
if isfile and isfile(filename) then
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(filename)) end)
    if success then settings = decoded end
end

local function saveSettings()
    if writefile then
        writefile(filename, HttpService:JSONEncode(settings))
    end
end

-- [[ MACRO ENGINE VARIABLE ]]
local isRecording = false
local isPlaying = false
local macroData = {}
local startTime = 0

-- Map Place IDs (Ganti dengan Place ID game Anda yang sebenarnya)
local MapIDs = {
    ["Desert"] = 12345678, 
    ["Toilet City"] = 87654321,
    ["Cameraman HQ"] = 13579246
}

-- [[ UI CREATION ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TD_Macro_Panel"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 420)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "TD MACRO PANEL"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = MainFrame

-- UI List Layout untuk merapikan tombol
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Spacer di bawah judul agar tidak menempel
local Spacer = Instance.new("Frame")
Spacer.Size = UDim2.new(1, 0, 0, 40)
Spacer.BackgroundTransparency = 1
Spacer.LayoutOrder = 0
Spacer.Parent = MainFrame

-- Input Nama File Macro
local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0, 300, 0, 35)
NameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NameInput.Text = settings.MacroName
NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NameInput.PlaceholderText = "Masukkan nama file macro..."
NameInput.LayoutOrder = 1
NameInput.Parent = MainFrame
NameInput.FocusLost:Connect(function()
    settings.MacroName = NameInput.Text
    saveSettings()
end)

-- Tombol Record
local RecordBtn = Instance.new("TextButton")
RecordBtn.Size = UDim2.new(0, 300, 0, 35)
RecordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecordBtn.Text = "RECORD: OFF"
RecordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordBtn.LayoutOrder = 2
RecordBtn.Parent = MainFrame

-- Tombol Play
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 300, 0, 35)
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
PlayBtn.Text = "PLAY MACRO"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.LayoutOrder = 3
PlayBtn.Parent = MainFrame

-- Tombol Auto Skip Toggle
local SkipBtn = Instance.new("TextButton")
SkipBtn.Size = UDim2.new(0, 300, 0, 35)
SkipBtn.BackgroundColor3 = settings.AutoSkip and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
SkipBtn.Text = "AUTO SKIP: " .. (settings.AutoSkip and "ON" or "OFF")
SkipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkipBtn.LayoutOrder = 4
SkipBtn.Parent = MainFrame

-- Tombol Auto Teleport Toggle
local TpToggleBtn = Instance.new("TextButton")
TpToggleBtn.Size = UDim2.new(0, 300, 0, 35)
TpToggleBtn.BackgroundColor3 = settings.AutoTP and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
TpToggleBtn.Text = "AUTO TELEPORT: " .. (settings.AutoTP and "ON" or "OFF")
TpToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpToggleBtn.LayoutOrder = 5
TpToggleBtn.Parent = MainFrame

-- Dropdown/Tombol Pilihan Map
local MapBtn = Instance.new("TextButton")
MapBtn.Size = UDim2.new(0, 300, 0, 35)
MapBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
MapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MapBtn.LayoutOrder = 6
MapBtn.Parent = MainFrame

-- [[ LOGIC & FUNCTIONALITY ]]

-- 1. Solusi Upgrade: Logika Deteksi Berdasarkan Posisi Grid
local function getUnitAtPosition(position)
    -- Ganti 'Workspace.PlacedUnits' sesuai dengan folder tempat game Anda menyimpan unit yang sudah dipasang
    for _, unit in pairs(workspace:WaitForChild("PlacedUnits"):GetChildren()) do
        if unit:IsA("Model") and unit.PrimaryPart then
            local distance = (unit.PrimaryPart.Position - position).Magnitude
            if distance < 2 then -- Toleransi jarak posisi grid
                return unit
            end
        end
    end
    return nil
end

-- Record Action
local function recordAction(actionType, unitName, position, upgradeLevel)
    if not isRecording then return end
    table.insert(macroData, {
        Time = tick() - startTime,
        Action = actionType, -- "Place" atau "Upgrade"
        UnitName = unitName,
        Position = {position.X, position.Y, position.Z},
        Level = upgradeLevel
    })
end

-- Integrasi Hook Penempatan Unit untuk Record (Contoh Kerangka Kerja Game TD)
-- Catatan: Anda perlu menyambungkan ini ke RemoteFunction/Event game Anda
-- Contoh: RemoteEvent.OnClientEvent / InvokeServer Hooking
local function onUnitPlacedByUser(unitName, position)
    recordAction("Place", unitName, position, 1)
end

local function onUnitUpgradedByUser(position)
    recordAction("Upgrade", nil, position, nil)
end

-- Tombol Record Toggle
RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    if isRecording then
        macroData = {}
        startTime = tick()
        RecordBtn.Text = "RECORD: ON (🔴)"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    else
        RecordBtn.Text = "RECORD: OFF"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        -- Auto Save saat record dimatikan
        if writefile then
            writefile(settings.MacroName .. ".json", HttpService:JSONEncode(macroData))
        end
    end
end)

-- Tombol Play Macro
PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    
    -- Load Macro Data jika ada file eksternal
    if isfile and isfile(settings.MacroName .. ".json") then
        macroData = HttpService:JSONDecode(readfile(settings.MacroName .. ".json"))
    end
    
    if #macroData == 0 then return end
    
    isPlaying = true
    task.spawn(function()
        local macroStartTime = tick()
        for _, step in ipairs(macroData) do
            if not isPlaying then break end
            
            -- Tunggu waktu timeline yang tepat
            while (tick() - macroStartTime) < step.Time do
                task.wait(0.05)
            end
            
            local targetPos = Vector3.new(step.Position[1], step.Position[2], step.Position[3])
            
            if step.Action == "Place" then
                -- Panggil Remote Penempatan Unit Game Anda di sini
                -- GameRemote:InvokeServer("PlaceUnit", step.UnitName, targetPos)
            elseif step.Action == "Upgrade" then
                local targetUnit = getUnitAtPosition(targetPos)
                if targetUnit then
                    -- Panggil Remote Upgrade Game Anda menggunakan Instansi Unit yang ditemukan
                    -- GameRemote:InvokeServer("UpgradeUnit", targetUnit)
                end
            end
        end
        isPlaying = false
    end)
end)

-- Auto Skip Loop
task.spawn(function()
    while true do
        task.wait(1)
        if settings.AutoSkip then
            -- Panggil Remote Auto Skip game Anda disini
            -- ReplicatedStorage.RemoteEvents.SkipWave:FireServer()
        end
    end
end)

SkipBtn.MouseButton1Click:Connect(function()
    settings.AutoSkip = not settings.AutoSkip
    SkipBtn.Text = "AUTO SKIP: " .. (settings.AutoSkip and "ON" or "OFF")
    SkipBtn.BackgroundColor3 = settings.AutoSkip and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

-- Pilihan Map Loop Dropdown Sederhana
local maps = {"Desert", "Toilet City", "Cameraman HQ"}
MapBtn.MouseButton1Click:Connect(function()
    local currentIndex = table.find(maps, settings.TargetMap) or 1
    local nextIndex = currentIndex + 1
    if nextIndex > #maps then nextIndex = 1 end
    settings.TargetMap = maps[nextIndex]
    MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
    saveSettings()
end)

-- Auto Teleport Logic saat masuk lobi / pindah map
TpToggleBtn.MouseButton1Click:Connect(function()
    settings.AutoTP = not settings.AutoTP
    TpToggleBtn.Text = "AUTO TELEPORT: " .. (settings.AutoTP and "ON" or "OFF")
    TpToggleBtn.BackgroundColor3 = settings.AutoTP and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

task.spawn(function()
    if settings.AutoTP then
        local targetPlaceID = MapIDs[settings.TargetMap]
        if targetPlaceID and game.PlaceId ~= targetPlaceID then
            task.wait(3) -- Tunggu map benar-benar ter-load sebelum TP
            TeleportService:Teleport(targetPlaceID, LocalPlayer)
        end
    end
end)
