--[[
https://luarmor.net
--]]
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

if getgenv().nobulemKeySystemLoaded then
    game.Players.LocalPlayer:Kick('Maximum load attempts reached!')
    return
end
getgenv().nobulemKeySystemLoaded = true

local NotificationLib = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/NotificationLib.lua"))()
local Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()

local Config = {
    Title = "nobulem.wtf",
    Subtitle = "Enter your access key to continue",
    GetKeyLink = "nobulem.wtf/key",
    DiscordLink = "https://discord.gg/mugcSRnpuG",
    LuarmorId = "dfd60575e93fbaacae09e64352bd227f"
}

local function saveKey(key)
    if writefile and isfolder and makefolder then
        if not isfolder("nobulem") then makefolder("nobulem") end
        writefile("nobulem/key.txt", key)
    end
end

local function loadKey()
    if readfile and isfile and isfile("nobulem/key.txt") then
        return readfile("nobulem/key.txt")
    end
    return nil
end

local function clearKey()
    if delfile and isfile and isfile("nobulem/key.txt") then
        delfile("nobulem/key.txt")
    end
end

local function formatDuration(seconds)
    if not seconds or seconds <= 0 or seconds == -1 then
        return "Lifetime"
    end
    
    local units = {
        {unit = "d", seconds = 86400},
        {unit = "h", seconds = 3600},
        {unit = "m", seconds = 60},
        {unit = "s", seconds = 1}
    }
    
    local parts = {}
    local remaining = seconds
    
    for _, data in ipairs(units) do
        local value = math.floor(remaining / data.seconds)
        if value > 0 then
            table.insert(parts, value .. data.unit)
            remaining = remaining % data.seconds
            if #parts >= 2 then break end
        end
    end
    
    return #parts > 0 and table.concat(parts, " ") or "0s"
end

local LuarmorAPI
local function loadLuarmorAPI()
    local success, api = pcall(function()
        return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
    end)
    
    if success then
        api.script_id = Config.LuarmorId
        return api
    end
    return nil
end

LuarmorAPI = loadLuarmorAPI()

local KeyHandlers = {
    KEY_VALID = function(data)
        pcall(function()
            if LuarmorAPI.purge_cache then
                LuarmorAPI.purge_cache()
            end
        end)
        
        local timeLeft
        if data.auth_expire then
            if data.auth_expire == -1 then
                timeLeft = "Lifetime"
            else
                local secondsLeft = data.auth_expire - os.time()
                timeLeft = formatDuration(secondsLeft)
            end
        else
            timeLeft = "Unknown"
        end
        
        local details = {
            "Executions: " .. tostring(data.total_executions or 0),
            "Expires: " .. timeLeft
        }
        
        if data.note and data.note ~= "" then
            table.insert(details, "Note: " .. data.note)
        end
        
        NotificationLib:Success(
            "Welcome, " .. LocalPlayer.DisplayName,
            table.concat(details, "\n"),
            8
        )

        script_key = data.key
        
        if data.key then
            saveKey(data.key)
        end
        
        task.delay(0.5, function()
            loadstring(game:HttpGet('https://api.luarmor.net/files/v3/loaders/dfd60575e93fbaacae09e64352bd227f.lua'))()
        end)
        
        return true, "Valid key"
    end,
    
    KEY_HWID_LOCKED = function(data)
        NotificationLib:Warning(
            "HWID Mismatch",
            "This key is linked to another device\nReset via Dashboard or Discord\n\nClick to copy Discord invite",
            12,
            function()
                setclipboard(Config.DiscordLink)
            end
        )
        return false, "HWID locked"
    end,
    
    KEY_EXPIRED = function(data)
        NotificationLib:Error(
            "Subscription Expired",
            "Your key has expired\nRenew to continue using nobulem.wtf\n\nClick to copy Discord invite",
            12,
            function()
                setclipboard(Config.DiscordLink)
            end
        )
        return false, "Key expired"
    end,
    
    KEY_BANNED = function(data)
        NotificationLib:Error(
            "Access Revoked",
            "This key has been blacklisted\nContact support if you believe this is an error\n\nClick to copy Discord invite",
            12,
            function()
                setclipboard(Config.DiscordLink)
            end
        )
        return false, "Key banned"
    end,
    
    KEY_INCORRECT = function(data)
        NotificationLib:Error(
            "Invalid Key",
            "Key not found in database\nDiscord invite copied to clipboard\n\nClick to copy again",
            12,
            function()
                setclipboard(Config.DiscordLink)
            end
        )
        return false, "Key incorrect"
    end
}

local function validateKey(key)
    if not LuarmorAPI then 
        return false, "Failed to connect to authentication server"
    end
    
    local status = LuarmorAPI.check_key(key)
    
    local handler = KeyHandlers[status.code]
    if handler then
        status.data = status.data or {}
        status.data.key = key
        return handler(status.data)
    end
    
    NotificationLib:Error(
        "Authentication Error",
        "Code: " .. tostring(status.code) .. "\n" .. (status.message or "Unknown error"),
        8,
        function()
            setclipboard(Config.DiscordLink)
        end
    )
    
    return false, status.message or "Authentication failed"
end

local function setLucideIcon(imageLabel, iconName)
    local asset = Lucide.GetAsset(iconName)
    if asset then
        imageLabel.Image = asset.Url
        imageLabel.ImageRectSize = asset.ImageRectSize
        imageLabel.ImageRectOffset = asset.ImageRectOffset
    end
end

local saved = loadKey()
if saved and saved ~= "" then
    local valid, msg = validateKey(saved)
    if valid then
        return
    else
        clearKey()
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NobulemKeySystem"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(400, 260)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(35, 35, 45)
Stroke.Thickness = 1
Stroke.Transparency = 1
Stroke.Parent = MainFrame

local TopAccent = Instance.new("Frame")
TopAccent.Size = UDim2.new(1, 0, 0, 2)
TopAccent.BackgroundColor3 = Color3.fromRGB(19, 128, 225)
TopAccent.BorderSizePixel = 0
TopAccent.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -40, 1, -40)
Content.Position = UDim2.fromOffset(20, 20)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = Config.Title
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Size = UDim2.new(1, 0, 0, 24)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTransparency = 1
Title.Parent = Content

local Subtitle = Instance.new("TextLabel")
Subtitle.Text = Config.Subtitle
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextColor3 = Color3.fromRGB(170, 170, 185)
Subtitle.TextSize = 13
Subtitle.Size = UDim2.new(1, 0, 0, 14)
Subtitle.Position = UDim2.fromOffset(0, 30)
Subtitle.BackgroundTransparency = 1
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextTransparency = 1
Subtitle.Parent = Content

local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, 0, 0, 44)
InputFrame.Position = UDim2.fromOffset(0, 70)
InputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
InputFrame.BorderSizePixel = 0
InputFrame.BackgroundTransparency = 1
InputFrame.Parent = Content

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = InputFrame

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(35, 35, 45)
InputStroke.Thickness = 1
InputStroke.Transparency = 1
InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
InputStroke.Parent = InputFrame

local KeyIcon = Instance.new("ImageLabel")
KeyIcon.Size = UDim2.fromOffset(20, 20)
KeyIcon.Position = UDim2.fromOffset(12, 12)
KeyIcon.BackgroundTransparency = 1
KeyIcon.ImageColor3 = Color3.fromRGB(88, 166, 255)
KeyIcon.ImageTransparency = 1
setLucideIcon(KeyIcon, "key")
KeyIcon.Parent = InputFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -50, 1, 0)
InputBox.Position = UDim2.fromOffset(42, 0)
InputBox.BackgroundTransparency = 1
InputBox.Font = Enum.Font.Code
InputBox.PlaceholderText = "Paste your key here..."
InputBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.TextSize = 14
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.TextTransparency = 1
InputBox.Text = ""
InputBox.ClearTextOnFocus = false
InputBox.Parent = InputFrame

InputBox.Focused:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(88, 166, 255)}):Play()
end)
InputBox.FocusLost:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(35, 35, 45)}):Play()
end)

local function CreateButton(text, iconName, color, position, widthScale, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(widthScale, -5, 0, 40)
    Btn.Position = position
    Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.BackgroundTransparency = 1
    Btn.Parent = Content

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(35, 35, 45)
    BtnStroke.Transparency = 1
    BtnStroke.Parent = Btn

    local BtnIcon = Instance.new("ImageLabel")
    BtnIcon.Size = UDim2.fromOffset(18, 18)
    BtnIcon.Position = UDim2.fromOffset(12, 11)
    BtnIcon.BackgroundTransparency = 1
    BtnIcon.ImageColor3 = color
    BtnIcon.ImageTransparency = 1
    setLucideIcon(BtnIcon, iconName)
    BtnIcon.Parent = Btn

    local BtnText = Instance.new("TextLabel")
    BtnText.Text = text
    BtnText.Size = UDim2.new(1, -30, 1, 0)
    BtnText.Position = UDim2.fromOffset(30, 0)
    BtnText.BackgroundTransparency = 1
    BtnText.Font = Enum.Font.GothamMedium
    BtnText.TextSize = 13
    BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
    BtnText.TextXAlignment = Enum.TextXAlignment.Center
    BtnText.TextTransparency = 1
    BtnText.Parent = Btn

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 26)}):Play()
    end)
    Btn.MouseButton1Click:Connect(callback)

    return {Btn, BtnStroke, BtnIcon, BtnText}
end

local CheckBtnData = CreateButton("Check Key", "arrow-right", Color3.fromRGB(75, 200, 130), UDim2.fromOffset(0, 130), 1, function()
    local key = InputBox.Text:gsub("%s+", "")
    if key == "" then
        NotificationLib:Error("Input Empty", "Please enter a key.", 3)
        return
    end
    validateKey(key)
end)

local LinkBtnData = CreateButton("Get Key", "link", Color3.fromRGB(88, 166, 255), UDim2.fromOffset(0, 180), 0.5, function()
    setclipboard(Config.GetKeyLink)
    NotificationLib:Info("Link Copied", "Key link copied to clipboard.", 3)
end)

local DiscordBtnData = CreateButton("Discord", "message-circle", Color3.fromRGB(114, 137, 218), UDim2.new(0.5, 5, 0, 180), 0.5, function()
    setclipboard(Config.DiscordLink)
    NotificationLib:Info("Discord Copied", "Discord invite copied to clipboard.", 3)
end)

MainFrame.BackgroundTransparency = 1
Stroke.Transparency = 1
Title.TextTransparency = 1
Subtitle.TextTransparency = 1
InputFrame.BackgroundTransparency = 1
InputStroke.Transparency = 1
KeyIcon.ImageTransparency = 1
InputBox.TextTransparency = 1

local function FadeInButton(data)
    TweenService:Create(data[1], TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(data[2], TweenInfo.new(0.5), {Transparency = 0}):Play()
    TweenService:Create(data[3], TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
    TweenService:Create(data[4], TweenInfo.new(0.5), {TextTransparency = 0}):Play()
end

task.spawn(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
    TweenService:Create(Stroke, TweenInfo.new(0.5), {Transparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(Title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(Subtitle, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(InputFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    TweenService:Create(InputStroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
    TweenService:Create(KeyIcon, TweenInfo.new(0.4), {ImageTransparency = 0}):Play()
    TweenService:Create(InputBox, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(0.1)
    FadeInButton(CheckBtnData)
    task.wait(0.1)
    FadeInButton(LinkBtnData)
    FadeInButton(DiscordBtnData)
end)
