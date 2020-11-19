assert(syn, "This script uses synapse-exclusive functions, whether there are alternatives to these functions or not, this script will not function with other executors. (I don't really care about other executors so this will probably not change anytime soon.)")

--[[ Locals ]]--
local httpService =   game:GetService("HttpService")
local uis         =   game:GetService("UserInputService")
local players     =   game:GetService("Players")
local lplayer     =   players.LocalPlayer
local mouse       =   lplayer:GetMouse()
local gameId      =   game.GameId
local camera      =   workspace.CurrentCamera

local function importf(path)
    local fileExtension = path:split('.')[2]
    assert(fileExtension == 'lua' or fileExtension == 'json', "importf can only import .json and .lua files.")

    local resposne = game:HttpGet("https://raw.githubusercontent.com/Unnamed0000/UAR/experimental/"..path, true)

    if response then
        if fileExtension == 'lua' then
            local ret, err = loadstring(response)
            if ret then
                return ret()
            end
        elseif fileExtension == 'json' then
            local success, val = pcall(httpService.JSONDecode, httpService, response)
            if success then
                return val
            end
        end
    end
end

local function ReadJSONFile(path)
    return isfile(path) and httpService:JSONDecode(readfile(path))
end

local function EnumToJSON(enum)
    return httpService:JSONEncode({
        EnumType = enum.EnumType,
        Name = enum.Name
    })
end

local function EnumFromJSON(json)
    local decoded = httpService:JSONDecode(json)
    return (decoded.EnumType and decoded.Name) and Enum[decoded.EnumType][decoded.Name] or false
end

local configTemplate =   importf("default.json") -- Import default config file
local config         =   ReadJSONFile("uarconfig.json")

if not config then
    config = configTemplate
    writefile("uarconfig.json", httpService:JSONEncode(config))
end

for key, value in next, configTemplate do -- Validate config file
    if not config[key] or typeof(config[key]) ~= typeof(configTemplate[key]) then
        config[key] = value
    end
end

local gameSpecificFuncs = importf("gameSpecificFuncs.lua")
local UAR = {}
UAR.__index = UAR
UAR.config = {}

for key, value in next, config do -- Just so I can index config by the name of certain properties, since in the JSON it's an array.
    UAR.config[value.Name] = value.Value
end

for key, value in next, gameSpecificFuncs do -- Set functions to game-specific functions or default if it isn't needed.
    UAR[key] = value[gameId] or value['default']
end

function UAR:UpdateFOV()
    local viewportSize = camera.ViewportSize
    local pixelPerDegreeX = (camera.FieldOfView * (viewportSize.X / viewportSize.Y)) / viewportSize.X 

    self.RealFOV = math.abs(self.config.FOV / pixelPerDegreeX)
    return self.RealFOV
end

function UAR:GetModelRect(model)
    local orientation, size = model:GetBoundingBox()
    local corners = {
        (orientation * CFrame.new(-size.X / 2, -size.Y / 2, -size.Z / 2)).p,
        (orientation * CFrame.new(size.X / 2, -size.Y / 2, -size.Z / 2)).p,
        (orientation * CFrame.new(-size.X / 2, -size.Y / 2, size.Z / 2)).p,
        (orientation * CFrame.new(size.X / 2, -size.Y / 2, size.Z / 2)).p,
        (orientation * CFrame.new(-size.X / 2, size.Y / 2, -size.Z / 2)).p,
        (orientation * CFrame.new(size.X / 2, size.Y / 2, -size.Z / 2)).p,
        (orientation * CFrame.new(-size.X / 2, size.Y / 2, size.Z / 2)).p,
        (orientation * CFrame.new(size.X / 2, size.Y / 2, size.Z / 2)).p
    }
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local onScreen = false
    for _, corner in next, corners do
        local screenpoint, os = camera:WorldToViewportPoint(corner)
        local x, y = screenpoint.X, screenpoint.Y
        minX = x < minX and x or minX
        minY = y < minY and y or minY
        maxX = x > maxX and x or maxX
        maxY = y > maxY and y or maxY

        if onscreen then
            onScreen = os
        end
    end

    if onScreen then
        return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
    end
end

function UAR:PointInFOV(point)
    local mousePos = uis:GetMouseLocation()
    local FOV = self.RealFOV or self:UpdateFOV()
    local distance = (mousePos - nearestPoint).magnitude

    if distance <= FOV then
        return true, distance
    end
end

function UAR:RectInFOV(rectPos, rectSize)
    local mousePos = uis:GetMouseLocation()
    local FOV = self.RealFOV or self:UpdateFOV()
    local nearestPoint = Vector2.new(math.max(rectPos.X, math.min(mousePos.X, rectPos.X + rectSize.X)), math.max(rectPos.Y, math.min(mousePos.Y, rectPos.Y + rectSize.Y)))
    local distance = (mousePos - nearestPoint).magnitude

    if distance <= FOV then
        return true, distance
    end
end

function UAR:WallCheck(target)
    local coords = camera:WorldToViewportPoint(target.Position)
    local unit = camera:ViewportPointToRay(coords.X, coords.Y)
    local ray = Ray.new(unit.Origin, unit.Direction * (camera.CFrame.p - target.Position).magnitude)
    local ignore = { camera, lplayer.Character }
    local hit

    repeat
        hit = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
        if hit then
            if hit == target or hit:IsDescendantOf(target.Parent) then
                return true
            elseif hit == workspace.Terrain or hit.Transparency == 0 then
                return false
            end
        end
        ignore[#ignore+1] = hit
    until not hit

    return false
end

function UAR:GetNearest()
    local characters = self:GetCharacters()
    local FOV = self.RealFOV or self:UpdateFOV()
    local mousePos = uis:GetMouseLocation()
    local teamCheck = self.config.TeamCheck
    local aimPartName = self.config.AimPartName
    local hitScan = self.config.Hitscan

    local targets = {}
    for player, character in next, characters do
        if player ~= lplayer then
            if not teamCheck or self:TeamCheck(player) then
                local aimPart = character:FindFirstChild(aimPartName) or character.PrimaryPart
                if aimPart then
                    local screenpoint, os = camera:WorldToViewportPoint(aimPart.Position)
                    if os then
                        local inFOV, distance = self:PointInFOV(Vector2.new(screenpoint.X, screenpoint.Y)) or (hitScan and self:RectInFOV(self:GetModelRect(character)))
                        if inFOV then
                            targets[#targets+1] = { Player = player, Character = character, Distance = distance, TargetPart = aimPart }
                        end
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)

    for _, target in next, targets do
        local player = target.Player
        local character = target.Character
        local targetPart = target.TargetPart
        
        if targetPart then
            local visible = self:WallCheck(targetPart)
            if visible then
                return targetPart, player, character
            elseif hitScan then
                local children = character:GetChildren()
                for i, v in next, children do
                    if not v:IsA("BasePart") or v == targetPart then
                        children[i] = nil
                    end
                end

                table.sort(children, function(a, b)
                    local screenpoint_a, os_a = camera:WorldToViewportPoint(a.Position)
                    local screenpoint_b, os_b = camera:WorldToViewportPoint(b.Position)

                    if not os_a or not os_b then
                        return os_a and a or b
                    end

                    return (Vector2.new(screenpoint_a.X, screenpoint_a.Y) - mousePos).magnitude < (Vector2.new(screenpoint_b.X, screenpoint_b.Y) - mousePos).magnitude
                end)

                for i, v in next, children do
                    local visible = self:WallCheck(v)
                    if visible then
                        return v, player, character
                    end
                end
            end
        end
    end
end

return UAR