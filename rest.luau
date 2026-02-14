if not LPH_OBFUSCATED then
    getgenv().LPH_NO_VIRTUALIZE = function(f) return f end
    getgenv().LPH_JIT = function(f) return f end
end

local cloneref = cloneref or function(o) return o end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))

local notificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/laagginq/ui-libraries/main/xaxas-notification/src.lua"))();
local notifications = notificationLibrary.new({            
    NotificationLifetime = 3, 
    NotificationPosition = "Middle",
    TextFont = Enum.Font.Code,
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    TextStrokeTransparency = 0, 
    TextStrokeColor = Color3.fromRGB(0, 0, 0)
});
notifications:BuildNotificationUI();
notifications:Notify("Initializing Nobulem...");

local Games = {
    {
        Name = "Hypershot",
        ScriptId = "05120379223359915853",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild("Weapons") ~= nil 
        end
    },
    {
        Name = "Flick",
        ScriptId = "10454517847790247851",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild('ModuleScripts') ~= nil
        end
    },
    {
        Name = "Realm Rampage",
        ScriptId = "76386821174283751255",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild("Replicate") ~= nil 
        end
    },
    {
        Name = "Basketball Arcade",
        ScriptId = "82821932812279873779",
        CheckFunction = function() 
            local zone = ReplicatedStorage:FindFirstChild("Zone")
            return zone and zone:FindFirstChild("RotatedRegion3") ~= nil
        end
    },
    {
        Name = "Midnight Chasers: Highway Racing",
        ScriptId = "11933192791628534715",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild("NitrousVFX") ~= nil 
        end
    },
    {
        Name = "War Tycoon",
        ScriptId = "47810414497836905461",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild("ACS_Engine") ~= nil 
        end
    },
    {
        Name = "Marvellous Smackdown",
        ScriptId = "84770629132565768307",
        CheckFunction = function() 
            return ReplicatedStorage:FindFirstChild("SelectACharacter") ~= nil 
        end
    },
    {
        Name = "Bulked up",
        ScriptId = "75606579830270260942",
        CheckFunction = function() 
            return workspace:FindFirstChild("Laser Fence") ~= nil 
        end
    },
    {
        Name = "Slipshot",
        ScriptId = "45071982026652889788",
        CheckFunction = function() 
            return game:GetService("StarterPlayer"):FindFirstChild('BetterReplicationClient') ~= nil 
        end
    }
}

local function detectGame()
    for _, gameData in ipairs(Games) do
        local success, result = pcall(gameData.CheckFunction)
        if success and result then
            return gameData
        end
    end
    return nil
end

local function init()
    local detectedGame = detectGame()
    
    if not detectedGame then
        return
    end

    notifications:Notify("Loading " .. detectedGame.Name .. "...")

    local KEY = getgenv().script_key
    
    if not KEY then
        notifications:Notify("Error: No key provided from keysystem")
        return
    end
    local SCRIPT_ID = detectedGame.ScriptId
    local REGIONS = {"eu-1", "us-1"}
    
    
    local httpRequest = (request or http_request or (http and http.request) or (syn and syn.request))
    if not httpRequest then
        return
    end

    local activeNode = nil

    for _, region in ipairs(REGIONS) do
        local url = "https://" .. region .. ".luaprot.net/api/v1/nodes/get"
        
        local success, response = pcall(function()
            return httpRequest({Url = url, Method = "GET"})
        end)

        if success and response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.node then
                activeNode = data.node
                break
            end
        end
    end

    if not activeNode then
        return
    end

    getgenv().LP_NODE = activeNode
    getgenv().lp_key = KEY

    local loaderUrl = "https://" .. activeNode .. ".luaprot.net/api/v1/loader/get/" .. SCRIPT_ID .. "/" .. KEY

    local success, result = pcall(function()
        return loadstring(game:HttpGet(loaderUrl))()
    end)

    if success then
        notifications:Notify("Successfully Loaded!")
    end
end

init()
