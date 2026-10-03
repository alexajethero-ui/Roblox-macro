-- =============================================================================
-- 🌟 SLOP TD MACRO RAID STARLARP - TAHAP 1: LAYAR & UI UTAMA
-- =============================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- System Safety: Pengecekan PlayerGui agar Skrip Tidak Stuck/Crash
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
if not playerGui then 
    warn("[Slop Macro]: Gagal menemukan PlayerGui. Skrip dihentikan.")
    return 
end

-- Membersihkan UI lama jika ada sisa eksekusi sebelumnya
if playerGui:FindFirstChild("TowerMacroUI_Advanced") then
    playerGui.TowerMacroUI_Advanced:Destroy()
end

-- ==========================================
-- 🏗️ PEMBUATAN ELEMENT INTERFACE (UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerMacroUI_Advanced"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Main Frame (Compact, Modern, & Bisa Digeser)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 310) -- Ukuran pas, tidak memakan tempat
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0) -- Berada di posisi kiri tengah layar
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar Frame (Bagian Judul & Navigasi)
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
Title.Text = "🌟 SLOP TD MACRO RAID"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button (-)
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

-- Close Button (X)
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

-- Container Utama untuk Konten Tombol
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Fungsi Helper Pembuat Tombol Agar Ukuran & Font Konsisten
local function createButton(text, posTop, bgColor, fontStyle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, posTop)
    btn.BackgroundColor3 = bgColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = fontStyle or Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = ContentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

-- Menambahkan 6 Tombol Utama Sesuai Spesifikasi Fitur Makro Anda
local RecordBtn  = createButton("🔴 Record Macro", 10, Color3.fromRGB(50, 150, 50))
local PlayBtn    = createButton("▶️ Play Macro", 45, Color3.fromRGB(50, 100, 200), Enum.Font.SourceSansBold)
local AutoBtn    = createButton("🤖 Autoplay: OFF", 80, Color3.fromRGB(100, 40, 40), Enum.Font.SourceSansBold)
local SpeedBtn   = createButton("⚡ Speed: 1x", 115, Color3.fromRGB(100, 40, 40), Enum.Font.SourceSansBold)
local PlaceKeyBtn = createButton("🏗️ Placement Key: E", 150, Color3.fromRGB(70, 70, 70))
local SaveBtn    = createButton("💾 Save Macro", 185, Color3.fromRGB(180, 120, 30))

-- Info Board Label (Status Real-time untuk memantau Map/Raid)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 50)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 225)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.Text = "Map Terdeteksi: Menunggu...\nStatus: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = ContentFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

-- ==========================================
-- 🛠️ UI LOGIC EVENTS (MINIMIZE & CLOSE)
-- ==========================================
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 240, 0, 30)
        ContentFrame.Visible = false
        MinimizeBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 240, 0, 310)
        ContentFrame.Visible = true
        MinimizeBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("[Slop Macro]: UI berhasil ditutup.")
end)

-- Safe Auto Minimize saat skrip pertama kali dijalankan agar rapi
task.defer(function()
    task.wait(0.5)
    isMinimized = true
    MainFrame.Size = UDim2.new(0, 240, 0, 30)
    ContentFrame.Visible = false
    MinimizeBtn.Text = "+"
end)

print("[Slop Macro]: Tahap 1 (Layar & Tombol UI) berhasil dimuat!")
