assert(syn, "This script uses synapse-exclusive functions, whether there are alternatives to these functions or not, this script will not function with other executors. (I don't really care about other executors so this will probably not change anytime soon.)")

local function importf(path)
    local fileExtension = path:split('.')[2]
    assert(fileExtension == 'lua' or fileExtension == 'json', "importf can only import .json and .lua files.")

    local response = syn.request({
        Url = "https://api.github.com/repos/Unnamed0000/UAR/contents/"..path.."?ref=experimental",
        Method = "Get",
        Headers = {
            Accept = "application/vnd.github.v3.raw"
        }
    })

    if response.Success then
        if fileExtension == 'lua' then
            local success, val = loadstring(response.Body)
            if success then
                return val()
            end
        elseif fileExtension == 'json' then
            local success, val = pcall(httpService.JSONDecode, httpService, response.Body)
            if success then
                return val
            end
        end
    end

    return response.Success, response.StatusCode
end

--[[ Locals ]]--
local httpService =   game:GetService("HttpService")
local players     =   game:GetService("Players")
local lplayer     =   players.LocalPlayer
local mouse       =   lplayer:GetMouse()
local gameId      =   game.GameId
local camera      =   workspace.CurrentCamera

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
local config         =   ReadJSONFile("uarconfig.json") or configTemplate

for key, value in next, configTemplate do -- Validate config file
    if not config[key] or typeof(config[key]) ~= typeof(configTemplate[key]) then
        config[key] = value
    end
end

local gameSpecificFuncs = importf("gameSpecificFuncs.lua")
local UAR = {}
UAR.__index = UAR

for key, value in next, gameSpecificFuncs do -- Set functions to game-specific functions or default if it isn't needed.
    UAR[key] = value[gameId] or value['default']
end

local function UAR:SetMousePosition()
    return self.mousePos or (function()
        local mousePos = self.mousePos
        mousePos = Vector2.new(mouse.X, mouse.Y)
        return mousePos
    end)()
end

local function UAR:FOV()
    local viewportSize = camera.ViewportSize
    local pixelPerDegreeX = (camera.FieldOfView * (viewportSize.X / viewportSize.Y)) / viewportSize.X 

    self.RealFOV = math.abs(config.FOV / pixelPerDegreeX)
    return self.RealFOV
end

local function UAR:InFOV(screenPoint)
    return (screenPoint - (self.mousePos or UAR:SetMousePosition())).magnitude <= (self.RealFOV or UAR:FOV()) / 2
end

local function UAR:WallCheck(target)
    local coords = camera:WorldToScreenPoint(target.Position)
    local unit = camera:ScreenPointToRay(coords.X, coords.Y)
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

local function UAR:GetPriorityParts(model, goal)
    assert(goal, "GetPriorityParts requires a goal-part to compare against other parts.")
    local priorityParts = {}

    for _,v in next, model:GetChildren() do
        if v:IsA("BasePart") and v.Transparency ~= 1 then
            priorityParts[#priorityParts+1] = v
        end
    end

    table.sort(priorityParts, function(a, b)
        return (a.Position - goal.Position).magnitude < (b.Position - goal.Position).magnitude
    end)

    table.foreach(priorityParts, function(key, value)
        priorityParts[key] = tostring(value)
    end)

    return priorityParts
end

local function UAR:GetNearestToCursor()
    local characters = self:GetCharacters()
    local mousePos = self.mousePos or self:SetMousePosition()
end