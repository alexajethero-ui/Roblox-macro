-- Memuat Library GUI Rayfield Resmi dan Stabil
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

-- Membuat Window Utama (Tombol minimize bawaan menggunakan tombol "Right Shift" pada keyboard)
local Window = Rayfield:CreateWindow({
   Name = "Auto Ability Menu by Starlarp",
   LoadingTitle = "Memuat Script...",
   LoadingSubtitle = "by GitHub Developer",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AutoAbilityConfig", -- Folder penyimpanan otomatis di folder 'workspace' exploit Anda
      FileName = "SettingAbility"
   },
   KeySystem = false
})

-- Membuat Tab Utama
local MainTab = Window:CreateTab("Main Features", 4483362458) -- ID Icon bawaan

-- Menggunakan variabel global biasa tanpa keyword 'local' agar tidak error
_G.AutoAbilityActive = false

-- Fungsi utama untuk menjalankan Ability secara terus-menerus
local function startAutoAbility()
    task.spawn(function()
        while _G.AutoAbilityActive do
            local args = {
                [1] = "Drones",
                [2] = workspace.Towers:FindFirstChild("Upgraded Titan Cinema Man")
            }
            
            -- Memastikan Tower tujuan terdeteksi di workspace sebelum memicu remote server
            if args[2] then
                pcall(function()
                    game:GetService("ReplicatedStorage").RemoteFunctions.CinemaRelocate:InvokeServer(unpack(args))
                end)
            end
            
            -- Jeda waktu tunggu pengulangan (delay 1 detik)
            task.wait(1) 
        end
    end)
end

-- Membuat Tombol On/Off (Toggle) yang otomatis menyimpan settingan terakhir
local Toggle = MainTab:CreateToggle({
   Name = "Auto Use Ability",
   CurrentValue = false,
   Flag = "ToggleAbility", -- ID unik yang digunakan oleh sistem auto-save
   Callback = function(Value)
      _G.AutoAbilityActive = Value
      if Value then
          Rayfield:Notify({Title = "Status", Content = "Auto Ability DIAKTIFKAN", Duration = 2})
          startAutoAbility()
      else
          Rayfield:Notify({Title = "Status", Content = "Auto Ability DINONAKTIFKAN", Duration = 2})
      end
   end,
})

-- Memuat otomatis konfigurasi sakelar terakhir saat script pertama kali di-run
Rayfield:LoadConfiguration()
