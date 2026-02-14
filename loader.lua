--[[
https://nobulem.wtf
--]]
local cloneref = cloneref or function(obj) return obj end
local clonefunction = clonefunction or function(func) return func end

local CoreGui = cloneref(game:GetService("CoreGui"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players"))

local LocalPlayer = Players.LocalPlayer

local protectedHttpGet = clonefunction(game.HttpGet)
local protectedSetClipboard = clonefunction(setclipboard)

if getgenv().nobulemKeySystemLoaded then
    game.Players.LocalPlayer:Kick('Maximum load attempts reached!')
    return
end
getgenv().nobulemKeySystemLoaded = true


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
local Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()

local Config = {
    Title = "nobulem.wtf",
    Subtitle = "Enter your access key to continue",
    GetKeyLink = "nobulem.wtf/key",
    DiscordLink = "https://discord.gg/mugcSRnpuG",
    LuaProtScriptId = "63113132532302100423"
}

local function saveKey(key)
    if writefile and isfolder and makefolder then
        if not isfolder("nobulem") then makefolder("nobulem") end
        writefile("nobulem/keys.txt", key)
    end
end

local function loadKey()
    if readfile and isfile and isfile("nobulem/keys.txt") then
        return readfile("nobulem/keys.txt")
    end
    return nil
end

local function clearKey()
    if delfile and isfile and isfile("nobulem/keys.txt") then
        delfile("nobulem/keys.txt")
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

local sdk = loadstring(game:HttpGet("https://sdk.luaprot.net/"))()
sdk.scriptId = Config.LuaProtScriptId

local ScreenGui

local function destroyKeySystem()
    if ScreenGui then
        local mainFrame = ScreenGui:FindFirstChild("MainFrame")
        if mainFrame then
            local fadeOut = TweenService:Create(
                mainFrame, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
                {BackgroundTransparency = 1}
            )
            
            for _, child in pairs(mainFrame:GetDescendants()) do
                if child:IsA("GuiObject") then
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                    end
                    if child:IsA("ImageLabel") then
                        TweenService:Create(child, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
                    end
                    if child:IsA("Frame") then
                        TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                    end
                    if child:IsA("UIStroke") then
                        TweenService:Create(child, TweenInfo.new(0.3), {Transparency = 1}):Play()
                    end
                end
            end
            
            fadeOut:Play()
            fadeOut.Completed:Wait()
        end
        
        ScreenGui:Destroy()
        ScreenGui = nil
    end
end

local function validateKey(key)
    if not sdk then 
        notifications:Notify("Authentication Failed: Failed to connect to server")
        return false, "Failed to connect to authentication server"
    end
    
    local success, result = pcall(function()
        return sdk:checkKey(key)
    end)
    
    if not success then
        notifications:Notify("Authentication Failed: Connection error")
        return false, "Connection error"
    end
    
    if result.status == "VALID" then
        local details = {}
        
        if result.keyExecutions then
             table.insert(details, "Executions: " .. tostring(result.keyExecutions))
        end

        if result.expire then
             local timeLeft = "Unknown"
             local seconds = tonumber(result.expire)
             if seconds then
                 timeLeft = formatDuration(seconds)
             end
             table.insert(details, "Expires: " .. timeLeft)
        end
        
        if result.note and result.note ~= "" then
            table.insert(details, "Note: " .. result.note)
        end
        
        if result.discordUsername and result.discordUsername ~= "unknown" then
            table.insert(details, "Discord: " .. result.discordUsername)
        end
        
        notifications:Notify("Welcome, " .. LocalPlayer.DisplayName .. " | " .. table.concat(details, " | "))

        if key then
            saveKey(key)
        end
        
        task.spawn(function()
            task.wait(0.5)
            destroyKeySystem()
        end)
        
        task.delay(0.5, function()
            getgenv().script_key = key
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Emplic/NOBULEM/refs/heads/main/rest.luau"))()
        end)
        
        return true, "Valid key"
    else
        clearKey()
        notifications:Notify("Key Invalid: " .. (result.message or "Please enter a valid key"))
        
        return false, result.message or "Invalid key"
    end
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
        notifications:Notify("Saved key is invalid. Please enter a new key.")
    end
end



ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = game:GetService("HttpService"):GenerateGUID(false):sub(1, 16)
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
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
        notifications:Notify("Input Empty: Please enter a key.")
        return
    end
    validateKey(key)
end)

local LinkBtnData = CreateButton("Get Key", "link", Color3.fromRGB(88, 166, 255), UDim2.fromOffset(0, 180), 0.5, function()
    protectedSetClipboard(Config.GetKeyLink)
    notifications:Notify("Link Copied: Key link copied to clipboard.")
end)

local DiscordBtnData = CreateButton("Discord", "message-circle", Color3.fromRGB(114, 137, 218), UDim2.new(0.5, 5, 0, 180), 0.5, function()
    protectedSetClipboard(Config.DiscordLink)
    notifications:Notify("Discord Copied: Discord invite copied to clipboard.")
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
