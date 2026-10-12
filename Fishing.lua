local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingEvent = ReplicatedStorage.Fishing.Remotes.FishingEvent

local isHolding = false
local clickCounter = 0

-- Menggunakan tombol GUI khusus di layar ponsel
local reelButton = script.Parent 

reelButton.MouseButton1Down:Connect(function()
    isHolding = true
    
    -- Selama tombol ditahan, kirim data progres ke server secara berkala
    task.spawn(function()
        while isHolding do
            clickCounter = clickCounter + 1
            
            local args = {
                [1] = "Hit",
                [2] = {
                    ["Index"] = clickCounter,
                    ["ClickTime"] = os.clock()
                }
            }
            FishingEvent:FireServer(unpack(args))
            
            task.wait(0.3) -- Mengirim data setiap 0.3 detik (Pemain cukup menahan tombol)
        end
    end)
end)

-- Ketika pemain mengangkat jarinya dari tombol
reelButton.MouseButton1Up:Connect(function()
    isHolding = false
end)
