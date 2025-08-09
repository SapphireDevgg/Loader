-- Place-ID-only Loader (Luau) with wait-for-load + FPS boost
-- No GUI. Kicks if placeId is not valid. Waits for player & map to load, then applies FPS boost and executes remote script.
-- Requires: executor with HTTP enabled and support for loadstring/load

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

-- PlaceIdMap: each game -> list of valid place IDs (primary map and extra maps)
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

-- Build reverse lookup: placeId -> key
local placeToKey = {}
for key, idList in pairs(PlaceIdMap) do
    for _, pid in ipairs(idList) do
        placeToKey[tonumber(pid)] = key
    end
end

-- Robust HTTP GET supporting common exploit functions
local function http_get(url)
    assert(type(url) == "string", "Invalid URL")
    -- game:HttpGet (Roblox native)
    if type(game.HttpGet) == "function" then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res and res ~= "" then return res end
    end
    -- syn.request
    if type(syn) == "table" and type(syn.request) == "function" then
        local ok, res = pcall(function() return syn.request{Url = url, Method = "GET"} end)
        if ok and res and res.Body then return res.Body end
    end
    -- request
    if type(request) == "function" then
        local ok, res = pcall(function() return request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    -- http.request
    if type(http) == "table" and type(http.request) == "function" then
        local ok, res = pcall(function() return http.request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    -- http_request (older)
    if type(http_request) == "function" then
        local ok, res = pcall(function() return http_request({Url = url, Method = "GET"}) end)
        if ok and res and res.Body then return res.Body end
    end
    error("No supported HTTP method found in this executor.")
end

-- Compile & run code safely
local function run_code(src, label)
    label = label or "remote"
    if not src or src == "" then return false, "empty_source" end
    local loader = loadstring or load
    if not loader then return false, "no_loader_available" end
    local ok, chunk_or_err = pcall(function() return loader(src) end)
    if not ok or not chunk_or_err then
        return false, ("load_error: %s"):format(tostring(chunk_or_err))
    end
    local okRun, runErr = pcall(chunk_or_err)
    if not okRun then
        return false, ("runtime_error: %s"):format(tostring(runErr))
    end
    return true
end

-- Wait helpers
local function wait_for_player_and_map(timeoutSeconds)
    timeoutSeconds = timeoutSeconds or 30
    local Players = game:GetService("Players")
    local start = tick()

    -- Wait for game to load
    if not game:IsLoaded() then
        pcall(function() game.Loaded:Wait() end)
    end

    -- Wait for LocalPlayer
    local localPlayer = Players.LocalPlayer
    while not localPlayer do
        if tick() - start > timeoutSeconds then return false, "no_localplayer" end
        wait(0.5)
        localPlayer = Players.LocalPlayer
    end

    -- Wait for character & humanoidrootpart
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", timeoutSeconds)
    if not hrp then return false, "no_hrp" end

    -- Generic wait for map: wait until workspace has at least one BasePart (map loaded)
    local workspace = game:GetService("Workspace")
    local function map_ready()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                return true
            end
        end
        return false
    end

    while not map_ready() do
        if tick() - start > timeoutSeconds then
            return false, "map_timeout"
        end
        wait(0.5)
    end

    return true
end

-- FPS boost: conservative & safe
local function apply_fps_boost()
    -- disable common particle effects
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Sparkles") then
                pcall(function() v.Enabled = false end)
            end
            if v:IsA("Decal") or v:IsA("Texture") then
                -- hiding decals/textures can help on low-end devices
                pcall(function() v.Transparency = 1 end)
            end
        end
    end)

    -- Lighting tweaks
    pcall(function()
        local Lighting = game:GetService("Lighting")
        -- disable shadows
        if Lighting then
            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function() Lighting.FogEnd = 9e9 end)
            -- reduce brightness a bit (to avoid HDR heavy costs)
            pcall(function() Lighting.Brightness = 1 end)
        end
    end)

    -- try to set rendering quality low (may be blocked in some executors)
    pcall(function()
        if settings and settings().Rendering then
            pcall(function() settings().Rendering.QualityLevel = 1 end)
        end
    end)

    -- try disabling 3D rendering (some executors allow this on client)
    pcall(function()
        local RunService = game:GetService("RunService")
        if RunService and RunService.Set3DRenderingEnabled then
            pcall(function() RunService:Set3DRenderingEnabled(true) end) -- keep true by default; you can change to false if you want no 3D
            -- NOTE: setting false will make screen blank; keep it as an optional change
        end
    end)

    -- reduce particle rate from attachments in StarterGui, Camera or effects (best-effort)
    pcall(function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") then
                pcall(function() v.Rate = 0 end)
            end
        end
    end)

    -- disable expensive decals in Lighting or Terrain if present (best-effort)
    pcall(function()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            -- no direct heavy ops here, but user can adjust manually
        end
    end)

    -- optional: force a small garbage collection to free memory
    pcall(function() collectgarbage() end)
end

-- Client check (so we can Kick on invalid)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
if not localPlayer then
    error("[Loader] This loader must run client-side (LocalPlayer required).")
end

local placeId = tonumber(game.PlaceId)
local key = placeToKey[placeId]
if not key then
    localPlayer:Kick("This place is not supported by the loader. PlaceId: "..tostring(placeId))
    return
end

local url = URLs[key]
if not url then
    localPlayer:Kick("Loader misconfiguration: no URL for key '" .. tostring(key) .. "'.")
    return
end

-- Wait for player & map to be ready (timeout adjustable; default 30s)
local ok, err = wait_for_player_and_map(35)
if not ok then
    -- if we timed out waiting for map/character, still attempt to run script once, otherwise kick (user asked for kick)
    localPlayer:Kick("Failed to detect player/map ready (reason: "..tostring(err)..").")
    return
end

-- Apply FPS boost before fetching/executing remote script
pcall(apply_fps_boost)

-- Fetch and execute remote script
local okFetch, bodyOrErr = pcall(http_get, url)
if not okFetch or not bodyOrErr or bodyOrErr == "" then
    localPlayer:Kick("Failed to fetch loader script for '"..tostring(key).."'. HTTP error.")
    return
end

local ran, runErr = run_code(bodyOrErr, key)
if not ran then
    localPlayer:Kick("Failed to run script for '"..tostring(key).."'. Error: "..tostring(runErr))
    return
end

print("[Loader] Successfully loaded script for '"..tostring(key).."' (PlaceId: "..tostring(placeId)..")")
return
