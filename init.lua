assert(syn, "This script uses synapse-exclusive functions, whether there are alternatives to these functions or not, this script will not function with other executors. (I don't really care about other executors so this will probably not change anytime soon.)")

local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputSerivce")

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

local function readJsonFile(path)
    return isfile(path) and httpService:JSONDecode(readfile(path))
end

local settingsTemplate = importf("default.json")
local settings = readJsonFile("uar-settings.json") or settingsTemplate
