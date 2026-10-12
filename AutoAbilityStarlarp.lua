-- Memuat Library GUI (Menggunakan Rayfield karena stabil dan mendukung auto-save)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

-- Membuat Window Utama (Sudah termasuk tombol Minimize bawaan di pojok kanan atas)
local Window = Rayfield:CreateWindow({
   Name = "Auto Ability Menu by Starlarp",
   LoadingTitle = "Memuat Script...",
   LoadingSubtitle = "by GitHub Developer",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AutoAbilityConfig", -- Folder penyimpanan di folder 'workspace' exploit Anda
      FileName = "SettingAbility"
   },
   KeySystem = false
})

-- Membuat Tab Utama
local MainTab = Window:CreateTab("Main Features", 4483362458) -- ID Icon

-- Variabel status On/Off
local _G.AutoAbilityActive = false

-- Fungsi utama untuk menjalankan Ability secara terus-menerus
local function startAutoAbility()
    task.spawn(function()
        while _G.AutoAbilityActive do
            local args = {
                [1] = "Drones",
                [2] = workspace.Towers:FindFirstChild("Upgraded Titan Cinema Man")
            }
            
            -- Memastikan Tower ada sebelum memanggil RemoteFunction agar tidak error
            if args[2] then
                pcall(function()
                    game:GetService("ReplicatedStorage").RemoteFunctions.CinemaRelocate:InvokeServer(unpack(args))
                end)
            end
            
            -- Jeda waktu (delay) antar serangan/ability (bisa disesuaikan, misal 1 detik)
            task.wait(1) 
        end
    end)
end

-- Membuat Tombol On/Off (Toggle) yang otomatis menyimpan settingan terakhir
local Toggle = MainTab:CreateToggle({
   Name = "Auto Use Ability",
   CurrentValue = false,
   Flag = "ToggleAbility", -- Digunakan sebagai ID untuk auto-save
   Callback = function(Value)
      _G.AutoAbilityActive = Value
      if Value then
          Rayfield:Notify({Title = "Status", Content = "Auto Ability DIAKTIFKAN", Duration = 2})
          startAutoAbility()
      else
          Rayfield:Notify({Title = "Status", Content = "Auto Ability DINONAKTIFKAN", Duration = 2})
      end
    host.Value = Value
   end,
})

-- Memuat otomatis settingan terakhir saat script pertama kali di-run
Rayfield:LoadConfiguration()
