--//============================================================
--// ROBLOX AUTO CINEMA RELOCATE v1.2 - Orion UI
--//============================================================

-- Memuat Library GUI Orion yang ringan dan stabil
local OrionLib = loadstring(game:HttpGet(('https://githubusercontent.com')))()
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Variabel status On/Off
_G.AutoRelocateActive = false

--//========== RESOLVE INSTANCE BERBASIS SPATIAL (DARI TEMPLATE ANDA) ==========
local function ResolveInstance(path, name, posData)
    if posData and type(posData) == "table" then
        local targetPos = Vector3.new(posData.x or 0, posData.y or 0, posData.z or 0)
        local closestObj = nil
        local shortestDist = math.huge

        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == name then
                local p = nil
                pcall(function()
                    if desc:IsA("Model") then
                        p = desc:GetPivot().Position
                    elseif desc:IsA("BasePart") then
                        p = desc.Position
                    end
                end)
                if p then
                    local dist = (p - targetPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestObj = desc
                    end
                end
            end
        end
        return closestObj
    end
    return workspace:FindFirstChild(name)
end

--//========== FUNGSI UTAMA LOOP RELOCATE ==========
local function startAutoRelocate()
    task.spawn(function()
        while _G.AutoRelocateActive do
            -- Mencari tower target berdasarkan hierarki game Anda
            local targetTower = workspace.Towers:FindFirstChild("Upgraded Titan Cinema Man")
            
            if targetTower then
                local args = {
                    [1] = "Drones",
                    [2] = targetTower
                }
                
                -- Memanggil RemoteFunction CinemaRelocate secara aman menggunakan pcall
                pcall(function()
                    ReplicatedStorage.RemoteFunctions.CinemaRelocate:InvokeServer(unpack(args))
                end)
            end
            
            -- Jeda waktu perulangan (1 detik), bisa disesuaikan kebutuhan
            task.wait(1)
        end
    end)
end

--//========== MEMBUAT WINDOW UTAMA ORION UI ==========
local Window = OrionLib:MakeWindow({
    Name = "Auto Cinema Relocate", 
    HidePremium = true, 
    SaveConfig = true,                -- Menyimpan settingan tombol secara otomatis
    ConfigFolder = "CinemaRelocate",  -- Folder simpanan di folder 'workspace' exploit Anda
    IntroEnabled = false              -- Menu langsung terbuka instan saat di-run
})

--//========== MEMBUAT TAB UTAMA ==========
local MainTab = Window:MakeTab({ Name = "Main Settings", Icon = "rbxassetid://4483362458" })

--//========== TOMBOL ON/OFF DENGAN FITUR AUTO-SAVE SETTINGAN ==========
MainTab:AddToggle({
    Name = "Auto Relocate Tower",
    Default = false,
    Save = true,              -- Memastikan posisi terakhir (On/Off) tersimpan saat game di-run ulang
    Flag = "RelocateToggle",   -- ID Unik untuk konfigurasi penyimpanan
    Callback = function(Value)
        _G.AutoRelocateActive = Value
        if Value then
            OrionLib:MakeNotification({
                Name = "Status",
                Content = "Auto Cinema Relocate DIAKTIFKAN",
                Time = 2
            })
            startAutoRelocate()
        else
            OrionLib:MakeNotification({
                Name = "Status",
                Content = "Auto Cinema Relocate DINONAKTIFKAN",
                Time = 2
            })
        end
    end
})

--//========== INISIALISASI AKHIR GUI ==========
OrionLib:Init()
