-- ========================================================
-- TEMPLATE MACRO GUI HORIZONTAL STYLISH (CYBERPUNK GLOW)
-- ========================================================

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ControlLayout = Instance.new("UIListLayout")

-- Konfigurasi ScreenGui
ScreenGui.Name = "MacroHorizontalStylishGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 1. FRAME UTAMA (Desain Kaca Gelap / Dark Glossy)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Sangat gelap futuristik
MainFrame.Position = UDim2.new(0.15, 0, 0.05, 0)
MainFrame.Size = UDim2.new(0, 780, 0, 90) -- Penyesuaian ukuran tipis
MainFrame.Active = true
MainFrame.Draggable = true

-- Sudut melengkung halus untuk Frame Utama
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

-- Garis Tepi Neon Halus (Border Neon)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 200, 255) -- Warna biru neon
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4
mainStroke.Parent = MainFrame

-- 2. JUDUL MENU (Efek Header Elegan)
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 28)
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleLabel.Text = "   🌟SLOP TD MACRO RAID BY STARLARP"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold -- Font modern

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = TitleLabel

-- Pembatas bawah judul (Garis gradasi tipis)
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(80, 80, 90)
titleStroke.Thickness = 1
titleStroke.Parent = TitleLabel

-- 3. INTERFACE LAYOUT & PADDING
ControlLayout.Parent = MainFrame
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.Padding = UDim.new(0, 8)
ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 28)
uiPadding.PaddingLeft = UDim.new(0, 10)
uiPadding.Parent = MainFrame

-- ==========================================
-- STATE VARIABLE
-- ==========================================
local isRecording, isPlaying, isAutoPlaying = false, false, false
local macroSpeed = 1.0
local selectedTower = "None"

-- ==========================================
-- FUNGSI PREMIUM BUTTON (DENGAN GRADASI)
-- ==========================================
local function createStylishButton(name, text, startColor, endColor, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0, 88, 0, 48)
    btn.BackgroundColor3 = Color3.new(1, 1, 1) -- Harus putih agar gradasi muncul sempurna
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold -- Font tebal bergaya
    btn.TextSize = 11
    btn.TextWrapped = true
    btn.LayoutOrder = layoutOrder
    
    -- Efek Sudut Melengkung Tombol
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    -- Efek Garis Tepi Gelap pada Tombol
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.Thickness = 1
    stroke.Parent = btn

    -- 🌟 EFEK GRADASI WARNA (Membuat Tombol Berkilau/Glossy)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(startColor, endColor)
    gradient.Rotation = 45 -- Arah kemiringan gradasi
    gradient.Name = "BtnGradient"
    gradient.Parent = btn
    
    -- Efek Hover Sederhana (Berubah warna sedikit saat disentuh)
    btn.MouseEnter:Connect(function()
        gradient.Rotation = 90
    end)
    btn.MouseLeave:Connect(function()
        gradient.Rotation = 45
    end)
    
    return btn
end

-- ==========================================
-- PEMBUATAN ELEMEN TOMBOL KONTROL NEON
-- ==========================================
-- Format Warna: (Nama, Teks, Warna Atas, Warna Bawah, Urutan)
local RecordBtn   = createStylishButton("RecordBtn", "🔴 Record\nOFF", Color3.fromRGB(150, 30, 30), Color3.fromRGB(80, 10, 10), 1)
local PlayBtn     = createStylishButton("PlayBtn", "▶️ Play\nMacro", Color3.fromRGB(30, 140, 60), Color3.fromRGB(15, 70, 30), 2)
local AutoplayBtn = createStylishButton("AutoplayBtn", "🔁 Autoplay\nOFF", Color3.fromRGB(30, 80, 160), Color3.fromRGB(15, 40, 90), 3)
local TowerBtn    = createStylishButton("TowerBtn", "🗼 Target\nDefault", Color3.fromRGB(140, 130, 30), Color3.fromRGB(80, 70, 15), 4)
local SpeedBtn    = createStylishButton("SpeedBtn", "⚡ Speed\n1x", Color3.fromRGB(110, 40, 140), Color3.fromRGB(60, 20, 80), 5)
local SaveBtn     = createStylishButton("SaveBtn", "💾 Save\nData", Color3.fromRGB(70, 75, 80), Color3.fromRGB(40, 45, 50), 6)
local MinimizeBtn = createStylishButton("MinimizeBtn", "➖\nMinimize", Color3.fromRGB(50, 50, 55), Color3.fromRGB(30, 30, 35), 7)
local CloseBtn    = createStylishButton("CloseBtn", "❌\nClose", Color3.fromRGB(180, 40, 40), Color3.fromRGB(100, 20, 20), 8)

-- ==========================================
-- LOGIKA EVENT HANDLER & DINAMISASI WARNA
-- ==========================================

RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    local grad = RecordBtn:FindFirstChild("BtnGradient")
    if isRecording then
        RecordBtn.Text = "🔴 RECORDING"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50), Color3.fromRGB(180, 0, 0)) end
    else
        RecordBtn.Text = "🔴 Record\nOFF"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(150, 30, 30), Color3.fromRGB(80, 10, 10)) end
    end
end)

AutoplayBtn.MouseButton1Click:Connect(function()
    isAutoPlaying = not isAutoPlaying
    local grad = AutoplayBtn:FindFirstChild("BtnGradient")
    if isAutoPlaying then
        AutoplayBtn.Text = "🔁 Autoplay\nON"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(0, 230, 120), Color3.fromRGB(0, 120, 60)) end
    else
        AutoplayBtn.Text = "🔁 Autoplay\nOFF"
        if grad then grad.Color = ColorSequence.new(Color3.fromRGB(30, 80, 160), Color3.fromRGB(15, 40, 90)) end
    end
end)

TowerBtn.MouseButton1Click:Connect(function()
    if selectedTower == "None" then selectedTower = "DPS"
    elseif selectedTower == "DPS" then selectedTower = "Support"
    else selectedTower = "None" end
    TowerBtn.Text = "🗼 Target\n" .. selectedTower
end)

SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1.0 then macroSpeed = 2.0
    elseif macroSpeed == 2.0 then macroSpeed = 5.0
    else macroSpeed = 1.0 end
    SpeedBtn.Text = "⚡ Speed\n" .. macroSpeed .. "x"
end)

-- Melipat menu (Minimize) secara mulus
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 780, 0, 28)
        MinimizeBtn.Text = "➕\nMaximize"
        mainStroke.Color = Color3.fromRGB(255, 100, 0) -- Warna border berubah saat minimize
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "MinimizeBtn" then
                child.Visible = false
            end
        end
    else
        MainFrame.Size = UDim2.new(0, 780, 0, 90)
        MinimizeBtn.Text = "➖\nMinimize"
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

