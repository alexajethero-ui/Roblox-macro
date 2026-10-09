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
    MacroName = "MyMacro",
    AutoVote = false,
    TargetMode = "Easy",
    AutoLeave = false      -- Fitur Baru
}

-- Load Settings saat pindah map atau ganti server
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

-- [[ PEMETAAN ELEVATOR & REMOTE DARI GAME ANDA ]]
local MapElevators = {
    ["Desert"] = "Elevator1",
    ["Toilet City"] = "Elevator8",
    ["Cameraman HQ"] = "Elevator9"
}

-- Definisi Jalur Remote Sesuai Temuan Remote Spy Anda
local ElevatorRemote = game:GetService("ReplicatedStorage"):WaitForChild("ModuleLoader"):WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteFunction"):WaitForChild("ElevatorEnter")
local VoteRemote = game:GetService("ReplicatedStorage"):WaitForChild("ModuleLoader"):WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteEvent"):WaitForChild("ModeVote")
local SkipRemote = game:GetService("ReplicatedStorage"):WaitForChild("ModuleLoader"):WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteEvent"):WaitForChild("WaveSkip")
local LeaveRemote = game:GetService("ReplicatedStorage"):WaitForChild("ModuleLoader"):WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteEvent"):WaitForChild("OnLeave")

-- [[ UI PANEL CREATION ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TD_Macro_Panel"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 540) -- Ukuran panel disesuaikan untuk tombol baru
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

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

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

-- Tombol Pilihan Map
local MapBtn = Instance.new("TextButton")
MapBtn.Size = UDim2.new(0, 300, 0, 35)
MapBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
MapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MapBtn.LayoutOrder = 6
MapBtn.Parent = MainFrame

-- Tombol Auto Vote Mode Toggle
local VoteToggleBtn = Instance.new("TextButton")
VoteToggleBtn.Size = UDim2.new(0, 300, 0, 35)
VoteToggleBtn.BackgroundColor3 = settings.AutoVote and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
VoteToggleBtn.Text = "AUTO VOTE MODE: " .. (settings.AutoVote and "ON" or "OFF")
VoteToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VoteToggleBtn.LayoutOrder = 7
VoteToggleBtn.Parent = MainFrame

-- Tombol Pilihan Mode/Kesulitan
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 300, 0, 35)
ModeBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 150)
ModeBtn.Text = "MODE TARGET: " .. settings.TargetMode
ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeBtn.LayoutOrder = 8
ModeBtn.Parent = MainFrame

-- Tombol Auto Leave Toggle (Baru)
local LeaveToggleBtn = Instance.new("TextButton")
LeaveToggleBtn.Size = UDim2.new(0, 300, 0, 35)
LeaveToggleBtn.BackgroundColor3 = settings.AutoLeave and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
LeaveToggleBtn.Text = "AUTO LEAVE: " .. (settings.AutoLeave and "ON" or "OFF")
LeaveToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LeaveToggleBtn.LayoutOrder = 9
LeaveToggleBtn.Parent = MainFrame

-- [[ LOGIC & FUNCTIONALITY ]]

-- Mengatasi Masalah Variabel Berubah: Deteksi Unit lewat Koordinat XYZ
local function getUnitAtPosition(position)
    local placedFolder = workspace:FindFirstChild("PlacedUnits") or workspace:FindFirstChild("Towers")
    if placedFolder then
        for _, unit in pairs(placedFolder:GetChildren()) do
            if unit:IsA("Model") and unit.PrimaryPart then
                local distance = (unit.PrimaryPart.Position - position).Magnitude
                if distance < 2 then
                    return unit
                end
            end
        end
    end
    return nil
end

-- Simpan Aksi Macro ke Array
local function recordAction(actionType, unitName, position)
    if not isRecording then return end
    table.insert(macroData, {
        Time = tick() - startTime,
        Action = actionType, 
        UnitName = unitName,
        Position = {position.X, position.Y, position.Z}
    })
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
        if writefile then
            writefile(settings.MacroName .. ".json", HttpService:JSONEncode(macroData))
        end
    end
end)

-- Tombol Play Macro
PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    if isfile and isfile(settings.MacroName .. ".json") then
        macroData = HttpService:JSONDecode(readfile(settings.MacroName .. ".json"))
    end
    if #macroData == 0 then return end
    isPlaying = true
    task.spawn(function()
        local macroStartTime = tick()
        for _, step in ipairs(macroData) do
            if not isPlaying then break end
            while (tick() - macroStartTime) < step.Time do
                task.wait(0.05)
            end
            local targetPos = Vector3.new(step.Position, step.Position, step.Position)
            if step.Action == "Place" then
                -- Target jalurnya diisi dengan Remote Event Place game Anda nanti
            elseif step.Action == "Upgrade" then
                local targetUnit = getUnitAtPosition(targetPos)
                if targetUnit then
                    -- Target jalurnya diisi dengan Remote Event Upgrade game Anda nanti
                end
            end
        end
        isPlaying = false
    end)
end)

-- Toggle & Fungsi Firing Auto Skip
SkipBtn.MouseButton1Click:Connect(function()
    settings.AutoSkip = not settings.AutoSkip
    SkipBtn.Text = "AUTO SKIP: " .. (settings.AutoSkip and "ON" or "OFF")
    SkipBtn.BackgroundColor3 = settings.AutoSkip and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

task.spawn(function()
    while true do
        task.wait(1)
        if settings.AutoSkip then
            pcall(function()
                SkipRemote:FireServer()
            end)
        end
    end
end)

-- Toggle & Pilihan Map Target
local maps = {"Desert", "Toilet City", "Cameraman HQ"}
MapBtn.MouseButton1Click:Connect(function()
    local currentIndex = table.find(maps, settings.TargetMap) or 1
    local nextIndex = currentIndex + 1
if nextIndex > #maps then nextIndex = 1 end
settings.TargetMap = maps[nextIndex]
MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
saveSettings()
end)
-- Toggle & Fungsi Auto Teleport via Elevator Enter
TpToggleBtn.MouseButton1Click:Connect(function()
settings.AutoTP = not settings.AutoTP
TpToggleBtn.Text = "AUTO TELEPORT: " .. (settings.AutoTP and "ON" or "OFF")
TpToggleBtn.BackgroundColor3 = settings.AutoTP and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
saveSettings()
end)
task.spawn(function()
while true do
task.wait(2)
if settings.AutoTP then
local targetElevator = MapElevators[settings.TargetMap]
if targetElevator then
pcall(function()
ElevatorRemote:InvokeServer(targetElevator)
end)
end
end
end
end)
-- Logik Auto Vote Difficulty
VoteToggleBtn.MouseButton1Click:Connect(function()
settings.AutoVote = not settings.AutoVote
VoteToggleBtn.Text = "AUTO VOTE MODE: " .. (settings.AutoVote and "ON" or "OFF")
VoteToggleBtn.BackgroundColor3 = settings.AutoVote and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
saveSettings()
end)
local modes = {"Easy", "Normal", "Hard", "Insane"}
ModeBtn.MouseButton1Click:Connect(function()
local currentIndex = table.find(modes, settings.TargetMode) or 1
local nextIndex = currentIndex + 1
if nextIndex > #modes then nextIndex = 1 end
settings.TargetMode = modes[nextIndex]
ModeBtn.Text = "MODE TARGET: " .. settings.TargetMode
saveSettings()
end)
task.spawn(function()
while true do
task.wait(1)
if settings.AutoVote then
pcall(function()
VoteRemote:FireServer(settings.TargetMode)
end)
end
end
end)
-- LOGIK AUTO LEAVE (BARU)
LeaveToggleBtn.MouseButton1Click:Connect(function()
settings.AutoLeave = not settings.AutoLeave
LeaveToggleBtn.Text = "AUTO LEAVE: " .. (settings.AutoLeave and "ON" or "OFF")
LeaveToggleBtn.BackgroundColor3 = settings.AutoLeave and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
saveSettings()
end)
task.spawn(function()
while true do
task.wait(1)
if settings.AutoLeave then
-- Memicu leave secara otomatis ketika layar kemenangan/kekalahan terdeteksi
-- Biasanya ditandai dengan munculnya UI tertentu, misalnya game.PlayerGui:FindFirstChild("VictoryUI")
local matchEnded = workspace:FindFirstChild("MatchEnded") or game.PlayerGui:FindFirstChild("GameOver") or game.PlayerGui:FindFirstChild("Victory")
if matchEnded then
pcall(function()
LeaveRemote:FireServer()
end)
task.wait(5) -- Beri jeda agar tidak melakukan spam saat teleport lobi berlangsung
end
end
end
end)
