local gameSpecificImpls = {}
gameSpecificImpls.__index = gameSpecificImpls

local players = game:GetService("Players")
local localPlayer = players.localPlayer

-- Self-explainatory but checks if given player is on the same team on player, however, when second argument (ffa) is true, it will always return true.
gameSpecificImpls.TeamCheck = {
    [1] = function(player: Instance, ffa: boolean)
        return ffa or localPlayer.Team ~= player.Team
    end,
    [1534453623] = function(player: Instance, ffa: boolean) -- Recoil
        return ffa or localPlayer:FindFirstChild("GameStats").Team.Value ~= player:FindFirstChild("GameStats").Team.Value
    end
}

-- Returns a table containing players & characters in the format of (key = player, value = character)
gameSpecificImpls.GetPlayersCharacters = {
    [1] = function() -- Wow this ugly, but maybe less intensive?
        local playersCharacters = gameSpecificImpls.StoredCharacters or (function()
            gameSpecificImpls.StoredCharacters = {}

            table.foreach(players:GetPlayers(), function(_,player)
                local char = player.Character
                if char then
                    gameSpecificImpls.StoredCharacters[player] = char
                end

                player.CharacterAdded:Connect(function(character)
                    repeat wait() until character:IsDescendantOf(workspace)
                    gameSpecificImpls.StoredCharacters[player] = character
                end)

                player.CharacterRemvoing:Connect(function(character)
                    gameSpecificImpls.StoredCharacters[player] = character
                end)
            end)

            coroutine.wrap(function()
                players.PlayerAdded:Connect(function(player)
                    player.CharacterAdded:Connect(function(char)
                        repeat wait() until character:IsDescendantOf(workspace)
                        gameSpecificImpls.StoredCharacters[player] = char
                    end)

                    player.CharacterRemvoing:Connect(function(char)
                        gameSpecificImpls.StoredCharacters[player] = char
                    end)
                end)

                players.PlayerRemoving:Connect(function(player)
                    gameSpecificImpls.StoredCharacters[player] = nil
                end)
            end)()

            return gameSpecificImpls.StoredCharacters
        end)()

        return playersCharacters
    end,
    [292439477] = function() -- Phantom Forces
        local playersCharacters = {}
        local characterHashes = gameSpecificImpls.StoredCharacters or (function()
            for _,v in next, getgc() do
                if typeof(v) == 'function' and not is_synapse_function(v) then
                    -- There might be a better way but this has worked so far for me.
                    -- Gets the third upvalue of the setcharacterhash function, the third upvalue being a table containing characters & players. (key = character, value = player)
                    if getinfo(v).name == "setcharacterhash" then
                        gameSpecificImpls.StoredCharacters = getupvalue(v, 3)
                        return gameSpecificImpls.StoredCharacters
                    end
                end
            end
        end)()

        table.foreach(characterHashes, function(k,v)
            if k:IsDescendantOf(workspace) then
                playersCharacters[v] = k
            end
        end)

        return playersCharacters
    end
}

return gameSpecificImpls