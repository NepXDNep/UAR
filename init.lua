assert(syn, "This script has not been adapted for other exploits, if you would like it to work with your exploit maybe you can look at the code and suggest quick changes.")

local UAR  = {}
UAR.__index = UAR

-- Imports given filepath from my repos, not used for outside sources.
local function importf(...)
    local args = {...}
    assert(#args <= 3 and #args >= 1, "Incorrect number of arguments.")

    local urlStr = #args == 1 and ("https://api.github.com/repos/AnEverydayZomby/Aimthing/contents/"..args[1].."?ref=experimental") or 
        #args == 2 and ("https://api.github.com/repos/AnEverydayZomby/Aimthing/contents/"..args[1].."?ref="..args[2]) or
        #args == 3 and ("https://api.github.com/repos/AnEverydayZomby/"..args[2].."/contents/"..args[1].."?ref="..args[3])

    local requestInfo = {
        Url = urlStr,
        Method = "GET",
        Headers = {
            Accept = "application/vnd.github.v3.raw"
        }
    }

    local response = syn.request(requestInfo)
    assert(response.Success, tostring(response.StatusCode)..response.StatusMessage)

    local res, err = loadstring(response.Body)
    return res or error(err)
end

local gameSpecificImpls = importf("gameSpecificImpls.lua")()
local localConnections = importf("localConnections.lua")()
local defaultSettings, toolTips = importf("defaultSettings.lua")()

table.foreach(gameSpecificImpls, function(functionName, functionTbl)
    rawset(UAR, functionName, (functionTbl[game.PlaceId] or functionTbl[1]))
end)

local updateSettings = "https://www.aneverydayzombie.com/updatesettings.php"
local getSettings = "https://www.aneverydayzombie.com/getsettings.php"
local httpService = game:GetService("HttpService")
UAR.Settings = defaultSettings
UAR.SettingsChanged = localConnections.new()

do
    local response = syn.request({ Url = getSettings, Method = "GET" })
    local success, res = pcall(httpService.JSONDecode, httpService, response.Body)

    if success then
        table.foreach(defaultSettings, function(k,v)
            if not res[k] then res[k] = v end
        end)

        table.foreach(res, function(k,v)
            if not defaultSettings[k] then res[k] = nil end
        end)

        UAR.Settings = res
    else
        syn.request({ 
            Url = updateSettings,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = httpService:JSONEncode({
                ["settings_json"] = httpService:JSONEncode(defaultSettings)
            })
        })
    end
end

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local lplayer = players.lplayer
local camera = workspace.CurrentCamera
local mouse = lplayer:GetMouse()

function UAR:ActualFOV(fov)
    local viewSize = camera.ViewportSize
    return math.abs(fov/(camera.FieldOfView*(viewSize.X/viewSize.Y)/viewSize.X))
end

function UAR:WallCheck(pos, ignore_model)
    assert(typeof(pos) == "Vector3", "WallCheck argument #1 (pos) expects a Vector3 value.")
    if ignore_model then assert(typeof(ignore_model) == "Instance", "WallCheck argument #2 (ignore_model) expects an Instance value.") end

    local ignoreTransparency = self.Settings.IgnoreTransparency
    local screenPos = camera:WorldToScreenPoint(pos)
    local unit = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { camera, lplayer.Character, ignore_model }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult
    repeat 
        raycastResult = workspace:Raycast(unit.Origin, unit.Direction * screenPos.Z, raycastParams)
        if raycastResult then
            local hitPart = raycastResult.Instance
            if hitPart == workspace.Terrain 
                or ((not ignoreTransparency or (hitPart.Transparency == 0 or hitPart.Transparency == 1)) and lastHit.CanCollide) then 
                return false 
            end
            table.insert(raycastParams.FilterDescendantsInstances, hitPart)
        end
    until not raycastResult

    return true
end

function UAR:GetNearest()
    local settings = self.Settings
    local FOV = self:ActualFOV(settings.FOV)
    local playerCharacterTbl = self.GetPlayersCharacters()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local result = {}

    for player, character in next, playerCharacterTbl do
        if player ~= lplayer then
            if (settings.ForceFieldCheck and not character:FindFirstChildOfClass("ForceField")) or not settings.ForceFieldCheck then
                local priorityPart = character:FindFirstChild("Head") or character.PrimaryPart
                if priorityPart then
                    local screenPos, onscreen = camera:WorldToScreenPoint(priorityPart.Position)
                    if (onscreen and screenPos.Z > 0) then
                        if (mousePos - Vector2.new(screenPos.X, screenPos.Y)).magnitude <= FOV/2 then
                            if self.TeamCheck(player, settings.TeamCheck) then
                                table.insert(result, {
                                    Player = player,
                                    Character = character,
                                    Magnitude = (Vector3.new(screenPos.X, screenPos.Y, screenPos.Z/2) - Vector3.new(mouse.X, mouse.Y, 0.5)).magnitude,
                                    PriorityPart = priorityPart
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(result, function(a,b)
        return a.Magnitude < b.Magnitude
    end)

    for _,playerInfo in next, result do
        local player = playerInfo.Player
        local character = playerInfo.Character
        local priorityPart = playerInfo.PriorityPart
        if false --[[settings.HitScan]] then
            -- I'm too lazy to code a better way of doing hitscan atm.
        else
            local success, result = pcall(self.WallCheck, self, priorityPart)
            if success and result then
                return {
                    priorityPart,
                    true,
                    character
                }
            end
        end
    end

    local closestResult = result[1]
    if closestResult then
        local character = closestResult.Character
        return {
            character:FindFirstChild("Head") or character.PriorityPart, 
            false, 
            character
        }
    end

    return
end

function UAR:CheckMouseHit()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
    table.foreach(self.GetPlayersCharacters(), function(plr, char)
        if plr ~= lplayer then 
            table.insert(raycastParams.FilterDescendantsInstances, char)
        end
     end)

    local raycastResult = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 5000, raycastParams)
    return (raycastResult and self:WallCheck(raycastResult.Instance)) and raycastResult or false
end

local triggerThread = coroutine.wrap(function()
    while runService.Heartbeat:wait() do
        if UAR.Settings.Triggerbot then
            local mouseHit = self:CheckMouseHit()
            if mouseHit then
                local hitplr = players:GetPlayerFromCharacter(mouseHit.Instance.Parent) or (function()
                    for plr, char in next, UAR.GetPlayersCharacters() do
                        if plr ~= lplayer then
                            if mouseHit.Instance:IsDescendantOf(char) then return plr end
                        end
                    end
                end)()

                if hitplr and UAR.TeamCheck(hitplr, not UAR.Settings.TeamCheck) then

                end
            end
        end
    end
end)()

UAR.SettingsChanged:Connect(function(key, value)
end)

return UAR