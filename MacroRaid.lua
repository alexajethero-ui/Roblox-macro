-- =============================================================================
-- 🌟 SLOP TD MACRO RAID - PART 1: MODULE SCREEN & BUTTON UI
-- =============================================================================

local MacroGui = {}

function MacroGui.CreateUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Proteksi System: Pengecekan PlayerGui agar Skrip Tidak Stuck
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then 
        warn("[Slop UI]: Gagal menemukan PlayerGui.")
        return nil
    end

    -- Membersihkan UI lama jika ada sisa eksekusi sebelumnya
    if playerGui:FindFirstChild("TowerMacroUI_Advanced") then
        playerGui.TowerMacroUI_Advanced:Destroy()
    end

    -- Elemen Utama Layar UI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TowerMacroUI_Advanced"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

    -- Bingkai Utama Menu (Compact & Bisa Digeser)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 240, 0, 310)
    MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Bar Atas (Judul & Navigasi Kontrol)
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

    -- Tombol Perkecil Menu (-)
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

    -- Tombol Keluar (X)
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

    -- Kontainer Penampung Tombol
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

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

    -- Alokasi Tombol
    local RecordBtn   = createButton("🔴 Record Macro", 10, Color3.fromRGB(219, 68, 85))
    local PlayBtn     = createButton("▶️ Play Macro", 45, Color3.fromRGB(68, 189, 50), Enum.Font.SourceSansBold)
    local AutoBtn     = createButton("🤖 Autoplay: OFF", 80, Color3.fromRGB(72, 84, 96), Enum.Font.SourceSansBold)
    local SpeedBtn    = createButton("⚡ Speed: 1x", 115, Color3.fromRGB(241, 196, 15), Enum.Font.SourceSansBold)
    local PlaceKeyBtn = createButton("🏗️ Placement Key: E", 150, Color3.fromRGB(70, 70, 70))
    local SaveBtn     = createButton("💾 Save Macro", 185, Color3.fromRGB(155, 89, 182))

    -- Indikator teks status peta di bagian paling bawah
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 50)
    StatusLabel.Position = UDim2.new(0.05, 0, 0, 225)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    StatusLabel.Text = "Map Terdeteksi: Menunggu...\nStatus: Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 12
    StatusLabel.TextWrapped = true
    StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatusLabel.Parent = ContentFrame
    Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

    -- Logika perkecil menu saat klik (-)
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
    end)

    return {
        RecordBtn = RecordBtn,
        PlayBtn = PlayBtn,
        AutoBtn = AutoBtn,
        SpeedBtn = SpeedBtn,
        PlaceKeyBtn = PlaceKeyBtn,
        SaveBtn = SaveBtn,
        StatusLabel = StatusLabel
    }
end

return MacroGui
