local gameSpecificFuncs = {}
gameSpecificFuncs.__index = gameSpecificFuncs

local players = game:GetService("Players")
local lplayer = players.LocalPlayer

gameSpecificFuncs.GetCharacters = {
    default = function(self)
        return self.CharacterTable or (function()
            local characterTable = self.CharacterTable
            characterTable = {}
    
            local function checkOnAncestryChanged(parent, player)
                if parent ~= workspace then
                    characterTable[player] = nil
                end
            end

            local function addCharacter(character, player)
                repeat wait() until character.PrimaryPart
                characterTable[player] = character
                character.AncestryChanged:Connect(function(_, parent)
                    checkOnAncestryChanged(parent, player)
                end)
            end
    
            for _, player in next, plrs:GetPlayers() do
                coroutine.wrap(function()
                    if player.Character then
                        characterTable[player] = player.Character
                    end

                    player.CharactedAdded:Connect(function(character)
                        addCharacter(character, player)
                    end)
                end)()
            end
    
            players.PlayerAdded:Connect(function(player)
                player.CharactedAdded:Connect(function(character)
                    addCharacter(character, player)
                end)
            end)
    
            return characterTable
        end)()
    end,

    113491250 = function(self)
        local characterTable = self.CharacterTable
        local setCharacterHash = self.setCharacterHash
        characterTable = {}

        if not setCharacterHash then
            for _,v in next, getgc() do
                if type(v) == 'function' and not is_synapse_function(v) then
                    if getinfo(v).name = 'setcharacterhash' then
                        setCharacterHash = getupvalue(setCharacterHash, 3)
                        break
                    end
                end
            end
        end

        for character, player in next, setCharacterHash do
            characterTable[player] = character
        end

        return characterTable
    end
}

gameSpecificFuncs.TeamCheck = {
    default = function(self, player)
        return player.Team ~= lplayer.Team
    end
}

return gameSpecificFuncs