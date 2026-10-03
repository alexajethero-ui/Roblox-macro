-- ==========================================
-- TEMPLATE MACRO GUI (SLOP TOWER DEFENSE)
-- ==========================================

-- 1. UTAMA: Membuat ScreenGui dan Frame Utama
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ControlLayout = Instance.new("UIListLayout")

-- Konfigurasi ScreenGui agar muncul di layar pemain
ScreenGui.Name = "MacroSystemGui"
ScreenGui.Parent = game.CoreGui -- Menggunakan CoreGui agar tidak terhapus saat reset
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Desain Frame Utama (Tempat Tombol)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 320)
MainFrame.Active = true
MainFrame.Draggable = true -- Membuat GUI bisa digeser/drag di layar

-- Judul GUI
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "SLOP TD MACRO RAID STARLA V1"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold

-- Layout Otomatis untuk Tombol-Tombol
ControlLayout.Parent = MainFrame
ControlLayout.Padding = UDim.new(0, 5)
ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ==========================================
-- 2. STATE VARIABLE (Penyimpanan Data Macro)
-- ==========================================
local isRecording = false
local isPlaying = false
local isAutoPlaying = false
local macroSpeed = 1.0
local selectedTower = "None"
local recordedData = {} -- Menyimpan koordinat, waktu, dan aksi tower

-- ==========================================
-- 3. FUNGSI PEMBUAT TOMBOL ELEKTIF (REUSABLE)
-- ==========================================
local function createButton(name, text, color, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0, 180, 0, 35)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.LayoutOrder = layoutOrder
    
    -- Efek Sudut Melengkung Ringan
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

-- ==========================================
-- 4. PEMBUATAN ELEMEN BUTTON & KONTROL
-- ==========================================
local RecordBtn   = createButton("RecordBtn", "🔴 Record: OFF", Color3.fromRGB(180, 40, 40), 1)
local PlayBtn     = createButton("PlayBtn", "▶️ Play Macro", Color3.fromRGB(40, 140, 40), 2)
local AutoplayBtn = createButton("AutoplayBtn", "🔁 Autoplay: OFF", Color3.fromRGB(50, 50, 180), 3)
local SpeedBtn    = createButton("SpeedBtn", "⚡ Speed: 1x", Color3.fromRGB(100, 50, 150), 4)
local TowerBtn    = createButton("TowerBtn", "🗼 Tower: Default", Color3.fromRGB(120, 120, 30), 5)
local SaveBtn     = createButton("SaveBtn", "💾 Save Macro", Color3.fromRGB(80, 80, 80), 6)
local MinimizeBtn = createButton("MinimizeBtn", "➖ Minimize", Color3.fromRGB(60, 60, 65), 7)
local CloseBtn    = createButton("CloseBtn", "❌ Close UI", Color3.fromRGB(40, 40, 45), 8)

-- Padding atas agar layout tidak menabrak judul
local topPadding = Instance.new("UIPadding")
topPadding.PaddingTop = UDim.new(0, 35)
topPadding.Parent = MainFrame

-- ==========================================
-- 5. LOGIKA UTAMA & EVENT HANDLER
-- ==========================================

-- Fungsi Perekaman (Record)
RecordBtn.MouseButton1Click:Connect(function()
    isRecording = not isRecording
    if isRecording then
        RecordBtn.Text = "🔴 Recording..."
        RecordBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        recordedData = {} -- Reset data lama
        print("Mulai merekam macro placement tower...")
        -- Tulis logika tracking klik/tempatkan tower Anda di sini
    else
        RecordBtn.Text = "🔴 Record: OFF"
        RecordBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        print("Rekaman selesai. Total aksi tersimpan: " .. #recordedData)
    end
end)

-- Fungsi Pemutaran Rekaman (Play / MacroPlayback)
PlayBtn.MouseButton1Click:Connect(function()
    if isRecording then return end
    isPlaying = true
    print("Memutar macro dengan kecepatan: " .. macroSpeed .. "x")
    
    -- Simulasi Playback Berdasarkan Kecepatan (Speed)
    task.spawn(function()
        for i, action in ipairs(recordedData) do
            if not isPlaying then break end
            -- task.wait(action.delay / macroSpeed) 
            -- Eksekusi penempatan tower di sini
        end
        isPlaying = false
    end)
end)

-- Fungsi Putar Otomatis Terus Menerus (Autoplay)
AutoplayBtn.MouseButton1Click:Connect(function()
    isAutoPlaying = not isAutoPlaying
    if isAutoPlaying then
        AutoplayBtn.Text = "🔁 Autoplay: ON"
        AutoplayBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        print("Autoplay diaktifkan. Akan otomatis restart macro saat game selesai.")
    else
        AutoplayBtn.Text = "🔁 Autoplay: OFF"
        AutoplayBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 180)
    end
end)

-- Pengatur Kecepatan Macro (Speed)
SpeedBtn.MouseButton1Click:Connect(function()
    if macroSpeed == 1.0 then
        macroSpeed = 2.0
    elseif macroSpeed == 2.0 then
        macroSpeed = 5.0
    else
        macroSpeed = 1.0
    end
    SpeedBtn.Text = "⚡ Speed: " .. macroSpeed .. "x"
end)

-- Pemilihan Jenis Tower (Tower Selection)
TowerBtn.MouseButton1Click:Connect(function()
    -- Contoh simulasi pergantian target tower yang ingin dipasang
    if selectedTower == "None" then
        selectedTower = "DPS Tower"
    elseif selectedTower == "DPS Tower" then
        selectedTower = "Support Tower"
    else
        selectedTower = "None"
    end
    TowerBtn.Text = "🗼 Tower: " .. selectedTower
end)

-- Menyimpan Data ke Storage (Save)
SaveBtn.MouseButton1Click:Connect(function()
    print("Menyimpan konfigurasi macro ke local storage executor...")
    -- Jika executor Anda mendukung writefile, Anda bisa menyimpannya menjadi file .txt/.json
    -- writefile("SlopTD_Macro.txt", game:GetService("HttpService"):JSONEncode(recordedData))
end)

-- Mengecilkan GUI (Minimize)
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 200, 0, 30) -- Hanya menyisakan judul saja
        MinimizeBtn.Text = "➕ Maximize"
        -- Sembunyikan semua tombol di bawah judul
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "MinimizeBtn" then
                child.Visible = false
            end
        end
    else
        MainFrame.Size = UDim2.new(0, 200, 0, 320) -- Kembali ke ukuran semula
        MinimizeBtn.Text = "➖ Minimize"
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.Visible = true
            end
        end
    end
end)

-- Menutup UI Sepenuhnya (Close)
CloseBtn.MouseButton1Click:Connect(function()
    print("Menutup GUI Macro.")
    ScreenGui:Destroy()
end)

