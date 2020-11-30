assert(syn, 'This script contains synapse-exclusive functions.')
--[[
    Pls don't look, it's too spaghetti for one person to handle.
]] 


local players = game:GetService("Players")
local http = game:GetService("HttpService")
local runserv = game:GetService("RunService")
local gameSettings = UserSettings():GetService("UserGameSettings")
local lplayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = lplayer:GetMouse()
local settings = {}
local bpls = {}
local characterHashTable

local starter = game:GetService("StarterGui")
local messageSettings = {
    Color = Color3.fromRGB(85, 43, 170),
    Font = Enum.Font.SourceSans,
    TextSize = 18
}

local function broadcast(text)
    messageSettings.Text = text
    starter:SetCore("ChatMakeSystemMessage", messageSettings)
end

local Debug = _G.AimthingDebug

local reference_settings = {
    Aimkey = {
        EnumType = 'UserInputType',
        Name = 'MouseButton2'
    },
    FOV = 45,
    TeamCheck = true,
    WallCheck = true,
    Triggerbot = false,
    Triggerdelay = 0,
    DelayVariation = 0,
    Hitscan = true,
    Sensitivity = 3,
    AlwaysOn = false,
    IgnoreTransparency = false,
    AutoStop = false,
    CPS = 0,
    BurstClicks = 0,
    Overshoot = 0,
    ForceFieldCheck = true,
    DrawFOV = true
}

if isfile('config_aimthing.json') then
    settings = http:JSONDecode(readfile('config_aimthing.json'))
    for i,v in next, reference_settings do
        if settings[i] == nil then
            settings[i] = v
        end
    end
    for i,v in next, settings do
        if reference_settings[i] == nil then
            settings[i] = nil
        end
    end
    delfile("config_aimthing.json")

    syn.request({
        Url = "https://aneverydayzombie.com/updatesettings.php",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = http:JSONEncode({
            ["settings_json"] = http:JSONEncode(settings)
        })
    })
else
    local response = syn.request({
        Url = "https://aneverydayzombie.com/getsettings.php",
        Method = "GET"
    })

    local success, result = pcall(http.JSONDecode, http, response["Body"])

    if success then
        for i,v in next, reference_settings do
            if settings[i] == nil then
                settings[i] = v
            end
        end
        for i,v in next, settings do
            if reference_settings[i] == nil then
                settings[i] = nil
            end
        end
        settings = result
    else
        syn.request({
            Url = "https://aneverydayzombie.com/updatesettings.php",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = http:JSONEncode({
                ["settings_json"] = http:JSONEncode(reference_settings)
            })
        })

        broadcast("[UAR]: It seems it's your first time executing UAR, I hope you like it!")
        
        settings = reference_settings
    end
end

local toolTips = {
    Aimkey = "The keybind you must hold down to aim. (If AlwaysOn is on then this doesn't matter.)",
    FOV = "Degrees in which targets are accounted for.",
    TeamCheck = "Prevents aiming at teammates, disable for FFA. (If the aimbot isn't working I'd try turning this off to see if the game is FFA)",
    WallCheck = "Prevents aiming at targets through walls.",
    Triggerbot = "Shoots if target is infront of your mouse. (Only on while the aimbot is on. aka: If you are using a keybind, it will not work without it pressed down.)",
    Triggerdelay = "Amount of time (in ms) to wait before shooting at target with triggerbot.",
    DelayVariation = "Varies the triggerdelay by set number roughly every second.",
    Hitscan = "If enabled, it will aim at bodyparts that aren't head or primarypart when they are eligible to aim at.",
    Sensitivity = "Sort of misleading, but higher values will make aiming slower. This is so you can have high sensitivity and still use the aimbot. (You can also use this as a way to hide the aimbot.)\n\nI recommend using 3 or 6 if you are having problems with your sensitivity.",
    AlwaysOn = "If enabled, it will always be aiming at eligible targets.",
    IgnoreTransparency = "If enabled, it will count targets behind semi-transparent (meaning if they are behind a completely invisible wall that has collsion, it will recognize that as a boundary wall) walls as visible.",
    AutoStop = "If enabled and there is a current target, it will set your character's velocity to 0 to stop you. \n\n(Probably will not work on all games, but it should slow you down in games like CB:RO where movement hinders accuracy.)",
    CPS = "How fast the triggerbot will click, if set to 0, it will click as fast as possible. \n\n(This won't be 100% accurate and it can only go up so far.)",
    BurstClicks = "How many times to click everytime it attempts to click. (Sounds weird, but it's like a burstfire mode. If 0 it will be ignored.)",
    Overshoot = "Amount of time in ms to overshoot the target (Adds target's velocity multiplied by the time offset provided to the original position, I haven't changed triggerbot and wallcheck to work correctly with this, so high overshoots will probably require you to manually click.)",
    ForceFieldCheck = "Ignores characters with forcefields.",
    DrawFOV = "Draw FOV circle."
}

local orderedIndex = { -- I'm just lazy
    "Aimkey",
    "FOV",
    "TeamCheck",
    "WallCheck",
    "Triggerbot",
    "Triggerdelay",
    "DelayVariation",
    "Hitscan",
    "Sensitivity",
    "AlwaysOn",
    "IgnoreTransparency",
    "AutoStop",
    "CPS",
    "BurstClicks",
    "Overshoot",
    "ForceFieldCheck",
    "DrawFOV"
}

local function Enum2JSON(enum)
    return http:JSONEncode({
        EnumType = enum.EnumType,
        Name = enum.Name        
    })
end

local function JSON2Enum(json)
    local tbl = http:JSONDecode(json)
    return (tbl.EnumType and tbl.Name) and Enum[tbl.EnumType][tbl.Name] or false
end

local function GetFOV() 
    local viewportSize = camera.ViewportSize
    local pixelPerDegree = (camera.FieldOfView*(viewportSize.X/viewportSize.Y))/viewportSize.X
    return math.abs(settings.FOV/pixelPerDegree)
end

if game.GameId == 113491250 then
    for _,v in next, getgc() do
        if type(v) == 'function' and not is_synapse_function(v) then
            if getinfo(v).name == 'setcharacterhash' then
                characterHashTable = getupvalue(v, 3)
            end
        end
    end
end

function TeamCheck(plr)
    return (game.GameId == 1534453623 and (plr["GameStats"]["Team"].Value ~= lplayer["GameStats"]["Team"].Value) or plr.Team ~= lplayer.Team)
end

function WorldToScreenPointWithTimeOffset(part, offset)
    assert(typeof(part) == 'Instance' and part:IsA("BasePart"), "Function argument requires a basepart.")
    assert(part.Parent:IsA("Model"), "Inproper character part.")
    local position = part.Position + part.Parent.PrimaryPart.Velocity*(offset/1000)
    return {camera:WorldToScreenPoint(position)}
end

function GetPlayerAndCharacters()
    local result = {}

    if game.GameId == 113491250 then
        if characterHashTable then
            for character, player in next, characterHashTable do
                if character:IsDescendantOf(workspace) then
                    result[player] = character
                end
            end
        else
            for _,v in next, getgc() do
                if type(v) == 'function' and not is_synapse_function(v) then
                    if getinfo(v).name == 'setcharacterhash' then
                        characterHashTable = getupvalue(v, 3)
                        return GetPlayerAndCharacters()
                    end
                end
            end
        end
    else
        for _, player in next, players:GetPlayers() do
            if player.Character and player.Character:IsDescendantOf(workspace) then
                if ((player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0) or not player.Character:FindFirstChild("Humanoid")) then
                    result[player] = player.Character
                end
            end
        end
    end

    return result
end

function WallCheck(target)
    local vect3 = camera:WorldToScreenPoint(target.Position)
    local unit = camera:ScreenPointToRay(vect3.X, vect3.Y)
    local ray = Ray.new(unit.Origin, unit.Direction * 5000)
    local ignorelist = {camera}
    local lasthit, hitpos
    if lplayer.Character then ignorelist[#ignorelist+1] = lplayer.Character end

    repeat
        lasthit, hitpos = workspace:FindPartOnRayWithIgnoreList(ray, ignorelist)
        if lasthit then
            if lasthit == target or lasthit.Parent == target.Parent then
                return true
            elseif not settings.IgnoreTransparency or (settings.IgnoreTransparency and (lasthit.Transparency == 0 or lasthit.Transparency == 1)) or lasthit == workspace.Terrain then
                if lasthit.CanCollide then
                    if Debug ~= nil and Debug then
                        coroutine.wrap(function()
                            oldcolor = lasthit.BrickColor
                            oldmat = lasthit.Material
                            oldtransparency = lasthit.Transparency
                            lasthit.Material = Enum.Material.ForceField
                            lasthit.Transparency = 0.1
                            lasthit.BrickColor = BrickColor.new(0,255,255)

                            wait(2.5)
                            lasthit.Transparency = oldtransparency
                            lasthit.Material = oldmat
                            lasthit.BrickColor = oldcolor
                        end)()
                    end
                    return false
                end
            end
            ignorelist[#ignorelist+1] = lasthit
        end
    until not lasthit

    print('Raycast did not hit anything')
    return false
end

function GetBodyPriorityList(char)
    local priority = {}
    local toppart = char:FindFirstChild('Head') or char.PrimaryPart
    local humanoid = char:FindFirstChild("Humanoid")

    for _,v in next, char:GetChildren() do
        if v:IsA("BasePart") then
            table.insert(priority, v)
        end
    end

    table.sort(priority, function(a, b)
        return (a.Position - toppart.Position).magnitude < (b.Position - toppart.Position).magnitude
    end)

    for i,v in next, priority do
        priority[i] = v.Name
    end

    return priority
end

function GetNearestInfo()
    local FOV = GetFOV()
    local playerCharacterTable = GetPlayerAndCharacters()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local result = {}
    for player,character in next, playerCharacterTable do
        if player ~= lplayer then
            if (not character:FindFirstChildOfClass("ForceField") and settings.ForceFieldCheck) or not settings.ForceFieldCheck then
                local PriorityPart = character:FindFirstChild('Head') or character.PrimaryPart
                if PriorityPart then
                    local screenpoint, onscreen = camera:WorldToScreenPoint(PriorityPart.Position)
                    if (onscreen and screenpoint.Z > 0) and (mousePos - Vector2.new(screenpoint.X, screenpoint.Y)).magnitude <= FOV/2 then
                        if (settings.TeamCheck and TeamCheck(player)) or not settings.TeamCheck then
                            table.insert(result, {['player'] = player, ['character'] = character, ['magnitude'] = (Vector3.new(screenpoint.X, screenpoint.Y, screenpoint.Z/2) - Vector3.new(mouse.X, mouse.Y, 0.5)).magnitude})
                        end
                    end
                end
            end
        end
    end

    table.sort(result, function(a,b)
        return a.magnitude < b.magnitude
    end) 

    for _,playerInfo in next, result do
        local player = playerInfo.player
        local character = playerInfo.character

        if settings.Hitscan then
            local storedBPL = bpls[player]
            if not storedBPL then
                local success, result = pcall(GetBodyPriorityList, character)
                if success then
                    bpls[player] = result
                    storedBPL = bpls[player]
                else
                    storedBPL = {character:FindFirstChild("Head") or character.PrimaryPart}
                    error(error)
                end
            end

            for _,partname in next, storedBPL do
                local success, result = pcall(WallCheck, character:FindFirstChild(partname))
                if success and result then
                    return {character:FindFirstChild(partname), true, character}
                end
            end
        else
            local PriorityPart = character:FindFirstChild('Head') or character.PrimaryPart
            local success, result = pcall(WallCheck, PriorityPart)
            if success and result then
                return {PriorityPart, true, character}
            end
        end
    end

    if result[1] then
        return {(result[1].character:FindFirstChild('Head') or result[1].character.PrimaryPart), false, result[1].character}
    end

    return
end

function IsKeyDown(key, uis)
    local keyDown = key.EnumType == Enum.KeyCode and uis:IsKeyDown(key) or key.EnumType == Enum.UserInputType and uis:IsMouseButtonPressed(key)
    return keyDown
end

return {
    Initialize = function()
        print('Script by AnEverydayZombie, pls no copy pasterino.')
        
        game.OnClose = function()
            syn.request({
                Url = "https://aneverydayzombie.com/updatesettings.php",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = http:JSONEncode({
                    ["settings_json"] = http:JSONEncode(settings)
                })
            })
        end

        local UIS = game:GetService("UserInputService")

        local function GetDelta(vector1)
            local Delta = vector1 - Vector2.new(mouse.X, mouse.Y)
            local FixedDelta = Delta/(gameSettings.MouseSensitivity*settings.Sensitivity+UIS.MouseDeltaSensitivity)
            return math.clamp(FixedDelta.X, -mouse.X, camera.ViewportSize.X-mouse.X), math.clamp(FixedDelta.Y, -mouse.Y, camera.ViewportSize.Y-mouse.Y)
        end

        local Aiming = false
        local LastClickTick
        local TargetVisibleSince, LastTarget, Triggerdelay
        Triggerdelay = settings.Triggerdelay

        local function TriggerCheck(target)
            if TargetVisibleSince and tick()*1000 - TargetVisibleSince >= Triggerdelay then
                if target then
                    local unit = camera:ScreenPointToRay(mouse.X, mouse.Y)
                    local ray = Ray.new(unit.Origin, unit.Direction * (camera.CFrame.p - (target:IsA("Model") and target.PrimaryPart or target).Position).magnitude)
                    local hit = workspace:FindPartOnRayWithWhitelist(ray, {target})
                    if hit and (hit == target or hit:IsDescendantOf(target)) then
                        coroutine.wrap(function()
                            if settings.BurstClicks == 0 then
                                mouse1press()
                                wait()
                                mouse1release()
                            else
                                for i=0,settings.BurstClicks do
                                    mouse1press()
                                    wait()
                                    mouse1release()
                                    wait()
                                end
                            end
                        end)()
                        LastClickTick = tick()*1000
                    end
                end
            end
        end

        coroutine.wrap(function() -- trigger variation
            local oldTriggerdelay = Triggerdelay
            local time = tick()*1000
            while true do
                if tick()*1000-time > math.random(500, 1000) then
                    time = tick()*1000
                    Triggerdelay = math.random(settings.Triggerdelay-settings.DelayVariation/2,settings.Triggerdelay+settings.DelayVariation/2)
                elseif oldTriggerdelay ~= settings.Triggerdelay then
                    Triggerdelay = math.random(settings.Triggerdelay-settings.DelayVariation/2,settings.Triggerdelay+settings.DelayVariation/2)
                    oldTriggerdelay = settings.Triggerdelay
                end
                wait()
            end
        end)()
            
        local ManualOverride = false
        local function aimFunc()
            if not ManualOverride then
                local success, result = pcall(GetNearestInfo)
                if success and result then
                    local TargetPart, TargetVisible, TargetCharacter = unpack(result)
                    if TargetPart then
                        if (TargetVisible and settings.WallCheck) or not settings.WallCheck then
                            if TargetVisible then
                                if TargetVisibleSince == nil then
                                    TargetVisibleSince = tick()*1000
                                    LastTarget = TargetCharacter
                                elseif LastTarget ~= TargetCharacter then
                                    TargetVisibleSince = nil
                                end
                            else
                                TargetVisibleSince = nil
                            end
                            local success, result = pcall(WorldToScreenPointWithTimeOffset, TargetPart, settings.Overshoot)
                            if success then
                                local screenPos, onscreen = unpack(result)
                                if onscreen then
                                    mousemoverel(GetDelta(Vector2.new(screenPos.X, screenPos.Y)))
                                    if settings.Triggerbot and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                                        if settings.CPS == 0 or not LastClickTick or tick()*1000-LastClickTick > 1000/settings.CPS then
                                            coroutine.wrap(TriggerCheck)(TargetCharacter)
                                        end
                                    end

                                    coroutine.wrap(function() 
                                        if settings.AutoStop then
                                            if lplayer.Character then
                                                local HRP = lplayer.Character:FindFirstChild("HumanoidRootPart")
                                                if HRP then
                                                    HRP.Velocity = Vector3.new(0, HRP.Velocity.Y, 0)
                                                end
                                            end
                                        end
                                    end)()
                                end
                            else
                                warn(result)
                            end
                        end
                    end
                elseif success then
                    TargetVisibleSince = nil
                elseif not success then
                    error(error)
                end
            else
                Aiming = false
            end
        end

        local AlwaysOnCoroutine = coroutine.create(function()
            while true do
                if not settings.AlwaysOn then Aiming = false; coroutine.yield() end
                if not Aiming and not ManualOverride then Aiming = ManualOverride end
                aimFunc()
                runserv.Heartbeat:wait()
            end
        end)

        if settings.AlwaysOn then
            local success, error = coroutine.resume(AlwaysOnCoroutine)
            if not success then error(error) end
        end

        local aimKeyConnection = UIS.InputBegan:Connect(function(Input, _)
            if not settings.AlwaysOn then
                local Aimkey = JSON2Enum(http:JSONEncode(settings.Aimkey))
                if Input[settings.Aimkey.EnumType] == Aimkey then
                    Aiming = true
                    while IsKeyDown(Aimkey, UIS) do
                        aimFunc()
                        runserv.Heartbeat:wait()
                    end
                    Aiming = false
                end
            end
        end)

        local playerLeft = players.PlayerRemoving:Connect(function(player)
            if bpls[player] ~= nil then
                bpls[player] = nil
            end
        end)

        coroutine.wrap(function() -- Draw FOV
            local FOVCircle = Drawing.new('Circle')
            FOVCircle.Thickness = 2
            FOVCircle.Transparency = 0.5
            FOVCircle.Visible = true

            coroutine.wrap(function()
                spawn(function()
                    while wait() do
                        for i=0,1,0.01 do
                            FOVCircle.Color = Color3.fromHSV(i, 1, 1)
                            wait()
                        end
                    end
                end)

                local GUIInset = game:GetService("GuiService"):GetGuiInset()
                runserv.RenderStepped:Connect(function()
                    FOVCircle.Radius = GetFOV()/2
                    FOVCircle.Position = Vector2.new(mouse.X, mouse.Y) + GUIInset
                    FOVCircle.Visible = settings.DrawFOV
                end)
            end)()
        end)()

        local raw = syn.request({Url = "https://api.github.com/repos/Unnamed0000/UAR/contents/settings_module.lua", Method = "GET", Headers = {["Accept"] = "application/vnd.github.v3.raw"}}) 
        local SettingsModule = loadstring(raw["Body"])()
        local SettingsGUI = SettingsModule.new(Enum.KeyCode.LeftAlt)
        local GUI = getmetatable(SettingsGUI).__index

        local VisibilityChanged = GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
            ManualOverride = GUI.Enabled
        end)

        for _,index in next, orderedIndex do
            local i,v = index, settings[index]
            local val = Instance.new(typeof(v) == "number" and "NumberValue" or typeof(v) == "boolean" and "BoolValue" or "StringValue", game)
            val.Value = typeof(val.Value) == "string" and http:JSONEncode(v) or v 
            SettingsGUI:Option(i,val,toolTips[i])

            val.Changed:Connect(function()
                if typeof(val.Value) == "string" then
                    settings[i] = http:JSONDecode(val.Value)
                else
                    settings[i] = val.Value
                end

                if i == 'AlwaysOn' then
                    if val.Value then
                        local success, error = coroutine.resume(AlwaysOnCoroutine)
                        if not success then error(error) end
                    end
                end

                writefile('config_aimthing.json', http:JSONEncode(settings))
            end)
        end

        coroutine.wrap(function() pcall(function() loadstring(syn.request({Url = "https://api.github.com/repos/Unnamed0000/UAR/contents/intro.lua", Method = "GET", Headers = {["Accept"] = "application/vnd.github.v3.raw"}})["Body"])()() end) end)()
    end
}