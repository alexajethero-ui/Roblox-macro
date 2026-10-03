-- ========================================================
-- TEMPLATE MACRO GUI WIDE PANEL - COMPACT VERTICAL BUTTONS
-- ========================================================

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ControlLayout = Instance.new("UIListLayout")

-- Konfigurasi ScreenGui
ScreenGui.Name = "MacroWidePanelVerticalGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 1. FRAME UTAMA (Memanjang ke samping: 500px, Tinggi disesuaikan ke bawah)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Dark Premium Theme
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0) -- Posisi di samping layar
MainFrame.Size = UDim2.new(0, 500, 0, 260) -- Layar lebar ke samping (500px)
MainFrame.Active = true
MainFrame.Draggable = true

-- Sudut melengkung halus panel utama
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

-- Border Neon Halus
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 200, 255) -- Cyan Neon
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4
mainStroke.Parent = MainFrame

-- 2. JUDUL MENU (Ikut melebar penuh ke samping)
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 28)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleLabel.Text = "   🌟 SLOP TD MACRORAID BY STARLARP"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = TitleLabel

-- 3. INTERFACE LAYOUT (Tombol TETAP ke Arah Bawah / Vertikal)
ControlLayout.Parent = MainFrame
ControlLayout.FillDirection = Enum.FillDirection.Vertical -- Kunci tombol tetap ke bawah
ControlLayout.Padding = UDim.new(0, 4) -- Jarak antar tombol dibuat rapat
ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Tombol di tengah panel

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 34) -- Di bawah judul
uiPadding.Parent = MainFrame

-- ==========================================
-- STATE VARIABLE
-- ==========================================
local isRecording, isPlaying, isAutoPlaying = false, false, false
local macroSpeed = 1.0
local selectedTower = "None"

-- ==========================================
-- FUNGSI PREMIUM BUTTON (RAMPING & TIDAK BESAR)
-- ==========================================
local function createCompactButton(name, text, startColor, endColor, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = MainFrame
    -- Lebar tombol 460px (mengikuti layar lebar), Tinggi hanya 22px (sangat ramping agar tidak memenuhi layar)
    btn.Size = UDim2.new(0, 460, 0, 22) 
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.LayoutOrder = layoutOrder
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.9
    stroke.Thickness = 1
    stroke.Parent = btn

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(startColor, endColor)
    gradient.Rotation = 0 -- Gradasi horizontal tipis
    gradient.Parent = btn
    
    return btn
end

-- ==========================================
-- PEMBUATAN TOMBOL VERTIKAL YANG SLIM
-- ==========================================
local RecordBtn   = createCompactButton("RecordBtn", "🔴 Record: OFF", Color3.fromRGB(150, 30, 30), Color3.fromRGB(90, 15, 15), 1)
local PlayBtn     = createCompactButton("PlayBtn", "▶️ Play Macro", Color3.fromRGB(30, 140, 60), Color3.fromRGB(15, 80, 30), 2)
local AutoplayBtn = createCompactButton("AutoplayBtn", "🔁 Autoplay: OFF", Color3.fromRGB(30, 80, 160), Color3.fromRGB(15, 45, 90), 3)
local TowerBtn    = createCompactButton("TowerBtn", "🗼 Target Tower: Default", Color3.fromRGB(140, 130, 30), Color3.fromRGB(80, 70, 15), 4)
local SpeedBtn    = createCompactButton("SpeedBtn", "⚡ Macro Speed: 1x", Color3.fromRGB(110, 40, 140), Color3.fromRGB(60, 20, 80), 5)
local SaveBtn     = createCompactButton("SaveBtn", "💾 Save Macro Data", Color3.fromRGB(70, 75, 80), Color3.fromRGB(40, 45, 50), 6)
local MinimizeBtn = createCompactButton("MinimizeBtn", "➖ Minimize Panel", Color3.fromRGB(50, 50, 55), Color3.fromRGB(30, 30, 35), 7)
local CloseBtn    = createCompactButton("CloseBtn", "❌ Close UI Completely", Color3.fromRGB(180, 40, 40), Color3.fromRGB(100, 20, 20), 8)

-- ==========================================
-- LOGIKA EVENT HANDLER
-- ==========================================

RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    local grad = RecordBtn:FindFirstChild("UIGradient")
    if isRecording then
        RecordBtn.Text = "🔴 RECORDING ACTIVE..."
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50), Color3.fromRGB(180, 0, 0)) end
    else
        RecordBtn.Text = "🔴 Record: OFF"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(150, 30, 30), Color3.fromRGB(90, 15, 15)) end
    end
end)

AutoplayBtn.MouseButton1Click:Connect(function()
    isAutoPlaying = not isAutoPlaying
    local grad = AutoplayBtn:FindFirstChild("UIGradient")
    if isAutoPlaying then
        AutoplayBtn.Text = "🔁 Autoplay: ON"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(0, 230, 120), Color3.fromRGB(0, 120, 60)) end
    else
        AutoplayBtn.Text = "🔁 Autoplay: OFF"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(30, 80, 160), Color3.fromRGB(15, 45, 90)) end
    end
end)

TowerBtn.MouseButton1Click:Connect(function()
    if selectedTower == "None" then selectedTower = "DPS"
    elseif selectedTower == "DPS" then selectedTower = "Support"
    else selectedTower = "None" end
    TowerBtn.Text = "🗼 Target Tower: " .. selectedTower
end)

SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1.0 then macroSpeed = 2.0
    elseif macroSpeed == 2.0 then macroSpeed = 5.0
    else macroSpeed = 1.0 end
    SpeedBtn.Text = "⚡ Macro Speed: " .. macroSpeed .. "x"
end)

-- Fungsi Melipat Menu (Minimize) ke Atas
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 500, 0, 28) -- Menyusut jadi garis horizontal tipis
        MinimizeBtn.Text = "➕ Maximize Panel"
        mainStroke.Color = Color3.fromRGB(255, 100, 0)
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "MinimizeBtn" then
                child.Visible = false
            end
        end
    else
        MainFrame.Size = UDim2.new(0, 500, 0, 260) -- Kembali ke tinggi normal
        MinimizeBtn.Text = "➖ Minimize Panel"
        mainStroke.Color = Color3.fromRGB(0, 200, 255)
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.Visible = true
            end
        end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

