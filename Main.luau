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

local placeToKey = {}
for key, idList in pairs(PlaceIdMap) do
    for _, pid in ipairs(idList) do
        placeToKey[pid] = key
    end
end

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

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

if not lp then
    repeat task.wait() until Players.LocalPlayer
    lp = Players.LocalPlayer
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
    lp.CharacterAdded:Wait()
end

repeat
    task.wait(0.5)
until #workspace:GetChildren() > 15

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

task.wait(1)

if src:match("^%s*loadstring") then
    local ran, err = pcall(function() loadstring(src)() end)
    if not ran then
        lp:Kick("Script error: " .. tostring(err))
        return
    end
else
    local ran, err = run_code(src)
    if not ran then
        lp:Kick("Script error: " .. tostring(err))
        return
    end
end

print("[Loader] Script for '" .. key .. "' loaded successfully.")
