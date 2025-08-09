-- Roblox Place-ID-only Loader (Luau)
-- Features: Wait for player & map load, FPS boost, loadstring/load fallback, no GUI

-- == CONFIG == --
local URLs = {
    ["pixel-blade"]       = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/pixel-blade.lua.txt",
    ["my-fishing-pier"]   = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/My-fishing-Pier.lua.txt",
    ["muscle-legends"]    = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/muscle-legends.lua.txt",
    ["mm2"]               = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/mm2.lua.txt",
    ["dungeon-heroes"]    = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/dungeon-heroes.lua.txt",
    ["fisch"]             = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/fisch.lua.txt",
    ["anime-rising"]      = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/anime-rising.lua.txt",
    ["build-an-island"]   = "https://raw.githubusercontent.com/SapphireDevgg/Loader/refs/heads/main/build-an-island.lua.txt",
}

local PlaceIdMap = {
    ["pixel-blade"]       = { 18172550962 },
    ["my-fishing-pier"]   = { 94682676231618 },
    ["muscle-legends"]    = { 3623096087 },
    ["mm2"]               = { 142823291 },
    ["dungeon-heroes"]    = { 94845773826960 },
    ["fisch"]             = { 16732694052, 106011698424775 },
    ["anime-rising"]      = { 80343758583098 },
    ["build-an-island"]   = { 101949297449238 },
}

-- == REVERSE LOOKUP ==
local placeToKey = {}
for key, idList in pairs(PlaceIdMap) do
    for _, pid in ipairs(idList) do
        placeToKey[pid] = key
    end
end

-- == UTILS ==
local function http_get(url)
    if game.HttpGet then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then return res end
    end
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request{Url = url, Method = "GET"} end)
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(function() return request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    if http and http.request then
        local ok, res = pcall(function() return http.request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    if http_request then
        local ok, res = pcall(function() return http_request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    error("No supported HTTP method.")
end

local function run_code(src)
    if not src or src == "" then return false, "empty_source" end
    local loader = loadstring or load
    if not loader then return false, "no_loader" end
    local fn, err = loader(src)
    if not fn then return false, err end
    local ok, runtimeErr = pcall(fn)
    if not ok then return false, runtimeErr end
    return true
end

local function fps_boost()
    -- Remove textures/decals
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Texture") or v:IsA("Decal") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
            v.Rate = 0
        elseif v:IsA("Explosion") then
            v.Visible = false
        end
    end
    -- Lighting tweaks
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    Lighting.Brightness = 1
    -- Clear debris often
    game:GetService("Debris"):ClearAllChildren()
    -- Set LOD for terrain
    workspace.LevelOfDetail = Enum.LevelOfDetailSetting.Low
end

-- == WAIT FOR LOAD ==
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

if not lp then
    repeat task.wait() until Players.LocalPlayer
    lp = Players.LocalPlayer
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if lp.Character == nil or not lp.Character:FindFirstChild("HumanoidRootPart") then
    lp.CharacterAdded:Wait()
end

-- Simple wait for workspace map parts to exist
repeat
    task.wait()
until #workspace:GetChildren() > 10

fps_boost()

-- == MAIN ==
local placeId = game.PlaceId
local key = placeToKey[placeId]
if not key then
    lp:Kick("Unsupported game. PlaceId: " .. placeId)
    return
end

local url = URLs[key]
local ok, src = pcall(http_get, url)
if not ok or not src then
    lp:Kick("Failed to fetch script for " .. key)
    return
end

local ran, err = run_code(src)
if not ran then
    lp:Kick("Script error: " .. tostring(err))
    return
end

print("[Loader] Script for '" .. key .. "' loaded successfully.")
