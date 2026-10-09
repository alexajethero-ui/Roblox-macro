-- [[ 1. JEDA MENUNGGU ANTI-BYPASS / PROTEKSI GAME SELESAI MEMUAT ]]
task.wait(5) -- Menunda jalannya script selama 5 detik awal saat masuk game

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Hapus panel lama jika ada double inject agar tidak menumpuk
if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TD_Macro_Panel") then
    LocalPlayer.PlayerGui.TD_Macro_Panel:Destroy()
end

-- [[ 2. PEMBUATAN ELEMENT GUI (DIPAKSA MUNCUL DULUAN AGAR TIDAK MACET) ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TD_Macro_Panel"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 540)
MainFrame.Position = UDim2.new(0.35, 0, 0.2, 0) -- Berada di tengah layar
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

-- [[ 3. LOAD CONFIGURATION SYSTEM ]]
local filename = "macro_settings.json"
local settings = {
    AutoSkip = false,
    AutoTP = false,
    TargetMap = "Desert",
    MacroName = "MyMacro",
    AutoVote = false,
    TargetMode = "Easy",
    AutoLeave = false
}

pcall(function()
    if isfile and readfile and isfile(filename) then
        local decoded = HttpService:JSONDecode(readfile(filename))
        if decoded then
            for k, v in pairs(decoded) do settings[k] = v end
        end
    end
end)

local function saveSettings()
    pcall(function()
        if writefile then
            writefile(filename, HttpService:JSONEncode(settings))
        end
    end)
end

-- [[ 4. MEMBUAT TOMBOL INTERFACE PADA PANEL GUI ]]
local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0, 300, 0, 35)
NameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NameInput.Text = settings.MacroName
NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NameInput.PlaceholderText = "Masukkan nama file macro..."
NameInput.LayoutOrder = 1
NameInput.Parent = MainFrame

local RecordBtn = Instance.new("TextButton")
RecordBtn.Size = UDim2.new(0, 300, 0, 35)
RecordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecordBtn.Text = "RECORD: OFF"
RecordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordBtn.LayoutOrder = 2
RecordBtn.Parent = MainFrame

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 300, 0, 35)
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
PlayBtn.Text = "PLAY MACRO"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.LayoutOrder = 3
PlayBtn.Parent = MainFrame

local SkipBtn = Instance.new("TextButton")
SkipBtn.Size = UDim2.new(0, 300, 0, 35)
SkipBtn.BackgroundColor3 = settings.AutoSkip and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
SkipBtn.Text = "AUTO SKIP: " .. (settings.AutoSkip and "ON" or "OFF")
SkipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkipBtn.LayoutOrder = 4
SkipBtn.Parent = MainFrame

local TpToggleBtn = Instance.new("TextButton")
TpToggleBtn.Size = UDim2.new(0, 300, 0, 35)
TpToggleBtn.BackgroundColor3 = settings.AutoTP and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
TpToggleBtn.Text = "AUTO TELEPORT: " .. (settings.AutoTP and "ON" or "OFF")
TpToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpToggleBtn.LayoutOrder = 5
TpToggleBtn.Parent = MainFrame

local MapBtn = Instance.new("TextButton")
MapBtn.Size = UDim2.new(0, 300, 0, 35)
MapBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
MapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MapBtn.LayoutOrder = 6
MapBtn.Parent = MainFrame

local VoteToggleBtn = Instance.new("TextButton")
VoteToggleBtn.Size = UDim2.new(0, 300, 0, 35)
VoteToggleBtn.BackgroundColor3 = settings.AutoVote and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
VoteToggleBtn.Text = "AUTO VOTE MODE: " .. (settings.AutoVote and "ON" or "OFF")
VoteToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VoteToggleBtn.LayoutOrder = 7
VoteToggleBtn.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 300, 0, 35)
ModeBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 150)
ModeBtn.Text = "MODE TARGET: " .. settings.TargetMode
ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeBtn.LayoutOrder = 8
ModeBtn.Parent = MainFrame

local LeaveToggleBtn = Instance.new("TextButton")
LeaveToggleBtn.Size = UDim2.new(0, 300, 0, 35)
LeaveToggleBtn.BackgroundColor3 = settings.AutoLeave and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
LeaveToggleBtn.Text = "AUTO LEAVE: " .. (settings.AutoLeave and "ON" or "OFF")
LeaveToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LeaveToggleBtn.LayoutOrder = 9
LeaveToggleBtn.Parent = MainFrame

-- [[ 5. ENGINE & LISTENERS ]]
local isRecording = false
local isPlaying = false
local macroData = {}
local startTime = 0
local MapElevators = {["Desert"] = "Elevator1", ["Toilet City"] = "Elevator8", ["Cameraman HQ"] = "Elevator9"}

NameInput.FocusLost:Connect(function() settings.MacroName = NameInput.Text saveSettings() end)

RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    if isRecording then
        macroData = {} startTime = tick()
        RecordBtn.Text = "RECORD: ON (🔴)" RecordBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    else
        RecordBtn.Text = "RECORD: OFF" RecordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        pcall(function() if writefile then writefile(settings.MacroName .. ".json", HttpService:JSONEncode(macroData)) end end)
    end
end)

-- Menghubungkan klik tombol ke setelan konfigurasinya masing-masing
SkipBtn.MouseButton1Click:Connect(function()
    settings.AutoSkip = not settings.AutoSkip
    SkipBtn.Text = "AUTO SKIP: " .. (settings.AutoSkip and "ON" or "OFF")
    SkipBtn.BackgroundColor3 = settings.AutoSkip and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

TpToggleBtn.MouseButton1Click:Connect(function()
    settings.AutoTP = not settings.AutoTP
    TpToggleBtn.Text = "AUTO TELEPORT: " .. (settings.AutoTP and "ON" or "OFF")
    TpToggleBtn.BackgroundColor3 = settings.AutoTP and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

local maps = {"Desert", "Toilet City", "Cameraman HQ"}
MapBtn.MouseButton1Click:Connect(function()
    local currentIndex = table.find(maps, settings.TargetMap) or 1
    local nextIndex = currentIndex + 1
    if nextIndex > #maps then nextIndex = 1 end
    settings.TargetMap = maps[nextIndex]
    MapBtn.Text = "MAP TARGET: " .. settings.TargetMap
    saveSettings()
end)

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

LeaveToggleBtn.MouseButton1Click:Connect(function()
    settings.AutoLeave = not settings.AutoLeave
    LeaveToggleBtn.Text = "AUTO LEAVE: " .. (settings.AutoLeave and "ON" or "OFF")
    LeaveToggleBtn.BackgroundColor3 = settings.AutoLeave and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
    saveSettings()
end)

-- [[ 6. BACKGROUND FUNCTION ENGINE (TIDAK MENGHAMBAT JALANNYA GUI) ]]
task.spawn(function()
    -- Mengamankan proses pencarian folder game agar jika gagal, GUI tetap muncul
    local success, Shared = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("ModuleLoader"):WaitForChild("Shared"):WaitForChild("Network")
    end)
    
    if not success or not Shared then return end

    local ElevatorRemote = Shared:FindFirstChild("RemoteFunction") and Shared.RemoteFunction:FindFirstChild("ElevatorEnter")
    local VoteRemote = Shared:FindFirstChild("RemoteEvent") and Shared.RemoteEvent:FindFirstChild("ModeVote")
    local SkipRemote = Shared:FindFirstChild("RemoteEvent") and Shared.RemoteEvent:FindFirstChild("WaveSkip")
    local LeaveRemote = Shared:FindFirstChild("RemoteEvent") and Shared.RemoteEvent:FindFirstChild("OnLeave")

    while true do
        task.wait(1.5)
        pcall(function()
            if settings.AutoSkip and SkipRemote then SkipRemote:FireServer() end
            if settings.AutoVote and VoteRemote then VoteRemote:FireServer(settings.TargetMode) end
            
            if settings.AutoTP and ElevatorRemote then
                local targetElevator = MapElevators[settings.TargetMap]
                if targetElevator then ElevatorRemote:InvokeServer(targetElevator) end
            end
            
            if settings.AutoLeave and LeaveRemote then
    local matchEnded = workspace:FindFirstChild("MatchEnded") or LocalPlayer.PlayerGui:FindFirstChild("GameOver") or LocalPlayer.PlayerGui:FindFirstChild("Victory")
if matchEnded then LeaveRemote:FireServer() task.wait(5) end
          end
       end)
    end
end)
