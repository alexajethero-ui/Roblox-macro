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

        if self.Name == "SpawnTower" then
            local result = rawNamecall(self, ...)
            
            local spawnedTower = nil
            if typeof(result) == "Instance" then
                spawnedTower = result
            elseif typeof(result) == "table" and result[1] then
                spawnedTower = result[1]
            end

            if not spawnedTower and args[2] then
                local searchStart = tick()
                repeat
                    task.wait(0.05)
                    spawnedTower = findTowerByPosition(args[2], 8, placedTowersRecord)
                until spawnedTower or (tick() - searchStart > 1.5)
            end

            if not spawnedTower and (result == false or result == nil) then
                logConsole("[REC WARN] SpawnTower gagal (Uang kurang / invalid). Aksi diabaikan.")
                return result
            end

            table.insert(placedTowersRecord, spawnedTower)
            local towerIndex = #placedTowersRecord

            if #recordedActions == 0 then
                recordStartTime = tick()
                currentTime = 0
                end

                if not spawnedTower and args[2] then
                local searchStart = tick()
                repeat
                    task.wait(0.05)
                    spawnedTower = findTowerByPosition(args[2], 8, placedTowersRecord)
                until spawnedTower or (tick() - searchStart > 1.5)
            end

            if not spawnedTower and (result == false or result == nil) then
                logConsole("[REC WARN] SpawnTower gagal (Uang kurang / invalid). Aksi diabaikan.")
                return result
            end

            table.insert(placedTowersRecord, spawnedTower)
            local towerIndex = #placedTowersRecord

            if #recordedActions == 0 then
                recordStartTime = tick()
                currentTime = 0
            end

            table.insert(recordedActions, {
                actionType = "Place",
                time = currentTime,
                towerIndex = towerIndex,
                towerName = args[1],
                cframe = args[2],
                arg3 = args[3],
                arg4 = args[4],
                arg5 = args[5]
            })

            logConsole(string.format("[REC] Place Tower #%d: %s", towerIndex, tostring(args[1])))
            StatusLabel.Text = string.format("Status: Recording...\n[Aksi %d] Place: %s (ID: #%d)", #recordedActions, tostring(args[1]), towerIndex)

            return result

        elseif self.Name == "UpgradeTower" then
            local result = rawNamecall(self, ...)

            if result == false then
                logConsole("[REC WARN] Upgrade ditolak server (Uang kurang/Max). Aksi diabaikan.")
                return result
            end

            local targetTower = args[1]
            local towerName = args[2]

            local towerIndex = getTowerIndexFromRecord(targetTower)

            if not towerIndex and targetTower then
                local targetPos = nil
                if typeof(targetTower) == "Instance" then
                    local primaryPart = targetTower.PrimaryPart or targetTower:FindFirstChildWhichIsA("BasePart")
                    if primaryPart then targetPos = primaryPart.Position end
                end

                if targetPos then
                    local shortestDistance = 8
                    for idx, recTower in pairs(placedTowersRecord) do
                        if recTower and recTower:IsDescendantOf(Workspace) then
                            local recPart = recTower.PrimaryPart or recTower:FindFirstChildWhichIsA("BasePart")
                            if recPart then
                                local dist = (recPart.Position - targetPos).Magnitude
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    towerIndex = idx
                                end
                            end
                        end
                    end
                end
            end

            if not towerIndex and #placedTowersRecord > 0 then
                towerIndex = #placedTowersRecord
            end

            if towerIndex then
                local extraArgs = {}
                for i = 2, #args do
                    table.insert(extraArgs, args[i])
                end

                local towerCFrame = nil
                if targetTower and typeof(targetTower) == "Instance" then
                    local primaryPart = targetTower.PrimaryPart or targetTower:FindFirstChildWhichIsA("BasePart")
                    if primaryPart then towerCFrame = primaryPart.CFrame end
                end

                table.insert(recordedActions, {
                    actionType = "Upgrade",
                    time = currentTime,
                    towerIndex = towerIndex,
                    towerName = towerName,
                    cframe = towerCFrame,
                    extraArgs = extraArgs
                })

                logConsole(string.format("[REC] Upgrade Tower #%d: %s", towerIndex, tostring(towerName)))
                StatusLabel.Text = string.format("Status: Recording...\n[Aksi %d] Upgrade Tower #%d", #recordedActions, towerIndex)
            else
                logConsole("[REC WARN] Upgrade gagal direkam: Tidak ada tower yang terdaftar.")
            end

            return result
        end
    end

    return rawNamecall(self, ...)
end)

-- ==========================================
-- PLAYBACK ENGINE
-- ==========================================
playMacro = function(macroName)
    if isPlaying or isRecording then return end

    local loadSuccess = true
    if macroName and macroName ~= "" then
        loadSuccess = loadMacroFromFile(macroName)
    end

    if not loadSuccess or #recordedActions == 0 then
        StatusLabel.Text = "Status: Macro Kosong / Tidak dapat dimuat!"
        return
    end

    local functionsFolder = ReplicatedStorage:FindFirstChild("Functions")
    local spawnRemote = functionsFolder and functionsFolder:FindFirstChild("SpawnTower")
    local upgradeRemote = functionsFolder and functionsFolder:FindFirstChild("UpgradeTower")

    if not spawnRemote or not upgradeRemote then
        StatusLabel.Text = "Status: Remote Error\nGame belum siap!"
        return
    end

    setGameSpeed(currentSpeedMultiplier)
    isPlaying = true
    placedTowersPlay = {}
    local globalPlaceActions = {}
    logConsole("--- Memulai Playback Macro ---")

    task.spawn(function()
        local playStartTime = tick()

        for index, action in ipairs(recordedActions) do
            if not isPlaying then break end

            local targetTime = action.time / currentSpeedMultiplier
            local timeToWait = targetTime - (tick() - playStartTime)

            while timeToWait > 0 and isPlaying do
                targetTime = action.time / currentSpeedMultiplier
                timeToWait = targetTime - (tick() - playStartTime)

                StatusLabel.Text = string.format("Status: Playing (%s)\n[%d/%d] Next: %s\nWait: %.1fs", 
                    selectedMacroFile ~= "" and selectedMacroFile or "Current Session", index, #recordedActions, action.actionType, math.max(timeToWait, 0))
                task.wait(math.min(timeToWait, 0.05))
            end

            if not isPlaying then break end

            if action.actionType == "Place" then
                globalPlaceActions[action.towerIndex] = action
                StatusLabel.Text = string.format("Status: Playing...\n[%d/%d] Place Tower #%d", index, #recordedActions, action.towerIndex)

                local newTowerInstance = nil
                local maxAttempts = 600

                for attempt = 1, maxAttempts do
                    if not isPlaying then break end

                    local ignoreList = getPlacedTowersPlayList(action.towerIndex)

                    if action.cframe then
                        newTowerInstance = findTowerByPosition(action.cframe, 8, ignoreList)
                    end

                    if not newTowerInstance then
                        local result = spawnRemote:InvokeServer(
                            action.towerName,
                            action.cframe,
                            action.arg3,
                            action.arg4,
                            action.arg5
                        )

                        if typeof(result) == "Instance" then
                            newTowerInstance = result
                        elseif typeof(result) == "table" and result[1] then
                            newTowerInstance = result[1]
                        end

                        if not newTowerInstance and action.cframe then
                            local searchStart = tick()
                            repeat
                                task.wait(0.05)
                                newTowerInstance = findTowerByPosition(action.cframe, 8, ignoreList)
                            until newTowerInstance or (tick() - searchStart > 1.5)
                        end
                     end 
                    if newTowerInstance then
                        placedTowersPlay[action.towerIndex] = newTowerInstance
                        logConsole(string.format("[PLAY %d/%d] Placed Tower #%d: %s", index, #recordedActions, action.towerIndex, tostring(newTowerInstance)))
                        break
                    else
                        StatusLabel.Text = string.format("Status: Waiting Cash...\n[%d/%d] Place Tower #%d\nRetry (%d/%d)", index, #recordedActions, action.towerIndex, attempt, maxAttempts)
                        task.wait(0.2)
                    end
                end

                if not newTowerInstance then
                    logConsole(string.format("[PLAY ERROR] Gagal Place Tower #%d setelah %d percobaan!", action.towerIndex, maxAttempts))
                end

            elseif action.actionType == "Upgrade" then
                StatusLabel.Text = string.format("Status: Playing...\n[%d/%d] Upgrade Tower #%d", index, #recordedActions, action.towerIndex)

                local successUpgrade = false
                local maxAttempts = 300

                for attempt = 1, maxAttempts do
                    if not isPlaying then break end

                    local targetTower = placedTowersPlay[action.towerIndex]

                    if not targetTower or not targetTower:IsDescendantOf(Workspace) then
                        local targetCFrame = action.cframe

                        if not targetCFrame and globalPlaceActions[action.towerIndex] then
                            targetCFrame = globalPlaceActions[action.towerIndex].cframe
                        end

                        if not targetCFrame then
                            for _, act in ipairs(recordedActions) do
                                if act.actionType == "Place" and act.towerIndex == action.towerIndex then
                                    targetCFrame = act.cframe
                                    break
                                end
                            end
                        end

                        if targetCFrame then
                            local ignoreList = getPlacedTowersPlayList(action.towerIndex)
                            local currentRadius = (attempt > 10) and 15 or 8
                            targetTower = findTowerByPosition(targetCFrame, currentRadius, ignoreList)
                            
                            if targetTower then
                                placedTowersPlay[action.towerIndex] = targetTower
                            end
                        end
                    end

                    if targetTower then
                        local isMaxLevel = false
                        pcall(function()
                            if targetTower:GetAttribute("Max") == true or targetTower:GetAttribute("IsMax") == true then
                                isMaxLevel = true
                            elseif targetTower:FindFirstChild("Max") or targetTower:FindFirstChild("IsMax") then
                                isMaxLevel = true
                            end
                        end)

                        if isMaxLevel then
                            logConsole(string.format("[PLAY MAX DETECTED] Tower #%d sudah MAX. Menyeberang ke aksi berikutnya.", action.towerIndex))
                            successUpgrade = true
                            break
                        end

                        local res
                        if action.extraArgs and #action.extraArgs > 0 then
                            res = upgradeRemote:InvokeServer(targetTower, unpack(action.extraArgs))
                        else
                            res = upgradeRemote:InvokeServer(targetTower, action.towerName)
                        end
                        
                        if res == false then
                            res = upgradeRemote:InvokeServer(targetTower)
                        end

                        if res ~= false and res ~= nil then
                            successUpgrade = true
                            logConsole(string.format("[PLAY %d/%d] Upgraded Tower #%d (%s)", index, #recordedActions, action.towerIndex, targetTower.Name))
                            break
                        end
                    end

                    StatusLabel.Text = string.format("Status: Waiting Cash for Upgrade...\n[%d/%d] Upgrade Tower #%d\nAttempt (%d/%d)", index, #recordedActions, action.towerIndex, attempt, maxAttempts)
                    task.wait(0.25)
                end

                if not successUpgrade then
                    logConsole(string.format("[PLAY TIMEOUT] Upgrade Tower #%d dilewati setelah batas waktu habis.", action.towerIndex))
                end
            end
        end

        logConsole("--- Playback Macro Selesai ---")
        StatusLabel.Text = "Status: Playback Finished!"
        isPlaying = false
    end)
end

-- ==========================================
-- BUTTON EVENTS
-- ==========================================
RecordBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    if not isRecording then
        isRecording = true
        recordedActions = {}
        placedTowersRecord = {}

        local towersFolder = Workspace:FindFirstChild("Towers") or Workspace
        for _, obj in ipairs(towersFolder:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                if primaryPart and (obj:FindFirstChild("Humanoid") or obj:GetAttribute("Tower") or string.find(string.lower(obj.Name), "tower")) then
                    table.insert(placedTowersRecord, obj)
                end
            end
        end

        recordStartTime = tick()
        RecordBtn.Text = "Recording... (Stop)"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StatusLabel.Text = "Status: Recording Started...\nPasang unit pertama kamu!"
    else
        isRecording = false
        RecordBtn.Text = "Record"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        StatusLabel.Text = string.format("Status: Recording Finished!\nTotal Aksi: %d", #recordedActions)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        isPlaying = false
        StatusLabel.Text = "Status: Playback Dihentikan."
        return
    end

    if not isRecording then
        if selectedMacroFile ~= "" then
            playMacro(selectedMacroFile)
        elseif #recordedActions > 0 then
            playMacro("")
        else
            StatusLabel.Text = "Status: Pilih/Load Macro terlebih dahulu!"
        end
    end
end)

SaveBtn.MouseButton1Click:Connect(function()
    if SaveNameBox.Text ~= "" then saveMacroToFile(SaveNameBox.Text) end
end)

RefreshBtn.MouseButton1Click:Connect(function()
    if not supportsFileSystem then return end
    local files = listfiles(FOLDER_NAME)
    local fileList = {}
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name and name ~= "config" then table.insert(fileList, name) end
    end
    if #fileList > 0 then
        local currentIndex = table.find(fileList, selectedMacroFile) or 0
        local nextIndex = (currentIndex % #fileList) + 1
        loadMacroFromFile(fileList[nextIndex])
        saveConfigToFile()
    end
end)

DeleteBtn.MouseButton1Click:Connect(function()
    if not supportsFileSystem then
        StatusLabel.Text = "Status: Executor tidak mendukung FileSystem!"
        return
    end

    if selectedMacroFile == "" then
        StatusLabel.Text = "Status: Pilih/Load file macro terlebih dahulu!"
        return
    end

    local path = FOLDER_NAME .. "/" .. selectedMacroFile .. ".json"
    if isfile(path) then
        local deletedName = selectedMacroFile
        delfile(path)
        
        selectedMacroFile = ""
        recordedActions = {}
        SelectLabel.Text = "Selected: None"
        StatusLabel.Text = string.format("Status: File '%s.json' berhasil dihapus!", deletedName)
        saveConfigToFile()
    else
        StatusLabel.Text = "Status: File tidak ditemukan!"
    end
end)

AutoPlayBtn.MouseButton1Click:Connect(function()
    isAutoPlayEnabled = not isAutoPlayEnabled
    updateAutoPlayUI()
    saveConfigToFile()
end)

SpeedBtn.MouseButton1Click:Connect(function()
    if currentSpeedMultiplier == 1 then
        currentSpeedMultiplier = 2
    elseif currentSpeedMultiplier == 2 then
        currentSpeedMultiplier = 5
    else
        currentSpeedMultiplier = 1
    end
    
    SpeedBtn.Text = "Speed: " .. currentSpeedMultiplier .. "x"
    SpeedBtn.BackgroundColor3 = (currentSpeedMultiplier > 1) and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
    
    setGameSpeed(currentSpeedMultiplier)
    saveConfigToFile()
end)

AutoVoteBtn.MouseButton1Click:Connect(function()
    isAutoVoteEnabled = not isAutoVoteEnabled
    AutoVoteBtn.Text = isAutoVoteEnabled and "Vote ON" or "Vote OFF"
    AutoVoteBtn.BackgroundColor3 = isAutoVoteEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
    saveConfigToFile()
end)

AutoVoteDiffBtn.MouseButton1Click:Connect(function()
    isAutoVoteDiffEnabled = not isAutoVoteDiffEnabled
    AutoVoteDiffBtn.Text = isAutoVoteDiffEnabled and "Diff ON" or "Diff OFF"
    AutoVoteDiffBtn.BackgroundColor3 = isAutoVoteDiffEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
    saveConfigToFile()
end)

AutoSummonBtn.MouseButton1Click:Connect(function()
    isAutoSummonEnabled = not isAutoSummonEnabled
    AutoSummonBtn.Text = isAutoSummonEnabled and "Auto Summon (10x): ON" or "Auto Summon (10x): OFF"
    AutoSummonBtn.BackgroundColor3 = isAutoSummonEnabled and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(100, 40, 40)
    saveConfigToFile()
end)

loadConfigFromFile()

-- ==========================================
-- SMART AUTO VOTE MAP FUNCTION
-- ==========================================
local function executeMapVote()
    local mapInput = MapNameBox.Text
    local voteMapRemote = getEventRemote({"VoteForMap", "VoteMap"})
    if not voteMapRemote then return end

    local targetChoice = nil
    local numInput = tonumber(mapInput)

    if numInput then
        targetChoice = numInput
    else
        pcall(function()
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (string.find(string.lower(gui.Name), "vote") or string.find(string.lower(gui.Name), "map")) then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and string.find(string.lower(desc.Text), string.lower(mapInput)) then
                            local slotNum = desc.Name:match("%d+") or (desc.Parent and desc.Parent.Name:match("%d+"))
                            if slotNum then
                                targetChoice = tonumber(slotNum) or slotNum
                                break
                            end
                        end
                    end
                end
            end
        end)
    end

    pcall(function()
        if targetChoice then
            voteMapRemote:FireServer(targetChoice)
            logConsole(string.format("Auto Vote Map dikirim via Slot/Pilihan: %s", tostring(targetChoice)))
        else
            voteMapRemote:FireServer(mapInput)
            logConsole("Auto Vote Map dikirim via Nama String: " .. mapInput)
        end
    end)
end

-- ==========================================
-- AUTO SUMMON LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(2)
        if isAutoSummonEnabled then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local summonFolder = remotes and remotes:FindFirstChild("Summon")
                local summonRemote = summonFolder and summonFolder:FindFirstChild("Summon")

                if summonRemote then
                    summonRemote:InvokeServer(10)
                    logConsole("Auto Summon (10x) dieksekusi")
                end
            end)
        end
    end
end)

-- ==========================================
-- AUTO PLAY & VOTE LOOP
-- ==========================================
local function isMatchActuallyStarted()
    local functionsFolder = ReplicatedStorage:FindFirstChild("Functions")
    local spawnRemote = functionsFolder and functionsFolder:FindFirstChild("SpawnTower")
    local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Board")
    return (spawnRemote ~= nil and mapFolder ~= nil)
end

task.spawn(function()
    while true do
        task.wait(1)

        if (isAutoVoteEnabled or isAutoVoteDiffEnabled) and not hasVotedThisSession then
            hasVotedThisSession = true
            task.spawn(function()
                if isAutoVoteEnabled then
                    for attempt = 1, 3 do
                        executeMapVote()
                        task.wait(0.5)
                    end
                end

                task.wait(5)

                if isAutoVoteDiffEnabled then
                    local voteDiffRemote = getEventRemote({"VoteForComplication", "VoteComplication"})
                    if voteDiffRemote then
                        for attempt = 1, 5 do
                            pcall(function()
                                voteDiffRemote:FireServer(DiffNameBox.Text)
                            end)
                            logConsole(string.format("Auto Vote Difficulty (%d/5) dikirim: %s", attempt, DiffNameBox.Text))
                            task.wait(1)
                        end
                    end
                end
            end)
        end

        if isMatchActuallyStarted() then
            setGameSpeed(currentSpeedMultiplier)

            if isAutoPlayEnabled and not isPlaying and not isRecording and not hasAutoPlayedThisSession then
                hasAutoPlayedThisSession = true
                for i = 13, 1, -1 do
                    StatusLabel.Text = string.format("Status: Match Detected!\nWaiting Spawn Buffer: %d s", i)
                    task.wait(1)
                end

                if selectedMacroFile ~= "" then
                    playMacro(selectedMacroFile)
                elseif #recordedActions > 0 then
                    playMacro("")
                else
                    logConsole("[AUTO PLAY WARN] Tidak ada macro yang terpilih/tersimpan!")
                end
            end
        else
            hasAutoPlayedThisSession = false
            hasVotedThisSession = false
        end
    end
end)
