--// Sapphire Hub Loader
-- Wait until the game and player are fully loaded
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

-- FPS Boost
for _, v in pairs(game:GetDescendants()) do
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Enabled = false
    end
end
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

-- Supported games with place IDs and script URLs
local games = {
    [18172550962] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/pixel-blade.lua.txt",
    [94682676231618] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/My-fishing-Pier.lua.txt",
    [3623096087] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/muscle-legends.lua.txt",
    [142823291] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/mm2.lua.txt",
    [94845773826960] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/dungeon-heroes.lua.txt",
    [16732694052] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/fisch.lua.txt",
    [80343758583098] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/anime-rising.lua.txt",
    [101949297449238] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/build-an-island.lua.txt",
    [104067066727140] = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/Voxseas.lua"
}

-- Function to load the script for the current game
local scriptUrl = games[game.PlaceId]
if scriptUrl then
    loadstring(game:HttpGet(scriptUrl))()
else
    game.Players.LocalPlayer:Kick("❌ This game is not supported by Sapphire Hub.")
end
