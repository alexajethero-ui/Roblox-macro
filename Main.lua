local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Check Executor File System Support
local supportsFileSystem = (writefile and readfile and isfolder and makefolder and listfiles and delfile and isfile)
if not supportsFileSystem then
    warn("[Macro System]: Executor kamu tidak mendukung File System lengkap (writefile/readfile/delfile)!")
end

local FOLDER_NAME = "TowerMacroData"
local CONFIG_FILE = FOLDER_NAME .. "/config.json"

if supportsFileSystem and not isfolder(FOLDER_NAME) then
    makefolder(FOLDER_NAME)
end

-- System Variables
local recordedActions = {}
local isRecording = false
local isPlaying = false
local recordStartTime = 0
local selectedMacroFile = ""
local isAutoPlayEnabled = false
local currentSpeedMultiplier = 1
local isAutoSummonEnabled = false

-- Loop & Timing Variables
local hasAutoPlayedThisSession = false

-- Auto Vote Variables
local isAutoVoteEnabled = false
local isAutoVoteDiffEnabled = false
local hasVotedThisSession = false

-- System Tracking
local placedTowersRecord = {}
local placedTowersPlay = {}

local function logConsole(msg)
    print(string.format("[Macro System]: %s", tostring(msg)))
end

-- Forward Declarations
local saveConfigToFile, loadConfigFromFile, loadMacroFromFile, playMacro, updateAutoPlayUI

-- ==========================================
-- HELPER FUNCTIONS (ENHANCED TOWER LOOKUP)
-- ==========================================
local function setGameSpeed(speed)
    local functionsFolder = ReplicatedStorage:FindFirstChild("Functions")
    local changeSpeedRemote = functionsFolder and functionsFolder:FindFirstChild("ChangeSpeed")
    if changeSpeedRemote then
        pcall(function()
            changeSpeedRemote:InvokeServer(speed)
        end)
    end
end

local function findTowerByPosition(targetCFrame, maxDist, ignoreTable)
    if not targetCFrame then return nil end
    local towersFolder = Workspace:FindFirstChild("Towers") or Workspace
    if not towersFolder then return nil end

    maxDist = maxDist or 6
    ignoreTable = ignoreTable or {}

    local closestTower = nil
    local shortestDistance = maxDist

    for _, tower in ipairs(towersFolder:GetChildren()) do
        if tower:IsA("Model") then
            local isIgnored = false
            for _, ignoredTower in pairs(ignoreTable) do
                if ignoredTower == tower then
                    isIgnored = true
                    break
                end
            end

            if not isIgnored then
                local primaryPart = tower.PrimaryPart or tower:FindFirstChild("HumanoidRootPart") or tower:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    local dist = (primaryPart.Position - targetCFrame.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestTower = tower
                    end
                end
            end
        end
    end

    return closestTower
end

local function getEventRemote(nameList)
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return nil end
    for _, name in ipairs(nameList) do
        local remote = events:FindFirstChild(name)
        if remote then return remote end
    end
    return nil
end

local function getPlacedTowersPlayList(excludeIndex)
    local ignoreList = {}
    for idx, towerModel in pairs(placedTowersPlay) do
        if idx ~= excludeIndex and towerModel then
            table.insert(ignoreList, towerModel)
        end
    end
    return ignoreList
end

-- ==========================================
-- UI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerMacroUI_Advanced"
ScreenGui.ResetOnSpawn = false

local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
if not playerGui then return end

if playerGui:FindFirstChild("TowerMacroUI_Advanced") then
    playerGui.TowerMacroUI_Advanced:Destroy()
end
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 510)
MainFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar Frame
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
Title.Text = "Tower Macro System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
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

-- Close Button
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

-- Container
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Record Button
local RecordBtn = Instance.new("TextButton")
RecordBtn.Size = UDim2.new(0.9, 0, 0, 30)
RecordBtn.Position = UDim2.new(0.05, 0, 0, 5)
RecordBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
RecordBtn.Text = "Record"
RecordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordBtn.Font = Enum.Font.SourceSans
RecordBtn.TextSize = 14
RecordBtn.Parent = ContentFrame
Instance.new("UICorner", RecordBtn).CornerRadius = UDim.new(0, 4)

-- Play Button
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0.9, 0, 0, 30)
PlayBtn.Position = UDim2.new(0.05, 0, 0, 40)
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
PlayBtn.Text = "Play Macro"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.Font = Enum.Font.SourceSansBold
PlayBtn.TextSize = 14
PlayBtn.Parent = ContentFrame
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 4)

-- Save Input Box
local SaveNameBox = Instance.new("TextBox")
SaveNameBox.Size = UDim2.new(0.6, 0, 0, 30)
SaveNameBox.Position = UDim2.new(0.05, 0, 0, 75)
SaveNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SaveNameBox.Text = "Macro1"
SaveNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveNameBox.Font = Enum.Font.SourceSans
SaveNameBox.TextSize = 13
SaveNameBox.Parent = ContentFrame
Instance.new("UICorner", SaveNameBox).CornerRadius = UDim.new(0, 4)

-- Save Button
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.28, 0, 0, 30)
SaveBtn.Position = UDim2.new(0.67, 0, 0, 75)
SaveBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 30)
SaveBtn.Text = "Save"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.SourceSans
SaveBtn.TextSize = 14
SaveBtn.Parent = ContentFrame
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 4)

-- Selected Macro Label
local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0.9, 0, 0, 25)
SelectLabel.Position = UDim2.new(0.05, 0, 0, 110)
SelectLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SelectLabel.Text = "Selected: None"
SelectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SelectLabel.Font = Enum.Font.SourceSansItalic
SelectLabel.TextSize = 12
SelectLabel.Parent = ContentFrame
Instance.new("UICorner", SelectLabel).CornerRadius = UDim.new(0, 4)

-- Refresh/Switch Button
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.43, 0, 0, 25)
RefreshBtn.Position = UDim2.new(0.05, 0, 0, 140)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RefreshBtn.Text = "Switch Macro"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.SourceSans
RefreshBtn.TextSize = 12
RefreshBtn.Parent = ContentFrame
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

-- Delete Macro Button
local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Size = UDim2.new(0.43, 0, 0, 25)
DeleteBtn.Position = UDim2.new(0.52, 0, 0, 140)
DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
DeleteBtn.Text = "Delete File"
DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteBtn.Font = Enum.Font.SourceSansBold
DeleteBtn.TextSize = 12
DeleteBtn.Parent = ContentFrame
Instance.new("UICorner", DeleteBtn).CornerRadius = UDim.new(0, 4)

-- Auto Play Toggle Button
local AutoPlayBtn = Instance.new("TextButton")
AutoPlayBtn.Size = UDim2.new(0.9, 0, 0, 30)
AutoPlayBtn.Position = UDim2.new(0.05, 0, 0, 170)
AutoPlayBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
AutoPlayBtn.Text = "Auto Play: OFF"
AutoPlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoPlayBtn.Font = Enum.Font.SourceSansBold
AutoPlayBtn.TextSize = 13
AutoPlayBtn.Parent = ContentFrame
Instance.new("UICorner", AutoPlayBtn).CornerRadius = UDim.new(0, 4)

-- Speed Multiplier Toggle Button
local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(0.9, 0, 0, 30)
SpeedBtn.Position = UDim2.new(0.05, 0, 0, 205)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
SpeedBtn.Text = "Speed: 1x"
SpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBtn.Font = Enum.Font.SourceSansBold
SpeedBtn.TextSize = 13
SpeedBtn.Parent = ContentFrame
Instance.new("UICorner", SpeedBtn).CornerRadius = UDim.new(0, 4)

-- Map Input Box
local MapNameBox = Instance.new("TextBox")
MapNameBox.Size = UDim2.new(0.6, 0, 0, 30)
MapNameBox.Position = UDim2.new(0.05, 0, 0, 240)
MapNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MapNameBox.Text = "Desert"
MapNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MapNameBox.Font = Enum.Font.SourceSans
MapNameBox.TextSize = 13
MapNameBox.Parent = ContentFrame
Instance.new("UICorner", MapNameBox).CornerRadius = UDim.new(0, 4)

-- Auto Vote Map Toggle Button
local AutoVoteBtn = Instance.new("TextButton")
AutoVoteBtn.Size = UDim2.new(0.28, 0, 0, 30)
AutoVoteBtn.Position = UDim2.new(0.67, 0, 0, 240)
AutoVoteBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
AutoVoteBtn.Text = "Vote ON"
AutoVoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoVoteBtn.Font = Enum.Font.SourceSansBold
AutoVoteBtn.TextSize = 11
AutoVoteBtn.Parent = ContentFrame
Instance.new("UICorner", AutoVoteBtn).CornerRadius = UDim.new(0, 4)

-- Difficulty Input Box
local DiffNameBox = Instance.new("TextBox")
DiffNameBox.Size = UDim2.new(0.6, 0, 0, 30)
DiffNameBox.Position = UDim2.new(0.05, 0, 0, 275)
DiffNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
DiffNameBox.Text = "Nightmare"
DiffNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
DiffNameBox.Font = Enum.Font.SourceSans
DiffNameBox.TextSize = 13
DiffNameBox.Parent = ContentFrame
Instance.new("UICorner", DiffNameBox).CornerRadius = UDim.new(0, 4)

-- Auto Vote Difficulty Toggle Button
local AutoVoteDiffBtn = Instance.new("TextButton")
AutoVoteDiffBtn.Size = UDim2.new(0.28, 0, 0, 30)
AutoVoteDiffBtn.Position = UDim2.new(0.67, 0, 0, 275)
AutoVoteDiffBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
AutoVoteDiffBtn.Text = "Diff ON"
AutoVoteDiffBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoVoteDiffBtn.Font = Enum.Font.SourceSansBold
AutoVoteDiffBtn.TextSize = 11
AutoVoteDiffBtn.Parent = ContentFrame
Instance.new("UICorner", AutoVoteDiffBtn).CornerRadius = UDim.new(0, 4)

-- Auto Summon Toggle Button
local AutoSummonBtn = Instance.new("TextButton")
AutoSummonBtn.Size = UDim2.new(0.9, 0, 0, 30)
AutoSummonBtn.Position = UDim2.new(0.05, 0, 0, 310)
AutoSummonBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
AutoSummonBtn.Text = "Auto Summon (10x): OFF"
AutoSummonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSummonBtn.Font = Enum.Font.SourceSansBold
AutoSummonBtn.TextSize = 13
AutoSummonBtn.Parent = ContentFrame
Instance.new("UICorner", AutoSummonBtn).CornerRadius = UDim.new(0, 4)

-- Detailed Status Info Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 125)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 345)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.Text = "Status: Ready\nSilahkan pilih Macro atau mulai Recording."
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = ContentFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

-- UI Events
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 240, 0, 30)
        ContentFrame.Visible = false
        MinimizeBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 240, 0, 510)
        ContentFrame.Visible = true
        MinimizeBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ==========================================
-- SAVE & LOAD CONFIG / MACRO SYSTEM
-- ==========================================
updateAutoPlayUI = function()
    AutoPlayBtn.Text = isAutoPlayEnabled and "Auto Play: ON" or "Auto Play: OFF"
    AutoPlayBtn.BackgroundColor3 = isAutoPlayEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
end

saveConfigToFile = function()
    if not supportsFileSystem then return end
    local configData = {
        autoPlay = isAutoPlayEnabled,
        autoVote = isAutoVoteEnabled,
        autoVoteDiff = isAutoVoteDiffEnabled,
        speedMultiplier = currentSpeedMultiplier,
        autoSummon = isAutoSummonEnabled,
        mapName = MapNameBox.Text,
        diffName = DiffNameBox.Text,
        selectedMacro = selectedMacroFile,
        saveInputText = SaveNameBox.Text
    }
    writefile(CONFIG_FILE, HttpService:JSONEncode(configData))
end

loadConfigFromFile = function()
    if not supportsFileSystem or not isfile(CONFIG_FILE) then return end
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if success and typeof(result) == "table" then
        if result.autoPlay ~= nil then isAutoPlayEnabled = result.autoPlay end
        updateAutoPlayUI()

        if result.autoVote ~= nil then
            isAutoVoteEnabled = result.autoVote
            AutoVoteBtn.Text = isAutoVoteEnabled and "Vote ON" or "Vote OFF"
            AutoVoteBtn.BackgroundColor3 = isAutoVoteEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
        end

        if result.autoVoteDiff ~= nil then
            isAutoVoteDiffEnabled = result.autoVoteDiff
            AutoVoteDiffBtn.Text = isAutoVoteDiffEnabled and "Diff ON" or "Diff OFF"
            AutoVoteDiffBtn.BackgroundColor3 = isAutoVoteDiffEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
        end

        if result.speedMultiplier ~= nil then
            currentSpeedMultiplier = result.speedMultiplier
            SpeedBtn.Text = "Speed: " .. currentSpeedMultiplier .. "x"
            SpeedBtn.BackgroundColor3 = (currentSpeedMultiplier > 1) and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
        end

        if result.autoSummon ~= nil then
            isAutoSummonEnabled = result.autoSummon
            AutoSummonBtn.Text = isAutoSummonEnabled and "Auto Summon (10x): ON" or "Auto Summon (10x): OFF"
            AutoSummonBtn.BackgroundColor3 = isAutoSummonEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
        end

        if result.mapName then MapNameBox.Text = result.mapName end
        if result.diffName then DiffNameBox.Text = result.diffName end
        if result.saveInputText then SaveNameBox.Text = result.saveInputText end
        if result.selectedMacro and result.selectedMacro ~= "" then loadMacroFromFile(result.selectedMacro) end
    end
end

local function serializeCFrame(cf) return {cf:GetComponents()} end
local function deserializeCFrame(tbl) return CFrame.new(unpack(tbl)) end

local function saveMacroToFile(fileName)
    if not supportsFileSystem or #recordedActions == 0 then return end

    local serializedData = {}
    for _, action in ipairs(recordedActions) do
        local copyAction = {
            actionType = action.actionType,
            time = action.time,
            towerIndex = action.towerIndex,
            towerName = action.towerName,
            arg3 = action.arg3,
            arg4 = action.arg4,
            arg5 = action.arg5,
            extraArgs = action.extraArgs
        }
        if action.cframe then copyAction.cframe = serializeCFrame(action.cframe) end
        table.insert(serializedData, copyAction)
    end

    local path = FOLDER_NAME .. "/" .. fileName .. ".json"
    writefile(path, HttpService:JSONEncode(serializedData))
    SelectLabel.Text = "Selected: " .. fileName
    selectedMacroFile = fileName
    StatusLabel.Text = string.format("Status: Saved!\nFile: %s.json\nTotal Aksi: %d", fileName, #recordedActions)
    saveConfigToFile()
end

loadMacroFromFile = function(fileName)
    if not supportsFileSystem then return false end
    local path = FOLDER_NAME .. "/" .. fileName .. ".json"
    if not isfile(path) then return false end

    local rawJson = readfile(path)
    local decoded = HttpService:JSONDecode(rawJson)

    recordedActions = {}
    for _, action in ipairs(decoded) do
        local restoredAction = {
            actionType = action.actionType,
            time = action.time,
            towerIndex = action.towerIndex,
            towerName = action.towerName,
            arg3 = action.arg3,
            arg4 = action.arg4,
            arg5 = action.arg5,
            extraArgs = action.extraArgs
        }
        if action.cframe then restoredAction.cframe = deserializeCFrame(action.cframe) end
        table.insert(recordedActions, restoredAction)
    end

    SelectLabel.Text = "Selected: " .. fileName
    selectedMacroFile = fileName
    StatusLabel.Text = string.format("Status: Loaded Macro\nFile: %s\nTotal Aksi: %d", fileName, #recordedActions)
    return true
end

-- ==========================================
-- HOOK RECORDING SYSTEM
-- ==========================================
local function getTowerIndexFromRecord(towerInstance)
    if not towerInstance then return nil end
    for index, instance in pairs(placedTowersRecord) do
        if instance == towerInstance then
            return index
        end
    end
    return nil
end

local rawNamecall
rawNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if isRecording and (method == "InvokeServer" or method == "invokeServer") then
        local currentTime = tick() - recordStartTime

        if self.Name ==
